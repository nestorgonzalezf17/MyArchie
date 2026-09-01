# 01 — Preparar el USB y entrar al instalador

> Objetivo: arrancar tu máquina con el ISO oficial de Arch y llegar a un prompt
> `root@archiso ~ #` con internet funcionando.

---

## 1. Descargar el ISO

Ve a https://archlinux.org/download/ y descarga `archlinux-x86_64.iso` (elige un mirror
cercano, o usa el torrent que suele ser más rápido).

### Verifica que no esté corrupto (importante)

Descarga también el archivo de firma `.iso.sig` de la misma página y verifica:

```bash
# En Linux/macOS
sha256sum archlinux-x86_64.iso     # compara con el hash publicado en la web
gpg --keyserver-options auto-key-retrieve --verify archlinux-x86_64.iso.sig
```

En Windows (PowerShell):

```powershell
Get-FileHash .\archlinux-x86_64.iso -Algorithm SHA256
```

💡 *Por qué:* un ISO corrupto produce errores aleatorios e incomprensibles a mitad de la
instalación. Cinco segundos de verificación te ahorran una tarde.

## 2. Grabar el ISO al USB

⚠️ **Esto borra el USB por completo.**

### Opción A — Linux (recomendada, `dd`)

Primero identifica tu USB. Conéctalo y ejecuta:

```bash
lsblk -o NAME,SIZE,MODEL,TRAN
```

Busca el dispositivo cuyo tamaño coincida con tu USB y cuyo `TRAN` sea `usb`. Digamos que
es `/dev/sdb`. **Verifica dos veces**: si escribes en el disco equivocado, pierdes tus datos.

```bash
sudo dd if=archlinux-x86_64.iso of=/dev/sdb bs=4M status=progress oflag=sync
```

- `if=` *input file*, el ISO. `of=` *output file*, el USB **completo** (`/dev/sdb`, no `/dev/sdb1`).
- `bs=4M` escribe en bloques de 4 MB (más rápido).
- `oflag=sync` obliga a vaciar el búfer, para que al terminar el comando el USB esté
  realmente escrito.

### Opción B — Windows / macOS

Usa [Rufus](https://rufus.ie) (Windows) o [balenaEtcher](https://etcher.balena.io)
(multiplataforma). En Rufus: selecciona el ISO, esquema de partición **GPT**, sistema destino
**UEFI**, y si pregunta, elige el modo **DD image**.

## 3. Entrar al firmware (BIOS/UEFI)

Reinicia y pulsa repetidamente la tecla del fabricante nada más encender:

| Marca | Tecla |
|---|---|
| Dell | `F2` (setup) / `F12` (menú de arranque) |
| HP | `Esc` o `F10` |
| Lenovo / ThinkPad | `F1` o `F2`, algunos con botón Novo |
| ASUS | `Del` o `F2` |
| Acer | `F2` |
| MSI | `Del` |
| Placa genérica | `Del` |

### Ajustes que debes cambiar

1. **Secure Boot → Disabled.** El ISO de Arch no está firmado con las claves de Microsoft.
   (Se puede habilitar después con claves propias; queda fuera del alcance de esta guía.)
2. **Boot Mode → UEFI** (no "Legacy" ni "CSM"). Esta guía asume UEFI.
3. **Fast Boot → Disabled**, si existe. Impide entrar al menú de arranque.
4. Si vienes de Windows: **desactiva Fast Startup en Windows**
   (Panel de Control → Opciones de energía → Elegir el comportamiento del botón de inicio →
   desmarcar "Activar inicio rápido"). Si no, Windows deja el disco "bloqueado" y Linux no
   podrá montarlo.
5. Si tienes RAID/Intel RST: cambia el modo SATA a **AHCI**. Con RST, Linux no ve el disco.
   ⚠️ Si Windows ya está instalado en modo RST, cambiar esto lo dejará sin arrancar hasta que
   lo repares. Investiga antes si vas a hacer arranque dual.

Guarda y sal (normalmente `F10`), con el USB conectado. Elige el USB en el menú de arranque.

## 4. Primeros pasos dentro del ISO

Verás un menú; elige **"Arch Linux install medium (x86_64, UEFI)"**. Tras unos segundos
llegas a:

```
root@archiso ~ #
```

Ya estás en un Linux completo funcionando en RAM. Nada se ha tocado en tu disco todavía.

### 4.1 Teclado en español

```bash
loadkeys la-latin1     # teclado latinoamericano
# loadkeys es          # teclado de España
```

Prueba escribiendo `ñ` y `-`. Si salen mal, prueba el otro layout.

### 4.2 Confirmar que arrancaste en UEFI

```bash
cat /sys/firmware/efi/fw_platform_size
```

- Devuelve `64` → perfecto, UEFI de 64 bits. Continúa.
- Devuelve `32` → UEFI de 32 bits (tablets antiguas). Requiere pasos extra, ve al doc 12.
- Dice "No existe el archivo" → arrancaste en **modo BIOS/Legacy**. Vuelve al firmware y
  corrígelo, o sigue la variante BIOS del doc 12.

### 4.3 Conectar a internet

**Cable Ethernet:** ya debería funcionar. Compruébalo:

```bash
ping -c 3 archlinux.org
```

**Wi-Fi:** el ISO trae `iwctl`:

```bash
iwctl
```

Dentro del prompt `[iwd]#`:

```
device list                                  # anota el nombre, normalmente wlan0
station wlan0 scan
station wlan0 get-networks                   # lista de redes
station wlan0 connect "Nombre De Tu Red"     # pedirá la contraseña
exit
```

Verifica:

```bash
ping -c 3 archlinux.org
```

💡 Si `ping` falla pero la conexión parece establecida, casi siempre es DNS. Prueba
`ping -c 3 1.1.1.1`: si eso sí responde, edita `/etc/resolv.conf` y añade
`nameserver 1.1.1.1`.

### 4.4 Sincronizar el reloj

```bash
timedatectl set-ntp true
timedatectl status      # debe decir "System clock synchronized: yes"
```

💡 *Por qué:* si el reloj está mal, las firmas criptográficas de los paquetes se consideran
inválidas ("signature is from the future") y `pacstrap` fallará.

### 4.5 (Opcional pero muy útil) Trabajar por SSH desde otra máquina

Copiar y pegar comandos largos en una consola sin ratón es doloroso. Si tienes otra
computadora en la misma red, puedes controlar el instalador desde ella:

```bash
# En el ISO de Arch:
passwd                       # pon una contraseña temporal a root
systemctl start sshd
ip -brief address            # anota la IP, por ejemplo 192.168.1.50
```

Desde la otra máquina:

```bash
ssh root@192.168.1.50
```

Ahora puedes pegar comandos directamente. Muy recomendado.

---

## Checklist antes de continuar

- [ ] Estoy en el prompt `root@archiso`
- [ ] `cat /sys/firmware/efi/fw_platform_size` devuelve `64`
- [ ] `ping -c 3 archlinux.org` responde
- [ ] `timedatectl status` dice sincronizado
- [ ] Mi teclado escribe `ñ` correctamente

---

**Siguiente:** [02 — Instalación base manual](02-instalacion-base-manual.md)
