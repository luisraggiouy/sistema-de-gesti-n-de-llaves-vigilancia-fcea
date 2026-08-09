# =============================================================
# RESTAURAR_TERMINAL_ORIGINAL.ps1
# Deja la PC como ANTES del blindaje (Opcion B):
#   1) Quita la contrasena de Windows de la cuenta del kiosko
#      (la deja en blanco) para que arranque SOLA como antes.
#   2) Configura autologin en blanco (arranque desatendido).
#   3) Revierte la UAC al comportamiento por defecto (Si/No).
#
# NO toca la app FCEA, ni PocketBase, ni los datos.
#
# Necesita permisos de admin: si la UAC todavia esta blindada,
# te va a pedir la contrasena actual (doors1975) UNA vez.
# Reutilizable en Terminal A, Terminal B y Monitor Vigilancia.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'RESTAURAR TERMINAL (Opcion B) - Sistema FCEA'

$carpetaLog = Join-Path $PSScriptRoot '_RESULTADOS'
if (-not (Test-Path $carpetaLog)) { New-Item -ItemType Directory -Path $carpetaLog -Force | Out-Null }
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$logPath = Join-Path $carpetaLog ("LOG_RESTAURAR_{0}_{1}.log" -f $env:COMPUTERNAME, $stamp)
try { Start-Transcript -Path $logPath -Force | Out-Null } catch {}

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function Header($t) { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t) { Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

Header "RESTAURAR TERMINAL (Opcion B) - $env:COMPUTERNAME"
Write-Host "  Log: $logPath" -ForegroundColor Gray

$usuarioActual = $env:USERNAME
Write-Host ""
Write-Host "  Esto va a:" -ForegroundColor White
Write-Host "   - Quitar la contrasena de Windows de la cuenta '$usuarioActual'"
Write-Host "   - Dejar el arranque automatico (sin pedir contrasena)"
Write-Host "   - Revertir la UAC al modo normal (Si/No)"
Write-Host ""
$c = Read-Host "  Confirmas dejar la PC como antes del blindaje? (S/N, default S)"
if ($c -match '^[nN]') {
    Write-Host "  Cancelado. No se cambio nada." -ForegroundColor Gray
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host ""; Write-Host "Presiona ENTER..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit 0
}

$u = Read-Host "  Usuario del kiosko (ENTER = $usuarioActual)"
if ([string]::IsNullOrWhiteSpace($u)) { $u = $usuarioActual }

# ---- 1) Quitar contrasena (dejar en blanco) ----
Sub "[1] Quitando contrasena de '$u'"
$okPass = $false
try {
    $empty = New-Object System.Security.SecureString
    Set-LocalUser -Name $u -Password $empty -ErrorAction Stop
    $okPass = $true
    Write-Host "  [OK] Contrasena quitada (queda en blanco)." -ForegroundColor Green
} catch {
    Write-Host "  Set-LocalUser fallo, intento con 'net user'..." -ForegroundColor Yellow
    cmd.exe /c "net user `"$u`" `"`"" | Out-Null
    if ($LASTEXITCODE -eq 0) { $okPass = $true; Write-Host "  [OK] Contrasena quitada con net user." -ForegroundColor Green }
    else { Write-Host "  [ERROR] No se pudo quitar la contrasena." -ForegroundColor Red }
}

# ---- 2) Autologin en blanco (arranque desatendido) ----
Sub "[2] Configurando arranque automatico (sin contrasena)"
$reg = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
New-ItemProperty -Path $reg -Name 'AutoAdminLogon'    -Value '1'              -PropertyType String -Force | Out-Null
New-ItemProperty -Path $reg -Name 'DefaultUserName'   -Value $u               -PropertyType String -Force | Out-Null
New-ItemProperty -Path $reg -Name 'DefaultDomainName' -Value $env:COMPUTERNAME -PropertyType String -Force | Out-Null
New-ItemProperty -Path $reg -Name 'DefaultPassword'   -Value ''               -PropertyType String -Force | Out-Null
Write-Host "  [OK] Autologin configurado (usuario '$u', sin contrasena)." -ForegroundColor Green

# ---- 3) Revertir UAC al default ----
Sub "[3] Revirtiendo la UAC al modo normal (Si/No)"
$regUac = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
New-ItemProperty -Path $regUac -Name 'ConsentPromptBehaviorAdmin' -Value 5 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $regUac -Name 'PromptOnSecureDesktop'      -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host "  [OK] UAC de vuelta al comportamiento por defecto." -ForegroundColor Green

# ---- Verificacion ----
Sub "[4] Verificando"
$aa = (Get-ItemProperty -Path $reg -Name AutoAdminLogon -ErrorAction SilentlyContinue).AutoAdminLogon
$cp = (Get-ItemProperty -Path $regUac -Name ConsentPromptBehaviorAdmin -ErrorAction SilentlyContinue).ConsentPromptBehaviorAdmin
Write-Host ("  Contrasena quitada       : {0}" -f ($(if($okPass){'SI'}else{'NO'})))
Write-Host ("  AutoAdminLogon           : {0}" -f $aa)
Write-Host ("  UAC ConsentPromptBehavior: {0}  (5 = default)" -f $cp)

Write-Host ""
Line
if ($okPass -and $aa -eq '1' -and $cp -eq 5) {
    Write-Host "  LISTO - Terminal restaurada al estado original en $env:COMPUTERNAME" -ForegroundColor Green
    Write-Host "  REINICIA la PC: debe arrancar SOLA al kiosko, sin pedir contrasena." -ForegroundColor Cyan
} else {
    Write-Host "  ATENCION - Revisa los valores de arriba." -ForegroundColor Yellow
}
Line
Write-Host ""
Write-Host "  Recordatorio: borra del pendrive el archivo" -ForegroundColor Gray
Write-Host "  INSTRUCTIVO_PONER_CONTRASENA_Y_BLINDAR_2026-08-09.md (tenia la clave)." -ForegroundColor Gray
try { Stop-Transcript | Out-Null } catch {}
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
