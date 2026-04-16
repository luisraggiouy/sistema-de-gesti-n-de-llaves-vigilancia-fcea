# 💾 FUNCIONAMIENTO: Respaldos Automáticos del Sistema
## Sistema de Gestión de Llaves — FCEA

**Versión:** 1.0  
**Fecha:** Abril 2026  
**Destinatarios:** Autoridades de la Facultad, Personal de Sistemas

---

## 1. Resumen ejecutivo para autoridades

El sistema cuenta con un mecanismo de **respaldos automáticos** que garantiza que, aunque la computadora falle, se apague inesperadamente, o el sistema se dañe, **nunca se pierda el historial** de préstamos de llaves, usuarios registrados ni autorizaciones.

### ¿Cómo se logra esto?

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   El sistema copia automáticamente toda la base de      │
│   datos cada semana (domingos a las 8:00 AM) y guarda   │
│   las últimas 10 copias comprimidas en una carpeta      │
│   especial. Si algo falla, se puede restaurar desde     │
│   cualquiera de esas copias.                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 2. ¿Qué datos se respaldan?

| Dato | ¿Se respalda? | Descripción |
|------|:------------:|-------------|
| Historial de préstamos de llaves | ✅ Sí | Quién retiró qué llave, cuándo, y cuándo la devolvió |
| Usuarios registrados | ✅ Sí | Nombres, celulares, tipo de usuario |
| Autorizaciones especiales | ✅ Sí | Personas autorizadas a retirar llaves específicas |
| Configuración de llaves | ✅ Sí | Nombres de lugares, zonas, tipos |
| Vigilantes y turnos | ✅ Sí | Lista de vigilantes y sus turnos |
| Objetos olvidados | ✅ Sí | Registro de objetos encontrados |
| Estadísticas del Dashboard | ✅ Sí | Se calculan a partir de los datos anteriores |

> **En resumen:** Se respalda **TODO**. La base de datos completa se copia íntegramente.

---

## 3. ¿Cómo funciona el respaldo automático?

### 3.1 El proceso paso a paso (lo hace la computadora sola)

```
Cada domingo a las 8:00 AM, automáticamente:

  1️⃣  El sistema verifica que hay espacio suficiente en el disco
      (necesita al menos 15% libre)

  2️⃣  Detiene temporalmente la base de datos (2 segundos)
      para asegurar que la copia sea perfecta

  3️⃣  Copia el archivo de base de datos completo
      (pocketbase/pb_data/data.db)

  4️⃣  Comprime la copia en formato ZIP para ahorrar espacio
      (una base de datos de 50 MB se comprime a ~15 MB)

  5️⃣  Reinicia la base de datos automáticamente
      (el sistema vuelve a funcionar en segundos)

  6️⃣  Verifica la integridad de la base de datos
      (comprueba que no haya datos corruptos)

  7️⃣  Elimina las copias más antiguas si hay más de 10
      (siempre mantiene las 10 más recientes)

  8️⃣  Registra todo en un archivo de log
      (para que se pueda auditar qué pasó)
```

### 3.2 ¿Dónde se guardan los respaldos?

```
pocketbase\
├── pb_data\
│   └── data.db                    ← Base de datos ACTIVA (la que usa el sistema)
│
├── pb_backups\                    ← 📁 CARPETA DE RESPALDOS
│   ├── backup_full_20260412_080000.db.zip    ← Respaldo del 12/04/2026
│   ├── backup_full_20260405_080000.db.zip    ← Respaldo del 05/04/2026
│   ├── backup_full_20260329_080000.db.zip    ← Respaldo del 29/03/2026
│   └── ... (hasta 10 respaldos)
│
└── maintenance\
    └── logs\
        └── maintenance.log        ← Registro de todas las operaciones
```

### 3.3 ¿Cuánto espacio ocupan los respaldos?

| Concepto | Tamaño aproximado |
|----------|-------------------|
| Base de datos activa | 10-100 MB (depende del uso) |
| Cada respaldo comprimido | 3-30 MB |
| 10 respaldos (máximo) | 30-300 MB |
| **Total máximo** | **~400 MB** |

