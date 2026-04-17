# Preparación de Pendrive para Instalador Automatizado

Este documento describe el proceso para preparar un pendrive con el instalador automatizado del Sistema de Gestión de Llaves FCEA. Este pendrive permitirá instalar el sistema completo en cualquier equipo compatible, con soporte para pantallas táctiles y configuración optimizada.

## Requisitos

- **Pendrive USB**: 16GB o superior, preferiblemente USB 3.0 para mayor velocidad.
- **Formato**: FAT32 (para máxima compatibilidad con diferentes sistemas).
- **Computadora**: Acceso a este equipo con los archivos del sistema.

## Estructura de Directorios

El pendrive debe tener la siguiente estructura:

```
SISTEMA_LLAVES_FCEA_INSTALLER/
├── autorun.inf                      # Configuración autoarranque
├── INSTALAR_SISTEMA.bat             # Script principal de instalación
├── README.txt                       # Instrucciones básicas
├── assets/                          # Recursos gráficos
│   └── logo.ico                     # Icono del instalador
├── installers/                      # Instaladores de software necesario
│   ├── node-v18.17.1-x64.msi        # Instalador Node.js
│   └── vcredist_x64.exe             # Visual C++ Redistributable (opcional)
├── packages/                        # Componentes preempaquetados
│   ├── node_modules.7z              # Dependencias comprimidas (opcional)
│   └── pocketbase/                  # Motor de base de datos
│       ├── pocketbase.exe           # Ejecutable PocketBase
│       ├── pb_data_produccion/      # Datos iniciales para producción
│       └── pb_data_prueba/          # Datos iniciales para pruebas
├── system/                          # Sistema completo
│   ├── pocketbase/                  # Archivos PocketBase
│   ├── public/                      # Archivos públicos
│   ├── src/                         # Código fuente
│   └── package.json                 # Dependencias
├── recursos/                        # Recursos adicionales
│   ├── diccionario_personalizado.dic # Diccionario para teclado táctil
│   └── wallpapers/                  # Fondos de pantalla personalizados
└── tools/                           # Herramientas auxiliares
    ├── 7z.exe                       # Compresor/descompresor
    └── setup_utils.bat              # Utilidades de instalación
```

## Instrucciones Paso a Paso

### 1. Preparación del Pendrive

1. Conecta el pendrive a este equipo.
2. Abre el Explorador de Archivos y localiza la letra asignada al pendrive (ej. E:).
3. Formatea el pendrive:
   ```
   > Clic derecho en el pendrive > Formatear
   > Selecciona "FAT32" como sistema de archivos
   > Marca "Formato rápido"
   > Clic en "Iniciar"
   ```

### 2. Crear Estructura de Carpetas

1. Crea la carpeta principal en el pendrive:
   ```
   > Abre el pendrive
   > Crea una nueva carpeta llamada "SISTEMA_LLAVES_FCEA_INSTALLER"
   ```

2. Dentro de la carpeta principal, crea las siguientes subcarpetas:
   - `assets`
   - `installers`
   - `packages`
   - `packages/pocketbase`
   - `packages/pocketbase/pb_data_produccion`
   - `packages/pocketbase/pb_data_prueba`
   - `system`
   - `recursos`
   - `recursos/wallpapers`
   - `tools`

### 3. Copiar Archivos del Instalador

1. Abre la carpeta `c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\scripts\instalador_automatico\` en este equipo.

2. Copia los siguientes archivos a la raíz de tu carpeta principal en el pendrive:
   - `INSTALAR_SISTEMA.bat` → `SISTEMA_LLAVES_FCEA_INSTALLER/INSTALAR_SISTEMA.bat`
   - `autorun.inf` → `SISTEMA_LLAVES_FCEA_INSTALLER/autorun.inf`

3. Copia el archivo de diccionario personalizado:
   - `recursos/diccionario_personalizado.dic` → `SISTEMA_LLAVES_FCEA_INSTALLER/recursos/diccionario_personalizado.dic`

### 4. Preparar Archivos del Sistema

1. Para **system/**, copia el repositorio completo (excepto node_modules):
   ```
   > Abre c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\
   > Selecciona todos los archivos (excepto node_modules y .git)
   > Copia al pendrive en SISTEMA_LLAVES_FCEA_INSTALLER/system/
   ```

2. Para **packages/pocketbase/**:
   ```
   > Copia el archivo pocketbase.exe desde c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase\
   > Pégalo en SISTEMA_LLAVES_FCEA_INSTALLER/packages/pocketbase/
   ```

3. Para datos de prueba, copia la base de datos actual (si deseas conservar datos de ejemplo):
   ```
   > Copia toda la carpeta c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase\pb_data\
   > Pégala en SISTEMA_LLAVES_FCEA_INSTALLER/packages/pocketbase/pb_data_prueba/
   ```

### 5. Descargar Instaladores Necesarios

1. Node.js Instalador:
   - Visita [https://nodejs.org/download/release/v18.17.1/](https://nodejs.org/download/release/v18.17.1/)
   - Descarga `node-v18.17.1-x64.msi`
   - Guárdalo en `SISTEMA_LLAVES_FCEA_INSTALLER/installers/`

2. Visual C++ Redistributable (opcional pero recomendado):
   - Visita [https://aka.ms/vs/17/release/vc_redist.x64.exe](https://aka.ms/vs/17/release/vc_redist.x64.exe)
   - Guárdalo en `SISTEMA_LLAVES_FCEA_INSTALLER/installers/`

### 6. Crear Archivo README.txt

Crea un archivo README.txt en la raíz con instrucciones básicas:

```
SISTEMA DE GESTIÓN DE LLAVES FCEA - INSTALADOR AUTOMATIZADO
===========================================================

