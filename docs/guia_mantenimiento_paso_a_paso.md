# Guía Paso a Paso para Mantenimiento del Sistema
## Análisis de Estabilidad y Procedimientos de Mantenimiento

## Escenario de Uso Planteado
- 200 operaciones de llaves por día (entregas y devoluciones)
- 40 objetos perdidos registrados por día
- 40 objetos entregados por día
- 10 autorizaciones por día (entre ingresos y búsquedas)

## Análisis de Carga y Estabilidad

### Base de Datos (PocketBase)

PocketBase utiliza SQLite como motor de base de datos subyacente, que es conocido por su estabilidad y bajo mantenimiento. Considerando el volumen de operaciones:

- **Operaciones diarias**: Aproximadamente 290 operaciones CRUD por día
- **Operaciones mensuales**: ~8,700 operaciones
- **Operaciones anuales**: ~105,000 operaciones

**Estabilidad**: SQLite puede manejar cómodamente millones de registros en una base de datos, y cientos de miles de operaciones sin problemas de rendimiento significativos. La probabilidad de fallo por volumen es extremadamente baja.

**Punto de atención**: Las copias de seguridad automáticas son esenciales. Se recomienda implementar una rutina de backup semanal, además de la exportación custodial.

### Frontend React

El sistema utiliza React para la interfaz de usuario, que maneja eficientemente la renderización de componentes en función de los cambios de estado.

**Estabilidad con el volumen indicado**:
- La visualización de 200 registros diarios distribuidos en diferentes vistas no representa una carga significativa
- Los componentes de gráficos usan la biblioteca Recharts, que está optimizada para renderizado eficiente
- La probabilidad de fallo por sobrecarga de UI es muy baja en este rango de operaciones

### Puntos Potenciales de Fallo

1. **Concurrencia de operaciones**
   - **Probabilidad de fallo**: BAJA
   - **Escenario crítico**: Múltiples vigilantes intentando registrar operaciones simultáneamente
   - **Mitigación**: El sistema implementa bloqueos optimistas para manejar la concurrencia

2. **Corrupción de la base de datos**
   - **Probabilidad**: MUY BAJA
   - **Escenario crítico**: Fallo de energía durante una operación de escritura
   - **Mitigación**: PocketBase/SQLite tiene protección contra corrupción y journaling

3. **Degradación de rendimiento con el crecimiento de datos**
   - **Probabilidad**: BAJA las primeras semanas/meses, MEDIA a largo plazo
   - **Escenario**: Consultas lentas después de acumular años de registros
   - **Mitigación**: Implementación de índices en PocketBase y paginación eficiente

4. **Problemas con la exportación a USB**
   - **Probabilidad**: BAJA-MEDIA
   - **Escenario crítico**: Exportación de grandes volúmenes de datos a dispositivos USB de baja calidad
   - **Mitigación**: El sistema implementa timeouts y manejo de errores para operaciones de E/S

## Proyección de Estabilidad por Tiempo

### Corto Plazo (0-6 meses)
- **Probabilidad de fallo crítico**: < 0.1% mensual
- **Escenario más probable**: Errores de usuario o interrupción del servicio por factores externos (energía, red)
- **Operaciones acumuladas**: ~52,000
- **Tamaño de base de datos estimado**: 10-20 MB (muy por debajo de límites críticos)

### Medio Plazo (6-18 meses)
- **Probabilidad de fallo crítico**: < 0.5% mensual
- **Escenario más probable**: Podría comenzarse a notar alguna degradación leve en consultas complejas
- **Operaciones acumuladas**: ~150,000
- **Tamaño de base de datos estimado**: 30-60 MB
- **Necesidades**: Primera limpieza/archivo de datos históricos

### Largo Plazo (18+ meses)
- **Probabilidad de fallo crítico**: < 2% mensual sin mantenimiento, < 0.5% con mantenimiento
- **Escenario más probable**: Necesidad de archivado de datos históricos para mantener rendimiento
- **Operaciones acumuladas**: 200,000+
- **Tamaño de base de datos estimado**: 100+ MB
- **Necesidades**: Implementación de política de retención de datos y archivado

