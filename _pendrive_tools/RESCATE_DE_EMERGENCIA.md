# 🚨 RESCATE DE EMERGENCIA — Sistema FCEA

Esta guía es tu **red de contención** para los 3 problemas más frecuentes que ya
diagnosticamos en producción. **Si algo se rompe, primero corré el diagnóstico,
después la solución de la sección que corresponde**. No hay que adivinar nada,
cada script te dice qué está mal y cómo arreglarlo.

Todos los scripts están en `D:\HERRAMIENTAS_RED\` del pendrive (letra puede variar).
Antes de usarlos, **enchufá el pendrive** en la PC afectada.

---

## 🩺 SIEMPRE EMPEZAR POR EL DIAGNÓSTICO

En la PC que tiene el problema (Monitor o Terminal):

**Doble clic en `D:\HERRAMIENTAS_RED\DIAGNOSTICAR_RED.bat`**

No toca nada. Solo muestra:
- IPs y hostname
- Qué dice el `config.json`
- Si hay algún PocketBase corriendo
- Cuántas solicitudes tiene la base

Sacá foto de la pantalla. Con eso identificás cuál de los 3 problemas es.

---

## 🔴 PROBLEMA 1: El Monitor NO puede grabar nada ("Error al guardar")

**Síntoma en la UI:**
- Al agregar vigilante → "Error al agregar vigilante"
- Al aceptar solicitud → falla
- Todo lo que se LEE se ve bien, pero al ESCRIBIR falla

**Causa técnica**: `data.db` de SQLite se quedó "congelado" y los cambios se
acumulan en el `data.db-wal` sin poder aplicarse (WAL huérfano).

### 🔧 Solución en 3 pasos

En el Monitor (con permisos de admin):

1. **Doble clic en `D:\HERRAMIENTAS_RED\CAZAR_POCKETBASE_ZOMBIE.bat`**
   - Corre el diagnóstico completo.
   - Al final pregunta: `¿Ejecutar ya el paso 1 (matar todo pocketbase.exe)? (S/N):`
   - Escribí **`S`** y ENTER.
   - Cuando termine → apretá ENTER para cerrar.

2. **Doble clic en `D:\HERRAMIENTAS_RED\ARRANCAR_POCKETBASE.bat`**
   - Aceptá el UAC (permisos de administrador).
   - Hace un backup automático de `data.db` (por si acaso, no se pierde nada).
   - Levanta PocketBase con los mismos parámetros de siempre.
   - Prueba CREATE en una colección y te confirma con `[OK]`.
   - **NO CIERRES la ventanita "C:\sistema-llaves-fcea\pocketbase\pocketbase.exe"**
     que quedó abierta — ese ES el PocketBase corriendo.

3. **En Chrome del Monitor: F5** (refrescar).
   - Probá agregar cualquier cosa.
   - Debería funcionar.

### ⚠️ Si sigue fallando después de ARRANCAR_POCKETBASE

- Sacá foto del paso `[7]` del script.
- El backup de `data.db` está en `C:\ProgramData\FCEA-Sistema-Llaves\pb_data\data.db.bak_YYYYMMDD_HHMMSS`.
- Contactar soporte. Plan B: recuperar la base con `sqlite3 .recover`.

---

## 🔴 PROBLEMA 2: Terminal-A/B hace pedidos pero NO aparecen en el Monitor

**Síntoma:**
- En Terminal-A pedís una llave → dice "solicitud enviada".
- En el Monitor NO aparece.
- Ambos están conectados a la red (ping OK entre ellos).

**Causa típica**: el `config.json` de la Terminal tiene `pocketbaseUrl` vacío
o apuntando a `127.0.0.1` en vez de a la IP del Monitor.

### 🔧 Solución en 2 pasos

**En el MONITOR primero** (esto es opcional, solo si no responde):

Doble clic en `D:\HERRAMIENTAS_RED\REPARAR_CONFIG.bat`

- Auto-detecta que es el Monitor.
- Deja `pocketbaseUrl = http://127.0.0.1:8090`.

**En la TERMINAL** (Terminal-A o Terminal-B):

Doble clic en `D:\HERRAMIENTAS_RED\REPARAR_CONFIG.bat`

- Auto-detecta que es Terminal.
- Te pregunta la IP del Monitor. Por defecto es `192.168.100.10`.
- Confirmá con ENTER (o escribí la IP correcta si es distinta).
- Escribe `pocketbaseUrl = http://192.168.100.10:8090`.

**Test:**
- En Terminal, refrescá con F5.
- Pedí una llave.
- En Monitor debe aparecer en menos de 3 segundos.

Si en Terminal la app te dice "sin conexión" antes de poder pedir, primero
corré `DIAGNOSTICAR_RED.bat` en la Terminal para ver si el ping al Monitor
funciona.

---

## 🔴 PROBLEMA 3: El Monitor perdió la IP fija 192.168.100.10

**Síntoma:**
- Las Terminales no lo encuentran (no pueden hacer pedidos).
- Al hacer `ipconfig` en el Monitor, la IP es algo tipo `192.168.1.x` o `169.254.x.x`.

### 🔧 Solución

En el Monitor:

Doble clic en `D:\HERRAMIENTAS_RED\FIJAR_IP_MONITOR.bat`

- Auto-detecta la interfaz Ethernet.
- Le fija IP = `192.168.100.10 / 24`.
- Hace backup de la configuración anterior por si hay que revertir.

Después, en cada Terminal, correr `REPARAR_CONFIG.bat` (ver Problema 2).

---

## 📞 Contactos y datos

- **Admin PocketBase**: `vigilancia@llaves.local` / `vigilanciamvp2026`
- **URL Monitor local**: http://127.0.0.1:8090 (PocketBase) / http://127.0.0.1:4173 (frontend)
- **URL desde Terminales**: http://192.168.100.10:8090
- **Repo**: `sistema-de-gesti-n-de-llaves-vigilancia-fcea` (rama principal)
- **Tag de rescate del 26/07/2026**: `rescate-26jul2026`

## 🔒 Regla de oro

**No cierres las ventanitas negras** de PocketBase ni del frontend que quedan
abiertas después de arrancar el sistema. Son los servicios corriendo — cerrarlas
es apagar el sistema.

Si por error cerraste algo: doble clic en el escritorio en el ícono del sistema
(o correr `C:\sistema-llaves-fcea\scripts\install\INICIAR.bat`) y vuelve a
arrancar todo.
