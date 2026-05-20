# Arquitectura del Sistema – v2.0

> **Cambio mayor respecto a v1.x:** el sistema deja de correr en una sola PC y
> pasa a una arquitectura distribuida de **3 mini-PCs** conectadas por un
> **switch de red local cerrada**. Esto elimina el problema de competencia por
> los dispositivos de entrada en Windows (mouse y teclado) y permite que las 3
> estaciones trabajen **simultáneamente y de forma autónoma**.

---

## 1. Topología física

```
┌───────────────────────────────┐
│  Cabina de Vigilancia         │
│  ┌─────────────────────────┐  │
│  │  Mini-PC SERVIDOR       │  │   <-- 16 GB RAM
│  │  rol: monitor + PB      │  │
│  │  (cabina, vigilante)    │  │
│  └────────────┬────────────┘  │
└───────────────┼───────────────┘
                │
                │ Ethernet
                ▼
       ┌────────────────┐
       │  Switch (5 p.) │
       └────┬──────┬────┘
            │      │
            ▼      ▼
┌──────────────┐  ┌──────────────┐
│ Mini-PC      │  │ Mini-PC      │
│ TERMINAL-A   │  │ TERMINAL-B   │
│ (puesto      │  │ (puesto      │
│  usuarios A) │  │  usuarios B) │
└──────────────┘  └──────────────┘
```

- **1 switch de 5 puertos** (los 2 puertos libres quedan disponibles para una
  PC de Dashboard opcional o un Access Point para administración).
- **Red privada cerrada** (sin acceso a Internet en producción). DHCP estático
  o IPs fijas para cada PC.

---

## 2. Roles y responsabilidades

| Rol          | PC      | Función                                                                 |
|--------------|---------|-------------------------------------------------------------------------|
| `monitor`    | Cabina  | **Servidor PocketBase** + Monitor de Vigilancia + Watchdog + Backup     |
| `terminal-a` | Puesto A| Solo cliente web → Terminal de Usuario A                                |
| `terminal-b` | Puesto B| Solo cliente web → Terminal de Usuario B                                |
| `dashboard`  | (opc.)  | Cliente web → Dashboard de reportes / administración (PC adicional)     |

> **La PC `monitor` es la única que ejecuta PocketBase.** Las terminales solo
> hablan HTTP con ella vía `pocketbase_url` configurada en `public/config.json`.

### Por qué la cabina es la más potente (16 GB RAM)
1. Es el **único servidor de datos** (PocketBase + sqlite).
2. Ejecuta el **watchdog** y los **backups automáticos**.
3. Mantiene un **WebSocket abierto por cada terminal** (subscripciones en tiempo
   real con la API de PocketBase).
4. Renderiza el **Monitor de Vigilancia**, que es la pantalla más cargada
   (solicitudes en vivo, KeyHistorySearch, SystemHealthAlerts, etc.).

---

## 3. Modos de configuración disponibles

El instalador (`scripts/install/INSTALAR.bat`) pregunta por uno de 4 modos:

### Modo 1 – DESARROLLO / DEMO
- **1 PC.** Frontend y PocketBase en la misma máquina.
- La UI muestra el botón "alternar Monitor / Terminal" (modo dev clásico).
- Útil para demos, capacitación y desarrollo.

### Modo 2 – PRODUCCIÓN ECONÓMICA (3 PCs)
- 3 mini-PCs, todas con teclado + mouse + monitor LCD.
- Sin pantalla táctil. Es la opción más barata para empezar.

### Modo 3 – PRODUCCIÓN MIXTA (3 PCs)
- Igual que el modo 2, pero la PC de la **cabina** tiene **monitor táctil**.
- Las 2 terminales siguen con teclado + mouse.
- Se activa `teclado_virtual_forzado: true` solo en la cabina.

### Modo 4 – PRODUCCIÓN IDEAL (3 PCs con monitor táctil)
- Las 3 PCs usan monitor táctil como **única interfaz**.
- Sin teclados ni mouse físicos. Todo por pantalla táctil + teclado virtual
  con predicción.

---

## 4. Configuración runtime (`public/config.json`)

Cada PC tiene **su propio** `public/config.json` que el frontend lee al arrancar.
Define rol, modo, URL del servidor PocketBase y opciones de UI. Ejemplo para la
cabina (rol = monitor) en modo 4:

```json
{
  "version": "2.0.0",
  "modo": "produccion",
  "rol": "monitor",
  "pocketbase_url": "http://127.0.0.1:8090",
  "red": {
    "ip_servidor": "192.168.50.10",
    "ip_terminal_a": "192.168.50.11",
    "ip_terminal_b": "192.168.50.12"
  },
  "ui": {
    "teclado_virtual_forzado": false,
    "tema": "claro"
  }
}
```

Y en una terminal (rol = terminal-a) apuntando a la cabina:

```json
{
  "version": "2.0.0",
  "modo": "produccion",
  "rol": "terminal-a",
  "pocketbase_url": "http://192.168.50.10:8090",
  "red": { "ip_servidor": "192.168.50.10", "ip_terminal_a": "192.168.50.11", "ip_terminal_b": "192.168.50.12" },
  "ui": { "teclado_virtual_forzado": false, "tema": "claro" }
}
```

El frontend lee este archivo en `src/lib/runtimeConfig.ts` y todos los hooks/
componentes consumen los valores derivados (`useDeviceConfig`,
`useTouchDetection`, etc.).

---

## 5. Resumen de beneficios

- **Sin contención de entrada**: cada PC tiene su propio Windows, mouse,
  teclado y/o pantalla táctil. Nada de "robarse el cursor".
- **Autonomía parcial**: si una terminal se cuelga, las otras siguen funcionando.
  Si la cabina cae, las terminales muestran un cartel "sin conexión"
  (re-conectan automáticamente cuando vuelve el servidor).
- **Backups consistentes**: el backup vive solo en el servidor; las terminales
  no necesitan respaldo (son stateless).
- **Watchdog único**: corre en la cabina y vigila únicamente a PocketBase.
- **Pendrive de recuperación universal**: sirve para reinstalar cualquiera de
  las 3 PCs según el rol que se elija al lanzar `INSTALAR.bat`.
