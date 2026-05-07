# INSTRUCTIVO: Dashboard de Estadisticas y Exportacion de Datos
## Sistema de Gestion de Llaves — FCEA

Version: 2.0
Fecha: Mayo 2026
Destinatarios: Todo el personal de vigilancia, jefes de turno, intendencia y autoridades de la Facultad

---

## 1. Que es el Dashboard?

El Dashboard (Panel de Estadisticas) es una pantalla del sistema que muestra informacion resumida sobre el uso de llaves en la Facultad: cuantas llaves se prestaron, a quien, en que horarios, que salones son los mas solicitados, estadisticas por turno, actividad reciente, etc.

---

## 2. Quien puede ver el Dashboard?

El Dashboard es visible para todos sin necesidad de contrasena. Cualquier persona frente a la pantalla puede consultar las estadisticas.

Para llevarse los datos en un pendrive (exportar), si se requiere una contrasena. Esto protege que cualquiera pueda extraer informacion del sistema.

| Accion | Requiere contrasena? |
|--------|---------------------|
| Ver estadisticas y graficas | No |
| Ver actividad reciente | No |
| Ver estadisticas por turno | No |
| Exportar datos a pendrive | Si |
| Cambiar contrasena de exportacion | Si (la contrasena actual) |

---

## 3. Como acceder al Dashboard

En la computadora donde esta instalado el sistema, abra el navegador web (Google Chrome recomendado) y escriba en la barra de direcciones:

```
http://localhost:8080/dashboard
```

Tambien puede acceder desde la pantalla del Monitor de Vigilancia haciendo clic en el boton "Dashboard" que aparece en la esquina superior.

El Dashboard se abre directamente, sin pedir contrasena.

---

## 4. Como exportar datos a un pendrive

Solo las personas autorizadas (jefes de turno, jefes de apoyo, intendencia) pueden llevarse los datos en un pendrive.

### Paso 1 — Conectar el pendrive

Conecte un pendrive comun al puerto USB de la computadora. El sistema lo detectara automaticamente y mostrara una barra verde en la parte superior del Dashboard.

### Paso 2 — Presionar "Exportar a Pendrive"

Haga clic en el boton "Exportar a Pendrive" en el encabezado del Dashboard.

### Paso 3 — Ingresar la contrasena

El sistema pedira la contrasena de exportacion. Ingresela y presione "Verificar y Continuar".

Contrasena por defecto: `custodio2026`

### Paso 4 — Seleccionar fechas y datos

Una vez verificada la contrasena, seleccione:
- Rango de fechas (por defecto los ultimos 30 dias)
- Que datos incluir (llaves entregadas, devueltas, objetos olvidados, autorizaciones, etc.)

### Paso 5 — Exportar

Haga clic en "Exportar a USB". Los datos se guardaran directamente en el pendrive.

### Paso 6 — Retirar el pendrive

Cuando aparezca el mensaje de confirmacion, puede retirar el pendrive de forma segura.

---

## 5. Cambio de contrasena de exportacion

Para cambiar la contrasena de exportacion:

1. En el encabezado del Dashboard, haga clic en "Cambiar Contrasena Exportacion"
2. Ingrese la contrasena actual
3. Ingrese la nueva contrasena (minimo 6 caracteres)
4. Confirme la nueva contrasena

Recomendacion: Cambiar la contrasena al menos una vez por semestre y cada vez que un jefe de turno deje su cargo.

---

## 6. Contrasena por defecto

| Funcion | Contrasena por defecto |
|---------|----------------------|
| Exportacion a pendrive | `custodio2026` |

Se recomienda cambiar esta contrasena inmediatamente despues de la primera instalacion.

Importante: La contrasena por defecto se restablece automaticamente cada vez que se restaura el sistema con el pendrive restaurador. Despues de cada restauracion, cambiar la contrasena nuevamente.

---

## 7. Preguntas frecuentes

P: Puedo ver el Dashboard sin contrasena?
R: Si. El Dashboard es visible para todos. Solo se pide contrasena para exportar datos a un pendrive.

P: Que pasa si olvido la contrasena de exportacion?
R: Contacte al administrador del sistema (area de Sistemas). La contrasena puede ser restablecida desde la base de datos PocketBase.

P: Los datos exportados incluyen informacion personal?
R: Los reportes incluyen nombres de quienes retiraron llaves, fechas y horarios. Esta informacion debe manejarse con confidencialidad.

P: Se puede acceder al Dashboard desde otra computadora?
R: Si, desde cualquier computadora conectada a la misma red, escribiendo la direccion IP del servidor seguida de `:8080/dashboard`.

P: Necesito un pendrive especial?
R: No. Funciona con cualquier pendrive comun formateado en FAT32 o NTFS.

---

*Documento preparado para archivo y custodia autoridades de FCEA.*
