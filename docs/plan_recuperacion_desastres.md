# Plan de Recuperación ante Desastres (DRP)

**Sistema de Gestión de Llaves – FCEA v2.0**

Este documento describe el procedimiento para reconstruir el sistema
completo en caso de **incendio, robo, falla total de hardware o
catástrofe**.

---

## 1. Escenario contemplado

> *"Se quema el local de vigilancia. Se pierden las 3 PCs, el switch,
> los cables y todos los soportes en sitio. El sistema deja de funcionar."*

Objetivo: que con **un solo pendrive bien custodiado** y **3 PCs nuevas
cualesquiera con Windows 10/11**, se pueda volver a operar el sistema en
menos de 3 horas, con la última foto disponible de los datos.

---

## 2. Métricas del plan

| Métrica | Valor | Definición |
|---------|-------|------------|
| **RTO** (Recovery Time Objective) | **2 a 3 horas** | Tiempo desde 3 PCs vacías hasta sistema operando |
| **RPO** (Recovery Point Objective) | **≤ 7 días** | Datos perdidos como máximo (si se cumple la actualización semanal) |
| Pérdida sin actualización | 1 día / día sin actualizar | Sin política semanal el RPO se degrada linealmente |

> **Importante — qué NO se borra durante el mantenimiento automático:** El
> backup diario solo elimina **archivos ZIP de backup obsoletos** (>14 días)
> de la carpeta `backups\` de la cabina, para liberar espacio en disco. La
> **base de datos productiva** (`pocketbase\pb_data\data.db`), el historial
> de movimientos, usuarios, vigilantes, autorizaciones, objetos olvidados
> con sus fotos y la agenda **no se borran nunca**. El procedimiento DRP
> descrito a continuación restaura el último estado de `pb_data\` que viaja
> dentro del pendrive INSTALADOR DRP (de ahí la importancia de la
> actualización semanal). Ver
> [`guia_mantenimiento_paso_a_paso.md`](./guia_mantenimiento_paso_a_paso.md) § 1.1
> para el detalle exhaustivo de la política de retención.

---

## 3. Inventario mínimo de continuidad

Debe mantenerse **fuera del local de vigilancia** (caja fuerte de
Decanato, oficina alterna, domicilio del responsable o bóveda) el
siguiente kit:

### Kit obligatorio
- **1 pendrive INSTALADOR DRP** (16 GB recomendado), actualizado
  semanalmente. Contiene:
  - Código fuente completo del sistema
  - `pb_data\` con TODOS los datos productivos al día del último backup
  - `pb_backups\` con backups históricos
  - **Node.js portable** (~30 MB embebido — no requiere internet)
  - `INSTALAR.bat`, `DESINSTALAR.bat`, `ACTUALIZAR_DATOS.bat`
  - Documentación completa

### Kit recomendado adicional
- **1 pendrive RECUPERACIÓN** (8 GB), regenerado mensualmente.
- **1 pendrive CÓDIGO FUENTE** (cualquier capacidad), regenerado
  cuando hay cambios mayores. Custodia institucional permanente.
- **1 switch Ethernet de 5 puertos** + 5 cables RJ-45 de 2 m.
- **Cuaderno físico de movimientos** (registro paralelo manual de las
  últimas semanas, para recargar los datos perdidos entre el último
  backup y el incidente).

---

## 4. Procedimiento de reconstrucción paso a paso

### Fase 1 — Hardware (30 minutos)

1. Conseguir 3 PCs cualesquiera con Windows 10/11 (mini PCs, escritorio
   o portátiles). Mínimo:
   - Cabina/Monitor: 16 GB RAM, SSD 256 GB.
   - Terminales A y B: 4 GB RAM, SSD 128 GB.
2. Conectar las 3 PCs al switch Ethernet.
3. Asignar IPs estáticas:
   - Cabina: `192.168.50.10`
   - Terminal-A: `192.168.50.11`
   - Terminal-B: `192.168.50.12`
   - Máscara: `255.255.255.0`, sin gateway.
4. Verificar conectividad cruzada con `ping`.

### Fase 2 — Instalación de la Cabina (60 minutos)

1. Conectar el pendrive INSTALADOR DRP en la PC de la cabina.
2. Click derecho en `INSTALAR.bat` → **Ejecutar como administrador**.
3. Cuando pregunte el modo, elegir según el caso:
   - `[2]` Económica si las 3 PCs tienen teclado/mouse.
   - `[3]` Mixta si solo la cabina tiene táctil.
   - `[4]` Ideal si las 3 PCs son táctiles.
4. Cuando pregunte el rol, elegir `[S]` (Servidor/Monitor).
5. Esperar a que `npm install` + `npm run build` terminen
   (~10-15 min). No se requiere internet: usa `node-portable\`.
6. Cuando pregunte *"¿Restaurar TODOS los datos del pendrive? [S/N]"*,
   responder **`S`**.
7. Verificar que aparece el mensaje:
   > `[OK] DATOS PRODUCTIVOS RESTAURADOS CORRECTAMENTE`
8. Anotar la IP local de la cabina (`ipconfig`).

### Fase 3 — Instalación de Terminal-A (30 minutos)

1. Conectar el pendrive en la PC de Terminal-A.
2. Ejecutar `INSTALAR.bat` como administrador.
3. Elegir el mismo modo que en la cabina.
4. Cuando pregunte el rol, elegir `[A]`.
5. Indicar la IP de la cabina (`192.168.50.10`).
6. Esperar a que termine la instalación.

### Fase 4 — Instalación de Terminal-B (30 minutos)

1. Repetir Fase 3 en la PC de Terminal-B, eligiendo rol `[B]`.

### Fase 5 — Verificación (15 minutos)

1. En la cabina, abrir el navegador en `http://127.0.0.1:5173` (o
   `:4173` en modo build). Debe aparecer el Monitor de Vigilancia con
   **todas las llaves** del sistema.
