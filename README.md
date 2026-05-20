# Sistema de Gestión de Llaves – FCEA UdelaR

> Sistema de gestión y vigilancia de llaves de aulas / oficinas para la Facultad
> de Ciencias Económicas y de Administración (UdelaR), con arquitectura
> **distribuida de 3 mini-PCs** sobre red local cerrada.

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)]()
[![Stack](https://img.shields.io/badge/stack-Vite%20%2B%20React%20%2B%20TypeScript%20%2B%20PocketBase-success.svg)]()
[![License](https://img.shields.io/badge/license-FCEA%20UdelaR-lightgrey.svg)]()

---

## Novedades de v2.0

- 🖥️ **Arquitectura de 3 PCs** conectadas por switch de red local cerrada.
- 👆 **Teclado virtual con predicción** y detección automática de pantallas
  táctiles.
- 🔌 **4 modos de instalación**: desarrollo, económico, mixto e ideal (táctil).
- 💾 **Watchdog + backup diario** corriendo solo en la PC servidor.
- 💼 **Pendrives unificados**: un solo script genera el instalador o el
  pendrive de recuperación según el parámetro.
- 🧹 **Repo limpio**: se removieron 30+ scripts duplicados de v1.x.

Detalles completos en [`docs/ARQUITECTURA.md`](./docs/ARQUITECTURA.md).

---

## Inicio rápido

### Modo desarrollo (1 PC)
```bat
git clone <repo>
cd sistema-de-gestion-de-llaves-vigilancia-fcea
scripts\install\INSTALAR.bat
:: Elegir [1] DESARROLLO
scripts\install\INICIAR.bat
```

### Modo producción (3 PCs)
1. Generar pendrive instalador desde una PC con el repo:
   ```powershell
   .\scripts\pendrive\crear_pendrive.ps1 -Drive E: -Tipo instalador
   ```
2. Conectarlo a cada PC y correr `INSTALAR.bat`, eligiendo el modo (2, 3 o 4)
   y el rol (`S` cabina, `A` o `B` terminales).
3. En la cabina, además:
   ```powershell
   .\scripts\install\CONFIGURAR_INICIO_AUTOMATICO.ps1
   .\scripts\maintenance\CONFIGURAR_MANTENIMIENTO.ps1
   ```

Guía completa: [`docs/INSTALACION.md`](./docs/INSTALACION.md).

---

## Estructura del repositorio

```
.
├─ docs/                       # Documentación del sistema
│  ├─ ARQUITECTURA.md          ← Topología, roles, modos
│  ├─ INSTALACION.md           ← Instalación paso a paso
│  ├─ OPERACION.md             ← Operación diaria, mantenimiento, troubleshooting
│  └─ ...
├─ pocketbase/                 # Backend (servidor de datos)
│  ├─ pocketbase.exe
│  ├─ pb_config.json           ← CORS abierto para la red local
│  ├─ pb_data/                 ← Datos (no se commitea WAL/SHM)
│  ├─ pb_migrations/           ← Migraciones del schema
│  └─ start-server.bat         ← Arranca PocketBase en 0.0.0.0:8090
├─ public/
│  └─ config.json              ← Runtime config (rol, URL, modo, ui)
├─ scripts/
│  ├─ install/                 ← INSTALAR.bat, INICIAR.bat, CONFIGURAR_INICIO_AUTOMATICO.ps1
│  ├─ maintenance/             ← watchdog.ps1, backup_automatico.ps1, CONFIGURAR_MANTENIMIENTO.ps1
│  ├─ pendrive/                ← crear_pendrive.ps1 (instalador / recuperación)
│  └─ recovery/                ← RECUPERAR.bat + utilidades
├─ src/                        # Frontend (Vite + React + TS)
│  ├─ components/
│  │  ├─ monitor/              ← Vista cabina (rol=monitor)
│  │  ├─ terminal/             ← Vista de las terminales
│  │  ├─ dashboard/            ← Reportes
│  │  ├─ admin/                ← Admin / autorizaciones
│  │  └─ ui/                   ← shadcn + VirtualKeyboard + TouchInput
│  ├─ hooks/                   ← useDeviceConfig, useTouchDetection, etc.
│  ├─ lib/
│  │  ├─ runtimeConfig.ts      ← Carga sincronizada de public/config.json
│  │  └─ pocketbase.ts         ← Cliente PB con URL dinámica
│  └─ pages/
└─ package.json
```

---

## Stack técnico

- **Frontend**: Vite + React 18 + TypeScript + TailwindCSS + shadcn/ui
- **Backend**: PocketBase 0.22+ (SQLite embebida)
- **Tiempo real**: WebSockets nativos de PocketBase (subscripciones de colección)
- **Despliegue**: Windows 10/11 + Chrome en modo kiosk
- **Automatización**: Task Scheduler de Windows (watchdog + backup + autostart)

---

## Documentación

Ver [`docs/INDICE_DOCUMENTACION.md`](./docs/INDICE_DOCUMENTACION.md) para el
índice completo.

---

## Soporte

Para soporte o reportar bugs, contactar al equipo de mantenimiento. Antes,
correr el diagnóstico desde el pendrive de recuperación
(`RECUPERAR.bat → [1] Diagnostico`) y adjuntar el output.
