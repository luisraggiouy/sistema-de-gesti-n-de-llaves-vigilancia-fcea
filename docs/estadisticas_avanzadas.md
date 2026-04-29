# Estadísticas Avanzadas y Exportación de Visualizaciones

## Introducción

Este documento detalla las nuevas funcionalidades de visualización de datos y estadísticas implementadas en el Sistema de Gestión de Llaves FCEA. Estas mejoras permiten un análisis más profundo de las tendencias de uso de llaves e incluyen múltiples tipos de gráficos y la capacidad de exportar visualizaciones como imágenes.

## Visualizaciones Disponibles

El sistema ahora ofrece tres tipos diferentes de visualizaciones estadísticas:

### 1. Gráficos de Torta

- **Funcionalidad**: Muestran la proporción entre llaves devueltas y pendientes para cada turno.
- **Interpretación**: El porcentaje en el centro representa la tasa de devolución (llaves devueltas/llaves entregadas).
- **Uso recomendado**: Ideal para evaluar el desempeño general de cada turno en términos de tasa de devolución.

### 2. Gráficos de Barras

- **Funcionalidad**: Comparan directamente las cantidades de llaves entregadas, devueltas y pendientes por turno.
- **Características**: Incluyen un eje secundario (derecho) que muestra el porcentaje de devolución.
- **Uso recomendado**: Perfecto para comparar volúmenes de operaciones entre diferentes turnos y ver la relación entre cantidad de operaciones y eficiencia (tasa de devolución).

### 3. Gráficos de Línea Temporal

- **Funcionalidad**: Muestran la evolución de la actividad a lo largo del tiempo por turno.
- **Características**: 
  - Líneas separadas para cada turno (Matutino, Vespertino, Nocturno)
  - Línea adicional para el total de operaciones
- **Uso recomendado**: Ideal para detectar patrones temporales, picos de actividad, o evaluar tendencias a mediano y largo plazo.

## Filtros Temporales

Todas las visualizaciones pueden filtrarse según tres horizontes temporales:

- **Mensual**: Datos del mes en curso
- **Semestral**: Datos de los últimos 6 meses
- **Anual**: Datos de los últimos 12 meses

## Exportación de Visualizaciones a Imágenes

### Funcionalidad

El sistema permite exportar cualquiera de las visualizaciones como imagen PNG de alta calidad, facilitando su inclusión en informes, presentaciones o documentación.

### Proceso de Exportación

1. Seleccione el tipo de gráfico deseado (Torta, Barras, o Línea)
2. Configure el período temporal requerido (Mensual, Semestral, Anual)
3. Haga clic en el botón "Exportar como Imagen"
4. Se descargará automáticamente un archivo PNG con la visualización actual

### Características Técnicas

- **Formato**: PNG con fondo transparente
- **Resolución**: Alta resolución (2x) para mayor nitidez en impresiones
- **Nombrado**: Los archivos siguen el formato `estadisticas_llaves_[tipo]_[periodo]_[fecha].png`
- **Compatibilidad**: Las imágenes son compatibles con todas las aplicaciones de ofimática (Word, PowerPoint, etc.)

## Interpretación de los Datos

### Códigos de Color en Tasas de Devolución

Para facilitar la interpretación de los datos, se utilizan códigos de color para las tasas de devolución:

- **Verde (≥98%)**: Excelente tasa de devolución
- **Ámbar (90-97.9%)**: Tasa de devolución aceptable
- **Rojo (<90%)**: Tasa de devolución por debajo del estándar esperado

### Métricas Clave

- **Total de Llaves**: Suma de todas las llaves entregadas en el período
- **Tasa Media de Devolución**: Porcentaje global de llaves que fueron devueltas en el período seleccionado

## Beneficios para la Gestión

Las nuevas visualizaciones y la capacidad de exportación proporcionan múltiples beneficios:

- **Análisis Comparativo**: Facilita la comparación entre turnos para identificar áreas de mejora
- **Seguimiento de Tendencias**: Permite detectar patrones temporales que podrían requerir ajustes operativos
- **Informes Ejecutivos**: La exportación de imágenes simplifica la creación de reportes para autoridades
- **Evidencia Visual**: Proporciona evidencia clara y comprensible del desempeño del sistema
- **Establecimiento de Objetivos**: La visualización clara de métricas facilita la definición de metas de mejora

## Recomendaciones de Uso

1. **Revisión Regular**: Establecer un cronograma para la revisión periódica de las estadísticas (semanal, quincenal o mensual)
2. **Análisis Comparativo**: Utilizar diferentes tipos de gráficos para obtener una visión completa del desempeño
3. **Exportación para Reuniones**: Exportar las visualizaciones relevantes antes de reuniones de gestión o evaluación
4. **Establecimiento de KPIs**: Utilizar las tasas de devolución como indicadores clave de desempeño para cada turno
5. **Documentación de Incidentes**: Cuando se detecten anomalías en los gráficos, documentarlas junto con posibles causas

## Implementación Técnica

- La funcionalidad está construida sobre la biblioteca Recharts para visualizaciones interactivas
- La exportación de imágenes utiliza html2canvas para capturar el estado actual del gráfico
- Las imágenes se procesan a escala 2x para garantizar alta calidad en dispositivos de alta resolución
- Los colores y estilos mantienen la coherencia con la interfaz general del sistema