# ============================================================
#  CREAR PENDRIVE DE RESCATE FCEA "CON INSTRUCCIONES" en D:
# ------------------------------------------------------------
#  Deja el pendrive listo para que un jefe (sin conocimientos
#  de informatica) pueda recuperar el sistema:
#    - enchufar el pendrive
#    - click derecho en RECUPERAR SISTEMA.bat -> Ejecutar como admin
#    - contrasena de administrador de Windows
#    - esperar unos minutos
#
#  Contenido que graba en D::
#    RECUPERAR SISTEMA.bat        (launcher principal)
#    INSTALAR SISTEMA.bat         (para desastre total / PC nueva)
#    DESINSTALAR SISTEMA.bat
#    ARRANCAR SISTEMA.bat
#    ACTUALIZAR DATOS (Luis).bat  (refresco semanal en el Monitor)
#    LEEME - EMPEZAR AQUI.txt
#    INSTRUCCIONES\               (docs esquematicos + contrasenas)
#    sistema-llaves-fcea\         (sistema completo - NO TOCAR)
#    node-portable\               (Node.js portable - NO TOCAR)
#
#  Los datos (pb_data) que viajan aca son de EJEMPLO. Los datos
#  REALES se inyectan despues corriendo "ACTUALIZAR DATOS (Luis).bat"
#  en el Monitor Vigilancia.
# ============================================================

$ErrorActionPreference = 'Continue'
$SRC   = 'C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea'
$P     = 'D:'
$NODE  = 'C:\sistema-llaves-fcea\node-portable'
$destSistema = "$P\sistema-llaves-fcea"
$destInstr   = "$P\INSTRUCCIONES"

function Line($t, $c='Gray') { Write-Host $t -ForegroundColor $c }

Write-Host ""
Line "============================================================" Yellow
Line "  CREAR PENDRIVE DE RESCATE FCEA (con instrucciones)  ->  $P" Yellow
Line "============================================================" Yellow

# --- Verificar pendrive ---
$vol = Get-Volume -DriveLetter D -ErrorAction SilentlyContinue
if (-not $vol) { Line "[ERROR] No hay unidad D:" Red; exit 1 }
Line ("Pendrive D:  Label='{0}'  FS={1}  Libre={2:N1} GB" -f $vol.FileSystemLabel, $vol.FileSystem, ($vol.SizeRemaining/1GB)) Cyan

# --- Verificar origen ---
Write-Host ""
Line "[1/8] Verificando origen..." Cyan
$ok1 = Test-Path "$SRC\dist\index.html"
$ok2 = Test-Path "$SRC\node_modules\vite\bin\vite.js"
$ok3 = Test-Path "$SRC\pocketbase\pocketbase.exe"
$ok4 = Test-Path "$SRC\pocketbase\pb_data\data.db"
$ok5 = Test-Path "$NODE\node\node.exe"
Line ("  dist/index.html      : {0}" -f $(if($ok1){'OK'}else{'FALTA'})) $(if($ok1){'Green'}else{'Red'})
Line ("  node_modules/vite    : {0}" -f $(if($ok2){'OK'}else{'FALTA'})) $(if($ok2){'Green'}else{'Red'})
Line ("  pocketbase.exe       : {0}" -f $(if($ok3){'OK'}else{'FALTA'})) $(if($ok3){'Green'}else{'Red'})
Line ("  pb_data/data.db (ej) : {0}" -f $(if($ok4){'OK'}else{'FALTA'})) $(if($ok4){'Green'}else{'Red'})
Line ("  node-portable/node   : {0}" -f $(if($ok5){'OK'}else{'FALTA'})) $(if($ok5){'Green'}else{'Red'})
if (-not ($ok1 -and $ok2 -and $ok3 -and $ok5)) { Line "[ERROR] Faltan piezas criticas en el origen. Abortando." Red; exit 1 }

