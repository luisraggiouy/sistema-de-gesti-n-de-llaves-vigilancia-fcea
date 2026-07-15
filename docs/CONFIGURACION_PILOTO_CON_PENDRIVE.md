# Configuración piloto con pendrive

**Guía paso a paso para desplegar el Sistema de Gestión de Llaves FCEA v4.4
en las 3 PCs del piloto (1 PC común + 2 PCs con monitor táctil 3nStar TCM008).**

> Guía complementaria a [`escenario_3pcs_mixtas.md`](./escenario_3pcs_mixtas.md).
> Este documento se enfoca **exclusivamente** en la secuencia de acciones
> físicas para dejar el piloto funcionando, sin depender de que yo
> (Cline) esté disponible.

---

## Índice

- [Configuración piloto con pendrive](#configuración-piloto-con-pendrive)
  - [Índice](#índice)
  - [0. Antes de empezar — hoja de ruta y checklist rápido](#0-antes-de-empezar--hoja-de-ruta-y-checklist-rápido)
  - [1. Reparto de PCs y roles](#1-reparto-de-pcs-y-roles)
  - [2. Preparativos en la PC de desarrollo (la tuya)](#2-preparativos-en-la-pc-de-desarrollo-la-tuya)
  - [3. Grabar los 2 pendrives](#3-grabar-los-2-pendrives)
  - [4. Configurar la red LAN del piloto](#4-configurar-la-red-lan-del-piloto)
  - [5. Instalar PC1 — Monitor Vigilancia + Servidor](#5-instalar-pc1--monitor-vigilancia--servidor)
  - [6. Configurar hardware táctil en PC2 y PC3](#6-configurar-hardware-táctil-en-pc2-y-pc3)
  - [7. Instalar PC2 — Terminal-A (táctil)](#7-instalar-pc2--terminal-a-táctil)
  - [8. Instalar PC3 — Terminal-B (táctil)](#8-instalar-pc3--terminal-b-táctil)
  - [9. Prueba de humo end-to-end](#9-prueba-de-humo-end-to-end)
  - [10. Configurar arranque automático (opcional pero recomendado)](#10-configurar-arranque-automático-opcional-pero-recomendado)
  - [11. Problemas comunes y soluciones rápidas](#11-problemas-comunes-y-soluciones-rápidas)
  - [12. Rollback: cómo desinstalar y volver al estado anterior](#12-rollback-cómo-desinstalar-y-volver-al-estado-anterior)

---

## 0. Antes de empezar — hoja de ruta y checklist rápido

**Tiempo total estimado**: 90–120 minutos para el piloto completo
(15 min grabar pendrives + 15 min por PC + 30 min de red y pruebas).

**Lo que vas a hacer, resumido:**

1. Grabar los 2 pendrives desde tu PC de desarrollo (con la v4.4 recién
   commiteada).
2. Conectar las 3 PCs a la misma red (switch/router) y asignar IPs fijas.
3. Instalar PC1 primero (servidor). Confirmar que PocketBase responde
   por LAN.
4. Ejecutar `Fix-ModoTactil.ps1` en PC2 y PC3.
5. Instalar PC2 y PC3.
6. Prueba end-to-end desde las Terminales.

**Materiales necesarios:**

- [ ] 2 pendrives de al menos **8 GB** cada uno (idealmente 16 GB).
- [ ] Las 3 PCs con Windows 10/11 y acceso de Administrador.
- [ ] Un switch o router para conectarlas por cable.
- [ ] 3 cables de red.
- [ ] Chrome instalado en las 3 PCs (el sistema abre Chrome, no otro
      navegador).

---

## 1. Reparto de PCs y roles

| PC     | Hardware                       | Rol asignado                  | IP LAN         | Hostname sugerido |
|--------|--------------------------------|-------------------------------|----------------|-------------------|
| **PC1** | Monitor común + teclado + mouse | **Monitor Vigilancia + Servidor PocketBase** | `192.168.1.10` | `FCEA-MONITOR`    |
| **PC2** | Monitor táctil 3nStar TCM008    | **Terminal-A**                | `192.168.1.11` | `FCEA-TERMINAL-A` |
| **PC3** | Monitor táctil 3nStar TCM008    | **Terminal-B**                | `192.168.1.12` | `FCEA-TERMINAL-B` |

> **Por qué el vigilante usa la PC común (y no una táctil):**
> el Monitor Vigilancia se opera 8 horas por día con filtros, búsquedas
> y edición constante. Con teclado y mouse eso es rapidísimo; con touch
> resistivo (que además NO soporta scroll por gesto ni teclado virtual
> automático) sería una tortura. Las 2 PCs táctiles quedan como
> Terminales de usuario, donde la UX es simple (identificarse → tocar
> llave → confirmar) y el touch se aprovecha al máximo.
>
> Bonus: la PC común aloja también PocketBase, así minimizamos reboots
> en la máquina crítica (si un usuario apaga sin querer una Terminal,
> no se cae el servidor).

**Antes de conectar las PCs al piloto, renombralas** (opcional pero
muy útil para debugging):

1. `Configuración → Sistema → Información → Cambiar el nombre de este equipo`.
2. Poner el hostname de la tabla y reiniciar.

> El instalador usa el hostname para **autodetectar el rol**. Aunque
> también sirve la IP fija, tener hostnames claros te ahorra dolores
> de cabeza.

---

## 2. Preparativos en la PC de desarrollo (la tuya)

Todo esto se hace **una sola vez**, en la PC donde tenés el código
(`C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea`).

1. **Verificar que estás en la última versión de `main`** con la v4.4:

   ```powershell
   cd C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea
   git status
   # Debe decir: "On branch main, nothing to commit, working tree clean"
   # (o al menos que tu commit v4.4 esté hecho: git log -1 --oneline)

   git log -1 --oneline
   # Debe empezar con "84d9e92 v4.4: UX tactil para monitores 3nStar TCM008 ..."
   ```

2. **Compilar la última versión del frontend:**

   ```powershell
   cd C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea
   npm run build
   ```

   Debe terminar con `built in XX s` sin errores. La carpeta `dist/`
   queda con el build listo para copiar a los pendrives.

3. **Cerrar todas las ventanas de PocketBase / Chrome / VSCode que
   estén tocando `pb_data`** para que el grabador pueda hacer el
   snapshot limpio.

---

## 3. Grabar los 2 pendrives

1. **Enchufar los 2 pendrives vacíos**. No importa qué letra les asigne
   Windows (D:, E:, F:...): el grabador los identifica por el
   *volume label*, no por la letra.

2. **Formatear cada pendrive y ponerle el label correcto:**

   - Pendrive 1 → label = `INSTALADOR_LLAVES_FCEA` (FAT32 o exFAT).
   - Pendrive 2 → label = `RECUPERACION_FCEA` (FAT32 o exFAT).

   > Se hace desde el Explorador: clic derecho en el pendrive →
   > `Formatear...` → en "Etiqueta del volumen" poné el nombre exacto,
   > sin tildes ni espacios. Aceptar.

3. **Ejecutar el grabador** con doble clic:

   ```
   C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\GRABAR_PENDRIVES.bat
   ```

   Windows va a pedir permisos de Administrador (UAC) → aceptar.

4. **Qué hace el grabador (automático, sin preguntar nada):**

   - [1/6] Detiene PocketBase local (10 s de downtime del sistema en tu PC).
   - [2/6] Copia `pb_data` productivo a una carpeta temporal.
   - [3/6] Reanuda PocketBase (tu sistema local ya vuelve a estar online).
   - [4/6] Copia al pendrive INSTALADOR:
     - código fuente (sin `node_modules`, sin `.git`)
     - `dist/` recién compilado (paso 2 de la sección anterior)
     - `pocketbase.exe` + `pb_migrations/` + snapshot de `pb_data`
     - `node-portable/` (para PCs sin Node.js instalado)
     - launchers: `INSTALAR SISTEMA.bat`, `DESINSTALAR SISTEMA.bat`,
       `RECUPERAR SISTEMA.bat`
     - `Documentacion/*.md`
     - `LEEME_PRIMERO.txt`
   - [5/6] Copia lo mismo al pendrive RECUPERACION (son clones).
   - [6/6] Borra la carpeta temporal.

5. **Cuando termine**, deberías ver `[OK] Grabación completada`.
   Tiempo estimado: 5–10 minutos por pendrive.

6. **Verificar que los pendrives quedaron bien**, en el Explorador:

   - Cada pendrive debe tener en la raíz: `INSTALAR SISTEMA.bat`,
     `DESINSTALAR SISTEMA.bat`, `RECUPERAR SISTEMA.bat`,
     `LEEME_PRIMERO.txt`, carpeta `sistema-llaves-fcea/`,
     carpeta `node-portable/`, carpeta `Documentacion/`.

7. **Expulsá los pendrives correctamente** (Safe Remove) antes de
   sacarlos, para evitar corrupción.

> **Podés usar cualquiera de los 2 pendrives para instalar** — son
> idénticos. La razón de tener 2 es que si uno se rompe físicamente,
> tenés el respaldo.

---

## 4. Configurar la red LAN del piloto

Las 3 PCs tienen que **verse entre sí por IP fija en la LAN**.
Recomendación: switch simple (o un router común con DHCP apagado) y
IPs fijas en el rango `192.168.1.0/24`.

En **cada** una de las 3 PCs:

1. `Panel de control → Red e Internet → Centro de redes → Cambiar
   configuración del adaptador`.
2. Clic derecho en la conexión Ethernet activa → `Propiedades`.
3. Doble clic en `Protocolo de Internet versión 4 (TCP/IPv4)`.
4. Marcar `Usar la siguiente dirección IP` y completar:

   | PC  | IP              | Máscara         | Puerta de enlace  |
   |-----|-----------------|-----------------|-------------------|
   | PC1 | `192.168.1.10`  | `255.255.255.0` | (dejar en blanco) |
   | PC2 | `192.168.1.11`  | `255.255.255.0` | (dejar en blanco) |
   | PC3 | `192.168.1.12`  | `255.255.255.0` | (dejar en blanco) |

5. Aceptar → Aceptar → Cerrar.

**Probar la conectividad**: desde PC2 abrir CMD y ejecutar:

```cmd
ping 192.168.1.10
ping 192.168.1.12
```

Ambos tienen que responder. Si no responden, revisar el firewall de
Windows (paso 5.6) y que estén en la misma "red de perfil" (Privada,
no Pública).

---

## 5. Instalar PC1 — Monitor Vigilancia + Servidor

**Importante: PC1 tiene que estar instalada y con PocketBase corriendo
ANTES de instalar las Terminales.**

1. Enchufar en PC1 el pendrive `INSTALADOR_LLAVES_FCEA`.

2. Doble clic en `INSTALAR SISTEMA.bat` (en la raíz del pendrive).
   Aceptar UAC.

3. En el menú aparecen 3 opciones. Elegir **`[2] PRODUCCION EN 3 PCs`**.

4. El instalador va a **autodetectar el rol** por hostname/IP.
   Como PC1 tiene el hostname `FCEA-MONITOR` (o IP `192.168.1.10`),
   debería detectar:

   ```
   Rol      : monitor
   Hardware : tradicional         ← porque no hay driver de touch instalado
   Servidor : 127.0.0.1
   Hostname : FCEA-MONITOR
   ```

   > ⚠️ **Si detecta `hardware: tactil` por error** (algún driver
   > residual): dejá que termine la instalación y después editá
   > `C:\sistema-llaves-fcea\public\config.json` cambiando
   > `"hardware": "tactil"` → `"hardware": "tradicional"`.

5. Confirmar con `S`. El instalador va a:

   - [1/5] Copiar el sistema a `C:\sistema-llaves-fcea\`.
   - [2/5] Copiar Node.js portable.
   - [3/5] Configurar PocketBase, firewall (abre puerto 8090), y tareas
     programadas (backup diario, watchdog).
   - [4/5] Restaurar los datos del pendrive (llaves, vigilantes,
     usuarios, historial).
   - [5/5] Abrir Chrome automáticamente en `http://127.0.0.1:4173`
     mostrando el Monitor Vigilancia con toda la agenda cargada.

6. **Verificar que PocketBase responde por LAN** (importante para las
   Terminales):

   En PC1 abrir CMD:

   ```cmd
   curl http://192.168.1.10:8090/api/health
   ```

   Debe responder `{"code":200,"message":"API is healthy.",...}`.

   Si NO responde, el firewall de Windows está bloqueando el puerto
   8090. Ejecutar como Admin:

   ```powershell
   New-NetFirewallRule -DisplayName "PocketBase FCEA" -Direction Inbound `
     -Protocol TCP -LocalPort 8090 -Action Allow
   ```

7. **Anotar la IP de PC1** — vas a necesitarla para configurar PC2 y
   PC3 (aunque el instalador debería detectarla sola).

8. Expulsar el pendrive.

---

## 6. Configurar hardware táctil en PC2 y PC3

**Este paso se hace SOLO en PC2 y PC3** (las que tienen el monitor
3nStar TCM008). **NO en PC1.**

1. Copiá desde el pendrive el script `scripts/Fix-ModoTactil.ps1` al
   Escritorio de PC2:

   ```
   Origen: <pendrive>\sistema-llaves-fcea\scripts\Fix-ModoTactil.ps1
   Destino: C:\Users\<usuario>\Desktop\Fix-ModoTactil.ps1
   ```

2. Clic derecho en el script → `Ejecutar con PowerShell` **como
   Administrador**.

   Si Windows bloquea la ejecución, abrir PowerShell como Admin y
   ejecutar:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass -Force
   & "$env:USERPROFILE\Desktop\Fix-ModoTactil.ps1"
   ```

3. El script hace lo siguiente **y genera un backup `.reg` en
   `C:\` antes de tocar nada**:

   1. Detiene el servicio `TabletInputService` (teclado virtual del
      sistema que interfiere con el custom de la app).
   2. Desactiva el "Modo Tablet" automático (Windows 10).
   3. Desactiva gestos Windows Ink (press-and-hold = clic derecho —
      que a veces se dispara sin querer con el dedo).
   4. Fuerza `monitor-timeout-ac = 0` y `monitor-timeout-dc = 0`
      (el monitor nunca se apaga por DPMS).
   5. Oculta el ícono del teclado táctil en la barra de tareas.
   6. Deja el `.reg` de backup en `C:\backup_modo_tactil_<fecha>.reg`.

4. **Reiniciar PC2** para que todos los cambios tomen efecto.

5. Repetir todo el punto 6 en **PC3**.

---

## 7. Instalar PC2 — Terminal-A (táctil)

1. Enchufar el pendrive `INSTALADOR_LLAVES_FCEA` en PC2.

2. Doble clic en `INSTALAR SISTEMA.bat`. Aceptar UAC.

3. Elegir **`[2] PRODUCCION EN 3 PCs`**.

4. Autodetección esperada:

   ```
   Rol      : terminal-a
   Hardware : tactil          ← detecta el driver del TCM008
   Servidor : 192.168.1.10    ← apunta a PC1
   Hostname : FCEA-TERMINAL-A
   ```

   > ⚠️ **Si detecta `hardware: tradicional`** (el driver del TCM008
   > se instala como HID genérico y a veces la autodetección falla):
   > dejá terminar y editá `C:\sistema-llaves-fcea\public\config.json`
   > cambiando `"hardware": "tradicional"` → `"hardware": "tactil"`.
   > Recargar Chrome con `Ctrl+F5` o cerrar y volver a abrir.

5. Confirmar con `S` y esperar que abra Chrome con la Terminal.

6. **Verificar visualmente** en la Terminal-A:

   - [ ] Título: "Terminal de Usuario" (no "Monitor Vigilancia").
   - [ ] Tras 1 minuto sin tocar, aparece el overlay:
         **"¡BIENVENIDO/A! TOQUE LA PANTALLA PARA SOLICITAR SU/S LLAVES"**.
   - [ ] Al tocar el overlay, desaparece.
   - [ ] Al tocar el campo "Buscar por celular/email", aparece el
         teclado virtual custom (no el de Windows).
   - [ ] Al scrollear la lista de llaves con el dedo NO funciona (es
         panel resistivo) pero los **botones ▲ / ▼** flotantes en la
         esquina inferior derecha SÍ funcionan.
   - [ ] Podés buscar un usuario existente que hayas cargado en tu PC
         de desarrollo → aparece en la lista.

7. Expulsar el pendrive.

---

## 8. Instalar PC3 — Terminal-B (táctil)

Idéntico al paso 7 pero en PC3. La autodetección debería devolver
`Rol: terminal-b` (por hostname `FCEA-TERMINAL-B` o IP `192.168.1.12`).

---

## 9. Prueba de humo end-to-end

Con las 3 PCs corriendo simultáneamente:

1. **Desde PC2 (Terminal-A):**
   - Registrar un usuario nuevo de prueba: nombre "Piloto Test",
     celular "099999999", email "piloto@test.com".
   - Solicitar una llave cualquiera (la que tengas cargada, ej.
     "Aula 101"). Confirmar.

2. **Desde PC1 (Monitor Vigilancia):**
   - En < 3 segundos (por el polling de `SolicitudesContext`) tiene
     que aparecer la solicitud pendiente de "Piloto Test → Aula 101".
   - Aprobar la solicitud desde PC1 con el mouse.

3. **Desde PC2 (Terminal-A):**
   - La UI tiene que actualizarse sola y mostrar "Llave entregada".

4. **Desde PC3 (Terminal-B):**
   - Buscar al usuario "Piloto Test" por celular → debe aparecer con
     la llave "Aula 101" en su poder.
   - Devolver la llave desde PC3.

5. **En PC1 (Monitor Vigilancia):**
   - Ver el historial. Debe listar: solicitud desde Terminal-A,
     aprobación desde Monitor, devolución desde Terminal-B.

Si todos esos pasos funcionaron, **el piloto está listo**. ✅

---

## 10. Configurar arranque automático (opcional pero recomendado)

Para que el sistema se levante solo al prender cada PC (útil para las
Terminales, que no tienen operador que las inicie):

En **cada una de las 3 PCs**, abrir PowerShell como Admin y ejecutar:

```powershell
powershell -ExecutionPolicy Bypass -File `
  "C:\sistema-llaves-fcea\scripts\install\CONFIGURAR_INICIO_AUTOMATICO.ps1"
```

Esto crea una tarea programada `FCEA-Sistema-Llaves-AutoStart` que:

- Arranca PocketBase (solo en PC1, en las Terminales lo omite).
- Arranca Chrome en modo kiosk apuntando a la URL correcta según el
  rol (`http://192.168.1.10:4173/monitor` en PC1,
  `.../terminal` en PC2 y PC3).

Para probarlo sin reiniciar: `Ctrl+Alt+Supr → Cerrar sesión → volver
a iniciar sesión`.

---

## 11. Problemas comunes y soluciones rápidas

| Síntoma                                                          | Causa probable                                       | Solución                                                                                                                                          |
|------------------------------------------------------------------|------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| PC2/PC3 dicen "No se pudo conectar al servidor"                  | PC1 no responde en 192.168.1.10:8090                 | En PC1 correr `curl http://127.0.0.1:8090/api/health`. Si funciona local pero no por LAN → abrir firewall (ver paso 5.6).                          |
| El teclado táctil de Windows aparece encima del custom            | `Fix-ModoTactil.ps1` no se ejecutó o falló           | Volver a ejecutar el script como Admin. Reiniciar. Verificar en `services.msc` que `TabletInputService` está detenido/manual.                     |
| Los botones ▲ / ▼ no aparecen en la lista de llaves               | `config.json` tiene `"hardware": "tradicional"`      | Editar `C:\sistema-llaves-fcea\public\config.json`, poner `"hardware": "tactil"` y `Ctrl+F5` en Chrome.                                            |
| El screensaver no aparece tras 1 minuto                          | `ui.screensaver_activo: false` o `hardware: tradicional` | Editar `config.json`: `"ui": { "screensaver_activo": true, "screensaver_delay_ms": 60000 }`. Recargar.                                             |
| El screensaver aparece en PC1 (vigilancia) y molesta al vigilante | Bandera activa en PC1 por error                     | Editar `C:\sistema-llaves-fcea\public\config.json` en PC1: `"ui": { "screensaver_activo": false }`. Recargar Chrome.                                |
| Chrome se abre pero muestra "This site can't be reached"          | PocketBase no arrancó o Node no está en PATH        | Correr manualmente: `C:\sistema-llaves-fcea\scripts\install\INICIAR.bat`. Ver mensajes.                                                            |
| El monitor se apaga solo tras 15 minutos                         | Windows aplicó su propio ahorro de energía          | `powercfg /change monitor-timeout-ac 0` como Admin. `Fix-ModoTactil.ps1` ya lo hace, pero puede haberse revertido con una GPO del dominio de FCEA. |
| Al escribir con el teclado virtual custom, aparecen letras dobles | Doble handler: se instaló el teclado del sistema Y el custom | Correr `Fix-ModoTactil.ps1` de nuevo. Reiniciar.                                                                                                   |

---

## 12. Rollback: cómo desinstalar y volver al estado anterior

**Si hay que revertir el piloto** (fin de la prueba, hardware devuelto,
o problemas graves):

1. **Desinstalar el sistema en cada PC**:

   ```
   Doble clic en <pendrive>\DESINSTALAR SISTEMA.bat
   ```

   Esto borra `C:\sistema-llaves-fcea\`, elimina las tareas programadas
   `FCEA-*`, y cierra los procesos. Deja un backup en `C:\backup_fcea_*`.

2. **Revertir los cambios de `Fix-ModoTactil.ps1` en PC2 y PC3**:

   Doble clic en el `.reg` de backup que dejó el script:

   ```
   C:\backup_modo_tactil_<fecha>.reg
   ```

   Aceptar la fusión con el registro. Reiniciar.

3. **Restaurar IPs por DHCP** en cada PC:

   Panel de control → Red → Propiedades TCP/IPv4 → `Obtener una
   dirección IP automáticamente`.

4. **Devolver los pendrives** — o formatearlos si es reutilización.

---

**Documento vivo**: si aparece algún caso raro en el piloto que no
esté acá, agregar al punto 11. La próxima persona que despliegue lo
va a agradecer.
