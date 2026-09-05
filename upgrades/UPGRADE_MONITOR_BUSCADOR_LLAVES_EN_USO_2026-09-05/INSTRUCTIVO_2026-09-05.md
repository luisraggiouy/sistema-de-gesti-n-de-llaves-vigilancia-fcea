# UPGRADE: Buscador en "Llaves en Uso" (Monitor de Vigilancia)

**Fecha:** 2026-09-05
**Aplicar en:** LAS 3 PC (Monitor de Vigilancia, Terminal A y Terminal B)

---

## Qué hace este upgrade

En el **Monitor de Vigilancia**, la sección **"Llaves en Uso"** ahora tiene:

1. **Buscador al lado del título.** Siempre que haya **al menos 1 llave en uso**,
   aparece un campo de búsqueda a la derecha del título "Llaves en Uso".
   Filtra la lista **en vivo** por:
   - **nombre de la llave / salón**, y
   - **nombre de la persona** que la tiene.

   Usa el mismo criterio que el buscador de las Terminales: no distingue
   mayúsculas ni acentos, y muestra primero los resultados que **empiezan**
   con lo que escribiste. Tiene una **"X"** para borrar la búsqueda de un
   solo click.

2. **Contador dinámico.** Mientras buscás, el cartelito del título muestra
   **"X de Y en uso"** (ej.: *"3 de 22 en uso"*). Sin búsqueda, muestra el
   total normal (*"22 en uso"*).

3. **Orden garantizado (última arriba).** Antes "Llaves en Uso" salía en el
   orden crudo de la base (sin orden garantizado). Ahora se ordena por
   **hora de entrega descendente**: la **última llave entregada queda arriba**.

El objetivo: con 20+ llaves en uso, el vigilante ya **no tiene que scrollear**
buscando; escribe el salón o la persona y la encuentra al instante.

> **Nota UX/táctil:** se mantiene **una tarjeta por renglón** (no se cambió el
> layout ni el tamaño de los botones de devolución/intercambio). El campo de
> búsqueda tiene altura táctil cómoda (h-11).

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
   `upgrades\UPGRADE_MONITOR_BUSCADOR_LLAVES_EN_USO_2026-09-05`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pedirá permisos de administrador).
4. Cuando diga **EXITO**, cerrá el navegador/kiosko y volvé a abrirlo (Ctrl+F5).
5. Repetí los pasos 1-4 en las otras dos PC.

El script hace un **backup automático** del `dist` actual
(`C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`) antes de copiar el nuevo, y
**preserva `config.json` y `system_health.json`** (la config de red de cada PC).

---

## Cómo probarlo (en el Monitor de Vigilancia)

1. Con **al menos 1 llave en uso** ya aparece el buscador junto al título.
2. Al lado del título **"Llaves en Uso"**, escribí un salón (ej. "101") o una
   persona (ej. "Cavani").
3. La lista se **filtra en vivo** y el contador muestra **"X de Y en uso"**.
4. La **"X"** del campo limpia la búsqueda de un click.
5. Verificá que la **última llave entregada** aparezca arriba de la lista.
6. Si buscás algo que no existe, aparece **"Sin resultados"** con botón
   *"Limpiar búsqueda"*.

---

## Rollback (si algo saliera mal)

En la MISMA PC, doble clic en **`2-DESHACER_ROLLBACK.bat`**. Restaura el último
`dist_backup_*` que dejó el script al aplicar.

---

## Archivo modificado (para el registro)

- `src/pages/MonitorVigilancia.tsx` — sección "Llaves en Uso":
  estado `busquedaEnUso`, cálculo `entregadasOrdenadas` (orden por
  `horaEntrega` desc.) y `entregadasFiltradas` (filtro por nombre de llave y
  persona con `normalizarTexto` + ranking "empieza con"), input `ClearableInput`
  con lupa a la derecha del título, badge dinámico "X de Y en uso" y estado
  vacío de búsqueda. **No se modificó `KeyInUseCard.tsx`.**
