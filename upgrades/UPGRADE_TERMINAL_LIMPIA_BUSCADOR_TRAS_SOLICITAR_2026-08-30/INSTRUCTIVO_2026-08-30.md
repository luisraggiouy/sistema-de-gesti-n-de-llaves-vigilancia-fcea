# UPGRADE — La Terminal limpia el buscador de llaves tras solicitar
**Fecha:** 2026-08-30

## Qué problema resuelve
En las Terminales (A y B), al buscar una llave se teclea, por ejemplo,
`rendi` y se despliega la lista de llaves que contienen esos caracteres.
Después de **solicitar** la llave, el usuario se deslogueaba correctamente,
**pero el buscador quedaba con el texto `rendi` escrito y la lista de
opciones desplegada** debajo. Había que apretar **F5** para dejar la
terminal limpia.

Con este upgrade, tras enviar la solicitud la Terminal vuelve al inicio con:
- la sesión cerrada,
- el buscador de llaves **vacío** (sin el texto tecleado),
- los filtros (tipo/edificio) reseteados,
- y la lista de resultados **replegada**,

todo **sin apretar F5**, quedando 100% limpia para el próximo usuario.

## ⚠️ MUY IMPORTANTE: se aplica en LAS 3 PC
Este upgrade cambia el **frontend compilado (`dist`)**. Como cada PC sirve su
propio `dist` local en `127.0.0.1:5173`, hay que ejecutarlo en **las 3 PC**:
**Monitor de Vigilancia, Terminal A y Terminal B**. Si se aplica solo en una,
las otras seguirán con el JavaScript viejo y el cambio "no aparecerá".

## Pasos (repetir en cada una de las 3 PC)
1. Conectá el pendrive en la PC.
2. Entrá a la carpeta
   `UPGRADES\UPGRADE_TERMINAL_LIMPIA_BUSCADOR_TRAS_SOLICITAR_2026-08-30`.
3. Clic derecho en **`1-APLICAR_UPGRADE.bat`** → **Ejecutar como administrador**
   → "Sí".
4. Esperá el mensaje **`EXITO`** y presioná ENTER para cerrar.
5. **Cerrá el kiosko/navegador y volvé a abrirlo** (o `Ctrl+F5`).
6. Repetí los pasos 1–5 en las otras dos PC.

## Cómo probar que funcionó (en Terminal A o B)
1. Identificate como un usuario.
2. En el buscador de llaves tecleá por ej. `rendi` → se despliega la lista.
3. Seleccioná una llave y **Confirmar** el pedido.
4. La Terminal debe volver al inicio con la sesión cerrada **y** el buscador
   **vacío** y la lista **replegada**, **sin** tener que apretar F5.

## Rollback (si algo sale mal)
Ejecutá **`2-DESHACER_ROLLBACK.bat`** como administrador en la misma PC:
restaura el `dist` anterior desde el backup `dist_backup_<fecha_hora>`.

## Notas técnicas (referencia interna)
- Archivo modificado: `src/pages/TerminalUsuario.tsx`.
- `KeySearch` guarda su propio estado interno (texto de búsqueda + filtros de
  tipo/edificio). Al enviar una solicitud normal, la Terminal volvía a `main`
  pero `KeySearch` **no se desmontaba**, por lo que conservaba el texto y la
  lista. (El flujo de intercambio ya quedaba limpio porque pasaba por la
  pantalla `exchange-success`, que sí lo desmontaba.)
- Fix: nuevo estado `terminalResetKey` que se incrementa en `handleNewRequest()`
  (tras enviar) y en `handleExchangeFinish()`, y se usa como `key` del
  `<KeySearch>`. Al cambiar el `key`, React **remonta** `KeySearch` limpio.
- No toca PocketBase ni datos. Preserva `config.json` y `system_health.json`
  (`robocopy ... /XF config.json system_health.json`).
