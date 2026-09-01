# 05 — Estética y personalización

> Objetivo: que tu sistema se vea coherente y bonito en **todas** las aplicaciones, no solo
> en Hyprland. Aquí es donde tu instalación se convierte en *tu* distro.

---

## 1. El problema de la coherencia visual en Linux

Las apps de Linux usan distintos toolkits gráficos y **cada uno se tematiza por separado**:

| Toolkit | Apps típicas | Se configura en |
|---|---|---|
| **GTK 3/4** | Firefox, Thunar, GNOME apps | `~/.config/gtk-3.0/`, `gsettings` |
| **Qt 5/6** | VLC, KDE apps, DBeaver | `qt5ct` / `qt6ct` o `kvantum` |
| **Electron** | VS Code, Slack, Discord | Tema propio de cada app |
| **Terminal** | Kitty, Ghostty | Config propia |

Por eso el truco es elegir **una paleta** y aplicarla en los cuatro frentes. Usaremos
**Catppuccin Mocha** (oscuro, cálido, con buen contraste). Alternativas igual de buenas:
Tokyo Night, Gruvbox, Nord, Rosé Pine.

### La paleta Catppuccin Mocha

```
Base       #1e1e2e    Fondo principal
Mantle     #181825    Fondo secundario (barras)
Surface0   #313244    Bordes, separadores
Text       #cdd6f4    Texto principal
Subtext0   #a6adc8    Texto secundario
Blue       #89b4fa    Acento principal
Mauve      #cba6f7    Acento secundario
Green      #a6e3a1    Éxito
Yellow     #f9e2af    Advertencia
Red        #f38ba8    Error
Peach      #fab387    Naranja
```

Anota estos hex: los vas a pegar en Waybar, Kitty, Starship y tu editor.

## 2. Temas GTK

```bash
paru -S catppuccin-gtk-theme-mocha papirus-icon-theme \
        catppuccin-cursors-mocha
```

Aplícalo (Hyprland no tiene panel de "Apariencia", se hace por línea de comandos):

```bash
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
```

GTK4 y libadwaita además leen `gsettings`:

```bash
gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-blue-cursors'
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

💡 `color-scheme: prefer-dark` es la señal estándar que hace que Firefox, GNOME Text Editor
y las apps libadwaita se pongan en modo oscuro solas.

## 3. Temas Qt

```bash
sudo pacman -S --needed qt5ct qt6ct kvantum
paru -S kvantum-theme-catppuccin-git
```

Añade a tu `~/.config/hypr/hyprland.conf` (o a `~/.zprofile`):

```
env = QT_QPA_PLATFORMTHEME,qt6ct
```

Luego abre `qt6ct` y en "Appearance" elige **kvantum-dark**; después abre
`kvantummanager` y selecciona **Catppuccin-Mocha-Blue**.

## 4. Cursor (el detalle que casi todos olvidan)

En Wayland, el cursor lo pone el compositor. Añade en `hyprland.conf`:

```
env = XCURSOR_THEME,catppuccin-mocha-blue-cursors
env = XCURSOR_SIZE,24
exec-once = hyprctl setcursor catppuccin-mocha-blue-cursors 24
```

Sin esto verás el cursor "X" negro y feo por defecto en algunas superficies.

## 5. Fondo de pantalla con hyprpaper

```bash
mkdir -p ~/Imágenes/wallpapers
# descarga tus wallpapers ahí

cat > ~/.config/hypr/hyprpaper.conf <<'CONF'
preload = ~/Imágenes/wallpapers/main.png
wallpaper = , ~/Imágenes/wallpapers/main.png
splash = false
ipc = on
CONF
```

Y que arranque solo (ya viene en la config del repo):
`exec-once = hyprpaper`

### Colores automáticos desde el wallpaper (opcional, muy vistoso)

```bash
paru -S pywal16
wal -i ~/Imágenes/wallpapers/main.png
```

`pywal` extrae la paleta de tu fondo y genera archivos de color para terminal, Waybar y más.
⚠️ Es divertido pero puede dar contrastes malos; empieza con Catppuccin fijo y experimenta
después.

## 6. Bloqueo de pantalla (hyprlock) e inactividad (hypridle)

```bash
cat > ~/.config/hypr/hyprlock.conf <<'CONF'
background {
    monitor =
    path = ~/Imágenes/wallpapers/main.png
    blur_passes = 3
    blur_size = 8
    brightness = 0.6
}

