# Credenciales del Sistema de Gestion de Llaves — FCEA

DOCUMENTO CONFIDENCIAL — Guardar en lugar seguro. No compartir con personal no autorizado.

---

## 1. PocketBase — Administrador de Base de Datos

| Campo | Valor |
|-------|-------|
| Descripcion | Acceso al panel de administracion de PocketBase (base de datos del sistema). Permite ver/editar todos los registros directamente. |
| URL | http://localhost:8090/_/ |
| Email | vigilancia@llaves.local |
| Contrasena | vigilanciamvd2026 |
| Uso | Solo para mantenimiento tecnico y scripts de administracion del sistema. |

---

## 2. Exportacion de Datos a Pendrive — Contrasena de Acceso

| Campo | Valor |
|-------|-------|
| Descripcion | Contrasena unica para autorizar la exportacion de datos del sistema a un pendrive USB. El Dashboard es visible para todos sin contrasena; esta contrasena solo se pide al momento de exportar. |
| Como acceder | http://localhost:8080/dashboard — boton "Exportar a Pendrive" |
| Contrasena por defecto | custodio2026 |
| Donde se guarda | Coleccion `admin_config` de PocketBase, clave: `custodian_password` |
| Quienes la usan | Jefes de turno, jefes de apoyo, intendencia, autoridades de la Facultad. Cualquier persona autorizada a llevarse los datos en un pendrive. |

---

## Notas Importantes

- El Dashboard (estadisticas, graficas, actividad reciente) es visible para todos sin contrasena. Cualquier vigilante o persona en la sala puede verlo.
- La contrasena solo se solicita al presionar "Exportar a Pendrive". Esto protege que cualquiera pueda llevarse los datos.
- La contrasena de exportacion se puede cambiar desde el boton "Cambiar Contrasena Exportacion" en el encabezado del Dashboard.
- La contrasena de PocketBase solo se puede cambiar desde el panel de administracion de PocketBase (`/_/`).
- Si se olvida la contrasena de exportacion, se puede restablecer directamente en PocketBase: coleccion `admin_config`, registro con clave `custodian_password`.
- Si se olvida la contrasena de PocketBase, se debe restaurar desde un backup o reinstalar el sistema.
- Cambiar la contrasena de exportacion inmediatamente despues de la instalacion.
- Las contrasenas por defecto se restablecen automaticamente cada vez que se restaura el sistema utilizando el pendrive restaurador. Despues de cada restauracion, cambiar la contrasena nuevamente.

---

*Ultima actualizacion: 06/05/2026 — v5.5*
*Documento preparado para archivo y custodia autoridades de FCEA.*
