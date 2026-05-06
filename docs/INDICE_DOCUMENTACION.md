# 📚 ÍNDICE COMPLETO DE DOCUMENTACIÓN
## Sistema de Gestión de Llaves — FCEA

**Última actualización:** Mayo 2026  
**Versión del sistema:** 5.1

---

##  Resumen de Documentos

Este índice organiza toda la documentación del sistema en categorías para facilitar su consulta.

---

##  INSTALACIÓN Y CONFIGURACIÓN INICIAL

### 0. **instructivo_instalacion_paso_a_paso.md** ⭐ NUEVO - EMPEZAR AQUÍ
   - **Propósito**: Guía ultra-simplificada para instalar el sistema
   - **Cuándo usar**: Primera instalación del sistema
   - **Contenido clave**:
     - Explicado paso a paso como para un niño
     - Instalación con pendrive autorun (doble clic y listo)
     - Recuperación del sistema
     - Solución de problemas comunes
     - **Recomendado para**: Personal sin conocimientos técnicos

### 1. **INSTRUCCIONES_RAPIDAS_PENDRIVES.md**  REFERENCIA RÁPIDA
   - **Propósito**: Guía rápida para grabar los pendrives de instalación
   - **Cuándo usar**: Antes de instalar el sistema por primera vez
   - **Contenido clave**:
     - Cómo grabar pendrive instalador (16 GB)
     - Cómo grabar pendrive de recuperación (8 GB)
     - Configuración de hardware (táctil vs tradicional)
     - Proceso de instalación paso a paso

### 2. **preparacion_pendrives_instalacion.md**
   - **Propósito**: Documentación completa del sistema de pendrives
   - **Cuándo usar**: Para entender en detalle el sistema de instalación
   - **Contenido clave**:
     - Características de ambos pendrives
     - Diagramas de conexión física
     - Proceso de instalación automática (10 pasos)
     - Proceso de recuperación
     - Checklists de verificación
     - Solución de problemas

### 3. **SOLUCION_INICIO_AUTOMATICO.md** ⭐ CRÍTICO PARA PRODUCCIÓN
   - **Propósito**: Configuración de inicio automático al arrancar Windows
   - **Cuándo usar**: INMEDIATAMENTE después de instalar el sistema
   - **Contenido clave**:

### 3.1. **SOLUCION_PROBLEMA_REINICIO.md** 🔴 NUEVO - SOLUCIÓN URGENTE
   - **Propósito**: Solución cuando el sistema no inicia después de reiniciar
   - **Cuándo usar**: Si después de reiniciar la PC el sistema no está disponible
   - **Contenido clave**:
     - Diagnóstico del problema (inicio automático no configurado)
     - Solución inmediata: Script INICIAR_SISTEMA_AHORA.bat
     - Solución permanente: Configurar inicio automático
     - Verificación del sistema
     - Troubleshooting completo
   - **Archivos relacionados**:
     - `INICIAR_SISTEMA_AHORA.bat` - Inicia el sistema manualmente
     - `CONFIGURAR_INICIO_DEFINITIVO.bat` ⭐ NUEVO - Menú interactivo (simple o avanzado)
     - `CONFIGURAR_INICIO_AUTOMATICO_DEFINITIVO.bat` - Configura inicio automático avanzado
     - `LEEME_SOLUCION_REINICIO.txt` - Instrucciones rápidas
     - Problema: Sistema no se inicia automáticamente
     - Solución: Tarea programada de Windows + Watchdog
     - Configuración paso a paso
     - Triple protección: Inicio automático + Watchdog PocketBase + Watchdog Frontend
     - Comandos útiles y troubleshooting
     - **CRÍTICO**: Evita que el sistema quede caído en producción

### 4. **configuracion_produccion.md**
   - **Propósito**: Configuración del sistema para ambiente de producción
   - **Cuándo usar**: Después de instalar, antes de poner en producción
   - **Contenido clave**:
     - Configuración de modo kiosk
     - Configuración de pantallas múltiples
     - Seguridad y permisos
     - Optimización de rendimiento

### 4. **teclado_tactil_configuracion.md**
   - **Propósito**: Configuración del teclado virtual para pantallas táctiles
   - **Cuándo usar**: Si se usan pantallas táctiles
   - **Contenido clave**:
     - Habilitación del teclado táctil de Windows
     - Configuración de diccionario personalizado
     - Ajustes de sensibilidad
     - Solución de problemas

---

##  OPERACIÓN Y USO DIARIO

