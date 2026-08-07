# INSTRUCTIVO — Upgrade "Texto descriptivo en Identificarse"
**Fecha:** 2026-08-07
**Módulo afectado:** Terminal A y Terminal B (pantalla de solicitud de llave)
**PC donde se aplica:** TERMINAL A y TERMINAL B (hay que repetirlo en cada una)

---

## ¿Qué cambia?

Antes, arriba de la caja de texto decía solamente:

> **Identificarse**

Ahora dice, con la palabra "Identificarse" en el mismo tamaño/color de siempre
y el texto de al lado un poco más chico (pero bien legible):

> **Identificarse** con su número de celular o e-mail

**Motivo:** en las pruebas los usuarios tienden a escribir su nombre. Con este
texto más descriptivo se busca evitar ese error desde el título mismo.

Es un cambio **solo visual** del frontend. No toca PocketBase, no borra datos,
no cambia la lógica de búsqueda.

---

## Pasos para aplicar (hacer en TERMINAL A y luego en TERMINAL B)

1. Enchufá el pendrive en la **Terminal A**.
2. Entrá a la carpeta `UPGRADE_TEXTO_IDENTIFICARSE_2026-08-07`.
3. Doble clic en **`1-APLICAR_TEXTO_IDENTIFICARSE.bat`**.
4. Aceptá el cartel de permisos de Windows (UAC → "Sí").
5. Esperá a que diga **"EXITO. Upgrade aplicado."** y presioná ENTER para cerrar.
6. Cerrá el navegador/kiosko y volvé a abrirlo. Si no ves el cambio, hacé
   **Ctrl + F5** para forzar recarga.
7. Verificá: arriba de la caja de texto ahora debe decir
   **"Identificarse con su número de celular o e-mail"**.
8. **Repetí los pasos 1 a 7 en la Terminal B.**

---

## Si algo sale mal (ROLLBACK)

En la misma PC donde aplicaste el upgrade:

1. Entrá a la carpeta `UPGRADE_TEXTO_IDENTIFICARSE_2026-08-07`.
2. Doble clic en **`2-DESHACER_TEXTO_IDENTIFICARSE_ROLLBACK.bat`**.
3. Aceptá el UAC. Espera a que diga **"[OK] dist restaurado"**.
4. Cerrá y abrí el navegador de nuevo (Ctrl + F5).

El rollback restaura automáticamente el `dist` que había antes
(se guarda en `C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`).

---

## Detalle técnico (para Cline / desarrollo)

- Archivo fuente modificado: `src/components/terminal/UserSearchInput.tsx`
  - El `<h3>` del título ahora usa `items-baseline` y agrega un `<span>`
    con `text-base font-normal text-muted-foreground` con el texto
    "con su número de celular o e-mail".
- El upgrade reemplaza la carpeta `dist` de `C:\sistema-llaves-fcea`
  usando `robocopy /MIR`, con backup previo.
