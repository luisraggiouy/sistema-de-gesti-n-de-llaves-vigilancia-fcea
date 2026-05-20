# Esquema de `install_config.json` y colección `sistema_config`

> **Versión 1.0 — Mayo 2026**
> Documento técnico que describe el contrato de configuración persistente del sistema.

---

## 1. Propósito

Cuando el sistema se instala por primera vez (pendrive instalador), el usuario elige:

1. **Modo de operación** → `produccion` o `desarrollo`.
2. **Tipo de hardware** → `tactil`, `tradicional` o `desarrollo`.

Cada elección dispara una serie de configuraciones reales (apertura de Chrome en kiosk en cada monitor, asignación de roles a cada pantalla, activación de webcam solo en el monitor de vigilancia, etc.). Para que el **pendrive recuperador** pueda restablecer el sistema **idéntico a como estaba funcionando**, esa configuración se persiste en dos lugares (estrategia DOBLE):

- **Local:** archivo `C:\sistema-llaves-fcea\config\install_config.json`.
- **PocketBase:** colección `sistema_config`, registro único con id `installcfg00001` (15 caracteres, requisito de PocketBase v0.22).

El recuperador lee primero el JSON local; si no existe, intenta leerlo de PocketBase (porque el respaldo de la base de datos viaja en el pendrive). Si tampoco está, se comporta como instalación nueva y muestra los diálogos.

---

## 2. Estructura del JSON

```json
{
  "version": "1.0",
  "modo": "produccion",
  "hardware": "tradicional",
  "fecha_instalacion": "2026-05-13T11:30:00.000-03:00",
  "pc_identifier": "PC-VIGILANCIA|Dell Inc.|ABC123",
  "monitores": {
    "cantidad": 3,
    "asignacion": [
      {
        "indice": 1,
        "rol": "vigilancia",
        "url": "/monitor",
        "kiosk": true,
        "webcam": true,
        "x": 0,    "y": 0,
        "ancho": 1920, "alto": 1080
      },
      {
        "indice": 2,
        "rol": "terminal_a",
        "url": "/terminal",
        "kiosk": true,
        "webcam": false,
        "x": 1920, "y": 0,
        "ancho": 1920, "alto": 1080
      },
      {
        "indice": 3,
        "rol": "terminal_b",
        "url": "/terminal",
        "kiosk": true,
        "webcam": false,
        "x": 3840, "y": 0,
        "ancho": 1920, "alto": 1080
      }
    ]
  },
  "dispositivos": {
    "webcams": [
      { "nombre": "Logitech C270", "clase": "Camera", "instance": "USB\\VID_046D..." }
    ],
    "cantidad_webcams": 1,
    "teclados_fisicos": 3,
    "mouses_fisicos": 3,
    "soporta_tactil": false
  },
  "notas": ""
}
```

### 2.1 Campos de primer nivel

| Campo | Tipo | Valores | Descripción |
|---|---|---|---|
| `version` | string | `"1.0"` | Versión del esquema; permite migraciones futuras. |
| `modo` | string | `produccion` \| `desarrollo` | Determina si abrir kiosk o ventana normal con botones de alternancia. |
| `hardware` | string | `tactil` \| `tradicional` \| `desarrollo` | Orienta la UI (botones grandes vs. inputs estándar). |
| `fecha_instalacion` | ISO-8601 | — | Para diagnóstico. |
| `pc_identifier` | string | — | Cadena única `nombre|fabricante|serial` (BIOS) para detectar si el config es de otra PC. |
| `monitores` | objeto | — | Ver §2.2 |
| `dispositivos` | objeto | — | Ver §2.3 |
| `notas` | string | libre | Avisos opcionales (ej. "menos de 3 monitores detectados"). |

### 2.2 `monitores`

| Campo | Descripción |
|---|---|
| `cantidad` | Total detectado por Windows. |
| `asignacion[]` | Cada elemento es un par "monitor físico ↔ rol del sistema". |

#### Cada elemento de `asignacion`

| Campo | Descripción |
|---|---|
| `indice` | 1, 2, 3… orden lógico (siempre de izquierda a derecha por `Bounds.X`). |
| `rol` | `vigilancia` \| `terminal_a` \| `terminal_b` \| `desarrollo`. |
| `url` | Ruta dentro del frontend (`/monitor`, `/terminal`, `/`). |
| `kiosk` | `true` → Chrome con `--kiosk`. `false` → ventana normal. |
| `webcam` | `true` solo para el monitor de vigilancia (es el único que activa la cámara). |
| `x`, `y` | Posición en el escritorio virtual de Windows (para `--window-position`). |
| `ancho`, `alto` | Resolución del monitor (para `--window-size`). |

