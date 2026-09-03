# UPGRADE — Identificarse con el email SIN tener que escribir la "@"

**Fecha:** 2026-09-03
**Módulo:** Terminales de usuario (buscador de identificación)
**Aplicar en:** LAS 3 PC → Monitor de Vigilancia, Terminal A y Terminal B

---

## Problema que resuelve

Un usuario registrado **solo con email** (sin celular) —por ejemplo
**Jorge Kantardjian, `katana941@hotmail.com`, Personal TAS / Suministros**—
podía registrarse bien, pero **no lograba identificarse** en la terminal.

**Causa (confirmada con diagnóstico):** al identificarse, la terminal solo
buscaba por email si el texto contenía la **`@`**. Si el usuario escribía solo
la parte de adelante del correo (ej. `katana941`), el sistema lo tomaba como
"búsqueda por nombre", la mostraba **bloqueada** ("por seguridad no está
permitida") y no devolvía ningún resultado. Como no tenía celular, no había
forma de encontrarlo sin escribir el correo completo con `@`.

## Qué cambia

- Ahora, si el texto **no** es un número de celular, la terminal busca por la
  **parte local del email** (lo que va **antes de la `@`**) por prefijo.
  Así, escribir `katana941` ya encuentra a Jorge.
- Escribir el email **completo con `@`** sigue funcionando igual que antes.
- **La seguridad se mantiene:** la coincidencia es **solo contra el email**,
  nunca contra el nombre de la persona. No se puede identificar a alguien
  tipeando su nombre y apellido.

## Importante: va en LAS 3 PC

El frontend **no** es centralizado: cada PC sirve su propio `dist`. Por eso
este upgrade se aplica **una vez en cada PC** (Monitor, Terminal A y Terminal B),
si no, la PC que quede sin actualizar seguirá con el comportamiento viejo.

---

## Pasos (repetir en cada una de las 3 PC)

1. Enchufar el pendrive en la PC.
2. Entrar a la carpeta
   `UPGRADES\UPGRADE_IDENTIFICAR_EMAIL_SIN_ARROBA_2026-09-03`.
3. Doble clic en **`1-APLICAR.bat`** y aceptar el pedido de permisos (UAC).
4. Esperar el mensaje **"EXITO. Upgrade aplicado en esta PC"**. Cerrar con ENTER.
5. Cerrar el navegador/kiosko y volver a abrirlo (si hace falta, `Ctrl+F5`).
6. **Probar:** en la pantalla de identificación de la terminal, escribir la
   parte del email antes de la `@` (ej. `katana941`) → debe aparecer el usuario
   en la lista para seleccionarlo.

Repetir los pasos 1–6 en las otras 2 PC.

---

## Rollback (si algo sale mal)

En la PC afectada, doble clic en **`2-DESHACER_ROLLBACK.bat`** (restaura el
`dist` anterior desde el backup automático `dist_backup_<fecha_hora>` que quedó
en `C:\sistema-llaves-fcea`). No toca datos ni PocketBase.

---

## Detalle técnico (para Cline / desarrollo)

Archivos fuente modificados:

- `src/hooks/useUsuariosRegistrados.ts` — función `buscarPorTexto`: cuando el
  texto no es celular y no contiene `@`, ahora se filtra por
  `norm(email.split('@')[0]).startsWith(textoNorm)` (parte local del email por
  prefijo). Se mantiene la rama de email completo (con `@`) y la de celular.
- `src/components/terminal/UserSearchInput.tsx` — `tipoBusqueda` ya no devuelve
  `'nombre'`: todo lo que no es celular se trata como `'email'`. Se eliminó el
  cartel "búsqueda por nombre no permitida" y las condiciones
  `tipoBusqueda !== 'nombre'` de los bloques de sugerencias.

El upgrade solo reemplaza el `dist` compilado; no toca PocketBase ni datos.
