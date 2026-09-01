# 07 — Stack de desarrollo: .NET 10, Python, Java, PHP, Node

> Objetivo: tener los cinco lenguajes funcionando, con gestión de versiones donde importa,
> y entender cómo aislar los entornos de cada proyecto.

---

## 0. Principio general: aísla por proyecto

El error clásico es instalar todo globalmente y acabar con "en mi máquina funciona". Regla:

| Lenguaje | Herramienta de aislamiento |
|---|---|
| Python | `venv` (o `uv`) — un entorno por proyecto |
| Node | `fnm` — una versión de Node por proyecto (`.nvmrc`) |
| Java | `sdkman` o `archlinux-java` — múltiples JDKs |
| .NET | `global.json` fija el SDK por solución |
| PHP | `composer` para dependencias |
| Bases de datos | **Contenedores**, siempre |

Crea una carpeta de trabajo:

```bash
mkdir -p ~/dev && cd ~/dev
```

---

## 1. .NET 10

### Instalación

```bash
sudo pacman -S --needed dotnet-sdk dotnet-runtime aspnet-runtime
dotnet --info
```

Comprueba que la versión del SDK sea `10.x`. Si el repositorio oficial aún trae la 9 y
necesitas la 10:

```bash
paru -S dotnet-sdk-10-bin aspnet-runtime-10-bin
```

**Opción C — instalador oficial de Microsoft** (útil para tener varias versiones sin tocar el
sistema; instala en tu `$HOME`):

```bash
curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
less /tmp/dotnet-install.sh          # revísalo antes
bash /tmp/dotnet-install.sh --channel 10.0

# añade a ~/.zshrc:
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"
```

### Ajustes recomendados

```bash
# en ~/.zshrc
export DOTNET_CLI_TELEMETRY_OPTOUT=1     # sin telemetría
export DOTNET_NOLOGO=1                    # sin el banner de bienvenida
```

### Primer proyecto

```bash
cd ~/dev
dotnet new webapi -o InventarioApi
cd InventarioApi
dotnet run
```

Abre http://localhost:5000. Ver `dotnet new list` para todas las plantillas
(`console`, `classlib`, `mvc`, `blazor`, `worker`, `xunit`...).

### Fijar la versión del SDK por proyecto

```bash
dotnet new globaljson --sdk-version 10.0.100 --roll-forward latestFeature
```

Esto crea `global.json`. Cualquiera que clone el repo usará ese SDK.

### Herramientas globales útiles

```bash
dotnet tool install --global dotnet-ef            # migraciones de Entity Framework
dotnet tool install --global dotnet-outdated-tool # ver dependencias desactualizadas
dotnet tool install --global dotnet-format
```

Añade a `~/.zshrc`: `export PATH="$PATH:$HOME/.dotnet/tools"`.

### Secretos (¡no hardcodees cadenas de conexión!)

```bash
cd ~/dev/InventarioApi
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:Default" \
  "Server=localhost,1433;Database=Inventario;User Id=sa;Password=TuP@ssw0rd!;TrustServerCertificate=True"
dotnet user-secrets list
```

Se guardan en `~/.microsoft/usersecrets/`, fuera del repo. En producción se usan variables
de entorno.

### Certificado HTTPS de desarrollo

```bash
dotnet dev-certs https --trust
```

En Linux, `--trust` tiene soporte limitado. Si el navegador se queja:

```bash
sudo pacman -S --needed nss
dotnet dev-certs https -ep ~/.aspnet/https/localhost.crt --format PEM
sudo trust anchor --store ~/.aspnet/https/localhost.crt
sudo update-ca-trust
```

---

## 2. Python

Arch trae Python preinstalado y **el sistema depende de él**.

⚠️ **Nunca ejecutes `sudo pip install`.** Sobrescribe paquetes gestionados por pacman y puede
romper herramientas del sistema. Arch bloquea esto por defecto (verás
`error: externally-managed-environment`); ese error es una **protección**, no un problema
que haya que forzar con `--break-system-packages`.

```bash
sudo pacman -S --needed python python-pip python-virtualenv \
                        python-pipx uv ipython
python --version
```

### Flujo correcto por proyecto

```bash
mkdir -p ~/dev/analisis && cd ~/dev/analisis

python -m venv .venv           # crear el entorno aislado
source .venv/bin/activate      # activarlo (el prompt muestra "(.venv)")
pip install pandas requests fastapi uvicorn
pip freeze > requirements.txt
deactivate                     # salir
```

