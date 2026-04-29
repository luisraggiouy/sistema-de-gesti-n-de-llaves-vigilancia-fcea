# Configuración para Producción - Sistema de Gestión de Llaves FCEA

## Resumen de la Configuración

El sistema está diseñado para funcionar con **3 dispositivos** en producción:

1. **1 Monitor de Vigilancia** (PC/laptop con pantalla grande)
2. **2 Terminales de Usuario** (tablets/pantallas táctiles)

## Configuración por Dispositivo

### 1. Monitor de Vigilancia

**Archivo `.env`:**
```bash
VITE_DEVICE_TYPE=monitor
VITE_PRODUCTION_MODE=true
VITE_DEVICE_ID=monitor-vigilancia
VITE_POCKETBASE_URL=http://localhost:8090
```

**Características:**
- Siempre abre en `/monitor` (Monitor de Vigilancia)
- No muestra botones de navegación
- Pantalla grande (recomendado: 1920x1080 o superior)
- Usado por los vigilantes para gestionar solicitudes

### 2. Terminal de Usuario 1

**Archivo `.env`:**
```bash
VITE_DEVICE_TYPE=terminal
VITE_PRODUCTION_MODE=true
VITE_DEVICE_ID=terminal-1
VITE_POCKETBASE_URL=http://localhost:8090
```

**Características:**
- Siempre abre en `/` (Terminal de Usuario)
- No muestra botones de navegación
- Pantalla táctil recomendada
- Ubicación sugerida: Entrada principal

### 3. Terminal de Usuario 2

**Archivo `.env`:**
```bash
VITE_DEVICE_TYPE=terminal
VITE_PRODUCTION_MODE=true
VITE_DEVICE_ID=terminal-2
VITE_POCKETBASE_URL=http://localhost:8090
```

**Características:**
- Siempre abre en `/` (Terminal de Usuario)
- No muestra botones de navegación
- Pantalla táctil recomendada
- Ubicación sugerida: Área de estudiantes/docentes

## Pasos para Configurar en Producción

### 1. Preparar el Servidor PocketBase

```bash
# En el servidor central (puede ser el mismo PC del monitor de vigilancia)
cd pocketbase
./pocketbase serve --http=0.0.0.0:8090
```

### 2. Configurar cada Dispositivo

Para cada dispositivo:

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git
   cd sistema-de-gesti-n-de-llaves-vigilancia-fcea
   ```

2. **Crear archivo `.env` específico:**
   ```bash
   # Copiar el ejemplo y editarlo según el dispositivo
   cp .env.example .env
   # Editar .env con la configuración correspondiente
   ```

3. **Instalar dependencias:**
   ```bash
   npm install
   ```

4. **Construir para producción:**
   ```bash
   npm run build
   ```

5. **Servir la aplicación:**
   ```bash
   npm run preview
   # O usar un servidor web como nginx/apache
   ```

### 3. Configuración de Red

**Importante:** Todos los dispositivos deben estar en la misma red y poder acceder al servidor PocketBase.

- **IP del servidor PocketBase:** Anotar la IP del dispositivo donde corre PocketBase
- **Puerto:** 8090 (por defecto)
- **URL completa:** `http://[IP_SERVIDOR]:8090`

Ejemplo: Si el servidor está en `192.168.1.100`:
```bash
VITE_POCKETBASE_URL=http://192.168.1.100:8090
```

## Detección Automática de Dispositivos

El sistema incluye detección automática basada en:

- **Tamaño de pantalla:** Pantallas ≥1920x1080 se consideran monitor de vigilancia
- **Capacidad táctil:** Dispositivos táctiles se consideran terminales
- **Configuración manual:** Variables de entorno tienen prioridad

## Configuraciones Adicionales

### Modo de Desarrollo (para pruebas)

```bash
VITE_DEVICE_TYPE=auto
VITE_PRODUCTION_MODE=false
VITE_DEVICE_ID=dev-device
```

En modo desarrollo:
- Se muestran botones de navegación
- Se puede cambiar entre interfaces
- Útil para pruebas y configuración

### Variables de Entorno Completas

```bash
# Tipo de dispositivo
VITE_DEVICE_TYPE=monitor|terminal|auto

# Modo de producción
VITE_PRODUCTION_MODE=true|false

# ID único del dispositivo
VITE_DEVICE_ID=identificador-unico

# URL del servidor PocketBase
VITE_POCKETBASE_URL=http://IP:8090

# Intervalo de verificación de red (ms)
VITE_NETWORK_CHECK_INTERVAL=3000
```

## Solución de Problemas

### Problema: Dispositivo no se conecta a PocketBase

**Solución:**
1. Verificar que PocketBase esté ejecutándose
2. Comprobar la IP y puerto en `.env`
3. Verificar conectividad de red: `ping [IP_SERVIDOR]`
4. Revisar firewall del servidor

### Problema: Interfaz incorrecta se muestra

**Solución:**
1. Verificar `VITE_DEVICE_TYPE` en `.env`
2. Limpiar caché del navegador
3. Reconstruir la aplicación: `npm run build`