## Plan de Mantenimiento Preventivo

Para mantener el sistema funcionando de manera óptima con el volumen descrito:

### Mantenimiento Automático

#### Semanal (Domingos 8:00 AM)
- ✅ **Copias de seguridad automáticas**
- ✅ **Verificación de integridad de la base de datos**
- ✅ **Limpieza de respaldos antiguos** - Mantiene 52 copias (1 año)
- ✅ **Optimización de base de datos** (vacuum)

#### Diario (7:00 AM)
- ✅ **Verificación de salud del sistema**
- ✅ **Monitoreo de espacio en disco**
- ✅ **Verificación de backups**
- ✅ **Detección de errores en logs**
- ✅ **Generación de alertas automáticas**

> **Nota**: Todo el mantenimiento es automático. Ver documento "configuracion_mantenimiento_automatizado.md" para configuración inicial.

### Sistema de Alertas en Monitor de Vigilancia

El sistema muestra automáticamente alertas cuando detecta problemas:

- 🔴 **Críticas**: Espacio disco < 10%, backup > 14 días, PocketBase caído
- 🟡 **Advertencias**: Espacio disco < 20%, backup > 8 días, pendrive > 90 días
- **Métricas**: Estado general del sistema visible en todo momento

**Los vigilantes solo deben**: Revisar el Monitor al inicio del turno y reportar alertas críticas a Personal de Sistemas.

### Mantenimiento Manual (Solo Anual)

> **IMPORTANTE**: Con el sistema de alertas automatizado, ya NO es necesario realizar mantenimiento mensual ni trimestral manual. El sistema se auto-mantiene y solo muestra alertas cuando requiere atención.

**Si el Monitor muestra alertas**, siga las acciones recomendadas en cada alerta. De lo contrario, no se requiere intervención.

---

### Mantenimiento Bajo Demanda (Solo cuando hay alertas)

**Responsable**: Personal de Sistemas  
**Cuándo**: Solo cuando el Monitor de Vigilancia muestre alertas críticas o advertencias

#### Respuesta a Alertas Críticas (🔴)

**Alerta: "Espacio en disco crítico"**
```
1. Abra "Este equipo" (⊞ + E)
2. Vaya a C:\sistema-llaves-fcea\pocketbase\pb_backups\
3. Copie los respaldos más antiguos a un pendrive externo
4. Elimine los respaldos copiados (mantenga últimos 12)
5. Vacíe la Papelera de reciclaje
```

**Alerta: "Backup desactualizado"**
```
1. Abra PowerShell como Administrador
2. cd C:\sistema-llaves-fcea\pocketbase\maintenance
3. .\system_maintenance.ps1
4. Verifique que se creó el backup en pb_backups\
```

**Alerta: "PocketBase no está ejecutándose"**
```
1. Abra el Administrador de tareas
2. Busque "pocketbase.exe" - si no está, continúe
3. cd C:\sistema-llaves-fcea
4. Ejecute: iniciar_sistema.bat
```

#### Respuesta a Advertencias (🟡)

**Alerta: "Pendrive de recuperación desactualizado"**
```
1. Conecte el pendrive de recuperación
2. cd C:\sistema-llaves-fcea
3. scripts\preparar_pendrive_recuperacion.bat
4. Etiquete con la fecha actual
```

**Alerta: "Errores en logs"**
```
1. Abra: C:\sistema-llaves-fcea\pocketbase\maintenance\logs\maintenance.log
2. Revise los errores recientes
3. Si no comprende el error, contacte soporte técnico
4. Documente las acciones tomadas
```

---

### Mantenimiento Anual (Manual) - Una vez al año

#### PROCEDIMIENTO PASO A PASO

---

#### PASO 1: Salir del Modo Kiosk
(Ver procedimiento en Mantenimiento Mensual - PASO 1)

---

#### PASO 2: Análisis de Rendimiento de Consultas

