# UPGRADE: Monitor — autoscroll 8s + buscador a la izquierda + notas en 1 renglón

**Fecha:** 2026-09-05
**Aplicar en:** LAS 3 PC (Monitor de Vigilancia, Terminal A y Terminal B)

---

## Qué hace este upgrade

Tres cambios simples de interfaz (todos en el frontend compilado `dist`):

1. **Autoscroll a 8 segundos.** En el **Monitor de Vigilancia**, el retorno
   automático al encabezado ahora se activa a los **8 segundos** de inactividad
   (antes eran 4). Da más tiempo antes de que la pantalla suba sola.

2. **Buscador de "Llaves en Uso" a la izquierda.** La caja de texto del buscador,
   que quedaba pegada al **borde derecho**, ahora va a la **izquierda**: en la
   misma línea que el título **"Llaves en Uso"** y **a la derecha del badge**
   contador (orden: título → badge → buscador).

3. **Notas en un solo renglón.** En cada tarjeta de **"Llave en Uso"**, el campo
   de **Notas** pasa de ocupar **2 renglones** (label arriba, campo abajo) a
   **un solo renglón**: el ícono, la palabra "Notas" y el campo van todos en la
   misma línea. Así se ahorra espacio vertical y hay que scrollear menos cuando
   hay muchas llaves en uso.

---

## Por qué va en LAS 3 PC

El `dist` (frontend compilado) **no se sirve centralizado**: cada PC corre su
propio `vite preview` en `127.0.0.1:5173` sirviendo el `dist` de **su propio
disco**. Si el upgrade se aplica solo en el Monitor, las Terminales A y B
seguirían con el JavaScript viejo. Por eso hay que ejecutar el mismo script
**una vez en cada PC**.

---

## Cómo aplicarlo (en CADA una de las 3 PC)

1. Enchufá el pendrive "cable" (normalmente `D:`).
2. Entrá a la carpeta
   `upgrades\UPGRADE_MONITOR_AUTOSCROLL_BUSCADOR_NOTAS_2026-09-05`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pedirá permisos de administrador).
4. Cuando diga **EXITO**, cerrá el navegador/kiosko y volvé a abrirlo (Ctrl+F5).
5. Repetí los pasos 1-4 en las otras dos PC.

El script hace un **backup automático** del `dist` actual
(`C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`) antes de copiar el nuevo, y
**preserva `config.json` y `system_health.json`** (la config de red de cada PC).

---

## Cómo probarlo (en el Monitor de Vigilancia)

1. **Autoscroll:** con contenido suficiente, scrolleá hacia abajo y dejá de tocar
   todo. Debe tardar **8 segundos** (antes 4) en volver solo al encabezado.
2. **Buscador:** con al menos 1 llave en uso, el campo de búsqueda aparece a la
   **izquierda**, junto al título "Llaves en Uso" y a la derecha del badge.
3. **Notas:** en cada tarjeta de llave en uso, el ícono, "Notas" y el campo de
   texto están todos en la **misma línea** (un solo renglón).

---

## Rollback (si algo saliera mal)

En la MISMA PC, doble clic en **`2-DESHACER_ROLLBACK.bat`**. Restaura el último
`dist_backup_*` que dejó el script al aplicar.

---

## Archivos modificados (para el registro)

- `src/pages/MonitorVigilancia.tsx`
  - autoscroll: `setTimeout(volverAlEncabezado, 8000)` (antes `4000`).
  - buscador "Llaves en Uso": se quitó `ml-auto` del contenedor del
    `ClearableInput` para alinearlo a la izquierda junto al título/badge.
- `src/components/monitor/KeyInUseCard.tsx`
  - sección Notas: ícono + label "Notas" + `ClearableTextarea` en un mismo
    contenedor `flex items-center` (campo con `flex-1`, altura `h-9`), en lugar
    de label en una fila y campo en la fila de abajo.