> El sistema automáticamente borra los respaldos más antiguos cuando hay más de 10, por lo que el espacio nunca crece indefinidamente.

---

## 4. ¿Qué pasa si la computadora falla?

### Escenario 1: La computadora se apaga inesperadamente

```
¿Se pierden datos?  → NO (o casi nada)

Explicación: La base de datos SQLite que usa el sistema escribe los datos
al disco inmediatamente. Si la computadora se apaga de golpe, como máximo
se podría perder la última operación que se estaba realizando en ese
exacto instante (por ejemplo, un préstamo que se estaba registrando en
ese segundo). Todo lo anterior está guardado.

Qué hacer: Encender la computadora y ejecutar iniciar_sistema.bat
```

### Escenario 2: El disco duro se daña

```
¿Se pierden datos?  → DEPENDE

Si los respaldos están en el mismo disco: Se pierden junto con el disco.
Si los respaldos están en un pendrive externo: NO se pierden.

Recomendación: Copiar periódicamente la carpeta pb_backups a un
pendrive externo o a otra computadora de la red.
```

### Escenario 3: Alguien borra archivos por error

```
¿Se pierden datos?  → NO (si no borró la carpeta pb_backups)

Qué hacer: Restaurar desde el último respaldo (ver sección 5).
```

### Escenario 4: El sistema se corrompe (errores extraños)

```
¿Se pierden datos?  → NO

El script de mantenimiento verifica la integridad de la base de datos
cada semana. Si detecta problemas, lo registra en el log.
Se puede restaurar desde un respaldo anterior al problema.
```

---

## 5. ¿Cómo restaurar desde un respaldo?

### Paso a paso (para Personal de Sistemas):

```
PASO 1:  Detenga el sistema
         (cierre las ventanas de comandos del sistema)

PASO 2:  Vaya a la carpeta de respaldos:
         pocketbase\pb_backups\

PASO 3:  Elija el respaldo más reciente
         (el archivo .zip con la fecha más nueva)

PASO 4:  Descomprima el archivo .zip
         (clic derecho → Extraer aquí)

PASO 5:  Copie el archivo .db extraído y péguelo en:
         pocketbase\pb_data\
         Renómbrelo a "data.db" (reemplazando el existente)

PASO 6:  Ejecute iniciar_sistema.bat
         El sistema arrancará con los datos del respaldo.
```

> ⚠️ **IMPORTANTE:** Al restaurar un respaldo, se recuperan los datos hasta la fecha de ese respaldo. Los datos ingresados después de esa fecha se perderán. Por eso es importante que los respaldos sean frecuentes.

---

## 6. Programación del respaldo automático

### ¿Cómo se programa? (Tarea programada de Windows)

El respaldo automático se ejecuta mediante el **Programador de Tareas de Windows**. Para configurarlo:

1. Abra el **Programador de Tareas** (busque "Programador de tareas" en el menú Inicio)
2. Haga clic en **"Crear tarea básica"**
3. Configure:
   - **Nombre:** `Mantenimiento Sistema Llaves FCEA`
   - **Desencadenador:** Semanalmente, Domingos, 08:00 AM
   - **Acción:** Iniciar un programa
   - **Programa:** `powershell.exe`
   - **Argumentos:** `-ExecutionPolicy Bypass -File "C:\sistema-llaves-fcea\pocketbase\maintenance\system_maintenance.ps1"`
4. Marque **"Ejecutar tanto si el usuario inició sesión como si no"**
5. Haga clic en **Finalizar**

### ¿Cómo verificar que está funcionando?

Revise el archivo de log:
```
pocketbase\maintenance\logs\maintenance.log
```

Debería ver entradas como:
```
[2026-04-13 08:00:01] [INFO] === Inicio del mantenimiento programado ===
[2026-04-13 08:00:01] [INFO] Espacio en disco: 45.23 GB libre de 120 GB (37.69%)
[2026-04-13 08:00:03] [INFO] Backup full completado exitosamente: backup_full_20260413_080003.db.zip
[2026-04-13 08:00:05] [INFO] Verificación de integridad de la base de datos: OK
[2026-04-13 08:00:05] [INFO] === Mantenimiento completado exitosamente ===
```