INSTRUCCIONES DE INSTALACIÓN:

1. Inserta el pendrive en la computadora donde deseas instalar el sistema.
2. Si el instalador no se inicia automáticamente, abre el pendrive y haz
   doble clic en "INSTALAR_SISTEMA.bat".
3. Sigue las instrucciones en pantalla.
4. Selecciona el modo de instalación (PRODUCCIÓN o PRUEBA).
5. Espera a que el proceso finalice.

REQUISITOS MÍNIMOS:
- Windows 10/11 (64 bits)
- 4GB RAM (8GB recomendado)
- 5GB espacio libre en disco
- Conexión a Internet (opcional, para descarga de componentes)
- Permisos de administrador

SOPORTE TÉCNICO:
Para asistencia, contacta al equipo de Vigilancia FCEA.
```

### 7. Verificación

Una vez preparado el pendrive:

1. Pruébalo en esta misma computadora:
   - Desconecta y vuelve a conectar el pendrive
   - Abre el pendrive y ejecuta INSTALAR_SISTEMA.bat
   - Verifica que aparezca el menú de instalación
   - Cancela la instalación

2. Si todo funciona correctamente, el pendrive está listo para ser usado en cualquier equipo compatible.

## Uso del Pendrive de Instalación

Para usar el pendrive de instalación:

1. **Preparación del equipo destino**:
   - Asegúrate de que el equipo destino cumpla con los requisitos mínimos
   - Cierra todas las aplicaciones
   - Inicia sesión con una cuenta con permisos de administrador

2. **Instalación**:
   - Inserta el pendrive en un puerto USB
   - Si el autorun está habilitado, el instalador debería iniciarse automáticamente
   - Si no, abre el pendrive manualmente y haz doble clic en "INSTALAR_SISTEMA.bat"
   - Sigue las instrucciones en pantalla:
     * Selecciona el modo de instalación (Producción/Prueba)
     * Confirma las opciones
     * Espera a que el proceso finalice

3. **Post-instalación**:
   - Para pantallas táctiles, verifica la configuración del teclado virtual
   - Prueba el inicio automático si instalaste en modo producción
   - Verifica el acceso al dashboard

## Solución de Problemas

### El instalador no inicia automáticamente
- El autorun puede estar deshabilitado en Windows por seguridad
- Abre el pendrive manualmente y ejecuta INSTALAR_SISTEMA.bat

### Error "Se necesitan permisos de administrador"
- Haz clic derecho en INSTALAR_SISTEMA.bat y selecciona "Ejecutar como administrador"

### Fallo al instalar Node.js
- Verifica que el archivo node-v18.17.1-x64.msi esté en la carpeta installers/
- Intenta descargar e instalar Node.js manualmente desde [nodejs.org](https://nodejs.org/)

### Error al configurar el teclado táctil
- Windows puede tener configuraciones de seguridad que bloquean cambios en el registro
- Ejecuta el script de verificación de teclado táctil manualmente después de la instalación

### PocketBase no inicia
- Verifica que el archivo pocketbase.exe se copió correctamente
- Comprueba que no hay otro servicio usando el puerto 8090
- Revisa los logs en la carpeta de instalación

## Actualización del Pendrive

Para actualizar el pendrive con nuevas versiones del sistema:

1. Reemplaza los archivos en la carpeta `system/` con la versión más reciente del sistema
2. Si hay cambios en la base de datos, actualiza los archivos en `packages/pocketbase/pb_data_produccion/` y `pb_data_prueba/`
3. Si hay cambios en el instalador, actualiza el archivo INSTALAR_SISTEMA.bat

## Notas Adicionales

- El pendrive es reutilizable y puede ser actualizado con nuevas versiones del sistema
- Recomendamos etiquetar el pendrive con la versión del sistema que contiene
- Guarda una copia de seguridad del contenido del pendrive en otro medio