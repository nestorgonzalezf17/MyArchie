# 12 — Solución de problemas

> Guía de rescate. Busca tu síntoma y sigue el procedimiento.

---

## 0. El procedimiento universal: chroot de rescate

**Memoriza esto.** Casi cualquier problema que impida arrancar se arregla así:

```bash
# 1. Arranca con el USB de Arch
# 2. Monta tu sistema con los subvolúmenes correctos
OPTS="noatime,compress=zstd:3,ssd,space_cache=v2"
ROOT=/dev/nvme0n1p2        # ajusta
ESP=/dev/nvme0n1p1         # ajusta

mount -o "$OPTS,subvol=@" "$ROOT" /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots,boot}
mount -o "$OPTS,subvol=@home"      "$ROOT" /mnt/home
mount -o "$OPTS,subvol=@log"       "$ROOT" /mnt/var/log
mount -o "$OPTS,subvol=@pkg"       "$ROOT" /mnt/var/cache/pacman/pkg
mount -o "$OPTS,subvol=@snapshots" "$ROOT" /mnt/.snapshots
mount "$ESP" /mnt/boot

# 3. Entra
arch-chroot /mnt

# 4. Arregla lo que sea

# 5. Sal y reinicia
exit
umount -R /mnt
reboot
```

Si no recuerdas los nombres de las particiones: `lsblk -f`.

---

## 1. No arranca

### Síntoma: no aparece el menú de systemd-boot; va directo a Windows o al BIOS

Entra al firmware y revisa el orden de arranque. Debe haber una entrada "Linux Boot Manager".
Si no está, desde el chroot:

```bash
bootctl install
bootctl list          # debe listar tus entradas
efibootmgr -v         # debe aparecer "Linux Boot Manager"
```

Si `efibootmgr` no muestra nada, el firmware no aceptó la entrada. Solución de respaldo
(ruta "removable", que todo firmware UEFI arranca):

```bash
bootctl install --no-variables
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/BOOT/BOOTX64.EFI
```

### Síntoma: "You are now being dropped into an emergency shell"

Casi siempre es el `fstab` o el subvolumen raíz.

```bash
# Desde la emergency shell:
journalctl -xb -p err
cat /proc/cmdline      # ¿está rootflags=subvol=@ ?
```

Desde el chroot de rescate, verifica:

1. `/boot/loader/entries/arch.conf` tiene `rootflags=subvol=@`.
2. El UUID en `options root=UUID=...` coincide con `blkid /dev/nvme0n1p2`.
3. `/etc/fstab` no tiene UUIDs de particiones que ya no existen. Comenta con `#` cualquier
   línea sospechosa o añádele la opción `nofail`.
4. `MODULES=(btrfs)` está en `/etc/mkinitcpio.conf` y regeneraste con `mkinitcpio -P`.

### Síntoma: kernel panic — "unable to mount root fs"

El initramfs no tiene el driver para leer tu disco.

```bash
# En el chroot:
nano /etc/mkinitcpio.conf     # MODULES=(btrfs)  y si es NVMe con RAID, añade nvme
mkinitcpio -P
```

Y prueba a arrancar con la entrada **fallback**, que incluye todos los drivers.

### Síntoma: "error: file '/vmlinuz-linux' not found"

El ESP no estaba montado en `/boot` cuando se instaló el kernel.

```bash
# En el chroot, con /boot montado correctamente:
pacman -S linux linux-firmware      # reinstala el kernel al lugar correcto
ls /boot                            # deben estar vmlinuz-linux e initramfs-linux.img
bootctl install
```

### Síntoma: arranca pero se queda en negro tras el menú

Suele ser el driver de video. Arranca con la entrada fallback y añade temporalmente
`nomodeset` a la línea `options`. Si con eso arranca, es confirmado: revisa el doc 03,
sección 4.

---

## 2. Sin red

```bash
ip link                            # ¿aparece la interfaz? ¿está DOWN?
systemctl status NetworkManager    # ¿está corriendo?
sudo systemctl enable --now NetworkManager

nmcli device status
nmcli device wifi list
nmcli device wifi connect "Red" --ask
```

### Interfaz Wi-Fi ausente

Falta firmware:

```bash
lspci -k | grep -A3 -i network     # ver el modelo y si tiene "Kernel driver in use"
```

Si no hay driver en uso, busca el firmware:

```bash
sudo pacman -S linux-firmware
# Broadcom antiguo:
sudo pacman -S broadcom-wl-dkms
# Realtek recientes suelen estar en el AUR:
paru -S rtw89-dkms-git       # ajusta al chip que te reporte lspci
```

