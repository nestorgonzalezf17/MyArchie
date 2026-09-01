# 02 — Instalación base manual

> Objetivo: pasar de un USB en vivo a un Arch Linux que arranca solo desde el disco duro.
> Este es el capítulo más importante y el más delicado. Léelo entero antes de ejecutar nada.

⚠️ **A partir de la sección 2 vas a borrar datos de forma irreversible.**

---

## 1. Cómo arranca una computadora (contexto)

Antes de particionar, entiende la cadena:

```
1. FIRMWARE (UEFI)    Vive en un chip de la placa. Al encender, busca en los discos una
                      partición especial FAT32 llamada ESP (EFI System Partition).
        ↓
2. BOOTLOADER         Un programa dentro del ESP (nosotros: systemd-boot). Su único trabajo
                      es cargar el kernel en memoria y decirle dónde está la raíz del sistema.
        ↓
3. KERNEL (Linux)     Toma control del hardware. Monta un mini-sistema temporal (initramfs)
                      con los drivers necesarios para leer tu disco real.
        ↓
4. INIT (systemd)     PID 1. Arranca todos los servicios: red, audio, login gráfico...
        ↓
5. TU SESIÓN
```

Cada paso de la instalación construye una pieza de esta cadena. Cuando algo no arranca,
identificas en qué eslabón se rompió.

## 2. Identificar y particionar el disco

### 2.1 Ver los discos

```bash
lsblk -o NAME,SIZE,TYPE,MODEL,MOUNTPOINTS
```

Ejemplo de salida:

```
NAME        SIZE TYPE MODEL
nvme0n1   476.9G disk Samsung SSD 980
sda        28.7G disk  USB DISK        <- tu USB de instalación, NO tocar
```

En esta guía usaré **`/dev/nvme0n1`**. Sustitúyelo por el tuyo en todos los comandos.

> ⚠️ **Ojo con la numeración de particiones:**
> - Discos NVMe: `/dev/nvme0n1` → particiones `/dev/nvme0n1p1`, `p2`...
> - Discos SATA/SSD/HDD: `/dev/sda` → particiones `/dev/sda1`, `sda2`...
>
> Fíjate en la `p`. Es el error #1 de los principiantes.

Guarda el nombre en una variable para no equivocarte:

```bash
DISK=/dev/nvme0n1
# Si es SATA:  DISK=/dev/sda
```

### 2.2 El esquema de particiones que vamos a crear

| # | Tamaño | Tipo | Sistema de archivos | Montaje | Para qué |
|---|--------|------|--------------------|---------|----------|
| 1 | 1 GiB  | EFI System | FAT32 | `/boot` | Bootloader + kernels. FAT32 es obligatorio: el firmware UEFI solo sabe leer eso. 1 GiB permite tener varios kernels. |
| 2 | resto  | Linux filesystem | Btrfs | `/` | Todo lo demás, con subvolúmenes. |

**¿Y la swap?** Usaremos un **archivo swap** en Btrfs (sección 4.4), no una partición. Es más
flexible: lo redimensionas después sin repartir el disco.

### 2.3 Particionar con `cfdisk` (interactivo, recomendado)

```bash
cfdisk "$DISK"
```

1. Si pregunta el tipo de etiqueta, elige **`gpt`**. (GPT es el estándar moderno que UEFI
   requiere.)
2. Si hay particiones viejas: selecciona cada una y elige **Delete**, hasta ver solo
   "Free space". ⚠️ *Aquí se pierden los datos.*
3. Selecciona el espacio libre → **New** → tamaño `1G` → Enter.
4. Con esa partición seleccionada → **Type** → elige **`EFI System`**.
5. Selecciona el espacio libre restante → **New** → acepta el tamaño completo (Enter).
   Su tipo `Linux filesystem` ya está bien.
6. **Write** → escribe `yes` en letras → **Quit**.

Verifica:

```bash
lsblk "$DISK"
```

Debes ver `nvme0n1p1` (1G) y `nvme0n1p2` (el resto).

Guarda también estas variables:

```bash
ESP="${DISK}p1"   ;  ROOT="${DISK}p2"     # NVMe
# ESP="${DISK}1"  ;  ROOT="${DISK}2"      # SATA
```

### 2.4 Alternativa no interactiva (`sgdisk`)

Si prefieres un solo comando (⚠️ borra el disco entero sin preguntar):

```bash
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+1G   -t 1:ef00 -c 1:"EFI System"       "$DISK"
sgdisk -n 2:0:0     -t 2:8300 -c 2:"Linux filesystem" "$DISK"
partprobe "$DISK"
```

