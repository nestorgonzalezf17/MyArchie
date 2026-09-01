#!/usr/bin/env bash
#
# actualizar-seguro — rutina de actualización con snapshot previo.
#
set -euo pipefail
C_INFO=$'\e[1;36m'; C_WARN=$'\e[1;33m'; C_OFF=$'\e[0m'

echo -e "${C_WARN}Revisa antes las noticias: https://archlinux.org/news/${C_OFF}"
read -rp "¿Continuar? [s/N] " r
[[ ${r,,} == s ]] || exit 0

echo -e "\n${C_INFO}==> Snapshot previo${C_OFF}"
sudo snapper -c root create --description "antes de actualizar $(date +%F_%H:%M)" || \
  echo "  (snapper no configurado; sigo sin snapshot)"

echo -e "\n${C_INFO}==> Actualizando${C_OFF}"
if command -v paru &>/dev/null; then paru; else sudo pacman -Syu; fi

echo -e "\n${C_INFO}==> Archivos .pacnew pendientes${C_OFF}"
if command -v pacdiff &>/dev/null; then
  sudo DIFFPROG="${DIFFPROG:-nvim -d}" pacdiff || true
else
  find /etc -name '*.pacnew' 2>/dev/null || true
fi

echo -e "\n${C_INFO}==> Limpieza${C_OFF}"
sudo paccache -rk2
huerfanos=$(pacman -Qdtq || true)
[[ -n $huerfanos ]] && sudo pacman -Rns $huerfanos --noconfirm || echo "  sin huérfanos"

echo -e "\n${C_INFO}==> Estado${C_OFF}"
systemctl --failed --no-pager
echo
echo "Si se actualizó el kernel o los drivers de video, reinicia."