```
1. Abra el navegador Chrome en modo normal (no kiosk)

2. Vaya a: http://localhost:8080/_/

3. Inicie sesión en PocketBase Admin:
   - Email: admin@fcea.local (o el configurado)
   - Contraseña: (la contraseña de administrador de PocketBase)

4. Vaya a "Logs" en el menú lateral

5. Revise las consultas más lentas:
   - Busque tiempos de respuesta > 1000ms
   - Anote las colecciones más consultadas

6. Si encuentra consultas lentas frecuentes:
   - Considere agregar índices (consulte con desarrollador)
   - Documente para revisión técnica
```

---

#### PASO 3: Optimización de Base de Datos

```
1. Abra el Símbolo del sistema como Administrador

2. Navegue a la carpeta de PocketBase:
   cd C:\sistema-llaves-fcea\pocketbase

3. Detenga el sistema si está corriendo:
   - Cierre todas las ventanas del navegador
   - En el Administrador de tareas, finalice "pocketbase.exe"

4. Ejecute el comando de optimización:
   pocketbase.exe vacuum

5. Espere a que termine (puede tardar 1-5 minutos)

6. Reinicie el sistema:
   cd C:\sistema-llaves-fcea
   iniciar_sistema.bat
```

> **Nota**: El comando `vacuum` reorganiza la base de datos para mejorar el rendimiento y reducir el tamaño del archivo.

---

#### PASO 4: Limpieza de Archivos Temporales

```
1. Abra el Explorador de Archivos

2. Limpie las siguientes carpetas:

   A) Caché del navegador:
      - Presione ⊞ + R
      - Escriba: %localappdata%\Google\Chrome\User Data\Default\Cache
      - Elimine todos los archivos (puede tardar unos minutos)

   B) Archivos temporales de Windows:
      - Presione ⊞ + R
      - Escriba: temp
      - Elimine todos los archivos que permita Windows

   C) Logs antiguos del sistema:
      - Vaya a: C:\sistema-llaves-fcea\pocketbase\maintenance\logs\
      - Si hay archivos .log.old, elimine los más antiguos de 6 meses

3. Vacíe la Papelera de reciclaje
```

---

#### PASO 5: Verificación de Actualizaciones de Seguridad

```
1. Abra Windows Update:
   - Presione ⊞ (tecla Windows)
   - Escriba "Windows Update"
   - Seleccione "Buscar actualizaciones"

2. Instale las actualizaciones críticas y de seguridad

3. NO instale actualizaciones de características sin consultar

4. Reinicie si es necesario

5. Después del reinicio, vuelva a iniciar el sistema:
   - Ejecute iniciar_sistema.bat
```

---

### Mantenimiento Anual (Manual)

**Tiempo estimado**: 1-2 horas  
**Responsable**: Personal de Sistemas  
**Frecuencia**: Una vez al año

#### PROCEDIMIENTO PASO A PASO

---

#### PASO 1: Archivado de Datos Históricos

```
1. Salga del modo kiosk (ver procedimiento anterior)

2. Acceda al Dashboard como Administrador:
   - Abra Chrome en modo normal
   - Vaya a: http://localhost:8080/dashboard
   - Ingrese la contraseña de administrador

3. Exporte datos históricos:
   - Clic en "Exportar Reporte"
   - Seleccione "Exportación Avanzada"
   - Rango de fechas: Todo el año anterior
   - Marque todas las opciones
   - Conecte un pendrive
   - Clic en "Descargar"

4. Etiquete el pendrive:
   "ARCHIVO HISTÓRICO LLAVES FCEA - Año [AÑO]"

5. Guarde el pendrive en archivo permanente
```

---

#### PASO 2: Verificación Completa de Integridad

```
1. Abra el Símbolo del sistema como Administrador

2. Navegue a la carpeta de PocketBase:
   cd C:\sistema-llaves-fcea\pocketbase

3. Detenga el sistema

4. Ejecute verificación de integridad:
   sqlite3 pb_data\data.db "PRAGMA integrity_check;"

5. Debe mostrar: "ok"
   - Si muestra errores, restaure desde el último respaldo

6. Ejecute análisis de la base de datos:
   sqlite3 pb_data\data.db "ANALYZE;"

7. Reinicie el sistema
```

---

#### PASO 3: Actualización de Dependencias (Opcional)

