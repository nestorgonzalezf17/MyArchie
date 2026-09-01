# Scripts

| Script | Cuándo se usa | Dónde se ejecuta |
|---|---|---|
| `instalar-myarchie.sh` | Instalar el sistema en un disco | Desde el ISO en vivo, como root |
| `postinstalacion-myarchie.sh` | Tras el primer arranque: AUR, temas, Claude Code | Sistema instalado, como tu usuario |
| `verificar-stack.sh` | Comprobar que todo el stack está | Cualquier momento |
| `actualizar-seguro.sh` | Rutina semanal de actualización | Cualquier momento |
| `backup-home.sh` | Respaldo a un disco externo | Con el disco montado |

⚠️ `instalar-myarchie.sh` **borra un disco entero**. Lee el
[doc 02](../docs/02-instalacion-base-manual.md) antes: el objetivo del proyecto es entender
lo que hace, no solo ejecutarlo.

Todos aceptan `bash -n` (comprobación de sintaxis) y están escritos con `set -euo pipefail`:
se detienen ante el primer error en vez de continuar dejando el sistema a medias.