## 3. Formatear

```bash
mkfs.fat -F32 -n ESP "$ESP"
mkfs.btrfs -f -L ARCH "$ROOT"
```

- `-F32` fuerza FAT32. `-n`/`-L` ponen una etiqueta legible (útil después).
- `-f` en `mkfs.btrfs` sobrescribe cualquier sistema de archivos anterior.

## 4. Btrfs: subvolúmenes, la parte que da superpoderes

💡 **Qué es un subvolumen.** Btrfs no te obliga a decidir tamaños por adelantado como las
particiones. Un subvolumen es como una carpeta que Btrfs trata como una unidad
independiente: puedes hacerle un *snapshot* (foto instantánea, casi gratis en espacio) o
montarlo con opciones distintas. Separamos `/` de `/home` para poder revertir el sistema
**sin** revertir tus archivos personales.

### 4.1 Crear los subvolúmenes

```bash
mount "$ROOT" /mnt

btrfs subvolume create /mnt/@            # raíz  →  /
btrfs subvolume create /mnt/@home        # datos →  /home
btrfs subvolume create /mnt/@log         # →  /var/log      (no queremos logs en snapshots)
btrfs subvolume create /mnt/@pkg         # →  /var/cache/pacman/pkg  (caché, no vale la pena)
btrfs subvolume create /mnt/@snapshots   # →  /.snapshots    (aquí viven las fotos)

umount /mnt
```

### 4.2 Montarlos en el orden correcto

```bash
OPTS="noatime,compress=zstd:3,ssd,space_cache=v2"

mount -o "$OPTS,subvol=@" "$ROOT" /mnt

mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots,boot}

mount -o "$OPTS,subvol=@home"      "$ROOT" /mnt/home
mount -o "$OPTS,subvol=@log"       "$ROOT" /mnt/var/log
mount -o "$OPTS,subvol=@pkg"       "$ROOT" /mnt/var/cache/pacman/pkg
mount -o "$OPTS,subvol=@snapshots" "$ROOT" /mnt/.snapshots

mount "$ESP" /mnt/boot
```

Qué significan las opciones:

- `noatime` — no escribir la hora de último acceso cada vez que se lee un archivo. Menos
  desgaste del SSD y más velocidad.
- `compress=zstd:3` — comprime transparentemente. Ahorra ~30-50 % de espacio y suele ser
  **más rápido**, porque leer menos bytes del disco compensa descomprimir.
- `ssd` — optimizaciones para SSD. Si tienes disco mecánico, quita esta opción.
- `space_cache=v2` — caché de espacio libre moderno.

Comprueba que todo esté montado:

```bash
findmnt -R /mnt
```

### 4.3 Mirrors rápidos (acelera muchísimo la descarga)

```bash
pacman -Sy --noconfirm reflector
reflector --country Chile,Argentina,Brazil,Mexico --protocol https \
          --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
```

Ajusta los países a los tuyos. Si no estás seguro, usa `--latest 20 --sort rate` sin filtro
de país (tarda más pero funciona en cualquier lugar).

### 4.4 (Se hace después) archivo swap

Lo crearemos ya dentro del sistema instalado, en la sección 8.

## 5. `pacstrap`: instalar el sistema base

Este es *el* comando que instala Arch. Descarga paquetes y los desempaqueta en `/mnt`.

```bash
pacstrap -K /mnt \
  base base-devel linux linux-firmware linux-headers \
  btrfs-progs \
  networkmanager \
  vim nano \
  sudo git \
  man-db man-pages texinfo \
  zsh \
  intel-ucode
```

⚠️ **Microcódigo del procesador — elige el correcto:**
- CPU Intel → `intel-ucode` (como arriba)
- CPU AMD → cambia por `amd-ucode`

Si no sabes cuál tienes: `grep -m1 'model name' /proc/cpuinfo`.

Qué es cada cosa:

| Paquete | Para qué |
|---|---|
| `base` | El conjunto mínimo para tener un sistema Arch |
| `base-devel` | Compilador, `make`, `fakeroot`... **Necesario para el AUR** |
| `linux` | El kernel |
| `linux-firmware` | Blobs de firmware para Wi-Fi, GPU, etc. |
| `linux-headers` | Cabeceras del kernel; las piden drivers como NVIDIA y VirtualBox |
| `btrfs-progs` | Herramientas de Btrfs. **Sin esto el sistema no arranca** con raíz Btrfs |
| `networkmanager` | Gestión de red (cable y Wi-Fi) tras reiniciar |
| `sudo` | Ejecutar comandos como root desde tu usuario |
| `*-ucode` | Parches de microcódigo del CPU; corrigen bugs de hardware y vulnerabilidades |

