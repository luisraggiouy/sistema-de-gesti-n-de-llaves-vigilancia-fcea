# Instructivo — Cartel de espera de arranque (Splash) — Monitor Vigilancia
**Fecha: 03/08/2026** · Upgrade ADITIVO y REVERSIBLE

## Qué es y para qué sirve
Mientras el Monitor arranca, PocketBase (el servidor) tarda un rato en estar
listo. Durante esa espera la pantalla puede verse en negro o "congelada", y
alguien puede pensar que se colgó y **reiniciar** (lo peor que puede pasar).

Este upgrade agrega un **cartel a pantalla completa, siempre al frente**, con:
- un **spinner que gira** (movimiento continuo, se nota que está vivo),
- una **barra de progreso** animada,
- un **contador de tiempo** (mm:ss),
- el mensaje: *"El sistema se está iniciando... POR FAVOR NO REINICIE, aguarde"*.

El cartel **consulta solo** `http://127.0.0.1:8090/api/health` cada 1 segundo.
Apenas PocketBase responde, muestra **"¡Listo!"** y **se cierra solo**.

### Importante (seguridad del sistema)
- Es **ADITIVO**: NO toca PocketBase, ni la base de datos, ni la config, ni el
  orquestador de arranque (`INICIAR.bat`). Solo mira `/api/health`.
- **No corrige** el arranque lento (eso es otro tema que estamos diagnosticando):
  esto es la **experiencia de espera** para que nadie reinicie.
- Tiene **tope de seguridad**: si en 15 min no arrancó, el cartel se cierra solo.
- Un técnico siempre puede cerrarlo con la tecla **ESC**.

---

## PASO 0 — Ver el cartel en la laptop (opcional, ya probado por Cline)
Doble clic en **`PROBAR_SPLASH.bat`**. Como esta PC no tiene PocketBase en 8090,
el cartel girará hasta 2 minutos o hasta que aprietes **ESC**. Sirve para ver
cómo se ve. No instala nada.

---

## PASO 1 — Instalar en el MONITOR VIGILANCIA
1. Enchufá el pendrive en el **Monitor Vigilancia**.
2. Entrá a la carpeta `upgrades\UPGRADE_SPLASH_ARRANQUE_2026-08-03`.
3. Doble clic en **`APLICAR_UPGRADE.bat`**.
4. Debe decir:
   - `[OK] Copiado: splash_arranque.ps1`
   - `[OK] Copiado: SPLASH_ARRANQUE.vbs`
   - `[OK] Acceso directo creado en Inicio: ...FCEA_Splash_Arranque.lnk`
   - `=== LISTO ===`
5. Cerrá la ventana (ENTER).

### Ver el cartel YA sin reiniciar (para chequear)
En el Monitor, doble clic en:
`C:\sistema-llaves-fcea\scripts\lib\splash\SPLASH_ARRANQUE.vbs`
Como PocketBase ya está corriendo, debería aparecer el cartel, decir
**"¡Listo!"** casi enseguida y cerrarse solo. Eso confirma que quedó bien.

---

## PASO 2 — La prueba de verdad: reiniciar
1. Reiniciá el Monitor Vigilancia.
2. Al iniciar sesión debe aparecer el **cartel de espera girando** encima de todo.
3. Cuando PocketBase termina de levantar, el cartel dice **"¡Listo!"** y se cierra
   solo, dejando ver el sistema.
4. Fijate el **contador**: te dice cuántos mm:ss tardó realmente en estar listo
   (dato útil para el diagnóstico del arranque lento).

---

## Si algo sale mal → DESINSTALAR (rollback)
Doble clic en **`QUITAR_UPGRADE.bat`** (en la misma carpeta del pendrive).
Borra el acceso directo de Inicio y la carpeta `splash`. El arranque queda
**exactamente como estaba antes**. No quedó nada tocado del sistema.

---

## Qué me tenés que decir a la vuelta (laptop de desarrollo)
- "El cartel apareció al reiniciar, giró y se cerró solo al estar listo" ✅
  o bien qué pasó si no.
- **Cuánto marcó el contador** cuando dijo "¡Listo!" (ej.: 02:14). Ese número
  me sirve para el diagnóstico del arranque lento.

Cuando me confirmes que **funcionó bien en el Monitor**, recién ahí hago el
commit con timestamp, subo a GitHub e integro el splash al arranque oficial
(script crítico de instalación), según las reglas.
