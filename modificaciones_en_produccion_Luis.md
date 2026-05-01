# 📋 GUÍA PERSONAL DE LUIS — CÓMO HACER MODIFICACIONES AL SISTEMA DE LLAVES FCEA

### (Usando Cline + OpenRouter + VS Code)

**Autor:** Luis Raggio | **Fecha:** Mayo 2026 | **Uso:** Personal y confidencial

---

## 🔧 CONTEXTO

Estás en FCEA, el sistema de llaves está en producción. Te piden un cambio. Tenés:
- PC de producción con el sistema corriendo en `C:\sistema-llaves-fcea`
- Código fuente en tu computadora de desarrollo
- Pendrive de instalación y recuperación guardados
- Cline + VS Code + OpenRouter funcionando
- Repositorio GitHub sincronizado

---

## PASO 0 — PREPARACIÓN INICIAL (en tu PC de desarrollo)

```cmd
git pull origin main
npm install
npm run dev
```

Sistema en `http://localhost:5173`. Si necesitás base de datos, en otra terminal:

```cmd
cd pocketbase
pocketbase serve
```

---

## PASO 1 — ENTENDER EL CAMBIO

Anotá: ¿qué cambiar? ¿en qué parte (Terminal/Monitor/Dashboard)? ¿quién lo pidió? ¿fecha límite?

Traducilo a frase técnica: "Agregar botón Imprimir en Monitor de Vigilancia".

---

## PASO 2 — CREAR RAMA GIT

```cmd
git checkout -b modificacion-[nombre-corto]
```

Ejemplos: `modificacion-boton-imprimir`, `modificacion-cambiar-color-tarjetas`

---

## PASO 3 — DESARROLLAR CON CLINE

En el chat de Cline en VS Code, escribí en español:

> *"Necesito hacer este cambio en el sistema: [DESCRIBILO]. Analizá el código y decime qué archivos modificar."*

Cline te dice qué archivos tocar y qué cambios hacer. Luego:

> *"Perfecto, hacé los cambios."*

Cline modifica los archivos automáticamente. Vos revisás.

Si da error al compilar:

> *"Me dio este error: [PEGALO]. ¿Cómo lo soluciono?"*

---

## PASO 4 — PROBAR EN LOCAL

```cmd
npm run build
```

Si compila bien, abrí `http://localhost:5173` y probá el cambio. Verificá que lo demás no se rompió.

Si algo no anda: *"Probé el cambio y [PROBLEMA]. ¿Podés revisar?"*

---

## PASO 5 — BACKUP EN PRODUCCIÓN ⚠️ NO SALTAR NUNCA

En la PC de producción, terminal como Administrador:

```cmd
cd C:\sistema-llaves-fcea
xcopy /E /I /Y "pocketbase\pb_data" "C:\backups_llaves\backup_pre_cambio_%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%\"
```

Verificá: `dir C:\backups_llaves\`

---

## PASO 6 — DESPLEGAR A PRODUCCIÓN

### Subir desde tu PC de desarrollo:

```cmd
git add .
git commit -m "Descripción del cambio"
git push origin modificacion-[nombre]
git checkout main
git merge modificacion-[nombre]
git push origin main
```

### Actualizar PC de producción:

```cmd
cd C:\sistema-llaves-fcea
git pull origin main
npm install
npm run build
```

Cerrá PocketBase (Ctrl+C) y reiniciá:

```cmd
cd C:\sistema-llaves-fcea\pocketbase
pocketbase serve
```

Reabrí los navegadores en modo kiosk.

---

## PASO 7 — VERIFICAR Y ROLLBACK

**Checklist:** Monitor ✓ | Terminal 1 ✓ | Terminal 2 ✓ | Cambio nuevo ✓ | F12 sin errores ✓

### Si algo falló — ROLLBACK:

```cmd
cd C:\sistema-llaves-fcea
git log --oneline
git reset --hard [HASH-DEL-COMMIT-ANTERIOR]
npm install
npm run build

cd pocketbase
rmdir /s /q pb_data
xcopy /E /I /Y "C:\backups_llaves\backup_pre_cambio_[FECHA]" pb_data
pocketbase serve
```

---

## PASO 8 — DOCUMENTAR Y ACTUALIZAR PENDRIVE

### Documentar en `docs/historial_cambios.md`:

```markdown
## [FECHA] - [DESCRIPCIÓN]

### Solicitado por: [Nombre]
### Descripción: [Qué se cambió]
### Archivos modificados: [lista]
### Tiempo: [X horas]
```

### Actualizar pendrive de recuperación:

```cmd
cd C:\sistema-llaves-fcea
scripts\preparar_pendrive_recuperacion.bat
```

---

## ⚡ COMANDOS RÁPIDOS

| Acción | Comando |
|--------|---------|
| Iniciar dev | `npm run dev` |
| Build | `npm run build` |
| Instalar | `npm install` |
| Estado git | `git status` |
| Historial git | `git log --oneline` |
| Subir cambios | `git add . && git commit -m "msg" && git push` |
| Bajar cambios | `git pull origin main` |
| Backup BD | `xcopy /E /I /Y pocketbase\pb_data C:\backups_llaves\backup_[fecha]\` |
| Restaurar BD | `xcopy /E /I /Y C:\backups_llaves\backup_[fecha] pocketbase\pb_data\` |
| Iniciar PocketBase | `cd pocketbase && pocketbase serve` |
| Actualizar pendrive recup. | `scripts\preparar_pendrive_recuperacion.bat` |

---

## 📊 RESUMEN VISUAL

```
0. PREPARACIÓN → git pull + npm install + npm run dev
1. ENTENDER   → Anotar qué, dónde, quién, cuándo
2. RAMA GIT   → git checkout -b modificacion-[nombre]
3. CLINE      → Describir en español → Analiza → Modifica → Revisar
4. PROBAR     → npm run build → Navegador → Corregir
5. BACKUP     → xcopy pb_data en PC producción (NO SALTAR)
6. DESPLEGAR  → git push → git pull en prod → npm build → reiniciar PB
7. VERIFICAR  → 3 pantallas + cambio + sin errores
8. DOCUMENTAR → historial + actualizar pendrive recuperación
```

---

## 🔑 CONSEJOS

1. **Siempre backup antes de tocar producción**
2. **Probá en local primero**, nunca directo en producción
3. **Usá ramas git** para poder descartar si algo sale mal
4. **Commiteá seguido** con mensajes claros
5. **Si no sabés, preguntale a Cline** en español
6. **Actualizá el pendrive de recuperación** tras cambios importantes
7. **Documentá todo**, tu yo del futuro lo agradecerá
8. **No tengas miedo**: git vuelve atrás, el backup restaura, Cline ayuda

---

*Guía personal de Luis Raggio. No incluida en el repositorio. Para terceros, consultar `docs/procedimiento_modificaciones_produccion.md`.*