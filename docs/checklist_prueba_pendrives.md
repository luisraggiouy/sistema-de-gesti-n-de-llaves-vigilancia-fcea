# Checklist de prueba — Pendrives FCEA

Plan de pruebas para validar los tres pendrives generados por
`scripts/pendrive/crear_pendrive.ps1` y el desinstalador
`scripts/install/DESINSTALAR.bat`.

---

## 0. Preparación

- [ ] Tener al menos 1 pendrive de **16 GB** (para Instalador) y 1 de
  **8 GB** (para Recuperación). Si hay un tercero, se usa para Código Fuente.
- [ ] Tener PowerShell 5.1+ (incluido en Windows 10/11).
- [ ] Tener `pocketbase.exe` ya presente en `pocketbase/` del repo.
- [ ] Identificar la letra de unidad de cada pendrive (Explorador de
  archivos → "Este equipo").

---

## 1. Generación del pendrive INSTALADOR

```powershell
cd C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea
.\scripts\pendrive\crear_pendrive.ps1 -Drive D: -Tipo instalador
```

Validaciones tras finalizar:

- [ ] La raíz del pendrive contiene:
  - `INSTALAR.bat`
  - `DESINSTALAR.bat`
  - `autorun.inf`
  - `LEEME.txt`
  - Carpeta `sistema-llaves-fcea\`
- [ ] La carpeta `sistema-llaves-fcea\` **NO** contiene `node_modules`,
  `dist`, `.git`, `pb_data`, `pb_backups`.
- [ ] El tamaño total del pendrive es razonable (≈ 100–250 MB).
- [ ] El `LEEME.txt` se abre correctamente y describe los 3 archivos.

---

## 2. Prueba de INSTALACIÓN en PC limpia

Recomendado: PC distinta a la de desarrollo, o una VM Windows limpia.

- [ ] Conectar el pendrive Instalador.
- [ ] Doble click en `INSTALAR.bat` (botón derecho → Ejecutar como
  Administrador).
- [ ] Elegir **modo [1] Desarrollo** para la primera prueba.
- [ ] Verificar:
  - [ ] Detecta o instala Node.js LTS.
  - [ ] Ejecuta `npm install` sin errores.
  - [ ] Ejecuta `npm run build` sin errores críticos.
  - [ ] Abre el puerto 8090 en el firewall (regla `FCEA-PocketBase-8090`).
  - [ ] Escribe `public/config.json` con `modo=desarrollo`.
- [ ] Iniciar el sistema (`npm run dev` o `npm run preview`).
- [ ] Abrir el navegador en `http://127.0.0.1:5173` (o 4173).
- [ ] Verificar que el botón Monitor/Terminal alterna correctamente.
- [ ] Verificar que PocketBase responde en `http://127.0.0.1:8090/_/`.

---

## 3. Generación y prueba del pendrive de RECUPERACIÓN

```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive E: -Tipo recuperacion `
    -PbDataPath "C:\sistema-llaves-fcea\pocketbase\pb_data"
