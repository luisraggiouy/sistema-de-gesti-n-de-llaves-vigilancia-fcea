# SOLUCIÓN: INICIO AUTOMÁTICO DEL SISTEMA

## 🚨 PROBLEMA IDENTIFICADO

El sistema NO se iniciaba automáticamente al arrancar Windows, requiriendo intervención manual cada vez que la computadora se reiniciaba o se apagaba. Esto es **CRÍTICO** para un entorno de producción.

## ✅ SOLUCIÓN IMPLEMENTADA

Se ha implementado un sistema de **INICIO AUTOMÁTICO** con las siguientes características:

### 1. **Watchdog Completo** (`scripts/watchdog_completo.ps1`)
- Monitorea **PocketBase** (backend) y **Frontend** (Vite)
- Reinicia automáticamente cualquier servicio que se caiga
- Verificación cada 2 minutos
- Se ejecuta en segundo plano de forma invisible

### 2. **Tarea Programada de Windows**
- Se ejecuta automáticamente al iniciar Windows
- Retraso de 30 segundos para permitir que el sistema operativo se estabilice
- Se ejecuta con privilegios SYSTEM (máximos permisos)
- Configurada para reintentar 3 veces si falla

## 📋 INSTRUCCIONES DE CONFIGURACIÓN

### **PASO 1: Ejecutar el Configurador (UNA SOLA VEZ)**

1. Localice el archivo en la raíz del proyecto:
   ```
   CONFIGURAR_INICIO_AUTOMATICO.bat
   ```

2. **Haga clic derecho** sobre el archivo

3. Seleccione **"Ejecutar como administrador"**

4. Acepte el UAC (Control de Cuentas de Usuario) cuando aparezca

5. Espere a que aparezca el mensaje de confirmación

### **PASO 2: Verificar la Configuración**

Abra PowerShell como Administrador y ejecute:

```powershell
Get-ScheduledTask -TaskName "SistemaLlavesFCEA_AutoInicio"
```

Debería ver la tarea con estado "Ready".

### **PASO 3: Probar el Inicio Automático**

**Opción A: Iniciar la tarea manualmente**
```powershell
Start-ScheduledTask -TaskName "SistemaLlavesFCEA_AutoInicio"
```

**Opción B: Reiniciar la computadora**
- El sistema se iniciará automáticamente 30 segundos después del arranque
- Abra el navegador en `http://localhost:8080` para verificar

## 🔧 CONFIGURACIÓN TÉCNICA

### Detalles de la Tarea Programada

| Parámetro | Valor |
|-----------|-------|
| **Nombre** | SistemaLlavesFCEA_AutoInicio |
| **Trigger** | Al iniciar Windows |
| **Retraso** | 30 segundos |
| **Usuario** | SYSTEM |
| **Privilegios** | Máximos (RunLevel Highest) |
| **Reintentos** | 3 veces (intervalo de 1 minuto) |
| **Duración** | Sin límite (365 días) |
| **Batería** | Permitido iniciar y continuar |

### Script Ejecutado

La tarea ejecuta:
```powershell
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\scripts\watchdog_completo.ps1"
```

## 🛡️ PROTECCIÓN AUTOMÁTICA

Una vez configurado, el sistema tiene **TRIPLE PROTECCIÓN**:

1. **Inicio Automático**: Se inicia al arrancar Windows
2. **Watchdog PocketBase**: Reinicia el backend si se cae
3. **Watchdog Frontend**: Reinicia el frontend si se cae

## 📊 MONITOREO

### Ver el Log del Watchdog

```powershell
Get-Content "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\scripts\watchdog_completo.log" -Tail 50
```

### Ver Estado de los Servicios

```powershell
# Ver PocketBase
Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue

# Ver Frontend (Node)
Get-Process -Name "node" -ErrorAction SilentlyContinue

# Ver puertos en uso
netstat -ano | findstr ":8080"
netstat -ano | findstr ":8090"
```

## 🚀 COMANDOS ÚTILES

### Detener el Sistema
```powershell
# Detener PocketBase
Stop-Process -Name "pocketbase" -Force

# Detener Frontend
Stop-Process -Name "node" -Force

# Detener Watchdog
Stop-Process -Name "powershell" -Force
```

### Reiniciar el Sistema Manualmente
```batch
c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\iniciar_sistema.bat
```

### Deshabilitar Inicio Automático
```powershell
Disable-ScheduledTask -TaskName "SistemaLlavesFCEA_AutoInicio"
```

### Habilitar Inicio Automático
```powershell
Enable-ScheduledTask -TaskName "SistemaLlavesFCEA_AutoInicio"
```

### Eliminar Inicio Automático
```powershell
Unregister-ScheduledTask -TaskName "SistemaLlavesFCEA_AutoInicio" -Confirm:$false
```

## ⚠️ IMPORTANTE PARA PRODUCCIÓN

### ✅ LO QUE DEBE HACER

1. **Ejecutar el configurador UNA VEZ** después de instalar el sistema
2. **Verificar** que la tarea se creó correctamente
3. **Probar** reiniciando la computadora
4. **Monitorear** el log durante los primeros días

### ❌ LO QUE NO DEBE HACER

1. **NO** cerrar manualmente las ventanas de PowerShell del watchdog
2. **NO** deshabilitar la tarea programada
3. **NO** modificar los scripts sin respaldo
4. **NO** ejecutar múltiples instancias del watchdog

## 🔍 SOLUCIÓN DE PROBLEMAS

### Problema: La tarea no se creó

**Solución:**
1. Asegúrese de ejecutar como Administrador
2. Acepte el UAC cuando aparezca
3. Verifique que no haya errores en el log

### Problema: El sistema no inicia al arrancar

**Solución:**
1. Verifique que la tarea esté habilitada:
   ```powershell
   Get-ScheduledTask -TaskName "SistemaLlavesFCEA_AutoInicio" | Select-Object State
   ```
2. Revise el log del watchdog
3. Inicie la tarea manualmente para probar

### Problema: El watchdog no reinicia los servicios

**Solución:**
1. Verifique que el watchdog esté corriendo:
   ```powershell
   Get-Process | Where-Object {$_.CommandLine -like '*watchdog_completo*'}
   ```
2. Revise el log para ver errores
3. Reinicie el watchdog manualmente

## 📞 SOPORTE

Si tiene problemas:

1. Revise el log del watchdog
2. Verifique el estado de la tarea programada
3. Consulte este documento
4. Contacte al equipo de soporte técnico

## 📝 HISTORIAL DE CAMBIOS

- **2026-05-03**: Implementación inicial del sistema de inicio automático
- Creación de watchdog completo
- Configuración de tarea programada
- Documentación completa

---

**NOTA CRÍTICA**: Este sistema es **ESENCIAL** para el funcionamiento en producción. NO lo deshabilite sin una razón válida y un plan de respaldo.
