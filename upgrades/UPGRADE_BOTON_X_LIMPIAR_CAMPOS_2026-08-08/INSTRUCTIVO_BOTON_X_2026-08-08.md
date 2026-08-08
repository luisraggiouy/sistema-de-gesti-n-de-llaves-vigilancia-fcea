# UPGRADE: Botón "X" para borrar todo el texto de un campo
**Fecha:** 2026-08-08
**Aplicar en:** Monitor de Vigilancia (la PC que hace de servidor)
**Tipo:** Upgrade de frontend (solo reemplaza el `dist`). NO toca PocketBase, NO borra datos.

---

## ¿Qué hace este upgrade?

En los campos de texto de **carga manual** ahora aparece una **"X" a la derecha**
(solo cuando el campo tiene texto). Al hacerle clic, **borra TODO el texto de una vez**,
además del backspace de siempre (que sigue borrando letra por letra).

Se aplicó en **TODOS los campos de texto donde se escribe manualmente**, incluidos los buscadores:
- **Gestión de Llaves** (pestañas *Agregar* y *Modificar*): **Nombre** y **Columna**.
- **Objetos Olvidados**:
  - *Buscar*: **Descripción** y **Lugar**.
  - *Registrar objeto*: **Descripción breve** y **Lugar donde se encontró**.
  - *Devolución*: **Nombre del receptor** y **Cédula del receptor**.
- **Agenda / Autorizaciones**:
  - *Contactos*: buscador + edición (**Nombre**, **Celular**, **Email**, **Empresa**).
  - *Autorizaciones*: buscadores (**Nombre/CI** y **Llave/Lugar**) + formulario nueva/editar
    (**Lugar autorizado**, **Autorizado por**, **Email de referencia**, **Horario**, **Observaciones**).
  - *Historial*: buscador (**Lugar o persona**).
- **Historial de llaves** (buscador): campo de **búsqueda**.
- **Tarjetas de llaves en uso**: campo de **Notas**.

**Importante:** Es un cambio de bajo riesgo: un componente nuevo que "envuelve" al campo,
sin modificar los campos base ni la lógica de búsqueda/guardado. En los buscadores la X
solo resetea el filtro de pantalla (igual que el botón "Limpiar" que ya existía).

---

## Pasos para aplicar

1. Enchufá el pendrive en la PC del **Monitor de Vigilancia**.
2. Abrí la carpeta `UPGRADE_BOTON_X_LIMPIAR_CAMPOS_2026-08-08`.
3. Doble clic en **`1-APLICAR_BOTON_X.bat`**.
   - Va a pedir permiso de administrador (aceptá).
   - El script hace un **backup** del `dist` actual y copia el nuevo, **preservando `config.json`**.
4. Cuando diga **"EXITO. Upgrade aplicado."**, cerrá el navegador/kiosko y volvé a abrirlo
   (si hace falta, `Ctrl + F5` para forzar recarga).

---

## Cómo probar que funcionó

1. Entrá a **Gestión de Llaves**.
2. En la pestaña **Agregar**, escribí algo en **Nombre de la llave**.
   - Debe aparecer una **X** al costado derecho del campo.
   - Al hacer clic en la X, el campo queda **vacío de un solo toque**.
3. Elegí una zona que use coordenadas (ej. "Central") y probá lo mismo en **Columna**.
4. En la pestaña **Modificar**, seleccioná una llave y probá la X en **Nombre** y **Columna**.
5. (Opcional) En **Objetos Olvidados** → *Devolver* un objeto, probá la X en
   **Nombre del receptor** y **Cédula del receptor**.

Si todo eso anda, el upgrade está OK.

---

## Si algo sale mal (Rollback)

Doble clic en **`2-DESHACER_BOTON_X_ROLLBACK.bat`** (pide admin).
Restaura el último backup del `dist` y deja todo como estaba. Después
cerrá y abrí el navegador de nuevo (`Ctrl + F5`).

---

## Avisá el resultado

Cuando lo pruebes, avisame acá en la laptop de desarrollo:
- **"Funcionó"** → integro el cambio a los archivos definitivos, hago commit con timestamp y lo subo a GitHub.
- **"No funcionó"** o algo raro → lo revierto/ajusto y grabamos la próxima versión.