### 5. **instructivo_acceso_dashboard.md**  PARA USUARIOS
   - **Propósito**: Guía para acceder y usar el dashboard de estadísticas
   - **Audiencia**: Vigilantes, Custodios, Administradores
   - **Cuándo usar**: Para consultar estadísticas del sistema
   - **Contenido clave**:
     - Roles y permisos (Vigilantes SÍ pueden ver, NO pueden exportar)
     - Cómo acceder al dashboard
     - Cómo exportar reportes (solo Administrador/Custodio)
     - Exportación a pendrive (modo kiosk)
     - Cierre de sesión automático (5 minutos)

### 6. **funcionalidad_administracion_custodio.md**
   - **Propósito**: Funcionalidades del rol Administrador y Custodio
   - **Audiencia**: Intendente (Administrador), Jefes de Apoyo y Turno (Custodios)
   - **Cuándo usar**: Para entender qué puede hacer cada rol
   - **Contenido clave**:
     - Administrador: Intendente
     - Custodios: Jefes de Apoyo y Jefes de Turno
     - Permisos y funcionalidades de cada rol
     - Exportación de datos
     - Gestión de usuarios

### 6b. **funcionalidad_autorizaciones.md** ⭐ NUEVO Mayo 2026
   - **Propósito**: Documentación completa del módulo de Autorizaciones
   - **Audiencia**: Vigilantes, Jefes de Turno, Personal de Sistemas
   - **Cuándo usar**: Para entender cómo registrar, verificar y gestionar autorizaciones de acceso a llaves
   - **Contenido clave**:
     - Cómo registrar una autorización (campos obligatorios y opcionales)
     - Búsqueda en tiempo real por nombre o CI
     - Historial: diferencia entre eliminadas y vencidas
     - Cómo restablecer una autorización eliminada
     - Modelo de datos y persistencia en localStorage
     - Reglas de negocio (purga automática de vencidas, etc.)

### 7. **estadisticas_avanzadas.md**
   - **Propósito**: Guía de uso de estadísticas y reportes
   - **Audiencia**: Administradores y Custodios
   - **Cuándo usar**: Para análisis de datos del sistema
   - **Contenido clave**:
     - Tipos de gráficos disponibles
     - Filtros y rangos de fechas
     - Interpretación de estadísticas
     - Exportación de reportes

---

##  MANTENIMIENTO Y SOPORTE

### 8. **guia_mantenimiento_paso_a_paso.md**  IMPORTANTE
   - **Propósito**: Procedimientos detallados de mantenimiento
   - **Audiencia**: Encargado designado, Jefes de Vigilancia, Sistemas 
   - **Cuándo usar**: Para mantenimiento mensual, trimestral y anual
   - **Contenido clave**:
     - Cómo salir del modo kiosk
     - Mantenimiento mensual (6 pasos)
     - Mantenimiento trimestral (5 pasos)
     - Mantenimiento anual (3 pasos)
     - Resolución de problemas comunes
     - Checklists de mantenimiento

### 9. **funcionamiento_respaldos_automaticos.md**
   - **Propósito**: Sistema de respaldos automáticos
   - **Cuándo usar**: Para entender el sistema de respaldos
   - **Contenido clave**:
     - Respaldos semanales automáticos (Domingos 8 AM)
     - Ubicación de respaldos
     - Restauración desde respaldos
     - Verificación de integridad

### 10. **configuracion_mantenimiento_automatizado.md**
   - **Propósito**: Configuración del mantenimiento automático
   - **Cuándo usar**: Durante la instalación o para reconfigurar
   - **Contenido clave**:
     - Tareas programadas de Windows
     - Scripts de mantenimiento
     - Logs y monitoreo
     - Notificaciones

### 11. **procedimiento_reinstalacion_sistema.md**
   - **Propósito**: Reinstalación completa del sistema
   - **Cuándo usar**: Si el sistema falla completamente
   - **Contenido clave**:
     - Cuándo reinstalar vs recuperar
     - Respaldo de datos antes de reinstalar
     - Proceso de reinstalación
     - Restauración de datos
     - Contraseñas por defecto después de reinstalar

---

##  ACTUALIZACIONES Y MODIFICACIONES

### 12. **plan_actualizaciones_mantenimiento.md**
   - **Propósito**: Plan de actualizaciones del sistema
   - **Audiencia**: Sistemas, Autoridades, quien se designe
   - **Cuándo usar**: Para planificar actualizaciones
   - **Contenido clave**:
     - Calendario de actualizaciones
     - Tipos de actualizaciones
     - Proceso de actualización
     - Rollback en caso de problemas

