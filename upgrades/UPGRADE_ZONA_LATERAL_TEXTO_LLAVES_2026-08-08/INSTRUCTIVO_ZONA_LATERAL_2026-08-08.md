# INSTRUCTIVO - UPGRADE "Zona del tablero: aclaración en Laterales"
**Fecha:** 2026-08-08
**Módulo:** Monitor de Vigilancia → pestaña **Llaves** (Agregar / Modificar)
**PC donde se aplica:** **MONITOR DE VIGILANCIA** (la que hace de servidor)

---

## ¿Qué cambia este upgrade?

En **Gestión de Llaves**, tanto en la pestaña **Agregar** como en **Modificar**,
el desplegable **"Zona del tablero"** ahora muestra una aclaración en los laterales:

- Antes: `Lateral izquierdo`
- Ahora: `Lateral izquierdo (espacio pequeño; no tiene número de fila, ni letra de columna)`

- Antes: `Lateral derecho`
- Ahora: `Lateral derecho (espacio pequeño; no tiene número de fila, ni letra de columna)`

> El **valor que se guarda es el mismo** (`Lateral izquierdo` / `Lateral derecho`).
> Solo cambia el **texto que se ve** en el desplegable. No se tocan datos.

### Recordatorio (comportamiento que YA estaba y es correcto)
- Al elegir un **lateral**, NO se piden fila ni columna (está bien así).
- Para el resto de zonas (**Fondo**, **Puerta izquierda**, **Puerta derecha**) SÍ se
  pueden **agregar y modificar** fila y columna.
- **Varias llaves pueden compartir la misma coordenada** (por ejemplo, varios nombres
  de llaves en **B4**). Esto ya funciona: no hay ninguna restricción que lo impida.

Este upgrade **NO toca PocketBase, NO borra datos y NO instala nada nuevo**.
Solo reemplaza el frontend compilado (`dist`) y deja un backup para poder revertir.

---

## Pasos para aplicar

1. Enchufá el **pendrive** en la PC del **MONITOR DE VIGILANCIA**.
2. Entrá a la carpeta `UPGRADE_ZONA_LATERAL_TEXTO_LLAVES_2026-08-08`.
3. Doble clic en **`1-APLICAR_ZONA_LATERAL.bat`**.
   - Si Windows pide permisos de administrador (UAC), aceptá con **Sí**.
4. Se abre una ventana azul de PowerShell. Va a:
   - Respaldar el `dist` actual en `C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`.
   - Copiar el frontend nuevo (preservando `config.json` y `system_health.json`).
5. Cuando diga **EXITO. Upgrade aplicado.**, presioná **ENTER** para cerrar.
6. **Cerrá el navegador / kiosko y volvelo a abrir** (si hace falta, `Ctrl + F5`).

---

## Cómo verificar que funcionó

1. En el Monitor, abrí **Gestión de Llaves**.
2. Andá a la pestaña **Modificar** (o **Agregar**).
3. Abrí el desplegable **"Zona del tablero"**.
4. Confirmá que los laterales aparecen con la aclaración entre paréntesis.
5. Elegí una zona **Fondo / Puerta izquierda / Puerta derecha** y verificá que
   podés escribir/editar **Fila** y **Columna** sin problema.

---

## Si algo sale mal (ROLLBACK)

1. En la misma PC (Monitor), doble clic en **`2-DESHACER_ZONA_LATERAL_ROLLBACK.bat`**.
2. Aceptá permisos de administrador.
3. Restaura automáticamente el último `dist_backup_*`.
4. Cerrá y abrí el navegador (`Ctrl + F5`).

---

## Aviso a Luis
Avisame acá en la laptop de desarrollo cuando lo probaste y **funcionó en producción**,
para hacer el commit con timestamp, subir a GitHub e integrar (ya está integrado en el
código fuente; falta solo confirmar y commitear tras tu OK).