2. En cada terminal, abrir `http://192.168.50.10:8090/api/health`.
   Debe responder `{"code":200,"message":"API is healthy."}`.
3. En cada terminal, abrir el navegador apuntando a la cabina; la UI
   debe cargar.
4. Hacer una **solicitud de prueba** desde Terminal-A: verificar que
   aparece en tiempo real en el Monitor de la cabina.

### Fase 6 — Recargar movimientos perdidos (variable)

Los movimientos ocurridos entre el último backup del pendrive y el
incidente **no están en el sistema**. Recargarlos manualmente desde el
cuaderno físico de respaldo: nuevas llaves entregadas, vigilantes
nuevos, autorizaciones recientes, objetos olvidados, etc.

---

## 5. Política de actualización del pendrive (CRÍTICA)

El RPO de 7 días solo se mantiene si se cumple la actualización
semanal. **Sin esta política, el plan DRP se degrada.**

### Procedimiento semanal (cada lunes)

1. Llegar a la cabina después del backup automático nocturno (que
   corre a las 03:00 hs).
2. Conectar el pendrive INSTALADOR DRP en la cabina.
3. Click derecho en `ACTUALIZAR_DATOS.bat` → Ejecutar como
   administrador. Tiempo: ~30 segundos.
4. Verificar que `ULTIMO_BACKUP.txt` muestra la fecha de hoy.
5. Llevar el pendrive de vuelta a su lugar de custodia (caja fuerte,
   oficina alterna, etc.).
6. Registrar la actualización en el libro de mantenimiento.

### Procedimiento mensual

1. Regenerar el pendrive de RECUPERACIÓN (si existe).
2. Verificar que el pendrive de CÓDIGO FUENTE sigue siendo legible.

### Procedimiento trimestral

1. **Prueba de simulacro DRP**: en una PC de prueba (no productiva),
   ejecutar `INSTALAR.bat` desde el pendrive y validar que se levanta
   con todos los datos. Documentar el resultado.
