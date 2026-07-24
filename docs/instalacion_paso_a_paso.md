pr# Instalación paso a paso del Sistema FCEA

> **Para quién es esta guía:** para quien tiene los pendrives `SISTEMA_FCEA`
> y necesita instalar el sistema en 2 o 3 PCs **desde cero**, sin conocimientos
> técnicos avanzados.
>
> **Tiempo total estimado:** 30 a 45 minutos para 3 PCs.
>
> **Versión del sistema:** v3.2 (junio 2026)

---

## 0. Antes de empezar - lo que necesitás

- [ ] **Las PCs** (2 o 3) con Windows 10 u 11 instalado y arrancado.
- [ ] **Un switch de red** (cualquier switch común de 4 u 8 bocas, no necesita ser caro).
- [ ] **Cables de red** (RJ45), un cable por cada PC.
- [ ] **Pendrive `SISTEMA_FCEA`** (cualquiera de los pendrives, son idénticos).
- [ ] **Cuenta de usuario con permisos de administrador** en cada PC (importante).
- [ ] **Saber cuál PC tiene más memoria RAM** (esa va a ser el SERVIDOR).
  - Para saberlo: clic derecho en "Este equipo" o "Mi PC" → Propiedades → fijate en "RAM instalada".
  - Lo ideal: 16 GB o más. Lo mínimo aceptable: 8 GB.

---

## 1. Cableado físico

- [ ] **Apagá** las 3 PCs (o por ahora dejalas apagadas).
- [ ] Enchufá el **switch** a la corriente y prendelo.
- [ ] Conectá un **cable de red** desde cada PC a una boca cualquiera del switch.
  - No importa el orden de las bocas.
  - Verificá que las luces del switch se enciendan al conectar cada cable.
- [ ] **Prendé las 3 PCs** y esperá a que carguen Windows completamente en cada una.

---

## 2. Identificar la PC SERVIDOR

- [ ] Elegí una PC para que sea el **servidor** (la de la cabina de vigilancia).
- [ ] Esa va a ser **la que más memoria RAM tenga**.
- [ ] Esa PC va a estar **encendida 24 horas, todos los días**.
- [ ] Ponele un cartelito físico que diga "SERVIDOR - NO APAGAR".

Las otras 2 PCs serán las **terminales** (las que ven los usuarios afuera de la cabina).

---

## 3. INSTALAR EN LA PC SERVIDOR (primera)

> ⚠️ IMPORTANTE: la PC servidor se instala **PRIMERA**. Las terminales después,
> porque necesitan que el servidor ya esté funcionando para detectarlo.

### 3.1 Conectar el pendrive

- [ ] Andá hasta la PC servidor (la de la cabina).
- [ ] Conectá el pendrive `SISTEMA_FCEA` en un puerto USB.
- [ ] Abrí el "Explorador de archivos" (la carpetita amarilla en la barra de tareas).
- [ ] En la barra de la izquierda, hacé clic en el pendrive (aparece como `SISTEMA_FCEA (E:)` o similar).

### 3.2 Lanzar el instalador

- [ ] Vas a ver archivos llamados:
  - `INSTALAR SISTEMA.bat`
  - `DESINSTALAR SISTEMA.bat`
  - `RECUPERAR SISTEMA.bat`
  - `LEEME_PRIMERO.txt`
  - una carpeta `Documentacion`

- [ ] **Hacé clic DERECHO** sobre `INSTALAR SISTEMA.bat`.
- [ ] Del menú que aparece, elegí **"Ejecutar como administrador"**.
- [ ] Aparece la ventana de Windows pidiendo permiso (UAC). Hacé clic en **"Sí"**.

### 3.3 Responder las preguntas del instalador

Se abre una ventana negra (consola). Va a hacer 2-3 preguntas:

- [ ] **"Seleccione modo [1-2]"** → escribí `2` y presioná Enter.
  - (Modo 2 = PRODUCCION con 3 PCs)

- [ ] **"Rol [S/A/B/D]"** → escribí `S` (de Servidor) y presioná Enter.

- [ ] El instalador detecta automáticamente el tipo de hardware (táctil o tradicional).
  Si te pregunta para confirmar, simplemente presioná **Enter** para aceptar lo detectado.

### 3.4 Esperar a que termine

- [ ] El instalador va a tardar **5 a 10 minutos**. Vas a ver muchos mensajes en verde.
- [ ] **NO cierres la ventana negra** ni tocás nada hasta que diga **"Instalacion finalizada"**.
- [ ] Cuando aparezca "Presione una tecla para continuar...", presioná cualquier tecla.

### 3.5 Reiniciar y verificar

- [ ] **Reiniciá la PC servidor** (menú Inicio → Encendido → Reiniciar).
- [ ] Cuando vuelva a iniciar, **el sistema debería arrancar SOLO** en modo pantalla completa
  mostrando el "Monitor de Vigilancia".
