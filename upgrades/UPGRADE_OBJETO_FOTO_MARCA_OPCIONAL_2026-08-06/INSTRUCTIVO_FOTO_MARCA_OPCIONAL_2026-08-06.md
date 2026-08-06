# INSTRUCTIVO — Upgrade "Foto de la marca OPCIONAL + área de foto CUADRADA"
**Fecha:** 2026-08-06
**Módulo afectado:** Monitor de Vigilancia → *Registrar Objeto Olvidado*

---

## ¿Qué cambia este upgrade?

1. **"Foto de la marca" pasa a ser OPCIONAL.**
   - Antes tenía un asterisco rojo (`*`) y no dejaba registrar sin esa foto.
   - Ahora dice **"Foto de la marca (opcional)"**, **sin asterisco**, y se puede
     registrar el objeto solo con la **Foto general**.
   - La única foto obligatoria (si NO se marca "Registrar sin fotos") sigue siendo
     la **Foto general**.

2. **El área de la foto ahora es CUADRADA** (mismo alto que ancho).
   - Antes era un rectángulo bajo y ancho, incómodo para objetos verticales
     (ej.: botella térmica había que acostarla).
   - Ahora es un cuadrado, más cómodo para encuadrar objetos parados o acostados.

> Nada de esto toca PocketBase ni los datos. Solo se reemplaza el **frontend
> compilado** (`dist`). Se crea un backup automático para poder volver atrás.

---

## ¿En qué PC se aplica?

En la PC que tiene instalado el sistema y donde se registran los objetos:
**Monitor de Vigilancia** (`C:\sistema-llaves-fcea`).

*(Las Terminales A y B no usan esta pantalla, así que no hace falta aplicarlo ahí.)*

---

## Pasos

1. Enchufá el **pendrive** en el **Monitor de Vigilancia**.

2. Abrí la carpeta del pendrive:
   `UPGRADE_OBJETO_FOTO_MARCA_OPCIONAL_2026-08-06`

3. Doble clic en **`1-APLICAR_FOTO_MARCA_OPCIONAL_EN_MONITOR.bat`**.
   - Si Windows pide permisos de administrador, aceptá (**Sí**).
   - Se abrirá una ventana negra que:
     - respalda el `dist` actual en `C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`,
     - copia el frontend nuevo.
   - Cuando diga **"EXITO. Upgrade aplicado."**, presioná **ENTER** para cerrar.

4. **Cerrá el navegador/kiosko** del Monitor y **volvé a abrirlo**.
   - Si no ves el cambio, hacé **Ctrl + F5** (recarga forzada) para limpiar caché.

5. **Probá:** Monitor → *Registrar Objeto Olvidado*.
   - Verificá que **"Foto de la marca (opcional)"** NO tenga asterisco rojo.
   - Verificá que puedas **registrar solo con la Foto general**.
   - Verificá que el **área de la foto sea cuadrada**.

6. Avisale a Cline en la laptop de desarrollo: **"funcionó"** o **"no funcionó"**.

---

## Si algo sale mal (ROLLBACK)

Doble clic en **`2-DESHACER_FOTO_MARCA_OPCIONAL_ROLLBACK.bat`** (aceptá permisos de administrador).
Restaura automáticamente el último `dist_backup_*` (el frontend como estaba antes).
Después cerrá y volvé a abrir el navegador (Ctrl + F5).

---

## Notas técnicas (para Cline / referencia)

- Archivos fuente modificados:
  - `src/components/monitor/RegistroObjetoModal.tsx`
    - `isValid`: ya no exige `fotoMarca`.
    - Etiqueta cambiada a "Foto de la marca (opcional)" y se quitó `required`.
  - `src/components/monitor/WebcamCapture.tsx`
    - Área de captura/preview: `h-40` → `aspect-square` (cuadrado).
- El paquete incluye el `dist` recompilado (`npm run build`).
- La copia se hace con `robocopy /MIR` para eliminar assets viejos con hash distinto.
