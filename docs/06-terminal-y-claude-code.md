# 06 — Terminal moderna y Claude Code

> Objetivo: dejar la terminal cómoda y potente, e **instalar Claude Code** para que te
> acompañe durante el resto de la construcción de tu distro.

---

## Parte A — La terminal

### 1. Zsh + configuración

Ya pusimos Zsh como shell al crear el usuario. Ahora lo hacemos útil.

```bash
sudo pacman -S --needed zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
```

- `zsh-autosuggestions` — sugiere el resto del comando en gris, según tu historial.
  Aceptas con `→`.
- `zsh-syntax-highlighting` — colorea el comando mientras escribes: verde si existe, rojo si
  no. Detectas errores de tipeo **antes** de pulsar Enter.

Copia la configuración de este repo:

```bash
cp dotfiles/zsh/.zshrc ~/.zshrc
```

### 2. Starship: el prompt

```bash
sudo pacman -S --needed starship
mkdir -p ~/.config
cp dotfiles/starship/starship.toml ~/.config/starship.toml
```

Starship detecta automáticamente el contexto y te muestra en el prompt: rama de Git y si hay
cambios, versión de Node/Python/.NET/Java del proyecto actual, si estás en un contenedor,
duración del último comando, y el código de salida si falló.

### 3. Herramientas que cambian tu día a día

Ya las instalaste en el doc 03. Aquí está cómo se usan de verdad:

```bash
# fzf — buscador difuso
Ctrl+R          # buscar en el historial de comandos (esto solo ya vale la instalación)
Ctrl+T          # insertar un archivo del directorio actual en el comando
Alt+C           # cd a un subdirectorio, eligiéndolo interactivamente

# zoxide — cd inteligente
z api           # salta a ~/dev/mi-proyecto/api si lo has visitado antes
zi              # elegir de una lista interactiva

# ripgrep
rg "TODO"                       # buscar en todo el proyecto (respeta .gitignore)
rg -t cs "class Usuario"        # solo en archivos C#
rg -i "conexion" --stats        # sin distinguir mayúsculas, con estadísticas

# fd
fd '\.csproj$'                  # todos los .csproj
fd -e py -x wc -l               # contar líneas de cada .py

# bat / eza
bat Program.cs                  # con colores y números de línea
eza -la --icons --git           # ls con iconos y estado de Git
eza --tree --level=2            # árbol de directorios
```

### 4. tmux (sesiones que sobreviven)

```bash
sudo pacman -S --needed tmux
```

💡 *Por qué lo querrás:* si cierras la terminal, los procesos mueren. Con tmux la sesión vive
en segundo plano: cierras la ventana, vuelves con `tmux attach` y todo sigue ahí. Y si
trabajas por SSH, una caída de red no mata tu compilación.

```bash
tmux new -s dev        # crear sesión llamada "dev"
# Ctrl+B luego D       -> desconectarse (detach)
tmux attach -t dev     # volver
tmux ls                # listar sesiones

# Dentro: Ctrl+B luego...
#   %   dividir vertical      "   dividir horizontal
#   ←→  moverse entre paneles  c   nueva ventana
#   [   modo scroll (q para salir)
```

---

## Parte B — Instalar Claude Code

**Claude Code** es la CLI oficial de Anthropic: un asistente que vive en tu terminal, lee y
edita archivos de tu proyecto, ejecuta comandos y te explica lo que hace. Es exactamente la
herramienta con la que puedes seguir esta guía preguntando dudas sobre la marcha.

### 1. Requisitos

Necesitas Node.js. Instálalo con `fnm` (gestor de versiones — así puedes cambiar de versión
por proyecto; se detalla en el doc 07):

```bash
sudo pacman -S --needed fnm
eval "$(fnm env --use-on-cd --shell zsh)"
fnm install --lts
fnm default lts-latest
node --version    # debe ser 18 o superior
```

> Alternativa rápida sin gestor de versiones: `sudo pacman -S nodejs npm`.

También necesitas una cuenta con acceso a Claude Code: una suscripción **Claude Pro o Max**,
o crédito en la **Anthropic Console** (`console.anthropic.com`).

