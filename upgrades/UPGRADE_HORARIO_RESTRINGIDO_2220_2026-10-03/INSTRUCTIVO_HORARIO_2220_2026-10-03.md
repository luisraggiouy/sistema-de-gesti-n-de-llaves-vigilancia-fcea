# UPGRADE — Restricción nocturna de botones ahora 22:20 (antes 22:00)
**Fecha:** 2026-10-03

Paquete **individual e independiente** (un solo cambio), con su propio `dist` y
su propio rollback.

## Qué cambia
Los botones restringidos de noche en el Monitor (Objetos, Agenda,
Configuración, Vigilantes, Llaves, Dashboard) ahora se bloquean desde las
**22:20** (antes 22:00). Se le achican **20 minutos al inicio** para dar margen
al cambio de turno; el **fin (06:00) queda igual**.

Ventana nocturna resultante: **22:20 → 06:00**.

| Franja        | Antes       | Ahora        |
|---------------|-------------|--------------|
| 22:00 – 22:19 | BLOQUEADO   | **HABILITADO** |
| 22:20 – 05:59 | BLOQUEADO   | BLOQUEADO    |
| 06:00 en adelante | HABILITADO | HABILITADO |

Se mantiene la protección anti-reloj-roto (si el año del sistema es < 2025, no
se restringe nada).

---

## ⚠️ IMPORTANTE: aplicar en LAS 3 PC
Reemplaza el **frontend (`dist`)**. Hay que ejecutarlo una vez en **cada una de
las 3 PC** (Monitor, Terminal A y Terminal B) y reabrir el kiosko.

## Pasos (repetir en Monitor, Terminal A y Terminal B)
1. Enchufar el pendrive en la PC.
2. Entrar a: `upgrades\UPGRADE_HORARIO_RESTRINGIDO_2220_2026-10-03`
3. Click **DERECHO** en **`1-APLICAR_UPGRADE.bat`** → **"Ejecutar como
   administrador"** → aceptar el UAC (**Sí**).
4. Esperar **"EXITO. Upgrade aplicado en esta PC"**.
5. En el kiosko, recargar con **Ctrl + F5** (como siempre). **No hace falta
   cerrar el navegador.**

### Verificación IMPORTANTE (confirmar que quedó el dist 22:20)
La vez anterior el bloqueo siguió a las 22:00 aun recargando con Ctrl+F5. Para
estar seguros de que esta vez quedó la lógica 22:20, verificá en la propia PC
que el `dist` copiado es el correcto. Abrí PowerShell y pegá (una línea):

```powershell
Select-String -Path 'C:\sistema-llaves-fcea\dist\assets\index-*.js' -Pattern 'r===22' -Quiet
```

- **Devuelve `True`** → quedó la lógica **22:20** (correcto).
- **Devuelve `False`** → quedó la lógica vieja **22:00**: el `dist` no se
  reemplazó bien. En ese caso, avisame (no sigas).

> Nota: NO cerramos el navegador a propósito — en producción es riesgoso dejar
> el kiosko caído. Con Ctrl+F5 alcanza, siempre que el `dist` en disco sea el
> correcto (eso es lo que verifica el comando de arriba).

## Cómo probar (en el Monitor)
- Verificar que a las **22:00–22:19** los botones restringidos siguen
  **habilitados**.
- Verificar que a partir de las **22:20** quedan **bloqueados** (hasta las
  06:00, igual que antes).
- (Si no querés esperar al horario real, se puede probar adelantando el reloj de
  la PC a esas horas de forma temporal, y después volverlo a la hora correcta.)

## Si algo sale mal (rollback)
- Click DERECHO en **`2-DESHACER_ROLLBACK.bat`** → "Ejecutar como
  administrador". Restaura el `dist` anterior.

## Notas técnicas (para integración posterior)
- **No** toca PocketBase, **no** borra datos, **no** cambia `config.json`.
- Archivo de código modificado:
  - `src/utils/horarioRestringido.ts` → `esHorarioRestringido()` ahora arranca
    a las 22:20 (contempla minutos cuando la hora es 22); fin 06:00 sin cambios.
- Tests: `src/test/horarioRestringido.test.ts` (11 casos, cubren 22:00, 22:19,
  22:20, 22:59, 23:00, madrugada, 05:59, 06:00, mediodía y anti-reloj-roto).
- El paquete incluye el `dist` recompilado (`vite build`, EXIT=0).
