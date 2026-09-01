# 10 — Mantenimiento, snapshots y respaldos

> Arch es *rolling release*: se actualiza continuamente, sin versiones. Eso es una ventaja
> (siempre lo último) y un riesgo (una actualización puede romper algo). Este documento es
> tu seguro.

---

## 1. Rutina de actualización segura

```bash
# 1. ¿Hay avisos que requieran intervención manual?
#    → https://archlinux.org/news/  (revísalo SIEMPRE antes de una actualización grande)

# 2. Snapshot manual con etiqueta (snap-pac ya hace uno automático, esto es tu red extra)
sudo snapper -c root create --description "antes de actualizar $(date +%F)"

# 3. Actualizar
paru

# 4. Revisar archivos .pacnew
sudo pacdiff

# 5. Si tocó el kernel o drivers de video, reinicia
```

Frecuencia recomendada: **una vez por semana**. Actualizar a diario multiplica las
probabilidades de tropezar con un paquete recién publicado con un bug; dejarlo tres meses
hace la actualización mucho más arriesgada por acumulación de cambios.

## 2. Snapshots con Snapper

Configurado en el [doc 03](03-post-instalacion.md#11-snapshots-automáticos-tu-red-de-seguridad).

```bash
sudo snapper -c root list                    # ver todos
sudo snapper -c root create -d "descripción" # crear uno manual
sudo snapper -c root delete 42               # borrar el número 42
sudo snapper -c root status 41..42           # qué archivos cambiaron entre dos snapshots
sudo snapper -c root diff 41..42 /etc/fstab  # ver el diff de un archivo concreto
```

### Restaurar archivos sueltos (lo más común)

Los snapshots están montados y son navegables como carpetas normales:

```bash
ls /.snapshots/42/snapshot/etc/
sudo cp /.snapshots/42/snapshot/etc/pacman.conf /etc/pacman.conf
```

💡 En el 90 % de los casos esto es todo lo que necesitas: recuperar el archivo de
configuración que rompiste.

### Deshacer una actualización entera

```bash
sudo snapper -c root undochange 41..42
```

Esto revierte los cambios de archivos entre los dos snapshots, dejando el sistema como estaba.
Si el problema fue una actualización de pacman, `snap-pac` habrá creado el par
"pre"/"post" con el comando exacto en la descripción.

### Restaurar cuando el sistema NO arranca

1. Arranca con el USB de Arch.
2. Monta el sistema de archivos raíz (sin subvolumen, la raíz "de verdad"):
   ```bash
   mount /dev/nvme0n1p2 /mnt
   ls /mnt          # verás @, @home, @snapshots...
   ```
3. Renombra el subvolumen roto y pon el snapshot en su lugar:
   ```bash
   mv /mnt/@ /mnt/@roto
   btrfs subvolume snapshot /mnt/@snapshots/42/snapshot /mnt/@
   ```
4. Desmonta y reinicia:
   ```bash
   umount /mnt && reboot
   ```
5. Si arranca bien, borra el viejo: `sudo btrfs subvolume delete /@roto`.

⚠️ Los números de snapshot en `/mnt/@snapshots/N/snapshot` corresponden a los que ves con
`snapper list`. Elige uno **anterior** al problema.

### Menú de arranque con snapshots (opcional, muy cómodo)

```bash
paru -S grub-btrfs   # requiere GRUB en vez de systemd-boot
```

⚠️ `grub-btrfs` no funciona con systemd-boot. Si quieres poder elegir un snapshot desde el
menú de arranque, tendrías que migrar a GRUB. Con systemd-boot, el método de recuperación
es el manual de arriba — perfectamente válido y solo tarda 5 minutos.

## 3. Respaldo de tus datos (los snapshots NO son un respaldo)

💡 **Importante:** un snapshot vive en el mismo disco. Si el disco muere, se van los dos.
Un respaldo de verdad está **en otro dispositivo**.

### Opción A — rsync a un disco externo

```bash
sudo pacman -S --needed rsync

# monta el disco externo en /mnt/backup y:
rsync -avh --delete --progress \
  --exclude='.cache' --exclude='node_modules' --exclude='bin/' --exclude='obj/' \
  --exclude='.venv' --exclude='target/' \
  ~/ /mnt/backup/home-nestor/
```

Script listo en [`scripts/backup-home.sh`](../scripts/backup-home.sh).

### Opción B — Btrfs send/receive (incremental y muy rápido)

Si el disco externo también es Btrfs:

```bash
sudo btrfs subvolume snapshot -r /home /.snapshots/home-$(date +%F)
sudo btrfs send /.snapshots/home-$(date +%F) | sudo btrfs receive /mnt/backup/
```

### Opción C — Restic (cifrado, deduplicado, a la nube o a disco)

```bash
sudo pacman -S --needed restic

export RESTIC_REPOSITORY=/mnt/backup/restic
export RESTIC_PASSWORD_FILE=~/.restic-pass

restic init
restic backup ~/dev ~/Documentos ~/.config --exclude-file ~/.restic-excludes
restic snapshots
restic restore latest --target /tmp/restauracion
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
```

### Qué respaldar como mínimo

- `~/dev` — tu código (aunque también esté en Git)
- `~/dotfiles` — tu configuración
- `~/.ssh` y `~/.gnupg` — tus llaves (⚠️ cífralas)
- `~/Documentos`, `~/Imágenes`
- `~/dev/infra/backups/*.bak` — tus bases de datos
- La lista de paquetes (siguiente sección)

## 4. La lista de paquetes: tu sistema como código

```bash
mkdir -p ~/dotfiles/paquetes
pacman -Qqen > ~/dotfiles/paquetes/oficiales.txt   # de repos oficiales
pacman -Qqem > ~/dotfiles/paquetes/aur.txt         # del AUR
```

Para reinstalar todo en una máquina nueva:

```bash
sudo pacman -S --needed - < ~/dotfiles/paquetes/oficiales.txt
paru -S --needed - < ~/dotfiles/paquetes/aur.txt
```

💡 Estos dos archivos + tus dotfiles = tu sistema entero reproducible. Es también la base
del [doc 11](11-empaquetar-tu-iso.md). Automatízalo con un hook de pacman:

```bash
sudo tee /etc/pacman.d/hooks/99-lista-paquetes.hook > /dev/null <<'HOOK'
[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Guardando la lista de paquetes explícitos...
When = PostTransaction
Exec = /usr/bin/su nestor -c '/usr/bin/pacman -Qqen > /home/nestor/dotfiles/paquetes/oficiales.txt; /usr/bin/pacman -Qqem > /home/nestor/dotfiles/paquetes/aur.txt'
HOOK
```

(Cambia `nestor` por tu usuario.)

## 5. Limpieza periódica

```bash
# Caché de pacman: conservar solo las 2 últimas versiones de cada paquete
sudo pacman -S --needed pacman-contrib
sudo paccache -rk2
sudo paccache -ruk0            # borrar el caché de paquetes ya desinstalados

# Caché de paru (AUR)
paru -Sc

# Paquetes huérfanos
sudo pacman -Rns $(pacman -Qdtq)

# Logs
sudo journalctl --vacuum-time=4weeks

# Docker (⚠️ revisa antes: -a borra imágenes no usadas)
docker system df
docker system prune -a

# Caché del usuario
du -sh ~/.cache/* | sort -h | tail -20
rm -rf ~/.cache/thumbnails/*

# Ver qué ocupa espacio
sudo pacman -S --needed ncdu
ncdu /
```

Automatiza el `paccache` con su timer:

```bash
sudo systemctl enable --now paccache.timer
```

## 6. Comprobación de salud

```bash
# SMART del disco
sudo pacman -S --needed smartmontools
sudo smartctl -a /dev/nvme0n1 | grep -Ei 'health|error|percentage'

# Btrfs: scrub verifica las sumas de comprobación de TODOS los datos
sudo btrfs scrub start /
sudo btrfs scrub status /
# Programa uno mensual:
sudo systemctl enable --now btrfs-scrub@-.timer

# Espacio real en Btrfs (df da números engañosos)
sudo btrfs filesystem usage /

# Servicios que fallaron
systemctl --failed

# Tiempo de arranque
systemd-analyze
systemd-analyze blame | head -15
```

## 7. Qué hacer si una actualización rompe algo

**Orden de acciones, de menos a más drástico:**

1. Reinicia. En serio: muchos problemas tras actualizar el kernel o los drivers se arreglan
   solos al reiniciar.
2. Mira el log: `journalctl -b -p err`.
3. Mira qué se actualizó: `grep -i upgraded /var/log/pacman.log | tail -30`.
4. **Degrada solo ese paquete** desde el caché local:
   ```bash
   ls /var/cache/pacman/pkg/ | grep nombre-del-paquete
   sudo pacman -U /var/cache/pacman/pkg/nombre-1.2.3-1-x86_64.pkg.tar.zst
   ```
   O con la herramienta `downgrade`:
   ```bash
   paru -S downgrade
   sudo downgrade nombre-del-paquete
   ```
   Para que la próxima `-Syu` no lo vuelva a subir, añade en `/etc/pacman.conf`:
   `IgnorePkg = nombre-del-paquete` (⚠️ y quítalo cuando el bug se corrija).
5. **Revierte el snapshot** (sección 2).
6. Arranca con la entrada **fallback** de systemd-boot si el problema es el initramfs.
7. Arranca con el USB y repara en chroot ([doc 12](12-solucion-de-problemas.md)).

## 8. Calendario sugerido

| Frecuencia | Tarea |
|---|---|
| Diario | Nada. Trabaja. |
| Semanal | `paru`, revisar `.pacnew`, respaldo de `~/dev` |
| Mensual | `paccache -rk2`, huérfanos, `btrfs scrub`, respaldo completo, verificar que un backup **restaura** |
| Trimestral | Revisar `systemd-analyze blame`, limpiar paquetes que ya no usas, actualizar la lista de paquetes del repo |

⚠️ **Un respaldo que nunca has restaurado no es un respaldo.** Prueba la restauración al
menos una vez.

---

**Siguiente:** [11 — Empaquetar tu propia ISO](11-empaquetar-tu-iso.md)
