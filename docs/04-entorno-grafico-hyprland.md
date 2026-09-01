# 04 — Entorno gráfico: Hyprland

> Objetivo: pasar de una consola de texto a un escritorio Wayland con mosaico, animaciones,
> barra de estado, notificaciones y lanzador de aplicaciones.

---

## 1. Conceptos: X11, Wayland y compositores

- **X11** es el sistema de ventanas clásico de Linux (de 1984). Funciona en todas partes,
  pero su arquitectura permite que cualquier app espíe el teclado de las otras.
- **Wayland** es el reemplazo moderno: más simple, seguro y fluido. Es lo que usamos.
- Un **compositor** es el programa que dibuja las ventanas en pantalla. En Wayland, el
  compositor **es** el escritorio: no hay una capa aparte.
- **Hyprland** es un compositor Wayland de tipo **tiling** (mosaico): las ventanas se
  acomodan solas sin superponerse, y navegas con el teclado. Además hace animaciones, blur
  y esquinas redondeadas — de ahí lo de "estético".

💡 En un tiling WM te olvidas del ratón para gestionar ventanas. Al principio se siente
raro; a los tres días no quieres volver.

## 2. Instalación

```bash
sudo pacman -S --needed \
  hyprland \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  qt5-wayland qt6-wayland \
  polkit-gnome \
  waybar \
  wofi \
  dunst libnotify \
  hyprpaper hyprlock hypridle \
  grim slurp wl-clipboard cliphist \
  thunar thunar-volman gvfs tumbler \
  kitty \
  brightnessctl playerctl \
  network-manager-applet blueman
```

Qué hace cada pieza:

| Paquete | Rol |
|---|---|
| `hyprland` | El compositor / escritorio |
| `xdg-desktop-portal-*` | Puente para que las apps pidan cosas al escritorio: compartir pantalla, diálogo "Abrir archivo". **Sin esto, compartir pantalla en Teams/Meet no funciona.** |
| `polkit-gnome` | Agente de autenticación: la ventanita que pide tu contraseña cuando una app gráfica necesita permisos |
| `waybar` | Barra de estado superior (reloj, batería, red, workspaces) |
| `wofi` | Lanzador de aplicaciones (tipo Spotlight) |
| `dunst` | Notificaciones emergentes |
| `hyprpaper` / `hyprlock` / `hypridle` | Fondo de pantalla / bloqueo de pantalla / apagado por inactividad |
| `grim` + `slurp` | Capturas de pantalla (`grim` captura, `slurp` selecciona el área) |
| `cliphist` | Historial de portapapeles |
| `thunar` | Explorador de archivos gráfico |
| `kitty` | Emulador de terminal acelerado por GPU |

## 3. Arrancar Hyprland

Por ahora, a mano: inicia sesión en la consola y escribe

```bash
Hyprland
```

(Con `H` mayúscula.) Deberías ver un fondo de color. **Atajo por defecto:
`Super + Q` abre una terminal**, `Super + M` sale de Hyprland. (`Super` es la tecla Windows.)

Si la pantalla queda negra o vuelve a la consola, mira los logs:

```bash
cat /tmp/hypr/*/hyprland.log | tail -50
```

## 4. Configuración de Hyprland

El archivo es `~/.config/hypr/hyprland.conf`. Este repo trae una configuración lista en
[`dotfiles/hypr/hyprland.conf`](../dotfiles/hypr/hyprland.conf); cópiala:

```bash
mkdir -p ~/.config/hypr
cp dotfiles/hypr/hyprland.conf ~/.config/hypr/
```

Y recarga con `Super + Shift + R` (o simplemente guarda el archivo: Hyprland recarga solo).

### Lo que debes ajustar sí o sí

Abre el archivo y busca la sección `monitor=`:

```bash
hyprctl monitors      # te dice el nombre y resoluciones de tus pantallas
```

Ejemplo de salida: `Monitor eDP-1 (ID 0): 1920x1080@60.00Hz`. Entonces:

```
monitor = eDP-1, 1920x1080@60, 0x0, 1
```

El formato es `nombre, resolución@refresco, posición, escala`. Para una pantalla HiDPI usa
escala `1.5` o `2`. Para dejar que Hyprland decida: `monitor = , preferred, auto, 1`.

## 5. Atajos de teclado principales

Estos son los que trae la configuración de este repo. `Super` = tecla Windows.

### Ventanas y aplicaciones

