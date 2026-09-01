# 00 — Plan general y conceptos base

> Objetivo de este documento: que entiendas **qué** vas a construir y **por qué**, antes de
> tocar un solo comando. Si algo aquí no se entiende, está explicado en el
> [glosario](glosario.md).

---

## 1. ¿Qué es "armar una distro"?

Una distribución de Linux (distro) son tres cosas juntas:

1. **Un kernel** — Linux, el núcleo que habla con tu hardware.
2. **Un conjunto de paquetes** — programas y librerías elegidos por alguien.
3. **Una configuración por defecto** — cómo se ve, qué arranca solo, qué atajos hay.

Arch Linux te da (1) y un gestor de paquetes excelente para (2), pero deliberadamente **no
te da (3)**. Eso es lo que tú vas a construir. Cuando tu configuración esté lista, la
metemos en una ISO con `archiso` y ya tienes literalmente tu propia distro.

## 2. Por qué NO usamos `archinstall`

`archinstall` es un script que hace la instalación por ti en 5 minutos. Es perfectamente
válido — pero tú pediste aprender. Haciéndolo a mano vas a entender:

- Cómo arranca realmente una computadora (firmware → bootloader → kernel → init).
- Qué es una partición, un sistema de archivos y un punto de montaje.
- Qué es `chroot` y por qué es mágico.
- Qué hace exactamente cada servicio que se inicia solo.

Ese conocimiento es el que te permite **arreglar** el sistema cuando se rompe, en lugar de
reinstalar.

## 3. La ruta completa, en un vistazo

```
┌─────────────────────────────────────────────────────────────┐
│ FASE A · Preparación          docs 01                       │
│   USB booteable → arrancar el ISO oficial de Arch           │
├─────────────────────────────────────────────────────────────┤
│ FASE B · Sistema base         docs 02-03                    │
│   particionar → formatear → pacstrap → chroot → bootloader  │
│   → usuario, red, audio, AUR                                │
├─────────────────────────────────────────────────────────────┤
│ FASE C · Escritorio           docs 04-06                    │
│   Hyprland + Waybar + tema + terminal + Claude Code         │
├─────────────────────────────────────────────────────────────┤
│ FASE D · Desarrollo           docs 07-08                    │
│   .NET 10 · Python · Java · PHP · Node · SQL Server         │
├─────────────────────────────────────────────────────────────┤
│ FASE E · Vida diaria          docs 09-10                    │
│   uso, mantenimiento, snapshots, respaldos                  │
├─────────────────────────────────────────────────────────────┤
│ FASE F · Tu distro            docs 11                       │
│   archiso → MyArchie.iso, instalable en cualquier máquina   │
└─────────────────────────────────────────────────────────────┘
```

## 4. Decisiones de diseño (y por qué)

Cada decisión aquí tiene una alternativa válida. Te explico por qué elegí ésta para tu caso.

| Decisión | Elegimos | Alternativa | Por qué |
|---|---|---|---|
| Sistema de archivos raíz | **Btrfs** con subvolúmenes | ext4 | Btrfs permite *snapshots*: fotos instantáneas del sistema. Si una actualización rompe algo, vuelves atrás en 30 segundos. Para alguien que está aprendiendo, esto es una red de seguridad enorme. |
| Bootloader | **systemd-boot** | GRUB | Mucho más simple (un archivo de texto de 4 líneas), y ya viene con systemd. GRUB es más potente pero tiene 10x más superficie para confundirse. |
| Entorno gráfico | **Hyprland** (Wayland) | KDE Plasma, GNOME | Pediste estética. Hyprland es un compositor de mosaico con animaciones, blur y transparencias; se ve espectacular y es 100% configurable en texto (perfecto para versionar en Git). Curva de aprendizaje mayor, pero tú quieres aprender. |
| Shell | **Zsh** + Starship | Bash, Fish | Zsh es compatible con Bash (todo lo que aprendas sirve) pero con autocompletado potente. Starship da el prompt bonito con info de Git, versión de Node/.NET, etc. |
| Paquetes AUR | **paru** | yay, makepkg manual | El AUR es el repositorio comunitario donde está *todo* lo demás. `paru` lo hace cómodo y te muestra el código antes de compilar. |
| SQL Server | **Contenedor Docker/Podman** | Instalación nativa | Microsoft solo da paquetes para RHEL/Ubuntu/SUSE. En Arch, el contenedor es la vía soportada, limpia y desechable. |
| Contenedores | **Docker** | Podman | Docker porque las imágenes de Microsoft y la documentación de .NET asumen Docker. Anoto los equivalentes en Podman. |

## 5. Requisitos de hardware

| Recurso | Mínimo | Recomendado |
|---|---|---|
| CPU | x86_64, 2 núcleos | 4+ núcleos (compilar del AUR y SQL Server piden CPU) |
| RAM | 4 GB | **16 GB** (SQL Server solo pide ~2 GB, y los IDEs comen) |
| Disco | 40 GB | 250 GB SSD NVMe |
| Firmware | UEFI | UEFI (esta guía asume UEFI; ver doc 12 si tienes BIOS legacy) |

> **SQL Server necesita mínimo 2 GB de RAM libres** o el contenedor se apaga solo.

## 6. Practica primero en una máquina virtual

**Hazlo. En serio.** Vas a equivocarte 3 o 4 veces la primera vez, y en una VM eso cuesta
cero. Cuando el proceso te salga fluido, lo repites en el hardware real.

En Windows o Linux, instala [VirtualBox](https://www.virtualbox.org) o usa
`virt-manager` (KVM). Configura la VM así:

- Tipo: Linux / Arch Linux (64-bit)
- RAM: 8192 MB
- Disco: 60 GB, dinámico
- **Habilita EFI** (en VirtualBox: Configuración → Sistema → "Habilitar EFI"). Sin esto,
  los pasos de UEFI de esta guía no aplican.
- Procesadores: 4
- Video: 128 MB

Si ya estás en Linux, esto crea la VM con KVM (más rápido que VirtualBox):

```bash
sudo pacman -S --needed qemu-full virt-manager libvirt edk2-ovmf dnsmasq
sudo systemctl enable --now libvirtd.socket
sudo usermod -aG libvirt "$USER"   # cierra sesión y vuelve a entrar
virt-manager                        # interfaz gráfica: New VM → ISO de Arch → marca "UEFI"
```

## 7. Convenciones de esta guía

- Los bloques con `#` al inicio del prompt son **como root**; los que tienen `$` son como
  tu usuario normal. En los bloques copiables omito el prompt para que puedas pegar directo.
- Cuando veas `<algo-entre-picos>`, **reemplázalo** por tu valor real.
- `⚠️` marca pasos destructivos o irreversibles. Lee dos veces antes de ejecutar.
- `💡` marca explicaciones del *por qué*, no solo del *cómo*.

---

**Siguiente:** [01 — Preparar USB y BIOS/UEFI](01-preparacion-usb-y-bios.md)
