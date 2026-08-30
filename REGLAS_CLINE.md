# REGLAS CLINE - LEE ESTO PRIMERO EN CADA NUEVA TAREA
**Creado: 28/07/2026 16:56 · última modificación: 03/08/2026 16:55**

## Restricciones Técnicas
No accedas ni leas archivos dentro de la carpeta `node_modules/` ya que contiene dependencias de terceros que están pre-auditadas y funcionando correctamente. Leer estos archivos consume tokens innecesarios, aumenta el contexto sin aportar valor al desarrollo, y puede causar errores de límite de contexto. Las dependencias de JavaScript/TypeScript en node_modules son estables y no requieren modificación ni revisión.

## Contexto del Sistema
Este es un sistema de gestión de llaves para vigilancia de la FCEA (Facultad de Ciencias Económicas y de Administración). Incluye tres interfaces principales: TERMINAL A, TERMINAL B (para solicitar llaves), MONITOR DE VIGILANCIA para gestionar entregas/devoluciones además tiene pestañas con módulos; Dashboard, objetos, agenda/autorizaciones, historial, configuración, vigilantes, llaves, un monitor de salud del sistema, un monitor de conexión. Utiliza React/TypeScript en el frontend, PocketBase como backend, y tiene un sistema robusto de instalación via pendrives, scripts de mantenimiento automatizado, manejo de objetos olvidados, sistema de autorizaciones, y funcionalidades de backup/recuperación. El sistema está diseñado para funcionar en modo kiosko en equipos dedicados. El navegador que está usando es Edge pero debe funcionar bien con cualquier navegador moderno.

**Hardware:** Si bien los monitores de las terminales son táctiles, tienen tecnología resistiva antigua inutilizable por lo tanto no van a ser utilizados como táctiles, van a ser usados como monitores convencionales, cada pc va a tener su teclado y su mouse. Usar siempre modo "tradicional" en lugar de "tactil" para lanzamiento de navegadores para que no de conflictos.

## Workflow de Desarrollo
Trabajemos de la siguiente manera: Esta es la laptop de desarrollo trabajo en Visual Studio Code, con Cline con openrouter, y algún modelo de IA, siempre tiene internet, el sistema de 3 pc (una terminal de usuario A, una terminal de usuario B que están ubicadas fuera de la cabina de vigilancia y un monitor vigilancia que hace de servidor también que está dentro de la cabina que son de uso de vigilantes y jefaturas) de facultad no tiene internet ni va a tener nunca, por lo tanto el pendrive es el "CABLE" entre la laptop de desarrollo y el sistema en producción de facultad para hacer fixes y upgrades por lo tanto no puedo copiar y pegar desde este laptop y pegar en el sistema de produccion.

Entonces: aquí conmigo en cline VSC yo soy Luis quien te escribe los prompts, tu haces el fix (arreglo) o el upgrade (nueva funcionalidad o mejora que hasta puede ser quitar algo), lo pruebas internamente en esta laptop, me dices que está pronto, lo grabas en el pendrive en la carpeta fix o en la carpeta upgrades, con un nombre específico representativo fecha y hora, me das un instructivo paso a paso con nombre representativo fecha y hora, yo desenchufo el pendrive de la laptop voy a la pc del sistema que me digas (terminal A, terminal B, o Monitor vigilancia) lo enchufo y ejecuto en la pc que corresponde, sigo tus instrucciones lo pruebo y si funciona bien te digo que funcionó. Ya con el pendrive nuevamente enchufado en la laptop de desarrollo, tu lo integras el fix o el upgrade a los archivos más importantes sabiendo que fue exitoso. Debes hacer los commits e integrar el fix o el upgrade una vez que te digo que funcionó bien en desarrollo y no cuando lo creas.

## Scripts Críticos
Los archivos más importantes que deben actualizarse SIEMPRE son:
- Instalar sistema
- Desinstalar sistema  
- Recuperar sistema
- Actualizar semilla
**SOLO SON ESOS**

## Regla de Oro del dist MAESTRO del pendrive (agregada 30/08/2026)
Todo upgrade/fix que cambie el **frontend compilado (`dist`)** y que YA fue probado con
éxito en producción DEBE, además de aplicarse en las 3 PC, **regrabar el `dist` MAESTRO
del pendrive** en `D:\sistema-llaves-fcea\dist`. Ese `dist` es el que copian **Instalar
Sistema** y **Recuperar Sistema** a cada PC. Si no se actualiza, una instalación o
recuperación futura reinstalaría el **frontend VIEJO** (perdiendo el upgrade) aunque el
commit y el paquete de upgrade estén perfectos.

Comando obligatorio (preserva la semilla per-PC igual que los upgrades):
```
robocopy <repo>\dist D:\sistema-llaves-fcea\dist /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP
```
**Por qué:** el `dist` de `D:\sistema-llaves-fcea\dist` es la "fuente maestra" del
frontend en el pendrive-cable. Los scripts críticos (INSTALAR.bat / RECUPERAR) NO
compilan en producción: copian ese `dist` tal cual. Pasó el 30/08/2026: tras aplicar un
upgrade de `dist` en las 3 PC, el `dist` maestro del pendrive seguía con el JS viejo, por
lo que reinstalar/recuperar habría revertido el cambio silenciosamente.

