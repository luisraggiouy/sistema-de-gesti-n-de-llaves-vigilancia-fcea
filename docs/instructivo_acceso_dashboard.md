# 📊 INSTRUCTIVO: Acceso al Dashboard de Estadísticas
## Sistema de Gestión de Llaves — FCEA

**Versión:** 1.0  
**Fecha:** Abril 2026  
**Destinatarios:** Autoridades de la Facultad, Jefes de Vigilancia habilitados

---

## 1. ¿Qué es el Dashboard?

El **Dashboard** (Panel de Estadísticas) es una pantalla especial del sistema que muestra información resumida sobre el uso de llaves en la Facultad: cuántas llaves se prestaron, a quién, en qué horarios, qué salones son los más solicitados, etc.

Esta información es **confidencial** y solo puede ser consultada por personas autorizadas.

---

## 2. ¿Quiénes pueden acceder?

El sistema tiene **dos niveles de acceso** protegidos por contraseña:

| Nivel | ¿Quién lo usa? | ¿Qué puede hacer? |
|-------|----------------|-------------------|
| **Administrador** | Jefe de Vigilancia designado | Ver estadísticas, exportar reportes completos (Excel, PDF), cambiar contraseñas, gestionar configuración |
| **Custodio** | Jefes de turno habilitados | Ver estadísticas, exportar reportes básicos. **No puede** cambiar contraseñas ni configuración avanzada |

> ⚠️ **IMPORTANTE:** Los vigilantes comunes que operan la pantalla del monitor de vigilancia **NO** tienen acceso al Dashboard. Solo ven la pantalla de gestión diaria de llaves.

---

## 3. Paso a paso: Cómo acceder al Dashboard

### Paso 1 — Abrir el navegador

En la computadora donde está instalado el sistema, abra el navegador web (Google Chrome recomendado) y escriba en la barra de direcciones:

```
http://localhost:8080/dashboard
```

También puede acceder desde la pantalla del Monitor de Vigilancia haciendo clic en el botón **"Dashboard"** que aparece en la esquina superior.

### Paso 2 — Pantalla de inicio de sesión

Al intentar acceder al Dashboard, el sistema mostrará una **pantalla de contraseña**:

```
┌─────────────────────────────────────┐
│                                     │
│   🔒 Acceso al Dashboard            │
│                                     │
│   Ingrese la contraseña:            │
│   ┌───────────────────────────┐     │
│   │ ••••••••                  │     │
│   └───────────────────────────┘     │
│                                     │
│   ☐ Ingresar como Custodio          │
│                                     │
│   [ Iniciar Sesión ]                │
│                                     │
└─────────────────────────────────────┘
```

### Paso 3 — Ingresar la contraseña

- Si usted es **Administrador**: escriba la contraseña de administrador y presione "Iniciar Sesión".
- Si usted es **Custodio (Jefe de turno)**: marque la casilla "Ingresar como Custodio", escriba la contraseña de custodio y presione "Iniciar Sesión".

### Paso 4 — Usar el Dashboard

Una vez dentro, verá:

- **Gráficos de torta** con estadísticas del turno actual
- **Gráficos de barras** con los salones más solicitados
- **Tablas** con el historial de préstamos
- **Botón "Exportar Reporte"** para descargar la información

### Paso 5 — Cerrar sesión

Cuando termine de consultar, presione el botón **"Cerrar Sesión"** en la esquina superior derecha. La sesión también se cierra automáticamente después de **4 horas** de inactividad.

---

## 4. ¿Cómo funciona la protección?

El sistema implementa las siguientes medidas de seguridad:

### 4.1 Contraseñas separadas
- Existe una contraseña para **Administrador** y otra diferente para **Custodio**.
- Cada una otorga permisos distintos.
- Las contraseñas se almacenan en la base de datos del sistema (no en un archivo de texto).

### 4.2 Sesión con tiempo limitado
- Al iniciar sesión, el sistema crea una "sesión" que dura **máximo 4 horas**.
- Pasadas las 4 horas, el sistema cierra la sesión automáticamente y pide la contraseña nuevamente.
- Esto evita que alguien acceda si el jefe se olvida de cerrar sesión.

### 4.3 Verificación continua
- Cada **60 segundos**, el sistema verifica internamente si la sesión sigue siendo válida.
- Si detecta que expiró, muestra un mensaje de "Sesión expirada" y redirige a la pantalla de contraseña.

### 4.4 Sin acceso desde la terminal de usuarios
- La pantalla que usan los usuarios para solicitar llaves (Terminal de Usuario) **no tiene ningún enlace ni botón** que lleve al Dashboard.
- Solo se puede acceder escribiendo la dirección directamente o desde el Monitor de Vigilancia.

---

## 5. Exportación de reportes

### ¿Qué se puede exportar?

| Formato | Contenido |
|---------|-----------|
| **Excel (.xlsx)** | Tabla completa con todos los préstamos del período seleccionado, filtrable por fecha, turno, tipo de lugar |
| **PDF** | Reporte formateado con gráficos y resumen, listo para imprimir |

### ¿Quién puede exportar?

- **Administrador**: Puede exportar reportes completos con todos los filtros avanzados.
- **Custodio**: Puede exportar reportes básicos del turno actual.

### Pasos para exportar:

1. Dentro del Dashboard, haga clic en **"Exportar Reporte"**
2. Seleccione el **rango de fechas** deseado
3. Seleccione el **formato** (Excel o PDF)
4. Haga clic en **"Descargar"**
5. El archivo se guardará en la carpeta de Descargas de la computadora

---

## 6. Cambio de contraseñas

Solo el **Administrador** puede cambiar las contraseñas. Para hacerlo:

1. Acceda al Dashboard con la contraseña de Administrador
2. Haga clic en el ícono de **Configuración** (⚙️)
3. Seleccione **"Cambiar contraseña"**
4. Ingrese la contraseña actual
5. Ingrese la nueva contraseña
6. Confirme

> 💡 **Recomendación:** Cambie las contraseñas al menos una vez por semestre y cada vez que un jefe de turno deje su cargo.

---

## 7. Contraseñas iniciales del sistema

| Tipo | Contraseña por defecto |
|------|----------------------|
| Administrador | `admin123` |
| Custodio | `custodio2026` |

> ⚠️ **Se recomienda encarecidamente cambiar estas contraseñas inmediatamente después de la primera instalación.**

---

## 8. Preguntas frecuentes

**P: ¿Qué pasa si olvido la contraseña?**  
R: Contacte al administrador del sistema (área de Sistemas). La contraseña puede ser restablecida desde la base de datos.

**P: ¿Puede un vigilante común ver las estadísticas?**  
R: No. Solo los jefes con la contraseña de Administrador o Custodio pueden acceder.

**P: ¿Los datos exportados incluyen información personal?**  
R: Los reportes incluyen nombres de quienes retiraron llaves, fechas y horarios. Esta información debe manejarse con confidencialidad.

**P: ¿Se puede acceder al Dashboard desde otra computadora?**  
R: Sí, desde cualquier computadora conectada a la misma red, escribiendo la dirección IP del servidor seguida de `:8080/dashboard`.

---

*Documento preparado para presentación a las autoridades de FCEA.*
