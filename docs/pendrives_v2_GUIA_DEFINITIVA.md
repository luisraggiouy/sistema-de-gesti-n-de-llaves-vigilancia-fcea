# Pendrives FCEA v2.0 — Guía Definitiva

> **Versión:** 2.0 (Mayo 2026)  
> **Aplica a:** Pendrive Instalador y Pendrive Recuperador.  
> Documento único y vigente para todo lo relativo a los pendrives.

---

## 1. Cambios respecto a v1 (qué se rompió y por qué)

| Síntoma v1                                                 | Causa                                                          | Solución v2 |
|------------------------------------------------------------|----------------------------------------------------------------|-------------|
| Pendrive **instalador** terminaba el .bat sin abrir Chrome y sin diálogos. | Las pantallas negras emergentes y la tarea de inicio se ejecutaban en otro contexto. | El pendrive **instalador** ahora delega en el mismo motor de instalación que el recuperador (ver §4). |
| Pendrive **recuperador** mostraba muchos `[--] No encontrado` al desinstalar. | El desinstalador buscaba en `C:\sistema-llaves-fcea` y la ruta real es `C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea`. | Desinstalador v2 busca **ambas rutas** y limpia perfiles Chrome del kiosk, accesos directos, registro y backups. |
| Líneas rojas (`npm warn deprecated …`) en pantalla durante la instalación. | `npm install` escribe warnings a `stderr`. PowerShell mostraba todo `stderr` en rojo. | El instalador captura `stderr` aparte y solo lo escribe al log. En pantalla no se ven las warnings (no son errores). |
| No aparecían los diálogos de Modo (desarrollo / producción) ni de Hardware (1 PC + táctil / 1 PC + 3 monitores). | El instalador antiguo no los preguntaba. | v2 los pregunta **siempre que no haya configuración previa** (ver §3). |

---

## 2. Estructura de los pendrives

### Pendrive Recuperador (`D:\RECUPERACION_SISTEMA_LLAVES_FCEA\`)

```
D:\RECUPERACION_SISTEMA_LLAVES_FCEA\
├── REINSTALAR-COMPLETO.bat            ← Reinstala/repara todo (detecta config previa y la reusa)
├── DESINSTALAR-SISTEMA.bat            ← Borra el sistema (NUEVO en v2)
├── LEEME-PRIMERO.txt
├── lib\                                ← Motores y librerías PowerShell
│   ├── REINSTALAR-COMPLETO.ps1         ← Motor real del reinstalador
│   ├── DESINSTALAR-SISTEMA.ps1         ← Wrapper PS del desinstalador
│   ├── DESINSTALAR_SISTEMA_LIMPIO.ps1  ← Motor real del desinstalador
│   ├── detectar_hardware.ps1
│   ├── install_config_io.ps1
│   └── abrir_chrome_kiosk.ps1
├── sistema\                            ← Copia del repo (no tocar a mano)
├── instaladores\                       ← Node.js, Chrome offline
└── respaldos_db\                       ← Respaldos automáticos de PocketBase
```