### 2. Instalar

**Opción A — instalador nativo (recomendado):**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

⚠️ Regla general de seguridad: nunca canalices a `bash` un script que no vas a revisar. Si
quieres inspeccionarlo primero (buena costumbre, hazlo):

```bash
curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh
less /tmp/claude-install.sh      # léelo
bash /tmp/claude-install.sh
```

**Opción B — vía npm:**

```bash
npm install -g @anthropic-ai/claude-code
```

⚠️ **No uses `sudo npm install -g`.** Configura primero un prefijo en tu home para que npm
instale sin permisos de root:

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Opción C — desde el AUR:**

```bash
paru -S claude-code
```

Verifica:

```bash
claude --version
claude doctor        # diagnóstico del entorno: PATH, permisos, versión de Node
```

### 3. Autenticarse

```bash
cd ~/dev/mi-proyecto     # entra a alguna carpeta
claude
```

La primera vez abre el navegador para iniciar sesión. Elige tu método (suscripción Claude o
API key de la Console). Después de eso, `claude` arranca directo.

### 4. Cómo se usa

```bash
claude                          # sesión interactiva en el directorio actual
claude "explícame este error"   # arrancar con una pregunta
claude -p "resume el README"    # modo no interactivo: responde y termina
claude -c                       # continuar la conversación anterior
claude --resume                 # elegir una conversación pasada de una lista
```

Dentro de la sesión interactiva:

| Comando | Qué hace |
|---|---|
| `/help` | Lista todos los comandos |
| `/init` | Analiza el proyecto y crea un `CLAUDE.md` con su contexto |
| `/clear` | Limpia la conversación (útil al cambiar de tarea) |
| `/model` | Cambiar de modelo |
| `/config` | Ajustes (tema, etc.) |
| `/cost` | Cuánto llevas gastado en esta sesión |
| `/doctor` | Diagnóstico |
| `Shift+Tab` | Alternar el modo de permisos (preguntar / aceptar ediciones / plan) |
| `Esc` | Interrumpir lo que está haciendo |
| `@archivo` | Mencionar un archivo para que lo lea |
| `!comando` | Ejecutar un comando de shell y meter la salida en el contexto |

### 5. Modelos disponibles

Al escribir `/model` verás las opciones actuales. La familia **Claude 5** (Opus 5, Sonnet 5,
Fable 5) y **Haiku 4.5** son las más recientes: Opus para razonamiento difícil, Sonnet como
equilibrio, Haiku para tareas rápidas y baratas.

### 6. Darle contexto de tu proyecto: `CLAUDE.md`

Claude Code lee automáticamente un archivo `CLAUDE.md` en la raíz del proyecto. Ahí pones las
reglas de la casa:

```bash
cd ~/dev/mi-proyecto
claude
> /init
```

O escríbelo a mano:

```markdown
# Proyecto: API de Inventario

## Stack
- .NET 10 (C#), Entity Framework Core
- SQL Server 2022 en Docker (puerto 1433)
- Frontend: React + Vite

## Comandos
- Compilar: `dotnet build`
- Tests: `dotnet test`
- Levantar la BD: `docker compose up -d sqlserver`

## Convenciones
- Nombres de clases en PascalCase, campos privados con `_camelCase`.
- Toda migración de EF Core debe tener nombre descriptivo.
- No commitear cadenas de conexión: usar `dotnet user-secrets`.
```

💡 Este archivo es lo que más mejora la calidad de las respuestas. Vale más que cualquier
prompt largo.

### 7. Un `CLAUDE.md` para *este* proyecto (tu distro)

Ya que estás construyendo un sistema operativo, dale contexto:

