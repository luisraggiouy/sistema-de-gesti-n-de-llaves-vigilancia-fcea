# Plan de Actualizaciones y Mantenimiento - Sistema de Gestión de Llaves FCEA

## Componentes que Requieren Actualizaciones

### 1. Dependencias de Software (Crítico - Actualizaciones de Seguridad)

#### Frontend (React/TypeScript)
```json
// Dependencias principales que requieren actualizaciones regulares:
{
  "react": "^18.x.x",           // Actualizaciones de seguridad cada 3-6 meses
  "typescript": "^5.x.x",       // Actualizaciones menores cada 2-3 meses
  "vite": "^5.x.x",            // Actualizaciones cada 3-4 meses
  "@types/node": "^20.x.x",     // Actualizaciones mensuales
  "tailwindcss": "^3.x.x"       // Actualizaciones cada 2-3 meses
}
```

**Frecuencia Recomendada:** Cada 3 meses
**Criticidad:** Alta (seguridad)
**Responsable:** Personal TAS/Sistemas

#### Backend (PocketBase)
```bash
# PocketBase se actualiza regularmente
# Versión actual: v0.22.x
# Nuevas versiones cada 1-2 meses
```

**Frecuencia Recomendada:** Cada 2 meses
**Criticidad:** Media-Alta
**Responsable:** Personal TAS/Sistemas

### 2. Sistema Operativo y Drivers

#### Mini-PC (Servidor)
- **Windows Updates:** Automáticas (recomendado)
- **Drivers de red:** Verificar cada 6 meses
- **Antivirus:** Actualizaciones automáticas

#### Terminales (Tablets/PCs)
- **Sistema operativo:** Actualizaciones automáticas
- **Navegador web:** Actualizaciones automáticas
- **Drivers táctiles:** Verificar cada 6 meses

**Frecuencia:** Automática + revisión semestral
**Criticidad:** Media
**Responsable:** Personal TAS

### 3. Configuración y Datos

#### Datos de la Facultad
- **Lista de vigilantes:** Actualizar cuando hay cambios de personal
- **Lugares/Salones:** Actualizar cuando hay cambios físicos
- **Departamentos:** Actualizar según estructura organizacional

**Frecuencia:** Según necesidad
**Criticidad:** Media
**Responsable:** Administración + Personal TAS

## Calendario de Mantenimiento

### Mantenimiento Diario (Automático)
```bash
# Ejecutado automáticamente por el sistema
- Backup de base de datos (2:00 AM)
- Verificación de conectividad (cada 5 minutos)
- Limpieza de logs antiguos
- Verificación de espacio en disco
```

### Mantenimiento Semanal (Manual)
```bash
# Domingos - Personal TAS
- Verificar logs de errores
- Comprobar backups automáticos
- Revisar rendimiento del sistema
- Verificar conectividad de todos los dispositivos
```

### Mantenimiento Mensual (Manual)
```bash
# Primer viernes de cada mes - Personal TAS
- Revisar actualizaciones de dependencias
- Verificar integridad de backups
- Comprobar espacio de almacenamiento
- Revisar configuración de red
- Actualizar documentación si es necesario
```

### Mantenimiento Trimestral (Planificado)
```bash
# Cada 3 meses - Personal TAS + Soporte Técnico
- Actualizar dependencias de software
- Revisar y actualizar documentación
- Capacitación de personal si es necesario
- Evaluación de rendimiento del sistema
- Planificación de mejoras
```

### Mantenimiento Semestral (Planificado)
```bash
# Cada 6 meses - Soporte Técnico
- Actualización mayor de PocketBase
- Revisión completa de seguridad
- Optimización de base de datos
- Actualización de drivers y sistema operativo
- Evaluación de hardware
```

## Procedimientos de Actualización

### 1. Actualizaciones de Dependencias (Rutinarias)

#### Preparación:
```bash
# 1. Crear backup completo
cp -r pocketbase/pb_data pocketbase/pb_data_backup_$(date +%Y%m%d)
git add . && git commit -m "Backup antes de actualización"

# 2. Verificar estado actual
npm audit
npm outdated
```

#### Actualización:
```bash
# 3. Actualizar dependencias
npm update
npm audit fix

# 4. Probar en desarrollo
npm run dev

# 5. Construir para producción
npm run build

# 6. Desplegar
npm run preview
```

#### Verificación:
```bash
# 7. Verificar funcionalidad
- Probar terminal de usuario
- Probar monitor de vigilancia
- Verificar conectividad
- Probar funciones críticas
```

### 2. Actualizaciones de PocketBase (Críticas)

#### Preparación:
```bash
# 1. Detener servicio
sudo systemctl stop pocketbase

# 2. Backup completo
cp -r pocketbase/pb_data /backup/pb_data_pre_update_$(date +%Y%m%d)
cp pocketbase/pocketbase pocketbase/pocketbase_old
```

