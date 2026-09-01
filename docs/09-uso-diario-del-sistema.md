# 09 — Uso diario del sistema

> Manual de referencia. No hace falta leerlo de corrido; vuelve aquí cuando necesites algo.

---

## 1. pacman — el gestor de paquetes

```bash
sudo pacman -Syu                # actualizar TODO el sistema (el comando más importante)
sudo pacman -S firefox          # instalar
sudo pacman -S --needed vim git # instalar solo lo que falte
sudo pacman -R firefox          # desinstalar (deja las dependencias)
sudo pacman -Rns firefox        # desinstalar + dependencias huérfanas + configs. El preferido.

pacman -Ss editor               # buscar en los repos
pacman -Qs editor               # buscar entre lo instalado
pacman -Qi firefox              # info detallada de un paquete instalado
pacman -Ql firefox              # qué archivos instaló
pacman -Qo /usr/bin/firefox     # qué paquete es dueño de este archivo
pacman -Qe                      # paquetes que instalé explícitamente
pacman -Qdt                     # huérfanos (nadie los necesita ya)
pacman -Qm                      # paquetes del AUR (foráneos)

sudo pacman -Rns $(pacman -Qdtq)   # limpiar huérfanos
sudo pacman -Sc                    # limpiar caché de paquetes viejos
```

Con AUR (`paru` entiende toda la sintaxis de pacman):

```bash
paru                # actualizar repos oficiales + AUR
paru -S spotify     # instalar de donde sea
paru -Ss spotify    # buscar en ambos
```

### Las reglas de oro

1. ⚠️ **Nunca `pacman -Sy paquete`.** Siempre `-Syu` o `-S` sin `-y`.
2. ⚠️ **Nunca actualices parcialmente.** Arch es *rolling release*: o actualizas todo, o nada.
3. **Lee la salida.** Si aparece `.pacnew`, hay que revisarlo (sección 6).
4. Antes de actualizar, mira https://archlinux.org/news/ — ahí se anuncian las
   intervenciones manuales necesarias.

## 2. systemd — servicios

```bash
systemctl status docker            # estado de un servicio
sudo systemctl start docker        # arrancar ahora
sudo systemctl stop docker         # detener ahora
sudo systemctl restart docker
sudo systemctl enable docker       # arrancar en cada inicio
sudo systemctl disable docker
sudo systemctl enable --now docker # ambas cosas

systemctl list-units --type=service --state=running   # qué está corriendo
systemctl list-unit-files --state=enabled             # qué arranca solo
systemctl --failed                                    # qué falló
```

Servicios de usuario (los que corren en tu sesión, como PipeWire):

```bash
systemctl --user status pipewire
systemctl --user restart wireplumber
```

## 3. journalctl — los logs

```bash
journalctl -b                  # logs del arranque actual
journalctl -b -1               # del arranque anterior (útil tras un cuelgue)
journalctl -b -p err           # solo errores de este arranque
journalctl -u docker -f        # seguir en vivo los logs de un servicio
journalctl -u docker --since "1 hour ago"
journalctl --since today
journalctl -k                  # mensajes del kernel (dmesg)
journalctl --disk-usage
sudo journalctl --vacuum-size=500M     # limitar el tamaño de los logs
```

💡 **Tu primer reflejo cuando algo falla debe ser `journalctl -b -p err`.** Casi siempre la
respuesta está ahí.

## 4. Comandos de sistema esenciales

```bash
# Información
fastfetch                      # resumen bonito del sistema
uname -r                       # versión del kernel
hostnamectl                    # hostname, SO, hardware
lsblk -f                       # discos, particiones y sistemas de archivos
df -h                          # espacio libre por punto de montaje
btrfs filesystem usage /       # espacio real en Btrfs (df miente con Btrfs)
free -h                        # memoria RAM y swap
lspci / lsusb                  # hardware PCI / USB
sensors                        # temperaturas (paquete lm_sensors, ejecuta sensors-detect)

# Procesos
btop                           # monitor interactivo
ps aux | grep dotnet
kill -15 <pid>                 # pedir que termine (educado)
kill -9 <pid>                  # matar (último recurso)
pkill -f "dotnet run"          # matar por nombre de comando

# Red
ip -brief address              # tus IPs
nmcli device status
nmcli device wifi list
nmcli device wifi connect "Red" --ask
ss -tulpn                      # qué está escuchando en qué puerto
ping -c 3 archlinux.org
```

## 5. Permisos y archivos

```bash
ls -l archivo         # -rw-r--r-- 1 nestor users  ...
```

Lectura del modo: `- rwx rw- r--` → tipo · **dueño** · **grupo** · **otros**.