```bash
cd ~/MyArchie   # o donde clonaste este repo
cat > CLAUDE.md <<'MD'
# MyArchie — Distro de Arch personalizada

Este repo documenta la construcción manual de una distro Arch para desarrollo.

## Contexto del sistema
- Arch Linux, UEFI, Btrfs con subvolúmenes (@, @home, @log, @pkg, @snapshots)
- Bootloader: systemd-boot
- Escritorio: Hyprland (Wayland) + Waybar + Kitty
- Shell: Zsh + Starship
- Stack: .NET 10, Python, Java, PHP, Node, SQL Server en Docker

## Reglas al ayudarme
- Explícame el *por qué* de cada comando, no solo el qué. Soy principiante.
- Marca claramente los comandos destructivos antes de proponerlos.
- Prefiere paquetes de los repos oficiales sobre el AUR cuando exista la opción.
- No propongas `archinstall`: el objetivo es aprender haciéndolo a mano.
- Antes de tocar archivos de arranque (/boot, mkinitcpio, fstab), avísame del riesgo.
- Responde en español.

## Comandos frecuentes
- Actualizar: `paru`
- Ver snapshots: `sudo snapper -c root list`
- Logs de arranque: `journalctl -b -p err`
MD
```

Ahora, cuando pidas ayuda dentro de este repo, Claude ya sabe todo tu contexto.

### 8. Trabajar con esta guía usando Claude Code

Ejemplos reales de uso durante la instalación:

```bash
# Estás atascado y no arranca
claude "mi sistema no arranca, dice 'you are now being dropped into an emergency shell'.
        Uso Btrfs con subvolumen @ y systemd-boot. ¿Qué reviso primero?"

# Quieres entender un archivo
claude "@/etc/fstab explícame línea por línea qué hace este fstab"

# Un servicio falla
claude '!systemctl status docker' "¿por qué falla?"

# Personalizar
claude "modifica @~/.config/waybar/config.jsonc para añadir un módulo que muestre
        la temperatura de la CPU"
```

### 9. Permisos: entiende qué le estás dejando hacer

Claude Code pide confirmación antes de ejecutar comandos o editar archivos. Con `Shift+Tab`
cambias entre modos:

- **normal** — pregunta por cada acción. El más seguro; úsalo mientras aprendes.
- **acceptEdits** — edita archivos sin preguntar, pero sigue preguntando por los comandos.
- **plan** — solo lee y propone un plan, no modifica nada. Ideal para "explícame" o
  "¿cómo harías...?".

⚠️ Existe un modo que salta todas las confirmaciones. **No lo uses** en tu sistema principal,
y menos con comandos que tocan `/boot`, `/etc` o discos.

Para permitir de forma permanente ciertos comandos seguros, crea
`~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(pacman -Ss:*)",
      "Bash(pacman -Qi:*)",
      "Bash(systemctl status:*)",
      "Bash(journalctl:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(ls:*)"
    ],
    "deny": [
      "Bash(rm -rf /*)",
      "Bash(mkfs*)",
      "Bash(dd:*)"
    ]
  }
}
```

### 10. Costos

`/cost` te dice el gasto de la sesión. Con suscripción Pro/Max tienes límites de uso en vez
de cobro por token. Con API key, se cobra por token: usa Haiku para preguntas simples y
`/clear` entre tareas distintas (una conversación larga reenvía todo el contexto cada vez y
se paga por ello).

### 11. Extras útiles

```bash
# Integración con VS Code: dentro de VS Code, abre una terminal y ejecuta `claude`.
# Detecta el editor automáticamente. También hay extensión oficial en el Marketplace.

# Atajo: lanzar Claude Code en una terminal flotante desde Hyprland.
# Añade a ~/.config/hypr/hyprland.conf:
bind = SUPER, C, exec, kitty --class claude-float -e claude
windowrulev2 = float, class:^(claude-float)$
windowrulev2 = size 1200 800, class:^(claude-float)$
windowrulev2 = center, class:^(claude-float)$
```

Ahora `Super + C` abre a Claude flotando en el centro de tu pantalla, en cualquier momento.

---

## Checklist

- [ ] Mi prompt muestra la rama de Git al entrar a un repo
- [ ] `Ctrl+R` abre el buscador difuso del historial
- [ ] `claude --version` responde
- [ ] `claude doctor` no reporta problemas
- [ ] Tengo un `CLAUDE.md` en el repo de mi distro
- [ ] `Super + C` abre Claude Code flotante

---

**Siguiente:** [07 — Stack de desarrollo](07-stack-desarrollo.md)
