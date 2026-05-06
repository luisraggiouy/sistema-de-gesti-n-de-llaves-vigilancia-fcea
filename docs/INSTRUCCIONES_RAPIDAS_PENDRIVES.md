# 💾 Instrucciones Rápidas: Preparar los Pendrives
## Sistema de Gestión de Llaves — FCEA · v5.3 · Mayo 2026

---

## Resumen

Se necesitan **2 pendrives**:

| Pendrive | Tamaño mínimo | Para qué sirve | Cuándo se usa |
|----------|---------------|----------------|---------------|
| **INSTALADOR** | 16 GB | Instalar el sistema en un equipo nuevo. Incluye copia del código fuente. | Una sola vez (o reinstalación) |
| **RECUPERACIÓN** | 8 GB | Restaurar datos si el sistema falla | En emergencias |

---

## PENDRIVE 1: INSTALADOR (16 GB)

### Paso 1 — Formatear
```
1. Conectar pendrive de 16 GB
2. Clic derecho → Formatear
3. Nombre: INSTALADOR_LLAVES_FCEA
4. Sistema de archivos: NTFS (recomendado) o FAT32
5. Formatear
```

### Paso 2 — Grabar el contenido
```
1. Abrir CMD como Administrador
2. cd C:\sistema-de-gestion-de-llaves-vigilancia-fcea
3. scripts\preparar_pendrive_instalador.bat
4. Seguir instrucciones en pantalla
5. Esperar 5-10 minutos
```

### Paso 3 — Agregar Node.js
```
1. Ir a: https://nodejs.org/
2. Descargar "Windows Installer (.msi)" — versión LTS
3. Guardar en: [PENDRIVE]\instaladores\node-setup.msi
```

### Paso 4 — Etiquetar
```
┌─────────────────────────────────┐
│ INSTALADOR SISTEMA LLAVES FCEA  │
│ Versión 5.3 - Mayo 2026         │
│ NO BORRAR - SOLO LECTURA        │
└─────────────────────────────────┘
```

### Contenido del pendrive una vez preparado:
```
INSTALADOR_LLAVES_FCEA\
├── INSTALAR_SISTEMA.bat      ← Ejecutar para instalar
├── sistema\                  ← Sistema listo para instalar
├── codigo_fuente\            ← Copia completa del código fuente (sin node_modules)
├── scripts\                  ← Scripts de mantenimiento
├── docs\                     ← Documentación completa
└── instaladores\
    └── node-setup.msi        ← Node.js (agregar manualmente)
```

> 📌 La carpeta `codigo_fuente\` contiene TODO el código fuente del sistema para archivo, auditoría o desarrollo futuro. Para restaurar las dependencias: `npm install`.

---

## PENDRIVE 2: RECUPERACIÓN (8 GB)

### Paso 1 — Formatear
```
1. Conectar pendrive de 8 GB
2. Clic derecho → Formatear
3. Nombre: RECUPERACION_LLAVES_FCEA
4. Sistema de archivos: FAT32
5. Formatear
```

### Paso 2 — Grabar el contenido
```
1. Abrir CMD como Administrador
2. cd C:\sistema-de-gestion-de-llaves-vigilancia-fcea
3. scripts\preparar_pendrive_recuperacion.bat
4. Seguir instrucciones en pantalla
5. Esperar 5-10 minutos
```

### Paso 3 — Copiar Node.js
```
Copiar el mismo node-setup.msi del pendrive instalador a:
[PENDRIVE]\instaladores\node-setup.msi
```

### Paso 4 — Etiquetar
```
┌─────────────────────────────────┐
│ RECUPERACIÓN SISTEMA LLAVES     │
│ Actualizado: [FECHA]            │
│ GUARDAR EN LUGAR SEGURO         │
└─────────────────────────────────┘
```

### Contenido del pendrive una vez preparado:
```
RECUPERACION_LLAVES_FCEA\
├── RESTAURAR_SISTEMA.bat     ← Ejecutar para restaurar
├── sistema\                  ← Código del sistema
├── respaldos_db\
│   └── pb_data_ultimo\       ← Datos de la base de datos
├── instaladores\
│   └── node-setup.msi        ← Node.js
└── docs\                     ← Documentación
```

---

## Configuración de Hardware

### Opción A: Pantallas Táctiles (Producción)

**Hardware necesario:**
- 1 Mini PC con Windows 10/11
- 3 Pantallas táctiles (21–24")
- 3 Cables HDMI/DisplayPort

**Conexión:**
```
Mini PC → Salida 1 → Pantalla Táctil 1 (Monitor Vigilancia)
        → Salida 2 → Pantalla Táctil 2 (Terminal Usuario 1)
        → Salida 3 → Pantalla Táctil 3 (Terminal Usuario 2)
