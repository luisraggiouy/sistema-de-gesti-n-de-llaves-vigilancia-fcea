# Documentación: Sistema de Autorizaciones de Acceso a Llaves

## Introducción

Este documento describe el módulo de **Autorizaciones** del Sistema de Gestión de Llaves de FCEA. Permite a los vigilantes registrar, consultar, gestionar y auditar permisos especiales que habilitan a personas a retirar llaves de lugares específicos.

---

## Índice

1. [Descripción general](#1-descripción-general)
2. [Pestaña Autorizaciones — Verificar y Registrar](#2-pestaña-autorizaciones--verificar-y-registrar)
3. [Pestaña Historial](#3-pestaña-historial)
4. [Modelo de datos](#4-modelo-de-datos)
5. [Persistencia](#5-persistencia)
6. [Reglas de negocio](#6-reglas-de-negocio)
7. [Changelog](#7-changelog)

---

## 1. Descripción General

El módulo de autorizaciones se accede desde **Agenda / Autorizaciones → pestaña Autorizaciones** en la pantalla del Monitor de Vigilancia.

Permite:
- Registrar una autorización que habilita a una persona (por nombre y/o CI) a retirar la llave de un lugar determinado.
- Verificar en tiempo real si una persona está autorizada para un lugar.
- Editar o eliminar autorizaciones vigentes.
- Consultar el historial de autorizaciones vencidas o eliminadas.
- Restablecer autorizaciones eliminadas por error.

---

## 2. Pestaña Autorizaciones — Verificar y Registrar

### Modo Verificar (por defecto)

Al abrir la pestaña, se muestra directamente el **listado completo de autorizaciones vigentes**, ordenadas cronológicamente con la más reciente primero.

Si el vigilante escribe en los campos de búsqueda, el listado se filtra en tiempo real:

| Campo | Descripción |
|-------|-------------|
| Nombre o CI | Busca por nombre completo o número de cédula de identidad (sin puntos ni guiones) |
| Llave / Lugar | Busca por nombre del lugar autorizado |

**Resultado de búsqueda:**
- Verde con ícono de escudo: se encontraron autorizaciones
- ❌ Rojo con ícono de escudo tachado: no hay autorización registrada

Cada tarjeta de autorización muestra:
- Nombre de la persona (y CI si fue registrada)
- Lugar autorizado (badge verde)
- Quién autorizó
- Fecha de autorización
- Vigencia: desde → hasta (si aplica)
- Horario autorizado (si aplica)
- Email de referencia (si aplica)
- Observaciones (si aplica)
- Botones: Editar | Eliminar

### Modo Nueva / Editar

Al hacer clic en **+ Nueva** o en el ícono de edición de una tarjeta, se abre el formulario:

| Campo | Obligatorio | Descripción |
|-------|-------------|-------------|
| Nombre de la persona | | Nombre completo |
| CI | No | Cédula de identidad sin puntos ni guiones |
| Llave / Lugar autorizado | | Nombre del lugar o llave |
| Autorizado por | | Nombre y cargo de quien autoriza (ej: "Director IESTA Juan González") |
| Fecha de autorización | No | Por defecto: fecha actual |
| Email de referencia | No | Correo del autorizante para respaldo |
| Vigencia desde | No | Fecha de inicio de la vigencia |
| Vigencia hasta | No | Fecha de fin de la vigencia (si se establece, la autorización se purga automáticamente al vencer) |
| Horario autorizado | No | Descripción del horario (ej: "Lunes a Viernes de 9 a 18") |
| Observaciones | No | Notas adicionales |

Al guardar, la autorización aparece inmediatamente en el listado.

---

## 3. Pestaña Historial

Muestra todas las autorizaciones que ya no están vigentes, ordenadas por fecha de baja (más reciente primero).

### Tipos de baja

| Tipo | Badge | Color | Descripción |
|------|-------|-------|-------------|
| **Eliminada** | Eliminada | Rojo | El vigilante la eliminó manualmente |
| **Vencida** | Vencida | Amarillo | La fecha de vigencia expiró y fue purgada automáticamente |

### Información mostrada por tarjeta

- Nombre y lugar
- Badge de tipo de baja (Eliminada / Vencida)
- Quién autorizó
- **Vigencia: fechaDesde → fechaHasta** (período original de la autorización)
- Horario, email, observaciones (si aplica)
- **"Eliminada el: DD/MM/AAAA"** o **"Venció el: DD/MM/AAAA"** según corresponda

### Restablecer (solo eliminadas)

Las autorizaciones **eliminadas** tienen un botón **↩ Restablecer** que las devuelve a la lista de vigentes. Las vencidas no pueden restablecerse directamente (deben crearse nuevamente con nueva vigencia).

### Filtros disponibles

- Búsqueda por texto (persona o lugar)
- Filtro por rango de fechas (Desde / Hasta) — filtra por fecha de baja

### Contadores

En el encabezado del historial se muestran badges con el total de eliminadas y vencidas en la vista actual.

---

## 4. Modelo de Datos

### Autorización vigente (`Autorizacion`)

```typescript
interface Autorizacion {
  id: string;                  // Generado automáticamente
  personaNombre: string;       // Nombre completo
  personaCI?: string;          // CI sin puntos ni guiones (opcional)
  lugarAutorizado: string;     // Nombre del lugar/llave
  autorizadoPor: string;       // Nombre y cargo del autorizante
  fechaAutorizacion: string;   // Fecha en que se registró la autorización (YYYY-MM-DD)
  fechaDesde?: string;         // Inicio de vigencia (YYYY-MM-DD, opcional)
  fechaHasta?: string;         // Fin de vigencia (YYYY-MM-DD, opcional)
  horario?: string;            // Descripción del horario (texto libre)
  emailReferencia?: string;    // Email del autorizante
  observaciones?: string;      // Notas adicionales
  fechaCreacion: string;       // ISO timestamp de creación en el sistema
}
```

### Historial (`AutorizacionHistorial`)

Extiende `Autorizacion` con:

```typescript
interface AutorizacionHistorial extends Autorizacion {
  motivoBaja: 'vencida' | 'eliminada';  // Razón por la que salió de vigentes
  fechaBaja: string;                     // ISO timestamp de la baja
}
```

---

## 5. Persistencia

Los datos se almacenan en `localStorage` del navegador:

| Clave | Contenido |
|-------|-----------|
| `fcea_autorizaciones_v1` | Array de autorizaciones vigentes |
| `fcea_historial_autorizaciones_v1` | Array de autorizaciones del historial |

> **Nota:** Al igual que el resto de los datos del sistema (historial de llaves, usuarios registrados, objetos olvidados), las autorizaciones se respaldan automáticamente mediante el mecanismo de respaldo del sistema (backup diario a las 03:00 AM). Ver [`OPERACION.md` § 3](./OPERACION.md#3-backups) y [`guia_mantenimiento_paso_a_paso.md`](./guia_mantenimiento_paso_a_paso.md).

---

## 6. Reglas de Negocio

1. **Purga automática de vencidas**: Al abrir la pestaña Autorizaciones, el sistema verifica si alguna autorización con `fechaHasta` ya expiró. Las vencidas se mueven automáticamente al historial con `motivoBaja: 'vencida'`.

2. **Búsqueda por CI**: La búsqueda acepta tanto nombre como número de CI. Esto permite verificar rápidamente si una persona que se presenta con su documento está autorizada.

3. **Restablecer solo eliminadas**: Las autorizaciones vencidas no se pueden restablecer directamente (su vigencia ya expiró). Deben crearse nuevamente con una nueva fecha de vigencia.

4. **Orden cronológico inverso**: Tanto el listado de vigentes como el historial muestran primero el registro más reciente.

5. **Campos obligatorios**: Nombre de la persona, lugar autorizado y quién autoriza son los únicos campos requeridos. El resto es opcional para mayor flexibilidad.

---

## 7. Changelog

### v5.1 — 05/05/2026
- **fix**: Implementadas todas las funciones de autorizaciones con `localStorage` (`guardarAutorizacion`, `eliminarAutorizacion`, `buscarAutorizacionEnVivo`, `getAutorizaciones`, `getHistorialAutorizaciones`, `purgarAutorizacionesVencidas`). Anteriormente eran stubs que no hacían nada.
- **feat**: El listado de autorizaciones vigentes se muestra directamente al abrir la pestaña (sin necesidad de buscar), ordenado por más reciente primero.
- **feat**: Historial mejorado: vigencia mostrada como `fechaDesde → fechaHasta`, badges diferenciados (Eliminada en rojo / Vencida en amarillo), etiqueta de fecha de baja contextual ("Eliminada el:" / "Venció el:").
- **feat**: Botón **↩ Restablecer** en autorizaciones eliminadas del historial. Mueve la autorización de vuelta a vigentes.
- **feat**: Función `restablecerAutorizacion(id)` en `fceaData.ts`.
- **feat**: Contadores de eliminadas/vencidas en el encabezado del historial.
