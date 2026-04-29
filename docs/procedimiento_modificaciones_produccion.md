# Procedimiento para Modificaciones en Producción - Sistema de Gestión de Llaves FCEA

## Flujo de Trabajo para Modificaciones

### 1. Proceso de Solicitud de Cambios

#### Paso 1: Solicitud Formal
```
Solicitante: [Autoridad/Usuario que solicita el cambio]
Fecha: [Fecha de solicitud]
Tipo de cambio: [Nuevo feature / Corrección / Mejora / Eliminación]
Descripción: [Descripción detallada del cambio solicitado]
Justificación: [Por qué es necesario este cambio]
Prioridad: [Alta / Media / Baja]
Fecha límite: [Cuándo se necesita implementado]
```

#### Paso 2: Evaluación Técnica
```
Evaluador: [Personal TAS / Soporte Técnico]
Complejidad: [Simple / Media / Compleja]
Tiempo estimado: [Horas de desarrollo]
Riesgos: [Identificar posibles problemas]
Impacto: [Qué partes del sistema se ven afectadas]
Costo estimado: [Si requiere soporte externo]
Recomendación: [Aprobar / Rechazar / Modificar]
```

### 2. Tipos de Modificaciones y Procedimientos

#### Tipo A: Modificaciones de Configuración (Simples)
**Ejemplos:**
- Cambiar lista de vigilantes
- Añadir/quitar lugares
- Modificar horarios de restricción
- Cambiar mensajes de WhatsApp

**Procedimiento:**
```bash
# 1. Backup de seguridad
cp -r pocketbase/pb_data pocketbase/pb_data_backup_$(date +%Y%m%d_%H%M)

# 2. Modificar datos directamente en PocketBase Admin
# Acceder a: http://[IP_SERVIDOR]:8090/_/
# Usuario: admin
# Contraseña: [Configurada durante instalación]

# 3. Verificar cambios en todas las pantallas
# 4. Documentar cambio realizado
```

**Responsable:** Personal TAS
**Tiempo:** 15-30 minutos
**Riesgo:** Bajo

#### Tipo B: Modificaciones de Interfaz (Medias)
**Ejemplos:**
- Cambiar colores o estilos
- Modificar textos de la interfaz
- Añadir campos a formularios
- Cambiar disposición de elementos

**Procedimiento:**
```bash
# 1. Entorno de desarrollo
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git dev-env
cd dev-env

# 2. Crear rama para el cambio
git checkout -b modificacion-[DESCRIPCION]

# 3. Realizar modificaciones
# Editar archivos necesarios

# 4. Probar en desarrollo
npm install
npm run dev

# 5. Construir para producción
npm run build

# 6. Crear Pull Request en GitHub
git add .
git commit -m "Descripción del cambio"
git push origin modificacion-[DESCRIPCION]

# 7. Revisar y aprobar cambios
# 8. Desplegar en producción
```

**Responsable:** Soporte Técnico + Personal TAS
**Tiempo:** 2-8 horas
**Riesgo:** Medio

#### Tipo C: Modificaciones de Funcionalidad (Complejas)
**Ejemplos:**
- Añadir nuevas funcionalidades
- Modificar lógica de negocio
- Integrar con otros sistemas
- Cambios en la base de datos

**Procedimiento:**
```bash
# 1. Análisis y diseño detallado
# Documentar requerimientos específicos
# Evaluar impacto en sistema existente

# 2. Desarrollo en entorno aislado
git clone [REPO] feature-env
cd feature-env
git checkout -b feature-[NOMBRE]

# 3. Desarrollo iterativo
# Implementar cambios paso a paso
# Probar cada componente

# 4. Pruebas exhaustivas
npm run test
npm run build
# Probar en entorno que simule producción

# 5. Documentación
# Actualizar documentación técnica
# Crear guía de usuario si es necesario

# 6. Despliegue planificado
# Programar ventana de mantenimiento
# Notificar a usuarios
# Ejecutar despliegue
```

**Responsable:** Soporte Técnico Especializado
**Tiempo:** 1-4 semanas
**Riesgo:** Alto

### 3. Entorno de Desarrollo y Pruebas

#### Configuración de Entorno de Desarrollo

