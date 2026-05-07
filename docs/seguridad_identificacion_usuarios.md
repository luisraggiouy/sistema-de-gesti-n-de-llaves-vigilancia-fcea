# Seguridad en la Identificacion de Usuarios — Terminal de Solicitud de Llaves

## Descripcion del Problema

Anteriormente, el buscador de usuarios en la terminal permitia buscar por nombre. Esto representaba un riesgo de seguridad: cualquier persona que conociera el nombre de otra persona podia suplantarle la identidad al momento de retirar llaves.

## Solucion Implementada

A partir de la version 5.6 (mayo 2026), la busqueda de usuarios en la terminal **solo acepta numero de celular o email**. La busqueda por nombre esta deshabilitada.

### Comportamiento del buscador

| Tipo de entrada | Resultado |
|----------------|-----------|
| Solo digitos (ej: `099123456`) | Busca por numero de celular |
| Texto con @ (ej: `juan@fcea.edu.uy`) | Busca por email |
| Texto libre (ej: `Juan Perez`) | Muestra advertencia: busqueda por nombre no permitida |

### Texto de instruccion en la terminal

La terminal muestra el siguiente texto:

> Identifiquese con su numero de celular o con su email. De lo contrario **registrese** para continuar.

La palabra "registrese" aparece en azul como enlace clickeable que abre el formulario de registro.

### Advertencia al intentar buscar por nombre

Si el usuario escribe texto que no es celular ni email, aparece un mensaje en ambar:

> Por seguridad, la busqueda por nombre no esta permitida.
> Ingrese su numero de celular o su email para identificarse.

## Razonamiento de Seguridad

- **Nombre:** Cualquier persona puede conocer el nombre de otra. Riesgo alto de suplantacion.
- **Celular:** Menos probable que alguien conozca el numero exacto de otra persona. Riesgo bajo.
- **Email:** Menos probable que alguien conozca el email exacto de otra persona. Riesgo bajo.

La combinacion de celular o email como identificador reduce significativamente el riesgo de suplantacion de identidad al momento de retirar llaves.

## Archivos Modificados

- `src/hooks/useUsuariosRegistrados.ts` — funcion `buscarPorTexto`: eliminada la busqueda por nombre, solo celular o email.
- `src/components/terminal/UserSearchInput.tsx` — texto de instruccion actualizado, advertencia al buscar por nombre, link de registro en azul.

## Consideraciones para el Registro

Al registrarse por primera vez, el usuario debe proporcionar:
- Nombre completo
- Numero de celular (obligatorio)
- Email (opcional pero recomendado)
- Tipo de usuario (Docente, Personal TAS, Empresa, etc.)

Una vez registrado, puede identificarse en cualquier terminal usando su celular o email.

## Impacto en Usuarios Existentes

Los usuarios ya registrados en el sistema no necesitan hacer nada. Simplemente deben usar su numero de celular o email para identificarse en lugar de su nombre.

Si un usuario no recuerda con que celular o email se registro, debe acudir a la ventanilla de vigilancia para que el vigilante lo busque en el sistema de administracion.

---

*Implementado: 06/05/2026 — v5.6*
*Documento preparado para archivo y custodia autoridades de FCEA.*
