# ============================================================
#  FIX ARRANQUE LENTO (~8 min) DEL MONITOR  -  2026-08-09
# ------------------------------------------------------------
#  CAUSA RAIZ (confirmada por logs con timestamps):
#    iniciar_pocketbase.ps1 (funcion Ensure-Owner) llama a
#    start_detached.ps1 con el parametro -Target, que NO existe.
#    start_detached.ps1 solo acepta -CommandLine (obligatorio) y
#    -WorkingDirectory. Por eso la llamada FALLA (silenciada con
#    2>$null) y run_pocketbase.bat NUNCA se lanza desde el
#    orquestador. Los 3 reintentos agotan ~8 min (45s x varios) y
#    terminan en [ERROR]; recien ahi el fallback de INICIAR.bat
#    arranca PocketBase (en segundos).
#
#  FIX (quirurgico, 1 sola linea): cambiar
#     -File $startDet -Target $runBat
#  por
#     -File $startDet -CommandLine "cmd /c $runBat" -WorkingDirectory $repoRoot
#  (identico patron al que ya usa INICIAR.bat y SI funciona).
#
#  SEGURO: no toca la base, ni el WAL, ni config.json, ni la
#  arquitectura de reintentos. Hace BACKUP antes y valida sintaxis
#  despues; si algo sale mal, restaura solo. Si el fix fallara,
#  degrada al comportamiento de hoy (el fallback de INICIAR.bat
#  sigue intacto).
# ============================================================
[CmdletBinding()]
param(
  [string]$Target = "C:\sistema-llaves-fcea\scripts\lib\iniciar_pocketbase.ps1",
  [string]$OutDir = "$PSScriptRoot"
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$logFile = Join-Path $OutDir "LOG_APLICAR_FIX_$($env:COMPUTERNAME)_$stamp.log"
Start-Transcript -Path $logFile -Force | Out-Null

Write-Host "===== FIX ARRANQUE LENTO ORQUESTADOR (2026-08-09) ====="
Write-Host ("PC        : " + $env:COMPUTERNAME)
Write-Host ("Fecha/hora: " + (Get-Date))
Write-Host ("Objetivo  : " + $Target)
Write-Host ""

if (-not (Test-Path $Target)) {
  Write-Host "[ERROR] No existe $Target. Abortado, sin cambios."
  Stop-Transcript | Out-Null
  exit 1
}

$old = 'powershell -NoProfile -ExecutionPolicy Bypass -File $startDet -Target $runBat 2>$null | Out-Null'
$new = 'powershell -NoProfile -ExecutionPolicy Bypass -File $startDet -CommandLine "cmd /c $runBat" -WorkingDirectory $repoRoot 2>$null | Out-Null'

$content = Get-Content $Target -Raw

if ($content -like "*$new*") {
  Write-Host "[OK] El fix YA estaba aplicado (se encontro la linea corregida). Nada que hacer."
  Stop-Transcript | Out-Null
  exit 0
}

if ($content -notlike "*$old*") {
  Write-Host "[ADVERTENCIA] No encontre la linea ORIGINAL a corregir:"
  Write-Host "   $old"
  Write-Host "   El archivo puede tener otra version. NO toco nada (seguridad)."
  Stop-Transcript | Out-Null
  exit 2
}

# --- Backup ---
$backup = "$Target.bak_$stamp"
Copy-Item $Target $backup -Force
Write-Host "Backup creado: $backup"

# --- Reemplazo literal (no regex) ---
$patched = $content.Replace($old, $new)
Set-Content -Path $Target -Value $patched -Encoding UTF8
Write-Host "Linea reemplazada."

# --- Validar sintaxis del archivo parcheado ---
$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($Target, [ref]$null, [ref]$errs)
if ($errs -and $errs.Count -gt 0) {
  Write-Host "[ERROR] El archivo parcheado tiene errores de sintaxis. RESTAURANDO backup..."
  Copy-Item $backup $Target -Force
  Write-Host "Restaurado desde $backup. Sistema como estaba."
  Stop-Transcript | Out-Null
  exit 3
}

# --- Verificar que quedo la linea nueva y NO la vieja ---
$check = Get-Content $Target -Raw
if (($check -like "*$new*") -and ($check -notlike "*$old*")) {
  Write-Host ""
  Write-Host "[EXITO] Fix aplicado y sintaxis OK."
  Write-Host "  - Antes : -Target `$runBat  (parametro inexistente -> no arrancaba PocketBase)"
  Write-Host "  - Ahora : -CommandLine \"cmd /c `$runBat\" -WorkingDirectory `$repoRoot"
  Write-Host ""
  Write-Host "SIGUIENTE PASO: REINICIAR el Monitor y medir el arranque."
  Write-Host "  (Deberia pasar de ~8 min a segundos.)"
  Write-Host ""
  Write-Host "Rollback si hiciera falta: ejecutar REVERTIR_FIX.bat"
  Write-Host "  o restaurar a mano: copy `"$backup`" `"$Target`""
} else {
  Write-Host "[ERROR] Verificacion final fallida. RESTAURANDO backup..."
  Copy-Item $backup $Target -Force
  Stop-Transcript | Out-Null
  exit 4
}

Stop-Transcript | Out-Null
Write-Host ""
Write-Host ("Log de esta corrida: " + $logFile)