```bash
# 1. Clonar repositorio
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git dev-sistema-llaves
cd dev-sistema-llaves

# 2. Configurar entorno de desarrollo
cp .env.example .env.development
# Editar .env.development:
VITE_DEVICE_TYPE=auto
VITE_PRODUCTION_MODE=false
VITE_DEVICE_ID=dev-environment
VITE_POCKETBASE_URL=http://localhost:8091  # Puerto diferente

# 3. Configurar PocketBase de desarrollo
cd pocketbase
cp -r pb_data pb_data_dev
./pocketbase serve --http=localhost:8091 --dir=pb_data_dev

# 4. Instalar dependencias
npm install

# 5. Ejecutar en modo desarrollo
npm run dev
```

#### Entorno de Staging (Pre-producción)

```bash
# Configurar entorno idéntico a producción pero separado
# Para pruebas finales antes del despliegue
VITE_DEVICE_TYPE=monitor  # O terminal según dispositivo
VITE_PRODUCTION_MODE=true
VITE_DEVICE_ID=staging-device
VITE_POCKETBASE_URL=http://localhost:8092
```

### 4. Procedimiento de Despliegue

#### Despliegue de Cambios Menores (Tipo A y B)

```bash
# 1. Verificar que no hay usuarios activos
# Coordinar con vigilantes

# 2. Crear backup completo
./scripts/backup_completo.sh

# 3. Desplegar cambios
cd /ruta/produccion/sistema-llaves
git pull origin main
npm install
npm run build

# 4. Reiniciar servicios
sudo systemctl restart pocketbase
# Reiniciar servidores web de terminales

# 5. Verificar funcionamiento
# Probar cada terminal y monitor
# Verificar conectividad
# Probar funciones críticas

# 6. Notificar finalización
```

**Tiempo de inactividad:** 5-15 minutos
**Ventana recomendada:** Fuera de horario laboral

#### Despliegue de Cambios Mayores (Tipo C)

```bash
# 1. Planificación (1-2 semanas antes)
- Notificar a usuarios con anticipación
- Programar ventana de mantenimiento extendida
- Preparar plan de rollback
- Coordinar con personal técnico

# 2. Pre-despliegue (día anterior)
- Backup completo del sistema
- Verificar entorno de staging
- Preparar scripts de despliegue
- Confirmar disponibilidad de personal

# 3. Despliegue (día programado)
- Detener sistema en producción
- Aplicar cambios
- Migrar base de datos si es necesario
- Probar exhaustivamente
- Activar sistema

# 4. Post-despliegue
- Monitorear sistema por 24-48 horas
- Resolver problemas menores
- Documentar lecciones aprendidas
```

**Tiempo de inactividad:** 2-6 horas
**Ventana recomendada:** Fin de semana

### 5. Control de Versiones y Ramas

#### Estrategia de Ramas en GitHub

```
main (producción)
├── develop (desarrollo)
├── feature/nueva-funcionalidad
├── hotfix/correccion-urgente
└── release/v4.4
```

#### Flujo de Trabajo:

1. **Desarrollo:** Crear rama desde `develop`
2. **Pruebas:** Merge a `develop` para pruebas
3. **Release:** Crear rama `release/vX.X` desde `develop`
4. **Producción:** Merge a `main` después de aprobación
5. **Hotfixes:** Rama directa desde `main` para correcciones urgentes

### 6. Documentación de Cambios

#### Registro Obligatorio

Para cada modificación, documentar en `docs/historial_cambios.md`:

```markdown
## [FECHA] - [TIPO] - [VERSIÓN]

### Solicitado por:
[Nombre y cargo de quien solicita]

### Descripción del cambio:
[Qué se modificó exactamente]

### Archivos modificados:
- src/components/[archivo].tsx
- src/hooks/[archivo].ts
- docs/[archivo].md

### Impacto:
[Qué partes del sistema se ven afectadas]

### Pruebas realizadas:
- [ ] Terminal Usuario 1
- [ ] Terminal Usuario 2  
- [ ] Monitor Vigilancia
- [ ] Conectividad
- [ ] Funciones críticas

### Problemas encontrados:
[Cualquier problema durante la implementación]

### Tiempo de inactividad:
[Cuánto tiempo estuvo el sistema fuera de servicio]

### Responsable técnico:
[Quién realizó la modificación]
```

### 7. Procedimientos de Emergencia

#### Rollback Rápido (Si algo sale mal)

```bash
# 1. Detener sistema actual
sudo systemctl stop pocketbase

# 2. Restaurar código anterior
cd /ruta/produccion/sistema-llaves
git reset --hard HEAD~1  # Volver al commit anterior
npm install
npm run build

# 3. Restaurar base de datos
cd pocketbase
rm -rf pb_data
cp -r pb_data_backup_[FECHA_RECIENTE] pb_data

# 4. Reiniciar sistema
sudo systemctl start pocketbase

# 5. Verificar funcionamiento
```