```

**Configuración en Windows:**
```
Clic derecho en escritorio → "Configuración de pantalla"
→ "Extender estas pantallas"
→ Organizar: [1] [2] [3] de izquierda a derecha
→ Aplicar
```

---

### Opción B: Monitores Tradicionales (Prueba/Desarrollo)

**Hardware necesario:**
- 1 Mini PC con Windows 10/11
- 3 Monitores estándar + 3 cables HDMI/DisplayPort
- 3 Teclados USB + 3 Mouses USB (o 1 Hub USB)

**Nota:** Windows comparte todos los teclados y mouses entre las pantallas. El cursor se mueve libremente. Colocar cada teclado/mouse cerca de su pantalla correspondiente.

---

## Checklist de Instalación

### Antes de empezar:
- [ ] Mini PC con Windows 10/11 instalado y actualizado
- [ ] 3 Pantallas conectadas (táctiles o monitores)
- [ ] Pendrive INSTALADOR preparado (con node-setup.msi)
- [ ] Pendrive RECUPERACIÓN preparado
- [ ] Conexión a internet disponible (recomendado)

### Durante la instalación:
- [ ] Ejecutar `INSTALAR_SISTEMA.bat` como Administrador
- [ ] NO interrumpir el proceso (10–15 minutos)
- [ ] NO desconectar el pendrive

### Después de la instalación:
- [ ] Sistema arranca automáticamente al iniciar Windows
- [ ] Pantalla 1 muestra Monitor de Vigilancia
- [ ] Pantalla 2 muestra Terminal de Usuario
- [ ] Pantalla 3 muestra Terminal de Usuario
- [ ] **Cambiar contraseñas por defecto** (ver `docs/credenciales_sistema.md`)
- [ ] Probar funcionalidad básica
- [ ] Guardar pendrive RECUPERACIÓN en lugar seguro

---

## Solución Rápida de Problemas

| Problema | Solución |
|----------|----------|
| El instalador no arranca | Clic derecho → "Ejecutar como administrador" |
| Node.js no se instala | Verificar que `node-setup.msi` está en `instaladores\`. Instalar manualmente. |
| Las pantallas no se detectan | Win+P → "Extender" · Configuración → Pantalla → "Detectar" |
| El sistema no arranca después de instalar | Doble clic en `iniciar_sistema.bat` · Esperar 30 seg · Abrir http://localhost:8080 |
| Error de puerto 8080 ocupado | Ver `docs/SOLUCION_ERROR_PUERTO_8080.md` |
| Error 404 | Ver `docs/SOLUCION_ERROR_404_PUERTO_INCORRECTO.md` |

---

## Credenciales

Ver: **[docs/credenciales_sistema.md](credenciales_sistema.md)**

Contraseñas por defecto (cambiar tras la instalación):
- Monitor Admin: `admin2026`
- Monitor Custodio: `custodio2026`
- PocketBase: ver el documento de credenciales

---

## Contacto Técnico

**Luis Raggio** — luisraggiouy@gmail.com — 099 600 873

---

*Última actualización: 06/05/2026 — v5.3*  
*Documento preparado para archivo y custodia autoridades de FCEA.*
