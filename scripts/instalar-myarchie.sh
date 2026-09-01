#!/usr/bin/env bash
#
# instalar-myarchie — instalador guiado de MyArchie
#
# Automatiza los documentos 02 y 03 de la guía. Está pensado para ejecutarse
# desde el ISO en vivo de MyArchie.
#
# ⚠️ ESTE SCRIPT BORRA EL DISCO QUE ELIJAS. Lee el doc 02 antes de usarlo:
#    entender lo que hace es el objetivo del proyecto; esto es solo el atajo.
#
set -euo pipefail

C_OK=$'\e[1;32m'; C_WARN=$'\e[1;33m'; C_ERR=$'\e[1;31m'; C_INFO=$'\e[1;36m'; C_OFF=$'\e[0m'
paso()  { echo -e "\n${C_INFO}==> $*${C_OFF}"; }
ok()    { echo -e "${C_OK}  ✓ $*${C_OFF}"; }
aviso() { echo -e "${C_WARN}  ! $*${C_OFF}"; }
error() { echo -e "${C_ERR}  ✗ $*${C_OFF}" >&2; exit 1; }

[[ $EUID -eq 0 ]] || error "Ejecuta este script como root."
[[ -d /sys/firmware/efi ]] || error "No arrancaste en modo UEFI. Ver doc 12."

cat <<'BANNER'

  ███╗   ███╗██╗   ██╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗███████╗
  ████╗ ████║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║██║██╔════╝
  ██╔████╔██║ ╚████╔╝ ███████║██████╔╝██║     ███████║██║█████╗
  ██║╚██╔╝██║  ╚██╔╝  ██╔══██║██╔══██╗██║     ██╔══██║██║██╔══╝
  ██║ ╚═╝ ██║   ██║   ██║  ██║██║  ██║╚██████╗██║  ██║██║███████╗
  ╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚══════╝

BANNER

# ─────────────────────────────────────────────────────────── comprobaciones
paso "Comprobando conexión a internet"
ping -c1 -W3 archlinux.org &>/dev/null || error "Sin internet. Conecta con: iwctl"
ok "Hay conexión"

paso "Sincronizando el reloj"
timedatectl set-ntp true
ok "Reloj sincronizado"

# ─────────────────────────────────────────────────────────── datos
paso "Elige el disco de destino"
lsblk -dpno NAME,SIZE,MODEL | grep -v loop
echo
read -rp "  Disco (ej. /dev/nvme0n1): " DISK
[[ -b $DISK ]] || error "$DISK no es un dispositivo de bloque válido."

if [[ $DISK == *nvme* || $DISK == *mmcblk* ]]; then
  ESP="${DISK}p1"; ROOT="${DISK}p2"
else
  ESP="${DISK}1";  ROOT="${DISK}2"
fi

read -rp "  Nombre de la máquina [myarchie]: " HOSTNAME; HOSTNAME=${HOSTNAME:-myarchie}
read -rp "  Nombre de usuario: " USUARIO
[[ -n $USUARIO ]] || error "El usuario no puede estar vacío."
read -rp "  Zona horaria [America/Santiago]: " TZ; TZ=${TZ:-America/Santiago}
[[ -f /usr/share/zoneinfo/$TZ ]] || error "Zona horaria desconocida: $TZ"
read -rp "  Locale [es_CL.UTF-8]: " LOCALE; LOCALE=${LOCALE:-es_CL.UTF-8}
read -rp "  Keymap de consola [la-latin1]: " KEYMAP; KEYMAP=${KEYMAP:-la-latin1}
read -rp "  Tamaño del archivo swap en GiB [8]: " SWAPGB; SWAPGB=${SWAPGB:-8}

while :; do
  read -rsp "  Contraseña para root: " PASS_ROOT; echo
  read -rsp "  Repite: " PASS_ROOT2; echo
  [[ $PASS_ROOT == "$PASS_ROOT2" && -n $PASS_ROOT ]] && break
  aviso "No coinciden o están vacías."
done
while :; do
  read -rsp "  Contraseña para $USUARIO: " PASS_USER; echo
  read -rsp "  Repite: " PASS_USER2; echo
  [[ $PASS_USER == "$PASS_USER2" && -n $PASS_USER ]] && break
  aviso "No coinciden o están vacías."
done

# microcódigo
if grep -qi 'GenuineIntel' /proc/cpuinfo; then UCODE=intel-ucode; else UCODE=amd-ucode; fi
ok "Microcódigo detectado: $UCODE"

# driver de video
GPU_PKGS="mesa"
if lspci | grep -qi 'VGA.*intel\|Display.*intel'; then
  GPU_PKGS="$GPU_PKGS vulkan-intel intel-media-driver"
