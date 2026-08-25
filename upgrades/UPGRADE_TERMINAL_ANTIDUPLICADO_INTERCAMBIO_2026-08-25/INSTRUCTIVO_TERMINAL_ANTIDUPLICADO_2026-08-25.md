# UPGRADE: Terminal — evitar pedidos duplicados + intercambio en frecuentes

**Fecha:** 2026-08-25
**Aplicar en:** **TERMINAL A y TERMINAL B** (las dos).
*(No es necesario en el Monitor, aunque no molesta si se aplica: es el mismo dist.)*

---

## ¿Qué mejora?

Dos cosas en la pantalla de la Terminal de Usuario:

### 1. Evita pedidos duplicados (el problema principal)
Antes: si el profesor A pedía "Salón 5 equipos" y el vigilante todavía no se
la había entregado, el profesor B veía esa llave como **"Disponible"** y podía
pedirla de nuevo → quedaban **dos solicitudes de la misma llave**.

Ahora: si la llave ya fue solicitada y está esperando la entrega, aparece
marcada **"Ya solicitada, esperando entrega"** y **no se puede volver a pedir**.
Esto vale tanto en el buscador como en "Tus llaves frecuentes".

### 2. Intercambio desde "Tus llaves frecuentes"
Antes: si una llave frecuente estaba **en uso** por otra persona, desaparecía
de la lista de frecuentes.

Ahora: aparece marcada **"En uso"**, muestra **en poder de quién** está, y
ofrece el botón **"Intercambiar"** — igual que en el buscador. Así el usuario
frecuente puede pedir el intercambio directo desde sus llaves habituales.

**Resultado:** el buscador y las llaves frecuentes ahora muestran la misma
información y las mismas acciones. Todo coherente.

---

## Pasos para aplicarlo (hacer en LAS DOS Terminales)

1. Enchufá el pendrive en la **Terminal A**.
2. Entrá a la carpeta:
   `UPGRADES\UPGRADE_TERMINAL_ANTIDUPLICADO_INTERCAMBIO_2026-08-25`
3. Doble clic en **`1-APLICAR_TERMINAL.bat`**.
4. Aceptá permisos de administrador (**Sí**).
5. Esperá el mensaje **"EXITO"** y presioná ENTER.
6. Cerrá y reabrí el navegador/kiosko (`Ctrl+F5` si hace falta).
7. **Repetí los pasos 1 a 6 en la Terminal B.**

---

## Cómo comprobar que funcionó

1. Desde la **Terminal A**, identificate y pedí una llave (ej: "Salón 5 equipos").
   NO la entregues todavía desde el Monitor.
2. Andá a la **Terminal B**, identificate con otro usuario y buscá la misma llave.
   - Debe aparecer **"Ya solicitada, esperando entrega"** y NO dejar pedirla.
3. Ahora entregá la llave desde el Monitor (queda "en uso").
4. En la Terminal B, con un usuario que tenga esa llave como **frecuente**:
   - Debe aparecer en "Tus llaves frecuentes" marcada **"En uso"**, con el
     nombre de quien la tiene y el botón **"Intercambiar"**.

---

## Si algo sale mal (volver atrás)

Doble clic en **`2-DESHACER_ROLLBACK.bat`** (aceptá admin) en la Terminal donde
lo aplicaste. Restaura el frontend anterior desde el backup automático.

---

## Notas técnicas (para Luis / desarrollo)

- Solo cambia el frontend (`dist`). No toca PocketBase, no borra datos.
- Preserva `config.json` y `system_health.json` (`robocopy ... /XF ...`).
- Archivos fuente modificados:
  - `src/pages/TerminalUsuario.tsx`: pasa solicitudes pendientes/entregadas y
    onExchangeRequest a FrequentKeys; base de frecuentes = todas las llaves.
  - `src/components/terminal/FrequentKeys.tsx`: 3 estados (disponible / ya
    solicitada / en uso con intercambio).
  - `src/components/terminal/KeySearch.tsx`: detecta 'pendiente' y bloquea el
    re-pedido con aviso 'Ya solicitada'.
- El estado real se deriva de `solicitudesPendientes` / `solicitudesEntregadas`
  por `lugar.id` (no del flag `disponible`, que solo cambia al entregar).
