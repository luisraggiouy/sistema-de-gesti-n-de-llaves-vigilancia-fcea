# Escenario de despliegue: 3 PCs mixtas (piloto FCEA v4.4)

Este documento describe cómo el sistema **queda preparado para el piloto
en producción con las 3 PCs prestadas por la Facultad**, donde una de
las tres tiene monitor común (mouse + teclado) y las otras dos tienen
un **monitor táctil resistivo 3nStar TCM008**.

## 1. Hardware disponible

| PC  | RAM   | Monitor                    | Uso previsto                       |
|-----|-------|----------------------------|------------------------------------|
| PC1 | 8 GB  | Monitor común + M/T        | **Monitor Vigilancia + Servidor**  |
| PC2 | 8 GB  | 3nStar TCM008 (touch)      | **Terminal-A** (usuarios)          |
| PC3 | 8 GB  | 3nStar TCM008 (touch)      | **Terminal-B** (usuarios)          |

> **Justificación del reparto**: el Monitor Vigilancia se usa 8 h por
> día con filtros, búsquedas y edición de registros — es MUCHO más
> productivo con teclado físico y mouse que con touch resistivo. Las
> dos Terminales de usuario, en cambio, tienen UX simplísima
> (identificarse → tocar llave → confirmar) y aprovechan perfectamente
> el panel táctil. Además, PC1 (común) hostea también el servidor
> PocketBase, minimizando reboots en la máquina crítica.


> El TCM008 es un panel **resistivo**: NO soporta scroll por gesto y
> NO despliega el teclado virtual del sistema automáticamente cuando
> se toca un `<input>`. Esas dos limitaciones motivan todos los ajustes
> descritos abajo.

## 2. Problemas concretos del TCM008 y cómo el sistema los resuelve

### 2.1 No hace scroll por gesto — solo scrolleando la barra lateral

**Solución multi-capa** implementada en v4.4:

- **`ScrollArea` y `ScrollableList` táctil-friendly** (`src/components/ui/`):
  cuando `hardware === "tactil"` (o `ui.scrollbar_ancha: true` en
  `config.json`), la barra de scroll pasa de **10 px → 25 px** con
  contraste alto, para que sea utilizable con el dedo.
- **Botones flotantes ▲ / ▼** en la lista de llaves (`KeySearch`):
  visibles solo en modo táctil, ubicados en la esquina inferior
  derecha, scrollean el 80 % del alto visible por toque.
- **CSS global** (`src/index.css` → `.scrollbar-touch`): estilos
  WebKit-scrollbar de 25 px, alto contraste, aplicados a cualquier
  contenedor con `overflow-y-auto` que use la clase (activada por
  `ScrollableList`).

### 2.2 No despliega el teclado virtual del sistema al tocar un `<input>`

El sistema **NUNCA depende** del teclado virtual de Windows. Usa un
**teclado virtual custom en React** (`src/components/ui/virtual-keyboard.tsx`)
que se monta encima del input cuando:

- `hardware === "tactil"` en `config.json`, **o**
- `useTouchDetection()` devuelve `true` (fallback automático).

En v4.4 los **5 flujos críticos del primer uso** ya usan `<TouchInput>`:

| Flujo                                        | Componente                | Estado v4.4 |
|----------------------------------------------|---------------------------|-------------|
| Buscar usuario por celular / email           | `UserSearchInput`         | ✅ TouchInput |
| Registro de nuevo usuario (nombre)           | `RegistrationModal`       | ✅ TouchInput |
| Registro de nuevo usuario (celular)          | `RegistrationModal`       | ✅ TouchInput (`inputMode="tel"`) |
| Registro de nuevo usuario (email)            | `RegistrationModal`       | ✅ TouchInput (`inputMode="email"`) |
| Registro: departamento "Otro" / empresa      | `RegistrationModal`       | ✅ TouchInput |
| Buscar llave por nombre                      | `KeySearch`               | ✅ TouchInput |

En `hardware === "tradicional"` o `"desarrollo"`, `TouchInput` se
comporta como un `Input` normal (no monta teclado). Cero regresión
para PC2 (Terminal-A con teclado físico).

### 2.3 Screensaver / "el monitor está apagado y no sé cómo prenderlo"

Componente **`TerminalScreensaver`** (`src/components/terminal/`):

- Se monta solo en la página `TerminalUsuario`.
- Solo se activa cuando `hardware === "tactil"` (default), o cuando
  `ui.screensaver_activo: true` en `config.json`.