fi
if lspci | grep -qi 'VGA.*AMD\|VGA.*ATI'; then
  GPU_PKGS="$GPU_PKGS vulkan-radeon libva-mesa-driver"
fi
if lspci | grep -qi 'VGA.*NVIDIA\|3D.*NVIDIA'; then
  GPU_PKGS="$GPU_PKGS nvidia-open-dkms nvidia-utils egl-wayland dkms"
  aviso "GPU NVIDIA detectada: revisa el doc 03 sección 4 tras instalar."
fi
ok "Paquetes de video: $GPU_PKGS"

# ─────────────────────────────────────────────────────────── confirmación
cat <<RESUMEN

${C_WARN}────────────────────────────────────────────────────${C_OFF}
  Disco a BORRAR : $DISK
  ESP            : $ESP  (1 GiB, FAT32)
  Raíz           : $ROOT (resto, Btrfs)
  Hostname       : $HOSTNAME
  Usuario        : $USUARIO
  Zona horaria   : $TZ
  Locale         : $LOCALE
  Swap           : ${SWAPGB} GiB
${C_WARN}────────────────────────────────────────────────────${C_OFF}

${C_ERR}TODOS LOS DATOS DE $DISK SE PERDERÁN.${C_OFF}
RESUMEN

read -rp "Escribe exactamente 'BORRAR' para continuar: " CONFIRM
[[ $CONFIRM == "BORRAR" ]] || error "Cancelado por el usuario."

# ─────────────────────────────────────────────────────────── particionado
paso "Particionando $DISK"
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI System"       "$DISK"
sgdisk -n 2:0:0   -t 2:8300 -c 2:"Linux filesystem" "$DISK"
partprobe "$DISK"; sleep 2
ok "Particiones creadas"

paso "Formateando"
mkfs.fat -F32 -n ESP "$ESP"
mkfs.btrfs -f -L MYARCHIE "$ROOT"
ok "Sistemas de archivos creados"

paso "Creando subvolúmenes Btrfs"
mount "$ROOT" /mnt
for sv in @ @home @log @pkg @snapshots; do
  btrfs subvolume create "/mnt/$sv" >/dev/null
done
umount /mnt
ok "Subvolúmenes: @ @home @log @pkg @snapshots"

paso "Montando"
OPTS="noatime,compress=zstd:3,space_cache=v2"
mount -o "$OPTS,subvol=@" "$ROOT" /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots,boot}
mount -o "$OPTS,subvol=@home"      "$ROOT" /mnt/home
mount -o "$OPTS,subvol=@log"       "$ROOT" /mnt/var/log
mount -o "$OPTS,subvol=@pkg"       "$ROOT" /mnt/var/cache/pacman/pkg
mount -o "$OPTS,subvol=@snapshots" "$ROOT" /mnt/.snapshots
mount "$ESP" /mnt/boot
ok "Todo montado en /mnt"

# ─────────────────────────────────────────────────────────── mirrors
paso "Optimizando mirrors (puede tardar un minuto)"
reflector --protocol https --latest 20 --sort rate \
          --save /etc/pacman.d/mirrorlist 2>/dev/null || aviso "reflector falló; sigo con los actuales"

# ─────────────────────────────────────────────────────────── sistema base
paso "Instalando el sistema base (esto tarda varios minutos)"
# shellcheck disable=SC2086
pacstrap -K /mnt \
  base base-devel linux linux-firmware linux-headers \
  btrfs-progs snapper snap-pac \
  networkmanager \
  "$UCODE" $GPU_PKGS \
  sudo git vim nano zsh \
  man-db man-pages texinfo \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol \
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  qt5-wayland qt6-wayland polkit-gnome \
  waybar wofi dunst libnotify hyprpaper hyprlock hypridle \
  grim slurp wl-clipboard cliphist \
  thunar thunar-volman gvfs tumbler kitty sddm \
  brightnessctl playerctl network-manager-applet blueman bluez bluez-utils \
  noto-fonts noto-fonts-emoji noto-fonts-cjk \
  ttf-jetbrains-mono-nerd ttf-firacode-nerd papirus-icon-theme \
  starship zsh-completions zsh-autosuggestions zsh-syntax-highlighting \
  ripgrep fd bat eza fzf zoxide jq yq tmux btop fastfetch \
  tree unzip zip p7zip wget curl rsync openssh reflector ufw \
  pacman-contrib smartmontools ncdu power-profiles-daemon \
  git-delta lazygit github-cli neovim \
  dotnet-sdk dotnet-runtime aspnet-runtime \
  python python-pip python-virtualenv python-pipx uv ipython \
  jdk21-openjdk jdk17-openjdk maven gradle \
  php php-gd php-sqlite php-intl composer \
  nodejs npm fnm \
  docker docker-compose docker-buildx sqlite
