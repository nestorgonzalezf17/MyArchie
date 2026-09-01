#!/usr/bin/env bash
#
# postinstalacion-myarchie — se ejecuta como TU USUARIO tras el primer arranque.
# Instala lo que no cabe en la ISO: paquetes del AUR, temas y Claude Code.
#
set -euo pipefail

C_OK=$'\e[1;32m'; C_INFO=$'\e[1;36m'; C_WARN=$'\e[1;33m'; C_OFF=$'\e[0m'
paso() { echo -e "\n${C_INFO}==> $*${C_OFF}"; }
ok()   { echo -e "${C_OK}  ✓ $*${C_OFF}"; }
aviso(){ echo -e "${C_WARN}  ! $*${C_OFF}"; }

[[ $EUID -ne 0 ]] || { echo "No ejecutes esto como root. Usa tu usuario normal."; exit 1; }

paso "Actualizando el sistema"
sudo pacman -Syu --noconfirm

# ─────────────────────────────────────────────────────── paru
if ! command -v paru &>/dev/null; then
  paso "Instalando paru (ayudante del AUR)"
  tmp=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  ok "paru instalado"
else
  ok "paru ya estaba instalado"
fi

# ─────────────────────────────────────────────────────── temas
paso "Instalando temas (Catppuccin Mocha)"
paru -S --needed --noconfirm \
  catppuccin-gtk-theme-mocha \
  catppuccin-cursors-mocha \
  || aviso "Algún tema falló; instálalo a mano después."

paso "Aplicando el tema"
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cat > ~/.config/gtk-3.0/settings.ini <<'INI'
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=catppuccin-mocha-blue-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
INI
cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-blue-cursors' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
fi
ok "Tema aplicado"

# ─────────────────────────────────────────────────────── Node y Claude Code
paso "Configurando Node.js (fnm)"
if command -v fnm &>/dev/null; then
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default lts-latest
  ok "Node $(node --version 2>/dev/null || echo '?') listo"
fi

paso "Instalando Claude Code"
if command -v claude &>/dev/null; then
  ok "Claude Code ya estaba instalado"
else
  if curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh; then
    bash /tmp/claude-install.sh && ok "Claude Code instalado" \
      || aviso "El instalador falló. Alternativa: npm install -g @anthropic-ai/claude-code"
    rm -f /tmp/claude-install.sh
  else
    aviso "No pude descargar el instalador. Instálalo a mano (doc 06)."
  fi
fi

# ─────────────────────────────────────────────────────── herramientas del AUR
paso "Instalando herramientas de desarrollo del AUR"
paru -S --needed --noconfirm \
  visual-studio-code-bin \
  azuredatastudio-bin \
  || aviso "Alguna app falló; revisa el error e instálala a mano."

paso "Instalando cliente de SQL Server"
paru -S --needed --noconfirm msodbcsql18 mssql-tools18 \
  || aviso "msodbcsql18 falló; ver doc 08."

if ! grep -q 'mssql-tools18' ~/.zshrc 2>/dev/null; then
  echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.zshrc
fi

# ─────────────────────────────────────────────────────── snapper
paso "Configurando snapshots (snapper)"
if ! sudo snapper -c root get-config &>/dev/null; then
  sudo umount /.snapshots 2>/dev/null || true
  sudo rm -rf /.snapshots
  sudo snapper -c root create-config /
  sudo btrfs subvolume delete /.snapshots
  sudo mkdir /.snapshots
  sudo mount -a
  sudo chmod 750 /.snapshots
  sudo snapper -c root set-config \
    TIMELINE_CREATE=yes TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
    TIMELINE_LIMIT_WEEKLY=4 TIMELINE_LIMIT_MONTHLY=2 TIMELINE_LIMIT_YEARLY=0
  sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
  ok "Snapper configurado"
else
  ok "Snapper ya estaba configurado"
fi
sudo snapper -c root create --description "sistema recién instalado" || true

# ─────────────────────────────────────────────────────── entorno de trabajo
paso "Preparando el entorno de desarrollo"
mkdir -p ~/dev/infra/backups ~/Imágenes/wallpapers

if [[ ! -f ~/dev/infra/docker-compose.yml ]]; then
  cat > ~/dev/infra/docker-compose.yml <<'YML'
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: sqlserver
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "${MSSQL_SA_PASSWORD:?define MSSQL_SA_PASSWORD en .env}"
      MSSQL_PID: "Developer"
    ports:
      - "127.0.0.1:1433:1433"
    volumes:
      - mssql-data:/var/opt/mssql
      - ./backups:/var/opt/mssql/backups
    restart: unless-stopped

volumes:
  mssql-data:
YML
  printf 'MSSQL_SA_PASSWORD=Dev_Str0ng!Pass2026\n' > ~/dev/infra/.env
  chmod 600 ~/dev/infra/.env
  printf '.env\nbackups/\n' > ~/dev/infra/.gitignore
  aviso "Cambia la contraseña de SA en ~/dev/infra/.env antes de usarlo."
  ok "docker-compose de SQL Server creado en ~/dev/infra"
fi

# ─────────────────────────────────────────────────────── git
paso "Configuración de Git"
if [[ -z "$(git config --global user.name || true)" ]]; then
  read -rp "  Tu nombre para Git: " GITNAME
  read -rp "  Tu correo para Git: " GITMAIL
  git config --global user.name  "$GITNAME"
  git config --global user.email "$GITMAIL"
fi
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.pager delta
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global merge.conflictstyle zdiff3
ok "Git configurado"

cat <<FIN

${C_OK}════════════════════════════════════════════════════${C_OFF}
  ${C_OK}Post-instalación completada.${C_OFF}

  Siguientes pasos:
    · Autentica Claude Code :  ${C_INFO}claude${C_OFF}
    · Levanta SQL Server    :  ${C_INFO}cd ~/dev/infra && docker compose up -d${C_OFF}
    · Verifica el stack     :  ${C_INFO}~/MyArchie/scripts/verificar-stack.sh${C_OFF}
    · Lee la documentación  :  ${C_INFO}~/MyArchie/docs/${C_OFF}

  ${C_WARN}Reinicia la sesión para que el grupo docker tome efecto.${C_OFF}
${C_OK}════════════════════════════════════════════════════${C_OFF}

FIN
