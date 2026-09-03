# UPGRADE: Vigilantes del turno Matutino visibles desde las 05:50

**Fecha:** 2026-09-03
**PC donde se aplica:** LAS 3 PC (Monitor de Vigilancia, Terminal A y Terminal B)

---

## Que hace este upgrade

Hoy el sistema ya tiene un **periodo de transicion de turno** (configurable, por
defecto 30 minutos) durante el cual, al comenzar un turno, se muestran tambien los
vigilantes del **turno anterior**.

Este upgrade agrega una **excepcion FIJA y NO configurable**:

- **Entre las 05:50 y las 05:59** (todavia es turno **Nocturno**), en el **Monitor de
  Vigilancia** aparecen **TAMBIEN los vigilantes del turno MATUTINO** en los botones
  de **entrega**, **devolucion** e **intercambio** de llaves (se muestran etiquetados
  como `(turno ant.)`), ademas de los del turno Nocturno.
- A las **06:00** el turno cambia normalmente a Matutino y todo sigue igual que siempre.

**Motivo:** el turno Matutino suele llegar ~5 minutos antes de las 6:00, cuando los del
turno Nocturno ya se retiraron o estan en retirada. Asi se puede registrar la operacion
con el vigilante que este fisicamente en la cabina.

> Este periodo de las 05:50 es **fijo** (esta en el codigo) e **independiente** del
> "Periodo de transicion de turno" editable en Configuracion. Aunque en Configuracion
> se ponga 0 minutos, la ventana de las 05:50 sigue funcionando.

Solo cambia el **frontend compilado (dist)**. **NO toca PocketBase, NO borra datos.**

---

## Pasos para aplicar (repetir en LAS 3 PC)

> Importante: el frontend NO se sirve centralizado. Cada PC (Monitor, Terminal A y
> Terminal B) corre su propio `dist` local. Por eso hay que aplicar este upgrade en las
> **3 PC**; si se aplica solo en el Monitor, las Terminales A/B seguiran con el JS viejo.
> (En este upgrade el cambio visible esta en el Monitor, pero igual se recomienda dejar
> las 3 PC con el mismo `dist` para que no queden desincronizadas.)

En cada PC:

1. Enchufa el pendrive.
2. Entra a la carpeta:
   `upgrades\UPGRADE_VIGILANTES_MATUTINO_0550_2026-09-03`
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** y acepta el pedido de permisos (UAC).
4. Espera el mensaje **EXITO** y presiona ENTER para cerrar.
5. Cierra el navegador/kiosko y volvelo a abrir (Ctrl+F5).

Repeti los pasos 1 a 5 en las otras dos PC.

---

## Como probarlo (en el Monitor)

1. Entre las **05:50 y 05:59** (o adelanta la hora de la PC para probar), abri el
   Monitor de Vigilancia con al menos una llave pendiente o en uso.
2. En los botones de entrega/devolucion/intercambio deben aparecer **tambien** los
   vigilantes del **turno Matutino** (marcados `(turno ant.)`), ademas de los del
   Nocturno.
3. A las **06:00** el turno pasa a Matutino con normalidad.

---

## Rollback (si algo sale mal)

En la MISMA PC donde aplicaste el upgrade:

1. Entra a la carpeta del upgrade.
2. Doble clic en **`2-DESHACER_ROLLBACK.bat`** y acepta el UAC.
3. Restaura automaticamente el ultimo `dist_backup_*`.
4. Cierra y abri el navegador (Ctrl+F5).

---

## Archivo modificado (para el registro)

- `src/hooks/useVigilantes.ts` -> funcion `obtenerVigilantesConTransicion`:
  se agrego la excepcion fija de las 05:50-05:59 que suma los vigilantes del turno
  Matutino a la lista `anteriores` cuando el turno vigente es Nocturno.