### Resuelve IPs pero no nombres (falla DNS)

```bash
cat /etc/resolv.conf
ping -c2 1.1.1.1        # si esto va y ping archlinux.org no, es DNS

sudo tee /etc/NetworkManager/conf.d/dns.conf <<'CONF'
[global-dns-domain-*]
servers=1.1.1.1,9.9.9.9
CONF
sudo systemctl restart NetworkManager
```

### Wi-Fi que se corta cada pocos minutos

Ahorro de energía agresivo:

```bash
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf <<'CONF'
[connection]
wifi.powersave = 2
CONF
sudo systemctl restart NetworkManager
```

---

## 3. Sin audio

```bash
systemctl --user status pipewire wireplumber
systemctl --user restart pipewire pipewire-pulse wireplumber

wpctl status                  # lista dispositivos; el ⭐ marca el por defecto
wpctl set-default <ID>        # cambiar de salida
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0     # quitar el mute
pavucontrol                   # GUI: revisa la pestaña "Configuración"
```

Si el dispositivo aparece pero no suena, en `pavucontrol` → pestaña **Configuración**, el
perfil suele estar en "Off". Cámbialo a "Analog Stereo Duplex" o "Pro Audio".

---

## 4. Hyprland no arranca

```bash
cat /tmp/hypr/*/hyprland.log | tail -60
```

| Mensaje | Causa |
|---|---|
| `No GPUs found` | Falta driver de video o `MODULES` de NVIDIA en el initramfs |
| `Config error at line N` | Error de sintaxis en `hyprland.conf`; la línea te la dice |
| Pantalla negra con cursor | Falla el `monitor=`. Prueba `monitor = , preferred, auto, 1` |
| Sale inmediatamente | Suele ser una `exec-once` que falla; coméntalas todas y ve añadiendo |

Para arrancar con una configuración limpia y descartar tu config:

```bash
mv ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak
Hyprland      # arrancará con la config por defecto
```

### Waybar no aparece

```bash
waybar          # ejecútalo en una terminal: los errores de JSON se muestran ahí
```

Un `config.jsonc` con una coma de más es la causa habitual.

---

## 5. pacman y paquetes

### "error: failed to commit transaction (conflicting files)"

Un archivo del paquete ya existe en disco sin pertenecer a él.

```bash
# Verifica de quién es:
pacman -Qo /ruta/al/archivo/en/conflicto

# Si no es de ningún paquete (huérfano de una instalación manual), bórralo y reintenta.
sudo mv /ruta/al/archivo /ruta/al/archivo.bak
sudo pacman -Syu
```

⚠️ `--overwrite` existe, pero úsalo solo cuando entiendas exactamente qué archivo estás
pisando.

### "error: ... signature is invalid / unknown trust"

```bash
sudo pacman -Sy archlinux-keyring
sudo pacman -Syu
```

Si persiste (llavero corrupto):

```bash
sudo rm -rf /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Syu
```

⚠️ Comprueba también la fecha: `timedatectl`. Un reloj mal puesto invalida las firmas.

### "unable to lock database"

Quedó un lock de una operación interrumpida.

```bash
# ⚠️ Asegúrate de que NO hay ningún pacman corriendo: ps aux | grep pacman
sudo rm /var/lib/pacman/db.lck
```

### Descargas lentísimas o mirrors caídos

```bash
sudo reflector --country Chile,Argentina,Brazil --protocol https \
               --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu
```

### Un paquete del AUR no compila

```bash
paru -S --rebuild paquete
paru --devel --rebuild        # para paquetes -git desactualizados
```

Lee el error: suele faltar una dependencia de compilación o el upstream cambió. Mira los
comentarios de la página del paquete en aur.archlinux.org.

---

## 6. Espacio en disco lleno

⚠️ Btrfs se comporta distinto: puede decir "No space left" con `df` mostrando espacio libre.

```bash
sudo btrfs filesystem usage /        # los números REALES
sudo btrfs balance start -dusage=50 /   # recompactar bloques medio vacíos
```

Y limpia:

```bash
sudo paccache -rk1
sudo pacman -Rns $(pacman -Qdtq)
sudo journalctl --vacuum-size=200M
docker system prune -a
sudo snapper -c root list            # ¿demasiados snapshots?
sudo snapper -c root delete 10-30    # borra un rango
ncdu /                               # localizar los grandes
```

---

## 7. Docker y SQL Server

