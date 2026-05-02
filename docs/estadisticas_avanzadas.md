# Estadísticas Avanzadas y Exportación de Datos

## Introducción

Este documento detalla las funcionalidades de visualización de datos y exportación implementadas en el Sistema de Gestión de Llaves FCEA. El Dashboard proporciona un reflejo completo del trabajo realizado por cada vigilante y por cada turno, permitiendo análisis profundos y exportación de información para evaluación y toma de decisiones.

## Concepto del Dashboard

**El Dashboard es el fiel reflejo del trabajo realizado por cada vigilante y por cada turno.**

El sistema registra y permite exportar TODA la información relacionada con las tareas que realizan los vigilantes:
- 🔑 Gestión de llaves (entregas y devoluciones)
- 📦 Objetos olvidados (registro y devolución)
- ✅ Autorizaciones (creación y gestión)

## Visualizaciones Disponibles

El sistema ofrece tres tipos diferentes de visualizaciones estadísticas para analizar el desempeño:

### 1. Gráficos de Torta

- **Funcionalidad**: Muestran la proporción entre llaves devueltas y pendientes para cada turno
- **Interpretación**: El porcentaje en el centro representa la tasa de devolución (llaves devueltas/llaves entregadas)
- **Uso recomendado**: Ideal para evaluar el desempeño general de cada turno en términos de tasa de devolución

### 2. Gráficos de Barras

- **Funcionalidad**: Comparan directamente las cantidades de llaves entregadas, devueltas y pendientes por turno
- **Características**: Incluyen un eje secundario (derecho) que muestra el porcentaje de devolución
- **Uso recomendado**: Perfecto para comparar volúmenes de operaciones entre diferentes turnos

### 3. Gráficos de Línea Temporal

- **Funcionalidad**: Muestran la evolución de la actividad a lo largo del tiempo por turno
- **Características**: 
  - Líneas separadas para cada turno (Matutino, Vespertino, Nocturno)
  - Línea adicional para el total de operaciones
- **Uso recomendado**: Ideal para detectar patrones temporales, picos de actividad o evaluar tendencias

## Filtros Temporales

Todas las visualizaciones pueden filtrarse según tres horizontes temporales:

- **Mensual**: Datos del mes en curso
- **Semestral**: Datos de los últimos 6 meses
- **Anual**: Datos de los últimos 12 meses

## Exportación de Datos

### Funcionalidad de Exportación

El sistema permite exportar datos completos en formato CSV (compatible con Excel) para análisis externo, informes y evaluaciones. La exportación requiere:

- **Selección de rango de fechas**: Obligatorio para todos los usuarios
- **Dispositivo USB conectado**: Obligatorio para todos los usuarios (compatible con modo kiosk)
- **Selección de datos**: Checkboxes para elegir qué información incluir

### Datos Incluidos en la Exportación

El sistema permite seleccionar qué información incluir:

#### 🔑 Gestión de Llaves

**Solicitudes Pendientes**:
- Fecha y hora de solicitud
- Usuario completo (nombre, celular, tipo, departamento, empresa)
- Lugar solicitado (nombre, tipo, edificio, piso)
- Estado

**Llaves Entregadas** (en uso):
- Fecha y hora de solicitud y entrega
- Usuario completo
- Lugar completo
- Vigilante que entregó
- Tiempo en uso
- Notas
- Estado

**Llaves Devueltas**:
- Fecha y hora de solicitud, entrega y devolución
- Usuario completo
- Lugar completo
- Vigilante que entregó
- Vigilante que recibió
- Tiempo total de uso
- Notas
- Estado

#### 📦 Objetos Olvidados

**Registro de Objetos**:
- Fecha y hora de registro
- Descripción detallada del objeto
- Lugar donde fue encontrado
- **Vigilante que lo registró**
- Estado actual (pendiente/devuelto)

**Devolución de Objetos**:
- Fecha y hora de devolución
- Nombre y CI del receptor
- **Vigilante que realizó la devolución**
- Observaciones

#### ✅ Autorizaciones Ingresadas

**Creación de Autorizaciones**:
- Fecha y hora de autorización
- Persona autorizada (nombre y CI)
- Lugar autorizado
- **Vigilante que autorizó**
- Período de vigencia (desde/hasta)
- Horario permitido
- Email de referencia
- Observaciones

#### 📈 Información Adicional (Opcional)

- **Estadísticas y Resúmenes**: Análisis agregados por turno y período
- **Lista de Usuarios**: Catálogo de usuarios registrados en el sistema
- **Catálogo de Llaves**: Inventario completo de lugares y llaves disponibles

