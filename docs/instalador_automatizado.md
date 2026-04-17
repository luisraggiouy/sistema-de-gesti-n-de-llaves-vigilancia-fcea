# Instalador Automatizado para Sistema de Gestión de Llaves FCEA

## Requisitos de Hardware y Software

### Hardware Mínimo Recomendado
- Procesador: Intel Core i3 o equivalente (2+ núcleos)
- RAM: 4GB mínimo, 8GB recomendado
- Almacenamiento: 20GB de espacio libre en disco duro
- Pantalla: Resolución mínima 1366x768
- Conexiones: Puerto USB para pendrive de instalación/respaldo

### Software Requerido
- Sistema Operativo: Windows 10/11 (64 bits)
- Permisos: Administrador local para instalación

## Creación del Instalador Automatizado

Es completamente factible crear un pendrive de instalación automatizada que configure todo el sistema sin intervención manual significativa. El proceso se puede implementar en aproximadamente 2-3 días de trabajo.

### Componentes del Instalador

1. **Instalador Maestro AutoRun**
   - Archivo `autorun.inf` para inicio automático al insertar pendrive
   - Script principal `INSTALAR_SISTEMA.bat` que gestiona todo el proceso

2. **Componentes a Instalar Automáticamente**
   - Node.js LTS (versión preempaquetada)
   - PocketBase (versión específica probada)
   - Repositorio completo del Sistema de Gestión de Llaves
   - Paquetes NPM necesarios (preempaquetados para evitar descargas)

3. **Configuraciones Automáticas**
   - Iniciar con Windows
   - Puertos firewall
   - Base de datos con datos iniciales
   - Creación de accesos directos en escritorio
   - Configuración de respaldos automáticos

4. **Opciones Durante Instalación**
   - Instalación completa (recomendado)
   - Instalación personalizada (con opciones para componentes específicos)
   - Reinstalación/Recuperación (manteniendo datos existentes)

## Procedimiento de Implementación

### Fase 1: Preparación del Instalador

1. **Crear Estructura del Pendrive**
   ```
   SISTEMA_LLAVES_FCEA_INSTALLER/
   ├── autorun.inf                  # Configuración de inicio automático
   ├── INSTALAR_SISTEMA.bat         # Script principal de instalación
   ├── assets/                      # Recursos gráficos e iconos
   │   └── logo.ico
   ├── installers/                  # Paquetes de instaladores
   │   ├── node-v18.17.1-x64.msi    # Instalador Node.js
   │   └── vcredist_x64.exe         # Visual C++ Redistributable
   ├── packages/                    # Componentes del sistema preempaquetados
   │   ├── node_modules.7z          # Dependencias comprimidas
   │   └── pocketbase/
   ├── system/                      # Sistema completo
   │   ├── pocketbase/
   │   ├── src/
   │   └── public/
   └── tools/                       # Utilidades de instalación
       ├── 7z.exe                   # Compresor/descompresor
       ├── setup_utils.bat          # Funciones de utilidad
       └── config_templates/        # Plantillas de configuración
   ```

