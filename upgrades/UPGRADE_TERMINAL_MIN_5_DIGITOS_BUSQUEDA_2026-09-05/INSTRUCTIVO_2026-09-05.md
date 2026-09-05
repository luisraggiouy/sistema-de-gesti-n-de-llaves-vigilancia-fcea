# UPGRADE — La lista de usuarios por celular recién aparece al 5.º dígito

**Fecha:** 2026-09-05
**Tipo:** Upgrade de seguridad (frontend / `dist`)
**Aplicar en:** LAS 3 PC → Monitor de Vigilancia, Terminal A y Terminal B.

---

## ¿Qué problema resuelve?

Al identificarse por **número de celular** en las Terminales, con solo tipear el
primer dígito **"0"** se desplegaban **todos** los usuarios cuyo celular empieza
con 0; con **"09"**, todos los "09…". Es decir, con 1 o 2 dígitos se veía
prácticamente **la lista completa de usuarios registrados**, lo que habilita la
**suplantación de identidad** (cualquiera podía ver y elegir a otra persona).

## ¿Qué cambia?

- La lista de coincidencias por **celular** ahora recién se despliega a partir
  del **5.º dígito** tipeado. Con 1, 2, 3 o 4 dígitos **no aparece nada**.
- Se conserva la rapidez (con 5 dígitos el número ya queda muy acotado) y se
  gana seguridad.
- La búsqueda por **email** queda **igual** (se despliega desde 2 caracteres),
  porque no expone la lista completa.

No toca PocketBase ni borra datos: solo reemplaza el frontend (`dist`).

---

## Pasos (repetir en CADA una de las 3 PC)

1. Enchufá el pendrive en la PC (Monitor / Terminal A / Terminal B).
2. Entrá a la carpeta `UPGRADES\UPGRADE_TERMINAL_MIN_5_DIGITOS_BUSQUEDA_2026-09-05`.
3. Clic derecho en **`1-APLICAR_UPGRADE.bat`** → **Ejecutar como administrador**.
4. Esperá el cartel **EXITO** y presioná ENTER.
5. **Cerrá el kiosko/navegador y volvé a abrirlo** (o Ctrl+F5) para que cargue el
   frontend nuevo.

> Repetir en las 3 PC. Si se aplica solo en el Monitor, las Terminales A y B
> seguirían con el JavaScript viejo (el `dist` no se sirve centralizado).

## Cómo probar (en Terminal A o B)

1. En "Identificarse", tipeá **1 solo dígito** (ej. `0`): **NO** debe aparecer
   ninguna lista.
2. Seguí tipeando hasta el **5.º dígito**: recién ahí aparece la lista de
   coincidencias (ya acotada).
3. Probá por **email**: sigue funcionando desde 2 caracteres.

## Rollback

Si algo sale mal, en la misma PC ejecutá **`2-DESHACER_ROLLBACK.bat`** como
administrador: restaura el último backup del `dist`.
