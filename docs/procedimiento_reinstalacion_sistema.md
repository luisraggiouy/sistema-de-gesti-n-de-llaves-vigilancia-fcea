# 🔧 PROCEDIMIENTO: Reinstalación del Sistema ante Fallas
## Sistema de Gestión de Llaves — FCEA

**Versión:** 2.0  
**Fecha:** Abril 2026  
**Destinatarios:** Autoridades de la Facultad, Personal de Sistemas, Jefes de Vigilancia

---

## 1. Resumen para autoridades

El sistema está diseñado para que, en caso de falla grave, pueda ser **restaurado completamente** siguiendo pasos simples. Existen dos métodos:

| Método | Dificultad | Tiempo estimado | ¿Quién lo hace? |
|--------|-----------|-----------------|-----------------|
| **Método A: Pendrive de recuperación** | Muy fácil (enchufar y ejecutar) | 5-10 minutos | Cualquier persona |
| **Método B: Reinstalación manual** | Intermedia | 15-30 minutos | Personal de Sistemas |

---

## 2. Escenarios de falla y tiempos reales de recuperación

### 📊 Tabla de escenarios críticos

| # | Escenario | Gravedad | ¿Se pierden datos? | Método de recuperación | Tiempo real | ¿Quién lo resuelve? |
|---|-----------|----------|--------------------|-----------------------|-------------|---------------------|
| 1 | **Corte de luz / apagón** | 🟢 Baja | NO (máximo 1 operación en curso) | Encender PC + ejecutar `iniciar_sistema.bat` | **2-3 min** | Vigilante |
| 2 | **PC se congela / pantalla azul** | 🟢 Baja | NO | Reiniciar PC + ejecutar `iniciar_sistema.bat` | **3-5 min** | Vigilante |
| 3 | **Software corrupto** (archivos del sistema dañados) | 🟡 Media | NO (la base de datos está separada) | Pendrive de recuperación (Método A) | **5-10 min** | Vigilante o Jefe |
| 4 | **Disco duro dañado parcialmente** (solo archivos del sistema) | 🟡 Media | NO (si `pb_data` está intacta) | Pendrive de recuperación (Método A) | **5-10 min** | Vigilante o Jefe |
| 5 | **Disco duro dañado totalmente** (PC misma) | 🔴 Alta | DEPENDE del pendrive | Pendrive en la MISMA PC (si arranca) | **10-15 min** | Jefe de Vigilancia |
| 6 | **PC destruida** (hay que usar otra PC que YA tiene Node.js) | 🔴 Alta | NO (datos en el pendrive) | Pendrive en PC nueva con Node.js | **5-10 min** | Personal de Sistemas |
| 7 | **PC destruida** (PC nueva SIN Node.js, CON pendrive completo) | 🔴 Crítica | NO (datos en el pendrive) | Pendrive con instalador de Node.js | **15-20 min** | Personal de Sistemas |
| 8 | **PC destruida + pendrive perdido** (peor caso) | 🔴 Crítica | Datos hasta último respaldo semanal | Reinstalación manual desde GitHub + respaldo | **30-45 min** | Personal de Sistemas |

---

### Detalle de cada escenario

#### 🟢 Escenario 1: Corte de luz / Apagón
```
Qué pasó:    Se fue la luz y la computadora se apagó de golpe.
Datos:       NO se pierden. SQLite escribe al disco inmediatamente.
             Como máximo se pierde la operación que se estaba haciendo
             en ese exacto segundo (ej: un préstamo a medio registrar).
Recuperación:
  1. Encender la computadora
  2. Doble clic en "iniciar_sistema.bat"
  3. Esperar 30 segundos
  4. Abrir el navegador → http://localhost:8080/
Tiempo:      2-3 minutos
Quién:       Cualquier vigilante
```

#### 🟢 Escenario 2: PC se congela / Pantalla azul
```
Qué pasó:    Windows se colgó, apareció pantalla azul, o la PC no responde.
Datos:       NO se pierden.
Recuperación:
  1. Mantener presionado el botón de encendido 10 segundos (apagado forzado)
  2. Esperar 10 segundos
  3. Encender la computadora
  4. Doble clic en "iniciar_sistema.bat"
Tiempo:      3-5 minutos
Quién:       Cualquier vigilante
```