💡 El flag `-K` inicializa un llavero de claves GPG nuevo dentro del sistema instalado.

Esto tarda entre 3 y 15 minutos según tu conexión.

## 6. `fstab`: cómo se monta todo al arrancar

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

`-U` usa **UUID** en vez de `/dev/nvme0n1p2`. 💡 *Por qué importa:* si conectas otro disco,
los nombres `/dev/sdX` pueden cambiar de orden y el sistema no arrancaría. El UUID es único
y permanente.

Revisa que el archivo tenga una línea por cada subvolumen (`subvol=/@home`, etc.) y una para
`/boot`. Si algo falta, vuelve a montarlo y regenera.

## 7. `arch-chroot`: entrar al sistema nuevo

```bash
arch-chroot /mnt
```

💡 **Qué acaba de pasar.** `chroot` ("change root") cambia cuál directorio es `/` para tu
shell. A partir de ahora, cuando escribes `/etc/hostname`, estás editando
`/mnt/etc/hostname` del sistema instalado. Estás "dentro" de tu nuevo Arch aunque el kernel
que corre siga siendo el del USB. `arch-chroot` además monta `/proc`, `/sys` y `/dev` por ti.

El prompt cambia a `[root@archiso /]#`. **Todos los comandos de aquí en adelante van dentro
del chroot**, hasta que diga lo contrario.

## 8. Configuración dentro del chroot

### 8.1 Zona horaria y reloj

```bash
ln -sf /usr/share/zoneinfo/America/Santiago /etc/localtime
hwclock --systohc
```

Cambia la zona por la tuya. Para ver las disponibles:
`ls /usr/share/zoneinfo/America/`.

💡 `hwclock --systohc` escribe la hora del sistema al reloj de hardware **en UTC**. Si haces
arranque dual con Windows verás las horas desfasadas; la solución correcta es decirle a
Windows que use UTC (busca "RealTimeIsUniversal" en la Arch Wiki).

### 8.2 Idioma (locales)

```bash
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#es_CL.UTF-8 UTF-8/es_CL.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo 'LANG=es_CL.UTF-8' > /etc/locale.conf
echo 'KEYMAP=la-latin1' > /etc/vconsole.conf
```

Cambia `es_CL` por tu locale (`es_MX`, `es_ES`, `es_AR`...). Dejamos `en_US` también
habilitado porque muchos mensajes de error solo existen en inglés y son más fáciles de
buscar en Google.

### 8.3 Nombre de la máquina y hosts

```bash
echo 'myarchie' > /etc/hostname

cat > /etc/hosts <<'HOSTS'
127.0.0.1   localhost
::1         localhost
127.0.1.1   myarchie.localdomain myarchie
HOSTS
```

### 8.4 Contraseña de root y tu usuario

```bash
passwd                                    # contraseña de root

useradd -m -G wheel -s /bin/zsh nestor    # <-- cambia "nestor" por tu nombre de usuario
passwd nestor
```

- `-m` crea `/home/nestor`.
- `-G wheel` lo mete al grupo `wheel`, que es al que daremos permisos de `sudo`.
- `-s /bin/zsh` pone Zsh como shell por defecto.

Habilita `sudo` para el grupo `wheel`:

```bash
EDITOR=nano visudo
```

Busca y **descomenta** (quita el `#`) esta línea:

```
%wheel ALL=(ALL:ALL) ALL
```

Guarda con `Ctrl+O`, `Enter`, y sal con `Ctrl+X`.

💡 *Por qué `visudo` y no editar el archivo directo:* `visudo` valida la sintaxis antes de
guardar. Un `/etc/sudoers` con un error de sintaxis te deja **sin sudo y sin forma de
arreglarlo** salvo arrancando desde el USB otra vez.

### 8.5 Archivo swap

```bash
btrfs subvolume create /swap
btrfs filesystem mkswapfile --size 8g --uuid clear /swap/swapfile
swapon /swap/swapfile

cat >> /etc/fstab <<'SWAP'

# swap
/swap/swapfile none swap defaults 0 0
SWAP
```

Tamaño recomendado: igual a tu RAM si quieres hibernación, o la mitad si no. Con 16 GB de
RAM, 8 GB está bien.

### 8.6 initramfs

El initramfs es el mini-sistema que el kernel carga primero, con los drivers justos para
poder leer tu disco real.

