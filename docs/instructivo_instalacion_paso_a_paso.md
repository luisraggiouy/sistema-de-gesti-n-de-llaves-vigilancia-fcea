# Instructivo de Instalación Paso a Paso - Sistema de Llaves FCEA

## Guía Ultra-Simplificada (Para Cualquier Persona)

Este documento explica cómo instalar el sistema de forma TAN SIMPLE que hasta un niño podría hacerlo.

---

## OPCIÓN 1: Instalación con Pendrive (MÁS FÁCIL)

### Paso 1: Preparar el Pendrive de Instalación

#### 1.1 - Conseguir un pendrive vacío
- **Tamaño mínimo**: 8 GB
- **Importante**: Se borrará todo lo que tenga el pendrive

#### 1.2 - Copiar los archivos al pendrive
1. Abrir el explorador de archivos (la carpeta amarilla de Windows)
2. Ir a donde está el código del sistema
3. Copiar TODA la carpeta del sistema
4. Pegar en el pendrive
5. Esperar a que termine de copiar (puede tardar 5-10 minutos)

#### 1.3 - Verificar que el pendrive tenga estos archivos
```
📁 Pendrive/
├── 📄 autorun.inf                    ← Debe estar aquí
├── 📁 scripts/
│   ├── 📁 instalador_automatico/
│   │   ├── 📄 INSTALAR_SISTEMA.bat  ← Debe estar aquí
│   │   └── 📄 autorun.inf
│   └── 📄 instalar_automatico.ps1
├── 📁 src/
├── 📁 pocketbase/
└── ... (otros archivos)
```

---

### Paso 2: Instalar en el Mini PC

#### 2.1 - Conectar el pendrive
1. Tomar el pendrive
2. Conectarlo en cualquier puerto USB del Mini PC
3. Esperar 5 segundos

#### 2.2 - Abrir el pendrive
1. Abrir "Este equipo" (Mi PC)
2. Hacer doble clic en el pendrive
3. Buscar el archivo `INSTALAR_SISTEMA.bat`

#### 2.3 - Ejecutar el instalador
1. Hacer **clic derecho** en `INSTALAR_SISTEMA.bat`
2. Seleccionar **"Ejecutar como administrador"**
3. Si aparece una ventana preguntando "¿Desea permitir...?" → Clic en **SÍ**

#### 2.4 - Seguir el asistente (SUPER FÁCIL)

**Pantalla 1: Bienvenida**
```
============================================================================
            INSTALADOR AUTOMATICO - SISTEMA DE LLAVES FCEA
============================================================================

  Este instalador configurara automaticamente TODO el sistema:

   [*] Instalacion de Node.js
   [*] Copia del sistema
   ... (más cosas)

  Duracion estimada: 10-15 minutos

============================================================================
  IMPORTANTE: Este script debe ejecutarse como ADMINISTRADOR
============================================================================

Presione cualquier tecla para continuar...
```
→ **Presionar cualquier tecla** (Enter, Espacio, etc.)

**Pantalla 2: Verificación de requisitos**
```
═══════════════════════════════════════════════════════════
  PASO 1/10: Verificación de requisitos del sistema
═══════════════════════════════════════════════════════════

✓ Windows 10.0 detectado
✓ Espacio en disco: 245.67 GB disponibles
✓ RAM: 8.00 GB detectados
✓ Ejecutando como Administrador
✓ Pantallas detectadas: 3

Presione Enter para continuar
```
→ **Presionar Enter**

**Pantalla 3: Seleccionar modo de operación**
```
═══════════════════════════════════════════════════════════
  1. MODO DE OPERACIÓN
═══════════════════════════════════════════════════════════

  [1] Producción (recomendado)
      - Modo kiosk activado
      - Inicio automático
      - Mantenimiento automático configurado

  [2] Desarrollo (para pruebas)
      - Modo normal del navegador
      - Sin inicio automático
      - Para desarrollo y pruebas

Seleccione una opción (1 o 2):
```
→ **Escribir `1`** y presionar Enter (para producción)
→ **O escribir `2`** y presionar Enter (para desarrollo/pruebas)

**Pantalla 4: Seleccionar tipo de hardware**
```
═══════════════════════════════════════════════════════════
  2. TIPO DE HARDWARE
═══════════════════════════════════════════════════════════

  [1] Pantallas Táctiles
      - Teclado virtual automático
      - Gestos táctiles habilitados
      - Sin teclados ni mouses físicos

  [2] Monitores Tradicionales
      - Teclados físicos (3 unidades)
      - Mouses físicos (3 unidades)
      - Más económico para etapa de prueba

Seleccione una opción (1 o 2):
```
→ **Escribir `1`** y presionar Enter (para pantallas táctiles)
→ **O escribir `2`** y presionar Enter (para monitores con teclado/mouse)

**Pantalla 5: Confirmación**
```
═══════════════════════════════════════════════════════════
  RESUMEN DE CONFIGURACIÓN
═══════════════════════════════════════════════════════════

  Modo de operación: PRODUCCIÓN
  Tipo de hardware:  TACTIL
  Ruta de instalación: C:\sistema-llaves-fcea

¿Confirma la instalación con esta configuración? (S/N):
```
→ **Escribir `S`** y presionar Enter

**Pantallas 6-10: Instalación automática**
```
El instalador hará TODO automáticamente:
- Instalar Node.js
- Copiar archivos
- Instalar dependencias
- Configurar base de datos
- Configurar hardware
- Configurar modo kiosk
- Configurar mantenimiento automático (3 tareas)
- Configurar watchdog anti-caídas
- Verificar que todo funcione

SOLO ESPERAR 10-15 MINUTOS
```