# --- [2/8] Codigo + scripts + docs + pocketbase (sin node_modules, .git, dist, backups, logs) ---
$t0 = Get-Date
Write-Host ""
Line "[2/8] Copiando codigo + scripts + pocketbase (con pb_data de ejemplo)..." Cyan
$argsA = @($SRC, $destSistema, '/E', '/R:1', '/W:1', '/MT:8', '/NFL', '/NDL', '/NP', '/NJH', '/NJS')
$argsA += '/XD'; $argsA += "$SRC\node_modules"
$argsA += '/XD'; $argsA += "$SRC\.git"
$argsA += '/XD'; $argsA += "$SRC\.github"
$argsA += '/XD'; $argsA += "$SRC\.vscode"
$argsA += '/XD'; $argsA += "$SRC\dist"
$argsA += '/XD'; $argsA += "$SRC\backups"
$argsA += '/XD'; $argsA += "$SRC\logs"
$argsA += '/XD'; $argsA += "$SRC\pocketbase\pb_backups"
& robocopy @argsA | Out-Null
Line ("      robocopy exit=$LASTEXITCODE (0-7 = OK)  t={0:N0}s" -f ((Get-Date)-$t0).TotalSeconds) Gray

# --- [3/8] dist compilado ---
Write-Host ""
Line "[3/8] Copiando dist compilado..." Cyan
& robocopy "$SRC\dist" "$destSistema\dist" /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS | Out-Null
Line ("      robocopy exit=$LASTEXITCODE (0-7 = OK)") Gray

# --- [4/8] node_modules (lo grande, ~5-8 min) ---
Write-Host ""
Line "[4/8] Copiando node_modules (~5-8 min, tenga paciencia)..." Cyan
$tnm = Get-Date
& robocopy "$SRC\node_modules" "$destSistema\node_modules" /E /R:1 /W:1 /MT:16 /NFL /NDL /NP /NJH /NJS /XD ".ignored" | Out-Null
Line ("      robocopy exit=$LASTEXITCODE (0-7 = OK)  t={0:N0}s" -f ((Get-Date)-$tnm).TotalSeconds) Gray

# --- [5/8] node-portable en la RAIZ (obligatorio: el Monitor no tiene Node) ---
Write-Host ""
Line "[5/8] Copiando node-portable a la raiz..." Cyan
$tnp = Get-Date
& robocopy "$NODE" "$P\node-portable" /E /R:1 /W:1 /MT:8 /NFL /NDL /NP /NJH /NJS | Out-Null
Line ("      robocopy exit=$LASTEXITCODE (0-7 = OK)  t={0:N0}s" -f ((Get-Date)-$tnp).TotalSeconds) Gray

# --- [6/8] Launchers + refresco a la raiz ---
Write-Host ""
Line "[6/8] Copiando launchers a la raiz..." Cyan
$launchers = @(
  @{ src="$SRC\scripts\pendrive\RECUPERAR_SISTEMA_launcher.bat";  dst="$P\RECUPERAR SISTEMA.bat" }
  @{ src="$SRC\scripts\pendrive\INSTALAR_SISTEMA_launcher.bat";   dst="$P\INSTALAR SISTEMA.bat" }
  @{ src="$SRC\scripts\pendrive\DESINSTALAR_SISTEMA_launcher.bat"; dst="$P\DESINSTALAR SISTEMA.bat" }
  @{ src="$SRC\ARRANCAR SISTEMA.bat";                             dst="$P\ARRANCAR SISTEMA.bat" }
  @{ src="$SRC\scripts\pendrive\ACTUALIZAR_DATOS_RESCATE.bat";    dst="$P\ACTUALIZAR DATOS (Luis).bat" }
)
foreach ($l in $launchers) {
  if (Test-Path $l.src) {
    Copy-Item $l.src $l.dst -Force -ErrorAction SilentlyContinue
    $tag = if (Test-Path $l.dst) { 'OK' } else { 'FALLO' }
    Line ("  [{0}] {1}" -f $tag, (Split-Path $l.dst -Leaf)) $(if($tag -eq 'OK'){'Green'}else{'Red'})
  } else {
    Line ("  [FALTA-ORIGEN] {0}" -f $l.src) Yellow
  }
}

# --- [7/8] INSTRUCCIONES + LEEME ---
Write-Host ""
Line "[7/8] Generando INSTRUCCIONES\ y LEEME..." Cyan
New-Item -ItemType Directory -Force -Path $destInstr | Out-Null
$hoy = (Get-Date -Format 'yyyy-MM-dd HH:mm')

$leeme = @"
============================================================
   SISTEMA DE LLAVES FCEA  --  PENDRIVE DE RESCATE
   (con instrucciones)         Generado: $hoy
