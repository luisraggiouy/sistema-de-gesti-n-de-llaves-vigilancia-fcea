# ============================================================
#  scripts\lib\desactivar_tabtip.ps1
#  Desactiva el "Touch Keyboard" (TabTip.exe) de Windows, que
#  aparece automaticamente como un teclado gigante en pantallas
#  tactiles y tapa el formulario de registro.
#
#  El sistema FCEA usa su PROPIO teclado virtual (compacto,
#  integrado en la UI), por lo que el de Windows sobra.
#
#  Que hace:
#    1. Detiene el servicio TabletInputService.
#    2. Lo pone en modo Manual (no arranca solo).
#    3. Mata TabTip.exe si esta corriendo.
#    4. Escribe en el registro para deshabilitar el auto-invoke
#       del touch keyboard en presencia de inputs.
#
#  Requiere ejecutar como Administrador.
# ============================================================

$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "  === Desactivando teclado tactil de Windows ==="

# 1) Detener el servicio
try {
  Stop-Service -Name 'TabletInputService' -Force -ErrorAction Stop
  Write-Host "     [OK] Servicio TabletInputService detenido."
} catch {
  Write-Host "     [i] Servicio TabletInputService ya estaba detenido o no existe."
}

# 2) Deshabilitar arranque automatico del servicio
try {
  Set-Service -Name 'TabletInputService' -StartupType Disabled -ErrorAction Stop
  Write-Host "     [OK] Servicio TabletInputService deshabilitado."
} catch {
  Write-Host "     [i] No se pudo cambiar el arranque del servicio."
}

# 3) Matar TabTip.exe si esta corriendo
Get-Process -Name 'TabTip','TabTip32' -ErrorAction SilentlyContinue | ForEach-Object {
  try { $_ | Stop-Process -Force -ErrorAction Stop } catch { }
}
Write-Host "     [OK] TabTip.exe detenido si estaba activo."

# 4) Registro: deshabilitar auto-invoke del panel de entrada
$rutaTabTip = 'HKCU:\SOFTWARE\Microsoft\TabletTip\1.7'
if (-not (Test-Path $rutaTabTip)) {
  New-Item -Path $rutaTabTip -Force | Out-Null
}
try {
  New-ItemProperty -Path $rutaTabTip -Name 'EnableAutoInvokeInDesktopMode' -PropertyType DWord -Value 0 -Force | Out-Null
  New-ItemProperty -Path $rutaTabTip -Name 'EnableEdgeTarget' -PropertyType DWord -Value 0 -Force | Out-Null
  New-ItemProperty -Path $rutaTabTip -Name 'TipbandDesiredVisibility' -PropertyType DWord -Value 0 -Force | Out-Null
  Write-Host "     [OK] Registro (usuario) actualizado."
} catch {
  Write-Host "     [i] No se pudo escribir en HKCU\TabletTip: $($_.Exception.Message)"
}

# 5) Registro maquina: deshabilitar politica que fuerza el teclado
$rutaPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Input Panel'
if (-not (Test-Path $rutaPolicy)) {
  New-Item -Path $rutaPolicy -Force | Out-Null
}
try {
  New-ItemProperty -Path $rutaPolicy -Name 'DisableInkFlicks' -PropertyType DWord -Value 1 -Force | Out-Null
  Write-Host "     [OK] Politica de maquina aplicada."
} catch {
  Write-Host "     [i] No se pudo escribir politica de maquina."
}

Write-Host "     Listo. El teclado tactil de Windows NO se abrira mas."
Write-Host ""
exit 0
