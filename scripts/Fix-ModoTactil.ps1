# =====================================================================
# Fix-ModoTactil.ps1
# =====================================================================
# Corrige la configuración táctil de Windows en las 2 PCs con monitor
# 3nStar TCM008 (Terminal-B y Monitor Vigilancia) para asegurar que:
#
#   1. Al tocar un campo de texto NO aparezca el teclado virtual táctil
#      del sistema (que solaparía al teclado virtual custom de la app).
#   2. NO se active el "Modo Tablet" de Windows 10 (interfaz Metro).
#   3. Los toques se comporten SIEMPRE como clics de mouse, sin gestos
#      raros de Windows Ink (press-and-hold = click derecho, etc.).
#   4. Windows NO apague el monitor por inactividad cuando la Terminal
#      está en modo kiosk (redundante con el screensaver de la app,
#      pero mejor cinturón + tirantes).
#   5. Chrome / Edge en modo kiosk NO muestren la barra de sugerencias
#      táctiles ni el sombreado azul de "toque".
#
# Uso:
#   1. Abrir PowerShell como Administrador.
#   2. Set-ExecutionPolicy -Scope Process Bypass
#   3. .\Fix-ModoTactil.ps1
#
# Este script es idempotente: se puede correr varias veces sin problema.
# Escribe un backup de los valores anteriores en el mismo directorio.
# =====================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
$backupPath = Join-Path $PSScriptRoot "backup-registro-$(Get-Date -Format 'yyyyMMdd-HHmmss').reg"

function Write-Section {
    param([string]$Titulo)
    Write-Host ""
    Write-Host "=== $Titulo ===" -ForegroundColor Cyan
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = 'DWord'
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    Write-Host "  [OK] $Path\$Name = $Value" -ForegroundColor Green
}

Write-Host "Corrigiendo configuracion tactil de Windows para kiosk FCEA" -ForegroundColor Yellow
Write-Host "Backup del registro: $backupPath"

# Backup de las ramas que vamos a tocar.
$ramasBackup = @(
    "HKCU\SOFTWARE\Microsoft\TabletTip\1.7",
    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell",
    "HKCU\SOFTWARE\Microsoft\Wisp\Touch",
    "HKCU\Control Panel\Desktop"
)
foreach ($rama in $ramasBackup) {
    try {
        reg export $rama $backupPath /y | Out-Null
    } catch { }
}

# ---------------------------------------------------------------------
# 1. Desactivar teclado virtual táctil automático
# ---------------------------------------------------------------------
Write-Section "1/5 Desactivar teclado virtual tactil del sistema"
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\TabletTip\1.7" `
                  -Name "EnableAutoInvokeInDesktopMode" -Value 0
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\TabletTip\1.7" `
                  -Name "EnableDesktopModeAutoInvoke" -Value 0

# Desactivar servicio TabletInputService (opcional pero recomendado).
try {
    Set-Service -Name "TabletInputService" -StartupType Disabled -ErrorAction Stop
    Stop-Service -Name "TabletInputService" -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Servicio TabletInputService deshabilitado" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] No se pudo deshabilitar TabletInputService: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# 2. Desactivar Modo Tablet automatico
# ---------------------------------------------------------------------
Write-Section "2/5 Desactivar Modo Tablet"
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" `
                  -Name "TabletMode" -Value 0
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" `
                  -Name "SignInMode" -Value 1   # 1 = siempre escritorio
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" `
                  -Name "ConvertibleSlateModePromptPreference" -Value 0

# ---------------------------------------------------------------------
# 3. Desactivar gestos Windows Ink (press-and-hold, flicks, etc.)
# ---------------------------------------------------------------------
Write-Section "3/5 Desactivar gestos y feedback tactil"
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Wisp\Touch" `
                  -Name "TouchGate" -Value 1
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Wisp\Touch" `
                  -Name "TouchModeN_1" -Value 0
# Desactivar "Press and hold = right click"
Set-RegistryValue -Path "HKCU:\Control Panel\Cursors" `
                  -Name "ContactVisualization" -Value 0
Set-RegistryValue -Path "HKCU:\Control Panel\Cursors" `
                  -Name "GestureVisualization" -Value 0

# ---------------------------------------------------------------------
# 4. Impedir apagado de monitor y suspension en modo AC
# ---------------------------------------------------------------------
Write-Section "4/5 Impedir apagado de monitor (kiosk)"
try {
    powercfg /change monitor-timeout-ac 0
    powercfg /change standby-timeout-ac 0
    powercfg /change hibernate-timeout-ac 0
    powercfg /change disk-timeout-ac 0
    Write-Host "  [OK] Timeouts de energia (AC) puestos en 0 (nunca)" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] powercfg fallo: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# 5. Opciones de Explorer para kiosk
# ---------------------------------------------------------------------
Write-Section "5/5 Ajustes generales de escritorio"
# Ocultar boton de teclado tactil en la barra de tareas.
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                  -Name "TaskbarTal" -Value 0

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Configuracion tactil aplicada correctamente." -ForegroundColor Green
Write-Host " Reinicie la PC para que TODOS los cambios tengan efecto." -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Backup del registro anterior: $backupPath"
Write-Host " Para revertir: doble-click en el .reg -> aceptar."
Write-Host ""
