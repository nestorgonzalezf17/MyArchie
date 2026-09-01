# ══════════════════════════════════════════════════════════
#  MyArchie · .zshrc
# ══════════════════════════════════════════════════════════

# ── Historial ─────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY            # comparte el historial entre terminales
setopt HIST_IGNORE_ALL_DUPS     # sin duplicados
setopt HIST_IGNORE_SPACE        # un comando que empieza con espacio no se guarda
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY         # guarda también la fecha
setopt INC_APPEND_HISTORY

# ── Comportamiento ────────────────────────────────────────
setopt AUTO_CD                  # escribir "Documentos" equivale a "cd Documentos"
setopt AUTO_PUSHD               # cada cd apila el directorio (ver con "dirs -v")
setopt PUSHD_IGNORE_DUPS
setopt CORRECT                  # corrige errores de tipeo en comandos
setopt INTERACTIVE_COMMENTS     # permite # comentarios en la línea de comandos
setopt NO_BEEP

# ── Autocompletado ────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # ignora mayúsculas
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'

# ── Plugins (paquetes de Arch) ────────────────────────────
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#585b70'

# ── Teclas ────────────────────────────────────────────────
bindkey -e                                    # atajos estilo emacs (Ctrl+A, Ctrl+E...)
bindkey '^[[1;5C' forward-word                # Ctrl+→
bindkey '^[[1;5D' backward-word               # Ctrl+←
bindkey '^[[3~'   delete-char
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line

# búsqueda en el historial con lo ya escrito
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ── Variables de entorno ──────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS='-R --use-color'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export JAVA_HOME=/usr/lib/jvm/default

typeset -U path                                # sin duplicados en el PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.dotnet/tools"
  "$HOME/.npm-global/bin"
  "$HOME/.config/composer/vendor/bin"
  "/opt/mssql-tools18/bin"
  $path
)
export PATH

# ── Integraciones ─────────────────────────────────────────
command -v starship &>/dev/null && eval "$(starship init zsh)"
command -v zoxide   &>/dev/null && eval "$(zoxide init zsh)"
command -v fnm      &>/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"

if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=rounded \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ── Alias: navegación y archivos ──────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git --group-directories-first'
alias la='eza -a --icons'
alias lt='eza --tree --level=2 --icons'
alias ltt='eza --tree --level=3 --icons'
alias cat='bat --paging=never'
alias catp='bat -pp'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'                 # -I pregunta solo si son >3 archivos
alias df='df -h'
alias du='du -h'
alias free='free -h'

# ── Alias: sistema ────────────────────────────────────────
alias update='paru'
alias upd='~/MyArchie/scripts/actualizar-seguro.sh'
alias orphans='pacman -Qdtq'
alias cleanup='sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || echo "sin huérfanos"'
alias logs='journalctl -b -p err --no-pager'
alias logsf='journalctl -f'
alias ports='ss -tulpn'
alias services='systemctl list-units --type=service --state=running'
alias failed='systemctl --failed'
alias snaps='sudo snapper -c root list'
alias ff='fastfetch'

# ── Alias: git ────────────────────────────────────────────
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all'
alias lg='lazygit'

# ── Alias: desarrollo ─────────────────────────────────────
alias dr='dotnet run'
alias db='dotnet build'
alias dt='dotnet test'
alias dw='dotnet watch run'
alias py='python'
alias venv='python -m venv .venv && source .venv/bin/activate'
alias act='source .venv/bin/activate'
alias serve='python -m http.server'

alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dclean='docker system prune -a'
alias db-up='docker compose -f ~/dev/infra/docker-compose.yml up -d'
alias db-down='docker compose -f ~/dev/infra/docker-compose.yml stop'
alias db-logs='docker compose -f ~/dev/infra/docker-compose.yml logs -f'

alias cc='claude'
alias ccp='claude -p'

# ── Funciones ─────────────────────────────────────────────

# mkdir + cd de una vez
mkcd() { mkdir -p "$1" && cd "$1"; }

# extraer cualquier archivo comprimido
extraer() {
  [[ -f $1 ]] || { echo "'$1' no es un archivo"; return 1; }
  case $1 in
    *.tar.bz2) tar xjf "$1"   ;;
    *.tar.gz)  tar xzf "$1"   ;;
    *.tar.xz)  tar xJf "$1"   ;;
    *.tar)     tar xf  "$1"   ;;
    *.tbz2)    tar xjf "$1"   ;;
    *.tgz)     tar xzf "$1"   ;;
    *.bz2)     bunzip2 "$1"   ;;
    *.gz)      gunzip  "$1"   ;;
    *.zip)     unzip   "$1"   ;;
    *.7z)      7z x    "$1"   ;;
    *.rar)     unrar x "$1"   ;;
    *) echo "No sé cómo extraer '$1'" ;;
  esac
}

# buscar un paquete y ver su info
pkgi() { pacman -Si "$1" 2>/dev/null || paru -Si "$1"; }

# ¿qué ocupa espacio aquí?
grandes() { du -ah . 2>/dev/null | sort -rh | head -"${1:-15}"; }

# matar lo que use un puerto
puerto() { sudo ss -tulpn | grep ":$1 "; }

# nuevo proyecto .NET con git
nuevo-dotnet() {
  local nombre=${1:?uso: nuevo-dotnet <nombre> [plantilla]}
  local plantilla=${2:-webapi}
  dotnet new "$plantilla" -o "$nombre" && cd "$nombre" || return
  dotnet new gitignore
  git init -q && git add -A && git commit -qm "commit inicial"
  echo "Listo: $nombre ($plantilla)"
}

# ── Bienvenida ────────────────────────────────────────────
command -v fastfetch &>/dev/null && fastfetch