### `uv` — la alternativa rápida (recomendada)

`uv` reemplaza a pip/venv/pyenv y es 10-100x más rápido:

```bash
cd ~/dev/analisis
uv init                        # crea pyproject.toml
uv add pandas requests fastapi
uv run python app.py           # crea y usa el venv automáticamente
uv python install 3.12         # instalar otra versión de Python
uv sync                        # instalar exactamente lo del lockfile
```

### Herramientas de CLI escritas en Python

Usa `pipx`, que las instala cada una en su propio entorno:

```bash
pipx install black
pipx install ruff
pipx install httpie
pipx list
```

---

## 3. Java

```bash
sudo pacman -S --needed jdk21-openjdk jdk17-openjdk maven gradle
```

### Cambiar entre versiones de Java

Arch tiene una herramienta propia:

```bash
archlinux-java status          # ver las instaladas y cuál está activa
sudo archlinux-java set java-21-openjdk
java --version
```

Añade a `~/.zshrc`:

```bash
export JAVA_HOME=/usr/lib/jvm/default
```

### Alternativa: SDKMAN (más versiones, sin sudo)

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

sdk list java
sdk install java 21.0.5-tem     # Temurin 21
sdk use java 21.0.5-tem         # solo en esta terminal
sdk default java 21.0.5-tem     # por defecto
sdk install maven
sdk install gradle
```

### Primer proyecto

```bash
cd ~/dev
mvn archetype:generate -DgroupId=com.ejemplo -DartifactId=miapp \
    -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
cd miapp && mvn package && java -cp target/miapp-1.0-SNAPSHOT.jar com.ejemplo.App
```

### IDE

```bash
paru -S intellij-idea-community-edition   # o intellij-idea-ultimate-edition
```

💡 IntelliJ usa Java Swing (X11). Si se ve borroso o con la fuente rara en Wayland, añade en
`Help → Edit Custom VM Options`: `-Dawt.toolkit.name=WLToolkit` (soporte Wayland
experimental), o déjalo en XWayland con `xwayland { force_zero_scaling = true }` en Hyprland.

---

## 4. PHP

```bash
sudo pacman -S --needed php php-fpm php-gd php-sqlite php-intl composer
php --version
```

### Extensiones (el paso que siempre olvida la gente)

Edita `/etc/php/php.ini` y **descomenta** (quita el `;`) las que necesites:

```ini
extension=pdo_mysql
extension=pdo_sqlite
extension=mysqli
extension=gd
extension=intl
extension=curl
extension=zip
extension=iconv
extension=bcmath
```

Para SQL Server desde PHP hacen falta los drivers de Microsoft (compilan con PECL):

```bash
sudo pacman -S --needed unixodbc
paru -S msodbcsql18 mssql-tools18       # driver ODBC de Microsoft
sudo pecl install sqlsrv pdo_sqlsrv
```

y añade a `php.ini`:

```ini
extension=sqlsrv
extension=pdo_sqlsrv
```

Verifica: `php -m | grep -i sqlsrv`.

### Servidor de desarrollo

```bash
cd ~/dev/mi-web
php -S localhost:8080          # servidor integrado, suficiente para desarrollar
```

Para algo más real, usa el contenedor del doc 08 o `php-fpm` + nginx.

### Laravel / Symfony

```bash
composer global require laravel/installer
echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> ~/.zshrc
source ~/.zshrc

laravel new mi-proyecto
cd mi-proyecto && php artisan serve
```

---

## 5. Node.js

Ya lo instalaste en el doc 06 para Claude Code. Aquí, el flujo completo.

```bash
sudo pacman -S --needed fnm

# en ~/.zshrc (ya está en la config del repo):
eval "$(fnm env --use-on-cd --shell zsh)"
```

```bash
fnm install --lts               # última LTS
fnm install 20                  # otra versión
fnm list
fnm default lts-latest
fnm use 20                      # solo en esta terminal
```

💡 `--use-on-cd` hace que al entrar a una carpeta con `.nvmrc` o `.node-version`, fnm cambie
de versión **solo**. Fija la versión de un proyecto así:

```bash
cd ~/dev/mi-front
node --version > .nvmrc
```

### Gestores de paquetes

```bash
corepack enable               # habilita pnpm y yarn sin instalarlos aparte
pnpm --version
```

`pnpm` es recomendable: usa enlaces duros, así que 20 proyectos con React comparten un solo
`node_modules` en disco.

### Primer proyecto

```bash
cd ~/dev
pnpm create vite@latest mi-front -- --template react-ts
cd mi-front && pnpm install && pnpm dev
```

### Herramientas globales

```bash
pnpm add -g typescript tsx nodemon serve
```

---

## 6. Git y control de versiones

```bash
sudo pacman -S --needed git git-delta lazygit github-cli