Edita `/etc/mkinitcpio.conf` y busca la línea `MODULES=`:

```bash
nano /etc/mkinitcpio.conf
```

Déjala así:

```
MODULES=(btrfs)
```

Luego regenera:

```bash
mkinitcpio -P
```

💡 Si ves *warnings* sobre firmware de dispositivos que no tienes (por ejemplo módulos de
Wi-Fi ajenos), ignóralos. Solo importan los errores (`==> ERROR`).

## 9. Bootloader: systemd-boot

### 9.1 Instalarlo

```bash
bootctl install
```

Esto copia el bootloader al ESP (`/boot`) y lo registra en el firmware UEFI.

### 9.2 Configuración del cargador

```bash
cat > /boot/loader/loader.conf <<'LOADER'
default  arch.conf
timeout  3
console-mode max
editor   no
LOADER
```

- `timeout 3` — 3 segundos de menú para poder elegir otra entrada.
- `editor no` — impide editar los parámetros del kernel en el arranque. 💡 Es una medida de
  seguridad: sin esto, cualquiera con acceso físico puede añadir `init=/bin/bash` y entrar
  como root sin contraseña.

### 9.3 La entrada de arranque

Necesitamos el UUID de la partición raíz:

```bash
ROOT_UUID=$(findmnt -no UUID -T /)
echo "$ROOT_UUID"      # verifica que imprima algo
```

Y ahora la entrada (ajusta `intel-ucode` → `amd-ucode` si tienes AMD):

```bash
cat > /boot/loader/entries/arch.conf <<EOF2
title    MyArchie
linux    /vmlinuz-linux
initrd   /intel-ucode.img
initrd   /initramfs-linux.img
options  root=UUID=$ROOT_UUID rootflags=subvol=@ rw quiet loglevel=3
EOF2
```

Y una entrada de rescate con el initramfs "fallback" (que incluye *todos* los drivers):

```bash
cat > /boot/loader/entries/arch-fallback.conf <<EOF2
title    MyArchie (fallback)
linux    /vmlinuz-linux
initrd   /intel-ucode.img
initrd   /initramfs-linux-fallback.img
options  root=UUID=$ROOT_UUID rootflags=subvol=@ rw
EOF2
```

💡 **Guarda esta entrada de fallback.** El día que una actualización rompa el initramfs
normal, será tu forma de arrancar.

⚠️ Lo más crítico aquí es `rootflags=subvol=@`. Sin eso, el kernel monta el subvolumen raíz
de Btrfs (donde solo se ven las carpetas `@`, `@home`...) y no encuentra `/sbin/init`,
dándote un kernel panic.

Verifica:

```bash
bootctl list
```

### 9.4 Mantener el bootloader actualizado automáticamente

```bash
mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/95-systemd-boot.hook <<'HOOK'
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Actualizando systemd-boot en el ESP...
When = PostTransaction
Exec = /usr/bin/bootctl update
HOOK
```

## 10. Servicios esenciales

```bash
systemctl enable NetworkManager
systemctl enable systemd-timesyncd
```

`enable` significa "arranca solo en cada inicio". (`start` sería "arranca ahora", que dentro
del chroot no tiene sentido.)

## 11. Reiniciar al sistema nuevo

```bash
exit                  # salir del chroot
umount -R /mnt
swapoff -a
reboot
```

**Quita el USB** mientras reinicia.

### Si arranca 🎉

Verás el menú de systemd-boot y luego un login de texto. Entra con tu usuario y contraseña.
Comprueba la red:

```bash
nmcli device status
ping -c 3 archlinux.org
```

Si estás en Wi-Fi y no hay conexión:

```bash
nmcli device wifi list
nmcli device wifi connect "Nombre De Tu Red" --ask
```

### Si NO arranca

No entres en pánico: no perdiste nada, el sistema está en disco. Arranca de nuevo con el USB
y ve a [12 — Solución de problemas](12-solucion-de-problemas.md), sección "No arranca".
El patrón de recuperación es siempre el mismo: montar de nuevo con los subvolúmenes,
`arch-chroot`, arreglar, salir, reiniciar.

---

## Checklist

- [ ] El sistema arranca desde el disco, sin USB
- [ ] Puedo iniciar sesión con mi usuario
- [ ] `sudo -v` funciona (pide mi contraseña y no da error)
- [ ] Tengo internet
- [ ] `findmnt /` muestra `btrfs` y `subvol=/@`

---

**Siguiente:** [03 — Post-instalación](03-post-instalacion.md)