- [ ] Si arrancó solo y ves el monitor, **¡la PC servidor está lista!** ✅
- [ ] Si no arranca solo (después de 1-2 minutos), abrí `RECUPERAR SISTEMA.bat` (como admin)
  y elegí la opción "Reparar inicio automático".

### 3.6 Anotar dato útil (opcional)

- [ ] Antes de cerrar la cabina, sería útil saber la IP del servidor.
  Para verla: presioná las teclas **Ctrl + Alt + Supr** → Administrador de tareas →
  pestaña "Rendimiento" → "Ethernet" → vas a ver algo como **192.168.1.10**.
- [ ] Anotalo en un papel. (Aunque casi seguro NO lo vas a necesitar, gracias a la
  autodetección.)

### 3.7 Sacar el pendrive

- [ ] Hacé clic en el ícono de pendrive en la bandeja del sistema (esquina inferior derecha)
  y elegí "Expulsar SISTEMA_FCEA".
- [ ] Sacá el pendrive físicamente.

---

## 4. INSTALAR EN LA TERMINAL A (segunda PC)

> ⚠️ ANTES DE EMPEZAR: la PC servidor tiene que estar **encendida y funcionando**.
> Si no, la terminal no la va a poder encontrar.

### 4.1 Conectar pendrive y lanzar instalador

- [ ] Conectá el pendrive `SISTEMA_FCEA` en la PC TERMINAL A.
- [ ] Abrí el Explorador, andá al pendrive.
- [ ] Clic derecho en `INSTALAR SISTEMA.bat` → "Ejecutar como administrador".
- [ ] Clic en "Sí" en el UAC.

### 4.2 Responder las preguntas

- [ ] **"Seleccione modo [1-2]"** → `2` Enter.
- [ ] **"Rol [S/A/B/D]"** → `A` Enter (terminal A).
- [ ] El instalador dirá: **"Buscando servidor FCEA en la red local automaticamente..."**
- [ ] Esperá 5-10 segundos.

#### 4.2.a CASO IDEAL: encontró el servidor

- [ ] Aparece: **`[OK] Servidor FCEA encontrado automaticamente en: 192.168.1.10`**
  (o similar).
- [ ] Te pregunta "Confirmar (Enter para aceptar, N para escribirla manualmente)".
- [ ] Presioná **Enter** para aceptar.
- [ ] ¡Listo! Seguí en el paso 4.3.

#### 4.2.b CASO PROBLEMA: NO encontró el servidor

- [ ] Aparece: **`[!] No se encontro el servidor automaticamente.`**
- [ ] Quiere decir que la PC servidor está apagada, mal conectada al switch, o el firewall
  está bloqueando.
- [ ] Volvé a la cabina, verificá que esté **encendida** y que el cable de red esté firme.
- [ ] Si está todo bien y aún así no la encuentra, escribí la IP que anotaste en el paso 3.6
  (ej. `192.168.1.10`) y presioná Enter.

### 4.3 Esperar y reiniciar

- [ ] El instalador tarda **3 a 5 minutos** (menos que el servidor porque no instala la base).
- [ ] Cuando termine, **reiniciá** la terminal.
- [ ] Al volver a iniciar, debería aparecer la **"Terminal de Usuario"** en pantalla completa.

### 4.4 Verificar conexión

- [ ] La terminal debería mostrar una pantalla donde el usuario puede buscar su nombre y pedir
  una llave.
- [ ] Si en lugar de eso aparece un cartel rojo de error "No se puede conectar al servidor":
  - Verificá que el cable de red de la terminal esté bien.
  - Verificá que el servidor esté encendido.
  - Si persiste, ejecutá `RECUPERAR SISTEMA.bat` desde el pendrive.

---

## 5. INSTALAR EN LA TERMINAL B (tercera PC)

> Es **idéntico** al paso 4, pero respondiendo `B` en lugar de `A`.

- [ ] Conectá el pendrive en la PC TERMINAL B.
- [ ] Clic derecho `INSTALAR SISTEMA.bat` → "Ejecutar como administrador" → "Sí".
- [ ] Modo: `2` Enter.
- [ ] **Rol: `B`** Enter.
- [ ] Confirmar el servidor encontrado automáticamente (Enter).
- [ ] Esperar 3-5 minutos.
- [ ] Reiniciar.
- [ ] Verificar que aparezca la Terminal de Usuario.

---

## 6. Verificación final del sistema completo

Con las 3 PCs encendidas y arrancadas en modo kiosk:

- [ ] **Servidor** (cabina): muestra el Monitor de Vigilancia con tabla de llaves disponibles.
- [ ] **Terminal A** (puesto A): muestra la pantalla de "Solicitar Llave".
- [ ] **Terminal B** (puesto B): muestra la pantalla de "Solicitar Llave".