### 2.3 `dispositivos`

| Campo | Descripción |
|---|---|
| `webcams[]` | Array de webcams con nombre y clase PnP. |
| `cantidad_webcams` | Conteo. |
| `teclados_fisicos` | Cantidad de teclados USB/PS2/HID. |
| `mouses_fisicos` | Cantidad de mouses USB/PS2/HID. |
| `soporta_tactil` | Indicio de pantalla táctil presente. |

---

## 3. Reglas de asignación de roles a monitores

Implementadas en `scripts\lib\install_config_io.ps1` → `New-InstallConfig`:

### 3.1 Modo producción (3 monitores)

1. **Monitor #1** (más a la izquierda) → `vigilancia` con webcam, kiosk, abre `/monitor`.
2. **Monitor #2** → `terminal_a`, kiosk, abre `/terminal`.
3. **Monitor #3** → `terminal_b`, kiosk, abre `/terminal`.

> Si el orden físico real no coincide con lo deseado, el usuario lo arregla desde **Configuración de pantalla de Windows** (reordenando) y reinicia. El sistema vuelve a leer la posición y se reasigna correctamente.

### 3.2 Modo producción con menos de 3 monitores

Se asignan roles solo hasta donde alcanzan los monitores; el campo `notas` documenta la situación. El sistema funciona pero no abre las ventanas faltantes.

### 3.3 Modo desarrollo

Una única ventana en monitor primario, no-kiosk, apuntando a `/` (página raíz que muestra los botones de alternancia entre Monitor / Terminal / Dashboard).

---

## 4. Colección PocketBase `sistema_config`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | text | Siempre `"installcfg00001"` (15 caracteres). |
| `modo` | select | `produccion` \| `desarrollo` |
| `hardware` | select | `tactil` \| `tradicional` \| `desarrollo` |
| `monitores_json` | json | Equivale a `monitores` del JSON local. |
| `dispositivos_json` | json | Equivale a `dispositivos` del JSON local. |
| `version` | text | `"1.0"` |
| `fecha_instalacion` | date | ISO-8601 |
| `pc_identifier` | text | igual que JSON |
| `notas` | text | libre |

**Reglas de acceso:** lectura pública (`listRule = ""` y `viewRule = ""`); escritura abierta (no requiere admin) para que el instalador pueda escribir desde PowerShell sin autenticarse — ya que solo corre durante la instalación local. Esta decisión asume entorno de red privada/intranet de la facultad.

---

## 5. API PowerShell

Importar siempre con dot-sourcing:

```powershell
. "$PSScriptRoot\lib\detectar_hardware.ps1"
. "$PSScriptRoot\lib\install_config_io.ps1"
. "$PSScriptRoot\lib\abrir_chrome_kiosk.ps1"

# Detectar
$det = Get-DeteccionHardwareCompleta
Show-DeteccionResumen -Deteccion $det

# Construir y persistir
$cfg = New-InstallConfig -Modo 'produccion' -Hardware 'tradicional' -Deteccion $det
Save-InstallConfigLocal      -Config $cfg
Save-InstallConfigPocketBase -Config $cfg

# Abrir el sistema en cada monitor
Open-SistemaEnMonitores -Config $cfg -BaseUrl 'http://localhost:8080'
```

### En el recuperador

```powershell
$res = Get-InstallConfigSmart
if ($res) {
    Write-Host "Configuracion previa detectada (origen: $($res.origen))"
    Show-InstallConfigResumen -Config $res.config
    # preguntar al usuario si reinstala igual o cambia
} else {
    # No hay config -> tratar como instalacion nueva (mostrar dialogos)
}
```

---

## 6. Versionado

Cuando cambie el esquema en el futuro:

1. Incrementar `version` (ej. `"1.1"`).
2. Mantener compatibilidad hacia atrás en `Read-InstallConfigLocal` o agregar migraciones automáticas.
3. Agregar una entrada en este documento.

| Versión | Fecha | Cambios |
|---|---|---|
| 1.0 | 2026-05-13 | Esquema inicial (modo, hardware, monitores, dispositivos). |
