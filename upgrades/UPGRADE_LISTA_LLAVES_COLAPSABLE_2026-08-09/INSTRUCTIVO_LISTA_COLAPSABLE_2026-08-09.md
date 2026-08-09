# UPGRADE: Lista de Llaves Colapsable (aparece al buscar)
**Fecha:** 2026-08-09
**Aplicar en:** TERMINAL A y TERMINAL B (las dos PC de usuario, fuera de la cabina)
**NO aplicar en:** Monitor de Vigilancia (no hace falta)

---

## ¿Qué cambia? (UX/UI)

En la pantalla donde el usuario pide llaves ("Buscar Llaves"), antes el
**listado largo de llaves** estaba SIEMPRE visible y ocupaba mucho espacio
vertical, obligando a hacer scroll para llegar al botón de solicitar.

Ahora:

- El **listado permanece OCULTO** mientras no escribas nada ni elijas un filtro.
  En su lugar aparece un texto discreto: *"Escribí el nombre de una llave o
  usá los filtros para ver el listado."*
- El listado **se despliega automáticamente** apenas:
  - escribís algo en el buscador, **o**
  - elegís un filtro de **tipo** o de **edificio**.
- Las **"Llaves frecuentes"** siguen apareciendo igual que siempre. La idea es
  que el usuario recurrente use sus frecuentes y llegue mucho más rápido al
  botón de solicitar, sin scroll molesto.

**Importante:** es un cambio SOLO de presentación (frontend). No toca
PocketBase, no borra datos, no cambia la lógica de pedidos, intercambios ni
llaves frecuentes.

---

## Pasos para aplicar (repetir en Terminal A y en Terminal B)

1. Enchufá el pendrive en la PC (Terminal A o Terminal B).
2. Entrá a la carpeta del pendrive:
   `UPGRADES\UPGRADE_LISTA_LLAVES_COLAPSABLE_2026-08-09`
3. Doble clic en **`1-APLICAR_LISTA_COLAPSABLE.bat`**.
4. Aceptá el cartel de permisos de administrador (UAC).
5. Esperá a que diga **"EXITO. Upgrade aplicado."** y presioná ENTER.
6. Cerrá el navegador/kiosko y volvelo a abrir. Si el cambio no se ve,
   hacé **Ctrl + F5** (recarga forzada).
7. Repetí los pasos 1 a 6 en la **otra terminal**.

---

## ¿Cómo verificar que funcionó?

1. Identificate como usuario en la terminal.
2. Fijate que la sección **"Buscar Llaves"** muestre el texto de ayuda y
   **NO** el listado completo.
3. Escribí algo en el buscador (o elegí un filtro): el **listado aparece**.
4. Borrá lo que escribiste y volvé filtros a "Todos": el listado
   **vuelve a ocultarse**.

---

## Si algo sale mal (ROLLBACK)

El script hizo un backup automático del `dist` anterior en
`C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`.

Para volver atrás:

1. Doble clic en **`2-DESHACER_LISTA_COLAPSABLE_ROLLBACK.bat`**.
2. Aceptá el UAC y esperá el mensaje de OK.
3. Cerrá y abrí el navegador (Ctrl + F5).

---

## Notas técnicas (para el desarrollador)

- Archivo modificado: `src/components/terminal/KeySearch.tsx`.
- Se agregó la variable `busquedaActiva` (true si hay texto en el buscador o
  un filtro de tipo/edificio distinto de "todos").
- El bloque `<ScrollableList>` y el contador "Mostrando X de Y" solo se
  renderizan cuando `busquedaActiva` es true.
- El `robocopy` del `dist` usa `/XF config.json system_health.json` para
  NO pisar la configuración de red de cada PC (Regla de Oro de los upgrades).