**Checklist al cerrar un upgrade de `dist` que funcionó:**
1. `npm run build` en el repo (deja el `dist` nuevo).
2. Aplicar en las 3 PC (paquete de upgrade con su `APLICAR_UPGRADE.ps1`).
3. **Regrabar el `dist` MAESTRO del pendrive** con el robocopy de arriba.
4. **VERIFICAR (OBLIGATORIO)** que el `dist` maestro quedó IDÉNTICO al `dist` del repo
   (ver bloque de verificación abajo). Como el build compila todo el código fuente, ese
   `dist` ya trae TODOS los upgrades históricos juntos; esta verificación garantiza que
   ninguno quedó afuera y que el pendrive no arrastra JS viejo.
5. Commit + push (el `dist` del repo está en .gitignore; lo que se versiona es el código
   fuente y el paquete del upgrade).

### VERIFICACIÓN OBLIGATORIA (hacer SIEMPRE, no es opcional)
```
# 1) Debe dar rc=0 (idénticos). Si da 1, faltó copiar -> repetir el robocopy real.
robocopy <repo>\dist D:\sistema-llaves-fcea\dist /L /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP
# 2) Los hashes de index.html y del bundle JS deben COINCIDIR entre repo y pendrive.
(Get-FileHash <repo>\dist\index.html).Hash ; (Get-FileHash D:\sistema-llaves-fcea\dist\index.html).Hash
```
Verificado OK el 30/08/2026: `robocopy /L` dio rc=0 y los hashes de `index.html` y del
bundle JS coincidieron exactamente entre repo y pendrive → el `dist` maestro contiene
todos los upgrades históricos.

## Regla de Oro
Una mejora/upgrade o fix UNA VEZ QUE FUE PROBADA CON ÉXITO EN EL SISTEMA DE PRODUCCIÓN (3 pc sin internet) POR MI debe quedar grabada en todas partes, eso significa aquí en la laptop de desarrollo, en github, y en el pendrive también. Tiene que ser un proceso de mejora incremental y que vaya quedando comiteada y respaldada para que sirva de respaldo de rollback y **nunca olvidar hacer commit con timestamp y subir a github una vez que el arreglo o el upgrade funcionó bien** que fue útil porque muchas veces creas archivos que lo intentas pero fallan. 

## Regla Pendrive = Cable (agregada 31/07/2026)
El pendrive es el ÚNICO "cable" con el sistema appliance de facultad (3 PC sin internet). Por lo tanto: **cada fix o upgrade nuevo que crees debe grabarse SIEMPRE también en el pendrive**, no solo en la carpeta `fix/` o `upgrades/` del repo de desarrollo. No tiene sentido que Luis lo copie a mano.

Flujo obligatorio de cada intento:
1. Creás/actualizás el fix o upgrade en el repo (`fix/` o `upgrades/`).
2. Lo grabás en el pendrive (mismo contenido) para que Luis pueda enchufarlo y probarlo en producción.
3. Si el intento **NO sirvió**, se borra de **TODAS partes** (repo + pendrive) y se graba el **siguiente intento** (próxima versión). Así hasta que el fix/upgrade funcione.
4. Recién cuando Luis confirma acá en la laptop de desarrollo que **funcionó en producción**, se integra a los scripts críticos y se hace el commit con timestamp (ver "Regla de Oro" y "Nueva Regla Fix Carpeta").

Recordatorio: la letra de unidad del pendrive puede variar; preguntar/confirmar cuál es antes de grabar (históricamente `D:`).

## Nueva Regla Fix Carpeta (30/07/2026)
Cada vez que crees un nuevo archivo tratando de solucionar un problema en la carpeta fix o en la carpeta upgrade, borra el anterior, debe quedar solo el archivo que funcione con el instructivo de este. No puede quedar el script V1 V2 V3 V4 si ninguna funcionó y además todas tienen su correspondiente instructivo lo que llena de archivos basura QUE NO SIRVEN DE NADA, debe quedar solo el archivo con el instructivo que funcione ADEMÁS DE LA INTEGRACIÓN DE ESTE A LOS SCRIPTS CRÍTICOS, Cómo sabes que funcionó? Porque te lo voy a decir aquí en la laptop de desarrollo. Por ejemplo "acabo de probar el archivo para poder conectar el terminal B y funcionó!" ahí recién comiteas e integras

## Regla de Logs de Diagnóstico al Pendrive (agregada 03/08/2026)
Todo script de diagnóstico o prueba que le hago correr a Luis **debe escribir su salida (output) a un archivo `.log` en el pendrive**, con un nombre descriptivo que incluya el tema, la PC y la fecha/hora (ej.: `LOG_ARRANQUE_LENTO_MONITOR_2026-08-03_1830.log`). El log se guarda al lado del script (o en una subcarpeta `_RESULTADOS`), **no** en el escritorio de la PC de producción.

**Motivo:** el pendrive es el "cable". Guardando el output en el pendrive, Luis solo lo trae de vuelta y **Cline lee el `.log` directamente** desde la laptop de desarrollo, sin que Luis tenga que sacar y pegar fotos de la pantalla.

**Formato obligatorio de cada diagnóstico:**
- Usar `Start-Transcript` (PowerShell) o redirección `>> archivo.log 2>&1` (batch) hacia el pendrive.
- Encabezar el log con: fecha/hora, nombre de la PC (`$env:COMPUTERNAME`) y qué se está diagnosticando.
- Al terminar, mostrar en pantalla la ruta exacta del `.log` generado para que Luis sepa qué traer.
- Los diagnósticos siguen siendo **solo lectura** (no modifican el sistema).
