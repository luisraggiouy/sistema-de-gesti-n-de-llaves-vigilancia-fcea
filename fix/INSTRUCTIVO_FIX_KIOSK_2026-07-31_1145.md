# INSTRUCTIVO - FIX KIOSK 404 (Terminal B)
**Fecha/hora:** 2026-07-31 11:45
**PC objetivo:** Terminal B (y sirve igual para Terminal A y Monitor)

---

## Que problema resuelve
El icono "abrir llaves FCEA modo kiosk" (y el arranque automatico) abrian el
navegador contra el **8090 del Monitor**, que es **solo-API (PocketBase)** y
devuelve `{"code":404,"message":"Not Found."}` para rutas como `/terminal?id=B`.
Por eso "la Terminal no levantaba" y mostraba el 404.

**La app YA funciona en el frontend local** (lo confirmamos: `127.0.0.1:5173`
carga la Terminal B perfecto). El fix hace que el navegador abra **SIEMPRE el
frontend LOCAL `http://127.0.0.1:5173`**. Los datos siguen yendo al Monitor por
dentro de la app (via `pocketbase_url` del config.json).

## Que cambia (2 archivos)
1. `scripts\lib\lanzar_navegador.ps1` - elimina la "defensa v2.8" que redirigia
   al 8090 del Monitor; ahora fuerza el frontend local.
2. `scripts\lib\abrir_llaves_kiosk.bat` - asegura que el 5173 local este arriba
   (si no, lo arranca) y abre el navegador en `127.0.0.1:5173`.

El aplicador hace **backup con timestamp** de las versiones actuales antes de
copiar (por si hay que volver atras).

---

## Pasos en Terminal B
1. Enchufar el pendrive en Terminal B.
2. Entrar a la carpeta `fix` del pendrive.
3. Doble click en **`APLICAR_FIX_KIOSK.bat`**.
4. Aceptar el cartel de permisos de administrador (UAC).
5. El script hace backup, copia los 2 archivos, actualiza el icono del
   escritorio y **relanza el kiosko solo**.
6. Verificar: debe abrir en pantalla completa la **Terminal B**
   (titulo "Sistema de Gestion de Llaves", identificarse / buscar llaves),
   **NO** el `{"code":404,...}`.
7. (Opcional) Reiniciar la PC para confirmar que al prender arranca sola bien.

---

## Que me tenes que decir (dev laptop)
- Si el kiosko abrio la **Terminal B** correctamente (si / no).
- Si al **reiniciar** la PC arranca sola en la Terminal (si probaste).

> Recien cuando me confirmes que funciono, integro el fix a los archivos del
> repo (`scripts\lib\lanzar_navegador.ps1` y `abrir_llaves_kiosk.bat`), hago el
> commit con timestamp y lo subo a GitHub.

## Rollback (si algo sale mal)
En `C:\sistema-llaves-fcea\scripts\lib\` quedaron los backups
`lanzar_navegador.ps1.bak_<timestamp>` y `abrir_llaves_kiosk.bat.bak_<timestamp>`.
Renombralos quitando el `.bak_<timestamp>` para volver al estado anterior.