### Problema: Botones de navegación aparecen en producción

**Solución:**
1. Verificar `VITE_PRODUCTION_MODE=true` en `.env`
2. Reconstruir la aplicación
3. Reiniciar el servidor web

## Mantenimiento

### Actualizaciones del Sistema

1. **Hacer backup de la base de datos:**
   ```bash
   cp -r pocketbase/pb_data pocketbase/pb_data_backup_$(date +%Y%m%d)
   ```

2. **Actualizar código:**
   ```bash
   git pull origin main
   npm install
   npm run build
   ```

3. **Reiniciar servicios:**
   ```bash
   # Reiniciar PocketBase y servidores web
   ```

### Monitoreo

- **Logs de PocketBase:** Revisar regularmente para errores
- **Conectividad:** Verificar que todos los dispositivos se conecten
- **Rendimiento:** Monitorear uso de CPU/memoria en el servidor

## Arquitectura de Red Recomendada

```
[Router/Switch Principal]
         |
    [Red Local]
         |
    ┌────┴────┬────────────┬────────────┐
    │         │            │            │
[Monitor]  [Terminal1]  [Terminal2]  [Servidor]
Vigilancia    Entrada    Estudiantes  PocketBase
```

## Plan de Contingencias y Recuperación

### 1. Interrupción de Energía / Mini-PC Desenchufada

**¿Qué pasa?**
- Los terminales pierden conexión con la base de datos
- Aparece mensaje "Sin conexión" en las pantallas
- No se pueden procesar nuevas solicitudes
- Las solicitudes en curso se mantienen en memoria local temporalmente

**Recuperación Automática:**
```bash
# El sistema está configurado para reconectarse automáticamente
# Intervalo de reconexión: cada 3 segundos
VITE_NETWORK_CHECK_INTERVAL=3000
```

**Pasos de Recuperación Manual:**

1. **Verificar la Mini-PC:**
   ```bash
   # Encender la Mini-PC si está apagada
   # Verificar que PocketBase se inicie automáticamente
   cd pocketbase
   ./pocketbase serve --http=0.0.0.0:8090
   ```

2. **Verificar conectividad desde terminales:**
   ```bash
   # Desde cualquier terminal, verificar conexión
   ping [IP_MINI_PC]
   # Ejemplo: ping 192.168.1.100
   ```

3. **Reiniciar servicios si es necesario:**
   ```bash
   # En la Mini-PC
   sudo systemctl restart pocketbase  # Si está configurado como servicio
   # O manualmente:
   cd pocketbase && ./pocketbase serve --http=0.0.0.0:8090
   ```

**Configuración de Auto-inicio (Recomendado):**

Crear servicio systemd en la Mini-PC:
```bash
# Crear archivo /etc/systemd/system/pocketbase.service
[Unit]
Description=PocketBase
After=network.target

[Service]
Type=simple
User=pocketbase
WorkingDirectory=/home/pocketbase/sistema-llaves/pocketbase
ExecStart=/home/pocketbase/sistema-llaves/pocketbase/pocketbase serve --http=0.0.0.0:8090
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# Activar el servicio
sudo systemctl enable pocketbase
sudo systemctl start pocketbase
```

### 2. Falla del Software / Corrupción del Sistema

**Escenarios de Falla:**
- Corrupción de archivos del sistema
- Error en la base de datos
- Problemas de dependencias
- Actualizaciones fallidas

**Plan de Recuperación por Niveles:**

#### Nivel 1: Reinicio Simple
```bash
# 1. Reiniciar servicios
sudo systemctl restart pocketbase

# 2. Limpiar caché del navegador en terminales
# Ctrl+Shift+R en cada terminal

# 3. Verificar logs
journalctl -u pocketbase -f
```

#### Nivel 2: Restauración de Código
```bash
# 1. Ir al directorio del proyecto
cd /ruta/al/sistema-llaves

# 2. Descartar cambios locales
git reset --hard HEAD

# 3. Actualizar desde repositorio
git pull origin main

# 4. Reinstalar dependencias
npm install

# 5. Reconstruir aplicación
npm run build

# 6. Reiniciar servicios
sudo systemctl restart pocketbase
```

#### Nivel 3: Restauración de Base de Datos
```bash
# 1. Detener PocketBase
sudo systemctl stop pocketbase

# 2. Restaurar backup de base de datos
cd pocketbase
cp -r pb_data pb_data_corrupted_$(date +%Y%m%d_%H%M)
cp -r pb_data_backup_[FECHA] pb_data

# 3. Reiniciar PocketBase
sudo systemctl start pocketbase
```

#### Nivel 4: Reinstalación Completa
```bash
# 1. Backup de datos críticos
cp -r pocketbase/pb_data /backup/pb_data_emergency_$(date +%Y%m%d)

# 2. Clonar repositorio fresco
cd /tmp
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git
cd sistema-de-gesti-n-de-llaves-vigilancia-fcea

# 3. Configurar cada dispositivo
# (Seguir pasos de "Configurar cada Dispositivo" de arriba)

# 4. Restaurar datos
cp -r /backup/pb_data_emergency_[FECHA]/* pocketbase/pb_data/
```