#### 🟡 Escenario 3: Software corrupto
```
Qué pasó:    El sistema no arranca, da errores extraños, o alguien borró
             archivos del sistema por accidente.
Datos:       NO se pierden. La base de datos (pb_data) está en una carpeta
             separada y no se ve afectada.
Recuperación:
  1. Conectar el pendrive de recuperación
  2. Abrir el pendrive → doble clic en "RESTAURAR_SISTEMA.bat"
  3. Seguir las instrucciones en pantalla
  4. El script respalda los datos existentes antes de restaurar
Tiempo:      5-10 minutos
Quién:       Vigilante o Jefe de Vigilancia
```

#### 🟡 Escenario 4: Disco duro dañado parcialmente
```
Qué pasó:    Algunos archivos del sistema están corruptos pero la PC
             enciende y el disco funciona parcialmente.
Datos:       NO se pierden SI la carpeta pocketbase\pb_data está intacta.
Recuperación:
  1. Intentar copiar pocketbase\pb_data a un pendrive (por seguridad)
  2. Conectar el pendrive de recuperación
  3. Ejecutar "RESTAURAR_SISTEMA.bat"
  4. El script detecta y respalda los datos existentes automáticamente
Tiempo:      5-10 minutos
Quién:       Jefe de Vigilancia o Personal de Sistemas
```

#### 🔴 Escenario 5: Disco duro dañado totalmente (misma PC)
```
Qué pasó:    El disco duro murió. Hay que instalar un disco nuevo o
             reinstalar Windows.
Datos:       Se pierden los datos del disco, PERO se recuperan desde
             el pendrive de recuperación (que tiene la última copia).
Recuperación:
  1. Instalar disco nuevo / reinstalar Windows
  2. Conectar el pendrive de recuperación
  3. Ejecutar "RESTAURAR_SISTEMA.bat"
  4. El script instala Node.js automáticamente si no está
  5. Restaura el sistema completo con los datos del pendrive
Tiempo:      10-15 minutos (sin contar instalación de Windows)
Quién:       Personal de Sistemas
Pérdida:     Datos desde la última actualización del pendrive
             (por eso se recomienda actualizar el pendrive cada mes)
```

#### 🔴 Escenario 6: PC destruida → PC nueva CON Node.js
```
Qué pasó:    La computadora se rompió completamente. Se consiguió otra
             que ya tiene Node.js instalado.
Datos:       NO se pierden (están en el pendrive).
Recuperación:
  1. Conectar el pendrive de recuperación a la PC nueva
  2. Ejecutar "RESTAURAR_SISTEMA.bat"
  3. El sistema se instala y arranca con todos los datos históricos
Tiempo:      5-10 minutos
Quién:       Personal de Sistemas
```

#### 🔴 Escenario 7: PC destruida → PC nueva SIN Node.js (pendrive completo)
```
Qué pasó:    La computadora se rompió. La PC nueva no tiene nada instalado
             excepto Windows.
Datos:       NO se pierden (están en el pendrive).
Recuperación:
  1. Conectar el pendrive de recuperación
  2. Ejecutar "RESTAURAR_SISTEMA.bat"
  3. El script detecta que no hay Node.js
  4. Instala Node.js automáticamente desde el pendrive (~5 min)
  5. Copia el sistema y los datos
  6. Inicia el sistema
Tiempo:      15-20 minutos
Quién:       Personal de Sistemas
Requisito:   El pendrive debe tener el instalador de Node.js
             (se incluye al preparar el pendrive con el script)
```

