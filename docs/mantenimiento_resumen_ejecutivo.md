# Mantenimiento del Sistema de Gestión de Llaves FCEA
## Resumen técnico

> **Síntesis:** El aspecto "mantenimiento" fue contemplado y resuelto en el
> diseño del sistema. El esquema implementado combina **automatización** y
> **auto‑diagnóstico visible**, de modo que la operación normal no requiere
> intervención humana y, cuando la requiere, el propio sistema indica qué
> hacer en pantalla.

---

## 1. Capas de mantenimiento implementadas

### 1.1 Capa automática (sin intervención humana)

| Tarea | Frecuencia | Mecanismo |
|---|---|---|
| Backup de la base de datos | **Diaria** (03:00 AM) | Tarea `FCEA-Backup-Diario` + `scripts/maintenance/backup_automatico.ps1` |
| Retención de backups | Continua | Se conservan los **archivos ZIP de backup** de los últimos 14 días en `C:\sistema-llaves-fcea\backups\`; los ZIP más viejos que 14 días se eliminan automáticamente. **No se borra ningún dato del sistema** (la base de datos productiva `pb_data\data.db` queda intacta; lo que se elimina son copias de seguridad obsoletas) |
| Watchdog de PocketBase | Al login + **cada 30 segundos** | Tarea `FCEA-Watchdog` + `scripts/maintenance/watchdog.ps1` |
| Verificación de salud del sistema | Al login + **cada 30 minutos** | Tarea `FCEA-Chequeo-Salud` + `pocketbase/maintenance/check_system_health.ps1` (escribe `public/system_health.json` y `dist/system_health.json`) |
| Vacuum / optimización SQLite | Anual (manual) | Procedimiento documentado en `guia_mantenimiento_paso_a_paso.md` § 5 |
| Detección de errores en logs | Cada 30 min | El chequeo de salud analiza tamaño y crecimiento de logs |

Toda la automatización se configura en una sola ejecución mediante
`scripts/maintenance/CONFIGURAR_MANTENIMIENTO.ps1`.

### 1.2 Capa de auto‑diagnóstico (visible en el Monitor de Vigilancia)

El componente `SystemHealthIndicator` (en el header del Monitor de Vigilancia,
junto al reloj) muestra de forma permanente el estado general del sistema,
leído **cada 60 segundos** desde `/system_health.json` (servido por el
frontend, que escribe tanto en `public/` como en `dist/` desde la tarea de
chequeo de salud):

| Estado | Significado | Comportamiento |
|---|---|---|
| 🟢 Saludable | Todos los chequeos dentro de los umbrales aceptables | No requiere acción |
| 🟡 Advertencia | Disco < 20 %, último backup > 8 días, pendrive de recuperación > 90 días | Se muestra alerta no bloqueante con recomendación |
| 🔴 Crítico | Disco < 10 %, último backup > 14 días, PocketBase caído | Se muestra alerta destacada + acción correctiva concreta |

Cada alerta incluye:
- **Mensaje**: descripción del problema detectado.
- **Acción requerida**: pasos a seguir, redactados de forma operativa.
- **Documento de referencia**: archivo en `docs/` que detalla el procedimiento.

### 1.3 Capa de recuperación (ante incidentes)

Cobertura ante fallos de software, hardware o datos:

- **Pendrive de Recuperación**: backup de `pb_data` + menú con scripts de
  diagnóstico, reparación de PocketBase, restauración de backups y
  reinstalación del frontend (`scripts/recovery/*`).
- **Pendrive Instalador**: permite reinstalar el sistema en una PC nueva en
  forma desatendida (4 modos de instalación + 4 roles posibles).
- **Pendrive de Código Fuente**: archivo bajo custodia con el repositorio
  completo, historial Git, documentación y verificación SHA256.
- **Desinstalador limpio**: `DESINSTALAR.bat` remueve el sistema preservando
  automáticamente los datos en `C:\backup_fcea_<fecha>\`.

---

## 2. ¿Por qué este enfoque es efectivo?

### 2.1 Stack autocontenido y estándar

- **Frontend:** React 18 + TypeScript + Vite (estándar de la industria).
- **Backend:** PocketBase — un único binario `.exe` autocontenido que
  embebe SQLite, sin dependencias externas.
- **Base de datos:** SQLite, motor probado en miles de millones de
  dispositivos, con journaling y protección contra corrupción.
- **Cero servicios externos:** no hay APIs en la nube, ni claves de
  terceros, ni licencias propietarias, ni dependencias de red de la FCEA
  más allá de la LAN interna.

### 2.2 Dimensionamiento sobrado para la carga real

- Carga estimada: ~290 operaciones CRUD por día.
- Carga anual: ~105 000 operaciones / ~30 MB de base de datos.
- Límite técnico de SQLite: cientos de millones de registros sin
  degradación significativa.
- Margen: el sistema opera al **<1 % de su capacidad técnica**.

### 2.3 Probabilidad de fallo crítico

| Periodo | Probabilidad mensual estimada |
|---|---|
| Primeros 6 meses | < 0,1 % |
| Primer año | < 0,1 % |
| Mediano plazo (6–18 meses) | < 0,5 % |
| Largo plazo (18+ meses) con mantenimiento | < 0,5 % |
| Largo plazo (18+ meses) sin mantenimiento | < 2,0 % |

La principal causa potencial de fallo no es técnica sino ambiental
(corte de energía sin UPS, falla física del disco), y está cubierta
por los backups diarios con retención de 14 días.

---

## 3. Continuidad del sistema

El sistema fue diseñado para no depender de una persona en particular:

- **Código fuente** versionado en repositorio Git, archivado en pendrive
  bajo custodia institucional y verificable por hash SHA256.
- **Documentación**: 15+ documentos en `docs/` cubriendo arquitectura,
  instalación, operación, seguridad, mantenimiento y especificación SRS.
- **Tecnología estándar** (React + PocketBase + SQLite): cualquier
  desarrollador con experiencia básica puede tomar el proyecto.
- **Sin acoplamiento con servicios propietarios**: no hay claves, ni
  cuentas, ni licencias externas que mantener.
- **Reinstalación automatizada**: el pendrive instalador reproduce el
  sistema completo en una PC limpia con doble click.

---

## 4. Resumen visual

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   AUTOMÁTICO         AUTO‑DIAGNÓSTICO        RECUPERACIÓN       │
│   ───────────        ────────────────        ─────────────       │
│   • Backup           • Indicador 🟢/🟡/🔴     • Pendrive          │
│     diario 03:00      en header Monitor        instalador       │
│   • Watchdog PB      • Alertas con acción    • Pendrive          │
│     cada 30 s          requerida concreta      recuperación      │
│   • Limpieza         • Refresco cada 60 s    • Pendrive código   │
│     backups > 14 d   • Refer. a doc/           fuente            │
│   • Chequeo salud                            • Desinstalador     │
│     cada 30 min                                con respaldo      │
│                                                automático        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
        │                       │                      │
        ▼                       ▼                      ▼
   No requiere            Indica qué hacer      Permite reinstalar
   intervención            cuando la requiere   o reparar en
                                                cualquier momento
```

---

## 5. Documentos relacionados

- `docs/ARQUITECTURA.md` — diseño técnico y stack.
- `docs/INSTALACION.md` — procedimiento de instalación.
- `docs/OPERACION.md` — uso operativo cotidiano.
- `docs/guia_mantenimiento_paso_a_paso.md` — procedimientos manuales
  detallados (referencia para cuando una alerta lo requiera).
- `docs/checklist_prueba_pendrives.md` — plan de pruebas del esquema
  de instalación / recuperación / desinstalación.

---

*Documento técnico. Versión 1.0 — describe el esquema de mantenimiento
implementado en el sistema, independiente del responsable que lo opere.*
