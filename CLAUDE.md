# MyArchie — Distro de Arch personalizada

Repositorio de documentación y configuración para construir manualmente una distribución
Arch Linux orientada a desarrollo de software.

## Contexto del sistema

- Arch Linux, arranque UEFI, `systemd-boot`
- Btrfs con subvolúmenes `@`, `@home`, `@log`, `@pkg`, `@snapshots`
- Escritorio: Hyprland (Wayland) + Waybar + Kitty, tema Catppuccin Mocha
- Shell: Zsh + Starship
- Stack: .NET 10, Python, Java (21/17), PHP, Node.js, SQL Server en Docker
- Snapshots con Snapper + snap-pac

## Estructura

```
docs/       Los 13 capítulos de la guía, en orden. Léelos como fuente de verdad.
scripts/    Automatizan pasos ya explicados en docs/. Bash con set -euo pipefail.
dotfiles/   Configuración de Hyprland, Waybar, Kitty, Zsh, Starship.
```

## Reglas al ayudarme

- Responde en **español**.
- Explica el *por qué* de cada comando, no solo el qué. Soy principiante en Linux.
- Marca claramente los comandos destructivos (⚠️) antes de proponerlos.
- Prefiere paquetes de los repos oficiales sobre el AUR cuando exista la opción.
- **No propongas `archinstall`**: el objetivo del proyecto es aprender haciéndolo a mano.
- Antes de tocar `/boot`, `mkinitcpio` o `fstab`, avísame del riesgo y de cómo revertir.
- Si cambias algo en `scripts/` o `dotfiles/`, actualiza el documento de `docs/` que lo
  explica, y viceversa. Deben estar sincronizados.
- Los scripts deben pasar `bash -n` y usar `set -euo pipefail`.

## Comandos frecuentes en el sistema

```bash
paru                              # actualizar todo
scripts/actualizar-seguro.sh      # actualizar con snapshot previo
scripts/verificar-stack.sh        # comprobar el stack de desarrollo
sudo snapper -c root list         # ver snapshots
journalctl -b -p err              # errores del arranque actual
docker compose -f ~/dev/infra/docker-compose.yml up -d   # levantar SQL Server
```

## Comprobar el repo

```bash
for f in scripts/*.sh; do bash -n "$f" || echo "FALLA: $f"; done
```