input-field {
    monitor =
    size = 300, 55
    outline_thickness = 2
    dots_size = 0.25
    dots_spacing = 0.3
    outer_color = rgba(89b4faee)
    inner_color = rgba(1e1e2edd)
    font_color = rgb(cdd6f4)
    placeholder_text = <span foreground="##a6adc8">Contraseña...</span>
    fail_text = <span foreground="##f38ba8">Incorrecta</span>
    rounding = 12
    position = 0, -50
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "$(date +'%H:%M')"
    color = rgb(cdd6f4)
    font_size = 90
    font_family = JetBrainsMono Nerd Font
    position = 0, 180
    halign = center
    valign = center
}
CONF

cat > ~/.config/hypr/hypridle.conf <<'CONF'
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {                       # atenuar pantalla
    timeout = 300
    on-timeout = brightnessctl -s set 10
    on-resume  = brightnessctl -r
}

listener {                       # bloquear
    timeout = 600
    on-timeout = loginctl lock-session
}

listener {                       # apagar pantalla
    timeout = 900
    on-timeout = hyprctl dispatch dpms off
    on-resume  = hyprctl dispatch dpms on
}

listener {                       # suspender (quita este bloque en un equipo de escritorio)
    timeout = 1800
    on-timeout = systemctl suspend
}
CONF
```

## 7. Notificaciones (dunst) con la paleta

```bash
mkdir -p ~/.config/dunst
cat > ~/.config/dunst/dunstrc <<'CONF'
[global]
    monitor = 0
    follow = mouse
    width = (300, 420)
    origin = top-right
    offset = 12x48
    scale = 0
    notification_limit = 5
    progress_bar = true
    padding = 12
    horizontal_padding = 14
    frame_width = 2
    corner_radius = 12
    font = Noto Sans 10
    markup = full
    format = "<b>%s</b>\n%b"
    icon_theme = "Papirus-Dark"
    enable_recursive_icon_lookup = true
    mouse_left_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#1e1e2e"
    foreground = "#a6adc8"
    frame_color = "#313244"
    timeout = 5

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#89b4fa"
    timeout = 8

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#f38ba8"
    frame_color = "#f38ba8"
    timeout = 0
CONF

killall dunst; dunst &
notify-send "MyArchie" "Las notificaciones funcionan 🎉"
```

## 8. Terminal bonita

La configuración de Kitty está en [`dotfiles/kitty/kitty.conf`](../dotfiles/kitty/kitty.conf):

```bash
mkdir -p ~/.config/kitty
cp dotfiles/kitty/kitty.conf ~/.config/kitty/
```

> **Ghostty** es otra excelente opción (más rápida de arrancar, buen soporte de ligaduras):
> `sudo pacman -S ghostty`. Su config va en `~/.config/ghostty/config`.

## 9. Consejos de diseño (para que no quede recargado)

1. **Una fuente para código, una para interfaz.** JetBrains Mono Nerd + Noto Sans. Ya.
2. **Máximo dos acentos.** Azul para lo activo, malva para lo secundario. Todo lo demás en
   grises de la paleta.
3. **Espaciado consistente.** Elige un `gaps_in = 5` / `gaps_out = 12` y respétalo en Waybar
   (mismo margen) y en dunst (mismo `corner_radius`).
4. **Transparencia con moderación.** `active_opacity = 1.0` (nítido donde trabajas) y
   `inactive_opacity = 0.92`. Terminales transparentes al 70 % se ven geniales en capturas
   y son ilegibles a las 3 de la tarde.
5. **Animaciones cortas.** 200-300 ms. Más lento y sientes que la máquina va lenta.

## 10. Versiona tus dotfiles

Tu configuración es código. Trátala así:

```bash
mkdir -p ~/dotfiles
cd ~/dotfiles && git init

# mueve las configs al repo y enlázalas
for d in hypr waybar kitty dunst; do
  mv ~/.config/$d ~/dotfiles/$d
  ln -s ~/dotfiles/$d ~/.config/$d
done

git add -A && git commit -m "config inicial del escritorio"
```

💡 Los enlaces simbólicos hacen que editar `~/.config/hypr/hyprland.conf` edite realmente el
archivo del repo. Cuando reinstales, clonas el repo, creas los enlaces y en 2 minutos tienes
tu escritorio de vuelta. Esto es literalmente la base del doc 11 (empaquetar tu ISO).

---

## Checklist

- [ ] Thunar y Firefox se ven oscuros y coherentes
- [ ] El cursor es el del tema, no el "X" negro
- [ ] Tengo fondo de pantalla y se restaura al reiniciar
- [ ] `Super + L` bloquea con la pantalla difuminada
- [ ] `notify-send` muestra una notificación con mi paleta
- [ ] Mis dotfiles están en un repo de Git

---

**Siguiente:** [06 — Terminal y Claude Code](06-terminal-y-claude-code.md)