### Proceso de Exportación

1. Acceder al Dashboard
2. Hacer clic en el botón "Exportar Datos"
3. Conectar un dispositivo USB (se detecta automáticamente)
4. Seleccionar el rango de fechas (inicio y fin)
5. Marcar los checkboxes de los datos a incluir
6. Hacer clic en "Exportar a USB"
7. Esperar la confirmación de exportación exitosa
8. Retirar el pendrive de forma segura

### Archivos Generados

La exportación genera múltiples archivos CSV:

1. `Dashboard_FCEA_[fechas]_Resumen.csv` - Resumen general con totales
2. `Dashboard_FCEA_[fechas]_Solicitudes_Pendientes.csv`
3. `Dashboard_FCEA_[fechas]_Llaves_Entregadas.csv`
4. `Dashboard_FCEA_[fechas]_Llaves_Devueltas.csv`
5. `Dashboard_FCEA_[fechas]_Objetos_Olvidados.csv`
6. `Dashboard_FCEA_[fechas]_Autorizaciones.csv`
7. `Dashboard_FCEA_[fechas]_Completo.csv` - Todos los datos en un archivo

### Características Técnicas

- **Formato**: CSV (Comma-Separated Values)
- **Compatibilidad**: Excel, LibreOffice Calc, Google Sheets
- **Codificación**: UTF-8 con BOM para correcta visualización de caracteres especiales
- **Separador**: Coma (,)
- **Nombrado**: Incluye rango de fechas y timestamp para fácil identificación

## Interpretación de los Datos

### Códigos de Color en Tasas de Devolución

Para facilitar la interpretación de los datos, se utilizan códigos de color:

- **Verde (≥98%)**: Excelente tasa de devolución
- **Ámbar (90-97.9%)**: Tasa de devolución aceptable
- **Rojo (<90%)**: Tasa de devolución por debajo del estándar esperado

### Métricas Clave

- **Total de Llaves**: Suma de todas las llaves entregadas en el período
- **Tasa Media de Devolución**: Porcentaje global de llaves devueltas
- **Total de Objetos**: Cantidad de objetos olvidados registrados
- **Total de Autorizaciones**: Cantidad de autorizaciones creadas
- **Total de Registros**: Suma de todas las operaciones realizadas

## Beneficios del Sistema

### Para la Gestión

- **Evaluación Completa**: Permite evaluar TODO el trabajo de cada vigilante
- **Análisis Comparativo**: Facilita la comparación entre turnos para identificar áreas de mejora
- **Seguimiento de Tendencias**: Permite detectar patrones temporales
- **Trazabilidad Total**: Cada acción queda registrada con fecha, hora y responsable
- **Evidencia Documentada**: Respaldo de todas las operaciones realizadas

### Para los Vigilantes

- **Reconocimiento del Trabajo**: Su labor con llaves, objetos y autorizaciones queda registrada
- **Transparencia**: Claridad sobre qué se registra y exporta
- **Responsabilidad**: Cada acción tiene un responsable identificado

### Para las Autoridades

- **Informes Ejecutivos**: La exportación simplifica la creación de reportes
- **Evidencia Visual**: Proporciona evidencia clara del desempeño del sistema
- **Toma de Decisiones**: Información completa para decisiones informadas
- **Establecimiento de Objetivos**: Facilita la definición de metas de mejora

## Seguridad y Privacidad

- ✅ Requiere USB conectado para exportar (todos los usuarios)
- ✅ Requiere seleccionar rango de fechas (no exportación masiva indiscriminada)
- ✅ Registro de quién exportó y cuándo
- ✅ Compatible con modo kiosk
- ✅ Datos sensibles protegidos

## Recomendaciones de Uso

1. **Revisión Regular**: Establecer un cronograma para la revisión periódica de las estadísticas
2. **Análisis Comparativo**: Utilizar diferentes tipos de gráficos para obtener una visión completa
3. **Exportación Planificada**: Exportar datos regularmente para mantener respaldos actualizados
4. **Establecimiento de KPIs**: Utilizar las métricas como indicadores clave de desempeño
5. **Documentación de Incidentes**: Cuando se detecten anomalías, documentarlas junto con posibles causas

## Implementación Técnica

- Las visualizaciones están construidas sobre la biblioteca Recharts
- La exportación utiliza el API de File System para escritura directa en USB
- Los datos se filtran por rango de fechas en el cliente antes de exportar
- Los archivos CSV mantienen compatibilidad con estándares internacionales
- El sistema detecta automáticamente dispositivos USB conectados
