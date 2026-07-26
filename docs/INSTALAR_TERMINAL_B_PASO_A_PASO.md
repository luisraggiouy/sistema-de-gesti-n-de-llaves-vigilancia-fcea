# 🔵 Instalar Terminal-B con el pendrive — Paso a paso

Guía humana, sin adivinar nada. **Solo hay que enchufar el pendrive y darle
doble clic al INSTALADOR**. La detección de rol y hardware es automática.

---

## 0) Antes de empezar

Comprobá que:

- [ ] El **Monitor** (192.168.100.10) está prendido y funcionando.
      Podés ver el sistema en su pantalla.
- [ ] La **PC que va a ser Terminal-B** está conectada al mismo switch/router
      que el Monitor (cable Ethernet).
- [ ] La PC tiene una IP en la red `192.168.100.x` (chequear con `ipconfig`).
      Si no la tiene, primero configurarla estáticamente en `192.168.100.12`.
- [ ] Podés hacer `ping 192.168.100.10` desde la Terminal-B y responde.
- [ ] Tenés el **pendrive KINGSTON** enchufado (que ya trae toda la data del sistema).

Si algo de arriba falla, resolver eso **antes** de correr el instalador.

---

## 1) Enchufar el pendrive en Terminal-B

Metelo en un puerto USB. Esperá 5 segundos a que Windows lo reconozca.

Abrí el explorador de archivos y andá a la letra del pendrive (normalmente `D:` o `E:`).
Vas a ver algo así:

```
📁 sistema-llaves-fcea/     ← código + datos + binarios
📁 node-portable/            ← Node.js portable (por si la PC no lo tiene)
📁 HERRAMIENTAS_RED/         ← rescate de emergencia (no tocar en instalación normal)
📄 INSTALAR SISTEMA.bat      ← ESTE es el que corremos
📄 RECUPERAR SISTEMA.bat     ← solo para emergencias
📄 DESINSTALAR SISTEMA.bat   ← solo si hay que empezar de cero
📄 ARRANCAR SISTEMA.bat      ← solo si el sistema ya estaba instalado
```

---

## 2) Doble clic en `INSTALAR SISTEMA.bat`

- Windows te va a pedir permiso de administrador (UAC) → **Sí**.
- Se abre una ventana negra con el título "Sistema FCEA - Instalador".

---

## 3) Elegir la opción correcta del menú

Vas a ver:

```
[1] DESARROLLO EN 1 SOLA PC
[2] PRODUCCION EN 3 PCs (autodeteccion de rol y hardware)
[3] SALIR
```

Escribí **`2`** y ENTER.

**IMPORTANTE**: Nunca elijas `[1]` en una Terminal real. Esa opción es solo
para la PC de desarrollo del programador.

---

## 4) Confirmar la autodetección

El script detecta automáticamente:

- **Rol**: `terminal-b` (por el hostname o la IP `192.168.100.12`).
- **Hardware**: `tactil` o `tradicional` (según drivers).
- **IP servidor**: `192.168.100.10` (dirección del Monitor).

Ejemplo de lo que verás:

```
Resultado de la autodeteccion:
  Rol      : terminal-b
  Hardware : tactil
  Servidor : 192.168.100.10
  Hostname : TERMINAL-B

Continuar? [S/N]:
```

**Verificá que diga `Rol : terminal-b`**. Si dice otra cosa (ej: `monitor` o
`terminal-a`), NO CONTINUES: cancelá con `N`, avisale al soporte técnico.

Si todo está bien, escribí **`S`** y ENTER.

---

## 5) Esperar la instalación (5 a 15 minutos)

El instalador hace 5 pasos, con barra de progreso:

```
[1/5] Copiando sistema desde pendrive        ← ~2 min
[2/5] Copiando Node.js portable              ← ~1 min
[3/5] Configurando PocketBase y firewall     ← ~30 seg
[4/5] Restaurando TODOS los datos            ← ~1 min
[5/5] Abriendo Chrome con la Terminal        ← inmediato
```

Al final:
- Se abre Chrome automáticamente con la Terminal.
- Se configura el arranque automático (para que la Terminal arranque sola cada
  vez que se prenda la PC).
- Aparece el mensaje: `[OK] INSTALACION COMPLETADA Y SISTEMA CORRIENDO`.

**Apretá una tecla** para cerrar el instalador. **NO cierres las otras
ventanitas negras que quedan abiertas** — son PocketBase y el servidor
frontend, tienen que quedar corriendo.

---

## 6) Test funcional (2 minutos)

En la pantalla de Terminal-B (Chrome ya abierto):

1. Ingresá cualquier usuario de prueba (ej: Juan Doe).
2. Pedí cualquier llave (ej: "Sala comisiones").
3. Confirmá el pedido.

En el Monitor, deberías ver en **menos de 3 segundos**:
- La solicitud nueva en el bloque "Solicitudes pendientes".
- Sonido de alerta (si tenés el sonido activado).

Si aparece → ✅ **Terminal-B instalada y funcionando**.

Si NO aparece:
- Correr `D:\HERRAMIENTAS_RED\DIAGNOSTICAR_RED.bat` en Terminal-B.
- Ver la guía `D:\HERRAMIENTAS_RED\RESCATE_DE_EMERGENCIA.md`, sección "Problema 2".
- Lo más común: `pocketbaseUrl` quedó mal → correr `REPARAR_CONFIG.bat`.

---

## 7) Sacar el pendrive

Cuando el test funcional dio OK:

- Click derecho en el ícono USB de la bandeja → "Expulsar KINGSTON".
- Sacá el pendrive físicamente.
- Guardalo en un lugar seguro. **Es tu red de contención**. Si algo falla más
  adelante, volvés a enchufarlo y usás las herramientas de `HERRAMIENTAS_RED/`.

---

## 🆘 Si algo sale mal

### "El pendrive no se detecta"
- Probá otro puerto USB.
- Chequeá que la unidad aparezca en el explorador (D:, E:, F:).

### "El instalador dice ERROR y se detiene"
- Sacá foto del error.
- El log completo queda en `C:\fcea_recuperador.log` o en la ventana negra.
- Correr `RECUPERAR SISTEMA.bat` para diagnóstico. **No re-ejecutes INSTALAR
  ciegamente**, avisá a soporte primero.

### "Chrome se abre pero dice 'Error 500' o 'No se conecta al servidor'"
- Esperá 30 segundos más y refrescá con F5. A veces PocketBase tarda en arrancar.
- Si sigue: correr `DIAGNOSTICAR_RED.bat`.

### "Instalé pero al día siguiente no arranca solo al prender"
- Correr manualmente `C:\sistema-llaves-fcea\scripts\install\INICIAR.bat`.
- Configurar arranque automático:
  ```
  powershell -ExecutionPolicy Bypass -File C:\sistema-llaves-fcea\scripts\install\CONFIGURAR_INICIO_AUTOMATICO.ps1
  ```

---

## 📝 Checklist final para Terminal-B

- [ ] `ipconfig` muestra IP en rango `192.168.100.x`
- [ ] `ping 192.168.100.10` responde
- [ ] Chrome muestra la pantalla de Terminal (no la de Monitor)
- [ ] Un pedido de prueba llegó al Monitor en menos de 3 segundos
- [ ] `C:\sistema-llaves-fcea\` existe y tiene la subcarpeta `pocketbase/`
- [ ] Al reiniciar la PC, el sistema arranca solo (probarlo)
- [ ] Pendrive guardado en lugar seguro
