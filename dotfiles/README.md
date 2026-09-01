# Dotfiles

Configuración lista para copiar. Cada carpeta corresponde a `~/.config/<nombre>/`.

```bash
mkdir -p ~/.config
cp -r dotfiles/hypr    ~/.config/
cp -r dotfiles/waybar  ~/.config/
cp -r dotfiles/kitty   ~/.config/
cp    dotfiles/starship/starship.toml ~/.config/
cp    dotfiles/zsh/.zshrc ~/.zshrc
```

| Archivo | Documento donde se explica |
|---|---|
| `hypr/hyprland.conf` | [04 — Hyprland](../docs/04-entorno-grafico-hyprland.md) |
| `waybar/config.jsonc`, `waybar/style.css` | [04](../docs/04-entorno-grafico-hyprland.md) y [05](../docs/05-estetica-y-personalizacion.md) |
| `kitty/kitty.conf` | [05 — Estética](../docs/05-estetica-y-personalizacion.md) |
| `zsh/.zshrc` | [06 — Terminal](../docs/06-terminal-y-claude-code.md) |
| `starship/starship.toml` | [06 — Terminal](../docs/06-terminal-y-claude-code.md) |

## Lo que debes ajustar

1. **`hypr/hyprland.conf`** → línea `monitor =` (ejecuta `hyprctl monitors` para ver el tuyo)
   y `kb_layout` (`latam`, `es` o `us`).
2. **`hypr/hyprland.conf`** → si tienes NVIDIA, descomenta el bloque correspondiente.
3. **`zsh/.zshrc`** → revisa los alias `db-up`/`db-down` si tu `docker-compose.yml` no está
   en `~/dev/infra/`.
4. **Paleta de colores** — todo usa Catppuccin Mocha. Para cambiarla, sustituye los hex en
   `waybar/style.css`, `kitty/kitty.conf` y `starship/starship.toml`.

## Versionarlos

En vez de copiar, enlaza (así editas el repo directamente):

```bash
for d in hypr waybar kitty; do ln -sfn "$PWD/dotfiles/$d" ~/.config/$d; done
ln -sf "$PWD/dotfiles/starship/starship.toml" ~/.config/starship.toml
ln -sf "$PWD/dotfiles/zsh/.zshrc" ~/.zshrc
```
