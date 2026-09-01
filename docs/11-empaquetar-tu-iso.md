# 11 — Empaquetar tu propia ISO: nace MyArchie

> Objetivo: convertir todo lo que construiste en una **ISO instalable**. Este es el paso que
> hace que tu configuración deje de ser "mi Arch" y pase a ser una distribución.

---

## 1. Qué es `archiso`

`archiso` es la herramienta oficial con la que el propio equipo de Arch construye el ISO que
descargaste en el doc 01. Le das:

- una **lista de paquetes** (`packages.x86_64`),
- un **árbol de archivos** que se copia dentro del sistema (`airootfs/`),
- una **configuración de arranque** (`efiboot/`, `syslinux/`),
- un **perfil** (`profiledef.sh`) que define el nombre y el tipo de imagen,

y te devuelve un `.iso` booteable.

### Dos tipos de perfil

| Perfil | Qué es |
|---|---|
| `releng` | El ISO oficial: un entorno *live* de instalación. Arrancas, instalas a mano. |
| `baseline` | Un ISO mínimo, base para construir el tuyo desde cero. |

Partiremos de `releng`, porque queremos un live funcional (con red, drivers y tu escritorio)
del que además se pueda instalar.

## 2. Dos estrategias (elige una)

### Estrategia A — ISO live "showcase" + script de instalación *(recomendada)*

La ISO arranca directamente en tu Hyprland con tu tema, y trae un script `instalar-myarchie`
que reproduce los docs 02-08 automáticamente sobre el disco destino.

- ✅ Más simple de construir y mantener.
- ✅ La ISO sirve también como sistema de rescate usable.
- ✅ La instalación siempre baja paquetes frescos.
- ❌ La instalación necesita internet y tarda lo que tarde la descarga.

### Estrategia B — ISO con instalador por imagen

La ISO lleva un sistema completo comprimido que se vuelca al disco.

- ✅ Instalación en 3 minutos, sin internet.
- ❌ Mucho más compleja (hay que manejar UUIDs, `machine-id`, expansión de particiones).
- ❌ La ISO pesa varios GB.

**Vamos con la A.**

## 3. Preparar el entorno

```bash
sudo pacman -S --needed archiso git

mkdir -p ~/myarchie-iso
cp -r /usr/share/archiso/configs/releng ~/myarchie-iso/profile
cd ~/myarchie-iso/profile
ls
```

Verás:

```
airootfs/          Todo lo que hay aquí aparece en / dentro del ISO
efiboot/           Config de arranque UEFI
syslinux/          Config de arranque BIOS
grub/              Menú GRUB del ISO
packages.x86_64    La lista de paquetes que irán en el ISO
pacman.conf        Config de pacman usada al construir
profiledef.sh      Nombre, versión, tipo de imagen, permisos de archivos
```

## 4. Identidad de tu distro (`profiledef.sh`)

```bash
nano profiledef.sh
```

Cambia estas líneas:

```bash
iso_name="myarchie"
iso_label="MYARCHIE_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Nestor Gonzalez <nestorgonzalezf17@gmail.com>"
iso_application="MyArchie Live/Install Medium"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
```

⚠️ `iso_label` **debe estar en mayúsculas y sin guiones**: es la etiqueta FAT32 con la que el
kernel encuentra el ISO al arrancar. Si la cambias mal, el ISO no bootea.

## 5. La lista de paquetes

```bash
nano packages.x86_64
```

Al final del archivo (después de los que ya trae `releng`), añade tu stack:

```
# ── Escritorio ────────────────────────────
hyprland
xdg-desktop-portal-hyprland
xdg-desktop-portal-gtk
waybar
wofi
dunst
libnotify
hyprpaper
hyprlock
hypridle
polkit-gnome
qt5-wayland
qt6-wayland
grim
slurp
wl-clipboard
cliphist
thunar
thunar-volman
gvfs
tumbler
kitty
sddm
brightnessctl
playerctl
network-manager-applet
blueman

# ── Audio ─────────────────────────────────
pipewire
pipewire-alsa
pipewire-pulse
pipewire-jack
wireplumber
pavucontrol

# ── Fuentes y temas ───────────────────────
noto-fonts
noto-fonts-emoji
noto-fonts-cjk
ttf-jetbrains-mono-nerd
ttf-firacode-nerd
papirus-icon-theme

# ── Shell y CLI ───────────────────────────
zsh
zsh-completions
zsh-autosuggestions
zsh-syntax-highlighting
starship
git
git-delta
lazygit
github-cli
neovim
tmux
btop
fastfetch
ripgrep
fd
bat
eza
fzf
zoxide
jq
yq
rsync
wget
unzip
p7zip
tree
man-db
man-pages

# ── Desarrollo ────────────────────────────
dotnet-sdk
dotnet-runtime
aspnet-runtime
python
python-pip
python-virtualenv
python-pipx
uv
ipython
jdk21-openjdk
jdk17-openjdk
maven
gradle
php
php-gd
php-sqlite
php-intl
composer
nodejs
npm
fnm
docker
docker-compose
docker-buildx
sqlite

# ── Sistema ───────────────────────────────
networkmanager
btrfs-progs
snapper
snap-pac
reflector
ufw
sudo
base-devel
linux-headers
pacman-contrib
smartmontools
ncdu
power-profiles-daemon
bluez
bluez-utils
intel-ucode
amd-ucode
```

💡 Metemos **`intel-ucode` y `amd-ucode`**: el ISO debe funcionar en cualquier máquina, y el
instalador elegirá el correcto.

⚠️ **`archiso` solo instala desde los repositorios oficiales.** Los paquetes del AUR
(`paru`, `visual-studio-code-bin`, temas Catppuccin...) **no** pueden ir en esta lista. Se
instalan después del primer arranque, con el script de la sección 8.

## 6. Meter tu configuración en la ISO (`airootfs/`)

Todo lo que pongas en `airootfs/` aparece en `/` dentro del ISO.

### 6.1 Los dotfiles del usuario live

El ISO de Arch usa el usuario `root` con home en `/root`.

```bash
cd ~/myarchie-iso/profile

mkdir -p airootfs/root/.config
cp -r ~/dotfiles/hypr    airootfs/root/.config/
cp -r ~/dotfiles/waybar  airootfs/root/.config/
cp -r ~/dotfiles/kitty   airootfs/root/.config/
cp -r ~/dotfiles/dunst   airootfs/root/.config/
cp ~/.zshrc              airootfs/root/.zshrc
cp ~/.config/starship.toml airootfs/root/.config/
```

Y un "esqueleto" para los usuarios que se creen después:

```bash
mkdir -p airootfs/etc/skel/.config
cp -r airootfs/root/.config/* airootfs/etc/skel/.config/
cp airootfs/root/.zshrc airootfs/etc/skel/.zshrc
```

💡 `/etc/skel` es la plantilla que se copia al home de cada usuario nuevo. Es la forma
correcta de que tu escritorio esté configurado para todos.

### 6.2 Los archivos de tu distro

```bash
mkdir -p airootfs/root/myarchie
cp -r ~/MyArchie/docs    airootfs/root/myarchie/
cp -r ~/MyArchie/scripts airootfs/root/myarchie/
cp    ~/MyArchie/README.md airootfs/root/myarchie/

cat > airootfs/etc/motd <<'MOTD'

  ███╗   ███╗██╗   ██╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗███████╗
  ████╗ ████║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║██║██╔════╝
  ██╔████╔██║ ╚████╔╝ ███████║██████╔╝██║     ███████║██║█████╗
  ██║╚██╔╝██║  ╚██╔╝  ██╔══██║██╔══██╗██║     ██╔══██║██║██╔══╝
  ██║ ╚═╝ ██║   ██║   ██║  ██║██║  ██║╚██████╗██║  ██║██║███████╗
  ╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚══════╝

  Distro de desarrollo · Arch Linux

  · Instalar en disco :  instalar-myarchie
  · Documentación     :  /root/myarchie/docs/
  · Iniciar escritorio:  Hyprland
  · Conectar Wi-Fi    :  iwctl  →  station wlan0 connect "TuRed"

MOTD
```

### 6.3 Servicios activos en la ISO

En `airootfs/etc/systemd/system/` se crean los enlaces simbólicos que `systemctl enable`
haría. El perfil `releng` ya trae varios; añade los tuyos:

```bash
cd ~/myarchie-iso/profile/airootfs/etc/systemd/system

# NetworkManager (releng usa systemd-networkd; lo cambiamos)
mkdir -p multi-user.target.wants
ln -sf /usr/lib/systemd/system/NetworkManager.service multi-user.target.wants/
ln -sf /usr/lib/systemd/system/NetworkManager-wait-online.service multi-user.target.wants/

cd ~/myarchie-iso/profile
```

⚠️ Si activas NetworkManager, **desactiva** los servicios de red que trae `releng` para que
no compitan: borra los enlaces de `systemd-networkd.service` y `systemd-resolved.service` en
`airootfs/etc/systemd/system/`.

Si quieres que la ISO arranque **directo al escritorio**, activa SDDM con autologin:

```bash
mkdir -p airootfs/etc/sddm.conf.d
cat > airootfs/etc/sddm.conf.d/autologin.conf <<'CONF'
[Autologin]
User=root
Session=hyprland
CONF

ln -sf /usr/lib/systemd/system/sddm.service airootfs/etc/systemd/system/display-manager.service
```

### 6.4 Configuración del sistema en la ISO

```bash
mkdir -p airootfs/etc

echo 'KEYMAP=la-latin1' > airootfs/etc/vconsole.conf
echo 'myarchie' > airootfs/etc/hostname

# pacman con colores y descargas en paralelo, también en el live
sed -i 's/^#Color/Color/;s/^#ParallelDownloads.*/ParallelDownloads = 5/' pacman.conf
```

## 7. El script de instalación

Este es el corazón de tu distro: automatiza los docs 02-03. Está completo en
[`scripts/instalar-myarchie.sh`](../scripts/instalar-myarchie.sh). Cópialo al ISO:

```bash
mkdir -p airootfs/usr/local/bin
cp ~/MyArchie/scripts/instalar-myarchie.sh airootfs/usr/local/bin/instalar-myarchie
```

Y dale permisos de ejecución. ⚠️ Los permisos **no** se heredan del sistema de archivos: hay
que declararlos en `profiledef.sh`, en el array `file_permissions`:

```bash
nano profiledef.sh
```

Añade dentro de `file_permissions=(...)`:

```bash
  ["/usr/local/bin/instalar-myarchie"]="0:0:755"
  ["/root"]="0:0:750"
  ["/root/.config"]="0:0:700"
  ["/root/myarchie"]="0:0:755"
  ["/usr/local/bin/postinstalacion-myarchie"]="0:0:755"
```

El formato es `["ruta"]="uid:gid:modo"`.

💡 Este es el error más común al usar archiso: copias un script, construyes el ISO, arrancas
y "command not found" o "permission denied". Es porque olvidaste `file_permissions`.

## 8. El script de post-instalación (para el AUR y los temas)

Como el AUR no cabe en el ISO, dejamos un script que el usuario ejecuta tras el primer
arranque. Está en [`scripts/postinstalacion-myarchie.sh`](../scripts/postinstalacion-myarchie.sh):

```bash
cp ~/MyArchie/scripts/postinstalacion-myarchie.sh \
   airootfs/usr/local/bin/postinstalacion-myarchie
```

Instala `paru`, los temas Catppuccin, Claude Code, VS Code y los drivers del AUR que hagan
falta.

## 9. Construir la ISO

```bash
cd ~/myarchie-iso
mkdir -p out work

sudo mkarchiso -v -w work -o out profile
```

- `-v` verboso (querrás verlo la primera vez).
- `-w work` directorio de trabajo temporal.
- `-o out` dónde dejar el `.iso`.

⏱️ Tarda entre 15 y 45 minutos y descarga varios GB. Necesitas ~20 GB libres.

Al terminar:

```bash
ls -lh out/
# myarchie-2026.09.01-x86_64.iso
```

🎉 **Esa es tu distro.**

⚠️ Si repites la construcción, **borra `work/` primero** (`sudo rm -rf work/`): archiso no
limpia bien y reutilizar el directorio da errores incomprensibles.

## 10. Probar la ISO (antes de grabarla a un USB)

```bash
sudo pacman -S --needed qemu-full edk2-ovmf

# Arranque UEFI, que es como la vas a usar
qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 4 \
  -bios /usr/share/edk2/x64/OVMF.4m.fd \
  -cdrom out/myarchie-*.iso \
  -boot d \
  -vga virtio -display gtk,gl=on
```