**Tiempo de recuperación:** 10-20 minutos

#### Contactos de Emergencia

```
Problemas Críticos (24/7):
- Soporte Técnico: [TELÉFONO]
- Personal TAS Jefe: [TELÉFONO]

Problemas Menores (horario laboral):
- Personal TAS: [TELÉFONO]
- Administración: [TELÉFONO]
```

### 8. Herramientas de Desarrollo

#### Software Necesario para Modificaciones

```bash
# Herramientas básicas
- Git (control de versiones)
- Node.js v18+ (entorno de ejecución)
- npm (gestor de paquetes)
- Editor de código (VS Code recomendado)

# Herramientas opcionales
- GitHub Desktop (interfaz gráfica para Git)
- Postman (para probar APIs)
- Browser DevTools (depuración)
```

#### Configuración del Entorno de Desarrollo

```bash
# 1. Instalar Node.js
# Descargar desde: https://nodejs.org/

# 2. Instalar Git
# Descargar desde: https://git-scm.com/

# 3. Clonar repositorio
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git

# 4. Configurar proyecto
cd sistema-de-gesti-n-de-llaves-vigilancia-fcea
npm install
cp .env.example .env

# 5. Ejecutar en modo desarrollo
npm run dev
```

### 9. Ejemplos de Modificaciones Comunes

#### Ejemplo 1: Añadir un Nuevo Vigilante

**Archivos a modificar:**
- `src/data/fceaData.ts` (añadir a la lista de vigilantes)

**Procedimiento:**
```typescript
// En src/data/fceaData.ts
export const vigilantes: Vigilante[] = [
  // ... vigilantes existentes
  { id: 'v17', nombre: 'Nuevo Vigilante', esJefe: false, turno: 'Matutino' },
];
```

**Despliegue:**
```bash
git add src/data/fceaData.ts
git commit -m "Añadir nuevo vigilante: Nuevo Vigilante"
git push origin main
# Desplegar en producción
```

#### Ejemplo 2: Modificar Tiempo de Alerta

**Archivos a modificar:**
- Configuración en PocketBase Admin

**Procedimiento:**
1. Acceder a PocketBase Admin: `http://[IP]:8090/_/`
2. Ir a colección `configuracion`
3. Modificar campo `tiempo_alerta_minutos`
4. Guardar cambios
5. Verificar en monitor de vigilancia

#### Ejemplo 3: Añadir Nuevo Tipo de Lugar

**Archivos a modificar:**
- `src/data/fceaData.ts`
- `src/components/terminal/KeySearch.tsx` (si necesita lógica especial)

**Procedimiento:**
```typescript
// En src/data/fceaData.ts
export type TipoLugar = 
  | 'Salón' 
  | 'Salón Híbrido' 
  | 'Oficina'
  | 'Nuevo Tipo';  // Añadir aquí

export const tiposLugar: TipoLugar[] = [
  'Salón', 'Salón Híbrido', 'Oficina', 'Nuevo Tipo'  // Y aquí
];

// Añadir color si es necesario
export function getColorTipoLugar(tipo: TipoLugar): string {
  const colores: Record<TipoLugar, string> = {
    // ... colores existentes
    'Nuevo Tipo': 'bg-purple-500',
  };
  return colores[tipo] || 'bg-muted';
}
```

### 10. Checklist de Modificaciones

#### Pre-Modificación
```markdown
- [ ] Solicitud formal aprobada
- [ ] Evaluación técnica completada
- [ ] Backup completo realizado
- [ ] Entorno de desarrollo configurado
- [ ] Plan de rollback preparado
- [ ] Personal técnico disponible
- [ ] Ventana de mantenimiento programada (si es necesario)
- [ ] Usuarios notificados (si es necesario)
```

#### Durante la Modificación
```markdown
- [ ] Cambios implementados en desarrollo
- [ ] Pruebas unitarias pasadas
- [ ] Pruebas de integración realizadas
- [ ] Documentación actualizada
- [ ] Código revisado (code review)
- [ ] Build de producción exitoso
```

#### Post-Modificación
```markdown
- [ ] Despliegue en producción exitoso
- [ ] Todas las funciones probadas
- [ ] Conectividad verificada
- [ ] Rendimiento verificado
- [ ] Logs revisados
- [ ] Personal capacitado (si es necesario)
- [ ] Documentación de usuario actualizada
- [ ] Cambio documentado en historial
```

