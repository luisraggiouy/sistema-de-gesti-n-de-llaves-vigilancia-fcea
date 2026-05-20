# Operación diaria y mantenimiento – v2.0

Este documento describe el día a día del sistema una vez instalado: cómo
encender, apagar, qué pasa si algo falla y cómo recuperarse.

---

## 1. Encendido normal

1. Encender el **switch de red** primero.
2. Encender la PC de la **cabina** (servidor). Esperar 60s a que arranque
   Windows y la tarea `FCEA-Sistema-Llaves-AutoStart` levante PocketBase +
   frontend en modo kiosk.
3. Encender las 2 **terminales**. Hacen autostart y se conectan solas a la
   cabina vía `pocketbase_url`.

Si todo está bien, en menos de 90 segundos las 3 PCs muestran su pantalla
operativa.

---

## 2. Apagado normal

Sin necesidad de hacer logout:
- Cabina: `Alt+F4` para salir de kiosk → apagar Windows. (Esto detiene
  PocketBase y el watchdog automáticamente al cerrar sesión.)
- Terminales: idem.

> El backup diario corre solo a las **03:00 AM**, así que si se apaga la cabina
> de noche no se ejecutará. Si la facultad cierra en feriados largos, dejar
> la cabina encendida o regenerar el pendrive de recuperación antes del cierre.

---

## 3. Backups

| Cuándo                | Dónde                                                  |
|-----------------------|--------------------------------------------------------|
| Automático diario 03:00 | `backups\YYYY-MM-DD_HH-mm-ss.zip` en la cabina        |
| Manual antes de cambios | Ejecutar `scripts\maintenance\backup_automatico.ps1`  |
| Externo (pendrive)    | `scripts\pendrive\crear_pendrive.ps1 -Tipo recuperacion -PbDataPath ...` |

Retención por defecto: **14 días** (configurable con `-RetencionDias` al script).

---

## 4. Watchdog

Corre **solo en la cabina**. Cada 30 segundos hace un GET a
`http://127.0.0.1:8090/api/health`. Si falla:
1. Mata cualquier `pocketbase.exe` colgado.
2. Re-lanza `pocketbase\start-server.bat` minimizado.
3. Loguea en `pocketbase\maintenance\logs\watchdog.log`.

Para inspeccionar:
```powershell
Get-Content pocketbase\maintenance\logs\watchdog.log -Tail 50
```

Para detenerlo temporalmente (sin desinstalar la tarea):
```powershell
Stop-ScheduledTask -TaskName "FCEA-Watchdog"
```

---

## 5. Diagnóstico rápido

Cuando algo no anda, el orden recomendado es:

### a) ¿La cabina ve a las terminales?
Desde la cabina, en CMD:
```bat
ping 192.168.50.11   :: Terminal-A
ping 192.168.50.12   :: Terminal-B
```

### b) ¿Las terminales ven a la cabina?
Desde cualquier terminal:
```bat
ping 192.168.50.10
curl http://192.168.50.10:8090/api/health
```

### c) Si una terminal muestra "sin conexión":
- Verificar el cable Ethernet y el LED del switch.
- Verificar `public/config.json` en esa terminal — la `pocketbase_url` debe
  apuntar a la IP de la cabina.
- Reiniciar la terminal.

### d) Si la cabina no responde:
- Insertar el **pendrive de recuperación** en la cabina.
- Ejecutar `RECUPERAR.bat → [3] Reparar PocketBase`.
- Si persiste, `[2] Restaurar base de datos desde backup`.

---

## 6. Cambio de configuración runtime

Para cambiar el rol, IP del servidor o forzar teclado virtual sin reinstalar:

1. Editar `public/config.json` en la PC afectada.
2. Reiniciar el frontend (cerrar Chrome kiosk y volver a abrir, o reiniciar
   Windows).

Ejemplo: forzar teclado virtual aunque la PC no sea táctil (útil para mouse):
```json
{
  "ui": { "teclado_virtual_forzado": true }
}
```

---

## 7. Actualizar el sistema

1. Hacer commit en GitHub desde la PC de desarrollo.
2. Generar pendrive instalador nuevo:
   ```powershell
   .\scripts\pendrive\crear_pendrive.ps1 -Drive E: -Tipo instalador
   ```
3. En cada PC del aire, **antes** de instalar, generar pendrive de recuperación.
4. En cada PC: detener `INICIAR.bat`, hacer `git pull` (o reinstalar desde
   pendrive) y `npm install && npm run build`.
5. La base de datos no se toca (vive en `pb_data\`).

---

## 8. Solución a problemas comunes

| Síntoma                                       | Causa probable                      | Acción                                         |
|----------------------------------------------|-------------------------------------|------------------------------------------------|
| Chrome arranca pero la página queda en blanco| No hizo `npm run build`             | `RECUPERAR → [4] Reinstalar frontend`          |
| Terminal dice "no se puede conectar"         | PocketBase caído o IP mal           | `RECUPERAR → [3] Reparar PocketBase` + verificar IP |
| Watchdog no reinicia PocketBase              | Firewall bloquea el puerto 8090     | Re-correr `RECUPERAR → [3]` (regenera la regla)|
| Backup no se ejecuta                         | Tarea no creada o usuario cambió    | Re-correr `CONFIGURAR_MANTENIMIENTO.ps1`       |
| Teclado virtual no aparece en pantalla táctil| No se detectó touch                 | Forzar con `ui.teclado_virtual_forzado: true`  |
| Dos PCs muestran "Monitor" al mismo tiempo   | Rol mal asignado en `config.json`   | Editar `config.json` y reiniciar               |
