# FIX: Recuperador con Autocura de Rol — 2026-08-09

## Qué resuelve
El **Recuperador de conexión** hasta ahora arreglaba la **IP** del servidor en
`config.json`, pero **no reafirmaba el campo `rol`**. Por eso, si una PC quedaba con
el `rol` equivocado (como pasó el 09/08/2026, las 3 PCs con `rol=terminal-b`), el
Recuperador dejaba el rol mal.

Con este fix, el Recuperador **también corrige el `rol` según el NOMBRE de la PC**:

| Nombre de la PC (COMPUTERNAME) | Rol que fuerza |
|--------------------------------|----------------|
| `FCEA-TERMINAL-A`              | `terminal-a`   |
| `FCEA-TERMINAL-B`              | `terminal-b`   |
| `FCEA-DASHBOARD`               | `dashboard`    |
| `FCEA-MONITOR` / `CABINA` / `SERVIDOR` | (no se toca: el Monitor no usa el Recuperador) |

**No toca datos, no reinstala nada.** Solo edita los `config.json` / `install_config.json`,
igual que el Recuperador original, y hace **backup** del script anterior.

---

## ¿Dónde está "el RECUPERAR / REPARAR CONEXIÓN"? (aclaración importante)
Hay **dos formas** en que corre este recuperador, y usan **copias distintas** del script:

1. **Automático (auto-repair):** lo dispara solo `INICIAR.bat` a los 90s si no encuentra
   el servidor. Usa la copia **INSTALADA**:
   `C:\sistema-llaves-fcea\scripts\lib\reparar_conexion_servidor.ps1`
2. **Manual:** el lanzador del pendrive
   `...\scripts\pendrive\REPARAR_CONEXION_SERVIDOR_launcher.bat`, que ejecuta la copia
   **del propio pendrive** (`...\scripts\lib\reparar_conexion_servidor.ps1`).

👉 **Para esta prueba usamos la copia INSTALADA** (la del punto 1, que es la que corre sola
en producción). Por eso este fix incluye un botón **`PROBAR_RECUPERADOR.bat`** que ejecuta
directamente esa copia instalada, sin depender del lanzador del pendrive.
*(La copia del pendrive se actualizará sola cuando, ya confirmado el fix, regrabemos el
pendrive de recuperación con la versión integrada.)*

---

## Dónde probarlo
En una **TERMINAL (A o B)**. NO hace falta probarlo en el Monitor.
El **Monitor Vigilancia debe estar encendido** (el recuperador lo busca en la red).

## Pasos
1. Enchufá el pendrive en la **Terminal A** (o B).
2. Entrá a `<pendrive>\fix\FIX_RECUPERADOR_AUTOCURA_ROL_2026-08-09\`.
3. Doble clic en **`APLICAR_FIX.bat`** → aceptá el permiso de Administrador (**Sí**).
   - Hace backup del recuperador instalado y lo reemplaza por la versión reforzada.
   - Deja un log en `_RESULTADOS`.
4. **(Opcional, para forzar la prueba)** desconfigurá el rol a propósito:
   corré `<pendrive>\HERRAMIENTAS_RED\REPARAR_ROL_CONFIG` y elegí un rol **equivocado**
   (o editá el rol a mano en `config.json`). Así comprobás que el recuperador lo corrige.
5. Doble clic en **`PROBAR_RECUPERADOR.bat`** (dentro de esta misma carpeta del fix).
   - Es lo mismo que "correr el RECUPERAR", pero apuntando a la copia instalada reforzada.
   - Va a escanear la red, encontrar el Monitor y reescribir la config.
6. Verificá el resultado con `<pendrive>\HERRAMIENTAS_RED\DIAGNOSTICO_FORENSE`:
   el `rol` debe haber quedado **correcto** según el nombre de la PC
   (la Terminal A debe decir `terminal-a`, la B `terminal-b`).
7. Reiniciá / recargá el kiosko y confirmá que la terminal muestra su pantalla correcta.

## Cómo revertir
Al lado del original quedó `reparar_conexion_servidor.ps1.bak_<fecha_hora>` en
`C:\sistema-llaves-fcea\scripts\lib\`. Renombralo sobre el original para volver atrás.

## Traé el pendrive de vuelta
Traé el pendrive a la laptop de desarrollo con el log de `_RESULTADOS` y decime si
la terminal quedó con el rol correcto tras el `PROBAR_RECUPERADOR`. Recién ahí integro
el cambio al script crítico del repo (`scripts/lib/reparar_conexion_servidor.ps1`),
regrabo el pendrive de recuperación y hago el commit con timestamp.