### 11. Matriz de Responsabilidades

| Tipo de Modificación | Autorización | Desarrollo | Pruebas | Despliegue | Soporte |
|----------------------|--------------|------------|---------|------------|---------|
| **Configuración Simple** | Admin FCEA | Personal TAS | Personal TAS | Personal TAS | Personal TAS |
| **Interfaz/Textos** | Admin FCEA | Soporte Técnico | Personal TAS | Personal TAS | Soporte Técnico |
| **Nueva Funcionalidad** | Decanato | Soporte Técnico | Soporte Técnico | Soporte Técnico | Soporte Técnico |
| **Cambios Críticos** | Decanato + TAS | Desarrollador | Soporte Técnico | Soporte Técnico | Desarrollador |

### 12. Comunicación de Cambios

#### Notificación a Usuarios

**Para cambios menores:**
- Email a vigilantes
- Nota en el sistema (si es posible)

**Para cambios mayores:**
- Reunión informativa
- Manual de usuario actualizado
- Capacitación si es necesario

#### Template de Comunicación

```
Asunto: [SISTEMA LLAVES] Actualización programada - [FECHA]

Estimados vigilantes y usuarios,

Se ha programado una actualización del Sistema de Gestión de Llaves para el [FECHA] de [HORA] a [HORA].

Cambios incluidos:
- [Lista de cambios principales]

Impacto esperado:
- [Tiempo de inactividad]
- [Nuevas funcionalidades]
- [Cambios en procedimientos]

Acciones requeridas:
- [Qué deben hacer los usuarios]

Contacto para consultas:
- [Información de contacto]

Saludos,
[Responsable técnico]
```

### 13. Herramientas de Gestión de Cambios

#### GitHub Issues (Recomendado)

```
Título: [TIPO] Descripción breve del cambio
Etiquetas: enhancement, bug, documentation, etc.
Asignado: [Responsable técnico]
Milestone: [Versión objetivo]

Descripción:
## Descripción del cambio
[Descripción detallada]

## Justificación
[Por qué es necesario]

## Criterios de aceptación
- [ ] Criterio 1
- [ ] Criterio 2

## Archivos afectados
- [ ] archivo1.tsx
- [ ] archivo2.ts

## Pruebas requeridas
- [ ] Prueba 1
- [ ] Prueba 2
```

#### Registro de Cambios (CHANGELOG.md)

```markdown
# Changelog

## [4.4.0] - 2026-XX-XX
### Añadido
- Nueva funcionalidad X
- Campo Y en formulario Z

### Modificado
- Mejorado rendimiento de búsqueda
- Actualizada interfaz de usuario

### Corregido
- Error en cálculo de tiempo
- Problema de conectividad

### Eliminado
- Funcionalidad obsoleta X
```

### 14. Costos de Modificaciones

#### Estimación de Costos por Tipo

**Modificaciones Tipo A (Configuración):**
- Personal TAS: 0.5-1 hora
- Costo: $20-40

**Modificaciones Tipo B (Interfaz):**
- Soporte Técnico: 2-8 horas
- Costo: $100-400

**Modificaciones Tipo C (Funcionalidad):**
- Desarrollo especializado: 20-160 horas
- Costo: $1000-8000

#### Presupuesto Anual Recomendado

```
Modificaciones menores: $500-1000
Modificaciones mayores: $2000-5000
Emergencias/Hotfixes: $500-1000
Total recomendado: $3000-7000/año
```

### 15. Mejores Prácticas

#### Para Solicitantes de Cambios:
1. **Describir claramente** qué se necesita y por qué
2. **Proporcionar ejemplos** o mockups si es posible
3. **Definir prioridad** realista
4. **Considerar impacto** en usuarios actuales

#### Para Personal Técnico:
1. **Siempre hacer backup** antes de cualquier cambio
2. **Probar en desarrollo** antes de producción
3. **Documentar todos los cambios**
4. **Comunicar proactivamente** con usuarios
5. **Mantener plan de rollback** listo

#### Para las Autoridades:
1. **Aprobar presupuesto** para mantenimiento
2. **Designar responsable** de solicitudes de cambios
3. **Establecer prioridades** claras
4. **Revisar cambios** antes de implementación

---

**IMPORTANTE:** Este procedimiento debe seguirse estrictamente para mantener la estabilidad y seguridad del sistema en producción. Cualquier desviación debe ser aprobada por las autoridades correspondientes.