2. Esta prueba debe ser **obligatoria** porque verifica que el pendrive
   sigue funcionando y que el procedimiento se mantiene operativo.

---

## 6. Roles y responsabilidades

| Tarea | Frecuencia | Responsable sugerido |
|-------|------------|----------------------|
| Actualización semanal del pendrive | Lunes | Operador de mantenimiento |
| Custodia del pendrive | Permanente | Coordinación de Servicios Generales |
| Simulacro DRP | Trimestral | Equipo de Sistemas FCEA |
| Auditoría del DRP | Anual | Decanato / Sistemas |

---

## 7. Variantes del escenario

### 7.1. Falla de una sola PC

No es un desastre completo. Procedimiento simplificado:

1. Adquirir/reasignar 1 PC nueva.
2. Conectar el pendrive INSTALADOR DRP.
3. Ejecutar `INSTALAR.bat`, elegir el rol correspondiente.
4. **NO** restaurar datos (los datos están vivos en la cabina si la PC
   afectada era una terminal).
5. Si la PC afectada **es la cabina**, sí restaurar datos del pendrive.

### 7.2. Pérdida de datos pero hardware intacto

1. Ejecutar el script `RECUPERAR.bat` del pendrive de Recuperación.
2. Opción `[2]` Restaurar base de datos desde backup.

### 7.3. Robo del pendrive (sin incidente físico)

Los datos del sistema siguen vivos en la cabina. Pero la confidencialidad
de los datos del pendrive se ve comprometida:

1. Regenerar pendrive desde la cabina actual.
2. Cambiar la contraseña del administrador del sistema.
3. Considerar cifrar el pendrive con BitLocker.

---

## 8. Costos estimados de continuidad

| Componente | Costo aprox. (USD) | Vida útil | Comentario |
|------------|-------------------|-----------|------------|
| 1 pendrive 16 GB | 5 | 5 años | Instalador DRP |
| 1 pendrive 8 GB | 3 | 5 años | Recuperación |
| 1 switch 5 puertos | 15 | 7 años | Ya existente |
| 3 PCs nuevas (emergencia) | 600-1500 | 5 años | Solo se compran si ocurre el desastre |
| **Total mantenimiento anual** | **~5 USD** | — | Reemplazo periódico de pendrives |

---

## 9. Anexo: comandos de regeneración del pendrive

### Generar pendrive desde cero
```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive D: -Tipo instalador
```

### Actualizar solo los datos (semanal)

Método recomendado: en el **Monitor Vigilancia** (con el sistema prendido),
doble click en `ACTUALIZAR DATOS (Luis).bat` del pendrive de rescate. Toma un
snapshot consistente vía el backup interno de PocketBase, **sin cortar el
servicio** y sin pisar `config.json`.

> El modo `.\scripts\pendrive\crear_pendrive.ps1 -Drive D: -Tipo actualizar-datos`
> quedó **deprecado** (copiaba `pb_data` en frío, con riesgo de copia
> inconsistente del SQLite). No usarlo.

### Generar pendrive sin Node.js portable (ahorra ~30 MB)
```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive D: -Tipo instalador -SinNode
```

### Generar pendrive con datos de otra ruta
```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive D: -Tipo instalador `
    -PbDataPath "C:\sistema-llaves-fcea\pocketbase\pb_data"
```

---

## 10. Validación firmada

Cada actualización semanal y cada simulacro trimestral debe quedar
documentado con fecha, responsable y resultado. Plantilla sugerida:

```
Fecha          : _________________
Tipo           : [ ] Actualización semanal
                 [ ] Simulacro trimestral
                 [ ] Reconstrucción real (incidente: _____________)
Responsable    : _________________
Resultado      : [ ] OK
                 [ ] OK con observaciones (detalle abajo)
                 [ ] Falló (detalle abajo)
Observaciones  : _________________________________________________
                 _________________________________________________
Firma          : _________________
```

---

*Plan de Recuperación ante Desastres v1.0 — FCEA v2.0*
