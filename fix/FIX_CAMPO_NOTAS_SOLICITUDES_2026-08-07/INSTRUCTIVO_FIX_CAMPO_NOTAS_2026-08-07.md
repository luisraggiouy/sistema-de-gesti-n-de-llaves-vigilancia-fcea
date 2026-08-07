# INSTRUCTIVO — FIX: Campo "notas" en solicitudes + Upgrade Notas en Histórico
**Fecha:** 2026-08-07
**PC destino:** MONITOR DE VIGILANCIA (es el servidor PocketBase)

---

## ¿Qué problema arregla?

En el **Buscador Histórico de Llaves** pediste que aparezcan las notas escritas
durante el uso de la llave. Descubrimos que **la base de datos NO tenía el campo
`notas`** en la colección `solicitudes`. Por eso:
- Las notas que el vigilante escribía en la tarjeta de "llave en uso" **nunca se
  guardaban** (PocketBase ignora campos que no existen en el schema).
- El histórico no tenía notas para mostrar → por eso "no funcionó" el upgrade.

Este fix **agrega el campo `notas`** a la base, en caliente, **sin reiniciar
PocketBase y sin cortar el servicio**.

> IMPORTANTE: las notas viejas NO existen (nunca se pudieron guardar).
> A partir de ahora, las notas que se escriban SÍ quedarán y aparecerán en el histórico.

---

## Orden de aplicación (2 partes, ambas en el MONITOR)

### PARTE 1 — Agregar el campo `notas` a la base (este FIX)

1. Enchufá el pendrive en el **Monitor de Vigilancia**.
2. Abrí la carpeta `fix\FIX_CAMPO_NOTAS_SOLICITUDES_2026-08-07`.
3. Doble clic en **`1-APLICAR_CAMPO_NOTAS.bat`**.
4. Se abre una ventana negra:
   - Se autentica en PocketBase, revisa el schema y agrega el campo `notas`.
   - Muestra **EXITO** si quedó agregado (o "ya estaba", que también está bien).
5. Deja un `.log` en `D:\_RESULTADOS\LOG_FIX_CAMPO_NOTAS_*.log`.
6. Apretá ENTER para cerrar.

### PARTE 2 — Aplicar el frontend nuevo (Upgrade que muestra las notas)

1. En el mismo Monitor, abrí la carpeta
   `upgrades\UPGRADE_NOTAS_HISTORIAL_LLAVES_2026-08-07`.
2. Doble clic en **`1-APLICAR_NOTAS_HISTORIAL.bat`** (pedirá permiso de administrador).
3. Cuando diga EXITO, cerrá el navegador/kiosko y volvelo a abrir (Ctrl+F5).

---

## Cómo probar que quedó funcionando

1. En el Monitor, entregá una llave a un usuario (o usá una que esté en uso).
2. En la tarjeta de **"Llave en Uso"**, escribí algo en el campo de **notas**
   (por ejemplo: "prueba nota 07/08").
3. Devolvé esa llave.
4. Abrí el **Buscador Histórico de Llaves** y buscá esa llave.
5. El registro debe mostrar la nota escrita. Los registros SIN notas no muestran nada.

---

## Si algo sale mal

- Si la PARTE 1 dice error de autenticación → avisá; puede que la contraseña de
  PocketBase se haya cambiado.
- El fix **no borra datos** y es **idempotente** (se puede correr de nuevo sin problema).
- Para deshacer solo el frontend (PARTE 2): `2-DESHACER_NOTAS_HISTORIAL_ROLLBACK.bat`
  dentro de la carpeta del upgrade.
- El campo `notas` en la base no molesta aunque no se use, así que no hace falta quitarlo.

---

## Traé de vuelta

Al terminar, traé el pendrive a la laptop de desarrollo con el archivo
`D:\_RESULTADOS\LOG_FIX_CAMPO_NOTAS_*.log` para que Cline confirme el resultado.
