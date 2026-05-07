# Documentacion: Dashboard de Estadisticas y Exportacion a Pendrive

## Introduccion

Este documento describe el funcionamiento del Dashboard de Actividad del Sistema de Gestion de Llaves de FCEA. El Dashboard es visible para todos sin contrasena. La contrasena solo se requiere para exportar datos a un pendrive USB.

## Indice

1. [Acceso al Dashboard](#1-acceso-al-dashboard)
2. [Exportacion a pendrive](#2-exportacion-a-pendrive)
3. [Cambio de contrasena de exportacion](#3-cambio-de-contrasena-de-exportacion)
4. [Estadisticas con graficos de torta](#4-estadisticas-con-graficos-de-torta)
5. [Consideraciones tecnicas](#5-consideraciones-tecnicas)

## 1. Acceso al Dashboard

### Descripcion General

El Dashboard es accesible para todos sin necesidad de contrasena. Cualquier persona frente a la pantalla puede ver:

- Graficas de actividad por turno (matutino, vespertino, nocturno)
- Estadisticas de entregas y devoluciones de llaves
- Actividad reciente (ultimas 30 operaciones)
- Estado de objetos olvidados
- Estadisticas avanzadas con graficos de barras y torta

### Como acceder

URL directa: `http://localhost:8080/dashboard`

Tambien desde el Monitor de Vigilancia: boton "Dashboard" en la esquina superior.

El Dashboard se abre directamente sin pedir contrasena.

## 2. Exportacion a Pendrive

### Descripcion de la Funcionalidad

La exportacion de datos a pendrive requiere una contrasena. Esto protege que cualquier persona pueda llevarse los datos del sistema.

Solo las personas autorizadas (jefes de turno, jefes de apoyo, intendencia, autoridades) conocen la contrasena de exportacion.

### Proceso de Exportacion

1. Conectar un pendrive comun al puerto USB del equipo.
2. El sistema detecta el pendrive automaticamente y muestra una barra verde.
3. Hacer clic en "Exportar a Pendrive" en el encabezado del Dashboard.
4. Ingresar la contrasena de exportacion (por defecto: `custodio2026`).
5. Seleccionar el rango de fechas y los datos a incluir.
6. Hacer clic en "Exportar a USB".
7. Los datos se guardan directamente en el pendrive.
8. Cuando aparece el mensaje de confirmacion, se puede retirar el pendrive.

### Contrasena por defecto

`custodio2026`

Se recomienda cambiarla inmediatamente despues de la instalacion.

### Caracteristicas de la Exportacion

- Deteccion automatica de USB: el sistema detecta cuando se conecta un pendrive.
- Notificacion visual: barra de estado que indica si hay un dispositivo conectado (verde) o no (ambar).
- Exportacion configurable: permite seleccionar rango de fechas y tipos de datos.
- Compatible con modo kiosk: no requiere salir del modo kiosk ni acceder a carpetas del sistema.
- Pendrive comun: funciona con cualquier pendrive estandar (FAT32 o NTFS), sin software especial.

### Formato de Archivos Exportados

- Los datos se exportan en formato CSV compatible con Excel.
- Se generan multiples archivos segun la configuracion seleccionada:
  - Resumen general
  - Solicitudes pendientes
  - Llaves entregadas
  - Llaves devueltas
  - Estadisticas (si se selecciono)
  - Usuarios registrados (si se selecciono)
  - Catalogo de llaves (si se selecciono)
  - Objetos olvidados (si se selecciono)
  - Autorizaciones (si se selecciono)

## 3. Cambio de Contrasena de Exportacion

### Funcionalidad

Cualquier persona que conozca la contrasena actual puede cambiarla desde el boton "Cambiar Contrasena Exportacion" en el encabezado del Dashboard.

### Proceso de Cambio

1. Hacer clic en "Cambiar Contrasena Exportacion" en el encabezado del Dashboard.
2. Ingresar la contrasena actual.
3. Ingresar la nueva contrasena (minimo 6 caracteres).
4. Confirmar la nueva contrasena.
5. El sistema actualiza la contrasena en la base de datos.

### Consideraciones de Seguridad

- Se recomienda cambiar la contrasena por defecto inmediatamente despues de la instalacion.
- Cambiar la contrasena cada vez que un jefe de turno deje su cargo.
- Las contrasenas por defecto se restablecen automaticamente cada vez que se restaura el sistema con el pendrive restaurador.

## 4. Estadisticas con Graficos de Torta

### Descripcion General

El Dashboard cuenta con un panel de estadisticas que muestra graficos de torta para cada turno, indicando la tasa de devoluciones de llaves.

### Caracteristicas del Panel Estadistico

- Graficos de torta interactivos para cada turno (Matutino, Vespertino, Nocturno)
- Codigos de color para facilitar la interpretacion:
  - Verde: Llaves devueltas
  - Rojo: Llaves pendientes de devolucion
- Filtros de tiempo para visualizar estadisticas en diferentes periodos:
  - Hoy
  - Mensual
  - Semestral
- Indicadores de desempeno que muestran:
  - Numero total de llaves entregadas
  - Numero de llaves devueltas
  - Numero de llaves pendientes
  - Porcentaje de devolucion (con codigos de color segun el nivel)

### Metricas de Desempeno

- Verde (mayor o igual a 98%): Excelente tasa de devolucion
- Ambar (90-97.9%): Tasa de devolucion aceptable
- Rojo (menor a 90%): Tasa de devolucion por debajo del estandar esperado

## 5. Consideraciones Tecnicas

### Arquitectura de la Solucion

- El Dashboard no requiere autenticacion para visualizacion.
- La autenticacion se realiza unicamente en el modal de exportacion, al momento de exportar.
- La contrasena de exportacion se almacena en la coleccion `admin_config` de PocketBase con la clave `custodian_password`.
- La deteccion de USB se implementa mediante un sistema de polling que verifica periodicamente la conexion de dispositivos.
- Los graficos utilizan la biblioteca Recharts para visualizaciones interactivas.

### Limitaciones Conocidas

- Compatibilidad USB: el sistema detecta dispositivos USB segun el API del navegador y el modo kiosk.
- Navegadores soportados: la funcionalidad USB depende de las capacidades del navegador y los permisos del sistema.
- Rendimiento de graficos: con grandes volumenes de datos, la carga y renderizado de los graficos podria ser mas lenta.

### Resolucion de Problemas Comunes

- USB no detectado: verificar que el dispositivo USB este formateado adecuadamente (FAT32 o NTFS) y tenga suficiente espacio libre.
- Error en exportacion: verificar que el dispositivo USB no este protegido contra escritura y que no este lleno.
- Contrasena incorrecta: verificar que se este usando la contrasena correcta. Si se olvido, restablecer desde PocketBase (coleccion `admin_config`, clave `custodian_password`).
- Graficos no actualizados: si los graficos no reflejan los ultimos cambios, intentar recargar la pagina.

---

*Ultima actualizacion: 06/05/2026 — v5.5*
*Documento preparado para archivo y custodia autoridades de FCEA.*