============================================================

  ESTE PENDRIVE SIRVE PARA REPARAR EL SISTEMA SI SE ROMPE.

  QUE HACER SI EL SISTEMA FALLA (resumen de 5 pasos):

    1) Enchufar este pendrive en la PC que fallo
       (Terminal A, Terminal B o Monitor Vigilancia).

    2) Abrir esta unidad (Este equipo -> RESCATE).

    3) Click DERECHO en  ->  RECUPERAR SISTEMA.bat
       y elegir  "Ejecutar como administrador".

    4) Aceptar la ventana azul/amarilla (boton SI) y poner la
       contrasena de Administrador de Windows de esa PC.

    5) Esperar 5 a 10 minutos SIN tocar nada. La PC se reinicia
       sola y el sistema queda funcionando.

  --> Para el paso a paso con mas detalle y las contrasenas,
      abrir la carpeta:   INSTRUCCIONES\

============================================================
  QUE HAY EN ESTE PENDRIVE
============================================================
  RECUPERAR SISTEMA.bat   <- LO QUE USA CASI SIEMPRE (reparar)
  INSTALAR SISTEMA.bat    <- solo si hay que instalar en una PC NUEVA
  DESINSTALAR SISTEMA.bat <- casi nunca se usa
  ARRANCAR SISTEMA.bat    <- si el sistema esta instalado pero no abrio
  ACTUALIZAR DATOS (Luis).bat <- SOLO Luis, para refrescar los datos
  INSTRUCCIONES\          <- guias faciles + contrasenas
  sistema-llaves-fcea\    <- el sistema (NO TOCAR)
  node-portable\          <- programa interno (NO TOCAR)

  IMPORTANTE: NO borrar ni mover las carpetas "sistema-llaves-fcea"
  ni "node-portable". Son las que reparan la PC.
============================================================
"@
Set-Content -Path "$P\LEEME - EMPEZAR AQUI.txt" -Value $leeme -Encoding UTF8 -Force

# ---------- Doc 1: paso a paso ----------
$doc1 = @"
============================================================
  1) SI EL SISTEMA FALLA  --  PASO A PASO
============================================================

  El sistema son 3 computadoras:
     - MONITOR VIGILANCIA  (dentro de la cabina; es el "cerebro")
     - TERMINAL A          (afuera, para pedir llaves)
     - TERMINAL B          (afuera, para pedir llaves)

  Primero mira CUAL PC fallo. Puede fallar una sola, o las tres.

------------------------------------------------------------
  CASO A: fallo UNA Terminal (A o B)
------------------------------------------------------------
   1. Enchufa este pendrive en ESA Terminal.
   2. Abri la unidad del pendrive (Este equipo -> RESCATE).
   3. Click DERECHO en  RECUPERAR SISTEMA.bat
      -> "Ejecutar como administrador".
   4. Boton SI en la ventana de Windows + contrasena de
      Administrador de esa PC.
   5. Si te pregunta que PC es, elegi:
         [2] TERMINAL A     o     [3] TERMINAL B
   6. Si te pide la IP del Monitor, escribi:
         IP del Monitor: ____________________  (ver INSTRUCCIONES doc 2)
   7. Espera 5 a 10 min. La PC se reinicia sola. Listo.

   (Los datos NO se pierden: viven en el Monitor, no en la Terminal.)

------------------------------------------------------------
  CASO B: fallo el MONITOR VIGILANCIA
------------------------------------------------------------
   1. Enchufa este pendrive en el MONITOR.
   2. Doble click en  "ACTUALIZAR DATOS (Luis).bat"  (no pide admin).
   3. NO se corta el servicio: toma una foto interna consistente
      de todos los datos, la baja al pendrive y al final pide ENTER.
   4. Verificar la fecha en  ULTIMO_REFRESCO_DE_DATOS.txt (raiz).
   5. Guardar el pendrive en su lugar de custodia.

   Frecuencia sugerida: 1 vez por semana. Minimo 1 vez por mes.

  B) HACER MAS CLONES (mismos pendrives para otros jefes)
  ------------------------------------------------------------
   Opcion facil (recomendada):
     1. Formatear el pendrive nuevo como exFAT.
     2. Copiar TODO el contenido de este pendrive (RESCATE)
        al pendrive nuevo (todas las carpetas y archivos).
     3. Renombrar la unidad nueva a  RESCATE.
     4. Refrescar sus datos con "ACTUALIZAR DATOS (Luis).bat"
        en el Monitor.

   Opcion desde la laptop de desarrollo:
     - Enchufar el pendrive nuevo como D: y correr:
         _crear_pendrive_rescate_D.ps1
     - Luego llevarlo al Monitor y correr "ACTUALIZAR DATOS (Luis).bat".

  C) RECORDATORIOS
  ------------------------------------------------------------
   - "ACTUALIZAR DATOS" NUNCA pisa config.json (respeta la red
     propia del pendrive/PC). Solo copia la base de datos.
   - Los datos reales solo estan en el Monitor; en las Terminales
     no hay datos.
