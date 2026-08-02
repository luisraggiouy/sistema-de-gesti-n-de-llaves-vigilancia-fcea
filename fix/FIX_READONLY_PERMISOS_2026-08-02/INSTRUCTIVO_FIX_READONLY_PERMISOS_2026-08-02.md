# INSTRUCTIVO — FIX DE RAÍZ del readonly (permisos de data.db) — 2026-08-02

## La causa raíz REAL (por fin, con pruebas)
El diagnóstico mostró en los permisos NTFS:

```
data.db   NT AUTHORITY\SYSTEM:(F)
          BUILTIN\Administradores:(F)
          BUILTIN\Usuarios:(RX)     <-- solo LECTURA, sin escritura
```

PocketBase corre como el usuario **estándar `vigilancia`** (miembro de *Usuarios*).
Sobre `data.db` ese usuario tenía **solo lectura (RX)**, así que **SQLite abría la base
en modo solo-lectura** y **toda escritura fallaba**:
- `Failed to write log` / `Logs delete failed` (en `logs.db`)
- `Failed to update/create record (400)` (al crear/actualizar **solicitudes**)

Los **reads daban 200** (RX permite leer), por eso el sistema "parecía" vivo pero no
se podían registrar solicitudes ni entregas. Probablemente una recuperación/reinstalación
recreó `data.db` sin darle escritura a *Usuarios*.

## Qué hace el fix (ataca la causa)
1. Detiene PocketBase (datos quietos).
2. Quita atributo *read-only* y **otorga `Modify` (escritura) a *Usuarios* y al usuario
   `vigilancia` sobre TODO `pb_data`** de forma recursiva (`icacls`). **La clave del fix.**
3. Limpia `logs.db` e instala el `run_pocketbase.bat` que la borra en cada arranque.
4. Arranca UNA instancia y **verifica con una escritura REAL**: crea un registro de prueba
   en `solicitudes` y lo borra. Solo dice VERDE si la escritura funcionó.
5. Deja en el pendrive `ACL_ANTES.txt`, `ACL_DESPUES.txt` y el tail del log.

---

## PASOS (en el MONITOR DE VIGILANCIA)

1. Enchufá el pendrive en el **Monitor**.
2. Carpeta `fix\FIX_READONLY_PERMISOS_2026-08-02` → **doble clic en `APLICAR_FIX.bat`** → UAC **Sí**.
3. Esperá 30–60 s. Tiene que mostrar en verde:
   - `Permisos Modify otorgados a Usuarios y vigilancia.`
   - `PocketBase responde /api/health (vivo).`
   - `ESCRITURA a data.db OK (HTTP 200). data.db ya es ESCRIBIBLE.`
   - `[OK] FIX APLICADO: data.db ES ESCRIBIBLE.`
4. Tecla para cerrar.

## PRUEBA REAL
5. Desde **Terminal A/B**, enviá una **solicitud de llave** → debe **aparecer en el Monitor**.
6. Entregá y devolvé una llave de prueba (ciclo completo).

## Si NO sale verde
Traé la carpeta `_LOGS_RESULTADO_<fecha_hora>` del pendrive (tiene `ACL_ANTES/DESPUES`,
`create_test_error.txt` y `pocketbase_TAIL.txt`) y avisame.

---

### Después (SOLO cuando confirmes que funcionó)
Integro el `icacls /grant Modify` a los scripts críticos **Instalar sistema**,
**Recuperar sistema** y **Actualizar semilla** (para que la escritura de `data.db`
quede garantizada en cada instalación/recuperación y no vuelva a pasar), commit con
timestamp y push a GitHub.