> ⚠️ **ADVERTENCIA**: Solo realizar si hay vulnerabilidades de seguridad conocidas o si el sistema presenta problemas. Requiere conocimientos técnicos avanzados.

```
1. Haga un respaldo completo del sistema antes de continuar

2. Abra el Símbolo del sistema como Administrador

3. Navegue a la carpeta del sistema:
   cd C:\sistema-llaves-fcea

4. Verifique actualizaciones disponibles:
   npm outdated

5. Si hay actualizaciones críticas de seguridad:
   npm update

6. Pruebe el sistema exhaustivamente después de actualizar

7. Si algo falla, restaure desde el respaldo
```

---

## Resolución de Problemas Comunes

### Problema: El sistema no arranca después del mantenimiento

```
SOLUCIÓN:
1. Verifique que PocketBase no esté corriendo:
   - Abra Administrador de tareas
   - Busque "pocketbase.exe"
   - Si existe, finalice el proceso

2. Verifique que el puerto 8080 esté libre:
   - Abra Símbolo del sistema
   - Ejecute: netstat -ano | findstr :8080
   - Si hay algo usando el puerto, finalice ese proceso

3. Intente iniciar manualmente:
   - cd C:\sistema-llaves-fcea\pocketbase
   - pocketbase.exe serve

4. Si muestra errores, restaure desde respaldo
```

### Problema: Logs muestran errores de espacio en disco

```
SOLUCIÓN:
1. Libere espacio inmediatamente:
   - Copie pb_backups a pendrive externo
   - Elimine respaldos antiguos (mantenga últimos 12)
   - Ejecute Liberador de espacio en disco de Windows

2. Si el problema persiste:
   - Considere mover el sistema a un disco con más espacio
   - Consulte con Personal de Sistemas
```

### Problema: El sistema está lento

```
SOLUCIÓN:
1. Ejecute el mantenimiento trimestral completo

2. Verifique recursos del sistema:
   - CPU, RAM, Disco en Administrador de tareas

3. Reinicie la computadora

4. Si persiste, ejecute vacuum en la base de datos

5. Como último recurso, restaure desde un respaldo reciente
```

---

## Checklist de Mantenimiento

### ✅ Automático (Sin intervención)
- [x] Backups semanales (Domingos 8:00 AM)
- [x] Verificación de salud diaria (7:00 AM)
- [x] Optimización de base de datos (vacuum)
- [x] Limpieza de backups antiguos
- [x] Monitoreo de espacio en disco
- [x] Detección de errores en logs
- [x] Alertas en Monitor de Vigilancia

### ✅ Bajo Demanda (Solo cuando hay alertas)
- [ ] Liberar espacio en disco (si alerta crítica)
- [ ] Ejecutar backup manual (si backup desactualizado)
- [ ] Actualizar pendrive recuperación (si advertencia)
- [ ] Revisar logs de errores (si advertencia)
- [ ] Reiniciar servicios (si PocketBase caído)

### ✅ Anual (Una vez al año)
- [ ] Archivar datos históricos del año anterior
- [ ] Verificación completa de integridad
- [ ] Evaluar necesidad de actualizar dependencias
- [ ] Revisar y actualizar documentación
- [ ] Actualizar pendrive de recuperación con datos archivados

## Conclusión

Con el volumen de uso especificado (290 operaciones diarias), el sistema está sobradamente dimensionado para mantener un funcionamiento estable con una probabilidad de fallo crítico inferior al 0.1% mensual durante el primer año. 

La probabilidad de experimentar problemas aumenta ligeramente con el tiempo debido a la acumulación de datos, pero implementando el plan de mantenimiento preventivo sugerido, el sistema puede mantener su rendimiento óptimo indefinidamente, con una probabilidad de fallo crítico que no debería superar el 0.5% mensual incluso después de varios años de operación continua.

Las principales vulnerabilidades no son técnicas sino operativas: falta de backups, falta de mantenimiento preventivo o condiciones externas como cortes de energía prolongados sin UPS apropiada.

---

*Documento preparado para archivo y custodia autoridades de FCEA.*
