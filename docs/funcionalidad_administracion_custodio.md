# Documentación: Sistema de Administración con Rol de Custodio y Estadísticas Avanzadas

## Introducción

Este documento describe las nuevas funcionalidades implementadas en el Sistema de Gestión de Llaves de FCEA para permitir la existencia de un rol de custodio que puede autenticar, cambiar sus credenciales y exportar datos a dispositivos USB, así como las estadísticas avanzadas con gráficos para el análisis de datos.

## Índice

1. [Sistema de credenciales dual](#1-sistema-de-credenciales-dual)
2. [Cambio de contraseñas](#2-cambio-de-contraseñas)
3. [Exportación directa a USB](#3-exportación-directa-a-usb)
4. [Interfaz de usuario para el custodio](#4-interfaz-de-usuario-para-el-custodio)
5. [Estadísticas con gráficos de torta](#5-estadísticas-con-gráficos-de-torta)
6. [Consideraciones técnicas](#6-consideraciones-técnicas)
7. [Guía para administradores](#7-guía-para-administradores)

## 1. Sistema de Credenciales Dual

### Descripción General

El sistema ahora soporta dos tipos de usuarios administrativos:

- **Administrador**: Acceso completo a todas las funcionalidades del sistema.
- **Custodio**: Acceso específico para exportar datos a un dispositivo USB.

### Funcionamiento

- Ambos roles utilizan el mismo formulario de inicio de sesión con una pestaña para seleccionar el tipo.
- Las credenciales se almacenan por separado en la base de datos.
- Por defecto, las credenciales iniciales son:
  - Administrador: `admin123`
  - Custodio: `custodio2026`

### Implementación Técnica

- Las credenciales se guardan en la colección `admin_config` de PocketBase con diferentes keys:
  - `admin_password` para el administrador
  - `custodian_password` para el custodio
- La sesión almacenada en `localStorage` guarda el tipo de usuario autenticado.

## 2. Cambio de Contraseñas

### Funcionalidad

- Tanto el administrador como el custodio pueden cambiar sus propias contraseñas.
- El sistema verifica que la contraseña actual sea correcta antes de permitir el cambio.
- Las nuevas contraseñas deben tener al menos 6 caracteres.

### Proceso de Cambio

1. El usuario hace clic en el botón "Cambiar Contraseña" en el dashboard.
2. Introduce su contraseña actual.
3. Introduce y confirma la nueva contraseña.
4. El sistema verifica y actualiza la contraseña en la base de datos.

### Consideraciones de Seguridad

- Se recomienda cambiar las contraseñas por defecto inmediatamente después de la instalación.
- Solo el tipo de usuario correspondiente puede cambiar su propia contraseña.
- Las sesiones tienen una duración máxima de 4 horas por motivos de seguridad.

## 3. Exportación Directa a USB

### Descripción de la Funcionalidad

El custodio puede exportar los datos del sistema directamente a un dispositivo USB, lo que facilita la portabilidad y revisión de la información.

### Características

- **Detección automática de USB**: El sistema detecta automáticamente cuando se conecta un dispositivo USB.
- **Notificación visual**: Se muestra una barra de estado que indica si hay un dispositivo conectado.
- **Exportación configurable**: Permite seleccionar:
  - Rango de fechas para los datos
  - Tipos de datos a incluir (solicitudes pendientes, llaves entregadas, devueltas, estadísticas, etc.)
- **Exportación directa**: Los datos se guardan directamente en el USB sin pasos intermedios.

### Proceso de Exportación

1. El custodio inicia sesión con sus credenciales.
2. Conecta un dispositivo USB al equipo.
3. El sistema detecta el USB y habilita el botón de exportación.
4. El custodio selecciona el rango de fechas y los datos a exportar.
5. Hace clic en "Exportar a USB" y los datos se guardan directamente en el dispositivo.

### Formato de Archivos Exportados

- Los datos se exportan en formato CSV compatible con Excel.
- Se generan múltiples archivos según la configuración seleccionada:
  - Resumen general
  - Solicitudes pendientes
  - Llaves entregadas
  - Llaves devueltas
  - Estadísticas (si se seleccionó)
  - Datos de usuarios (si se seleccionó)
  - Catálogo de llaves (si se seleccionó)
- Cada archivo incluye metadatos con fecha de generación y otros detalles relevantes.

## 4. Interfaz de Usuario para el Custodio

### Personalización del Dashboard

Para diferenciar claramente el modo custodio del modo administrador, se implementaron las siguientes características visuales:

- **Tema específico**: Fondo ámbar para el encabezado cuando se accede como custodio
- **Iconografía distintiva**: Icono de llave en lugar del icono de gráfica para el custodio
- **Etiqueta de modo**: Se muestra "Modo Custodio" junto a la fecha actual
- **Barra de estado USB**: Muestra el estado de conexión del dispositivo USB

### Elementos Exclusivos

- **Botón de exportación a USB**: Visible solo para el custodio
- **Notificaciones USB**: Avisos específicos sobre el estado de la conexión USB
- **Instrucciones contextuales**: Mensajes que guían al custodio en el proceso de exportación

## 5. Estadísticas con gráficos de torta

### Descripción General

El dashboard ahora cuenta con un panel de estadísticas que muestra gráficos de torta para cada turno, indicando la tasa de devoluciones de llaves. Esta visualización permite evaluar rápidamente qué porcentaje de las llaves entregadas en cada turno fueron devueltas satisfactoriamente.

### Características del Panel Estadístico

- **Gráficos de torta interactivos** para cada turno (Matutino, Vespertino, Nocturno)
- **Códigos de color** para facilitar la interpretación:
  - Verde: Llaves devueltas
  - Rojo: Llaves pendientes de devolución
- **Filtros de tiempo** para visualizar estadísticas en diferentes períodos:
  - Mensual
  - Semestral
  - Anual
- **Indicadores de desempeño** que muestran:
  - Número total de llaves entregadas
  - Número de llaves devueltas
  - Número de llaves pendientes
  - Porcentaje de devolución (con códigos de color según el nivel)

### Métricas de Desempeño

Se implementó un sistema visual con códigos de color para indicar el nivel de desempeño:
- **Verde (≥98%)**: Excelente tasa de devolución
- **Ámbar (90-97.9%)**: Tasa de devolución aceptable
- **Rojo (<90%)**: Tasa de devolución por debajo del estándar esperado

### Beneficios

- Proporciona una visión clara del desempeño de cada turno
- Facilita la identificación de patrones o problemas en la gestión de llaves
- Permite hacer seguimiento de mejoras a través del tiempo
- Ayuda a identificar turnos que podrían necesitar ajustes en sus procedimientos

### Implementación Técnica

- Utiliza la biblioteca Recharts para gráficos interactivos
- Cálculo automático de estadísticas basado en los datos históricos
- Actualización automática de datos cuando se producen cambios en el sistema

## 6. Consideraciones Técnicas

### Arquitectura de la Solución

- **Hook useAdminAuth**: Se amplió para soportar el modo custodio con la propiedad `isCustodian`.
- **Detección de USB**: Se implementó un sistema de polling que verifica periódicamente la conexión de dispositivos USB.
- **Exportación de datos**: Se amplió el sistema existente para permitir la exportación directa al USB.
- **Componente de gráficos**: Se implementó un componente reutilizable que gestiona los diferentes tipos de visualización con Recharts.

### Limitaciones Conocidas

- **Compatibilidad USB**: El sistema detecta dispositivos USB según el API del navegador y el modo kiosk.
- **Navegadores soportados**: La funcionalidad USB depende de las capacidades del navegador y los permisos del sistema.
- **Rendimiento de gráficos**: Con grandes volúmenes de datos, la carga y renderizado de los gráficos podría ser más lenta.

## 7. Guía para Administradores

### Configuración Inicial

1. **Contraseñas**: Cambiar las contraseñas por defecto tanto del administrador como del custodio.
2. **Designación de custodio**: Designar a una persona responsable para el rol de custodio.
3. **Configuración de objetivos**: Establecer objetivos de tasa de devolución para cada turno.

### Recomendaciones de Uso

- **Exportaciones periódicas**: Establecer un calendario para la exportación periódica de los datos.
- **Rotación de contraseñas**: Cambiar las contraseñas periódicamente.
- **Verificación de datos**: Verificar periódicamente la integridad de los datos exportados.
- **Revisión de estadísticas**: Revisar regularmente las estadísticas de devoluciones para identificar tendencias o problemas.
- **Establecer objetivos de desempeño**: Utilizar las estadísticas para establecer metas claras de porcentaje de devoluciones para cada turno.

### Resolución de Problemas Comunes

- **USB no detectado**: Verificar que el dispositivo USB esté formateado adecuadamente (preferentemente FAT32) y tenga suficiente espacio libre.
- **Error en exportación**: Verificar que el dispositivo USB no esté protegido contra escritura y que no esté lleno.
- **Sesión expirada**: La sesión caduca automáticamente después de 4 horas de inactividad. Volver a iniciar sesión.
- **Gráficos no actualizados**: Si los gráficos no reflejan los últimos cambios, intentar recargar la página.

---

## Notas Adicionales

- Esta funcionalidad está diseñada para facilitar la portabilidad de los datos para su revisión por parte de las autoridades.
- La exportación USB se realiza en un formato que garantiza la integridad y facilita la interpretación de los datos.
- Todos los archivos exportados incluyen metadatos que identifican claramente la fuente, la fecha de generación y el custodio que realizó la exportación.
- Los gráficos estadísticos proporcionan una herramienta valiosa para la toma de decisiones operativas y para el establecimiento de estándares de calidad en el servicio.