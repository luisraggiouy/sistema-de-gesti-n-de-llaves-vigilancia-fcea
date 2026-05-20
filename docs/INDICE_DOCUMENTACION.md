# Índice de Documentación — Sistema de Gestión de Llaves FCEA

> **Versión del sistema:** 6.0 — Mayo 2026  
> **Repositorio:** https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea

---

## Documentos por Categoría

### Acceso y Credenciales
| Documento | Descripción |
|-----------|-------------|
| [credenciales_sistema.md](credenciales_sistema.md) | Contraseñas de PocketBase, Monitor (Admin y Custodio). **Leer primero.** |

---

### Instalación y Pendrives — **v2 (vigente)**
| Documento | Descripción |
|-----------|-------------|
| [pendrives_v2_GUIA_DEFINITIVA.md](pendrives_v2_GUIA_DEFINITIVA.md) | ⭐ **Guía única y definitiva** para instalar, reinstalar, reparar y desinstalar el sistema desde los pendrives v2.0. |
| [install_config_schema.md](install_config_schema.md) | Esquema y API del archivo `install_config.json` (modo + hardware). |
| [configuracion_produccion.md](configuracion_produccion.md) | Configuración del entorno de producción (puertos, variables, inicio automático). |

---

### Uso del Sistema
| Documento | Descripción |
|-----------|-------------|
| [instructivo_acceso_dashboard.md](instructivo_acceso_dashboard.md) | Cómo acceder y usar el Dashboard de estadísticas (pestaña dentro del Monitor de Vigilancia). |
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
| [pendrives_v2_GUIA_DEFINITIVA.md](pendrives_v2_GUIA_DEFINITIVA.md) | Sección 4 → casos de instalación rota o cambio de hardware. |
| [resolucion_pantalla_en_blanco_watchdog.md](resolucion_pantalla_en_blanco_watchdog.md) | Solución al error de pantalla en blanco causado por el watchdog. |
| [resolucion_error_cors.md](resolucion_error_cors.md) | Solución a errores CORS entre el frontend y PocketBase. |

---

### Documentación Técnica
| Documento | Descripción |
|-----------|-------------|
| [SRS_Sistema_Gestion_Llaves_FCEA.md](SRS_Sistema_Gestion_Llaves_FCEA.md) | Especificación de Requisitos del Software (SRS) completa. |
| [entrega_codigo_fuente.md](entrega_codigo_fuente.md) | Descripción del código fuente entregado y su estructura. |
| [compatibilidad_navegadores.md](compatibilidad_navegadores.md) | Navegadores compatibles y configuración recomendada. |
| [seguridad_identificacion_usuarios.md](seguridad_identificacion_usuarios.md) | Seguridad e identificación de usuarios. |
| [modo_kiosk_instrucciones.md](modo_kiosk_instrucciones.md) | Modo kiosk de Chrome. |

---

### Presentación a Autoridades
| Documento | Descripción |
|-----------|-------------|
| [presentacion_autoridades.md](presentacion_autoridades.md) | Resumen ejecutivo del sistema para presentar a las autoridades de FCEA. |

---

## Estructura del Repositorio

```
sistema-de-gesti-n-de-llaves-vigilancia-fcea/
├── src/                    — Código fuente del frontend (React + TypeScript)
├── pocketbase/             — Base de datos y ejecutable PocketBase
│   ├── pocketbase.exe      — Servidor de base de datos
│   ├── pb_data/            — Datos de la base de datos (NO borrar)
│   └── pb_migrations/      — Migraciones de esquema
├── public/                 — Archivos estáticos
├── scripts/
│   ├── lib/                — Librerías comunes (hardware, kiosk, config v2)
│   ├── respaldo_recuperacion/   — Scripts del pendrive recuperador
│   ├── instalador_automatico/   — Scripts del pendrive instalador
│   ├── DESINSTALAR_SISTEMA_LIMPIO.ps1
│   └── …
├── docs/                   — Toda la documentación (este directorio)
├── ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1   — Sincroniza el pendrive recuperador
├── iniciar_sistema.bat     — Arrancar el sistema manualmente
└── README.md               — Descripción general del proyecto
```

---

## Inicio Rápido

### Arrancar el sistema
```
Doble clic en: iniciar_sistema.bat
```
Luego abrir en el navegador (URL únicas para el kiosk):
- Monitor de Vigilancia: <http://localhost:8080/monitor>
- Terminal de Usuario:    <http://localhost:8080/terminal>
- Admin PocketBase:       <http://localhost:8090/_/>

> El **Dashboard** de estadísticas no es una URL aparte: es una pestaña dentro del Monitor de Vigilancia.

### Si el sistema no arranca
Ver: [pendrives_v2_GUIA_DEFINITIVA.md](pendrives_v2_GUIA_DEFINITIVA.md) §4 (Caso B).

---

*Última actualización: 13/05/2026 — v6.0 (pendrives v2.0 con flujo inteligente y desinstalador unificado)*  
*Contacto técnico: Luis Raggio — luisraggiouy@gmail.com — 099 600 873*
