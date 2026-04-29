# Configuración del Mantenimiento Automatizado

Este documento proporciona instrucciones para configurar el script de mantenimiento automatizado que se ejecutará todos los domingos a las 8:00 AM, como se ha solicitado. El script realiza tareas esenciales como copias de seguridad, verificación de integridad de la base de datos y optimización del sistema.

## Estructura del Sistema de Mantenimiento

El sistema de mantenimiento consiste en:

1. **Script PowerShell** (`pocketbase/maintenance/system_maintenance.ps1`) - Realiza tareas de mantenimiento con diferentes frecuencias (semanal, mensual, trimestral, anual)
2. **Directorio de respaldos** (`pocketbase/pb_backups`) - Almacena copias de seguridad de la base de datos
3. **Directorio de logs** (`pocketbase/maintenance/logs`) - Almacena registros de todas las operaciones de mantenimiento

## Configuración de la Tarea Programada en Windows

Siga estos pasos para configurar la ejecución automática del script cada domingo a las 8:00 AM:

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

Para asegurarse de que la tarea se ejecutará correctamente:

1. En el Programador de tareas, localice la tarea "Mantenimiento Sistema Llaves FCEA" en la lista
2. Haga clic derecho sobre ella y seleccione **Ejecutar**
3. Verifique el archivo de registro generado en `pocketbase/maintenance/logs/maintenance.log`
4. Confirme que no haya errores y que todas las tareas se hayan completado correctamente

## Comprobación regular

Aunque el sistema está automatizado, se recomienda comprobar periódicamente:

1. El archivo de registro (`maintenance.log`) en busca de posibles advertencias o errores
2. El directorio de copias de seguridad (`pb_backups`) para asegurarse de que los respaldos se estén generando correctamente
3. El espacio libre en disco para asegurarse de que hay espacio suficiente para futuras copias de seguridad 

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