O más simple, con el runner de archiso:

```bash
run_archiso -u -i out/myarchie-*.iso     # -u = modo UEFI
```

**Qué probar:**
- [ ] Arranca en UEFI y en BIOS
- [ ] Hay red (`ping archlinux.org`)
- [ ] Hyprland inicia y se ve con tu tema
- [ ] `instalar-myarchie` arranca y llega hasta el final
- [ ] El sistema instalado arranca desde el disco virtual

Para probar la **instalación**, añade un disco a QEMU:

```bash
qemu-img create -f qcow2 /tmp/prueba.qcow2 60G
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \
  -bios /usr/share/edk2/x64/OVMF.4m.fd \
  -drive file=/tmp/prueba.qcow2,format=qcow2 \
  -cdrom out/myarchie-*.iso -boot d
```

## 11. Grabar y distribuir

```bash
sudo dd if=out/myarchie-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Y publica el checksum para que otros verifiquen:

```bash
cd out
sha256sum myarchie-*.iso > myarchie.iso.sha256
b2sum myarchie-*.iso > myarchie.iso.b2
```

## 12. Versionar el perfil de la ISO

⚠️ **No metas la ISO ni `work/` en Git** (son gigas). Versiona solo el perfil:

```bash
cd ~/myarchie-iso
cat > .gitignore <<'GI'
work/
out/
*.iso
*.sha256
GI

git init && git add -A
git commit -m "perfil archiso de MyArchie v1"
```

Ahora tu distro entera es reproducible: quien clone el repo y ejecute `mkarchiso` obtiene
exactamente tu ISO.

## 13. Automatizar la construcción

Un script de conveniencia:

```bash
cat > ~/myarchie-iso/construir.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Limpiando build anterior"
sudo rm -rf work

echo "==> Construyendo MyArchie ISO"
sudo mkarchiso -v -w work -o out profile

ISO=$(ls -t out/*.iso | head -1)
echo "==> Calculando checksum"
sha256sum "$ISO" | tee "${ISO}.sha256"

echo "==> Listo: $ISO ($(du -h "$ISO" | cut -f1))"
echo "    Probar con: run_archiso -u -i $ISO"
SH
chmod +x ~/myarchie-iso/construir.sh
```

### Construcción automática en GitHub Actions (opcional)

`.github/workflows/build-iso.yml`:

```yaml
name: Construir ISO
on:
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: archlinux:latest
      options: --privileged
    steps:
      - uses: actions/checkout@v4
      - name: Instalar archiso
        run: pacman -Syu --noconfirm archiso
      - name: Construir
        run: mkarchiso -v -w /tmp/work -o out profile
      - uses: actions/upload-artifact@v4
        with:
          name: myarchie-iso
          path: out/*.iso
```

## 14. Problemas comunes de archiso

| Síntoma | Causa |
|---|---|
| `Failed to prepare transaction: package not found` | Un paquete de `packages.x86_64` no existe en los repos oficiales (¿es del AUR?, ¿escribiste mal el nombre?). |
| El ISO arranca pero cae a un shell de emergencia | `iso_label` mal escrito, o el disco no fue reconocido. |
| `command not found` con tu script | Falta la entrada en `file_permissions` de `profiledef.sh`. |
| Errores raros al reconstruir | No borraste `work/`. `sudo rm -rf work`. |
| El ISO pesa 5 GB | Normal con .NET + JDKs. Reduce quitando `jdk17-openjdk` o `gradle` si no los usas. |
| `mkarchiso` se queda sin espacio | Necesita ~3x el tamaño final. Libera disco o mueve `work/` a otra partición. |

---

## Checklist final

- [ ] `mkarchiso` termina sin errores y produce un `.iso`
- [ ] La ISO arranca en QEMU en modo UEFI
- [ ] Hyprland se ve con mi tema dentro del live
- [ ] `instalar-myarchie` instala un sistema que arranca
- [ ] El perfil está versionado en Git (sin la ISO)
- [ ] Publiqué el checksum

**Ya tienes tu propia distribución de Linux.** 🎉

---

**Siguiente:** [12 — Solución de problemas](12-solucion-de-problemas.md)
