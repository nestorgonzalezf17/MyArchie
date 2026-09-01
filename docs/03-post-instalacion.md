# 03 — Post-instalación: dejar el sistema usable

> Objetivo: audio, AUR, drivers de video, firewall, y las bases para el escritorio.
> Todo esto ya se hace **desde tu sistema instalado**, con tu usuario y `sudo`.

---

## 1. Primera actualización

```bash
sudo pacman -Syu
```

- `-S` sincronizar/instalar, `-y` refrescar la base de datos de paquetes, `-u` actualizar
  todo lo instalado.

⚠️ **Nunca uses `pacman -Sy paquete` a secas.** Eso refresca la base de datos pero instala
solo un paquete, dejando tu sistema en un estado mixto ("partial upgrade") que rompe
librerías. La regla es: **siempre `-Syu`**, o `-S` sin `-y`.

## 2. Optimizar pacman (calidad de vida)

```bash
sudo nano /etc/pacman.conf
```

Descomenta / añade en la sección `[options]`:

```
Color
ILoveCandy
VerbosePkgLists
ParallelDownloads = 5
```

`ParallelDownloads` baja 5 paquetes a la vez: la actualización va mucho más rápido.
`ILoveCandy` convierte la barra de progreso en un Pac-Man (sí, es lo único que hace).

Y mantén los mirrors frescos automáticamente:

```bash
sudo pacman -S --needed reflector
sudo systemctl enable --now reflector.timer
```

## 3. Audio: PipeWire

```bash
sudo pacman -S --needed pipewire pipewire-alsa pipewire-pulse pipewire-jack \
                        wireplumber pavucontrol
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

💡 PipeWire es el servidor de audio moderno de Linux; reemplaza a PulseAudio y JACK a la vez.
`wireplumber` es el gestor de sesión (decide qué app va a qué salida). `pavucontrol` es la
GUI para elegir dispositivos y volúmenes por aplicación.

Prueba: `speaker-test -c2 -twav` (`Ctrl+C` para parar).

## 4. Drivers de video

Identifica tu GPU:

```bash
lspci -k | grep -EA3 'VGA|3D|Display'
```

### Intel (integrada)

```bash
sudo pacman -S --needed mesa vulkan-intel intel-media-driver libva-utils
```

### AMD

```bash
sudo pacman -S --needed mesa vulkan-radeon libva-mesa-driver
```

### NVIDIA

```bash
sudo pacman -S --needed nvidia-open-dkms nvidia-utils nvidia-settings \
                        libva-nvidia-driver egl-wayland dkms
```

Y añade estos parámetros al kernel para que Wayland funcione bien. Edita
`/boot/loader/entries/arch.conf` y agrega al final de la línea `options`:

```
nvidia_drm.modeset=1 nvidia_drm.fbdev=1
```

Además, en `/etc/mkinitcpio.conf` añade los módulos:

```
MODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

y regenera: `sudo mkinitcpio -P`.

> ⚠️ NVIDIA + Wayland + Hyprland funciona bien hoy, pero es la combinación con más aristas.
> Si tienes una GPU NVIDIA muy antigua (serie 700 o anterior), considera usar el driver
> `nouveau` (libre, ya incluido en `mesa`) o un escritorio X11 como KDE.

### Máquina virtual

```bash
# VirtualBox
sudo pacman -S --needed virtualbox-guest-utils
sudo systemctl enable --now vboxservice

# QEMU/KVM
sudo pacman -S --needed spice-vdagent qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

## 5. El AUR y `paru`

💡 **Qué es el AUR.** Los repositorios oficiales de Arch (`core`, `extra`) tienen ~14.000
paquetes. El *Arch User Repository* tiene ~90.000 más, mantenidos por la comunidad. No
contiene binarios, sino **recetas** (`PKGBUILD`) que tu máquina compila.

⚠️ **El AUR no está auditado.** Un PKGBUILD es un script que corre en tu máquina. Instala
solo paquetes conocidos y **lee el PKGBUILD** cuando `paru` te lo muestre.

Instalar `paru` (irónicamente, desde el AUR a mano — es la única vez que lo harás así):

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
cd /tmp/paru-bin
makepkg -si
cd ~ && rm -rf /tmp/paru-bin
```

Qué hace `makepkg -si`: `-s` instala las dependencias que falten, `-i` instala el paquete
resultante.

Uso diario:

```bash
paru -S <paquete>        # instalar (busca en repos oficiales y AUR)
paru                     # actualizar TODO: repos oficiales + AUR
paru -Ss <texto>         # buscar
```