git config --global user.name "Tu Nombre"
git config --global user.email "tucorreo@ejemplo.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.pager delta
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global merge.conflictstyle zdiff3
```

`delta` hace que `git diff` se vea legible y con colores. `lazygit` es una interfaz de texto
para Git (`lazygit` en cualquier repo) — muy recomendable mientras aprendes.

### Llave SSH para GitHub

```bash
ssh-keygen -t ed25519 -C "tucorreo@ejemplo.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub      # copia esto a GitHub → Settings → SSH keys
ssh -T git@github.com          # probar
```

O con la CLI de GitHub: `gh auth login`.

---

## 7. Editores e IDEs

```bash
# VS Code (build open source con Marketplace de Microsoft)
paru -S visual-studio-code-bin

# Alternativa 100% libre
sudo pacman -S code

# Neovim configurado
sudo pacman -S --needed neovim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# JetBrains (Rider para .NET, IntelliJ para Java, PhpStorm para PHP)
paru -S jetbrains-toolbox
```

Extensiones esenciales de VS Code para tu stack:

```bash
for ext in ms-dotnettools.csdevkit ms-python.python ms-python.vscode-pylance \
           redhat.java vscjava.vscode-java-pack bmewburn.vscode-intelephense-client \
           dbaeumer.vscode-eslint esbenp.prettier-vscode \
           ms-mssql.mssql ms-azuretools.vscode-docker \
           eamodio.gitlens catppuccin.catppuccin-vsc; do
  code --install-extension "$ext"
done
```

💡 Para que VS Code corra en Wayland nativo (nítido en HiDPI), asegúrate de tener
`ELECTRON_OZONE_PLATFORM_HINT=auto` en tu entorno (doc 04, sección 8).

---

## 8. Contenedores (base para el doc 08)

```bash
sudo pacman -S --needed docker docker-compose docker-buildx
sudo systemctl enable --now docker

sudo usermod -aG docker "$USER"
# ⚠️ cierra sesión y vuelve a entrar para que el grupo tenga efecto
newgrp docker    # o esto, para la terminal actual

docker run --rm hello-world
```

⚠️ **Nota de seguridad:** estar en el grupo `docker` equivale a tener root. Cualquiera que
pueda hablar con el socket de Docker puede montar `/` de tu máquina dentro de un contenedor.
En un equipo personal de desarrollo es un compromiso aceptado; si te incomoda, usa
**Podman rootless**:

```bash
sudo pacman -S --needed podman podman-compose
podman run --rm hello-world      # sin daemon, sin root
alias docker=podman              # la mayoría de comandos son idénticos
```

---

## 9. Verifica todo el stack

```bash
cat > ~/dev/verificar-stack.sh <<'SH'
#!/usr/bin/env bash
echo "=== Stack de desarrollo ==="
for c in "dotnet --version" "python --version" "java --version" "mvn -v" \
         "php --version" "composer --version" "node --version" "pnpm --version" \
         "docker --version" "git --version" "claude --version"; do
  printf '%-22s ' "${c%% *}:"
  eval "$c" 2>/dev/null | head -1 || echo "NO INSTALADO"
done
SH
chmod +x ~/dev/verificar-stack.sh && ~/dev/verificar-stack.sh
```

(El mismo script está en [`scripts/verificar-stack.sh`](../scripts/verificar-stack.sh).)

---

## Checklist

- [ ] `dotnet --info` muestra el SDK 10
- [ ] Puedo crear y activar un `venv` de Python
- [ ] `archlinux-java status` muestra mis JDKs
- [ ] `php -m` lista las extensiones que necesito
- [ ] `fnm list` muestra Node LTS y `node -v` responde
- [ ] `docker run --rm hello-world` funciona sin `sudo`

---

**Siguiente:** [08 — SQL Server y bases de datos](08-sql-server-y-bases-de-datos.md)
