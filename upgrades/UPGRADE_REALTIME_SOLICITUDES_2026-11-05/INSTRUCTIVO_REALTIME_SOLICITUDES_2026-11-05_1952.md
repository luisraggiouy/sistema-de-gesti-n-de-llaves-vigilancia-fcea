# INSTRUCTIVO — Upgrade "Realtime de Solicitudes" INSTANTÁNEO (v2)
**Fecha/hora: 2026-11-06 · PC objetivo: LAS 3 (Monitor, Terminal A, Terminal B)**

> **Este es el intento CORREGIDO.** El upgrade del 2026-11-05 quedó errático
> (la llave llegaba "a veces en 1s, a veces 2s, a veces instantáneo"). Esta
> versión arregla la causa real y da latencia **instantánea y consistente**.

## Qué resuelve
Cuando una terminal pedía una llave, en el Monitor aparecía con retraso
variable. **Por qué el intento anterior no sirvió:** la suscripción realtime
se montaba dentro de un `useEffect` que dependía de una función que cambia de
identidad al cambiar el estado de conexión; eso hacía que React **desmontara y
re-creara la suscripción constantemente**, perdiendo eventos (de ahí la
variación 1–2s). Además, cuando llegaba un evento, solo disparaba **otra
consulta HTTP** a la red en lugar de usar el dato que ya traía el evento.

**Esta versión (v2):**
- Monta la suscripción **una sola vez** (usando refs estables) → ya no se cae.
- Pinta la fila **al instante desde el propio evento** (sin otra consulta a la
  red): create/update/delete se reflejan de inmediato.
- Agrega un **re-fetch de respaldo (300 ms)** por si el evento viniera
  incompleto, sin saturar la red.
- El **polling de 3s** se mantiene como red de seguridad.

Resultado: la solicitud aparece en el Monitor en **milisegundos y de forma
consistente**.

## Qué cambia / qué NO cambia
- **Cambia:** un único archivo del frontend (`SolicitudesContext.tsx`) → se
  recompiló el `dist`.
- **NO toca** PocketBase, NO toca datos, NO cambia `config.json` (se preserva),
  NO cambia cómo se ve la pantalla (es un cambio puramente de "escucha" de
  eventos). En el peor caso, si el realtime fallara, el sistema sigue
  funcionando igual que hoy (con el polling de 3s).

---

## IMPORTANTE: aplicar en LAS 3 PC
Como este upgrade reemplaza el `dist` (frontend), y cada PC sirve su propio
`dist`, hay que ejecutarlo **una vez en cada una de las 3 PC**: Monitor de
Vigilancia, Terminal A y Terminal B. Si solo lo ponés en el Monitor, las
terminales seguirán con el bundle viejo (aunque el efecto visible principal
se nota en el Monitor, igual conviene dejar las 3 con el mismo frontend).

---

## Pasos (repetir en cada PC)

1. Enchufá el pendrive en la PC.
2. Entrá a la carpeta del pendrive:
   `UPGRADE_REALTIME_SOLICITUDES_2026-11-05`
3. Doble clic en **`1-APLICAR_REALTIME_SOLICITUDES.bat`**
   (si Windows pide permisos de administrador, aceptá).
4. El script:
   - crea un backup del dist actual (`dist_backup_<fecha_hora>`) y lo verifica,
   - copia el frontend nuevo preservando `config.json`,
   - verifica que quedó `index.html`.
   Al final dice **EXITO**. Presioná ENTER para cerrar.
5. **Cerrá el navegador/kiosko y volvé a abrirlo.** Si no notás el cambio,
   forzá recarga con **Ctrl+F5**.

Repetí los pasos 1–5 en las otras dos PC.

---

## Cómo probar que funcionó
1. Con el Monitor abierto, andá a una Terminal y **pedí una llave**.
2. Mirá el Monitor: la solicitud debe aparecer **casi al instante** (antes
   tardaba ~2 segundos).
3. Probá también entregar/devolver desde el Monitor y confirmá que todo sigue
   funcionando normal.

Si todo anda bien → avisale a Cline en la laptop de desarrollo: *"funcionó el
realtime de solicitudes"*, para que haga el commit, integre y suba a GitHub.

---

## Si algo sale mal (ROLLBACK simple)
1. En la MISMA PC, doble clic en
   **`2-DESHACER_REALTIME_SOLICITUDES_ROLLBACK.bat`**.
2. Restaura automáticamente el último backup del dist (verificando que tenga
   `index.html`) preservando `config.json`.
3. Cerrá y abrí el navegador con **Ctrl+F5**.
4. El sistema queda EXACTAMENTE como antes del upgrade.

> Nota: el backup se crea SÍ o SÍ antes de tocar nada, así que el rollback
> siempre tiene de dónde restaurar. Si por algún motivo extremo no hubiera
> backup, recién ahí usar el pendrive de RECUPERACIÓN.
