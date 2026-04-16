# 🔧 PROCEDIMIENTO: Reinstalación del Sistema ante Fallas
## Sistema de Gestión de Llaves — FCEA

**Versión:** 1.0  
**Fecha:** Abril 2026  
**Destinatarios:** Autoridades de la Facultad, Personal de Sistemas, Jefes de Vigilancia

---

## 1. Resumen para autoridades

El sistema está diseñado para que, en caso de falla grave, pueda ser **restaurado completamente** siguiendo pasos simples. Existen dos métodos:

| Método | Dificultad | Tiempo estimado | ¿Quién lo hace? |
|--------|-----------|-----------------|-----------------|
| **Método A: Pendrive de recuperación** | Muy fácil (enchufar y ejecutar) | 5-10 minutos | Cualquier persona |
| **Método B: Reinstalación manual** | Intermedia | 15-30 minutos | Personal de Sistemas |

---

## 2. MÉTODO A: Pendrive de Recuperación (Plug & Play)

### 2.1 ¿Qué es el pendrive de recuperación?

Es un pendrive USB preparado de antemano que contiene **todo lo necesario** para restaurar el sistema. Al conectarlo y ejecutar un archivo, el sistema se reinstala automáticamente conservando todos los datos históricos.

### 2.2 Preparación del pendrive (se hace UNA sola vez)

> ⚠️ Este paso lo realiza el personal de Sistemas al momento de la instalación inicial.

1. Consiga un pendrive USB de al menos **2 GB**
2. Formatéelo (botón derecho → Formatear → FAT32 o NTFS)
3. Copie **toda la carpeta del sistema** al pendrive:
   - Copie la carpeta `sistema-de-gesti-n-de-llaves-vigilancia-fcea` completa
4. Dentro del pendrive, cree un archivo llamado **`RESTAURAR_SISTEMA.bat`** con el siguiente contenido:

```batch
@echo off
echo ============================================
echo   RESTAURACION DEL SISTEMA DE LLAVES FCEA
echo ============================================
echo.
echo Este proceso restaurara el sistema completo.
echo Los datos historicos se mantendran intactos.
echo.
echo Presione cualquier tecla para continuar...
pause > nul

echo.
echo [1/5] Detectando unidad del pendrive...
set "USB_DRIVE=%~d0"
set "SISTEMA_DIR=C:\sistema-llaves-fcea"
echo     Pendrive detectado en: %USB_DRIVE%

echo.
echo [2/5] Verificando si existe instalacion previa...
if exist "%SISTEMA_DIR%\pocketbase\pb_data" (
    echo     Se encontro base de datos existente.
    echo     Respaldando datos antes de restaurar...
    set "BACKUP_DIR=%SISTEMA_DIR%\respaldo_antes_restauracion_%date:~-4%%date:~3,2%%date:~0,2%"
    mkdir "%BACKUP_DIR%" 2>nul
    xcopy "%SISTEMA_DIR%\pocketbase\pb_data" "%BACKUP_DIR%\pb_data\" /E /I /Q
    echo     Respaldo guardado en: %BACKUP_DIR%
) else (
    echo     No se encontro instalacion previa.
)

echo.
echo [3/5] Copiando archivos del sistema...
xcopy "%USB_DRIVE%\sistema-de-gesti-n-de-llaves-vigilancia-fcea" "%SISTEMA_DIR%" /E /I /Q /Y
echo     Archivos copiados correctamente.

echo.
echo [4/5] Restaurando base de datos...
if exist "%BACKUP_DIR%\pb_data" (
    echo     Restaurando datos historicos...
    xcopy "%BACKUP_DIR%\pb_data" "%SISTEMA_DIR%\pocketbase\pb_data\" /E /I /Q /Y
    echo     Datos historicos restaurados.
)

echo.
echo [5/5] Iniciando el sistema...
cd /d "%SISTEMA_DIR%"
call iniciar_sistema.bat

echo.
echo ============================================
echo   RESTAURACION COMPLETADA EXITOSAMENTE
echo ============================================
echo.
echo El sistema esta funcionando en:
echo   http://localhost:8080/
echo.
pause
```

5. **Etiquete el pendrive** claramente: "RECUPERACIÓN SISTEMA LLAVES FCEA - NO BORRAR"
6. Guárdelo en un lugar seguro (caja fuerte de vigilancia o despacho del jefe)

### 2.3 Uso del pendrive de recuperación (cuando el sistema falla)

```
PASO 1:  Conecte el pendrive a cualquier puerto USB de la computadora
         donde funciona el sistema.

PASO 2:  Abra "Este equipo" (Mi PC) y entre al pendrive.

PASO 3:  Haga doble clic en el archivo "RESTAURAR_SISTEMA.bat"

PASO 4:  Aparecerá una ventana negra con texto. 
         Presione cualquier tecla cuando se lo pida.

PASO 5:  Espere a que termine (5-10 minutos).
         Verá el mensaje "RESTAURACION COMPLETADA EXITOSAMENTE".

PASO 6:  Abra el navegador y vaya a http://localhost:8080/
         El sistema debería estar funcionando normalmente.
```

> 💡 **Nota:** El pendrive NO borra los datos históricos. Primero los respalda y luego los restaura.