## 6. Firewall

```bash
sudo pacman -S --needed ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable --now ufw
sudo ufw status verbose
```

Esto bloquea todo lo que entra y permite todo lo que sale — lo correcto para un portátil.
Cuando levantes un servidor de desarrollo y quieras que otro dispositivo de tu red lo vea:

```bash
sudo ufw allow 5000/tcp comment 'API .NET dev'
sudo ufw delete allow 5000/tcp   # para quitarlo después
```

⚠️ No abras el puerto de SQL Server (1433) hacia la red sin saber lo que haces.

## 7. Fuentes

Sin esto verás cuadraditos (□□□) en lugar de iconos y emojis.

```bash
sudo pacman -S --needed \
  noto-fonts noto-fonts-emoji noto-fonts-cjk \
  ttf-jetbrains-mono-nerd ttf-firacode-nerd \
  ttf-liberation ttf-dejavu
```

💡 Las fuentes "Nerd" son fuentes normales con miles de iconos añadidos (logos de lenguajes,
ramas de Git, flechitas). Waybar y Starship los usan; sin una Nerd Font todo se ve roto.

## 8. Bluetooth (si aplica)

```bash
sudo pacman -S --needed bluez bluez-utils blueman
sudo systemctl enable --now bluetooth
```

`blueman-manager` da la interfaz gráfica.

## 9. Portátiles: energía y suspensión

```bash
sudo pacman -S --needed power-profiles-daemon brightnessctl acpi
sudo systemctl enable --now power-profiles-daemon

# ver perfiles disponibles
powerprofilesctl list
powerprofilesctl set balanced
```

Y desactiva el `wpa_supplicant` de ahorro agresivo si el Wi-Fi se corta:

```bash
sudo nano /etc/NetworkManager/conf.d/wifi-powersave.conf
```
```
[connection]
wifi.powersave = 2
```

## 10. Utilidades de línea de comandos que vas a usar todos los días

```bash
sudo pacman -S --needed \
  htop btop \
  fastfetch \
  ripgrep fd bat eza fzf zoxide \
  tree unzip zip p7zip \
  wget curl rsync \
  jq yq \
  openssh \
  tmux \
  less which usbutils
```

| Herramienta | Reemplaza a | Qué hace |
|---|---|---|
| `btop` | `top` | Monitor de recursos bonito e interactivo |
| `ripgrep` (`rg`) | `grep -r` | Buscar texto en archivos, ~10x más rápido |
| `fd` | `find` | Buscar archivos con sintaxis humana |
| `bat` | `cat` | `cat` con colores y números de línea |
| `eza` | `ls` | `ls` con iconos y colores |
| `fzf` | — | Buscador difuso interactivo (`Ctrl+R` en el historial) |
| `zoxide` | `cd` | `cd` que aprende: `z proy` te lleva a `~/dev/mi-proyecto` |
| `jq` | — | Leer y transformar JSON en la terminal |

## 11. Snapshots automáticos (tu red de seguridad)

Configúralo **ahora**, antes de instalar el escritorio, para tener un punto de retorno limpio.

```bash
sudo pacman -S --needed snapper snap-pac
```

`snap-pac` hace un snapshot automático **antes y después de cada operación de pacman**.

```bash
# snapper se queja si /.snapshots ya existe: lo desmontamos, dejamos que lo cree, y lo restauramos
sudo umount /.snapshots
sudo rm -rf /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots
```

Ajusta la retención:

```bash
sudo snapper -c root set-config \
  TIMELINE_CREATE=yes TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
  TIMELINE_LIMIT_WEEKLY=4 TIMELINE_LIMIT_MONTHLY=2 TIMELINE_LIMIT_YEARLY=0

sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

Comprueba:

```bash
sudo snapper -c root list
sudo snapper -c root create --description "sistema base limpio"
```

El detalle de **cómo restaurar** está en [doc 10](10-mantenimiento-y-snapshots.md).

---

## Checklist

- [ ] `sudo pacman -Syu` termina sin errores
- [ ] Suena el audio (`speaker-test -c2 -twav`)
- [ ] `paru -Ss hyprland` devuelve resultados
- [ ] `sudo ufw status` dice "active"
- [ ] `sudo snapper -c root list` muestra al menos un snapshot

---

**Siguiente:** [04 — Entorno gráfico: Hyprland](04-entorno-grafico-hyprland.md)