### 13. **procedimiento_modificaciones_produccion.md**
   - **Propósito**: Cómo hacer cambios en producción
   - **Cuándo usar**: Antes de hacer cualquier cambio en producción
   - **Contenido clave**:
     - Proceso de aprobación de cambios
     - Respaldo antes de cambios
     - Pruebas en ambiente de desarrollo
     - Implementación en producción
     - Documentación de cambios

---

##  SOLUCIÓN DE PROBLEMAS

### 14. **resolucion_error_cors.md**
   - **Propósito**: Solución de errores CORS
   - **Cuándo usar**: Si aparecen errores CORS en el navegador
   - **Contenido clave**:
     - Qué es un error CORS
     - Causas comunes
     - Soluciones paso a paso
     - Scripts de corrección automática

---

## COMPATIBILIDAD Y REQUISITOS

### 15. **compatibilidad_navegadores.md**
   - **Propósito**: Navegadores compatibles con el sistema
   - **Cuándo usar**: Durante la instalación o si hay problemas de compatibilidad
   - **Contenido clave**:
     - Navegadores soportados (Chrome recomendado)
     - Versiones mínimas
     - Configuraciones recomendadas
     - Problemas conocidos por navegador

---

##  DOCUMENTACIÓN TÉCNICA Y ADMINISTRATIVA

### 16. **SRS_Sistema_Gestion_Llaves_FCEA.md**
   - **Propósito**: Especificación de Requisitos del Software
   - **Audiencia**: Desarrolladores, Personal de Sistemas, Autoridades
   - **Cuándo usar**: Para entender la arquitectura completa del sistema
   - **Contenido clave**:
     - Requisitos funcionales
     - Requisitos no funcionales
     - Casos de uso
     - Arquitectura del sistema
     - Modelo de datos

### 17. **entrega_codigo_fuente.md**
   - **Propósito**: Documentación de entrega del código fuente
   - **Audiencia**: Autoridades
   - **Cuándo usar**: Para auditorías o transferencia de conocimiento
   - **Contenido clave**:
     - Estructura del proyecto
     - Tecnologías utilizadas
     - Repositorio de código
     - Licencias
     - Contactos

### 18. **presentacion_autoridades.md**
   - **Propósito**: Documento de presentación oficial
   - **Audiencia**: Autoridades de FCEA
   - **Cuándo usar**: Para presentaciones oficiales
   - **Contenido clave**:
     - Resumen ejecutivo del sistema
     - Beneficios y características
     - Costos y recursos
     - Cronograma de implementación
     - **Pie de página**: "Documento preparado para archivo y custodia autoridades de FCEA"

---

## RESUMEN POR AUDIENCIA

### Para Personal de Sistemas o personal idóneo designado:
1.  **INSTRUCCIONES_RAPIDAS_PENDRIVES.md** (empezar aquí)
2. preparacion_pendrives_instalacion.md
3. configuracion_produccion.md
4. guia_mantenimiento_paso_a_paso.md
5. funcionamiento_respaldos_automaticos.md
6. procedimiento_reinstalacion_sistema.md
7. resolucion_error_cors.md
8. compatibilidad_navegadores.md

### Para Vigilantes:
1.  **instructivo_acceso_dashboard.md** (pueden VER dashboard, NO exportar)

### Para Custodios (Jefes de Apoyo y Turno):
1. instructivo_acceso_dashboard.md (pueden ver Y exportar)
2. funcionalidad_administracion_custodio.md
3. estadisticas_avanzadas.md

### Para Administrador (Intendente):
1. Todos los documentos de Custodios
2. funcionalidad_administracion_custodio.md (permisos completos)
3. plan_actualizaciones_mantenimiento.md
4. procedimiento_modificaciones_produccion.md

### Para Autoridades:
1. presentacion_autoridades.md
2. SRS_Sistema_Gestion_Llaves_FCEA.md
3. entrega_codigo_fuente.md

---



##  Soporte y Contacto

Para consultas sobre la documentación:
- Revisar este índice primero
- Consultar el documento específico según la necesidad
- Autor Luis Raggio 099600873 luisraggiouy@gmail.com

---

##  Control de Versiones

Todos los documentos están versionados en GitHub, y se hace entrega de copia en pendrive a autoridades de FCEA:
- Repositorio: https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea
- Última actualización: 06/05/2026 — v5.3 CSV exportable incluye Rol y Estado de licencia por vigilante; sección "PERSONAL EN LICENCIA" automática

---

*Documento preparado para archivo y custodia autoridades de FCEA.*
