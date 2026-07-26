# Post-mortem — WAL huérfano de SQLite en el Monitor (26/07/2026)

## Resumen ejecutivo

El Monitor mostraba error **"Error al agregar vigilante"** al intentar cualquier
escritura (agregar vigilante, aceptar solicitud, etc.). Las lecturas funcionaban
perfectamente. Diagnóstico confirmó que era un problema **general de escritura
en TODAS las colecciones**, no específico de `vigilante`.

- **Detección**: 26/07/2026 ~14:30 UTC-3.
- **Resolución**: 26/07/2026 15:17:44 (arranque limpio de PocketBase con WAL fusionado).
- **Impacto**: ~2h30 sin poder registrar cambios en la base productiva.
  Los datos previos NO se perdieron.

## Causa raíz

El archivo `data.db` de SQLite estaba **congelado** (última modificación
`10/06/2026 08:28:14`, 46 días atrás) mientras que `data.db-shm` y `data.db-wal`
estaban recientes.

Esto es el patrón clásico de **WAL huérfano**: PocketBase escribía correctamente
al journal (`data.db-wal`) pero el checkpoint que fusiona el WAL al `data.db`
principal nunca completaba. Cuando el frontend intentaba un `CREATE`, PocketBase
respondía HTTP 400 sin mensaje descriptivo (`{"code":400,"message":"Failed to create record.","data":{}}`).

**Por qué se produjo**: el instalador anterior había dejado 2 procesos
`pocketbase.exe` corriendo simultáneamente (uno legacy en `C:\sistema-llaves-fcea\pocketbase\pb_data`
y otro nuevo en `C:\ProgramData\FCEA-Sistema-Llaves\pb_data`). Ambos tocaban el
mismo `data.db` con locks NTFS incompatibles → el WAL nunca podía consolidarse.

## Cronología

| Hora  | Evento |
|-------|--------|
| ~14:00 | Usuario reporta error en Monitor al agregar vigilante |
| 14:15 | Diagnóstico con `CAZAR_POCKETBASE_ZOMBIE.bat` |
| 14:30 | Confirmación: WAL huérfano, escritura fallida en TODAS las colecciones |
| 14:45 | Grabación de `ARRANCAR_POCKETBASE.bat` con backup preventivo |
| 15:10 | Usuario mata PB con `CAZAR` + `S` |
| 15:17:44 | Arranque limpio de PocketBase → checkpoint del WAL exitoso |
| 15:20 | Test manual desde UI: "Agregar vigilante" ✅ funciona |
| 15:22 | Test manual: pedido desde Terminal-A → aparece en Monitor ✅ |

## Herramientas creadas hoy (red de contención)

Todas quedan versionadas en el repo y grabadas en el pendrive
(`_pendrive_tools/` → `D:\HERRAMIENTAS_RED\`):

1. **`CAZAR_POCKETBASE_ZOMBIE.bat/.ps1`** — Diagnóstico completo:
   detecta procesos `pocketbase.exe`, verifica handles NTFS sobre `data.db`,
   corre test CREATE en múltiples colecciones (`vigilante`, `lugares`,
   `objetos_olvidados`) y **te dice si el problema es general o específico**.

2. **`ARRANCAR_POCKETBASE.bat/.ps1`** — Arranque manual seguro:
   verifica que no haya PB corriendo, **hace backup preventivo** de `data.db`,
   levanta PocketBase con parámetros oficiales, espera respuesta HTTP,
   verifica checkpoint del WAL, hace test CREATE de verificación.

3. **`DIAGNOSTICAR_RED.bat/.ps1`** — Diagnóstico de red no-invasivo.

4. **`REPARAR_CONFIG.bat/.ps1`** — Corrección automática de `config.json`.

5. **`FIJAR_IP_MONITOR.bat/.ps1`** — Configurar IP estática del Monitor.

6. **`MATAR_POCKETBASE_ZOMBIE.bat/.ps1`** — Killer preciso (predecesor de CAZAR).

7. **`APUNTAR_TERMINAL_A_MONITOR.bat/.ps1`** — Redirección manual de Terminal.

8. **`VERIFICAR_CONFIG_ACTUAL.bat/.ps1`** — Read-only, muestra el config vigente.

## Lecciones aprendidas

### 1. Un instalador jamás debe correr sobre una instalación previa sin detectarla
El instalador `INSTALAR SISTEMA.bat` **ya tiene** esta lógica (verifica
`SISTEMA_VALIDO=1` y ofrece un menú "actualizar datos" vs "reinstalar desde cero").
El problema fue que la ruta legacy `%INSTALL_DIR%\pocketbase\pb_data\data.db`
quedaba viva junto a la nueva. Solución: **la próxima instalación debe eliminar
la ruta legacy** cuando detecta que `C:\ProgramData\FCEA-Sistema-Llaves\pb_data`
existe.

### 2. El backup preventivo antes de tocar PocketBase es no negociable
`ARRANCAR_POCKETBASE.bat` copia `data.db` a `data.db.bak_YYYYMMDD_HHMMSS` antes
de arrancar. Costo: 2 segundos y 2 MB de disco. Beneficio: reversibilidad total
si algo sale peor.

### 3. Los mensajes de error de PocketBase son opacos, hay que testear directo
El mensaje `HTTP 400 Failed to create record` no dice **por qué** falla.
La solución fue el test CREATE directo con curl/Invoke-RestMethod desde el
diagnóstico → confirmó que el problema era del lado del servidor, no del schema
ni del frontend.

### 4. WAL huérfano se soluciona con un reinicio limpio, no con "reparación"
No se necesitó `sqlite3 .recover` ni volver a un backup. SQLite fusiona el WAL
automáticamente al abrir la base limpia. La clave es que **no haya OTRO proceso
tocando data.db** al mismo tiempo.

## Acciones de seguimiento recomendadas

- [ ] **Corregir tiempo de solicitud "hace 300 min"**: bug conocido de UI,
      el cálculo usa timestamp del render inicial en vez del real. Pendiente
      para próximo sprint.
- [x] ~~Botón faltante del Dashboard en Monitor~~ — verificado 26/07 16:00:
      el botón existe y funciona correctamente. Falsa alarma.
- [ ] **Agregar al `ARRANCAR SISTEMA.bat` del pendrive el chequeo de zombies**
      antes de arrancar (evita que se cree el problema).
- [ ] **Agregar tarea programada `FCEA-Watchdog-WAL`**: cada 15 min verifica
      que `data.db` se haya modificado en la última hora (si no, alerta).
- [ ] **Documentar en README.md la política de un-único-PocketBase**:
      cualquier instalador debe matar `pocketbase.exe` antes de tocar `pb_data`.

## Tag de rescate

Al finalizar la sesión se creó el tag Git:

```
rescate-26jul2026
```

Este tag captura el estado del código + scripts + herramientas de emergencia
que dejaron el sistema funcionando después de este incidente. **Es el punto
de partida seguro para futuras iteraciones**.

Para volver a este estado:

```powershell
git checkout rescate-26jul2026
```
