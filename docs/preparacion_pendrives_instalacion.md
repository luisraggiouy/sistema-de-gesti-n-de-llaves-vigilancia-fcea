# Preparación de Pendrives de Instalación y Recuperación
## Sistema de Gestión de Llaves — FCEA

**Versión:** 1.0  
**Fecha:** Abril 2026  
**Destinatarios:** Personal de Sistemas

---

## Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Pendrive 1: Instalador Automático](#pendrive-1-instalador-automático)
3. [Pendrive 2: Recuperación del Sistema](#pendrive-2-recuperación-del-sistema)
4. [Configuración de Hardware](#configuración-de-hardware)
5. [Proceso de Grabación de Pendrives](#proceso-de-grabación-de-pendrives)
6. [Guía de Uso](#guía-de-uso)

---

## Resumen Ejecutivo

El sistema requiere **DOS pendrives** con propósitos diferentes:

| Pendrive | Propósito | Cuándo se usa | Tamaño mínimo |
|----------|-----------|---------------|---------------|
| **INSTALADOR** | Instalación inicial del sistema | Una vez, al configurar por primera vez | 16 GB |
| **RECUPERACIÓN** | Restaurar sistema ante fallas | Cuando el sistema falla o se corrompe | 8 GB |

---

## Pendrive 1: Instalador Automático

### Características

- **Nombre**: `INSTALADOR_LLAVES_FCEA`
- **Tamaño**: 16 GB mínimo
- **Formato**: FAT32 o NTFS
- **Contenido**:
  - Sistema completo
  - Node.js instalador (incluido)
  - Scripts de configuración automática
  - Base de datos inicial
  - Documentación

### Opciones de Instalación

El instalador presenta un menú interactivo con las siguientes opciones:

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   INSTALADOR AUTOMÁTICO - SISTEMA DE LLAVES FCEA          ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║   1. MODO DE OPERACIÓN:                                    ║
║      [ ] Producción (recomendado)                          ║
║      [ ] Desarrollo (para pruebas)                         ║
║                                                            ║
║   2. TIPO DE HARDWARE:                                     ║
║      [ ] Pantallas Táctiles (con teclado virtual)          ║
║      [ ] Monitores Tradicionales (teclado + mouse físico)  ║
║                                                            ║
║   3. CONFIGURACIÓN DE PANTALLAS:                           ║
║      Pantalla 1: Monitor de Vigilancia (Principal)         ║
║      Pantalla 2: Terminal de Usuario 1                     ║
║      Pantalla 3: Terminal de Usuario 2                     ║
║                                                            ║
║   [Iniciar Instalación]  [Cancelar]                        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

### Proceso de Instalación Automática

Una vez seleccionadas las opciones, el instalador ejecuta:

```
PASO 1: Verificación de requisitos del sistema
  ✓ Windows 10/11 detectado
  ✓ Espacio en disco: 50 GB disponibles
  ✓ RAM: 8 GB detectados
  ✓ Pantallas: 3 detectadas

PASO 2: Instalación de Node.js
  ✓ Node.js v18.17.0 instalado
  ✓ npm v9.6.7 instalado

PASO 3: Copia del sistema
  ✓ Archivos copiados a C:\sistema-llaves-fcea\
  ✓ Estructura de carpetas creada

PASO 4: Instalación de dependencias
  ✓ Dependencias de Node.js instaladas (2-5 minutos)
  ✓ PocketBase configurado

PASO 5: Configuración de base de datos
  ✓ Base de datos inicializada
  ✓ Datos de ejemplo cargados
  ✓ Usuarios administrativos creados

PASO 6: Configuración de hardware
  [MODO TÁCTIL]
  ✓ Teclado virtual habilitado en todas las pantallas
  ✓ Gestos táctiles configurados
  
  [MODO TRADICIONAL]
  ✓ Teclados físicos detectados y configurados
  ✓ Mouses configurados

PASO 7: Configuración de pantallas
  ✓ Pantalla 1 → Monitor de Vigilancia (http://localhost:8080/monitor)
  ✓ Pantalla 2 → Terminal Usuario 1 (http://localhost:8080/terminal)
  ✓ Pantalla 3 → Terminal Usuario 2 (http://localhost:8080/terminal)

PASO 8: Configuración de modo kiosk
  ✓ Chrome configurado en modo kiosk
  ✓ Inicio automático configurado
  ✓ Atajos de teclado deshabilitados (solo en producción)

PASO 9: Configuración de mantenimiento automático
  ✓ Tarea programada creada (Domingos 8:00 AM)
  ✓ Respaldos automáticos configurados
  ✓ Verificación de integridad programada

PASO 10: Verificación final
  ✓ Sistema iniciado correctamente
  ✓ Monitor de Vigilancia accesible
  ✓ Terminales de Usuario accesibles
  ✓ Base de datos respondiendo

╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE                   ║
║                                                            ║
║   El sistema está listo para usar en modo PRODUCCIÓN      ║
║                                                            ║
║   Contraseñas por defecto:                                 ║
║   - Administrador: admin123                                ║
║   - Custodio: custodio2026                                 ║
║                                                            ║
║   ⚠️ IMPORTANTE: Cambie estas contraseñas inmediatamente   ║
║                                                            ║
║   Presione cualquier tecla para reiniciar el sistema...    ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

---

## Pendrive 2: Recuperación del Sistema

### Características

- **Nombre**: `RECUPERACION_LLAVES_FCEA`
- **Tamaño**: 8 GB mínimo
- **Formato**: FAT32
- **Contenido**:
  - Sistema completo (código fuente)
  - Último respaldo de base de datos
  - Node.js instalador
  - Script de restauración automática

### Proceso de Recuperación

```
PASO 1: Detección del sistema existente
  ✓ Sistema anterior detectado en C:\sistema-llaves-fcea\
  ✓ Base de datos encontrada

PASO 2: Respaldo de datos actuales
  ✓ Datos respaldados en C:\respaldo_temporal\
  ✓ Fecha: 2026-04-29 19:45:00

PASO 3: Restauración del sistema
  ✓ Archivos del sistema restaurados
  ✓ Dependencias verificadas

PASO 4: Restauración de base de datos
  ✓ Base de datos restaurada desde respaldo
  ✓ Integridad verificada

PASO 5: Verificación final
  ✓ Sistema funcional
  ✓ Datos preservados

╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   ✅ RECUPERACIÓN COMPLETADA EXITOSAMENTE                  ║
║                                                            ║
║   El sistema ha sido restaurado con los datos preservados  ║
║                                                            ║
║   Presione cualquier tecla para iniciar el sistema...      ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

---

## Configuración de Hardware

### Opción A: Pantallas Táctiles (Producción Final)

#### Hardware Necesario:
- 1 Mini PC con Windows 10/11
- 3 Pantallas táctiles (recomendado: 21-24 pulgadas)
- 3 Cables HDMI o DisplayPort
- 1 Pendrive instalador (16 GB)

#### Conexión Física:

```
                    ┌─────────────────┐
                    │    MINI PC      │
                    │  Windows 10/11  │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │  PANTALLA 1  │ │  PANTALLA 2  │ │  PANTALLA 3  │
    │   TÁCTIL     │ │   TÁCTIL     │ │   TÁCTIL     │
    │              │ │              │ │              │
    │   Monitor    │ │  Terminal    │ │  Terminal    │
    │  Vigilancia  │ │  Usuario 1   │ │  Usuario 2   │
    └──────────────┘ └──────────────┘ └──────────────┘
       (Principal)      (Secundaria)     (Terciaria)
```

#### Configuración en Windows:

1. **Conectar las 3 pantallas** al Mini PC
2. **Configurar en Windows**:
   - Clic derecho en escritorio → "Configuración de pantalla"
   - Identificar pantallas (Windows + P)
   - Configurar como "Extender estas pantallas"
   - Organizar físicamente: 1-2-3 de izquierda a derecha

3. **Orden recomendado**:
   ```
   Pantalla 1 (Principal): Monitor de Vigilancia
   Pantalla 2 (Izquierda): Terminal Usuario 1
   Pantalla 3 (Derecha):   Terminal Usuario 2
   ```

#### Características del Modo Táctil:

- ✅ Teclado virtual automático al tocar campos de texto
- ✅ Gestos táctiles habilitados (deslizar, pellizcar)
- ✅ Botones grandes optimizados para dedos
- ✅ Sin necesidad de teclados ni mouses físicos
- ✅ Interfaz limpia sin periféricos

---

### Opción B: Monitores Tradicionales (Etapa de Prueba)

#### Hardware Necesario:
- 1 Mini PC con Windows 10/11
- 3 Monitores estándar (no táctiles)
- 3 Cables HDMI o DisplayPort
- 3 Teclados USB
- 3 Mouses USB
- 1 Hub USB (si el Mini PC no tiene suficientes puertos)
- 1 Pendrive instalador (16 GB)

#### Conexión Física:

```
                    ┌─────────────────┐
                    │    MINI PC      │
                    │  Windows 10/11  │
                    └────┬───────┬────┘
                         │       │
            ┌────────────┤       └─────────────┐
            │            │                     │
            ▼            ▼                     ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │  MONITOR 1   │ │  MONITOR 2   │ │  MONITOR 3   │
    │              │ │              │ │              │
    │   Monitor    │ │  Terminal    │ │  Terminal    │
    │  Vigilancia  │ │  Usuario 1   │ │  Usuario 2   │
    └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
           │                │                │
    ┌──────┴───────┐ ┌──────┴───────┐ ┌──────┴───────┐
    │ Teclado 1    │ │ Teclado 2    │ │ Teclado 3    │
    │ Mouse 1      │ │ Mouse 2      │ │ Mouse 3      │
    └──────────────┘ └──────────────┘ └──────────────┘
```

#### Configuración en Windows:

1. **Conectar los 3 monitores** al Mini PC
2. **Conectar teclados y mouses**:
   - Teclado 1 + Mouse 1 → Para Monitor 1 (Vigilancia)
   - Teclado 2 + Mouse 2 → Para Monitor 2 (Terminal 1)
   - Teclado 3 + Mouse 3 → Para Monitor 3 (Terminal 2)

3. **Configurar pantallas**:
   - Clic derecho en escritorio → "Configuración de pantalla"
   - Extender pantallas en orden 1-2-3

4. **Nota importante**: 
   - Windows comparte teclados/mouses entre todas las pantallas
   - Los usuarios deben usar el teclado/mouse más cercano a su pantalla
   - El cursor se mueve entre pantallas libremente

#### Características del Modo Tradicional:

- ✅ Teclados físicos siempre visibles
- ✅ Mouses para navegación precisa
- ✅ Más económico para etapa de prueba
- ✅ Fácil de conseguir hardware
- ✅ Puede migrar a táctil después sin cambiar software

---

## Proceso de Grabación de Pendrives

### Preparación del Pendrive Instalador

#### Requisitos:
- 1 Pendrive de 16 GB (mínimo)
- Computadora con el sistema funcionando
- Acceso a internet (para descargar Node.js)

#### Pasos:

```bash
# PASO 1: Formatear el pendrive
1. Conectar pendrive
2. Clic derecho → Formatear
3. Sistema de archivos: FAT32 (o NTFS si es mayor a 32GB)
4. Nombre: INSTALADOR_LLAVES_FCEA
5. Formatear

# PASO 2: Ejecutar script de preparación
1. Abrir CMD como Administrador
2. cd C:\sistema-llaves-fcea
3. scripts\preparar_pendrive_instalador.bat
4. Seguir instrucciones en pantalla

# PASO 3: Descargar Node.js
1. Ir a https://nodejs.org/
2. Descargar "Windows Installer (.msi)" - versión LTS
3. Copiar el archivo a: [PENDRIVE]\instaladores\node-setup.msi

# PASO 4: Verificar contenido
El pendrive debe contener:
├── INSTALAR_SISTEMA.bat          ← Ejecutar este archivo
├── sistema\                       ← Sistema completo
│   ├── src\
│   ├── pocketbase\
│   ├── package.json
│   └── ...
├── instaladores\
│   └── node-setup.msi             ← Node.js instalador
├── scripts\
│   ├── instalar_automatico.ps1
│   ├── configurar_pantallas.ps1
│   └── configurar_kiosk.ps1
└── docs\
    └── instrucciones_instalacion.md

# PASO 5: Etiquetar el pendrive
Pegar etiqueta física:
"INSTALADOR SISTEMA LLAVES FCEA
 Versión: 1.0 - Abril 2026
 NO BORRAR - SOLO LECTURA"
```

---

### Preparación del Pendrive de Recuperación

#### Requisitos:
- 1 Pendrive de 8 GB (mínimo)
- Sistema funcionando correctamente

#### Pasos:

```bash
# PASO 1: Formatear el pendrive
1. Conectar pendrive
2. Formatear como FAT32
3. Nombre: RECUPERACION_LLAVES_FCEA

# PASO 2: Ejecutar script de preparación
1. Abrir CMD como Administrador
2. cd C:\sistema-llaves-fcea
3. scripts\preparar_pendrive_recuperacion.bat
4. Esperar a que termine (5-10 minutos)

# PASO 3: Verificar contenido
El pendrive debe contener:
├── RESTAURAR_SISTEMA.bat          ← Ejecutar este archivo
├── sistema\                        ← Sistema completo
├── respaldos_db\
│   └── pb_data_ultimo\             ← Última copia de datos
├── instaladores\
│   └── node-setup.msi
└── docs\
    └── instrucciones_recuperacion.md

# PASO 4: Etiquetar el pendrive
Pegar etiqueta física:
"RECUPERACIÓN SISTEMA LLAVES FCEA
 Actualizado: [FECHA]
 GUARDAR EN LUGAR SEGURO"
```

---

## Guía de Uso

### Uso del Pendrive Instalador

#### Escenario: Primera instalación del sistema

```
PASO 1: Preparar el hardware
  - Conectar Mini PC a corriente
  - Conectar las 3 pantallas (táctiles o monitores)
  - Si es modo tradicional: conectar teclados y mouses
  - Encender el Mini PC
  - Instalar Windows 10/11 si es necesario

PASO 2: Configurar Windows
  - Completar configuración inicial de Windows
  - Configurar las 3 pantallas en "Extender"
  - Verificar que todas las pantallas funcionan

PASO 3: Ejecutar el instalador
  - Conectar el pendrive INSTALADOR
  - Abrir el pendrive en el explorador
  - Doble clic en "INSTALAR_SISTEMA.bat"
  - Seguir el menú interactivo

PASO 4: Seleccionar opciones
  - Modo: Producción (recomendado)
  - Hardware: Táctil o Tradicional
  - Confirmar configuración de pantallas

PASO 5: Esperar instalación
  - Duración: 10-15 minutos
  - NO interrumpir el proceso
  - NO desconectar el pendrive

PASO 6: Verificación
  - El sistema se reiniciará automáticamente
  - Verificar que las 3 pantallas muestran el sistema
  - Probar funcionalidad básica

PASO 7: Configuración post-instalación
  - Cambiar contraseñas por defecto
  - Configurar datos de la institución
  - Realizar pruebas completas
```

---

### Uso del Pendrive de Recuperación

#### Escenario: El sistema falló y necesita restauración

```
PASO 1: Conectar el pendrive
  - Insertar pendrive RECUPERACIÓN en el Mini PC

PASO 2: Cerrar el sistema si está corriendo
  - Cerrar navegadores
  - Finalizar proceso "pocketbase.exe" si existe

PASO 3: Ejecutar restauración
  - Abrir el pendrive
  - Doble clic en "RESTAURAR_SISTEMA.bat"
  - Confirmar que desea restaurar

PASO 4: Esperar restauración
  - Duración: 5-10 minutos
  - El script respaldará datos actuales primero
  - Luego restaurará el sistema

PASO 5: Verificación
  - El sistema se iniciará automáticamente
  - Verificar que todo funciona
  - Revisar que los datos están presentes
```

---

## Mantenimiento de los Pendrives

### Actualización del Pendrive de Recuperación

**Frecuencia**: Mensual (primer domingo de cada mes)

```bash
1. Conectar el pendrive RECUPERACIÓN
2. Abrir CMD como Administrador
3. cd C:\sistema-llaves-fcea
4. scripts\preparar_pendrive_recuperacion.bat
5. Esperar a que termine
6. Actualizar etiqueta con nueva fecha
7. Guardar en lugar seguro
```

### Actualización del Pendrive Instalador

**Frecuencia**: Cuando hay cambios importantes en el sistema

```bash
1. Conectar el pendrive INSTALADOR
2. Abrir CMD como Administrador
3. cd C:\sistema-llaves-fcea
4. scripts\preparar_pendrive_instalador.bat
5. Descargar última versión de Node.js si es necesario
6. Actualizar etiqueta con nueva versión
```

---

## Checklist de Verificación

### ✅ Antes de la Instalación

- [ ] Mini PC con Windows 10/11 instalado
- [ ] 3 Pantallas conectadas y funcionando
- [ ] Si modo tradicional: 3 teclados + 3 mouses conectados
- [ ] Pendrive INSTALADOR preparado y verificado
- [ ] Conexión a internet disponible (opcional pero recomendado)
- [ ] Espacio en disco: mínimo 50 GB libres

### ✅ Durante la Instalación

- [ ] Menú del instalador se muestra correctamente
- [ ] Opciones seleccionadas: Producción/Desarrollo
- [ ] Tipo de hardware seleccionado: Táctil/Tradicional
- [ ] Instalación progresa sin errores
- [ ] No se interrumpe el proceso

### ✅ Después de la Instalación

- [ ] Sistema se inicia automáticamente
- [ ] Monitor de Vigilancia accesible en Pantalla 1
- [ ] Terminal Usuario 1 accesible en Pantalla 2
- [ ] Terminal Usuario 2 accesible en Pantalla 3
- [ ] Teclado virtual funciona (si es modo táctil)
- [ ] Teclados físicos funcionan (si es modo tradicional)
- [ ] Base de datos responde correctamente
- [ ] Contraseñas por defecto cambiadas
- [ ] Pendrive RECUPERACIÓN preparado y guardado

---

## Solución de Problemas

### Problema: El instalador no inicia

```
SOLUCIÓN:
1. Verificar que el pendrive está correctamente conectado
2. Clic derecho en INSTALAR_SISTEMA.bat → "Ejecutar como administrador"
3. Si Windows bloquea: Clic en "Más información" → "Ejecutar de todas formas"
```

### Problema: Node.js no se instala

```
SOLUCIÓN:
1. Verificar que node-setup.msi está en la carpeta instaladores\
2. Instalar Node.js manualmente:
   - Abrir instaladores\node-setup.msi
   - Seguir el asistente de instalación
3. Volver a ejecutar el instalador
```

### Problema: Las pantallas no se detectan correctamente

```
SOLUCIÓN:
1. Ir a Configuración de Windows → Sistema → Pantalla
2. Clic en "Detectar"
3. Organizar las pantallas en el orden correcto (1-2-3)
4. Aplicar cambios
5. Volver a ejecutar el instalador
```

### Problema: El modo táctil no funciona

```
SOLUCIÓN:
1. Verificar que las pantallas son realmente táctiles
2. Ir a Configuración → Dispositivos → Entrada táctil
3. Verificar que el táctil está habilitado
4. Calibrar las pantallas táctiles si es necesario
5. Reiniciar el sistema
```

---

## Contacto y Soporte

Para problemas durante la instalación:
- Consultar este documento
- Revisar logs en: C:\sistema-llaves-fcea\logs\instalacion.log
- Contactar a Personal de Sistemas

---

*Documento preparado para archivo y custodia autoridades de FCEA.*
