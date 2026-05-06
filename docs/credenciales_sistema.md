# Credenciales del Sistema de Gestión de Llaves — FCEA

> ⚠️ **DOCUMENTO CONFIDENCIAL** — Guardar en lugar seguro. No compartir con personal no autorizado.

---

## 1. PocketBase — Administrador de Base de Datos

| Campo | Valor |
|-------|-------|
| **Descripción** | Acceso al panel de administración de PocketBase (base de datos del sistema). Permite ver/editar todos los registros directamente. |
| **URL** | http://localhost:8090/_/ |
| **Email** | vigilancia@llaves.local |
| **Contraseña** | vigilanciamvd2026 |
| **Uso** | Solo para mantenimiento técnico y scripts de administración del sistema. |

---

## 2. Monitor de Vigilancia — Contraseña Administrador

| Campo | Valor |
|-------|-------|
| **Descripción** | Acceso al panel de administración dentro del Monitor de Vigilancia (gestión de llaves, vigilantes, configuración, exportación de datos). |
| **URL** | http://localhost:8080/monitor → botón "Admin" |
| **Contraseña por defecto** | admin2026 |
| **Dónde se guarda** | Colección `admin_config` de PocketBase, clave: `admin_password` |
| **Uso** | Administrador del sistema en el día a día (Intendente). |

---

## 3. Monitor de Vigilancia — Contraseña Custodio

| Campo | Valor |
|-------|-------|
| **Descripción** | Acceso reducido para el custodio. Permite ver estadísticas y exportar reportes pero NO modificar configuración del sistema. |
| **URL** | http://localhost:8080/monitor → botón "Admin" → "Ingresar como Custodio" |
| **Contraseña por defecto** | custodio2026 |
| **Uso** | Jefes de Apoyo y Jefes de Turno (Custodios). |

---

## Notas Importantes

- Las contraseñas del Monitor (admin y custodio) **se pueden cambiar** desde el propio panel de administración del Monitor → "Cambiar Contraseña".
- La contraseña de PocketBase **solo se puede cambiar** desde el panel de administración de PocketBase (`/_/`).
- Si se olvida la contraseña de PocketBase, se debe restaurar desde un backup o reinstalar el sistema.
- **Cambiar las contraseñas por defecto** inmediatamente después de la instalación.

---

*Última actualización: 06/05/2026 — v5.3*  
*Documento preparado para archivo y custodia autoridades de FCEA.*
