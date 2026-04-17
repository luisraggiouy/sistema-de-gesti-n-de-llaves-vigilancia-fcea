# Entrega del Código Fuente - Sistema de Gestión de Llaves FCEA

## Ubicación del Código Fuente

### 1. Repositorio Principal en GitHub

**URL del Repositorio:**
```
https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git
```

**Información del Repositorio:**
- **Propietario:** luisraggiouy
- **Nombre:** sistema-de-gesti-n-de-llaves-vigilancia-fcea
- **Visibilidad:** Público
- **Última actualización:** [Fecha actual]

### 2. Estructura del Proyecto

```
sistema-de-gesti-n-de-llaves-vigilancia-fcea/
├── src/                          # Código fuente principal
│   ├── components/              # Componentes React
│   │   ├── dashboard/          # Componentes del dashboard
│   │   ├── monitor/            # Componentes del monitor de vigilancia
│   │   ├── terminal/           # Componentes de terminal de usuario
│   │   └── ui/                 # Componentes de interfaz base
│   ├── contexts/               # Contextos React (estado global)
│   ├── hooks/                  # Hooks personalizados
│   ├── lib/                    # Librerías y configuraciones
│   ├── pages/                  # Páginas principales
│   ├── types/                  # Definiciones de tipos TypeScript
│   ├── utils/                  # Utilidades y helpers
│   └── data/                   # Datos estáticos y configuraciones
├── docs/                       # Documentación
│   ├── configuracion_produccion.md
│   ├── presentacion_autoridades.md
│   └── entrega_codigo_fuente.md
├── pocketbase/                 # Base de datos y backend
│   ├── pocketbase.exe         # Ejecutable de PocketBase
│   ├── pb_data/               # Datos de la base de datos
│   └── pb_migrations/         # Migraciones de base de datos
├── public/                     # Archivos públicos (imágenes, etc.)
├── package.json               # Dependencias del proyecto
├── .env.example              # Ejemplo de configuración
├── README.md                 # Documentación principal
└── vite.config.ts           # Configuración del bundler
```

### 3. Tecnologías Utilizadas

**Frontend:**
- **React 18** - Framework de interfaz de usuario
- **TypeScript** - Lenguaje de programación tipado
- **Vite** - Herramienta de construcción y desarrollo
- **Tailwind CSS** - Framework de estilos
- **Shadcn/ui** - Componentes de interfaz
- **React Router** - Navegación entre páginas
- **Lucide React** - Iconos

**Backend:**
- **PocketBase** - Base de datos y API REST
- **SQLite** - Base de datos embebida

**Herramientas de Desarrollo:**
- **ESLint** - Linter de código
- **TypeScript Compiler** - Compilador de TypeScript
- **PostCSS** - Procesador de CSS

### 4. Cómo Descargar el Código Fuente

#### Opción 1: Clonar con Git (Recomendado)
```bash
# Clonar el repositorio
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git

# Entrar al directorio
cd sistema-de-gesti-n-de-llaves-vigilancia-fcea

# Instalar dependencias
npm install
```

#### Opción 2: Descargar ZIP desde GitHub
1. Ir a: https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea
2. Hacer clic en el botón verde "Code"
3. Seleccionar "Download ZIP"
4. Extraer el archivo ZIP en la ubicación deseada

#### Opción 3: Crear Backup Completo para Entrega
```bash
# Crear un archivo comprimido con todo el código fuente
git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git
cd sistema-de-gesti-n-de-llaves-vigilancia-fcea
tar -czf sistema_llaves_fcea_codigo_fuente_$(date +%Y%m%d).tar.gz .
```

### 5. Documentos para Entregar a las Autoridades

#### Documentos Principales:
1. **`docs/presentacion_autoridades.md`** - Presentación ejecutiva del sistema
2. **`docs/configuracion_produccion.md`** - Manual de configuración y contingencias
3. **`docs/entrega_codigo_fuente.md`** - Este documento
4. **`README.md`** - Documentación técnica del proyecto

#### Archivos de Configuración:
1. **`.env.example`** - Plantilla de configuración
2. **`package.json`** - Lista de dependencias y scripts
3. **`vite.config.ts`** - Configuración del proyecto

### 6. Información Legal y de Propiedad

**Propiedad Intelectual:**
- El código fuente es propiedad de la **Facultad de Ciencias Económicas y de Administración (FCEA)**
- Desarrollado específicamente para la Universidad de la República
- Licencia: [A definir por las autoridades]

**Desarrollador:**
- **Nombre:** Luis Raggio
- **Usuario GitHub:** luisraggiouy
- **Contacto:** 099 600 873 luisraggiouy@gmail.com

**Fecha de Desarrollo:**
- **Inicio:** [Fecha de inicio]
- **Entrega:** [Fecha actual]
- **Versión:** 4.3

### 7. Instrucciones para las Autoridades

#### Para Acceso Inmediato:
1. **Ver el código online:** Ir a https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea
2. **Navegar por archivos:** Usar la interfaz web de GitHub
3. **Ver documentación:** Acceder a la carpeta `docs/`

#### Para Descarga y Archivo:
1. **Descargar ZIP:** Usar el botón "Download ZIP" en GitHub
2. **Clonar repositorio:** Usar `git clone` si tienen Git instalado
3. **Crear backup:** Seguir las instrucciones de la Opción 3 arriba

#### Para Transferencia de Propiedad:
1. **Crear organización FCEA en GitHub** (recomendado)
2. **Transferir repositorio** a la organización
3. **Actualizar permisos** según necesidades institucionales

### 8. Continuidad del Proyecto

#### Mantenimiento Futuro:
- **Código abierto:** Disponible para modificaciones futuras
- **Documentación completa:** Incluye manuales técnicos y de usuario
- **Estructura modular:** Fácil de mantener y extender
- **Tecnologías estándar:** Usando herramientas ampliamente adoptadas

#### Recomendaciones:
1. **Mantener repositorio GitHub** para control de versiones
2. **Realizar backups regulares** del código fuente
3. **Documentar cambios futuros** en el repositorio
4. **Capacitar personal técnico** en las tecnologías utilizadas

### 9. Contacto para Consultas Técnicas

**Para consultas sobre el código fuente:**
- **Repositorio GitHub:** https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea
- **Issues/Problemas:** Usar el sistema de issues de GitHub
- **Desarrollador:** Luis Raggio

### 10. Verificación de Integridad

**Información del Repositorio al momento de entrega:**
- **Último commit:** [Hash del commit]
- **Número de archivos:** [Cantidad de archivos]
- **Tamaño total:** [Tamaño del proyecto]
- **Fecha de última modificación:** [Fecha]

**Verificación:**
```bash
# Verificar integridad del repositorio
git log --oneline -10  # Ver últimos 10 commits
git status            # Verificar estado del repositorio
find . -name "*.ts" -o -name "*.tsx" | wc -l  # Contar archivos TypeScript
```

---

**IMPORTANTE:** Este documento debe acompañar la entrega formal del código fuente a las autoridades de la FCEA. El código fuente completo está disponible en el repositorio de GitHub mencionado y puede ser descargado en cualquier momento.
