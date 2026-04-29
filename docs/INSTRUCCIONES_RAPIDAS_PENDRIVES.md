# 🚀 INSTRUCCIONES RÁPIDAS: Cómo Grabar los Pendrives
## Sistema de Gestión de Llaves — FCEA

---

## 📋 Resumen Ultra Rápido

Necesitas **2 pendrives diferentes**:

| Pendrive | Tamaño | Para qué sirve | Cuándo se usa |
|----------|--------|----------------|---------------|
| **INSTALADOR** | 16 GB | Instalar el sistema por primera vez | Una sola vez |
| **RECUPERACIÓN** | 8 GB | Restaurar si el sistema falla | En emergencias |

---

## 🔧 PENDRIVE 1: INSTALADOR (16 GB)

### Paso 1: Formatear el pendrive
```
1. Conectar pendrive de 16 GB
2. Clic derecho → Formatear
3. Nombre: INSTALADOR_LLAVES_FCEA
4. Sistema de archivos: FAT32 (o NTFS si es >32GB)
5. Formatear
```

### Paso 2: Grabar el contenido
```
1. Abrir CMD como Administrador
2. cd C:\sistema-llaves-fcea
3. scripts\preparar_pendrive_instalador.bat
4. Seguir instrucciones
5. Esperar 5-10 minutos
```

### Paso 3: Descargar Node.js
```
1. Ir a: https://nodejs.org/
2. Descargar "Windows Installer (.msi)" - LTS
3. Guardar en: [PENDRIVE]\instaladores\node-setup.msi
```

### Paso 4: Etiquetar
```
Pegar etiqueta física:
┌─────────────────────────────────┐
│ INSTALADOR SISTEMA LLAVES FCEA  │
│ Versión 1.0 - Abril 2026        │
│ NO BORRAR - SOLO LECTURA        │
└─────────────────────────────────┘
```

### ✅ Verificar que contiene:
```
INSTALADOR_LLAVES_FCEA\
├── INSTALAR_SISTEMA.bat          ← Archivo principal
├── sistema\                       ← Todo el código
├── scripts\                       ← Scripts de instalación
├── instaladores\
│   └── node-setup.msi             ← Node.js
└── docs\                          ← Documentación
```

---

## 💾 PENDRIVE 2: RECUPERACIÓN (8 GB)

### Paso 1: Formatear el pendrive
```
1. Conectar pendrive de 8 GB
2. Clic derecho → Formatear
3. Nombre: RECUPERACION_LLAVES_FCEA
4. Sistema de archivos: FAT32
5. Formatear
```

### Paso 2: Grabar el contenido
```
1. Abrir CMD como Administrador
2. cd C:\sistema-llaves-fcea
3. scripts\preparar_pendrive_recuperacion.bat
4. Seguir instrucciones
5. Esperar 5-10 minutos
```

### Paso 3: Copiar Node.js
```
Copiar el mismo node-setup.msi del pendrive instalador a:
[PENDRIVE]\instaladores\node-setup.msi
```

### Paso 4: Etiquetar
```
Pegar etiqueta física:
┌─────────────────────────────────┐
│ RECUPERACIÓN SISTEMA LLAVES     │
│ Actualizado: [FECHA]            │
│ GUARDAR EN LUGAR SEGURO         │
└─────────────────────────────────┘
```

### ✅ Verificar que contiene:
```
RECUPERACION_LLAVES_FCEA\
├── RESTAURAR_SISTEMA.bat          ← Archivo principal
├── sistema\                        ← Todo el código
├── respaldos_db\
│   └── pb_data_ultimo\             ← Datos
├── instaladores\
│   └── node-setup.msi              ← Node.js
└── docs\                           ← Documentación
```

---

## 🖥️ CONFIGURACIÓN DE HARDWARE

### Opción A: Pantallas Táctiles (Producción Final)