#### Actualización:
```bash
# 3. Descargar nueva versión
wget https://github.com/pocketbase/pocketbase/releases/download/v[VERSION]/pocketbase_[VERSION]_linux_amd64.zip
unzip pocketbase_[VERSION]_linux_amd64.zip
mv pocketbase pocketbase/pocketbase_new

# 4. Probar nueva versión
cd pocketbase
./pocketbase_new serve --http=localhost:8091  # Puerto diferente para prueba

# 5. Si funciona, reemplazar
mv pocketbase_new pocketbase
sudo systemctl start pocketbase
```

### 3. Actualizaciones del Código Fuente

#### Cuando hay nuevas funcionalidades:
```bash
# 1. Backup del sistema actual
git add . && git commit -m "Estado antes de actualización"

# 2. Obtener nuevos cambios
git pull origin main

# 3. Instalar nuevas dependencias
npm install

# 4. Reconstruir
npm run build

# 5. Reiniciar servicios
sudo systemctl restart pocketbase
```

## Monitoreo de Actualizaciones

### 1. Alertas Automáticas

#### Script de Verificación de Actualizaciones:
```bash
#!/bin/bash
# /home/pocketbase/check_updates.sh

LOG_FILE="/var/log/sistema_llaves_updates.log"
cd /home/pocketbase/sistema-llaves

# Verificar actualizaciones de npm
NPM_OUTDATED=$(npm outdated --json 2>/dev/null)
if [ "$NPM_OUTDATED" != "{}" ] && [ "$NPM_OUTDATED" != "" ]; then
    echo "$(date): Actualizaciones de npm disponibles" >> $LOG_FILE
    echo "$NPM_OUTDATED" >> $LOG_FILE
fi

# Verificar actualizaciones de git
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
if [ "$LOCAL" != "$REMOTE" ]; then
    echo "$(date): Actualizaciones de código disponibles en GitHub" >> $LOG_FILE
fi

# Verificar actualizaciones de PocketBase
CURRENT_VERSION=$(./pocketbase/pocketbase --version 2>/dev/null | grep -o 'v[0-9.]*')
echo "$(date): Versión actual de PocketBase: $CURRENT_VERSION" >> $LOG_FILE
```

```bash
# Ejecutar semanalmente
crontab -e
# Añadir:
0 9 * * 1 /home/pocketbase/check_updates.sh
```

### 2. Dashboard de Estado del Sistema

#### Información a Monitorear:
- **Versión actual de cada componente**
- **Fecha de última actualización**
- **Actualizaciones disponibles**
- **Estado de backups**
- **Logs de errores recientes**

## Riesgos y Mitigaciones

### Riesgos de No Actualizar:

1. **Vulnerabilidades de Seguridad**
   - **Riesgo:** Acceso no autorizado al sistema
   - **Mitigación:** Actualizaciones regulares de seguridad

2. **Incompatibilidades**
   - **Riesgo:** Componentes dejan de funcionar
   - **Mitigación:** Pruebas en entorno de desarrollo

3. **Pérdida de Soporte**
   - **Riesgo:** Versiones obsoletas sin soporte
   - **Mitigación:** Planificación de actualizaciones

### Riesgos de Actualizar:

1. **Introducción de Bugs**
   - **Mitigación:** Backups completos antes de actualizar
   - **Mitigación:** Pruebas exhaustivas post-actualización

2. **Incompatibilidades**
   - **Mitigación:** Leer notas de versión antes de actualizar
   - **Mitigación:** Mantener versión anterior como respaldo

3. **Tiempo de Inactividad**
   - **Mitigación:** Planificar actualizaciones fuera de horario laboral
   - **Mitigación:** Procedimientos de rollback rápido

## Estrategia de Actualizaciones

### Entorno de Pruebas (Recomendado)

```bash
# Configurar entorno de pruebas
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git test-env
cd test-env

# Configurar para pruebas
cp .env.example .env
# Editar .env con configuración de pruebas
VITE_DEVICE_TYPE=auto
VITE_PRODUCTION_MODE=false
VITE_POCKETBASE_URL=http://localhost:8091

# Probar actualizaciones aquí antes de aplicar en producción
```

### Ventana de Mantenimiento

**Horario Recomendado:**
- **Día:** Domingos
- **Hora:** 2:00 AM - 6:00 AM
- **Duración máxima:** 4 horas
- **Frecuencia:** Mensual para actualizaciones menores, trimestral para mayores

## Documentación de Cambios

### Registro de Actualizaciones

Mantener un log en `docs/historial_actualizaciones.md`:

```markdown
# Historial de Actualizaciones

## 2026-04-09 - v4.3
- Implementado sistema de autorizaciones con CI
- Mejorado filtrado de usuarios
- Corregido ordenamiento de llaves devueltas
- Añadido sistema de configuración para producción

## [FECHA] - v4.4
- [Descripción de cambios]
- [Componentes actualizados]
- [Problemas resueltos]
```

### Checklist de Actualización

