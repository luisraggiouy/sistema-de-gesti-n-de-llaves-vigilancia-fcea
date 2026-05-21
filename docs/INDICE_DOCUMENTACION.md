# Índice de documentación – v2.0

## 🆕 Documentación principal (v2.0)

| Documento                                       | Para qué sirve                                   |
|-------------------------------------------------|--------------------------------------------------|
| [`ARQUITECTURA.md`](./ARQUITECTURA.md)          | Topología de red, roles, modos de configuración  |
| [`INSTALACION.md`](./INSTALACION.md)            | Despliegue paso a paso (1 PC o 3 PCs)            |
| [`OPERACION.md`](./OPERACION.md)                | Día a día: encendido, backups, watchdog, troubleshooting |

## 🔐 Funcionalidades y seguridad

| Documento                                                                   | Contenido                                  |
|-----------------------------------------------------------------------------|--------------------------------------------|
| [`credenciales_sistema.md`](./credenciales_sistema.md)                       | Usuarios admin, claves por defecto         |
| [`seguridad_identificacion_usuarios.md`](./seguridad_identificacion_usuarios.md) | Política de identificación de usuarios |
| [`funcionalidad_autorizaciones.md`](./funcionalidad_autorizaciones.md)       | Flujo de autorizaciones                    |

## 📊 Reportes y datos

| Documento                                                          | Contenido                            |
|--------------------------------------------------------------------|--------------------------------------|
| [`estadisticas_avanzadas.md`](./estadisticas_avanzadas.md)         | Gráficos avanzados del Dashboard     |
| [`instructivo_acceso_dashboard.md`](./instructivo_acceso_dashboard.md) | Cómo entrar al Dashboard         |

## 🛠️ Mantenimiento y continuidad

| Documento                                                                   | Contenido                                        |
|-----------------------------------------------------------------------------|--------------------------------------------------|
| [`plan_recuperacion_desastres.md`](./plan_recuperacion_desastres.md)        | **DRP**: reconstrucción del sistema ante incendio/robo/falla total (RTO 3h, RPO 7 días) |
| [`mantenimiento_resumen_ejecutivo.md`](./mantenimiento_resumen_ejecutivo.md) | Resumen técnico del esquema de mantenimiento (capas automática, auto-diagnóstico y recuperación) |
| [`guia_mantenimiento_paso_a_paso.md`](./guia_mantenimiento_paso_a_paso.md)   | Procedimientos manuales detallados (referencia ante alertas) |
| [`checklist_prueba_pendrives.md`](./checklist_prueba_pendrives.md)           | Plan de pruebas de los 3 pendrives + desinstalador |

## 📋 Otros

| Documento                                                | Contenido                                       |
|----------------------------------------------------------|-------------------------------------------------|
| [`SRS_Sistema_Gestion_Llaves_FCEA.md`](./SRS_Sistema_Gestion_Llaves_FCEA.md) | Documento SRS (especificación) |
| [`presentacion_autoridades.md`](./presentacion_autoridades.md) | Presentación para autoridades             |

---

> **Nota sobre v1.x:** La documentación de la arquitectura monolítica
> (instalación en 1 sola PC con kiosk dual) quedó **obsoleta** y fue removida
> en v2.0. Para acceder a ella, ver el tag `v1.0-monolitico-pre-3pc` del
> repositorio en GitHub.