---

## 7. Verificaciones adicionales del mantenimiento

Además del respaldo, el script de mantenimiento automático realiza:

| Verificación | Qué hace | Frecuencia |
|-------------|----------|-----------|
| **Espacio en disco** | Alerta si queda menos del 15% libre | Cada ejecución |
| **Integridad de la base** | Verifica que no haya datos corruptos | Cada ejecución |
| **Limpieza de respaldos** | Borra los más antiguos si hay más de 10 | Cada ejecución |
| **Rotación de logs** | Si el log supera 10 MB, lo archiva y crea uno nuevo | Cada ejecución |

---

## 8. Recomendaciones para máxima seguridad

### 🥇 Nivel básico (mínimo recomendado)
- ✅ Dejar el respaldo automático semanal funcionando
- ✅ Verificar el log una vez al mes

### 🥈 Nivel intermedio (recomendado)
- ✅ Todo lo anterior
- ✅ Copiar la carpeta `pb_backups` a un pendrive externo una vez al mes
- ✅ Guardar el pendrive en un lugar diferente a donde está la computadora

### 🥉 Nivel avanzado (ideal)
- ✅ Todo lo anterior
- ✅ Copiar los respaldos a una carpeta compartida en la red de la Facultad
- ✅ Tener un segundo pendrive de recuperación actualizado
- ✅ Hacer una prueba de restauración cada 6 meses (para verificar que los respaldos funcionan)

---

## 9. Preguntas frecuentes

**P: ¿El respaldo interrumpe el uso del sistema?**  
R: Sí, pero solo por **2-3 segundos** mientras se copia la base de datos. Los usuarios prácticamente no lo notan. Se hace los domingos a las 8 AM cuando la Facultad está cerrada.

**P: ¿Qué pasa si la computadora está apagada el domingo a las 8 AM?**  
R: El respaldo no se ejecuta esa semana. Windows puede configurarse para ejecutar la tarea "lo antes posible" cuando se encienda la computadora. Se recomienda dejar la computadora encendida.

**P: ¿Puedo hacer un respaldo manual en cualquier momento?**  
R: Sí. Simplemente copie el archivo `pocketbase\pb_data\data.db` a cualquier ubicación segura. Eso es un respaldo completo.

**P: ¿Cuánto historial se puede guardar?**  
R: Ilimitado. La base de datos crece gradualmente con el uso. Con un uso normal de la Facultad, la base de datos no debería superar los 100 MB incluso después de varios años.

**P: ¿Los respaldos incluyen las contraseñas del Dashboard?**  
R: Sí, todo está incluido en la base de datos.

---

## 10. Resumen visual

```
                    SISTEMA DE RESPALDOS
                    ═══════════════════

  ┌──────────────┐     Cada domingo     ┌──────────────┐
  │  Base de     │ ──── 8:00 AM ──────► │  Respaldo    │
  │  datos       │     automático       │  comprimido  │
  │  activa      │                      │  (.zip)      │
  │  (data.db)   │                      │              │
  └──────────────┘                      └──────┬───────┘
        │                                      │
        │                                      ▼
        │                              ┌──────────────┐
        │                              │  Carpeta     │
        │                              │  pb_backups  │
        │                              │  (10 copias) │
        │                              └──────┬───────┘
        │                                      │
        │    Si el sistema falla:              │
        │                                      ▼
        │                              ┌──────────────┐
        │◄──── Se restaura desde ──────│  Respaldo    │
        │      el más reciente         │  elegido     │
        │                              └──────────────┘
        │
        ▼
  ┌──────────────┐
  │  Sistema     │
  │  funcionando │
  │  normalmente │
  └──────────────┘

  RESULTADO: Los datos NUNCA se pierden.
```

---

*Documento preparado para presentación a las autoridades de FCEA.*
