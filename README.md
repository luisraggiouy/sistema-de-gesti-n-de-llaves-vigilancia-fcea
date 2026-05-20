# 🔑 Sistema de Gestión de Llaves — FCEA
## Facultad de Ciencias Económicas y de Administración

**Versión:** 6.0 (Pendrives v2)  
**Fecha:** Mayo 2026  
**Estado:** Producción

---

## 📋 Descripción

Sistema integral de gestión de llaves para el servicio de vigilancia de FCEA, diseñado para operar en modo kiosk con soporte para pantallas táctiles y monitores tradicionales.

### Características Principales

- ✅ **Terminal de Usuario**: Registro de entrega y devolución de llaves
- ✅ **Monitor de Vigilancia**: Control en tiempo real de llaves en uso
- ✅ **Dashboard de Estadísticas**: Análisis y reportes del sistema
- ✅ **Gestión de Objetos Perdidos**: Registro y seguimiento
- ✅ **Sistema de Autorizaciones**: Control de ingresos y búsquedas
- ✅ **Respaldos Automáticos**: Semanales (Domingos 8 AM) con configuración automática
- ✅ **Sistema de Alertas**: Monitoreo de salud del sistema en tiempo real
- ✅ **Mantenimiento Automatizado**: Verificación diaria y mantenimiento semanal
- ✅ **Inicio Automático**: Se inicia automáticamente al arrancar Windows
- ✅ **Watchdog Completo**: Reinicio automático si PocketBase o Frontend se caen
- ✅ **Modo Kiosk**: Operación segura en producción
- ✅ **Soporte Multi-Pantalla**: 3 pantallas simultáneas
- ✅ **Instalación Automática**: Pendrive instalador con menú interactivo

---

## 🚀 Inicio Rápido

### Para Instalar el Sistema por Primera Vez

1. **Leer la guía única de pendrives**:
   ```
   docs/pendrives_v2_GUIA_DEFINITIVA.md  ← EMPEZAR AQUÍ
   ```

2. **Preparar los pendrives v2**:
   - Pendrive INSTALADOR (16 GB)
   - Pendrive RECUPERACIÓN (8 GB)

3. **Ejecutar el instalador**:
   - Conectar pendrive INSTALADOR
   - Ejecutar: `REINSTALAR-COMPLETO.bat`
   - Responder los diálogos (modo + hardware)
   - Esperar 10-15 minutos

4. **¡Listo!** El sistema arranca automáticamente en modo kiosk

### Para Desarrolladores

```bash
# Clonar el repositorio
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git

# Navegar al directorio
cd sistema-de-gesti-n-de-llaves-vigilancia-fcea

# Instalar dependencias
npm install

# Iniciar el sistema completo (recomendado)
# Esto inicia PocketBase + Frontend + Watchdog automáticamente
iniciar_sistema.bat

# O manualmente:
npm run dev                    # Terminal 1: Frontend
cd pocketbase && pocketbase serve  # Terminal 2: Backend
```

**Nota**: `iniciar_sistema.bat` ahora incluye un **watchdog automático** que reinicia PocketBase si se cae.

---

## 📚 Documentación

### 📖 Índice Completo
Ver: **[docs/INDICE_DOCUMENTACION.md](docs/INDICE_DOCUMENTACION.md)** para el índice completo de toda la documentación.

### 🎯 Documentos Clave por Rol

#### Para Personal de Sistemas:
1. ⭐ [pendrives_v2_GUIA_DEFINITIVA.md](docs/pendrives_v2_GUIA_DEFINITIVA.md) - Guía única para instalar/reparar/desinstalar
2. [install_config_schema.md](docs/install_config_schema.md) - Esquema de `install_config.json`
3. [configuracion_produccion.md](docs/configuracion_produccion.md) - Configuración de producción
4. [guia_mantenimiento_paso_a_paso.md](docs/guia_mantenimiento_paso_a_paso.md) - Mantenimiento del sistema

#### Para Vigilantes:
1. ⭐ [instructivo_acceso_dashboard.md](docs/instructivo_acceso_dashboard.md) - Acceso al dashboard

#### Para Custodios (Jefes de Apoyo y Turno):
1. [instructivo_acceso_dashboard.md](docs/instructivo_acceso_dashboard.md) - Dashboard y exportación
2. [funcionalidad_administracion_custodio.md](docs/funcionalidad_administracion_custodio.md) - Funcionalidades

#### Para Administrador (Intendente):
1. [funcionalidad_administracion_custodio.md](docs/funcionalidad_administracion_custodio.md) - Permisos completos
2. [plan_actualizaciones_mantenimiento.md](docs/plan_actualizaciones_mantenimiento.md) - Planificación

#### Para Autoridades:
1. [presentacion_autoridades.md](docs/presentacion_autoridades.md) - Presentación oficial
2. [SRS_Sistema_Gestion_Llaves_FCEA.md](docs/SRS_Sistema_Gestion_Llaves_FCEA.md) - Especificación técnica

---

## 🖥️ Configuraciones de Hardware Soportadas