**Pantalla Final: ¡Éxito!**
```
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║     ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE                         ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝

El sistema está listo para usar en modo: PRODUCCIÓN
Tipo de hardware: TACTIL

Ubicación: C:\sistema-llaves-fcea

Contraseñas por defecto:
  - Administrador: admin123
  - Custodio: custodio2026

⚠️  IMPORTANTE: Cambie estas contraseñas inmediatamente

Acceso al sistema:
  - Monitor de Vigilancia: http://localhost:8080/monitor
  - Terminal de Usuario: http://localhost:8080/terminal
  - Dashboard: http://localhost:8080/dashboard

Presione cualquier tecla para salir...
```
→ **Presionar cualquier tecla**

#### 2.5 - ¡LISTO!
El sistema ya está instalado y funcionando. Si seleccionaste "Producción", se iniciará automáticamente cuando enciendas el Mini PC.

---

## OPCIÓN 2: Recuperación con Pendrive (Si algo salió mal)

### Paso 1: Preparar el Pendrive de Recuperación

#### 1.1 - Conseguir un pendrive vacío
- **Tamaño mínimo**: 4 GB
- **Importante**: Se borrará todo lo que tenga el pendrive

#### 1.2 - Copiar los archivos de recuperación
1. Abrir el explorador de archivos
2. Ir a la carpeta `scripts/respaldo_recuperacion/`
3. Copiar TODO lo que hay en esa carpeta
4. Pegar en el pendrive
5. Esperar a que termine de copiar

#### 1.3 - Copiar el último respaldo
1. En el Mini PC, ir a `C:\sistema-llaves-fcea\pocketbase\pb_backups\`
2. Buscar el archivo más reciente (ejemplo: `backup_20260501_080000.zip`)
3. Copiar ese archivo al pendrive
4. Renombrarlo a `ultimo_respaldo.zip`

---

### Paso 2: Recuperar el Sistema

#### 2.1 - Conectar el pendrive
1. Tomar el pendrive de recuperación
2. Conectarlo en cualquier puerto USB del Mini PC
3. Esperar 5 segundos

#### 2.2 - Ejecutar el recuperador
1. Abrir "Este equipo" (Mi PC)
2. Hacer doble clic en el pendrive
3. Buscar el archivo `RECUPERAR_SISTEMA.bat`
4. Hacer **clic derecho** en `RECUPERAR_SISTEMA.bat`
5. Seleccionar **"Ejecutar como administrador"**
6. Si aparece una ventana preguntando "¿Desea permitir...?" → Clic en **SÍ**

#### 2.3 - Seguir el asistente de recuperación
```
============================================================================
          RECUPERADOR AUTOMATICO - SISTEMA DE LLAVES FCEA
============================================================================

  Este recuperador restaurara el sistema desde un respaldo:

   [*] Detener sistema actual
   [*] Crear respaldo de seguridad del estado actual
   [*] Restaurar base de datos desde respaldo
   [*] Restaurar archivos del sistema
   [*] Verificar integridad
   [*] Reiniciar sistema

  Duracion estimada: 5-10 minutos

============================================================================
Presione cualquier tecla para continuar...
```
→ **Presionar cualquier tecla**

El recuperador hará TODO automáticamente. Solo esperar 5-10 minutos.

#### 2.4 - ¡LISTO!
El sistema está recuperado y funcionando nuevamente.

---

## Solución de Problemas Comunes

### Problema 1: "No se puede ejecutar como administrador"
**Solución**:
1. Cerrar todo
2. Buscar el archivo `.bat`
3. Hacer **clic derecho**
4. Seleccionar **"Ejecutar como administrador"**
5. Clic en **SÍ** cuando pregunte

### Problema 2: "El pendrive no se abre automáticamente"
**Solución**:
1. Abrir "Este equipo" manualmente
2. Hacer doble clic en el pendrive
3. Buscar el archivo `INSTALAR_SISTEMA.bat` o `RECUPERAR_SISTEMA.bat`
4. Hacer doble clic (o clic derecho → Ejecutar como administrador)

### Problema 3: "Dice que falta Node.js"
**Solución**:
1. El instalador lo instalará automáticamente
2. Si falla, descargar Node.js de: https://nodejs.org/
3. Instalar Node.js
4. Volver a ejecutar el instalador

### Problema 4: "El sistema no inicia"
**Solución**:
1. Usar el pendrive de recuperación
2. Seguir los pasos de "OPCIÓN 2: Recuperación"
3. Si sigue sin funcionar, volver a instalar desde cero con "OPCIÓN 1"

---

## ✅ Checklist Final

Después de instalar, verificar que:

- [ ] El sistema abre en el navegador
- [ ] Se ven las 3 pantallas (Monitor + 2 Terminales)
- [ ] Se puede solicitar una llave
- [ ] Se puede devolver una llave
- [ ] El Monitor muestra las llaves en uso
- [ ] Las contraseñas por defecto funcionan
- [ ] **IMPORTANTE**: Cambiar las contraseñas por defecto

---

## ¿Necesitas Ayuda?

Si algo no funciona:

1. **Revisar este documento** desde el principio
2. **Revisar la sección "Solución de Problemas Comunes"**
3. **Consultar el log** en: `C:\Users\[TuUsuario]\AppData\Local\Temp\instalacion_llaves_fcea.log`
4. **Contactar a Personal de Sistemas de FCEA**

---

## ¡Felicitaciones!

Si llegaste hasta aquí y todo funciona, ¡lo lograste! El sistema está instalado y listo para usar.

**Recuerda**:
- Cambiar las contraseñas por defecto
- El sistema se inicia automáticamente (si elegiste modo Producción)
- El watchdog protege el sistema 24/7
- Los respaldos se hacen automáticamente todos los domingos

---

**Última actualización**: Mayo 2026
**Versión del documento**: 1.0
