# Horario restringido — Cómo funciona (resumen)

**Qué es:** una política de seguridad (por orden del Decano) que impide **solicitar y entregar llaves en horario no laboral**, para proteger el edificio.

## Horario
- **Permitido:** de **07:00 a 23:00**.
- **Bloqueado:** de **23:00 a 07:00** (madrugada/noche).

La regla en el sistema es exactamente: se bloquea si la hora actual es **menor a las 7** o **igual/mayor a las 23**.

## A quién afecta
Queda bloqueado en horario restringido: **Docentes, Alumnos, Empresas y Personal TAS** en general.

## Quiénes están exentos (pueden a cualquier hora, 24 hs)
Solo **Personal TAS** cuyo departamento/sección sea:
- **Servicios Generales**
- **Vigilancia**
- **Intendencia** (upgrade 2026-09-03 — son 4 personas)

> Ejemplo: "Personal TAS (Mantenimiento)" **NO** está exento → si intenta antes de las 7:00 o después de las 23:00, queda bloqueado.

## Excepción para Empresas (upgrade 2026-08-30, re-desplegado 2026-09-03)
Los usuarios de **tipo "Empresa"** (por ejemplo cooperativas de limpieza que empiezan a trabajar antes de las 7) pueden **solicitar llaves desde las 06:00**, es decir en la franja **06:00 a 06:59**. El resto de los usuarios mantiene el corte de las 07:00.

- El **bloqueo nocturno sigue vigente para las empresas**: no pueden solicitar **antes de las 06:00** ni **desde las 23:00**.
- Solo se les abre esa hora extra (06:00–07:00); todo lo demás queda igual.

Motivo: el 29/08/2026 una persona de una cooperativa de limpieza fue a las 6:10 y no pudo registrar el retiro (todavía no eran las 7:00), llevándose las llaves sin registrar. El upgrade 2026-08-30 introdujo la lógica pero **no llegó a quedar efectiva en la prueba real** (dist desplegado no la contenía); el **2026-09-03 se re-compiló y re-desplegó** el `dist` verificando dentro del bundle JS que la lógica está presente, y se probó con la cooperativa **"El Progreso"**.

## Qué ve el usuario cuando está fuera de horario
- Aparece un **banner rojo**: *"Horario restringido — No se permite la entrega de llaves antes de las 7:00 AM ni después de las 23:00 PM."*
- Al intentar enviar, la Terminal **no deja continuar** y muestra el aviso *"Horario no permitido"*.

## Dónde está en el código (referencia técnica)
- Archivo: `src/pages/TerminalUsuario.tsx`
- Función `esHorarioRestringido()`: `hora < 7 || hora >= 23`
- Función `usuarioExentoHorario()`: normaliza `tipo` y `departamento` con `.trim()`. Exento total (24 hs) si `tipo === 'Personal TAS' && (departamento === 'Servicios Generales' || departamento === 'Vigilancia' || departamento === 'Intendencia')`; además, exento en la franja 06:00–06:59 si `tipo === 'Empresa' && hora === 6` (upgrade 2026-08-30, re-desplegado 2026-09-03).
- El departamento/sección `'Intendencia'` está en el catálogo `departamentosTAS` de `src/data/fceaData.ts`. Para que la exención 24 hs aplique, cada usuario de Intendencia debe estar registrado como `Personal TAS` con ese departamento exacto.

## Nota importante
Esta restricción vive en la **Terminal de usuario** (donde se solicita). El **Monitor de Vigilancia** no tiene candado por horario: un vigilante puede registrar entregas/devoluciones a cualquier hora.