### Opción A: Pantallas Táctiles (Producción Final)
- 1 Mini PC con Windows 10/11
- 3 Pantallas táctiles (21-24")
- Teclado virtual automático
- Sin periféricos físicos

### Opción B: Monitores Tradicionales (Etapa de Prueba)
- 1 Mini PC con Windows 10/11
- 3 Monitores estándar
- 3 Teclados USB + 3 Mouses USB
- Más económico para pruebas

**Nota**: Puedes migrar de tradicional a táctil sin reinstalar el sistema.

---

## 🔧 Tecnologías Utilizadas

### Frontend
- **React 18** con TypeScript
- **Vite** como build tool
- **TailwindCSS** para estilos
- **Shadcn/ui** para componentes
- **Recharts** para gráficos
- **React Query** para gestión de estado

### Backend
- **PocketBase** como base de datos y API
- **SQLite** como motor de base de datos

### Herramientas
- **Git** para control de versiones
- **GitHub** para repositorio remoto
- **PowerShell** para scripts de instalación
- **Windows Task Scheduler** para mantenimiento automático

---

## 👥 Roles y Permisos

| Rol | Usuario | Permisos |
|-----|---------|----------|
| **Administrador** | Intendente | Acceso completo, exportación, gestión de usuarios |
| **Custodio** | Jefes de Apoyo y Turno | Ver dashboard, exportar reportes |
| **Vigilante** | Personal de vigilancia | Ver dashboard (solo lectura) |

---

## 🔐 Contraseñas por Defecto

Después de reinstalar el sistema con el pendrive restaurador:

- **Administrador**: `admin123`
- **Custodio**: `custodio2026`

⚠️ **IMPORTANTE**: Cambiar estas contraseñas inmediatamente después de la instalación.

---

## 📊 Estructura del Proyecto

```
sistema-de-gesti-n-de-llaves-vigilancia-fcea/
├── docs/                          # Documentación completa
│   ├── INDICE_DOCUMENTACION.md    # Índice de toda la documentación
│   ├── pendrives_v2_GUIA_DEFINITIVA.md  # Guía única de pendrives
│   └── ...                        # Otros documentos
├── src/                           # Código fuente del frontend
│   ├── components/                # Componentes React
│   ├── pages/                     # Páginas principales
│   ├── hooks/                     # Custom hooks
│   ├── types/                     # Definiciones TypeScript
│   └── utils/                     # Utilidades
├── pocketbase/                    # Backend y base de datos
│   ├── pocketbase.exe             # Ejecutable PocketBase
│   ├── pb_data/                   # Datos de la base de datos
│   └── maintenance/               # Scripts de mantenimiento
├── scripts/                       # Scripts de instalación y mantenimiento
│   ├── preparar_pendrive_instalador.bat
│   ├── instalar_automatico.ps1
│   └── ...
├── public/                        # Archivos públicos
├── package.json                   # Dependencias del proyecto
├── vite.config.ts                 # Configuración de Vite
└── iniciar_sistema.bat            # Script de inicio del sistema
```

---

## 🔄 Mantenimiento

### Automático (Configuración en 5 minutos)
- **Respaldos semanales**: Domingos a las 8:00 AM
- **Verificación de salud**: Diaria a las 7:00 AM
- **Alertas en Monitor**: Notificaciones automáticas de problemas
- **Verificación de integridad**: Automática
- **Limpieza de respaldos antiguos**: Mantiene 52 copias (1 año)

### Manual (Reducido al mínimo)
- **Anual**: Archivado de datos históricos únicamente
- **Bajo demanda**: Solo cuando el sistema muestre alertas críticas

### Sistema de Alertas Inteligente
El Monitor de Vigilancia muestra automáticamente:
- 🔴 **Alertas Críticas**: Espacio en disco bajo, backups fallidos, servicios caídos
- 🟡 **Advertencias**: Pendrive desactualizado, base de datos grande, errores en logs
- 📊 **Métricas**: Espacio disco, último backup, tamaño BD, último mantenimiento

Ver: [guia_mantenimiento_paso_a_paso.md](docs/guia_mantenimiento_paso_a_paso.md)

---

## 🆘 Soporte y Solución de Problemas

### Problemas Comunes

1. **El sistema no arranca**:
   ```
   → Ejecutar: C:\sistema-llaves-fcea\iniciar_sistema.bat
   ```

2. **Error CORS**:
   ```
   → Ejecutar: scripts\fix_cors_directo.bat
   ```

3. **Pantallas no se detectan**:
   ```
   → Windows + P → "Extender"
   → Configuración → Sistema → Pantalla → "Detectar"
   ```

4. **Sistema corrupto**:
   ```
   → Usar pendrive de RECUPERACIÓN
   → Ejecutar: RESTAURAR_SISTEMA.bat
   ```

### Documentación de Soporte
- [resolucion_error_cors.md](docs/resolucion_error_cors.md)
- [guia_mantenimiento_paso_a_paso.md](docs/guia_mantenimiento_paso_a_paso.md)
- [pendrives_v2_GUIA_DEFINITIVA.md](docs/pendrives_v2_GUIA_DEFINITIVA.md) §4 (reparar / reinstalar)

---

## 📞 Contacto

Para soporte técnico:
- Consultar la documentación en `docs/`
- Revisar logs en: `C:\sistema-llaves-fcea\pocketbase\maintenance\logs\`
- Contactar a Personal de Sistemas de FCEA

---

## 📝 Licencia

Sistema desarrollado para uso exclusivo de la Facultad de Ciencias Económicas y de Administración (FCEA).

---

## 🔗 Enlaces Útiles

- **Repositorio**: https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea
- **Node.js**: https://nodejs.org/
- **PocketBase**: https://pocketbase.io/
- **React**: https://react.dev/
- **Vite**: https://vitejs.dev/

---

## 📅 Historial de Versiones

### Versión 1.0 (Abril 2026)
- ✅ Sistema completo de instalación con pendrives
- ✅ Soporte para pantallas táctiles y monitores tradicionales
- ✅ Instalador automático con menú interactivo
- ✅ Guía de mantenimiento paso a paso
- ✅ Documentación completa actualizada
- ✅ Roles y permisos actualizados
- ✅ Sesión automática de 5 minutos
- ✅ Exportación a pendrive en modo kiosk

---

*Sistema desarrollado para FCEA — Abril 2026*