```markdown
## Checklist Pre-Actualización
- [ ] Backup de base de datos creado
- [ ] Backup de código fuente creado
- [ ] Entorno de pruebas configurado
- [ ] Personal técnico disponible
- [ ] Ventana de mantenimiento programada

## Checklist Post-Actualización
- [ ] Sistema iniciado correctamente
- [ ] Todas las funciones probadas
- [ ] Conectividad verificada
- [ ] Logs revisados
- [ ] Personal notificado
- [ ] Documentación actualizada
```

## Contactos para Actualizaciones

### Responsabilidades:

**Personal TAS (Actualizaciones Rutinarias):**
- Actualizaciones menores de dependencias
- Actualizaciones de sistema operativo
- Backups y verificaciones

**Soporte Técnico (Actualizaciones Mayores):**
- Actualizaciones de PocketBase
- Cambios en la arquitectura
- Resolución de problemas complejos

**Desarrollador Original (Consultas):**
- Interpretación de código
- Modificaciones personalizadas
- Capacitación técnica

### Información de Contacto:

```
Personal TAS:
- Responsable: [A COMPLETAR]
- Teléfono: [A COMPLETAR]
- Email: [A COMPLETAR]
- Disponibilidad: Lunes a Viernes 8:00-17:00

Soporte Técnico:
- Empresa/Persona: [A COMPLETAR]
- Teléfono: [A COMPLETAR]
- Email: [A COMPLETAR]
- Disponibilidad: Bajo demanda

Desarrollador Original:
- Nombre: Luis Raggi
- Usuario GitHub: luisraggiouy
- Email: [A COMPLETAR]
- Disponibilidad: Consultas puntuales
```

## Herramientas de Monitoreo

### 1. Verificación de Versiones

```bash
# Script para verificar versiones actuales
#!/bin/bash
echo "=== ESTADO DEL SISTEMA ==="
echo "Fecha: $(date)"
echo ""

echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "PocketBase: $(./pocketbase/pocketbase --version)"

echo ""
echo "=== DEPENDENCIAS PRINCIPALES ==="
npm list react typescript vite --depth=0

echo ""
echo "=== ACTUALIZACIONES DISPONIBLES ==="
npm outdated

echo ""
echo "=== ESTADO DE GIT ==="
git status --porcelain
git log --oneline -5
```

### 2. Alertas de Seguridad

```bash
# Verificar vulnerabilidades de seguridad
npm audit

# Corregir automáticamente si es posible
npm audit fix

# Para vulnerabilidades críticas
npm audit fix --force
```

## Planificación a Largo Plazo

### Ciclo de Vida de Tecnologías

#### React (Frontend)
- **Versión actual:** 18.x
- **Próxima versión mayor:** 19.x (estimado 2025)
- **Soporte LTS:** Hasta 2027
- **Acción requerida:** Actualización mayor en 2025

#### TypeScript
- **Versión actual:** 5.x
- **Actualizaciones:** Cada 3-4 meses
- **Soporte:** Continuo
- **Acción requerida:** Actualizaciones menores regulares

#### PocketBase
- **Versión actual:** 0.22.x
- **Desarrollo:** Activo
- **Estabilidad:** Alta
- **Acción requerida:** Seguir actualizaciones regulares

### Migración Futura (5+ años)

#### Consideraciones:
1. **Migración a tecnologías más nuevas** si es necesario
2. **Evaluación de alternativas** a PocketBase
3. **Modernización de la interfaz** según estándares futuros
4. **Integración con otros sistemas** de la universidad

#### Preparación:
- **Mantener documentación actualizada**
- **Preservar estructura de datos**
- **Capacitar personal técnico**
- **Evaluar necesidades futuras**

## Presupuesto Estimado para Mantenimiento

### Costos Anuales Estimados:

**Personal Técnico (TAS):**
- Mantenimiento rutinario: 2-3 horas/mes
- Actualizaciones: 4-6 horas/trimestre
- **Total:** ~40 horas/año

**Soporte Técnico Externo:**
- Actualizaciones mayores: 8-12 horas/año
- Emergencias: 4-8 horas/año
- **Total:** ~20 horas/año

**Software/Licencias:**
- Todas las tecnologías utilizadas son gratuitas y open source
- **Costo:** $0/año

**Hardware:**
- Reemplazo de componentes: Según necesidad
- **Estimado:** $200-500/año

### Total Estimado: $500-1000/año (principalmente mano de obra)

## Recomendaciones Finales

### Para las Autoridades:

1. **Designar responsable técnico** del personal TAS
2. **Establecer contrato de soporte** con empresa/persona técnica
3. **Programar capacitaciones** anuales para personal
4. **Mantener presupuesto** para mantenimiento y actualizaciones
5. **Revisar este plan** anualmente y actualizarlo según necesidades

### Para el Personal Técnico:

1. **Familiarizarse** con las tecnologías utilizadas
2. **Configurar entorno de pruebas** para actualizaciones
3. **Mantener documentación** actualizada
4. **Establecer procedimientos** de backup y recuperación
5. **Monitorear regularmente** el estado del sistema

---

**NOTA:** Este plan debe revisarse y actualizarse anualmente para reflejar cambios en tecnologías, necesidades institucionales y disponibilidad de recursos.