- Tras `ui.screensaver_delay_ms` (default 60 000 ms = 1 min) sin
  interacción, muestra un overlay a pantalla completa con:
  - Icono grande de mano animado (`lucide-react` `Hand`).
  - Texto configurable: **"¡BIENVENIDO/A! TOQUE LA PANTALLA PARA SOLICITAR SU/S LLAVES"** (`ui.screensaver_texto`).
  - Gradiente azul institucional FCEA.
- Al tocar cualquier lado, el overlay desaparece y la Terminal queda operativa.
- Como pinta pixels animados, previene el DPMS-off del monitor.

## 3. `public/config.json` por PC

**Monitor Vigilancia + Servidor (PC1, común con teclado + mouse):**
```json
{
  "modo": "produccion",
  "rol": "monitor",
  "hardware": "tradicional",
  "pocketbase_url": "http://127.0.0.1:8090",
  "red": { "ip_servidor": "127.0.0.1", "ip_terminal_a": "192.168.1.11", "ip_terminal_b": "192.168.1.12" },
  "ui": { "teclado_virtual_forzado": false, "tema": "claro" }
}
```

**Terminal-A (PC2, touch TCM008):**
```json
{
  "modo": "produccion",
  "rol": "terminal-a",
  "hardware": "tactil",
  "pocketbase_url": "http://192.168.1.10:8090",
  "red": { "ip_servidor": "192.168.1.10", "ip_terminal_a": "192.168.1.11", "ip_terminal_b": "192.168.1.12" },
  "ui": {
    "teclado_virtual_forzado": true,
    "tema": "claro",
    "scrollbar_ancha": true,
    "screensaver_activo": true,
    "screensaver_delay_ms": 60000,
    "screensaver_texto": "¡BIENVENIDO/A! TOQUE LA PANTALLA PARA SOLICITAR SU/S LLAVES"
  }
}
```

**Terminal-B (PC3, touch TCM008):** idéntico a Terminal-A pero cambiando `"rol": "terminal-b"`.

> El vigilante (PC1) usa teclado físico y mouse: NO se le monta teclado
> virtual, NI scrollbar ancha, NI screensaver. Es Windows normal con
> el Monitor Vigilancia a pantalla completa.


## 4. Configuración de Windows en las 2 PCs táctiles

Ver `scripts/Fix-ModoTactil.ps1`. Ejecutar UNA vez como Administrador
en las PCs con TCM008 (**PC2 y PC3**). **No ejecutar en PC1** (Vigilancia)
— PC1 se usa con teclado físico y no requiere estos ajustes. Corrige:


1. Desactiva el teclado virtual táctil del sistema (para que no se
   solape con el custom de la app).
2. Desactiva el "Modo Tablet" automático de Windows 10.
3. Desactiva gestos Windows Ink (press-and-hold = click derecho).
4. Fuerza `monitor-timeout-ac = 0` (nunca apagar monitor).
5. Oculta el botón de teclado táctil de la barra de tareas.

Genera un backup `.reg` en la misma carpeta por si hay que revertir.

## 5. Cómo validar en el sitio (checklist rápido)

- [ ] Las 3 PCs cargan `TerminalUsuario` / `MonitorVigilancia` sin errores.
- [ ] En PC2 y PC3 (táctiles), al tocar la lista de llaves aparecen los botones ▲ / ▼.
- [ ] En PC2 y PC3, al tocar un campo de texto se muestra SOLO el teclado
      virtual custom (no el de Windows).
- [ ] Después de 1 min sin uso, PC2 y PC3 muestran el overlay de bienvenida.
- [ ] En PC1 (Vigilancia con teclado físico), NO aparecen botones ▲ / ▼
      ni teclado virtual y NO aparece screensaver — se comporta como una
      PC normal con la web del Monitor a pantalla completa.
- [ ] Las 3 PCs comparten la misma agenda de usuarios y llaves
      (el polling de 3 s en `SolicitudesContext` funciona sobre la LAN).


## 6. Rollback rápido

Si algo falla en producción:

1. Editar `public/config.json` de la PC afectada → cambiar `hardware`
   a `"tradicional"`. Recargar el navegador. Los nuevos features táctiles
   quedan apagados sin recompilar.
2. Si el problema es el screensaver, poner `ui.screensaver_activo: false`.
3. Si el problema es la scrollbar ancha, poner `ui.scrollbar_ancha: false`.

Los tres flags son independientes.
