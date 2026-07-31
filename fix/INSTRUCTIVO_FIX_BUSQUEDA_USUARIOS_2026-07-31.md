# INSTRUCTIVO — Fix búsqueda de usuarios por teléfono (duplicados)
**Fecha:** 2026-07-31

## Qué arregla
En la búsqueda por teléfono (identificarse en Terminal A / B):
1. Un mismo usuario aparecía **duplicado** (×2 / ×3) en el listado.
2. Aparecía un usuario que **NO coincidía** con los dígitos tipeados.

## Causa (confirmada con diagnóstico)
El diagnóstico `DIAGNOSTICO_DUPLICADOS_USUARIOS_2026-07-31` confirmó que en la
base **NO hay usuarios duplicados** (cada teléfono tiene 1 sola fila). Era un
problema de **render del frontend**: la suscripción en tiempo real agregaba el
mismo registro varias veces en memoria → React renderizaba filas repetidas y
"fantasma". El fix es **solo de código**, no se toca la base de datos.

## Qué cambió en el código
En `src/hooks/useUsuariosRegistrados.ts`:
- La lista de usuarios ahora se mantiene **siempre deduplicada por `id`**
  (upsert) en la carga inicial, en la suscripción (create/update) y al
  registrar.
- El filtro por teléfono pasó de `includes` (subcadena) a **`startsWith`**
  (coincidencia estricta por prefijo).

## ⚠️ Importante
- **NO toca** PocketBase, NI la base de datos, NI borra usuarios.
- Solo reemplaza el frontend compilado (`index.html` + `assets\`).
- **No toca** `config.json` ni `system_health.json` (propios de cada PC).
- Hace **backup automático** antes de reemplazar (para rollback).

## Dónde aplicar
En **Terminal A** y **Terminal B** (son las que identifican por teléfono).
Opcionalmente también en el **Monitor**. Se puede correr en las 3.
> Sugerencia: probalo primero en **Terminal A**, confirmá que anda, y después
> replicás en Terminal B.

## Pasos
1. Enchufá el pendrive en la **Terminal A**.
2. Entrá a la carpeta `D:\FIX\fix_busqueda_usuarios_2026-07-31\`.
3. Doble clic en **`APLICAR_FIX_BUSQUEDA_USUARIOS_2026-07-31.bat`**.
4. Esperá el mensaje **"FIX APLICADO"**.
5. **Recargá el frontend**: cerrá el kiosko (Alt+F4) y volvé a abrirlo, o
   reiniciá la PC.
6. Probá identificarte con el teléfono `099098765`:
   - Debe aparecer **Lionel Messi UNA sola vez**.
   - **NO** debe aparecer Juan Peiras.
7. Repetí los pasos 1–6 en la **Terminal B**.

## Verificación rápida (que quede bien)
- Tipeá un teléfono y verificá que cada usuario aparece **una sola vez**.
- Verificá que solo aparecen usuarios cuyo teléfono **empieza** con lo tipeado.

## Rollback (si algo sale mal)
El script dejó una copia en:
`C:\sistema-llaves-fcea\backup_fix_busqueda_<fecha_hora>\`
Copiá `index.html` y la carpeta `assets\` de ese backup de vuelta sobre
`C:\sistema-llaves-fcea\dist\` y recargá.

## Después de probar
Avisame acá en la laptop de desarrollo si funcionó bien. Recién ahí hago el
commit, subo a GitHub e integro a los scripts críticos (Instalar / Recuperar).