Ver también la tabla del [doc 08, sección 9](08-sql-server-y-bases-de-datos.md#9-problemas-frecuentes).

```bash
systemctl status docker
sudo systemctl restart docker
docker compose logs --tail 100 sqlserver
docker stats                         # consumo de recursos en vivo
```

### "permission denied while trying to connect to the Docker daemon socket"

No estás en el grupo `docker`, o no has vuelto a iniciar sesión desde que te añadiste.

```bash
groups                # ¿aparece "docker"?
sudo usermod -aG docker "$USER"
# cierra sesión y vuelve a entrar (o: newgrp docker)
```

### El contenedor de SQL Server se reinicia en bucle

```bash
docker compose logs sqlserver | head -40
```

Las tres causas: contraseña que no cumple la política, menos de 2 GB de RAM, o permisos del
volumen. Para la tercera:

```bash
docker compose down
docker volume rm infra_mssql-data      # ⚠️ borra los datos
docker compose up -d
```

---

## 8. Arranque dual con Windows

### Windows no aparece en el menú de arranque

systemd-boot detecta Windows automáticamente **si comparte el mismo ESP**:

```bash
ls /boot/EFI/Microsoft/Boot/bootmgfw.efi     # ¿existe?
bootctl list                                  # ¿aparece "Windows Boot Manager"?
```

Si Windows tiene su propio ESP en otra partición, monta ese ESP en `/boot` en lugar del que
creaste, o copia la carpeta `EFI/Microsoft` al tuyo.

### Las horas están desfasadas

Windows escribe la hora local en el reloj de hardware; Linux escribe UTC. Arregla en Windows
(recomendado), con `regedit`:

```
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation
  RealTimeIsUniversal (DWORD 32 bits) = 1
```

### Windows "come" la partición EFI o rompe el arranque tras actualizar

Arranca con el USB, entra al chroot y ejecuta `bootctl install`. Es un clásico.

---

## 9. Rendimiento

```bash
systemd-analyze                 # tiempo de arranque
systemd-analyze blame | head -20
systemd-analyze critical-chain

btop                            # ¿quién come CPU/RAM?
sudo iotop                      # ¿quién usa el disco? (paquete iotop)
```

### Arranque lento

`NetworkManager-wait-online.service` es el sospechoso habitual (espera hasta 90 s a tener
red):

```bash
sudo systemctl disable NetworkManager-wait-online.service
```

### El sistema se congela al compilar

Falta memoria y entra en *swap thrashing*. Instala el gestor de presión de memoria:

```bash
sudo pacman -S --needed systemd-oomd
sudo systemctl enable --now systemd-oomd
```

O limita los trabajos paralelos en `/etc/makepkg.conf`: `MAKEFLAGS="-j4"`.

---

## 10. Casos especiales de hardware

### UEFI de 32 bits (tablets antiguas)

`fw_platform_size` devuelve `32`. Necesitas un bootloader de 32 bits sobre un kernel de 64:

```bash
sudo pacman -S grub efibootmgr
sudo grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB --removable
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Arranque BIOS/Legacy (equipos pre-2012)

En lugar de systemd-boot, usa GRUB, y particiona con tabla **MBR** (`dos` en cfdisk) más una
partición `BIOS boot` de 1 MiB si usas GPT:

```bash
sudo pacman -S grub
sudo grub-install --target=i386-pc /dev/sda
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Portátil que no suspende o no despierta

```bash
cat /sys/power/mem_sleep            # [s2idle] o [deep]
# forzar "deep" (mejor ahorro) añadiendo a options del kernel:
mem_sleep_default=deep
```

---

## 11. Pedir ayuda

Cuando preguntes (en foros o a Claude Code), incluye siempre:

```bash
# Genera un informe con todo lo relevante:
{
  echo "### Sistema";      fastfetch --pipe
  echo "### Kernel";       uname -a
  echo "### Errores";      journalctl -b -p err --no-pager | tail -50
  echo "### Fallidos";     systemctl --failed --no-pager
  echo "### Discos";       lsblk -f
  echo "### Últimos paquetes"; grep -i upgraded /var/log/pacman.log | tail -20
} > /tmp/informe.txt
```

Y con Claude Code:

```bash
claude "@/tmp/informe.txt tengo este problema: <describe qué pasa y qué esperabas>"
```

### Recursos

- **Arch Wiki** — https://wiki.archlinux.org — la mejor documentación de Linux que existe
- **Arch Forums** — https://bbs.archlinux.org
- **Noticias de Arch** — https://archlinux.org/news/ — léelas antes de actualizar
- **Hyprland Wiki** — https://wiki.hyprland.org
- **r/archlinux**, **r/hyprland**

---

**Volver al** [índice](../README.md) · **Glosario** [aquí](glosario.md)