> En la raíz **solo** hay archivos `.bat` (lo que el operador toca) y `LEEME-PRIMERO.txt`. Toda la lógica PowerShell vive en `lib\`.
> No existe un `REPARAR-Y-INICIAR-SISTEMA` separado: `REINSTALAR-COMPLETO.bat` detecta si ya hay `install_config.json` y, si lo encuentra, **reutiliza la configuración** sin volver a preguntar al operador. Es decir, "reparar" = "reinstalar conservando configuración".

### Pendrive Instalador

Mismos archivos que el recuperador en la raíz.  
**Lo que cambia:** el instalador no trae `respaldos_db\` (instalación nueva). Para "clonarlo" basta con copiar a la raíz lo mismo que está en el recuperador (excepto esa carpeta).

---

## 3. Configuración de instalación (`install_config.json`)

Cuando el sistema se instala por primera vez, los scripts preguntan dos cosas:

### 3.1 Modo de operación

| Opción | Significado |
|--------|-------------|
| **1. Desarrollo** | Aparecen botones para alternar manualmente entre Monitor de Vigilancia y Terminal de Usuario. Útil para probar. |
| **2. Producción** | Cada monitor abre una URL fija. Sin botones de cambio. (Recomendado en sala de vigilancia.) |

### 3.2 Configuración de hardware

| Código | Hardware | Asignación |
|--------|----------|------------|
| **A** | 1 mini-PC + 3 monitores **táctiles** + 1 webcam (en monitor de vigilancia) | Monitor primario → Vigilancia (con webcam). Otros 2 → Terminal Usuario (cada uno con su sesión Chrome aislada). |
| **B** | 1 mini-PC + 3 monitores no táctiles + 3 teclados + 3 mouses + 1 webcam (en vigilancia) | Igual que A, pero los terminales pueden recibir teclado/mouse físicos. |
| **C** | Otro / personalizado | El operador asigna manualmente qué monitor es vigilancia y cuál(es) terminal. |

El resultado se guarda en **dos lugares** (redundante a propósito):

- **Archivo JSON:** `C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\config\install_config.json`
- **PocketBase:** colección `sistema_config`, registro id `installconfig0001`.

> Esquema completo y API PowerShell: ver [`install_config_schema.md`](install_config_schema.md).

### 3.3 Reinstalar reutilizando la configuración previa

Si en la PC ya hay un `install_config.json` válido (o si en el pendrive recuperador hay un respaldo de la BD que lo contenga), el script ofrece:

```
Encontre configuracion previa: Modo=produccion, Hardware=B
[1] Reinstalar igual (recomendado)
[2] Cambiar configuracion
```

Eligiendo `1` no se pregunta nada y la reinstalación es no-interactiva.

---

## 4. Flujo de uso recomendado

### Caso A — PC totalmente nueva o limpia

1. Conectar **pendrive recuperador** (o instalador, son equivalentes en v2).
2. Doble clic en `REINSTALAR-COMPLETO.bat` → "Sí" al UAC.
3. Responder los 2 diálogos (Modo + Hardware) la primera vez. ~10 min.
4. Al finalizar se abren las ventanas de Chrome kiosk según la configuración elegida.
5. El sistema queda configurado para arrancar solo al prender la PC.

### Caso B — PC con instalación rota

1. Conectar pendrive.
2. Ejecutar `REINSTALAR-COMPLETO.bat`. Si detecta `install_config.json` previo, reusa la configuración y **no borra datos del operador** salvo que se elija "instalación limpia".
3. Si el problema persiste y querés un wipe total: `DESINSTALAR-SISTEMA.bat` → CONFIRMAR, y luego `REINSTALAR-COMPLETO.bat`.

### Caso C — Cambiar hardware (p. ej. agregar tercer monitor)

1. `DESINSTALAR-SISTEMA.bat` (los respaldos en escritorio se conservan si así se elige).
2. `REINSTALAR-COMPLETO.bat` → elegir **`2 - Cambiar configuracion`** → contestar nuevos diálogos.

---

## 5. Actualizar los pendrives desde el repo (técnico)

Desde el repo del sistema, en una PC con el pendrive conectado:

```powershell
# Recuperador (autodetecta letra)
.\ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1

# Recuperador en letra específica
.\ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1 -Letra D
```

El script:
- Limpia residuos del layout v1 (`.ps1` sueltos en la raíz) y carpetas `_backup_v1_*`.
- Limpia atributos `S/R/H` si los archivos previos los tenían.
- Copia los 2 wrappers `.bat` + `LEEME-PRIMERO.txt` a la raíz y reconstruye `lib\` (6 archivos `.ps1`).
- **No toca** `respaldos_db\`, `sistema\`, ni `instaladores\`.

> Lo más cómodo en la práctica es ejecutar `SINCRONIZAR_PENDRIVE_COMPLETO.ps1 -Letra D` que hace en un solo paso: robocopy del repo a `sistema\` + actualización del recuperador en raíz + `lib\`.

> Para preparar un pendrive desde cero la primera vez se sigue usando `scripts\preparar_pendrive_recuperacion.bat` (compatible con v1 y v2).

---

## 6. Verificación post-instalación

| Qué chequear | Cómo |
|--------------|------|
| `install_config.json` existe | `dir C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\config\install_config.json` |
| Registro en PocketBase | `http://localhost:8090/_/` → colección `sistema_config` debe tener 1 registro. |
| Tarea programada de inicio | `Get-ScheduledTask \| Where-Object Name -match FCEA` |
| Watchdog activo | `Get-Process \| Where-Object {$_.MainWindowTitle -match 'watchdog'}` |
| Frontend OK | Navegar a `http://localhost:8080/monitor` |

---

## 7. Líneas rojas del log de `npm install` (FAQ)

Si ve, durante una instalación con conexión a internet, algo como:

```
npm warn deprecated whatwg-encoding@2.0.0: Use @exodus/bytes instead ...
npm warn deprecated abab@2.0.6: Use your platform's native atob() ...
```

**Eso NO es un error**. Son advertencias de paquetes obsoletos. La instalación termina correctamente con:

```
added 499 packages in 33s
[OK] Dependencias instaladas
```

En **v2** estas líneas ya no se muestran en pantalla, pero quedan registradas en `%TEMP%\reinstalacion_fcea_<timestamp>.log` por si se necesita auditar.

---

## 8. Soporte

- Logs de instalación: `%TEMP%\reinstalacion_fcea_*.log`
- Log corto en el pendrive: `D:\RECUPERACION_SISTEMA_LLAVES_FCEA\ultimo_log_reinstalacion.txt`
- Repositorio: <https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea>
- Contacto: Luis Raggio — luisraggiouy@gmail.com