### 3. Responsabilidades y Contactos

#### Personal Técnico Responsable

**Nivel 1 - Vigilantes (Problemas Básicos):**
- Verificar que equipos estén encendidos
- Reiniciar terminales si no responden
- Reportar problemas al Nivel 2

**Nivel 2 - Personal TAS/Sistemas (Problemas Intermedios):**
- Reiniciar servicios
- Verificar conectividad de red
- Restaurar desde backups recientes
- Contactar Nivel 3 si es necesario

**Nivel 3 - Soporte Técnico Externo (Problemas Críticos):**
- Reinstalación completa del sistema
- Recuperación de datos complejos
- Actualizaciones mayores del sistema

#### Información de Contacto de Emergencia

```
Nivel 2 - Personal TAS:
- Nombre: [A COMPLETAR]
- Teléfono: [A COMPLETAR]
- Email: [A COMPLETAR]
- Horario: Lunes a Viernes 8:00-17:00

Nivel 3 - Soporte Técnico:
- Empresa/Persona: [A COMPLETAR]
- Teléfono: [A COMPLETAR]
- Email: [A COMPLETAR]
- Horario: 24/7 para emergencias críticas
```

### 4. Procedimientos de Backup Automático

#### Backup Diario Automático
```bash
# Crear script /home/pocketbase/backup_daily.sh
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/daily"
SOURCE_DIR="/home/pocketbase/sistema-llaves/pocketbase/pb_data"

mkdir -p $BACKUP_DIR
cp -r $SOURCE_DIR $BACKUP_DIR/pb_data_$DATE

# Mantener solo últimos 7 días
find $BACKUP_DIR -name "pb_data_*" -mtime +7 -exec rm -rf {} \;
```

```bash
# Añadir a crontab
crontab -e
# Añadir línea:
0 2 * * * /home/pocketbase/backup_daily.sh
```

#### Backup Semanal
```bash
# Crear script /home/pocketbase/backup_weekly.sh
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/weekly"
SOURCE_DIR="/home/pocketbase/sistema-llaves"

mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/sistema_completo_$DATE.tar.gz $SOURCE_DIR

# Mantener solo últimas 4 semanas
find $BACKUP_DIR -name "sistema_completo_*" -mtime +28 -exec rm -f {} \;
```

```bash
# Añadir a crontab
# Ejecutar domingos a las 3 AM
0 3 * * 0 /home/pocketbase/backup_weekly.sh
```

### 5. Monitoreo y Alertas

#### Script de Monitoreo
```bash
# Crear /home/pocketbase/monitor_system.sh
#!/bin/bash
POCKETBASE_URL="http://localhost:8090"
LOG_FILE="/var/log/sistema_llaves_monitor.log"

# Verificar si PocketBase responde
if curl -f -s $POCKETBASE_URL/_/ > /dev/null; then
    echo "$(date): Sistema OK" >> $LOG_FILE
else
    echo "$(date): ERROR - PocketBase no responde" >> $LOG_FILE
    # Intentar reiniciar
    sudo systemctl restart pocketbase
    sleep 10
    if curl -f -s $POCKETBASE_URL/_/ > /dev/null; then
        echo "$(date): Sistema recuperado automáticamente" >> $LOG_FILE
    else
        echo "$(date): CRÍTICO - Sistema no se pudo recuperar" >> $LOG_FILE
        # Aquí se podría enviar email/SMS de alerta
    fi
fi
```

```bash
# Ejecutar cada 5 minutos
crontab -e
# Añadir:
*/5 * * * * /home/pocketbase/monitor_system.sh
```

### 6. Documentos de Referencia Rápida

#### Tarjeta de Referencia para Vigilantes
```
🚨 PROBLEMAS COMUNES - SISTEMA DE LLAVES

❌ "Sin conexión" en pantallas:
1. Verificar que Mini-PC esté encendida
2. Esperar 30 segundos para reconexión automática
3. Si persiste, llamar a TAS: [TELÉFONO]

❌ Terminal no responde:
1. Presionar Ctrl+Shift+R
2. Si no funciona, reiniciar dispositivo
3. Esperar 2 minutos para que cargue

❌ Datos no se guardan:
1. Verificar conexión (esquina superior)
2. No apagar equipos hasta resolver
3. Llamar inmediatamente a TAS: [TELÉFONO]

📞 CONTACTOS DE EMERGENCIA:
- TAS (8-17h): [TELÉFONO]
- Soporte 24/7: [TELÉFONO]
```

## Contacto y Soporte

Para problemas técnicos o consultas sobre la configuración, contactar al equipo de desarrollo del sistema.

**Estructura de Soporte:**
- **Nivel 1:** Vigilantes (problemas básicos)
- **Nivel 2:** Personal TAS (problemas técnicos)
- **Nivel 3:** Soporte externo (emergencias críticas)