### Hacer una prueba end-to-end

- [ ] Desde la Terminal A, pedí una llave de prueba (escribí un nombre cualquiera).
- [ ] Vas a la cabina y deberías ver la solicitud aparecer en el Monitor de Vigilancia.
- [ ] Autorizá la solicitud.
- [ ] Volvé a la Terminal A y verificá que cambió a "Llave en uso".
- [ ] Hacé el devolución desde el monitor.

Si todo eso funciona: **el sistema está 100% operativo** ✅

---

## 7. Qué hace el sistema automáticamente (sin que tengas que hacer nada)

### En el servidor (la PC de la cabina):

- ✅ **Backup diario** a las 3:00 AM, conservando los últimos 30 días.
- ✅ **Watchdog cada 5 minutos**: si el motor de base de datos se cae, lo reinicia.
- ✅ **Chequeo de salud cada 15 minutos**: detecta problemas y los avisa en el monitor.
- ✅ **Arranque automático**: al prender la PC, el sistema arranca solo en modo kiosk.

### En las terminales:

- ✅ **Arranque automático** en modo kiosk al prender.
- ✅ **Reconexión automática** si el servidor se reinicia.

---

## 8. ¿Qué hacer si algo falla?

### 8.1 La PC servidor se cuelga, no responde

1. Apretá el botón de power 5 segundos para forzar apagado.
2. Volvé a prender.
3. Esperá 2 minutos a que arranque el sistema solo.
4. **Los datos NO se pierden** porque están en disco.

### 8.2 Una terminal no encuentra al servidor

1. Verificá el cable de red de la terminal y del servidor.
2. Reiniciá la terminal.
3. Si persiste: pendrive → `RECUPERAR SISTEMA.bat` → "Reparar conexión".

### 8.3 El sistema da errores raros, pantallas en blanco, etc.

> 🛡️ Filosofía del sistema v3.1: los datos NUNCA se pierden por desinstalar.

**Opción A - Reparación rápida:**

1. Conectá el pendrive `SISTEMA_FCEA`.
2. Clic derecho `RECUPERAR SISTEMA.bat` → "Ejecutar como administrador".
3. Seguí las indicaciones.

**Opción B - Reinstalación limpia (si nada más funciona):**

1. Conectá el pendrive.
2. Clic derecho `DESINSTALAR SISTEMA.bat` → "Ejecutar como administrador".
   - 👍 Esto **NO borra los datos** (siguen en `C:\ProgramData\FCEA-Sistema-Llaves\`).
3. Reiniciá la PC.
4. Conectá el pendrive otra vez.
5. Clic derecho `INSTALAR SISTEMA.bat` → "Ejecutar como administrador".
6. Respondé las mismas preguntas que la primera vez (modo 2, rol S/A/B).
7. El instalador **detecta los datos existentes y los respeta**.
8. Reiniciá.

Resultado: sistema nuevo, todos los datos **exactamente como estaban antes** del problema.

### 8.4 Corte de luz prolongado

- Las PCs se apagan abruptamente.
- Cuando vuelva la luz, prendelas en este orden:
  1. **Primero**: el switch de red.
  2. **Después**: la PC servidor (esperá 2 minutos a que arranque sola).
  3. **Por último**: las terminales A y B.
- PocketBase es a prueba de cortes; las transacciones que estaban en vuelo en el momento
  del corte pueden perderse, pero todo lo confirmado antes está intacto.

---

## 9. Mantenimiento mensual (recomendado, no obligatorio)

- [ ] Una vez por mes, copiar el contenido de
  `C:\ProgramData\FCEA-Sistema-Llaves\pb_backups\` a un disco externo o nube.
  (Por las dudas que falle el disco duro del servidor.)

- [ ] Una vez por año, ejecutar (desde el pendrive)
  `Documentacion\guia_mantenimiento_paso_a_paso.md` para hacer mantenimiento general.

---

## 10. Cosas que NUNCA debés hacer

- ❌ Nunca apagues la PC servidor desenchufándola directamente (usá Inicio → Apagar).
- ❌ Nunca borres carpetas a mano dentro de `C:\sistema-llaves-fcea\` ni
  `C:\ProgramData\FCEA-Sistema-Llaves\`.
- ❌ Nunca instales antivirus que bloquee `C:\sistema-llaves-fcea\pocketbase\pocketbase.exe`.
- ❌ Nunca dejes el pendrive `SISTEMA_FCEA` conectado en producción (es solo para instalar
  / reparar / desinstalar).

---

## ¡Listo!

Si seguiste todos los pasos y la verificación del punto 6 funcionó, el sistema está
operativo. A partir de ahora solo tenés que prender las PCs por la mañana (o dejarlas
prendidas 24/7) y el sistema funciona solo.

Cualquier duda, consultá los manuales en la carpeta `Documentacion\` del pendrive.