#### Hardware necesario:
- ✅ 1 Mini PC con Windows 10/11
- ✅ 3 Pantallas táctiles (21-24")
- ✅ 3 Cables HDMI/DisplayPort
- ✅ 1 Pendrive INSTALADOR

#### Conexión física:
```
Mini PC → Salida 1 → Pantalla Táctil 1 (Monitor Vigilancia)
       → Salida 2 → Pantalla Táctil 2 (Terminal Usuario 1)
       → Salida 3 → Pantalla Táctil 3 (Terminal Usuario 2)
```

#### Configuración en Windows:
```
1. Conectar las 3 pantallas
2. Clic derecho en escritorio → "Configuración de pantalla"
3. Seleccionar "Extender estas pantallas"
4. Organizar: [1] [2] [3] de izquierda a derecha
5. Aplicar
```

#### Usar el instalador:
```
1. Conectar pendrive INSTALADOR
2. Abrir pendrive → Doble clic en INSTALAR_SISTEMA.bat
3. Seleccionar:
   - Modo: [1] Producción
   - Hardware: [1] Pantallas Táctiles
4. Confirmar y esperar 10-15 minutos
5. ¡Listo! El sistema arranca automáticamente
```

---

### Opción B: Monitores Tradicionales (Etapa de Prueba)

#### Hardware necesario:
- ✅ 1 Mini PC con Windows 10/11
- ✅ 3 Monitores estándar
- ✅ 3 Cables HDMI/DisplayPort
- ✅ 3 Teclados USB
- ✅ 3 Mouses USB
- ✅ 1 Hub USB (si el Mini PC no tiene suficientes puertos)
- ✅ 1 Pendrive INSTALADOR

#### Conexión física:
```
Mini PC → Salida 1 → Monitor 1 (Monitor Vigilancia)
       → Salida 2 → Monitor 2 (Terminal Usuario 1)
       → Salida 3 → Monitor 3 (Terminal Usuario 2)
       
       → USB 1 → Teclado 1 + Mouse 1
       → USB 2 → Teclado 2 + Mouse 2
       → USB 3 → Teclado 3 + Mouse 3
```

#### Configuración en Windows:
```
1. Conectar los 3 monitores
2. Conectar los 3 teclados y 3 mouses
3. Clic derecho en escritorio → "Configuración de pantalla"
4. Seleccionar "Extender estas pantallas"
5. Organizar: [1] [2] [3] de izquierda a derecha
6. Aplicar
```

#### Usar el instalador:
```
1. Conectar pendrive INSTALADOR
2. Abrir pendrive → Doble clic en INSTALAR_SISTEMA.bat
3. Seleccionar:
   - Modo: [1] Producción
   - Hardware: [2] Monitores Tradicionales
4. Confirmar y esperar 10-15 minutos
5. ¡Listo! El sistema arranca automáticamente
```

#### Nota sobre teclados/mouses:
```
⚠️ Windows comparte todos los teclados y mouses entre las pantallas.
   El cursor se mueve libremente entre las 3 pantallas.
   
   Recomendación:
   - Coloque cada teclado/mouse cerca de su pantalla correspondiente
   - Los usuarios usarán el teclado/mouse más cercano
   - Esto es normal en configuraciones multi-monitor
```

---

## 🔄 Migración de Tradicional a Táctil

Si empiezas con monitores tradicionales y luego quieres migrar a táctiles:

```
1. Apagar el sistema
2. Desconectar monitores, teclados y mouses
3. Conectar las 3 pantallas táctiles
4. Encender el sistema
5. Configurar pantallas en Windows (extender)
6. Ejecutar: C:\sistema-llaves-fcea\scripts\configurar_tactil.bat
7. Reiniciar
8. ¡Listo! Ahora funciona con táctiles
```

**NO necesitas reinstalar todo el sistema**, solo cambiar la configuración de hardware.

---

## 📝 Checklist de Instalación

### Antes de empezar:
- [ ] Mini PC con Windows 10/11 instalado y actualizado
- [ ] 3 Pantallas conectadas (táctiles o monitores)
- [ ] Si tradicional: 3 teclados + 3 mouses conectados
- [ ] Pendrive INSTALADOR preparado
- [ ] Pendrive RECUPERACIÓN preparado
- [ ] Conexión a internet disponible (recomendado)

### Durante la instalación:
- [ ] Ejecutar INSTALAR_SISTEMA.bat como Administrador
- [ ] Seleccionar modo: Producción
- [ ] Seleccionar hardware: Táctil o Tradicional
- [ ] Confirmar configuración
- [ ] NO interrumpir el proceso (10-15 minutos)
- [ ] NO desconectar el pendrive

### Después de la instalación:
- [ ] Sistema arranca automáticamente
- [ ] Pantalla 1 muestra Monitor de Vigilancia
- [ ] Pantalla 2 muestra Terminal de Usuario
- [ ] Pantalla 3 muestra Terminal de Usuario
- [ ] Cambiar contraseñas por defecto
- [ ] Probar funcionalidad básica
- [ ] Guardar pendrive RECUPERACIÓN en lugar seguro

---

## ⚡ Solución Rápida de Problemas

### El instalador no arranca
```
→ Clic derecho en INSTALAR_SISTEMA.bat
→ "Ejecutar como administrador"
```

### Node.js no se instala
```
→ Verificar que node-setup.msi está en instaladores\
→ Instalar manualmente: Doble clic en node-setup.msi
→ Volver a ejecutar el instalador
```

### Las pantallas no se detectan
```
→ Windows + P → "Extender"
→ Configuración → Sistema → Pantalla → "Detectar"
→ Organizar pantallas en orden 1-2-3
```

### El sistema no arranca después de instalar
```
→ Ir a: C:\sistema-llaves-fcea\
→ Doble clic en: iniciar_sistema.bat
→ Esperar 30 segundos
→ Abrir navegador: http://localhost:8080
```

---

## 📞 Contacto

Para problemas durante la instalación:
- Revisar log: C:\Users\[USUARIO]\AppData\Local\Temp\instalacion_llaves_fcea.log
- Consultar: docs\preparacion_pendrives_instalacion.md
- Contactar: Personal de Sistemas

---

*Documento preparado para archivo y custodia autoridades de FCEA.*