2. **Crear Script Principal de Instalación**
   
   El script `INSTALAR_SISTEMA.bat` gestionará el proceso completo:

   ```batch
   @echo off
   setlocal enabledelayedexpansion

   :: Inicio del instalador con interfaz gráfica
   title Instalador Sistema de Gestión de Llaves FCEA v4.0
   color 1F
   
   :: Verificación de privilegios de administrador
   echo Verificando permisos de administrador...
   net session >nul 2>&1
   if %errorLevel% neq 0 (
       echo ERROR: Se requieren privilegios de administrador.
       echo Por favor, ejecute el instalador como administrador.
       pause
       exit /b 1
   )
   
   :: Menú principal
   :MENU
   cls
   echo ======================================================
   echo     SISTEMA DE GESTION DE LLAVES FCEA - INSTALADOR
   echo ======================================================
   echo.
   echo  [1] Instalación Completa (Recomendado)
   echo  [2] Instalación Personalizada
   echo  [3] Reinstalación/Recuperación
   echo  [4] Cancelar
   echo.
   
   set /p OPCION="Seleccione una opción (1-4): "
   
   if "%OPCION%"=="1" goto INSTALACION_COMPLETA
   if "%OPCION%"=="2" goto INSTALACION_PERSONALIZADA
   if "%OPCION%"=="3" goto REINSTALACION
   if "%OPCION%"=="4" goto SALIR
   
   :: Instalación completa
   :INSTALACION_COMPLETA
   call :VERIFICAR_REQUISITOS
   call :INSTALAR_NODEJS
   call :INSTALAR_SISTEMA
   call :CONFIGURAR_SISTEMA
   call :CREAR_ACCESOS_DIRECTOS
   call :CONFIGURAR_INICIO_AUTOMATICO
   call :FINALIZAR
   goto :eof
   
   :: Verificar requisitos del sistema
   :VERIFICAR_REQUISITOS
   echo Verificando requisitos del sistema...
   :: Verificar Windows 10/11
   ver | find "10." >nul || ver | find "11." >nul
   if %errorLevel% neq 0 (
       echo ERROR: Se requiere Windows 10 o Windows 11.
       pause
       exit /b 1
   )
   :: Verificar espacio en disco (mínimo 5GB)
   for /f "tokens=3" %%a in ('dir c:\ ^| findstr /C:"bytes free"') do set ESPACIO=%%a
   set ESPACIO_MINIMO=5000000000
   if %ESPACIO% LSS %ESPACIO_MINIMO% (
       echo ERROR: Se requieren al menos 5GB de espacio libre.
       pause
       exit /b 1
   )
   echo Requisitos verificados correctamente.
   return
   
   :: Instalar Node.js
   :INSTALAR_NODEJS
   echo Instalando Node.js...
   :: Verificar si ya está instalado
   where node >nul 2>&1
   if %errorLevel% equ 0 (
       echo Node.js ya está instalado. Verificando versión...
       for /f "tokens=1,2,3 delims=." %%a in ('node -v') do set NODE_VER=%%a%%b%%c
       if !NODE_VER! GEQ 16 (
           echo Versión de Node.js compatible detectada.
           return
       )
   )
   :: Instalar Node.js desde instalador empaquetado
   echo Instalando Node.js...
   start /wait installers\node-v18.17.1-x64.msi /quiet
   echo Node.js instalado correctamente.
   return
   
   :: ... [continúa el script con todas las funciones]
   ```

### Fase 2: Implementación de Instalación Desatendida

1. **Scripts de Configuración Post-Instalación**
   - Configuración automática de la base de datos
   - Ajustes específicos según el tipo de equipo/instalación
   - Creación de tareas programadas para mantenimiento

2. **Instalación de Servicios de Windows**
   - Registro de PocketBase como servicio
   - Configuración de inicio automático
   - Permisos adecuados para funcionamiento sin errores

3. **Validaciones y Comprobaciones**
   - Verificación de instalación correcta
   - Pruebas de conectividad
   - Chequeos de salud del sistema

### Fase 3: Creación de Sistema de Configuración Web

Adicionalmente, se puede implementar un panel de configuración web accesible localmente:

1. **Panel de Administración del Sistema**
   - Página `/admin-system` protegida con contraseña
   - Configuración del sistema post-instalación
   - Herramientas de diagnóstico y mantenimiento
   - Gestión de respaldos y restauraciones

2. **Asistente Inicial**
   - Primera ejecución guiada paso a paso
   - Configuración de vigilantes iniciales
   - Importación de datos existentes (si procede)

## Ventajas del Sistema Automatizado

1. **Tiempo de Implementación Reducido**
   - Instalación completa en menos de 10 minutos
   - Sin necesidad de conocimientos técnicos avanzados
   - Configuración inmediata sin ajustes manuales

2. **Mantenimiento Simplificado**
   - Actualizaciones distribuibles por pendrive
   - Respaldos programados automáticamente
   - Recuperación con un solo clic

3. **Consistencia entre Instalaciones**
   - Mismo comportamiento independientemente del hardware
   - Configuraciones estandarizadas
   - Entorno aislado de problemas externos

## Requisitos Adicionales para Despliegue

1. **Pendrive de 16GB o mayor** (para contener todos los componentes)
2. **Acceso a Internet durante la creación** del instalador (no necesario durante la instalación)
3. **Pruebas en máquina virtual** para validar el proceso completo

## Tiempo Estimado de Implementación

- Desarrollo del instalador automatizado: **2-3 días**
- Pruebas en diferentes configuraciones: **1 día**
- Documentación y manuales: **1 día**

Total: **4-5 días laborables**

## Conclusión

Es completamente factible crear un instalador automatizado mediante pendrive que realice todo el proceso de instalación y configuración sin intervención manual significativa. La solución propuesta utiliza tecnologías estándar de Windows y scripts batch, sin requerir herramientas externas complejas.

Esta aproximación permitirá que personal no técnico pueda instalar y configurar el sistema completo, además de facilitar actualizaciones futuras y mantenimiento del sistema.