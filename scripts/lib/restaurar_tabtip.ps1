# ============================================================
# Sistema FCEA - Restaurar teclado tactil de Windows (TabTip)
# ============================================================
# Revierte lo que hizo desactivar_tabtip.ps1 de la v5.0.
# Vuelve a habilitar el teclado tactil de Windows (TabTip.exe)
# porque las Terminales lo necesitan para escribir en inputs.
#
# Idempotente: se puede correr varias veces sin efecto negativo.
# ============================================================

#Requires -Version 5.1

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "  Restaurando teclado tactil de Windows..."

# --- 1) Habilitar auto-invocacion en modo escritorio ---
try {
  $regTabletTip = "HKCU:\SOFTWARE\Microsoft\TabletTip\1.7"
  if (-not (Test-Path $regTabletTip)) {
    New-Item -Path $regTabletTip -Force | Out-Null
  }
  Set-ItemProperty -Path $regTabletTip -Name "EnableAutoInvokeInDesktopMode" -Value 1 -Type DWord -Force
  Set-ItemProperty -Path $regTabletTip -Name "EnableDesktopModeAutoInvoke"   -Value 1 -Type DWord -Force
  Write-Host "    [OK] Auto-invocacion habilitada (aparece al tocar un input)"
} catch {
  Write-Host ("    [WARN] Registro TabletTip: " + $_.Exception.Message)
}

# --- 2) Servicio TabletInputService en Automatico ---
try {
  Set-Service -Name "TabletInputService" -StartupType Automatic -ErrorAction SilentlyContinue
  Start-Service -Name "TabletInputService" -ErrorAction SilentlyContinue
  Write-Host "    [OK] Servicio TabletInputService en Automatico"
} catch {
  Write-Host ("    [WARN] Servicio TabletInputService: " + $_.Exception.Message)
}

# --- 3) Asegurar que el TabTip.exe se pueda invocar (registro CTF) ---
try {
  $regCTF = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell"
  if (-not (Test-Path $regCTF)) { New-Item -Path $regCTF -Force | Out-Null }
  # Windows 10/11: si esta clave es 0 el teclado tactil no aparece automaticamente
  Remove-ItemProperty -Path $regCTF -Name "DisableTouchKeyboardAutoInvokeInDesktop" -ErrorAction SilentlyContinue
  Write-Host "    [OK] Auto-invocacion global permitida"
} catch {
  Write-Host ("    [WARN] Registro ImmersiveShell: " + $_.Exception.Message)
}

Write-Host "  Teclado tactil de Windows restaurado."
Write-Host ""
exit 0
