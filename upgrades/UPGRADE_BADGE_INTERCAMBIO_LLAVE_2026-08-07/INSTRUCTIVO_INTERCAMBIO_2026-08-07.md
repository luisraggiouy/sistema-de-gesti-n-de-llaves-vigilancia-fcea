# UPGRADE: Cartel "Intercambio de llave" en la tarjeta de Llaves en Uso
**Fecha:** 2026-08-07
**PC donde se aplica:** MONITOR DE VIGILANCIA (la que hace de servidor)
**Modulo:** Monitor de Vigilancia → Solicitudes → Llaves en Uso

---

## Que problema resuelve

Cuando se hace un **intercambio de llave** (una llave que estaba en uso pasa
de un usuario a otro sin devolverla al mostrador), la tarjeta del listado
**"Llaves en Uso"** mostraba solo el texto plano:

> Entregada por Manuel Adams · A cargo de Edinson Cavani ...

...sin ningun distintivo. No quedaba claro a simple vista que hubo un intercambio.

**Con este upgrade**, esa tarjeta muestra:
- Un **cartelito ambar "Intercambio de llave"** justo al lado del verde "En uso".
- El detalle **Entrego / Recibio** (quien tenia la llave y quien la recibio).

> El intercambio **NO** aparece en "Solicitudes pendientes" (correcto: el
> vigilante no tiene la llave para entregarla). Solo se refleja en "Llaves en Uso".

### Causa tecnica (para el historial)
La coleccion `solicitudes` del PocketBase del Monitor **no tenia** los campos
`es_intercambio` ni `usuario_anterior_*`. PocketBase ignora los campos que no
existen en su schema, asi que el flag del intercambio **nunca se guardaba** y,
al recargar, la tarjeta lo mostraba como una entrega comun. Este upgrade agrega
esos campos (en caliente, sin reiniciar) y actualiza el frontend.

---

## Antes de empezar
- El upgrade va **UNICAMENTE en el Monitor de Vigilancia**.
- **No** corta el servicio, **no** reinicia PocketBase, **no** borra datos.
- Preserva `config.json` y `system_health.json` (config de red de la PC).
- Deja un backup del frontend anterior por si hay que volver atras.

---

## Pasos

1. Enchufa el pendrive en la PC del **Monitor de Vigilancia**.
2. Entra a la carpeta `upgrades\UPGRADE_BADGE_INTERCAMBIO_LLAVE_2026-08-07`.
3. Hace **doble clic** en **`1-APLICAR_INTERCAMBIO.bat`**.
4. Windows va a pedir permisos de administrador → aceptar (Si).
5. Se abre una ventana azul. Va a:
   - Autenticarse en PocketBase y agregar los campos que falten (Parte A).
   - Respaldar el `dist` actual y copiar el `dist` nuevo (Parte B).
   - Si las credenciales por defecto del admin de PocketBase no sirven, te las
     pedira por teclado (3 intentos). Si no las sabes, cerra y avisame.
6. Cuando diga **"EXITO. Upgrade aplicado."**, presiona ENTER para cerrar.

---

## Como probar que quedo bien

1. En el Monitor, cerra el navegador/kiosko y volvelo a abrir (o `Ctrl + F5`).
2. Genera un **intercambio de llave** (desde la terminal, un segundo usuario
   toma una llave que ya estaba en uso).
3. Mira la tarjeta en **"Llaves en Uso"**: al lado de **"En uso"** debe aparecer
   el cartelito ambar **"Intercambio de llave"**, y debajo el detalle
   **Entrego / Recibio**.

Si lo ves asi → **funciono**. Avisame aca en la laptop de desarrollo y lo dejo
commiteado / integrado a los scripts criticos.

---

## Si algo sale mal (rollback del frontend)

Hace doble clic en **`2-DESHACER_ROLLBACK.bat`** (restaura el `dist` anterior
desde el backup). Los campos agregados a PocketBase son inofensivos y pueden
quedar; si hiciera falta quitarlos, avisame.

---

## Resultado (log)
El script deja un `.log` en `<pendrive>:\_RESULTADOS\LOG_UPGRADE_INTERCAMBIO_*.log`.
Trae el pendrive y lo leo desde la laptop si hace falta revisar.