---

## 3. MÉTODO B: Reinstalación Manual (paso a paso)

Si no se dispone del pendrive de recuperación, siga estos pasos:

### Paso 1 — Verificar qué falló

Antes de reinstalar, intente estas soluciones rápidas:

| Síntoma | Solución rápida |
|---------|----------------|
| La pantalla dice "No se puede conectar" | Ejecute `iniciar_sistema.bat` (está en la carpeta del sistema) |
| La pantalla se ve pero no carga datos | Reinicie PocketBase: abra una ventana de comandos, vaya a la carpeta `pocketbase` y ejecute `pocketbase.exe serve` |
| La computadora se reinició | Simplemente ejecute `iniciar_sistema.bat` |
| Error de "puerto en uso" | Cierre todas las ventanas de comandos negras y vuelva a ejecutar `iniciar_sistema.bat` |

### Paso 2 — Si nada de lo anterior funciona: Reinstalar

#### 2a. Respaldar los datos (MUY IMPORTANTE)

Antes de hacer cualquier cosa, copie esta carpeta a un lugar seguro (escritorio, otro pendrive, etc.):

```
C:\sistema-llaves-fcea\pocketbase\pb_data\
```

Esta carpeta contiene **TODA la base de datos**: historial de llaves, usuarios registrados, autorizaciones, etc.

#### 2b. Obtener el código fuente

El código fuente del sistema está disponible en:
- **GitHub:** https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git
- **Pendrive de respaldo** (si se preparó uno)

Para descargar desde GitHub:
1. Abra una ventana de comandos (cmd)
2. Escriba:
```
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git C:\sistema-llaves-fcea
```

#### 2c. Instalar dependencias

1. Abra una ventana de comandos en la carpeta del sistema
2. Ejecute:
```
npm install
```
3. Espere a que termine (puede tardar 2-5 minutos)

#### 2d. Restaurar la base de datos

Copie la carpeta `pb_data` que respaldó en el paso 2a de vuelta a:
```
C:\sistema-llaves-fcea\pocketbase\pb_data\
```

#### 2e. Iniciar el sistema

Haga doble clic en `iniciar_sistema.bat`

---

## 4. ¿Qué necesita la computadora para funcionar?

| Requisito | Detalle |
|-----------|---------|
| **Sistema operativo** | Windows 10 o Windows 11 |
| **Node.js** | Versión 18 o superior (necesario para el frontend) |
| **Navegador** | Google Chrome (recomendado), Firefox o Edge |
| **Espacio en disco** | Mínimo 500 MB libres |
| **Memoria RAM** | Mínimo 4 GB |
| **Red** | Conexión a la red local de la Facultad (para acceso desde otras PCs) |

### ¿Cómo verificar si Node.js está instalado?

1. Abra una ventana de comandos (cmd)
2. Escriba: `node --version`
3. Si aparece un número (ej: `v18.17.0`), está instalado
4. Si dice "no se reconoce", descárguelo de: https://nodejs.org/

---

## 5. Estructura de archivos importantes

```
C:\sistema-llaves-fcea\
│
├── iniciar_sistema.bat          ← EJECUTAR ESTO para iniciar el sistema
│
├── pocketbase\
│   ├── pocketbase.exe           ← Motor de base de datos
│   ├── pb_data\                 ← ⭐ BASE DE DATOS (NO BORRAR NUNCA)
│   │   └── data.db              ← Archivo principal de datos
│   ├── pb_migrations\           ← Estructura de la base de datos
│   └── maintenance\             ← Scripts de mantenimiento automático
│
├── src\                         ← Código fuente de la aplicación
├── scripts\                     ← Scripts auxiliares
├── docs\                        ← Documentación (este archivo)
└── package.json                 ← Configuración del proyecto
```

> ⭐ **La carpeta más importante es `pocketbase\pb_data\`**. Mientras esta carpeta esté intacta, todos los datos históricos se conservan sin importar qué pase con el resto del sistema.

---

## 6. Contactos de emergencia

| Rol | Acción |
|-----|--------|
| **Jefe de Vigilancia** | Ejecutar `iniciar_sistema.bat` o usar el pendrive de recuperación |
| **Personal de Sistemas** | Reinstalación manual completa |
| **Desarrollador** | Contactar a través del repositorio en GitHub |

---

## 7. Diagrama de decisión ante fallas

```
¿El sistema no funciona?
    │
    ├── ¿La computadora está encendida?
    │       NO → Encenderla y ejecutar iniciar_sistema.bat
    │       SÍ ↓
    │
    ├── ¿Aparece la página pero sin datos?
    │       SÍ → Reiniciar PocketBase (ver Paso 1 del Método B)
    │       NO ↓
    │
    ├── ¿Aparece "No se puede conectar"?
    │       SÍ → Ejecutar iniciar_sistema.bat
    │       NO ↓
    │
    ├── ¿Nada funciona?
    │       → Usar el PENDRIVE DE RECUPERACIÓN (Método A)
    │       → Si no hay pendrive: Método B (reinstalación manual)
    │
    └── ¿Sigue sin funcionar después de reinstalar?
            → Llamar a Personal de Sistemas
```

---

*Documento preparado para presentación a las autoridades de FCEA.*
