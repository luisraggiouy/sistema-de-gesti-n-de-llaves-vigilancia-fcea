# INSTRUCTIVO — Upgrade "Contraste + 'celular' en negrita + textos +15%"
**Fecha:** 2026-09-12
**Módulo afectado:** Terminal de usuario (pantalla de identificación / solicitud de llaves)
**Aplicar en:** LAS 3 PC → Monitor de Vigilancia, Terminal A y Terminal B

---

## ¿Qué cambia?

1. **Mejor contraste en las cajas de texto.** El borde y el relleno de los
   campos de texto (inputs) ahora son un poco más oscuros, así se distingue
   claramente el área donde se escribe.

2. **La palabra "celular" en negrita.** En la pantalla de identificación, el
   texto *"Identificarse con su número de **celular** o e-mail"* muestra ahora
   "celular" en negrita (también en el renglón de instrucción de más abajo).

3. **Textos +15% en las Terminales.** Todo el contenido de la Terminal de
   usuario se agranda un 15 % (uno de los monitores tiene más resolución y se
   veía chico). El **Monitor de Vigilancia NO se agranda**: usa el mismo `dist`
   pero esa pantalla no aplica el zoom, así que se ve igual que siempre.

---

## Cómo aplicarlo (repetir en LAS 3 PC)

> ⚠️ Como este upgrade cambia el **frontend compilado (`dist`)**, hay que
> aplicarlo en **las 3 PC**. El frontend NO se sirve centralizado: cada PC
> corre su propio `dist`. Si se aplica solo en una, las otras siguen con el
> JavaScript viejo.

1. Enchufá el pendrive en la PC (empezá por el **Monitor**, luego Terminal A y B).
2. Entrá a la carpeta `UPGRADE_CONTRASTE_CELULAR_NEGRITA_TEXTO_15_2026-09-12`.
3. Doble clic en **`1-APLICAR_CONTRASTE.bat`**.
4. Aceptá el cartel de permisos de Windows (UAC → "Sí").
5. Esperá a que diga **"EXITO. Upgrade aplicado."** y presioná ENTER para cerrar.
6. Cerrá y volvé a abrir el navegador/kiosko. Si hace falta, **Ctrl + F5** para
   forzar recarga.
7. Verificá en la Terminal: "celular" en negrita, textos más grandes y cajas de
   texto mejor delimitadas.
8. **Repetí los pasos 1 a 7 en las otras PC** (Terminal A, Terminal B y Monitor).

---

## Rollback (deshacer)

En la misma PC donde aplicaste el upgrade:

1. Entrá a la carpeta `UPGRADE_CONTRASTE_CELULAR_NEGRITA_TEXTO_15_2026-09-12`.
2. Doble clic en **`2-DESHACER_CONTRASTE_ROLLBACK.bat`**.
3. Aceptá el UAC. Esperá a que diga **"[OK] dist restaurado"**.
4. Cerrá y abrí el navegador de nuevo (Ctrl + F5).

---

## Detalle técnico (para Cline / desarrollo)

- `src/index.css`:
  - Se oscurecieron los tokens `--input` (72 % → antes 92 %) y `--border`
    (82 % → antes 88 %) del tema claro para dar más contraste a las cajas.
  - Se agregó la clase `.terminal-zoom { zoom: 1.15; }`.
- `src/pages/TerminalUsuario.tsx`: el `<div>` raíz suma la clase
  `terminal-zoom` (scoped solo a la Terminal de usuario, no al Monitor).
- `src/components/terminal/UserSearchInput.tsx`: la palabra "celular" se
  envolvió en `<span className="font-bold">` en el título y en el renglón de
  instrucción.
- El upgrade reemplaza la carpeta `dist` de `C:\sistema-llaves-fcea` usando
  `robocopy /MIR /XF config.json system_health.json`, con backup previo.