#### 🔴 Escenario 8: PEOR CASO — PC destruida + pendrive perdido
```
Qué pasó:    Se rompió la computadora Y se perdió el pendrive de
             recuperación. Solo quedan los respaldos semanales
             (si se copiaron a otro lugar) o el código en GitHub.
Datos:       Se recuperan hasta el último respaldo semanal disponible.
             Si no hay respaldos externos, se pierden los datos.
Recuperación:
  1. Conseguir una PC con Windows 10/11
  2. Instalar Node.js (descargar de https://nodejs.org/)
  3. Instalar Git (descargar de https://git-scm.com/)
  4. Abrir cmd y ejecutar:
     git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git C:\sistema-llaves-fcea
  5. cd C:\sistema-llaves-fcea
  6. npm install
  7. Si hay respaldo de pb_data, copiarlo a pocketbase\pb_data\
  8. Ejecutar iniciar_sistema.bat
Tiempo:      30-45 minutos
Quién:       Personal de Sistemas
Pérdida:     Datos desde el último respaldo disponible
```

---

## 3. MÉTODO A: Pendrive de Recuperación (Mejorado)

### 3.1 ¿Qué contiene el pendrive de recuperación?

```
RECUPERACION_SISTEMA_LLAVES_FCEA\
├── RESTAURAR_SISTEMA.bat           ← Ejecutar esto para restaurar
├── sistema\                        ← Código fuente completo
│   ├── node_modules\               ← Dependencias pre-instaladas
│   ├── pocketbase\                 ← Motor de base de datos
│   ├── src\                        ← Código de la aplicación
│   └── iniciar_sistema.bat         ← Iniciador del sistema
├── respaldos_db\                   ← Base de datos
│   └── pb_data_ultimo\             ← Última copia de los datos
└── instaladores\                   ← Software necesario
    └── node-setup.msi              ← Instalador de Node.js
```

### 3.2 Preparación del pendrive (se hace UNA vez, se actualiza cada mes)

> ⚠️ Este paso lo realiza el personal de Sistemas al momento de la instalación inicial.

**Requisitos:**
- Pendrive USB de al menos **8 GB** (recomendado 16 GB)
- El sistema debe estar funcionando correctamente

**Procedimiento automatizado:**

1. Conecte el pendrive a la computadora donde funciona el sistema
2. Abra una ventana de comandos (cmd)
3. Navegue a la carpeta del sistema:
   ```
   cd C:\sistema-llaves-fcea
   ```
4. Ejecute el script de preparación:
   ```
   scripts\preparar_pendrive_recuperacion.bat
   ```
5. Siga las instrucciones en pantalla
6. **Paso manual:** Descargue el instalador de Node.js de https://nodejs.org/ y cópielo a la carpeta `instaladores` del pendrive
7. Etiquete el pendrive: **"RECUPERACIÓN SISTEMA LLAVES FCEA - NO BORRAR"**
8. Guárdelo en un lugar seguro (caja fuerte de vigilancia o despacho del jefe)

### 3.3 Actualización mensual del pendrive

Para mantener los datos del pendrive actualizados:

1. Conecte el pendrive
2. Ejecute nuevamente `scripts\preparar_pendrive_recuperacion.bat`
3. El script sobrescribe los archivos con la versión más reciente
4. Guarde el pendrive nuevamente en su lugar seguro

### 3.4 Uso del pendrive de recuperación (cuando el sistema falla)

```
PASO 1:  Conecte el pendrive a cualquier puerto USB de la computadora.

PASO 2:  Abra "Este equipo" (Mi PC) y entre al pendrive.

PASO 3:  Entre a la carpeta "RECUPERACION_SISTEMA_LLAVES_FCEA"

PASO 4:  Haga doble clic en "RESTAURAR_SISTEMA.bat"

PASO 5:  Aparecerá una ventana negra con texto.
         Presione cualquier tecla cuando se lo pida.

PASO 6:  El script automáticamente:
         - Verifica si Node.js está instalado (si no, lo instala)
         - Respalda datos existentes (si los hay)
         - Copia el sistema completo
         - Restaura la base de datos
         - Inicia el sistema

PASO 7:  Cuando vea "RESTAURACION COMPLETADA EXITOSAMENTE",
         abra el navegador y vaya a http://localhost:8080/
```

