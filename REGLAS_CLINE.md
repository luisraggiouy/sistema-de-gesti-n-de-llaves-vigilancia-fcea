# REGLAS CLINE - LEE ESTO PRIMERO EN CADA NUEVA TAREA
**Creado: 28/07/2026 · última modificación: 06/11/2026**

> **NOMENCLATURA DE PENDRIVES (leer siempre):** en estas reglas NUNCA se fijan
> letras de unidad (`D:`, `E:`, `F:`). Se habla de dos pendrives por su rol:
> - **pendrive "cable":** el que lleva **fixes, upgrades y diagnósticos** entre la
>   laptop de desarrollo y las 3 PC de producción. Contiene las carpetas `FIX\`,
>   `UPGRADES\`, `HERRAMIENTAS_RED\` y `_RESULTADOS\`.
> - **pendrive "rescate":** el que contiene el **`dist` MAESTRO** y la operación de
>   **"Actualizar Datos"**, además de los scripts críticos (INSTALAR / RECUPERAR /
>   DESINSTALAR / ARRANCAR SISTEMA).
>
> La letra de unidad de cada pendrive **puede cambiar** entre sesiones y equipos.
> Por eso **Cline debe preguntarle a Luis la letra concreta CADA VEZ** que vaya a
> grabar o leer un pendrive, antes de tocar nada.

## ⛔ REGLA RAIZ #0 - ESTAS TOCANDO PRODUCCION PURA (agregada 05/10/2026)
El sistema de 3 PC de la FCEA esta EN PRODUCCION 24/7 (vigilancia real). Un error
menor en el frontend puede dejar el MONITOR EN PANTALLA BLANCA y voltear toda la
operativa. Por eso, ANTES de grabar al pendrive CUALQUIER cambio que toque el
frontend (`dist`), es OBLIGATORIO y NO negociable:

1. **Verificar imports / identificadores:** todo lo que se usa debe estar importado
   (en React: `useState`, `useEffect`, `useRef`, `useCallback`, `useMemo`, etc.).
2. **Type-check:** correr `node_modules\.bin\tsc.cmd --noEmit` y que de EXIT=0.
   (Esto SOLO habria evitado el incidente del 05/10: `useCallback is not defined`.)
3. **Build:** `vite build` sin errores.
4. **ABRIR LA APP COMPILADA Y USARLA:** levantar `vite preview` sobre el dist,
   pedir el index y el bundle por HTTP (deben dar 200) y, si es posible, abrir la
   pantalla afectada y usarla. NUNCA empaquetar un dist sin haberlo abierto una vez.

**Cambios menores = cambios MINIMOS.** No reescribir ni "mejorar" de mas. Si un
cambio menor ya fallo una vez, parar, revisar con lupa, no improvisar.

**INCIDENTE 05/10/2026 (precedente):** el fix de "scroll infinito del historial"
uso `useCallback` SIN importarlo. El `vite build` no lo freno, se empaqueto sin
abrir la app, y en produccion dejo el Monitor EN BLANCO. El rollback no alcanzo y
hubo que ir a Recuperar Sistema de emergencia. Era un cambio menor, mal hecho DOS
veces. Causa evitable 100% con el paso 2 (tsc) y el paso 4 (abrir la app).

**Rollback confiable:** todo `APLICAR_*.ps1` hace backup del dist antes de pisarlo,
pero el `2-DESHACER_ROLLBACK.bat` debe PROBARSE que realmente restaura. No confiar
en que "el rollback me salva": la prevencion (pasos 1-4) es lo que evita el desastre.

## ✨ Regla de Oro de la Prolijidad del Pendrive (agregada 06/11/2026)
Todo paquete de **fix** se graba SIEMPRE dentro de la carpeta **`FIX\`** del pendrive
cable, y todo **upgrade** dentro de **`UPGRADES\`**, cada uno en su propia subcarpeta
con nombre `NOMBRE_REPRESENTATIVO_AAAA-MM-DD`. **NUNCA** sueltos en la raíz del
pendrive.

**Excepciones permanentes que NO se mueven ni se limpian:**
- `HERRAMIENTAS_RED\` (caja de herramientas de diagnóstico/reparación reutilizable).
- Los `.log` de diagnóstico, que van a `_RESULTADOS\`.

**Por qué:** la raíz del pendrive se llenó históricamente de paquetes sueltos
(`UPGRADE_*`, `FIX_*`, `.txt`, `.ps1`) que ensucian y confunden cuál es el vigente.
Mantener `FIX\` y `UPGRADES\` ordenados por subcarpeta con fecha hace trivial saber
qué se aplicó y cuándo, y convive con la "Nueva Regla Fix Carpeta" (borrar intentos
fallidos) y con la regla de `HERRAMIENTAS_RED`.


## Restricciones Técnicas
No accedas ni leas archivos dentro de la carpeta `node_modules/` ya que contiene
dependencias de terceros que están pre-auditadas y funcionando correctamente. Leer
estos archivos consume tokens innecesarios, aumenta el contexto sin aportar valor al
desarrollo, y puede causar errores de límite de contexto. Las dependencias de
JavaScript/TypeScript en node_modules son estables y no requieren modificación ni
revisión.

## Regla de Oro de los Upgrades: NUNCA pisar config.json (agregada 07/08/2026)
Todo script que copie el `dist` a la instalación de producción
(`C:\sistema-llaves-fcea\dist`) DEBE excluir SIEMPRE `config.json` y
`system_health.json`. Es decir, el `robocopy` del `dist` nuevo tiene que llevar
OBLIGATORIAMENTE:

```
robocopy $DIST_SRC $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP
```

**Por qué:** `config.json` guarda la configuración de red propia de cada PC (a qué IP
de PocketBase apunta). Si un upgrade copia el `dist` con `/MIR` SIN este `/XF`, PISA
el `config.json` de producción con el de desarrollo (que apunta a `127.0.0.1`) y deja
las 3 PCs sin datos (terminales sin usuarios ni llaves). Esto ya pasó el 07/08/2026 y
costó una sesión entera de diagnóstico.

**Regla práctica:** al crear cualquier upgrade nuevo, usá como plantilla el
`APLICAR_UPGRADE.ps1` de `UPGRADE_NOTAS_HISTORIAL_LLAVES_2026-08-07` (o cualquiera de
los 5 ya corregidos ese día), que ya trae el `/XF`. Antes de grabar un upgrade al
pendrive, VERIFICAR que su `robocopy` de `dist` incluya `/XF config.json
system_health.json`. Con esto, el problema no puede repetirse.

## Regla de Oro de los Upgrades: TODO upgrade de `dist` se aplica en LAS 3 PC (agregada 30/08/2026)
Cualquier upgrade o fix que reemplace el **frontend compilado (`dist`)** DEBE
aplicarse en **las 3 PC** (Monitor de Vigilancia, Terminal A y Terminal B), NO solo
en el Monitor.

**Por qué:** el frontend NO se sirve centralizado. Cada PC corre su propio `vite
preview` en `127.0.0.1:5173` y sirve el `dist` de **su propio disco**
(`C:\sistema-llaves-fcea\dist`) — ver `abrir_llaves_kiosk.bat` y
`scripts/lib/run_frontend.bat`. Lo único que viaja por red al Monitor es la **API de
datos de PocketBase (puerto 8090)**; el `8090` NO sirve el HTML/JS (devuelve 404 para
rutas SPA). Por eso, si un upgrade de `dist` se aplica solo en el Monitor, las
Terminales A y B siguen cargando el JavaScript viejo y el cambio "no aparece".

Esto pasó el 30/08/2026 con `UPGRADE_TERMINAL_INTERCAMBIO_CIERRA_SESION_2026-08-25`:
el instructivo decía "aplicar solo en el Monitor" y por eso la Terminal seguía
quedando logueada tras el intercambio (el fix nunca llegó a A/B).

**Regla práctica:** en todo instructivo y en los mensajes de `APLICAR_UPGRADE.ps1` de
un upgrade que toque `dist`, indicar SIEMPRE "Aplicar en LAS 3 PC (Monitor, Terminal
A y Terminal B); ejecutar el mismo script una vez en cada una y reabrir el kiosko".
Solo los upgrades que tocan exclusivamente PocketBase/datos (no `dist`) van
únicamente en el Monitor.

## Regla de Oro: NUNCA pedir cerrar el navegador; Ctrl+F5 alcanza (agregada 04/10/2026)
**NO** indicar nunca "cerrar el navegador por completo" como paso de un fix/upgrade.
En este sistema, en produccion, **Ctrl+F5 SIEMPRE alcanzo** para incorporar un
`dist` nuevo. Cerrar el navegador en produccion es **riesgoso** (deja el kiosko de
vigilancia caido / fuera de la operativa). El procedimiento correcto es y sigue
siendo: aplicar el paquete -> en el kiosko **Ctrl+F5**. Nada mas.

(Esta regla CORRIGE una anterior del 04/10/2026 que, por un diagnostico apresurado,
llego a recomendar cerrar el navegador. Era incorrecta: ver la regla de verificacion
de dist de abajo, que explica la causa real.)

## Regla de Oro: tras aplicar un dist, VERIFICAR que es el correcto (agregada 04/10/2026)
Cuando un fix/upgrade de `dist` "no surte efecto" aunque se recargo con Ctrl+F5, la
causa real NO es cache: es que **el `dist` que se copio a produccion NO era el que se
creia** (dist viejo empaquetado por un BUILD_DIST mal apuntado, o paquete equivocado).
Paso el 03/10/2026: el upgrade 22:20 se aplico en las 3 PC y se recargo con Ctrl+F5,
pero igual bloqueo a las 22:00 porque el `dist` activo tenia la logica vieja
`r>=22||r<6` (22:00) en vez de `r===22?n>=20:r>=23` (22:20).

**Regla practica:** todo `APLICAR_*.ps1` de un fix de `dist` con una conducta
verificable (p. ej. un horario) DEBE, tras copiar, **auto-verificar el JS en disco**
con una firma del cambio y avisar en pantalla si no coincide. Ejemplo (upgrade 22:20):

```powershell
$js = Get-ChildItem (Join-Path $DIST_DEST 'assets') -Filter 'index-*.js' | Select-Object -First 1
if (Select-String -Path $js.FullName -Pattern 'r===22' -Quiet) { "[VERIFICADO] 22:20 OK" }
else { "[ALERTA] el dist NO es 22:20" }
```


## Regla de Oro del BUILD_DIST: compilar SIEMPRE desde el repo git (agregada 04/10/2026)
Todo `BUILD_DIST.ps1` DEBE compilar el `dist` SIEMPRE y SOLO desde el
**repositorio git de desarrollo** (unica fuente de verdad), definido en una
variable `$REPO` al tope del script, con validacion dura (si no hay
`package.json` + `node_modules` en esa ruta, ABORTA). NUNCA debe tener un
"fallback" a una copia congelada del codigo.

**Por qué:** esas copias congeladas (p. ej. una instalacion vieja en disco local)
compilaban contra el frontend viejo y PISABAN meses de upgrades en produccion
(incidente 03/10/2026: regresion del buscador de llaves y perdida de features). El
repo git es el unico que tiene todos los upgrades de sep/oct.

## Contexto del Sistema
Este es un sistema de gestión de llaves para vigilancia de la FCEA (Facultad de
Ciencias Económicas y de Administración). Incluye tres interfaces principales:
TERMINAL A, TERMINAL B (para solicitar llaves), MONITOR DE VIGILANCIA para gestionar
entregas/devoluciones; además tiene pestañas con módulos: Dashboard, objetos,
agenda/autorizaciones, historial, configuración, vigilantes, llaves, un monitor de
salud del sistema y un monitor de conexión. Utiliza React/TypeScript en el frontend,
PocketBase como backend, y tiene un sistema robusto de instalación via pendrives,
scripts de mantenimiento automatizado, manejo de objetos olvidados, sistema de
autorizaciones, y funcionalidades de backup/recuperación. El sistema está diseñado
para funcionar en modo kiosko en equipos dedicados. El navegador que está usando es
Edge pero debe funcionar bien con cualquier navegador moderno.

**Hardware:** Si bien los monitores de las terminales son táctiles, tienen tecnología
resistiva antigua inutilizable por lo tanto no van a ser utilizados como táctiles, van
a ser usados como monitores convencionales, cada pc va a tener su teclado y su mouse.
Usar siempre modo "tradicional" en lugar de "tactil" para lanzamiento de navegadores
para que no de conflictos.

## Workflow de Desarrollo
Trabajemos de la siguiente manera: Esta es la laptop de desarrollo, trabajo en Visual
Studio Code, con Cline con openrouter y algún modelo de IA, siempre tiene internet. El
sistema de 3 PC (una terminal de usuario A, una terminal de usuario B que están
ubicadas fuera de la cabina de vigilancia y un monitor vigilancia que hace de servidor
también, que está dentro de la cabina, de uso de vigilantes y jefaturas) de facultad
no tiene internet ni va a tener nunca. Por lo tanto el pendrive es el "CABLE" entre la
laptop de desarrollo y el sistema en producción de facultad para hacer fixes y
upgrades; no puedo copiar y pegar desde esta laptop al sistema de producción.

Entonces: aquí conmigo en Cline VSC yo soy Luis quien te escribe los prompts, tú haces
el fix (arreglo) o el upgrade (nueva funcionalidad o mejora, que hasta puede ser quitar
algo), lo pruebas internamente en esta laptop, me dices que está pronto, lo grabas en
el pendrive cable en la carpeta `FIX\` o en la carpeta `UPGRADES\`, con un nombre
específico representativo con fecha, me das un instructivo paso a paso con nombre
representativo con fecha. Yo desenchufo el pendrive de la laptop, voy a la PC del
sistema que me digas (Terminal A, Terminal B o Monitor vigilancia), lo enchufo y
ejecuto en la PC que corresponde, sigo tus instrucciones, lo pruebo y, si funciona
bien, te digo que funcionó. Ya con el pendrive nuevamente enchufado en la laptop de
desarrollo, tú integras el fix o el upgrade a los archivos más importantes sabiendo
que fue exitoso. Debes hacer los commits e integrar el fix o el upgrade una vez que te
digo que funcionó bien en desarrollo, y NO cuando lo creas.

## Scripts Críticos
Los archivos más importantes que deben actualizarse SIEMPRE son:
- Instalar sistema
- Desinstalar sistema
- Recuperar sistema
- Actualizar semilla

**SOLO SON ESOS**


## Regla de Oro del dist MAESTRO del pendrive rescate (agregada 30/08/2026; nomenclatura actualizada 06/11/2026)
> **¿Qué es el "dist MAESTRO"?** Es la carpeta `dist` (el frontend ya compilado, el
> HTML/JS que ve el vigilante) guardada **dentro del pendrive rescate**, en
> `sistema-llaves-fcea\dist`. Es la versión "oficial/de referencia" del frontend:
> los scripts **Instalar Sistema** y **Recuperar Sistema** NO compilan en producción,
> simplemente **copian ese `dist` tal cual** desde el pendrive rescate a cada PC.

Todo upgrade/fix que cambie el **frontend compilado (`dist`)** y que YA fue probado con
éxito en producción DEBE, además de aplicarse en las 3 PC, **regrabar el `dist` MAESTRO
del pendrive rescate** (en `sistema-llaves-fcea\dist` del pendrive rescate). Si no se
actualiza, una instalación o recuperación futura reinstalaría el **frontend VIEJO**
(perdiendo el upgrade) aunque el commit y el paquete de upgrade estén perfectos.

> ⚠️ **Letra de unidad:** NO se fija. El `dist` maestro vive en el **pendrive
> rescate**; preguntarle a Luis la letra concreta de ese pendrive ANTES de regrabar.

Comando obligatorio (preserva la semilla/config per-PC igual que los upgrades):
```
robocopy <repo>\dist <PENDRIVE_RESCATE>\sistema-llaves-fcea\dist /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP
```
**Por qué:** los scripts críticos (INSTALAR / RECUPERAR) NO compilan en producción:
copian ese `dist` tal cual desde el pendrive rescate. Pasó el 30/08/2026: tras aplicar
un upgrade de `dist` en las 3 PC, el `dist` maestro del pendrive seguía con el JS
viejo, por lo que reinstalar/recuperar habría revertido el cambio silenciosamente.

**Checklist al cerrar un upgrade de `dist` que funcionó:**
1. `npm run build` en el repo (deja el `dist` nuevo).
2. Aplicar en las 3 PC (paquete de upgrade con su `APLICAR_UPGRADE.ps1`).
3. **Regrabar el `dist` MAESTRO del pendrive rescate** con el robocopy de arriba.
4. **VERIFICAR (OBLIGATORIO)** que el `dist` maestro quedó IDÉNTICO al `dist` del repo.
5. Commit + push (el `dist` del repo está en .gitignore; lo que se versiona es el
   código fuente y el paquete del upgrade).

### VERIFICACIÓN OBLIGATORIA (hacer SIEMPRE, no es opcional)
```
# 1) Debe dar rc=0 (idénticos). Si da 1, faltó copiar -> repetir el robocopy real.
robocopy <repo>\dist <PENDRIVE_RESCATE>\sistema-llaves-fcea\dist /L /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP
# 2) Los hashes de index.html y del bundle JS deben COINCIDIR entre repo y pendrive.
(Get-FileHash <repo>\dist\index.html).Hash ; (Get-FileHash <PENDRIVE_RESCATE>\sistema-llaves-fcea\dist\index.html).Hash
```
Como el build compila TODO el código fuente, ese `dist` ya trae todos los upgrades
históricos juntos; la verificación asegura que ninguno quedó afuera y que el pendrive
no arrastra JS viejo. Verificado OK el 30/08/2026 (rc=0 + hashes idénticos).

## Regla de Oro del ROLLBACK confiable (agregada 05/10/2026)
Todo `QUITAR_*.ps1` / `2-DESHACER_ROLLBACK.bat` que restaure un `dist_backup_*`
NUNCA debe restaurar ciegamente "el mas nuevo por nombre". DEBE recorrer los
backups del mas nuevo al mas viejo y restaurar el PRIMERO que este **SANO**,
entendiendo por sano que su `index.html` referencie un `assets/index-*.js` que
EXISTA fisicamente en esa carpeta de backup. Si ninguno esta sano, abortar y
avisar que se use el pendrive de RESCATE (Recuperar Sistema).

**Por que:** el 05/10/2026 un fix de frontend dejo el Monitor en blanco; el
rollback restauro el backup mas nuevo, pero ese backup ya contenia el dist ROTO
(porque el fix se habia aplicado mas de una vez) -> el rollback NO salvo y hubo
que ir a recuperacion de emergencia. Validar que el backup este sano antes de
restaurarlo evita repetirlo. Plantilla probada: `QUITAR_FIX.ps1` del paquete
`FIX_HISTORIAL_LENTO_SCROLL_INFINITO_2026-10-05` (funcion `Test-DistSano`).


## Regla de Oro (grabar en todas partes tras éxito)
Una mejora/upgrade o fix, UNA VEZ QUE FUE PROBADA CON ÉXITO EN EL SISTEMA DE
PRODUCCIÓN (3 PC sin internet) POR MÍ, debe quedar grabada en todas partes: aquí en la
laptop de desarrollo, en GitHub, y en el pendrive también. Tiene que ser un proceso de
mejora incremental que vaya quedando comiteado y respaldado para que sirva de respaldo
de rollback, y **nunca olvidar hacer commit con timestamp y subir a GitHub una vez que
el arreglo o el upgrade funcionó bien**. Esto es útil porque muchas veces se crean
archivos que se intentan pero fallan.

## Regla Pendrive = Cable (agregada 31/07/2026)
El pendrive cable es el ÚNICO "cable" con el sistema appliance de facultad (3 PC sin
internet). Por lo tanto: **cada fix o upgrade nuevo que crees debe grabarse SIEMPRE
también en el pendrive cable**, no solo en la carpeta `FIX\` o `UPGRADES\` del repo de
desarrollo. No tiene sentido que Luis lo copie a mano.

Flujo obligatorio de cada intento:
1. Creás/actualizás el fix o upgrade en el repo (`fix/` o `upgrades/`).
2. Lo grabás en el pendrive cable (mismo contenido) para que Luis pueda enchufarlo y
   probarlo en producción.
3. Si el intento **NO sirvió**, se borra de **TODAS partes** (repo + pendrive) y se
   graba el **siguiente intento** (próxima versión). Así hasta que funcione.
4. Recién cuando Luis confirma acá en la laptop de desarrollo que **funcionó en
   producción**, se integra a los scripts críticos y se hace el commit con timestamp
   (ver "Regla de Oro" y "Nueva Regla Fix Carpeta").

Recordatorio: la letra de unidad del pendrive **puede variar**; Cline debe
preguntar/confirmar a Luis cuál es ANTES de grabar o leer.

## Nueva Regla Fix Carpeta (30/07/2026)
Cada vez que crees un nuevo archivo tratando de solucionar un problema en la carpeta
`FIX\` o en la carpeta `UPGRADES\`, borra el anterior: debe quedar solo el archivo que
funcione con el instructivo de éste. No puede quedar el script V1 V2 V3 V4 si ninguna
funcionó y además todas con su correspondiente instructivo, porque eso llena de
archivos basura QUE NO SIRVEN DE NADA. Debe quedar solo el archivo con el instructivo
que funcione, ADEMÁS DE LA INTEGRACIÓN DE ÉSTE A LOS SCRIPTS CRÍTICOS. ¿Cómo sabes que
funcionó? Porque te lo voy a decir aquí en la laptop de desarrollo. Por ejemplo "acabo
de probar el archivo para poder conectar el Terminal B y ¡funcionó!"; ahí recién
comiteas e integras.

Los scripts de diagnóstico (solo lectura, no modifican el sistema) pueden generarse
libremente durante la investigación. Solo se aplica la regla de limpieza a los scripts
que intentan modificar/reparar el sistema.

## Carpeta HERRAMIENTAS_RED (Caja de Herramientas Permanente)
La carpeta `HERRAMIENTAS_RED` (ubicada en el pendrive, FUERA de las carpetas `FIX\` /
`UPGRADES\`) es una caja de herramientas de diagnóstico y reparación **PERMANENTE y
reutilizable** entre las tres terminales (Terminal A, Terminal B, Monitor Vigilancia).

**IMPORTANTE:** a esta carpeta **NO se le aplica** la regla de limpieza de la "Nueva
Regla Fix Carpeta". Aquí SÍ se pueden acumular herramientas con nombres descriptivos,
por ejemplo:
- `DIAGNOSTICAR_RED`
- `VERIFICAR_CONFIG_ACTUAL`
- `CAZAR_POCKETBASE_ZOMBIE`
- `ARRANCAR_POCKETBASE`
- `MATAR_POCKETBASE_ZOMBIE`
- `REPARAR_CONFIG`

Cada herramienta nueva relevante debe sumarse ahí, **NO en FIX/UPGRADES**, y debe
seguir la convención existente de par lanzador `.bat` + script `.ps1` (por ejemplo:
`DIAGNOSTICAR_RED.bat` que lanza `DIAGNOSTICAR_RED.ps1`).

## Regla de Límite de Diagnóstico
Ante un bug, se permite generar diagnósticos de solo lectura libremente. Pero
**después de reunir evidencia suficiente** (o si ya existen herramientas de diagnóstico
previas en `HERRAMIENTAS_RED` que cubran el caso), el modelo debe **comprometerse con
una hipótesis principal y proponer un fix concreto**, en vez de seguir generando
rondas de diagnóstico.

Si la certeza es menor al 80%, debe decir explícitamente **qué información puntual
falta**, sin repetir diagnósticos ya cubiertos.

## Regla de Logs de Diagnóstico al Pendrive (agregada 03/08/2026)
Todo script de diagnóstico o prueba que le hago correr a Luis **debe escribir su salida
(output) a un archivo `.log` en el pendrive**, con un nombre descriptivo que incluya el
tema, la PC y la fecha/hora (ej.: `LOG_ARRANQUE_LENTO_MONITOR_2026-08-03_1830.log`). El
log se guarda en la subcarpeta `_RESULTADOS\` (o al lado del script), **no** en el
escritorio de la PC de producción.

**Motivo:** el pendrive es el "cable". Guardando el output en el pendrive, Luis solo lo
trae de vuelta y **Cline lee el `.log` directamente** desde la laptop de desarrollo,
sin que Luis tenga que sacar y pegar fotos de la pantalla.

**Formato obligatorio de cada diagnóstico:**
- Usar `Start-Transcript` (PowerShell) o redirección `>> archivo.log 2>&1` (batch)
  hacia el pendrive.
- Encabezar el log con: fecha/hora, nombre de la PC (`$env:COMPUTERNAME`) y qué se está
  diagnosticando.
- Al terminar, mostrar en pantalla la ruta exacta del `.log` generado para que Luis
  sepa qué traer.
- Los diagnósticos siguen siendo **solo lectura** (no modifican el sistema).

## Bitácora
- **Modelo de trabajo desde 30/07/2026:** anthropic/claude-opus-4.8 (antes: Sonnet 4).
- **06/11/2026:** unificación de las 3 copias de reglas en un único texto maestro;
  fusionadas las reglas que solo estaban en `.clinerules` (Pendrive = Cable, Nueva
  Regla Fix Carpeta, HERRAMIENTAS_RED, Límite de Diagnóstico, Logs al Pendrive);
  neutralizadas las letras de unidad fijas (pendrive "cable"/"rescate"); agregada la
  "Regla de Oro de la Prolijidad del Pendrive".

El instructivo tambien debe dar un comando de verificacion para correr en la propia PC.
