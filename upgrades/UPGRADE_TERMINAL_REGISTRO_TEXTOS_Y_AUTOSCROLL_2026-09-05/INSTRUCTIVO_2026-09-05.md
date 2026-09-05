# UPGRADE — Terminales: textos del registro, campos obligatorios en rojo y auto-scroll (2026-09-05)

## Qué cambia (todo es frontend / `dist`)

1. **Auto-scroll al encabezado (Terminales A y B).**
   Tras **4 segundos de inactividad** (sin mover mouse, teclado, rueda,
   scroll ni touch), la Terminal vuelve **sola y con scroll suave** al
   encabezado (identificación / búsqueda de usuario), igual que ya hace el
   Monitor. **No** actúa mientras hay un modal abierto (Registro o
   Intercambio) ni **sin conexión**.

2. **Textos del formulario de Registro de Usuario.**
   - `Nombre completo` → **`Nombre y apellido`** (placeholder incluido).
   - `Correo electrónico` → **`Correo electrónico (si ya ingresó su celular
     este campo es OPCIONAL)`**.
   - Debajo de *"Complete sus datos una única vez…"* se agrega la leyenda:
     **"Los campos marcados con `*` son obligatorios."**
   - Se mantienen los asteriscos `*` en los campos obligatorios.

3. **Campos obligatorios en rojo.**
   Al pulsar **Registrarse** con campos obligatorios sin completar, además de
   dejar el botón atenuado/inactivo (como ya pasaba), ahora se **resaltan en
   rojo** (borde + texto de ayuda) los campos que faltan: nombre, contacto
   (celular o correo), tipo de usuario, nombre de empresa, unidad académica.

## Dónde aplicarlo

**En LAS 3 PC: Monitor de Vigilancia, Terminal A y Terminal B.**
El `dist` es compartido pero cada PC sirve el suyo local (127.0.0.1:5173),
así que el mismo script se ejecuta **una vez en cada PC**.

## Pasos (repetir en cada PC)

1. Enchufar el pendrive "cable" (D:).
2. Entrar a la carpeta `UPGRADES\UPGRADE_TERMINAL_REGISTRO_TEXTOS_Y_AUTOSCROLL_2026-09-05`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pide permisos de administrador).
4. Esperar el mensaje **EXITO** y presionar ENTER.
5. **Cerrar el navegador/kiosko y volver a abrirlo** (Ctrl+F5).

## Cómo probarlo (en una Terminal, A o B)

1. Abrir *"¿Primera vez? Registrarse"*.
2. Verificar los textos nuevos (Nombre y apellido / Correo opcional / leyenda del `*`).
3. Con campos vacíos, tocar **Registrarse**: los que faltan deben quedar **en rojo**.
4. Completar y registrar: debe funcionar normal.
5. Cerrar el modal, bajar con la rueda del mouse y soltar: a los **4s** la
   pantalla vuelve sola arriba.

## Rollback

Ejecutar **`2-DESHACER_ROLLBACK.bat`** en la misma PC: restaura el último
`dist_backup_*`. No toca PocketBase ni datos.