> 💡 **Nota:** El pendrive NO borra los datos históricos. Primero los respalda y luego los restaura.

---

## 4. MÉTODO B: Reinstalación Manual (paso a paso)

Si no se dispone del pendrive de recuperación, siga estos pasos:

### Paso 1 — Verificar qué falló

Antes de reinstalar, intente estas soluciones rápidas:

| Síntoma | Solución rápida |
|---------|----------------|
| La pantalla dice "No se puede conectar" | Ejecute `iniciar_sistema.bat` (está en la carpeta del sistema) |
| La pantalla se ve pero no carga datos | Reinicie PocketBase: abra una ventana de comandos, vaya a la carpeta `pocketbase` y ejecute `pocketbase.exe serve` |
| La computadora se reinició | Simplemente ejecute `iniciar_sistema.bat` |
| Error de "puerto en uso" | Cierre todas las ventanas de comandos negras y vuelva a ejecutar `iniciar_sistema.bat` |

### Paso 2 — Si nada de lo anterior funciona: Reinstalar

#### 2a. Respaldar los datos (MUY IMPORTANTE)

Antes de hacer cualquier cosa, copie esta carpeta a un lugar seguro (escritorio, otro pendrive, etc.):

```
C:\sistema-llaves-fcea\pocketbase\pb_data\
```

Esta carpeta contiene **TODA la base de datos**: historial de llaves, usuarios registrados, autorizaciones, etc.

#### 2b. Obtener el código fuente

El código fuente del sistema está disponible en:
- **GitHub:** https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git
- **Pendrive de respaldo** (si se preparó uno)

Para descargar desde GitHub:
1. Abra una ventana de comandos (cmd)
2. Escriba:
```
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git C:\sistema-llaves-fcea
```

#### 2c. Instalar dependencias

1. Abra una ventana de comandos en la carpeta del sistema
2. Ejecute:
```
npm install
```
3. Espere a que termine (puede tardar 2-5 minutos)

#### 2d. Restaurar la base de datos

Copie la carpeta `pb_data` que respaldó en el paso 2a de vuelta a:
```
C:\sistema-llaves-fcea\pocketbase\pb_data\
```

#### 2e. Iniciar el sistema

Haga doble clic en `iniciar_sistema.bat`

---

## 5. ¿Qué necesita la computadora para funcionar?

| Requisito | Detalle |
|-----------|---------|
| **Sistema operativo** | Windows 10 o Windows 11 |
| **Node.js** | Versión 18 o superior (incluido en el pendrive de recuperación) |
| **Navegador** | Google Chrome (recomendado), Firefox o Edge |
| **Espacio en disco** | Mínimo 500 MB libres |
| **Memoria RAM** | Mínimo 4 GB |
| **Red** | NO necesaria para funcionamiento local |

### ¿Cómo verificar si Node.js está instalado?

1. Abra una ventana de comandos (cmd)
2. Escriba: `node --version`
3. Si aparece un número (ej: `v18.17.0`), está instalado
4. Si dice "no se reconoce", descárguelo de: https://nodejs.org/ (o use el instalador del pendrive)

---

## 6. Estructura de archivos importantes

```
C:\sistema-llaves-fcea\
│
├── iniciar_sistema.bat          ← EJECUTAR ESTO para iniciar el sistema
│
├── pocketbase\
│   ├── pocketbase.exe           ← Motor de base de datos
│   ├── pb_data\                 ← ⭐ BASE DE DATOS (NO BORRAR NUNCA)
│   │   └── data.db              ← Archivo principal de datos
│   ├── pb_backups\              ← Respaldos automáticos semanales (52 copias = 1 año)
│   ├── pb_migrations\           ← Estructura de la base de datos
│   └── maintenance\             ← Scripts de mantenimiento automático
│
├── scripts\
│   └── preparar_pendrive_recuperacion.bat  ← Para preparar/actualizar el pendrive
│
├── src\                         ← Código fuente de la aplicación
├── docs\                        ← Documentación (este archivo)
└── package.json                 ← Configuración del proyecto
```