```

- [ ] La raíz del pendrive contiene:
  - `RECUPERAR.bat`
  - `DESINSTALAR.bat`
  - `autorun.inf`
  - `LEEME.txt`
  - `backup_pb_data\` (con archivos de SQLite + `BACKUP_TIMESTAMP.txt`)
  - `scripts\` (con `diagnostico.bat`, `restaurar_backup.bat`, etc.)

**Prueba de recuperación (simular fallo):**

- [ ] En la PC con el sistema instalado, detener PocketBase manualmente
  (`taskkill /F /IM pocketbase.exe`).
- [ ] Renombrar `pocketbase\pb_data\` a `pb_data.broken\` para simular
  pérdida de datos.
- [ ] Conectar el pendrive de Recuperación.
- [ ] Ejecutar `RECUPERAR.bat` como Administrador.
- [ ] Elegir **[2] Restaurar base de datos desde backup**.
- [ ] Verificar que se restaura `pb_data\` desde el pendrive.
- [ ] Reiniciar el sistema y comprobar que vuelve a funcionar.

---

## 4. Generación y prueba del pendrive de CÓDIGO FUENTE

```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive F: -Tipo codigo-fuente
```

- [ ] La raíz del pendrive contiene:
  - `sistema-llaves-fcea\` (con `.git` incluido)
  - `sistema-llaves-fcea_codigo-fuente.zip`
  - `SHA256.txt` (con hash y commit)
  - `LEEME.txt`
- [ ] `SHA256.txt` indica un hash válido (64 caracteres hex) y el
  commit actual del repositorio.
- [ ] Verificar el hash:
  ```powershell
  Get-FileHash F:\sistema-llaves-fcea_codigo-fuente.zip -Algorithm SHA256
  ```
  Debe coincidir exactamente con el de `SHA256.txt`.

**Prueba de continuidad (levantar el código en otra PC):**

- [ ] Copiar `sistema-llaves-fcea\` a una PC con Node.js instalado.
- [ ] Ejecutar:
  ```cmd
  npm install
  npm run dev
  ```
- [ ] Verificar que arranca el sistema sin errores.

---

## 5. Prueba del DESINSTALADOR

Pre‑requisito: tener el sistema instalado en `C:\sistema-llaves-fcea\`.

- [ ] Conectar cualquiera de los pendrives (Instalador o Recuperación).
- [ ] Doble click en `DESINSTALAR.bat` como Administrador.
- [ ] Escribir `SI` cuando lo pida.
- [ ] Verificar al finalizar:
  - [ ] `pocketbase.exe` ya no se está ejecutando.
  - [ ] La regla de firewall `FCEA-PocketBase-8090` fue eliminada
    (`netsh advfirewall firewall show rule name="FCEA-PocketBase-8090"`
    debe devolver "No se han encontrado reglas").
  - [ ] Las tareas programadas `FCEA-*` fueron eliminadas
    (`schtasks /Query /TN FCEA-Backup-Semanal` debe devolver error).
  - [ ] La carpeta `C:\sistema-llaves-fcea\` fue eliminada.
  - [ ] Existe la carpeta `C:\backup_fcea_<fecha>\` con:
    - `pb_data\`
    - `pb_backups\` (si existía)
    - `config.json`
    - `desinstalacion.log`
- [ ] Abrir `desinstalacion.log` y verificar que registra los 6 pasos.

**Prueba de reinstalación con datos preservados:**

- [ ] Volver a ejecutar `INSTALAR.bat` desde el pendrive Instalador.
- [ ] Antes de iniciar el sistema, copiar el contenido de
  `C:\backup_fcea_<fecha>\pb_data\` a
  `C:\sistema-llaves-fcea\pocketbase\pb_data\`.
- [ ] Iniciar y verificar que los datos vuelven a aparecer en el Monitor.

---

## 6. Prueba opcional de modo PRODUCCIÓN (3 PCs)

Solo si hay 3 PCs disponibles en una LAN.

- [ ] PC 1: instalar con modo [2] y rol **S** (Servidor + Monitor).
- [ ] Anotar la IP del servidor (`ipconfig`).
- [ ] PC 2: instalar con modo [2], rol **A**, indicar IP del servidor.
- [ ] PC 3: instalar con modo [2], rol **B**, indicar IP del servidor.
- [ ] Verificar conectividad: en A y B ejecutar `ping <IP-servidor>`.
- [ ] En A o B abrir `http://<IP-servidor>:8090/_/` y validar que
  PocketBase responde.
- [ ] Realizar una solicitud de llave desde Terminal-A.
- [ ] Verificar que aparece en tiempo real en el Monitor.

---

## 7. Resultados esperados (criterios de éxito)

El esquema de pendrives se considera **aprobado** si:

- ✅ Los 3 pendrives se generan sin errores.
- ✅ La instalación en PC limpia funciona en modo Desarrollo.
- ✅ La recuperación restaura un sistema con `pb_data` perdido.
- ✅ El código fuente se puede levantar en otra PC.
- ✅ El desinstalador preserva los datos y limpia el sistema.
- ✅ La reinstalación + restauración manual de `pb_data` reproduce el
  estado anterior.

---

*Plan de pruebas v1.0. Ejecutar y marcar resultados; archivar este
checklist firmado como evidencia.*