ok "Sistema base instalado"

paso "Generando fstab"
genfstab -U /mnt >> /mnt/etc/fstab
ok "fstab generado"

# ─────────────────────────────────────────────────────────── chroot
paso "Configurando el sistema instalado"
arch-chroot /mnt /bin/bash -e <<CHROOT
set -euo pipefail

# hora y locale
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i "s/^#${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# identidad de red
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
HOSTS

# usuarios
echo "root:${PASS_ROOT}" | chpasswd
useradd -m -G wheel,docker -s /bin/zsh "$USUARIO"
echo "${USUARIO}:${PASS_USER}" | chpasswd
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel
visudo -c

# swap
btrfs subvolume create /swap
btrfs filesystem mkswapfile --size ${SWAPGB}g --uuid clear /swap/swapfile
printf '\n/swap/swapfile none swap defaults 0 0\n' >> /etc/fstab

# initramfs
sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
mkinitcpio -P

# pacman: colores y descargas paralelas
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf

# bootloader
bootctl install
ROOT_UUID=\$(findmnt -no UUID -T /)

cat > /boot/loader/loader.conf <<LOADER
default  arch.conf
timeout  3
console-mode max
editor   no
LOADER

cat > /boot/loader/entries/arch.conf <<ENTRY
title    MyArchie
linux    /vmlinuz-linux
initrd   /${UCODE}.img
initrd   /initramfs-linux.img
options  root=UUID=\${ROOT_UUID} rootflags=subvol=@ rw quiet loglevel=3
ENTRY

cat > /boot/loader/entries/arch-fallback.conf <<ENTRY
title    MyArchie (fallback)
linux    /vmlinuz-linux
initrd   /${UCODE}.img
initrd   /initramfs-linux-fallback.img
options  root=UUID=\${ROOT_UUID} rootflags=subvol=@ rw
ENTRY

mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/95-systemd-boot.hook <<HOOK
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Actualizando systemd-boot...
When = PostTransaction
Exec = /usr/bin/bootctl update
HOOK

# servicios
systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable sddm
systemctl enable docker
systemctl enable bluetooth
systemctl enable ufw
systemctl enable power-profiles-daemon
systemctl enable reflector.timer
systemctl enable paccache.timer
systemctl enable fstrim.timer

# firewall
ufw --force default deny incoming
ufw --force default allow outgoing
ufw --force enable
CHROOT
ok "Sistema configurado"

# ─────────────────────────────────────────────────────────── dotfiles
paso "Copiando la configuración del escritorio"
if [[ -d /root/.config/hypr ]]; then
  for d in hypr waybar kitty dunst; do
    [[ -d "/root/.config/$d" ]] && cp -r "/root/.config/$d" "/mnt/home/$USUARIO/.config/" 2>/dev/null || true
  done
  mkdir -p "/mnt/home/$USUARIO/.config"
  [[ -f /root/.zshrc ]] && cp /root/.zshrc "/mnt/home/$USUARIO/.zshrc"
  [[ -f /root/.config/starship.toml ]] && cp /root/.config/starship.toml "/mnt/home/$USUARIO/.config/"
  arch-chroot /mnt chown -R "$USUARIO:$USUARIO" "/home/$USUARIO"
  ok "Dotfiles copiados"
else
  aviso "No encontré dotfiles en /root/.config; los copiarás tú después."
fi

paso "Copiando la documentación de MyArchie"
if [[ -d /root/myarchie ]]; then
  cp -r /root/myarchie "/mnt/home/$USUARIO/MyArchie"
  cp /usr/local/bin/postinstalacion-myarchie /mnt/usr/local/bin/ 2>/dev/null || true
  arch-chroot /mnt chown -R "$USUARIO:$USUARIO" "/home/$USUARIO/MyArchie"
  ok "Docs en /home/$USUARIO/MyArchie"
fi

# ─────────────────────────────────────────────────────────── fin
paso "Desmontando"
swapoff -a 2>/dev/null || true
umount -R /mnt
ok "Desmontado"

cat <<FIN

${C_OK}════════════════════════════════════════════════════${C_OFF}
  ${C_OK}Instalación completada.${C_OFF}

  1. Apaga:            ${C_INFO}poweroff${C_OFF}
  2. Quita el USB
  3. Enciende e inicia sesión como '${USUARIO}'
  4. Ejecuta:          ${C_INFO}postinstalacion-myarchie${C_OFF}
     (instala paru, temas Catppuccin, Claude Code y VS Code)

  Documentación en:    ~/MyArchie/docs/
${C_OK}════════════════════════════════════════════════════${C_OFF}

FIN
