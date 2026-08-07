# INSTRUCTIVO — Upgrade "Notas en el Buscador Histórico de Llaves"
**Fecha:** 2026-08-07
**Módulo afectado:** Monitor de Vigilancia → Buscador Histórico de Llaves
**PC donde se aplica:** MONITOR DE VIGILANCIA (solo esa PC)

---

## ¿Qué cambia?

En el **Buscador Histórico de Llaves**, cada registro ahora muestra las
**notas** que se escribieron mientras la llave estaba en uso (el campo "Notas"
que aparece en la tarjeta de llave en uso del Monitor).

- Si el registro **tiene** notas → aparecen debajo, con un ícono de notita y el
  texto "Notas: ...".
- Si el registro **NO tiene** notas (quedó vacío) → **no aparece nada**, no
  ocupa espacio ni muestra "Notas:" vacío.

Es un cambio **solo visual** del frontend. No toca PocketBase, no borra datos,
no cambia la lógica de búsqueda ni el guardado de notas.

---

## Pasos para aplicar (en el MONITOR DE VIGILANCIA)

1. Enchufá el pendrive en la PC del **Monitor de Vigilancia**.
2. Entrá a la carpeta `UPGRADE_NOTAS_HISTORIAL_LLAVES_2026-08-07`.
3. Doble clic en **`1-APLICAR_NOTAS_HISTORIAL.bat`**.
4. Aceptá el cartel de permisos de Windows (UAC → "Sí").
5. Esperá a que diga **"EXITO. Upgrade aplicado."** y presioná ENTER para cerrar.
6. Cerrá el navegador/kiosko y volvé a abrirlo. Si no ves el cambio, hacé
   **Ctrl + F5** para forzar recarga.
7. Verificá: abrí el **Buscador Histórico de Llaves** y buscá una llave que
   sepas que tuvo notas cargadas → debajo del registro deben verse las notas.
   Los registros sin notas se ven igual que antes (sin línea de "Notas").

---

## Si algo sale mal (ROLLBACK)

En la misma PC (Monitor de Vigilancia):

1. Entrá a la carpeta `UPGRADE_NOTAS_HISTORIAL_LLAVES_2026-08-07`.
2. Doble clic en **`2-DESHACER_NOTAS_HISTORIAL_ROLLBACK.bat`**.
3. Aceptá el UAC. Esperá a que diga **"[OK] dist restaurado"**.
4. Cerrá y abrí el navegador de nuevo (Ctrl + F5).

El rollback restaura automáticamente el `dist` que había antes
(se guarda en `C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`).

---

## Detalle técnico (para Cline / desarrollo)

- Archivos fuente modificados:
  - `src/hooks/useBusquedaHistorial.ts`
    - Se agregó el campo `notas?: string` a la interfaz `HistorialLlaveItem`.
    - En el `map` se agrega `notas: s.notas?.trim() ? s.notas.trim() : undefined`
      (así las notas vacías o solo espacios quedan como `undefined` y no se muestran).
  - `src/components/monitor/KeyHistorySearch.tsx`
    - Se importó el ícono `StickyNote` de lucide-react.
    - En `HistorialCard` se agregó un bloque condicional `{item.notas && (...)}`
      que muestra las notas debajo del registro.
- El upgrade reemplaza la carpeta `dist` de `C:\sistema-llaves-fcea`
  usando `robocopy /MIR`, con backup previo.
