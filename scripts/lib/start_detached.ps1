# ============================================================
#  scripts\lib\start_detached.ps1
#  Lanza un comando como proceso COMPLETAMENTE desacoplado
#  del shell padre, usando WMI (Win32_Process.Create).
#
#  Por que WMI y no Start-Process / start /MIN / wscript?
#    - Start-Process y 'start /MIN' crean el hijo en el mismo
#      Job Object / grupo de consola del padre.  Cuando el padre
#      muere (cierre de CMD, cierre de ventana de VS Code Terminal,
#      etc), Windows manda CTRL_CLOSE_EVENT al Job entero y mata
#      tambien al hijo.
#    - WScript.Shell.Run sufre lo mismo cuando se invoca desde
#      ciertas terminales integradas.
#    - Win32_Process.Create lanza el proceso a traves del servicio
#      WMI Provider Host (wmiprvse.exe).  El nuevo proceso queda
#      colgado del servicio WMI, NO del shell.  Sobrevive a TODO:
#      cierres de consola, logout (en muchos escenarios) y, lo mas
#      importante, Job Objects impuestos por terminales como las
#      de VS Code/Cline.
#
#  Uso:
#      powershell -NoProfile -ExecutionPolicy Bypass `
#                 -File scripts\lib\start_detached.ps1 `
#                 -CommandLine 'cmd /c node scripts\lib\serve_dist.cjs 5173 dist'
#
#  Devuelve exitcode 0 si el proceso se creo OK.
# ============================================================

param(
  [Parameter(Mandatory=$true)]
  [string]$CommandLine,

  [string]$WorkingDirectory = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

try {
  $res = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
    CommandLine      = $CommandLine
    CurrentDirectory = $WorkingDirectory
  }
  if ($res.ReturnValue -eq 0) {
    Write-Host "[start_detached] OK -- PID $($res.ProcessId) -- $CommandLine"
    exit 0
  } else {
    Write-Host "[start_detached] FALLO Win32_Process.Create ReturnValue=$($res.ReturnValue)"
    exit 1
  }
} catch {
  Write-Host "[start_detached] EXCEPCION: $($_.Exception.Message)"
  exit 1
}
