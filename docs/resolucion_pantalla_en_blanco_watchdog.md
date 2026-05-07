# Resolución: Pantalla en Blanco al Reiniciar PC — Error Crítico del Watchdog

## Fecha
Mayo 2026

## Síntoma Reportado

Al encender la PC:
1. Chrome tenía abiertas las pestañas de Terminal y Monitor (funcionando correctamente)
2. Al minuto, un script abría Edge con `localhost:8080/monitor` → quedaba en **blanco**
3. Al hacer refresh en Chrome, las pestañas también quedaban en **blanco**
4. El sistema mostraba "error crítico" y dejaba de funcionar

## Causa Raíz Identificada

El problema estaba en **`scripts/watchdog_completo.ps1`**, función `Start-Frontend`:

```powershell
# CÓDIGO PROBLEMÁTICO (antes del fix):
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
```

Esta línea **mataba TODOS los procesos node.exe del sistema** cada vez que el watchdog
intentaba "reiniciar" el frontend, incluyendo el proceso que ya estaba sirviendo
correctamente el sitio en el puerto 8080.

### Secuencia del problema:
1. PC enciende → tarea `SistemaLlavesFCEA` se ejecuta con delay de **10 segundos**
2. El watchdog arranca y verifica si el frontend está corriendo
3. Como Vite tarda ~20-30 segundos en arrancar, el watchdog lo detecta como "caído"
4. El watchdog mata todos los node.exe y relanza `npm run dev`
5. El navegador (Chrome/Edge) que ya tenía la página abierta pierde la conexión HMR
6. La página queda en **blanco** porque el servidor Vite se reinició
7. Al hacer refresh, el navegador intenta reconectar pero el servidor aún está arrancando

## Soluciones Implementadas

### 1. Watchdog corregido (`scripts/watchdog_completo.ps1`)

**Cambio:** La función `Start-Frontend` ahora verifica primero si el puerto 8080
está respondiendo ANTES de matar cualquier proceso node.exe:

```powershell
# CÓDIGO CORREGIDO:
$port8080Check = netstat -ano 2>$null | Select-String ":8080" | Select-String "LISTENING"
if ($port8080Check) {
    Write-Log "Puerto 8080 ya está en uso, no se reiniciará el frontend" "WARNING"
    return $true  # No hace nada si el puerto ya responde
}
# Solo mata node.exe si el puerto 8080 realmente NO está disponible
```

**Resultado:** El watchdog ya NO mata el frontend si está funcionando correctamente.

### 2. Auto-reload en el frontend (`src/lib/cors-fix.js`)

Se agregó la función `setupAutoReload()` que:
- Verifica cada 5 segundos si el servidor Vite responde
- Si el servidor estuvo caído y volvió, **recarga la página automáticamente**
- Detecta si el `div#root` quedó vacío y recarga la página

```javascript
// Activo solo en modo desarrollo (puerto 8080)
// Recarga automáticamente cuando el servidor se recupera
```

**Resultado:** Si por alguna razón el servidor se reinicia, el navegador se recupera
solo sin intervención manual.

### 3. `iniciar_sistema.bat` mejorado

**Cambios:**
- Espera **20 segundos** + verifica activamente que el puerto 8080 esté escuchando
- Abre **Google Chrome** específicamente (no Edge) con ambas pestañas:
  - `http://localhost:8080/terminal`
  - `http://localhost:8080/monitor`
- Si Chrome no está instalado, usa el navegador predeterminado

```batch
:check_port
netstat -ano | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
    timeout /t 5 /nobreak >nul
    goto check_port
)
# Solo abre el navegador cuando el puerto está activo
```

### 4. Tarea programada con delay de 30 segundos

La tarea `SistemaLlavesFCEA` en el Programador de Tareas de Windows fue actualizada
para esperar **30 segundos** después del inicio de sesión (antes eran 10 segundos).

Esto da tiempo suficiente para que Windows cargue completamente antes de iniciar
el sistema.

**Para aplicar este cambio en una instalación nueva o recuperada:**
```
Ejecutar como administrador: ACTUALIZAR_TAREA_INICIO.bat
```

## Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `scripts/watchdog_completo.ps1` | No mata node.exe si puerto 8080 responde |
| `src/lib/cors-fix.js` | Agregado auto-reload cuando servidor se recupera |
| `iniciar_sistema.bat` | Espera puerto 8080 activo, abre Chrome específicamente |
| `scripts/configurar_inicio_automatico_DEFINITIVO.ps1` | Delay 30s en tarea |
| `scripts/preparar_pendrive_instalador.bat` | Copia nuevos archivos al pendrive |
| `scripts/preparar_pendrive_recuperacion.bat` | Copia nuevos archivos al pendrive |

## Archivos Nuevos Creados

| Archivo | Propósito |
|---------|-----------|
| `actualizar_tarea_30s.ps1` | Script PS1 para actualizar la tarea programada |
| `ACTUALIZAR_TAREA_INICIO.bat` | BAT con elevación de admin para aplicar el fix de la tarea |

## Verificación del Fix

Después de aplicar los cambios, al reiniciar la PC:

1. ✅ Windows carga → espera 30 segundos
2. ✅ `iniciar_sistema.bat` arranca PocketBase y el watchdog
3. ✅ El watchdog NO mata node.exe si el puerto 8080 ya responde
4. ✅ `iniciar_sistema.bat` espera que el puerto 8080 esté activo
5. ✅ Chrome se abre con Terminal y Monitor (no Edge)
6. ✅ Si por alguna razón el servidor se reinicia, el navegador recarga solo

## Cómo Aplicar en Instalación Nueva (desde pendrive)

Los pendrives de instalación y recuperación ya incluyen todos los archivos corregidos.
Después de instalar/recuperar el sistema, ejecutar como administrador:

```
ACTUALIZAR_TAREA_INICIO.bat
```

Esto actualiza la tarea programada con el delay de 30 segundos correcto.

## Notas Técnicas

- El watchdog verifica el sistema cada **2 minutos** (120 segundos)
- Vite tarda entre 15-30 segundos en arrancar completamente
- El delay de 30 segundos en la tarea es suficiente para que Windows cargue
  pero el watchdog aún puede necesitar esperar el primer ciclo de 2 minutos
- El auto-reload del frontend tiene un timeout de 3 segundos para detectar
  si el servidor no responde

---
*Documentado por: Sistema de Gestión de Llaves FCEA — Mayo 2026*
