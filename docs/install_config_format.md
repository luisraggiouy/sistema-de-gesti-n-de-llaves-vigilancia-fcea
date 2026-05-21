# Formato de `install_config.json`

> Documento de diseño técnico. Define la "fuente de verdad" sobre cómo está
> configurada una PC concreta del sistema FCEA (modo, hardware, dispositivos).

---

## Ubicación

| Capa | Ruta | Quién la escribe | Quién la lee |
|---|---|---|---|
| Disco local (principal) | `C:\sistema-llaves-fcea\config\install_config.json` | Instalador, Recuperador v2 | Recuperador v2, Frontend |
| PocketBase (respaldo) | Colección `sistema_config` | Instalador, Recuperador v2 (sync) | Recuperador v2 si falta el local |
| Frontend (publicado) | `C:\sistema-llaves-fcea\frontend\dist\install_config.json` | Instalador / Recuperador v2 | App SPA (fetch) |

---

## Esquema

```json
{
  "modo": "produccion",                       // "produccion" | "desarrollo"
  "hardware": "tactil",                       // "tactil" | "tradicional" | "desarrollo"
  "version": "1.0.0",
  "fecha_instalacion": "2026-05-20T22:00:00Z",
  "pc_identifier": "FCEA-VIG-01 / vigilante",
  "monitores": [
    {
      "indice": 0,
      "ancho": 1920,
      "alto": 1080,
      "x": 0,
      "y": 0,
      "primary": true,
      "nombre": "\\\\.\\DISPLAY1"
    }
  ],
  "dispositivos": {
    "webcams":    [{ "nombre": "USB Camera", "id": "USB\\VID_..." }],
    "impresoras": [{ "nombre": "EPSON L3150", "driver": "...", "default": true, "offline": false }],
    "audio":      [{ "nombre": "Altavoces (Realtek)", "id": "..." }]
  },
  "notas": ""
}
```

### Valores de `hardware`

| Valor | Descripción | UI esperada |
|---|---|---|
| `tactil` | PC con pantalla táctil (kiosko principal o terminal de usuario) | Chrome en `--kiosk`, sin acceso a Dashboard directo |
| `tradicional` | PC de oficina del vigilante / administrador | Chrome normal, botón Dashboard visible |
| `desarrollo` | Notebook del desarrollador | Chrome normal, todas las herramientas visibles |

### Valores de `modo`

- `produccion` → Habilita watchdog, backups, tareas programadas.
- `desarrollo` → Skip de servicios pesados; útil para correr en la máquina del dev.

---

## Quién consume qué campo

### Instalador (`scripts/install/INSTALAR.ps1`)
1. Pregunta `modo` y `hardware` al usuario.
2. Llama a `Get-HardwareSnapshot` para llenar `monitores` y `dispositivos`.
3. Llama a `Write-InstallConfig` y `Sync-InstallConfigToPocketBase`.

### Recuperador v2 (`scripts/recovery/RECUPERAR_v2.ps1`)
1. Llama a `Read-InstallConfig`. Si no existe → `Restore-InstallConfigFromPocketBase`.
2. Si tampoco → pregunta al usuario y reconstruye.
3. Diagnóstico usa `hardware` para saber si la falta de touch es un problema o no.

### Frontend (SPA React)
- Hook `useInstallConfig()` hace `fetch('/install_config.json')` al arrancar.
- `MonitorVigilancia.tsx` usa `hardware` para mostrar/ocultar botón Dashboard:
  - `hardware === 'tactil'` → botón oculto (queda detrás del menú admin).
  - `hardware === 'tradicional' || modo === 'desarrollo'` → botón siempre visible.
- `useTouchDetection` queda como fallback si el JSON aún no se cargó.

---

## Sincronización PocketBase

- Colección: `sistema_config` (migración `1779000000_created_sistema_config.js`).
- Un solo registro vivo (el más reciente por `updated`).
- Campos JSON: `monitores_json`, `dispositivos_json` se guardan **serializados como string** para mantener compatibilidad con el tipo `json` de PB.
- Reglas: lectura/escritura abiertas (es config local, no PII).

---

## Migración desde sistemas viejos

Si un equipo viene del instalador v1 (sin `install_config.json`):

1. El Recuperador v2 detecta la ausencia.
2. Intenta restaurarlo desde PB; si no hay, pregunta al operador.
3. Lo escribe y lo sube a PB para futuros recovers.

No es necesario "migrar manualmente" nada: la primera ejecución del recuperador v2 deja todo en regla.

---

## Archivos relacionados

| Archivo | Rol |
|---|---|
| `scripts/lib/detectar_hardware.ps1` | `Get-HardwareSnapshot`, `Suggest-HardwareMode`, `Test-TouchAvailable` |
| `scripts/lib/install_config_io.ps1` | `Read-InstallConfig`, `Write-InstallConfig`, `Sync-InstallConfigToPocketBase`, `Restore-InstallConfigFromPocketBase`, `Publish-InstallConfigForFrontend` |
| `scripts/lib/abrir_chrome_kiosk.ps1` | `Open-AppBrowser` (decide kiosk vs normal según `hardware`) |
| `pocketbase/pb_migrations/1779000000_created_sistema_config.js` | Migración de la colección |
| `scripts/recovery/RECUPERAR_v2.ps1` + `.bat` | Recuperador inteligente |
| `scripts/pendrive/ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1` + `.bat` | Refresca pendrive de recuperación |
