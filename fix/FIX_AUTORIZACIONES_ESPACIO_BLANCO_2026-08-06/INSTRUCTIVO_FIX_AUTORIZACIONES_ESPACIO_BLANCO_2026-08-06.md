# INSTRUCTIVO — FIX AUTORIZACIONES: ESPACIO EN BLANCO
**Fecha/hora:** 2026-08-06 12:15
**PC destino:** MONITOR VIGILANCIA (es donde se usa "Agenda / Autorizaciones")
**Tipo:** Fix de frontend (interfaz). NO toca PocketBase ni la base de datos.

---

## ¿Qué arregla?

En el **Monitor Vigilancia → botón "Agenda / Autorizaciones"**, al entrar a las
pestañas **AUTORIZACIONES** e **HISTORIAL** quedaba un **gran espacio en blanco**
entre las 3 pestañas de arriba (Contactos / Autorizaciones / Historial) y el
contenido de abajo (botones **Verificar / Nueva**, el buscador y la lista).
El contenido "flotaba" en la parte baja del modal.

**Causa:** la pestaña *Contactos* usaba un layout que llena el alto del modal,
pero *Autorizaciones* e *Historial* no. Ahora las 3 pestañas usan el mismo
layout: el contenido queda **pegado debajo de las pestañas**, sin hueco, y la
lista **crece para ocupar todo el alto disponible**.

### Sobre los botones "Verificar" y "Nueva"
Se revisaron: **AMBOS tienen función**, por eso **NO se quitaron**:
- **Verificar** → es el modo de búsqueda / verificación de autorizaciones (lo que ves por defecto).
- **Nueva** → abre el formulario para registrar una autorización nueva.

Si igual querés que se quite/renombre alguno, avisame y lo hago en otro fix.

---

## Antes de empezar
- Este fix trae el **dist ya compilado** desde la laptop (no se compila en la PC).
- **Preserva** el `config.json` y `system_health.json` propios de esa PC.
- Hace **backup** del `dist` actual (rollback disponible).

---

## Pasos

1. Enchufá el **pendrive** en el **MONITOR VIGILANCIA**.
2. Entrá a la carpeta:
   `FIX_AUTORIZACIONES_ESPACIO_BLANCO_2026-08-06`
3. Doble clic en **`APLICAR_FIX.bat`**.
   - Va a pedir permisos de **Administrador** → aceptá (Sí).
4. Esperá a que diga **"FIX APLICADO"** y presioná **ENTER** para cerrar.
5. **Cerrá y volvé a abrir el kiosko** (o hacé **Ctrl + F5** en el navegador)
   para que cargue la interfaz nueva.

---

## Cómo verificar que funcionó

1. En el Monitor, abrí **"Agenda / Autorizaciones"**.
2. Entrá a la pestaña **AUTORIZACIONES**:
   - El contenido (botones **Verificar / Nueva**, buscador y lista) debe quedar
     **pegado justo debajo** de las 3 pestañas, **SIN el espacio en blanco** de antes.
   - La lista de autorizaciones ocupa el alto disponible.
3. Entrá a la pestaña **HISTORIAL**: mismo comportamiento, sin hueco.
4. La pestaña **CONTACTOS** debe seguir viéndose igual que siempre.

---

## Si algo sale mal (Rollback)

El script deja un backup del `dist` en:
`C:\sistema-llaves-fcea\dist_bak_<fecha_hora>`

Para volver atrás manualmente:
1. Borrá la carpeta `C:\sistema-llaves-fcea\dist`
2. Renombrá `dist_bak_<fecha_hora>` a `dist`
3. Reiniciá la PC.

---

## Log automático
El script guarda un log en el pendrive:
`FIX_AUTORIZACIONES_ESPACIO_BLANCO_2026-08-06\_RESULTADOS\LOG_APLICAR_FIX_AUTORIZACIONES_<PC>_<fecha_hora>.log`

Traé el pendrive de vuelta a la laptop y avisame:
- **"funcionó"** → lo integro a los scripts críticos y hago el commit con timestamp.
- **"no funcionó"** → lo borro de todas partes y preparo el siguiente intento.
