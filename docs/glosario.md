# Glosario

Todos los términos raros de esta guía, en orden alfabético.

---

**AUR** (Arch User Repository) — Repositorio comunitario con ~90.000 recetas de compilación
(`PKGBUILD`). No contiene binarios: tu máquina compila. No está auditado; lee lo que instalas.

**archiso** — Herramienta oficial para construir imágenes ISO de Arch. Es lo que usas en el
doc 11 para crear tu distro.

**Bootloader** — Programa que el firmware ejecuta para cargar el kernel. Usamos
`systemd-boot`. La alternativa clásica es GRUB.

**Btrfs** — Sistema de archivos moderno con subvolúmenes, snapshots, compresión transparente
y sumas de comprobación. La alternativa simple es ext4.

**chroot** — "change root". Cambia cuál directorio es `/` para tu shell, de modo que puedes
trabajar "dentro" de otro sistema instalado. `arch-chroot` lo hace preparando también
`/proc`, `/sys` y `/dev`.

**Compositor** — En Wayland, el programa que dibuja las ventanas. Es a la vez servidor
gráfico y gestor de ventanas. Hyprland es un compositor.

**Contenedor** — Proceso aislado con su propio sistema de archivos, red y librerías, pero
compartiendo el kernel del host. Más ligero que una máquina virtual. Docker/Podman los
gestionan.

**Daemon** — Proceso que corre en segundo plano dando un servicio (`dockerd`, `NetworkManager`).

**Display manager** — Pantalla gráfica de login (SDDM, GDM). Opcional: puedes arrancar el
escritorio desde la consola.

**Dotfiles** — Los archivos de configuración de tu usuario, que empiezan con punto
(`.zshrc`, `.config/hypr/`). Se versionan en Git.

**ESP** (EFI System Partition) — Partición FAT32 donde el firmware UEFI busca los
bootloaders. La montamos en `/boot`.

**fstab** — `/etc/fstab`. Tabla que dice al sistema qué montar, dónde y con qué opciones al
arrancar.

**GPT** (GUID Partition Table) — Esquema de particionado moderno, requerido por UEFI.
Reemplaza a MBR.

**Hook (de pacman)** — Script que pacman ejecuta antes o después de una transacción. Los
usamos para actualizar el bootloader y guardar la lista de paquetes.

**Hyprland** — Compositor Wayland de mosaico con animaciones. Nuestro escritorio.

**initramfs** — Mini sistema de archivos en RAM que el kernel carga primero, con los drivers
justos para poder montar tu disco real. Se genera con `mkinitcpio`.

**journald / journalctl** — El sistema de logs de systemd y su comando de consulta.

**Kernel** — Linux. El núcleo que habla con el hardware y gestiona procesos y memoria.

**Locale** — Configuración de idioma, formato de fecha, moneda y ordenación
(`es_CL.UTF-8`).

**Microcódigo** (`intel-ucode` / `amd-ucode`) — Parches de firmware para el CPU que se cargan
al arrancar. Corrigen bugs de hardware y vulnerabilidades (Spectre, Meltdown).

**Mirror** — Servidor espejo de los repositorios de Arch. `reflector` elige los más rápidos.

**Montar** — Asociar un sistema de archivos a un directorio del árbol
(`mount /dev/sdb1 /mnt/usb`). Al revés: `umount`.

**Nerd Font** — Fuente monoespaciada a la que se le han añadido miles de iconos (logos,
símbolos de Git, flechas). Necesaria para que Waybar y Starship se vean bien.

**pacman** — El gestor de paquetes de Arch. `paru` lo extiende al AUR.

**.pacnew** — Cuando actualizas un paquete cuyo archivo de configuración tú habías
modificado, pacman deja el nuevo con este sufijo en vez de sobrescribir el tuyo. Revísalos
con `pacdiff`.

**pacstrap** — Comando que instala el sistema base de Arch en un directorio (`/mnt`).

**Partición** — División lógica de un disco. Una partición tiene un tipo y contiene un
sistema de archivos.

**PipeWire** — Servidor de audio (y vídeo) moderno de Linux. Reemplaza a PulseAudio y JACK.

**PKGBUILD** — Receta de compilación de un paquete de Arch: de dónde bajar el código, cómo
compilarlo y qué archivos instalar.

**Polkit** — Sistema que decide si un proceso sin privilegios puede hacer una acción
privilegiada. El "agente" es la ventanita que pide tu contraseña.

**Repositorio (repo)** — Colección de paquetes. Los oficiales de Arch son `core`, `extra` y
`multilib`.

**Rolling release** — Modelo de distribución sin versiones: el sistema se actualiza
continuamente. Arch es rolling; Ubuntu no.

**Snapshot** — Foto instantánea de un subvolumen Btrfs. Ocupa casi nada al crearse y crece
solo con lo que cambia después. No es un respaldo (vive en el mismo disco).

**Subvolumen** — Unidad independiente dentro de un sistema de archivos Btrfs. Se le puede
hacer snapshot y montar con opciones propias. Usamos `@`, `@home`, `@log`, `@pkg`,
`@snapshots`.

**Swap** — Espacio en disco que el sistema usa como extensión de la RAM. Puede ser una
partición o un archivo.

**systemd** — El sistema de init (PID 1) de Arch: arranca y supervisa todos los servicios.
`systemctl` es su comando.

**Tiling window manager** — Gestor de ventanas que las acomoda automáticamente sin
superponerlas, navegable con teclado. Hyprland es uno.

**UEFI** — Firmware moderno de las placas base, sucesor del BIOS. Arranca leyendo archivos
`.efi` del ESP.

**UUID** — Identificador único y permanente de una partición o sistema de archivos. Se usa en
`fstab` porque los nombres `/dev/sdX` pueden cambiar.

**Wayland** — Protocolo de servidor gráfico moderno de Linux, sucesor de X11. Más simple y
seguro.

**wheel** — Grupo tradicional de Unix cuyos miembros pueden usar `sudo`.

**XWayland** — Capa de compatibilidad que permite correr aplicaciones X11 dentro de Wayland.

**X11 / Xorg** — El sistema de ventanas clásico de Linux (1984). Aún muy usado, pero en
retirada.

**Zsh** — Shell compatible con Bash pero con mejor autocompletado y personalización.
