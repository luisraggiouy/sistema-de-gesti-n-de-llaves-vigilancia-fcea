# Horario restringido — Cómo funciona (resumen)

**Qué es:** una política de seguridad (por orden del Decano) que impide **solicitar y entregar llaves en horario no laboral**, para proteger el edificio.

## Horario
- **Permitido:** de **07:00 a 23:00**.
- **Bloqueado:** de **23:00 a 07:00** (madrugada/noche).

La regla en el sistema es exactamente: se bloquea si la hora actual es **menor a las 7** o **igual/mayor a las 23**.

## A quién afecta
Queda bloqueado en horario restringido: **Docentes, Alumnos, Empresas y Personal TAS** en general.

## Quiénes están exentos (pueden a cualquier hora)
Solo **Personal TAS** cuyo departamento sea:
- **Servicios Generales**
- **Vigilancia**

> Ejemplo: "Personal TAS (Mantenimiento)" **NO** está exento → si intenta antes de las 7:00 o después de las 23:00, queda bloqueado.

## Qué ve el usuario cuando está fuera de horario
- Aparece un **banner rojo**: *"Horario restringido — No se permite la entrega de llaves antes de las 7:00 AM ni después de las 23:00 PM."*
- Al intentar enviar, la Terminal **no deja continuar** y muestra el aviso *"Horario no permitido"*.

## Dónde está en el código (referencia técnica)
- Archivo: `src/pages/TerminalUsuario.tsx`
- Función `esHorarioRestringido()`: `hora < 7 || hora >= 23`
- Función `usuarioExentoHorario()`: `tipo === 'Personal TAS' && (departamento === 'Servicios Generales' || departamento === 'Vigilancia')`

## Nota importante
Esta restricción vive en la **Terminal de usuario** (donde se solicita). El **Monitor de Vigilancia** no tiene candado por horario: un vigilante puede registrar entregas/devoluciones a cualquier hora.