> ⭐ **La carpeta más importante es `pocketbase\pb_data\`**. Mientras esta carpeta esté intacta, todos los datos históricos se conservan sin importar qué pase con el resto del sistema.

---

## 7. Estrategia de protección de datos (defensa en profundidad)

El sistema tiene **4 capas de protección** contra pérdida de datos:

```
CAPA 1: Base de datos activa (data.db)
        → Siempre actualizada, en el disco de la PC
        → Protegida por SQLite con journaling anti-corrupción

CAPA 2: Respaldos automáticos semanales (pb_backups/)
        → 52 copias comprimidas = 1 año de historial
        → Se ejecutan automáticamente cada domingo
        → Están en el MISMO disco (protegen contra corrupción, NO contra fallo de disco)

CAPA 3: Pendrive de recuperación
        → Copia completa del sistema + datos + instalador de Node.js
        → Se actualiza mensualmente
        → Protege contra fallo total de la PC

CAPA 4: Copia externa (recomendada)
        → Copiar pb_backups a otro pendrive o PC de la red
        → Protege contra pérdida del pendrive de recuperación
        → Protege contra robo o incendio
```

### Resumen visual de protección:

```
                    ¿Qué se dañó?
                         │
          ┌──────────────┼──────────────┐
          │              │              │
     Solo el         El disco      La PC entera
     software        duro          + el disco
          │              │              │
          ▼              ▼              ▼
     CAPA 1          CAPA 2        CAPA 3
     Base de datos   Respaldos     Pendrive de
     intacta         semanales     recuperación
          │              │              │
          ▼              ▼              ▼
     Restaurar       Restaurar     Restaurar en
     software        desde último  PC nueva con
     (5-10 min)      respaldo      pendrive
                     (5-10 min)    (15-20 min)
```

---

## 8. Contactos de emergencia

| Rol | Acción |
|-----|--------|
| **Vigilante** | Ejecutar `iniciar_sistema.bat` (escenarios 1-2) |
| **Jefe de Vigilancia** | Usar el pendrive de recuperación (escenarios 3-5) |
| **Personal de Sistemas** | Reinstalación manual completa (escenarios 6-8) |
| **Desarrollador** | Contactar a través del repositorio en GitHub |

---

## 9. Diagrama de decisión ante fallas

```
¿El sistema no funciona?
    │
    ├── ¿La computadora está encendida?
    │       NO → Encenderla y ejecutar iniciar_sistema.bat (2-3 min)
    │       SÍ ↓
    │
    ├── ¿Aparece la página pero sin datos?
    │       SÍ → Reiniciar PocketBase (ver Paso 1 del Método B) (2-3 min)
    │       NO ↓
    │
    ├── ¿Aparece "No se puede conectar"?
    │       SÍ → Ejecutar iniciar_sistema.bat (2-3 min)
    │       NO ↓
    │
    ├── ¿Nada funciona?
    │       → Usar el PENDRIVE DE RECUPERACIÓN (Método A) (5-10 min)
    │       → Si no hay pendrive: Método B (reinstalación manual) (30-45 min)
    │
    └── ¿Sigue sin funcionar después de reinstalar?
            → Llamar a Personal de Sistemas
```

---

## 10. Checklist de preparación (para Personal de Sistemas)

Al instalar el sistema por primera vez, asegúrese de:

- [ ] Sistema funcionando correctamente en la PC de vigilancia
- [ ] Pendrive de recuperación preparado con `scripts\preparar_pendrive_recuperacion.bat`
- [ ] Instalador de Node.js copiado al pendrive (`instaladores\node-setup.msi`)
- [ ] Pendrive etiquetado y guardado en lugar seguro
- [ ] Tarea programada de respaldos automáticos configurada (domingos 8 AM)
- [ ] Jefe de Vigilancia capacitado en uso del pendrive de recuperación
- [ ] Vigilantes capacitados en ejecutar `iniciar_sistema.bat`
- [ ] Recordatorio mensual configurado para actualizar el pendrive

---

*Documento preparado para presentación a las autoridades de FCEA.*
