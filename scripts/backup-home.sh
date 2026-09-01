#!/usr/bin/env bash
#
# backup-home — respaldo incremental de tu home a un disco externo con rsync.
# Uso: ./backup-home.sh /mnt/backup
#
set -euo pipefail

DESTINO="${1:-}"
[[ -n $DESTINO ]] || { echo "Uso: $0 <directorio-destino>"; exit 1; }
[[ -d $DESTINO ]] || { echo "El destino '$DESTINO' no existe o no está montado."; exit 1; }

EXCLUIR=(
  --exclude='.cache/'
  --exclude='.local/share/Trash/'
  --exclude='node_modules/'
  --exclude='.venv/'
  --exclude='__pycache__/'
  --exclude='bin/'
  --exclude='obj/'
  --exclude='target/'
  --exclude='.next/'
  --exclude='dist/'
  --exclude='.gradle/'
  --exclude='.m2/repository/'
  --exclude='.nuget/'
  --exclude='.dotnet/'
  --exclude='.docker/'
)

echo "==> Respaldando $HOME → $DESTINO/$(whoami)/"
mkdir -p "$DESTINO/$(whoami)"

rsync -avh --delete --progress "${EXCLUIR[@]}" \
      "$HOME/" "$DESTINO/$(whoami)/"

echo "==> Guardando la lista de paquetes"
mkdir -p "$DESTINO/$(whoami)/paquetes"
pacman -Qqen > "$DESTINO/$(whoami)/paquetes/oficiales.txt"
pacman -Qqem > "$DESTINO/$(whoami)/paquetes/aur.txt"

echo "==> Respaldo completado: $(date)"
du -sh "$DESTINO/$(whoami)"
