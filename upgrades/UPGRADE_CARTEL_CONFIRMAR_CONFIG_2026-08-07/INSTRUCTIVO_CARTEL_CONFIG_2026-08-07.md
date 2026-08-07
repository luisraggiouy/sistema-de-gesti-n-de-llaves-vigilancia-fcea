# INSTRUCTIVO — UPGRADE "Cartel de advertencia al confirmar Configuración"

**Fecha:** 2026-08-07
**PC destino:** MONITOR DE VIGILANCIA (la que tiene instalado el sistema en `C:\sistema-llaves-fcea`)
**Módulo afectado:** Monitor de Vigilancia → pestaña **Configuración**

---

## ¿Qué hace este upgrade?

En la pestaña **Configuración** del Monitor de Vigilancia, al tocar
**"Guardar cambios"** o **"Restaurar valores"**, ahora aparece un cartel de
advertencia de acción sensible que hay que confirmar antes de aplicar el cambio:

> **Atención! acción sensible, usted quiere modificar datos en el sistema que
> requieren permisos de jefaturas, de continuar con esta acción quedará
> registro de los cambios que realiza.**

- Si se toca **Cancelar** → no se modifica nada.
- Si se toca **Sí, aplicar cambios** → recién ahí se guarda/restaura.

Este upgrade **solo reemplaza el frontend compilado** (carpeta `dist`).
NO toca PocketBase, NO borra datos, NO cambia configuración de red.

---

## Pasos para aplicar

1. Enchufá el pendrive en la PC **MONITOR DE VIGILANCIA**.
2. Entrá a la carpeta `UPGRADE_CARTEL_CONFIRMAR_CONFIG_2026-08-07`.
3. Doble clic en **`1-APLICAR_CARTEL_CONFIG_EN_MONITOR.bat`**.
   - Va a pedir permisos de administrador → aceptá (Sí).
4. Se abre una ventana azul de PowerShell. Esperá a que diga **"EXITO. Upgrade aplicado."**
   - Hace un backup automático del `dist` actual antes de reemplazarlo.
5. Presioná ENTER para cerrar.
6. **Cerrá el navegador/kiosko** del Monitor y volvé a abrirlo.
   - Si no ves el cambio, hacé **Ctrl + F5** para forzar recarga.

---

## Cómo verificar que funcionó

1. En el Monitor, abrí la pestaña **Configuración**.
2. Cambiá algún valor (por ejemplo el tiempo de alerta) y tocá **"Guardar cambios"**.
3. Debe aparecer el cartel de advertencia con el texto de arriba.
4. Probá **Cancelar** (no debe guardar) y luego **Guardar + Sí, aplicar cambios** (debe guardar).
5. Repetí lo mismo con el botón **"Restaurar valores"**.

Si todo eso funciona → avisar a Luis que **"funcionó en producción"**.

---

## Si algo sale mal (ROLLBACK)

1. En la misma carpeta, doble clic en **`2-DESHACER_CARTEL_CONFIG_ROLLBACK.bat`**.
2. Aceptá permisos de administrador.
3. Restaura automáticamente el `dist` anterior (el backup que se hizo al aplicar).
4. Cerrá y abrí de nuevo el navegador (Ctrl + F5).

---

## Notas técnicas (para desarrollo)

- Archivo modificado: `src/components/monitor/ConfigurationModal.tsx`
- Se reutiliza el componente estándar `ConfirmarAccionSensible` (mismo que llaves/vigilantes).
- El texto exacto se pasa por `descripcionExtra`.
- Backup del dist en producción: `C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`.
