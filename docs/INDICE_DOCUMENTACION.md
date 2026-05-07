# Índice de Documentación — Sistema de Gestión de Llaves FCEA

> **Versión del sistema:** 5.3 — Mayo 2026  
> **Repositorio:** https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea

---

## Documentos por Categoría

### Acceso y Credenciales
| Documento | Descripción |
|-----------|-------------|
| [credenciales_sistema.md](credenciales_sistema.md) | Contraseñas de PocketBase, Monitor (Admin y Custodio). **Leer primero.** |

---

### Instalación y Puesta en Marcha
| Documento | Descripción |
|-----------|-------------|
| [instructivo_instalacion_paso_a_paso.md](instructivo_instalacion_paso_a_paso.md) | Guía completa de instalación desde cero en un equipo nuevo. |
| [preparacion_pendrives_instalacion.md](preparacion_pendrives_instalacion.md) | Cómo preparar los pendrives Instalador y Recuperación. |
| [INSTRUCCIONES_RAPIDAS_PENDRIVES.md](INSTRUCCIONES_RAPIDAS_PENDRIVES.md) | Versión resumida y rápida para preparar los pendrives. |
| [configuracion_produccion.md](configuracion_produccion.md) | Configuración del entorno de producción (puertos, variables, inicio automático). |

---

### Uso del Sistema
| Documento | Descripción |
|-----------|-------------|
| [instructivo_acceso_dashboard.md](instructivo_acceso_dashboard.md) | Cómo acceder y usar el Dashboard de estadísticas. |
| [funcionalidad_administracion_custodio.md](funcionalidad_administracion_custodio.md) | Funciones del panel de administración y del modo Custodio. |
| [funcionalidad_autorizaciones.md](funcionalidad_autorizaciones.md) | Sistema de autorizaciones especiales de acceso. |
| [estadisticas_avanzadas.md](estadisticas_avanzadas.md) | Gráficas avanzadas, filtros por período y exportación de reportes. |

---

### Mantenimiento y Operación
| Documento | Descripción |
|-----------|-------------|
| [guia_mantenimiento_paso_a_paso.md](guia_mantenimiento_paso_a_paso.md) | Tareas de mantenimiento rutinario del sistema. |
| [plan_actualizaciones_mantenimiento.md](plan_actualizaciones_mantenimiento.md) | Calendario y procedimiento para actualizaciones. |
| [configuracion_mantenimiento_automatizado.md](configuracion_mantenimiento_automatizado.md) | Configuración del watchdog y tareas automáticas. |
| [funcionamiento_respaldos_automaticos.md](funcionamiento_respaldos_automaticos.md) | Cómo funcionan los respaldos automáticos de la base de datos. |
| [procedimiento_modificaciones_produccion.md](procedimiento_modificaciones_produccion.md) | Cómo aplicar cambios al sistema en producción sin interrumpir el servicio. |

---

### Solución de Problemas
| Documento | Descripción |
|-----------|-------------|
| [procedimiento_reinstalacion_sistema.md](procedimiento_reinstalacion_sistema.md) | Pasos para reinstalar el sistema completo desde cero. |
| [resolucion_pantalla_en_blanco_watchdog.md](resolucion_pantalla_en_blanco_watchdog.md) | ⭐ **NUEVO** Solución al error crítico de pantalla en blanco causado por el watchdog al reiniciar la PC. |
| [SOLUCION_PROBLEMA_REINICIO_5_MAYO.md](SOLUCION_PROBLEMA_REINICIO_5_MAYO.md) | Solución al problema de inicio automático tras reinicio del equipo. |
| [SOLUCION_ERROR_404_PUERTO_INCORRECTO.md](SOLUCION_ERROR_404_PUERTO_INCORRECTO.md) | Solución al error 404 por puerto incorrecto. |
| [SOLUCION_ERROR_PUERTO_8080.md](SOLUCION_ERROR_PUERTO_8080.md) | Solución cuando el puerto 8080 está ocupado. |
| [resolucion_error_cors.md](resolucion_error_cors.md) | Solución a errores CORS entre el frontend y PocketBase. |
| [PROBLEMA_PERMISOS_ADMINISTRADOR.md](PROBLEMA_PERMISOS_ADMINISTRADOR.md) | Solución a problemas de permisos al ejecutar scripts. |

---

### Documentación Técnica
| Documento | Descripción |
|-----------|-------------|
| [SRS_Sistema_Gestion_Llaves_FCEA.md](SRS_Sistema_Gestion_Llaves_FCEA.md) | Especificación de Requisitos del Software (SRS) completa. |
| [entrega_codigo_fuente.md](entrega_codigo_fuente.md) | Descripción del código fuente entregado y su estructura. |
| [compatibilidad_navegadores.md](compatibilidad_navegadores.md) | Navegadores compatibles y configuración recomendada. |

---

### Presentación a Autoridades
| Documento | Descripción |
|-----------|-------------|
| [presentacion_autoridades.md](presentacion_autoridades.md) | Resumen ejecutivo del sistema para presentar a las autoridades de FCEA. |

---

## Estructura del Repositorio

```
sistema-de-gestion-de-llaves-vigilancia-fcea/
├── src/                    — Código fuente del frontend (React + TypeScript)
├── pocketbase/             — Base de datos y ejecutable PocketBase
│   ├── pocketbase.exe      — Servidor de base de datos
│   ├── pb_data/            — Datos de la base de datos (NO borrar)
│   └── pb_migrations/      — Migraciones de esquema
├── public/                 — Archivos estáticos
├── scripts/                — Scripts de instalación, mantenimiento y watchdog
├── docs/                   — Toda la documentación (este directorio)
├── iniciar_sistema.bat     — Arrancar el sistema manualmente
├── INICIAR_SISTEMA_AHORA.bat — Arrancar el sistema (alternativo)
└── README.md               — Descripción general del proyecto
```

---

## Inicio Rápido

### Arrancar el sistema
```
Doble clic en: iniciar_sistema.bat
```
Luego abrir en el navegador:
- Monitor de Vigilancia: http://localhost:8080/monitor
- Terminal de Usuario: http://localhost:8080/terminal
- Dashboard: http://localhost:8080/dashboard
- Admin PocketBase: http://localhost:8090/_/

### Si el sistema no arranca
Ver: [SOLUCION_PROBLEMA_REINICIO_5_MAYO.md](SOLUCION_PROBLEMA_REINICIO_5_MAYO.md)

---

*Última actualización: 07/05/2026 — v5.4 (fix pantalla en blanco watchdog)*  
*Contacto técnico: Luis Raggio — luisraggiouy@gmail.com — 099 600 873*
