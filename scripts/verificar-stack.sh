#!/usr/bin/env bash
# Comprueba que todo el stack de desarrollo está presente y funcionando.
set -uo pipefail

OK=$'\e[1;32m✓\e[0m'; NO=$'\e[1;31m✗\e[0m'; T=$'\e[1;36m'; R=$'\e[0m'

check() {
  local nombre="$1" cmd="$2"
  local salida
  if salida=$(eval "$cmd" 2>/dev/null | head -1); then
    [[ -n $salida ]] && printf '  %s %-16s %s\n' "$OK" "$nombre" "$salida" \
                     || printf '  %s %-16s (sin salida)\n' "$OK" "$nombre"
  else
    printf '  %s %-16s no instalado\n' "$NO" "$nombre"
  fi
}

echo -e "\n${T}Lenguajes y runtimes${R}"
check ".NET"      "dotnet --version"
check "Python"    "python --version"
check "Java"      "java --version"
check "PHP"       "php --version"
check "Node"      "node --version"

echo -e "\n${T}Gestores de paquetes${R}"
check "pip"       "pip --version"
check "uv"        "uv --version"
check "Maven"     "mvn -v"
check "Gradle"    "gradle --version"
check "Composer"  "composer --version"
check "npm"       "npm --version"
check "pnpm"      "pnpm --version"
check "paru"      "paru --version"

echo -e "\n${T}Herramientas${R}"
check "Git"       "git --version"
check "Docker"    "docker --version"
check "compose"   "docker compose version"
check "sqlcmd"    "sqlcmd -? 2>&1 | head -1"
check "Claude"    "claude --version"
check "Starship"  "starship --version"

echo -e "\n${T}Sistema${R}"
check "Kernel"    "uname -r"
check "Hyprland"  "Hyprland --version 2>/dev/null | head -1"
check "Snapper"   "snapper --version"

echo -e "\n${T}Servicios${R}"
for s in NetworkManager docker bluetooth ufw sddm; do
  if systemctl is-active --quiet "$s"; then
    printf '  %s %-16s activo\n' "$OK" "$s"
  else
    printf '  %s %-16s inactivo\n' "$NO" "$s"
  fi
done

echo -e "\n${T}Contenedores${R}"
if command -v docker &>/dev/null && docker ps &>/dev/null; then
  docker ps --format '  → {{.Names}}\t{{.Status}}' || true
else
  echo "  (docker no accesible; ¿estás en el grupo 'docker'?)"
fi
echo