| Atajo | Acción |
|---|---|
| `Super + Return` | Abrir terminal (Kitty) |
| `Super + D` | Lanzador de aplicaciones (wofi) |
| `Super + E` | Explorador de archivos (Thunar) |
| `Super + B` | Navegador |
| `Super + Q` | Cerrar la ventana enfocada |
| `Super + V` | Alternar ventana flotante ↔ mosaico |
| `Super + F` | Pantalla completa |
| `Super + P` | Pseudo-tiling (ventana centrada, tamaño natural) |
| `Super + ←↑↓→` | Mover el foco entre ventanas |
| `Super + Shift + ←↑↓→` | Mover la ventana de sitio |
| `Super + Ctrl + ←↑↓→` | Redimensionar la ventana |
| `Super + botón izq. (arrastrar)` | Mover ventana con el ratón |
| `Super + botón der. (arrastrar)` | Redimensionar con el ratón |

### Espacios de trabajo (workspaces)

| Atajo | Acción |
|---|---|
| `Super + 1..9` | Ir al espacio N |
| `Super + Shift + 1..9` | Mover la ventana actual al espacio N |
| `Super + rueda del ratón` | Cambiar de espacio |
| `Super + S` | Espacio especial (scratchpad: una ventana que aparece/desaparece) |

💡 **Cómo organizar tus espacios.** Una convención cómoda para desarrollo:
`1` navegador · `2` editor/IDE · `3` terminales · `4` base de datos · `5` comunicación.

### Sistema

| Atajo | Acción |
|---|---|
| `Print` | Captura de área a portapapeles |
| `Shift + Print` | Captura de pantalla completa a archivo |
| `Super + L` | Bloquear pantalla |
| `Super + Shift + E` | Menú de apagado / reinicio / cerrar sesión |
| `Super + Shift + C` | Historial del portapapeles |
| `Super + Shift + R` | Recargar la configuración |
| Teclas Fn de brillo/volumen | Funcionan directamente |

## 6. Waybar: la barra de estado

Copia la configuración:

```bash
mkdir -p ~/.config/waybar
cp dotfiles/waybar/config.jsonc dotfiles/waybar/style.css ~/.config/waybar/
```

Recarga: `killall -SIGUSR2 waybar` (o reinicia Hyprland).

Si un módulo no aparece, prueba a ejecutar `waybar` en una terminal: los errores de
configuración se imprimen ahí.

## 7. Login gráfico (display manager)

Para no tener que escribir `Hyprland` cada vez:

```bash
sudo pacman -S --needed sddm
sudo systemctl enable sddm
```

Un tema decente para SDDM:

```bash
paru -S sddm-sugar-candy-git
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<'CONF'
[Theme]
Current=Sugar-Candy
CONF
```

Reinicia y deberías ver una pantalla de login gráfica con Hyprland en la lista de sesiones.

> **Alternativa minimalista:** si prefieres arrancar Hyprland desde la consola
> automáticamente, no instales SDDM y añade esto al final de tu `~/.zprofile`:
> ```bash
> if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then exec Hyprland; fi
> ```

## 8. Variables de entorno importantes

Ya vienen en la configuración del repo, pero conviene entenderlas:

```
env = XDG_CURRENT_DESKTOP,Hyprland     # las apps saben en qué escritorio están
env = QT_QPA_PLATFORM,wayland;xcb      # Qt usa Wayland, con X11 de respaldo
env = MOZ_ENABLE_WAYLAND,1             # Firefox en Wayland nativo (nítido en HiDPI)
env = ELECTRON_OZONE_PLATFORM_HINT,auto # VS Code, Slack, Discord en Wayland nativo
```

💡 Sin `ELECTRON_OZONE_PLATFORM_HINT`, VS Code corre bajo XWayland y se ve borroso en
pantallas HiDPI.

## 9. Compatibilidad con apps X11

Algunas apps (Java Swing antiguo, Wine, algunos IDEs de JetBrains) solo hablan X11.
Hyprland las corre a través de **XWayland**, que ya viene incluido y funciona sin
configuración. Si una app se ve borrosa, es porque va por XWayland; se puede corregir con
`xwayland { force_zero_scaling = true }` en la config.

---

## Checklist

- [ ] Hyprland arranca y veo el fondo
- [ ] `Super + Return` abre una terminal
- [ ] `Super + D` abre el lanzador
- [ ] Veo la barra de Waybar arriba con reloj y batería
- [ ] `Print` toma una captura
- [ ] Las notificaciones aparecen (`notify-send "hola" "funciona"`)

---

**Siguiente:** [05 — Estética y personalización](05-estetica-y-personalizacion.md)
