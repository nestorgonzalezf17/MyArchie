# MyArchie — Tu distro de Arch Linux personalizada para desarrollo

Este repositorio es **tu manual y tu código fuente** para construir, desde cero y a mano,
una distribución basada en Arch Linux orientada a desarrollo de software, bonita y usable
todos los días.

No usamos `archinstall`. Hacemos cada paso manualmente, entendiendo qué hace cada comando.
Al final, empaquetamos todo en una **ISO propia** que puedes reinstalar cuando quieras.

## ¿Qué vas a tener al terminar?

- Arch Linux instalado a mano, con Btrfs + snapshots (puedes deshacer una actualización rota).
- Escritorio Hyprland (Wayland) con estética cuidada: Waybar, fuentes Nerd, tema Catppuccin.
- Terminal moderna (Ghostty/Kitty) + Zsh + Starship + herramientas CLI modernas.
- **Claude Code** instalado en tu terminal para acompañarte durante todo el proceso.
- Stack de desarrollo: .NET 10, Python, Java, PHP, Node.js y SQL Server (en contenedor).
- Una ISO instalable con TODO lo anterior preconfigurado ("tu distro").

## Cómo leer esta guía

Sigue los documentos **en orden**. Cada uno asume que terminaste el anterior.
Si algo falla, ve directo a [`docs/12-solucion-de-problemas.md`](docs/12-solucion-de-problemas.md).

| # | Documento | Qué aprendes |
|---|-----------|--------------|
| 00 | [Plan general y conceptos](docs/00-plan-general.md) | Vocabulario, arquitectura, decisiones de diseño |
| 01 | [Preparar USB y BIOS/UEFI](docs/01-preparacion-usb-y-bios.md) | Crear el medio de arranque y entrar al instalador |
| 02 | [Instalación base manual](docs/02-instalacion-base-manual.md) | Particionar, Btrfs, pacstrap, chroot, bootloader |
| 03 | [Post-instalación](docs/03-post-instalacion.md) | Usuario, red, audio, AUR, firewall |
| 04 | [Entorno gráfico: Hyprland](docs/04-entorno-grafico-hyprland.md) | Wayland, compositor, barra, notificaciones |
| 05 | [Estética y personalización](docs/05-estetica-y-personalizacion.md) | Temas, fuentes, iconos, wallpapers, GTK/Qt |
| 06 | [Terminal + Claude Code](docs/06-terminal-y-claude-code.md) | Zsh, Starship, y **instalar Claude Code** |
| 07 | [Stack de desarrollo](docs/07-stack-desarrollo.md) | .NET 10, Python, Java, PHP, Node |
| 08 | [SQL Server y bases de datos](docs/08-sql-server-y-bases-de-datos.md) | SQL Server en contenedor, clientes, backups |
| 09 | [Uso diario del sistema](docs/09-uso-diario-del-sistema.md) | pacman, systemd, permisos, atajos |
| 10 | [Mantenimiento y snapshots](docs/10-mantenimiento-y-snapshots.md) | Actualizar sin miedo, Snapper, respaldos |
| 11 | [Empaquetar tu propia ISO](docs/11-empaquetar-tu-iso.md) | archiso: convertir tu setup en una distro |
| 12 | [Solución de problemas](docs/12-solucion-de-problemas.md) | Qué hacer cuando no arranca / no hay red |
| — | [Glosario](docs/glosario.md) | Todos los términos raros, explicados |

## Advertencias antes de empezar

1. **Vas a borrar un disco.** Haz respaldo de todo lo que te importe.
2. Practica primero en una **máquina virtual** (ver doc 00). Es gratis y no rompe nada.
3. La [Arch Wiki](https://wiki.archlinux.org) es la fuente de verdad. Esta guía es tu camino
   guiado; la wiki es el mapa completo.

## Estructura del repo

```
docs/       Los capítulos de la guía (léelos en orden)
scripts/    Scripts que automatizan pasos ya explicados en los docs
dotfiles/   Configuración de Hyprland, Waybar, Zsh, etc.
```