```bash
chmod +x script.sh             # hacerlo ejecutable
chmod 644 archivo              # rw- r-- r--
chmod 755 directorio           # rwx r-x r-x
chmod 600 ~/.ssh/id_ed25519    # solo yo (obligatorio para claves SSH)
chown nestor:nestor archivo
sudo chown -R nestor:nestor carpeta/
```

Números: lectura=4, escritura=2, ejecución=1. `755` = `7`(4+2+1) para el dueño,
`5`(4+1) para grupo y otros.

## 6. Archivos `.pacnew` y `.pacsave`

Cuando actualizas un paquete y **tú** habías modificado su archivo de configuración, pacman
no lo sobrescribe: deja el nuevo al lado como `archivo.pacnew`.

```bash
sudo pacman -S --needed pacdiff-git   # viene en pacman-contrib
sudo pacman -S --needed pacman-contrib
sudo DIFFPROG=nvim pacdiff            # revisar interactivamente
```

`pacdiff` te muestra las diferencias y pregunta qué hacer con cada una. Ignorarlos durante
meses es una fuente clásica de comportamientos raros.

## 7. Atajos de Hyprland (resumen rápido)

Ver el listado completo en [doc 04](04-entorno-grafico-hyprland.md#5-atajos-de-teclado-principales).
Los diez que usarás siempre:

```
Super + Return      terminal
Super + D           lanzador
Super + Q           cerrar ventana
Super + 1..9        cambiar de espacio
Super + Shift + 1..9  mover ventana a un espacio
Super + F           pantalla completa
Super + V           flotante / mosaico
Super + L           bloquear
Print               captura de área
Super + Shift + E   menú de apagado
```

## 8. Gestión de energía

```bash
systemctl suspend         # suspender a RAM
systemctl hibernate       # hibernar a disco (requiere swap ≥ RAM y resume=)
systemctl poweroff
systemctl reboot

powerprofilesctl set power-saver   # ahorro / balanced / performance
brightnessctl set 50%
brightnessctl set +10%
```

## 9. Archivos y compresión

```bash
tar -czf backup.tar.gz carpeta/       # comprimir
tar -xzf backup.tar.gz                # descomprimir
tar -tzf backup.tar.gz                # listar sin extraer
zip -r proyecto.zip proyecto/
unzip proyecto.zip
7z a archivo.7z carpeta/

rsync -avh --progress origen/ destino/          # copiar con progreso
rsync -avh --delete ~/dev/ /mnt/backup/dev/     # espejo exacto (⚠️ --delete borra)
```

## 10. Montar discos USB

Thunar los monta con un clic. A mano:

```bash
lsblk -f                                  # identificar, ej. /dev/sdb1
sudo mkdir -p /mnt/usb
sudo mount /dev/sdb1 /mnt/usb
sudo umount /mnt/usb                      # ⚠️ SIEMPRE antes de desconectar
```

Para discos con NTFS (de Windows):

```bash
sudo pacman -S --needed ntfs-3g
sudo mount -t ntfs3 /dev/sdb1 /mnt/usb
```

## 11. Alias recomendados

Ya vienen en el `.zshrc` de este repo:

```bash
alias ll='eza -la --icons --git'
alias ls='eza --icons'
alias lt='eza --tree --level=2 --icons'
alias cat='bat --paging=never'
alias grep='rg'
alias update='paru -Syu'
alias orphans='pacman -Qdtq'
alias cleanup='sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || echo "sin huérfanos"'
alias logs='journalctl -b -p err --no-pager'
alias ports='ss -tulpn'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias lg='lazygit'
alias db-up='docker compose -f ~/dev/infra/docker-compose.yml up -d'
alias db-down='docker compose -f ~/dev/infra/docker-compose.yml stop'
alias cc='claude'
```

## 12. Cuando algo no funciona: el método

1. **¿Qué dice el log?** `journalctl -b -p err` o `systemctl status <servicio>`.
2. **¿Cambié algo?** `grep -i upgraded /var/log/pacman.log | tail -20` te dice qué se
   actualizó hoy.
3. **¿Está en las noticias?** https://archlinux.org/news/
4. **¿Está en la wiki?** https://wiki.archlinux.org — busca el nombre exacto del error.
5. **Pregúntale a Claude Code** con el log pegado:
   ```bash
   claude '!journalctl -b -p err --no-pager | tail -40' "¿qué está fallando?"
   ```
6. **Si nada funciona:** vuelve a un snapshot ([doc 10](10-mantenimiento-y-snapshots.md)).

---

**Siguiente:** [10 — Mantenimiento y snapshots](10-mantenimiento-y-snapshots.md)