============================================================
"@
Set-Content -Path "$destInstr\4 - PARA LUIS - REFRESCAR Y CLONAR.txt" -Value $doc4 -Encoding UTF8 -Force

# --- Etiqueta del volumen ---
Write-Host ""
Line "[8/8] Etiquetando volumen como RESCATE..." Cyan
& cmd.exe /c "label $P RESCATE" 2>&1 | Out-Null
$volN = Get-Volume -DriveLetter D -ErrorAction SilentlyContinue
Line ("      Etiqueta actual: {0}" -f $volN.FileSystemLabel) Gray

# --- Verificacion final ---
Write-Host ""
Line "============================================================" Yellow
Line "  VERIFICACION FINAL DEL PENDRIVE $P" Yellow
Line "============================================================" Yellow
$checks = @(
  "$P\sistema-llaves-fcea\dist\index.html"
  "$P\sistema-llaves-fcea\node_modules\vite\bin\vite.js"
  "$P\sistema-llaves-fcea\node_modules\react\package.json"
  "$P\sistema-llaves-fcea\pocketbase\pocketbase.exe"
  "$P\sistema-llaves-fcea\pocketbase\pb_data\data.db"
  "$P\sistema-llaves-fcea\pocketbase\pb_migrations"
  "$P\sistema-llaves-fcea\package.json"
  "$P\sistema-llaves-fcea\public\config.json"
  "$P\sistema-llaves-fcea\scripts\install\INSTALAR.bat"
  "$P\sistema-llaves-fcea\scripts\install\INICIAR.bat"
  "$P\node-portable\node\node.exe"
  "$P\node-portable\node\npm.cmd"
  "$P\RECUPERAR SISTEMA.bat"
  "$P\INSTALAR SISTEMA.bat"
  "$P\DESINSTALAR SISTEMA.bat"
  "$P\ARRANCAR SISTEMA.bat"
  "$P\ACTUALIZAR DATOS (Luis).bat"
  "$P\LEEME - EMPEZAR AQUI.txt"
  "$destInstr\1 - SI EL SISTEMA FALLA (PASO A PASO).txt"
  "$destInstr\2 - CONTRASENAS (CONFIDENCIAL).txt"
  "$destInstr\3 - DONDE VIVEN LOS DATOS Y QUE ESTA AUTOMATIZADO.txt"
  "$destInstr\4 - PARA LUIS - REFRESCAR Y CLONAR.txt"
)
$ok = 0; $fail = 0; $falta = @()
foreach ($c in $checks) {
  if (Test-Path $c) { Line ("  [OK]    $c") Green; $ok++ }
  else { Line ("  [FALTA] $c") Red; $fail++; $falta += $c }
}

Write-Host ""
$sz = (Get-ChildItem "$destSistema" -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$n  = (Get-ChildItem "$destSistema" -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
Line ("Contenido sistema-llaves-fcea: {0} archivos, {1:N0} MB" -f $n, ($sz/1MB)) Cyan
$volPost = Get-Volume -DriveLetter D
Line ("Libre restante en D: {0:N1} GB" -f ($volPost.SizeRemaining/1GB)) Cyan
Line ("Duracion total: {0:N1} min" -f ((Get-Date)-$t0).TotalMinutes) Cyan

Write-Host ""
if ($fail -eq 0) {
  Line "============================================================" Green
  Line "  PENDRIVE DE RESCATE $P LISTO ($ok/$($checks.Count) checks OK)" Green
  Line "  Falta 1 paso: llevarlo al Monitor y correr" Green
  Line "  'ACTUALIZAR DATOS (Luis).bat' para meterle los datos REALES." Green
  Line "============================================================" Green
} else {
  Line "============================================================" Red
  Line "  ATENCION: $fail checks fallaron ($ok/$($checks.Count) OK)" Red
  Line "============================================================" Red
  $falta | ForEach-Object { Line "  - $_" Red }
}


