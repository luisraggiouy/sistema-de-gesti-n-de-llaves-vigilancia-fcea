# Configuración del Mantenimiento Automatizado

Este documento proporciona instrucciones para configurar el mantenimiento automatizado del sistema. Incluye:
- **Mantenimiento semanal**: Backups, verificación de integridad (Domingos 8:00 AM)
- **Verificación de salud diaria**: Monitoreo del sistema (Diario 7:00 AM)
- **Alertas en Monitor de Vigilancia**: Notificaciones automáticas de problemas

El sistema realiza tareas esenciales como copias de seguridad, verificación de integridad de la base de datos, optimización y monitoreo de salud.

## Estructura del Sistema de Mantenimiento

El sistema de mantenimiento consiste en:

1. **Script de mantenimiento** (`pocketbase/maintenance/system_maintenance.ps1`) - Realiza backups, verificación de integridad y optimización
2. **Script de verificación de salud** (`pocketbase/maintenance/check_system_health.ps1`) - Monitorea el estado del sistema diariamente
3. **Componente de alertas** (`src/components/monitor/SystemHealthAlerts.tsx`) - Muestra alertas en el Monitor de Vigilancia
4. **Directorio de respaldos** (`pocketbase/pb_backups`) - Almacena copias de seguridad de la base de datos
5. **Directorio de logs** (`pocketbase/maintenance/logs`) - Almacena registros de todas las operaciones
6. **Archivo de estado** (`public/system_health.json`) - Estado de salud del sistema en tiempo real

## Configuración Automática (Recomendada)

### Método Rápido: Script de Configuración Automática

El sistema incluye un script que configura automáticamente todas las tareas programadas en 5 minutos:

1. **Abrir PowerShell como Administrador**:
   - Presione `Win + X`
   - Seleccione "Windows PowerShell (Administrador)" o "Terminal (Administrador)"

2. **Navegar al directorio del sistema**:
   ```powershell
   cd C:\sistema-llaves-fcea
   ```

3. **Ejecutar el script de configuración**:
   ```powershell
   # Activa el watchdog de PocketBase (tarea programada cada 2 minutos)
   .\activar_watchdog_AHORA.ps1
   ```

   > **Nota:** El antiguo script `configurar_mantenimiento_automatico.ps1` fue reemplazado por `activar_watchdog_AHORA.ps1` y por `scripts\watchdog_completo.ps1`, que cubren las mismas funciones (backup + watchdog) y ya no presentan los problemas de sintaxis del original.

4. **El script configurará automáticamente**:
   - ✅ Tarea de mantenimiento semanal (Domingos 8:00 AM)
   - ✅ Tarea de verificación de salud diaria (Diario 7:00 AM)
   - ✅ Ejecutará una prueba para verificar que funciona
   - ✅ Mostrará el resultado en pantalla

5. **¡Listo!** El mantenimiento está configurado y funcionando.

---

## Configuración Manual (Alternativa)

Si prefiere configurar manualmente o el script automático falla, siga estos pasos:

### 1. Preparación previa

Asegúrese de que la estructura de directorios esté lista:

```
pocketbase/
├── maintenance/
│   ├── system_maintenance.ps1
│   └── logs/
└── pb_backups/
```

### 2. Abrir el Programador de tareas de Windows

1. Presione `Win + R` para abrir el cuadro de diálogo Ejecutar
2. Escriba `taskschd.msc` y presione Enter
3. Se abrirá el Programador de tareas de Windows

### 3. Crear una nueva tarea programada

1. En el panel derecho, haga clic en **Crear tarea básica**
2. Asigne un nombre: `Mantenimiento Sistema Llaves FCEA` 
3. Descripción: `Ejecuta tareas de mantenimiento automatizadas todos los domingos a las 8:00 AM`
4. Haga clic en **Siguiente**

### 4. Configurar el desencadenador (trigger)

1. Seleccione **Semanal**
2. Haga clic en **Siguiente**
3. Establezca la hora de inicio: `8:00 AM`
4. En la sección de recurrencia, seleccione **Domingo**
5. Haga clic en **Siguiente**

### 5. Configurar la acción

1. Seleccione **Iniciar un programa**
2. Haga clic en **Siguiente**
3. En **Programa/script**, escriba: `powershell.exe`
4. En **Argumentos**, escriba: `-ExecutionPolicy Bypass -File "[RUTA_COMPLETA]\pocketbase\maintenance\system_maintenance.ps1"` 
   - Reemplace `[RUTA_COMPLETA]` con la ruta completa donde está instalado el sistema
