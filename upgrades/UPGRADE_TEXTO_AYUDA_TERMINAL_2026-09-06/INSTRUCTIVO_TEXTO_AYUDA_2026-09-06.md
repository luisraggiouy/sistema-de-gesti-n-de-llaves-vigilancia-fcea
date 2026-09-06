# INSTRUCTIVO — Upgrade "Texto de ayuda en pantalla de identificación"
**Fecha:** 2026-09-06
**Módulo afectado:** Terminal A y Terminal B (pantalla de solicitud de llave)
**Tipo:** Upgrade de frontend (`dist`)

---

## Qué cambia

En la pantalla de identificación de las terminales de usuario:

1. **Debajo** del título *"Identificarse con su número de celular o e-mail"*
   ahora aparece un renglón de ayuda (texto gris, más chico):

   > Haga click sobre su nombre una vez que lo vea en la pantalla, para solicitar la/s llaves

2. El texto de ayuda **dentro de la caja de texto** (placeholder) ahora dice:

   > Ingrese aquí su número de celular o email...

Orden en pantalla (de arriba hacia abajo):
1. **Identificarse con su número de celular o e-mail**
2. **Haga click sobre su nombre una vez que lo vea en la pantalla, para solicitar la/s llaves**
3. Caja de texto con placeholder **"Ingrese aquí su número de celular o email..."**

**Motivo:** guiar mejor al usuario para que reconozca que debe hacer click sobre
su nombre en la lista de sugerencias.

---

## IMPORTANTE — Aplicar en LAS 3 PC ❗

Este upgrade toca el **frontend compilado (`dist`)**. Como cada PC sirve su
propio `dist`, debe aplicarse en **Terminal A, Terminal B y el Monitor de
Vigilancia** (ejecutar el mismo script una vez en cada una y reabrir el kiosko).

---

## Pasos para aplicar

1. Enchufá el pendrive en la PC.
2. Entrá a la carpeta `UPGRADE_TEXTO_AYUDA_TERMINAL_2026-09-06`.
3. Doble clic en **`1-APLICAR_TEXTO_AYUDA.bat`**.
4. Aceptá el cartel de permisos de Windows (UAC → "Sí").
5. Esperá a que diga **"EXITO. Upgrade aplicado."** y presioná ENTER para cerrar.
6. Cerrá y volvé a abrir el navegador/kiosko. Si hace falta, **Ctrl + F5** para forzar recarga.
7. Verificá que debajo del título aparezca el renglón de ayuda y que la caja de
   texto diga "Ingrese aquí su número de celular o email...".
8. **Repetí los pasos 1 a 7 en las otras PC (Terminal B y Monitor).**

---

## Rollback (si algo sale mal)

En la misma PC donde aplicaste el upgrade:

1. Entrá a la carpeta `UPGRADE_TEXTO_AYUDA_TERMINAL_2026-09-06`.
2. Doble clic en **`2-DESHACER_TEXTO_AYUDA_ROLLBACK.bat`**.
3. Aceptá el UAC. Esperá a que diga **"[OK] dist restaurado"**.
4. Cerrá y abrí el navegador de nuevo (Ctrl + F5).

---

## Detalle técnico

- Archivo modificado: `src/components/terminal/UserSearchInput.tsx`.
  - Se envolvió el título en un `<div>` y se agregó un `<p>` con
    `text-sm text-muted-foreground mt-1` con el texto de ayuda.
  - Se cambió el `placeholder` del `<Input>` a
    "Ingrese aquí su número de celular o email...".
- El upgrade reemplaza la carpeta `dist` de `C:\sistema-llaves-fcea`
  usando `robocopy /MIR /XF config.json system_health.json`, con backup previo.
