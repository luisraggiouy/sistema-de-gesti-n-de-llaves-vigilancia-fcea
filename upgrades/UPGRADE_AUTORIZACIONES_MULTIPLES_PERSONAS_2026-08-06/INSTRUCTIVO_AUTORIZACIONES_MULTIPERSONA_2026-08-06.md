# INSTRUCTIVO — Upgrade "Autorizaciones con VARIAS personas"
**Fecha:** 2026-08-06
**Módulo afectado:** Monitor de Vigilancia → *Agenda / Autorizaciones → Nueva*

---

## ¿Qué problema resuelve?

Antes, en **Autorizaciones → Nueva** solo se podía cargar **una persona** por
autorización. Cuando llegaba un mail con una lista (ej.: 6 personas de UAE
autorizadas para dar apoyo en el período de inscripciones), había que repetir
TODO el procedimiento 6 veces.

Con este upgrade, **una misma autorización puede incluir varias personas**.
Se cargan una sola vez el lugar, el autorizante, la vigencia, el horario, etc.,
y se agregan tantas personas como haga falta.

---

## ¿Qué cambia?

1. **Formulario "Nueva" con lista de personas.**
   - En vez de un solo "Nombre / CI", ahora hay una **lista de personas**.
   - Cada fila tiene **Nombre** y **CI (opcional)**.
   - Botón **"Agregar otra persona"** para sumar más filas.
   - Botón de tachito (papelera) para **quitar** una fila (siempre queda al menos una).

2. **Verificar sigue igual de simple.**
   - Al buscar por nombre o CI, la autorización aparece si **cualquiera** de
     las personas de la lista coincide.
   - En la tarjeta se ve un badge **"N personas autorizadas"** y el listado
     completo de nombres/CI.

3. **Historial** también muestra todas las personas de cada autorización.

> **Compatibilidad:** Las autorizaciones ya cargadas (de una sola persona)
> siguen viéndose y funcionando exactamente igual. No se pierde ni se toca
> ningún dato.

---

## ¿En qué PC se aplica?

En la PC que tiene instalado el sistema y donde se gestionan las autorizaciones:
**Monitor de Vigilancia** (`C:\sistema-llaves-fcea`).

*(Las Terminales A y B no usan esta pantalla, así que no hace falta aplicarlo ahí.)*

---

## Pasos

1. Enchufá el **pendrive** en el **Monitor de Vigilancia**.

2. Abrí la carpeta del pendrive:
   `UPGRADE_AUTORIZACIONES_MULTIPLES_PERSONAS_2026-08-06`

3. Doble clic en **`1-APLICAR_AUTORIZACIONES_MULTIPERSONA_EN_MONITOR.bat`**.
   - Si Windows pide permisos de administrador, aceptá (**Sí**).
   - Se abrirá una ventana negra que:
     - respalda el `dist` actual en `C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`,
     - copia el frontend nuevo.
   - Cuando diga **"EXITO. Upgrade aplicado."**, presioná **ENTER** para cerrar.

4. **Cerrá el navegador/kiosko** del Monitor y **volvé a abrirlo**.
   - Si no ves el cambio, hacé **Ctrl + F5** (recarga forzada) para limpiar caché.

5. **Probá:** Monitor → *Agenda / Autorizaciones → Nueva*.
   - Cargá el lugar y el autorizante.
   - Escribí la **primera persona** (nombre y CI opcional).
   - Tocá **"Agregar otra persona"** y cargá una segunda, una tercera, etc.
   - Guardá con **Registrar**.
   - Andá a **Verificar** y buscá por el nombre de alguna de las personas de la lista:
     debe aparecer la autorización con el badge **"N personas autorizadas"**.

6. Avisale a Cline en la laptop de desarrollo: **"funcionó"** o **"no funcionó"**.

---

## Si algo sale mal (ROLLBACK)

Doble clic en **`2-DESHACER_AUTORIZACIONES_MULTIPERSONA_ROLLBACK.bat`** (aceptá permisos de administrador).
Restaura automáticamente el último `dist_backup_*` (el frontend como estaba antes).
Después cerrá y volvé a abrir el navegador (Ctrl + F5).

---

## Notas técnicas (para Cline / referencia)

- Archivos fuente modificados:
  - `src/data/fceaData.ts`
    - Nueva interfaz `PersonaAutorizada { nombre; ci? }`.
    - `Autorizacion` gana campo opcional `personas?: PersonaAutorizada[]`.
      Los campos legacy `personaNombre`/`personaCI` se mantienen = **primera
      persona** (compat con búsqueda, historial y export existentes).
    - Nuevo helper `getPersonasAutorizadas(a)` (normaliza viejas y nuevas).
    - `buscarAutorizacionEnVivo`: ahora matchea contra **todas** las personas.
  - `src/components/monitor/AutorizacionesTab.tsx`
    - Form con lista dinámica de personas (agregar/quitar filas).
    - `AutorizacionCard` lista todas las personas + badge de cantidad.
  - `src/components/monitor/HistorialAutorizacionesTab.tsx`
    - `HistorialCard` lista todas las personas + badge de cantidad.
- El paquete incluye el `dist` recompilado (`npm run build`).
- La copia se hace con `robocopy /MIR` para eliminar assets viejos con hash distinto.
- No hay migración de datos: los registros viejos se leen igual gracias a `getPersonasAutorizadas`.