5. En **Iniciar en**, escriba la ruta al directorio `maintenance`: `[RUTA_COMPLETA]\pocketbase\maintenance\`
6. Haga clic en **Siguiente**

### 6. Finalizar la configuración

1. Verifique los detalles en la página de resumen
2. Seleccione **Abrir el diálogo de propiedades para esta tarea cuando haga clic en Finalizar**
3. Haga clic en **Finalizar**

### 7. Ajustes adicionales en las propiedades

En la ventana de propiedades de la tarea:

1. En la pestaña **General**:
   - Seleccione **Ejecutar con los privilegios más altos**
   - Seleccione **Ejecutar tanto si el usuario ha iniciado sesión como si no**
   - Seleccione **Ejecutar con la cuenta de:** y especifique una cuenta con permisos administrativos

2. En la pestaña **Condiciones**:
   - Desactive **Iniciar la tarea solo si el equipo está conectado a la CA**
   - Active **Activar** en la sección "Si la tarea falla, reintentar hasta"
   - Establezca **Reintentar hasta:** `3` veces
   - Establezca **Reintentar cada:** `15 minutos`

3. En la pestaña **Configuración**:
   - Seleccione **Si la tarea está en ejecución, detenerla**
   - Establezca **Si la tarea no se detiene cuando se solicita, forzar su detención**
   - Seleccione **Ejecutar una nueva instancia en paralelo** en caso de una tarea ya en ejecución

4. Haga clic en **Aceptar** para guardar los cambios

## Verificación de la Configuración

### Verificar Tareas Programadas

1. Abra el Programador de tareas de Windows (`taskschd.msc`)
2. Busque las siguientes tareas:
   - **"Mantenimiento Sistema Llaves FCEA"** - Debe ejecutarse domingos a las 8:00 AM
   - **"Verificación Salud Sistema Llaves FCEA"** - Debe ejecutarse diariamente a las 7:00 AM

### Probar Manualmente

Para probar que el sistema funciona:

1. **Ejecutar mantenimiento manualmente**:
   ```powershell
   cd C:\sistema-llaves-fcea\pocketbase\maintenance
   .\system_maintenance.ps1
   ```

2. **Ejecutar verificación de salud**:
   ```powershell
   cd C:\sistema-llaves-fcea\pocketbase\maintenance
   .\check_system_health.ps1
   ```

3. **Verificar logs**:
   - Mantenimiento: `pocketbase/maintenance/logs/maintenance.log`
   - Salud: `pocketbase/maintenance/logs/health_check.log`

4. **Verificar alertas en Monitor**:
   - Abra el Monitor de Vigilancia
   - Si hay problemas, verá alertas en la parte superior
   - Las alertas se actualizan cada 5 minutos automáticamente

## Sistema de Alertas en Monitor de Vigilancia

### Cómo Funciona

1. **Verificación Diaria**: Cada día a las 7:00 AM, el sistema verifica:
   - Espacio en disco disponible
   - Fecha del último backup
   - Tamaño de la base de datos
   - Errores en logs de mantenimiento
   - Estado del servicio PocketBase
   - Actualización del pendrive de recuperación

2. **Generación de Alertas**: Si detecta problemas, genera un archivo JSON con:
   - Nivel de alerta (crítico, advertencia, info)
   - Descripción del problema
   - Acción recomendada
   - Métricas del sistema

3. **Visualización**: El Monitor de Vigilancia lee este archivo cada 5 minutos y muestra:
   - 🔴 **Alertas Críticas**: Requieren acción inmediata
   - 🟡 **Advertencias**: Requieren atención pronto
   - **Métricas**: Estado general del sistema

### Tipos de Alertas

| Alerta | Nivel | Cuándo Aparece | Acción Requerida |
|--------|-------|----------------|------------------|
| Espacio en disco crítico | 🔴 Crítico | < 10% libre | Liberar espacio inmediatamente |
| Espacio en disco bajo | 🟡 Advertencia | < 20% libre | Planificar limpieza |
| Backup desactualizado | 🔴 Crítico | > 14 días | Verificar tarea programada |
| Backup atrasado | 🟡 Advertencia | > 8 días | Revisar configuración |
| Base de datos grande | 🟡 Advertencia | > 500 MB | Considerar archivado |
| Errores en logs | 🟡 Advertencia | Errores recientes | Revisar logs |
| Pendrive desactualizado | 🟡 Advertencia | > 90 días | Actualizar pendrive |
| PocketBase caído | 🔴 Crítico | Servicio no responde | Reiniciar sistema |

## Comprobación Regular

Con el sistema de alertas automatizado, la comprobación manual se reduce al mínimo:

### Vigilantes (Diario)
- Revisar el Monitor de Vigilancia al inicio del turno
- Si hay alertas críticas (🔴), contactar a Personal de Sistemas inmediatamente
- Si hay advertencias (🟡), reportar en el cambio de turno

### Personal de Sistemas (Bajo Demanda)
- Solo actuar cuando el sistema muestre alertas
- Seguir las acciones recomendadas en cada alerta
- Documentar las acciones tomadas

### Mantenimiento Anual (Una vez al año)
- Archivar datos históricos del año anterior
- Verificación completa del sistema
- Actualizar documentación si es necesario

## Solución de problemas comunes

### Problema: La tarea no se ejecuta
- Verifique que PowerShell esté instalado y accesible en el sistema
- Compruebe que la cuenta de usuario tenga permisos adecuados
- Asegúrese de que la política de ejecución de PowerShell permita la ejecución de scripts

### Problema: Error "Access Denied" al ejecutar la tarea
- Asegúrese de que la cuenta que ejecuta la tarea tenga permisos de administrador
- Compruebe los permisos en los directorios de destino (pb_backups y logs)

### Problema: No se generan copias de seguridad
- Verifique que PocketBase esté correctamente instalado y que la ruta a la base de datos sea correcta
- Compruebe el espacio disponible en disco

## Restauración de Copias de Seguridad

En caso de ser necesario, las copias de seguridad pueden restaurarse siguiendo estos pasos:

1. Detenga el servicio de PocketBase
2. Extraiga el archivo zip de respaldo ubicado en el directorio `pb_backups`
3. Reemplace el archivo de base de datos actual (`pb_data/data.db`) con el archivo respaldado
4. Reinicie PocketBase

## Mantenimiento Manual Anual

Aunque muchas tareas están automatizadas, se recomienda realizar un mantenimiento manual anual para:

1. Archivar datos históricos de más de un año
2. Revisar y actualizar dependencias del sistema
3. Realizar una verificación exhaustiva de la integridad del sistema

Para archivado de datos, se puede implementar un script adicional o un proceso manual según las necesidades específicas de retención de datos de la facultad.