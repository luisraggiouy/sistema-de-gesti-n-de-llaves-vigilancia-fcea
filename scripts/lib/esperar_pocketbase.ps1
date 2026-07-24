# ============================================================
#  scripts\lib\esperar_pocketbase.ps1
#  Espera activamente a que PocketBase responda en el puerto 8090
#  antes de abrir el navegador. Evita el clasico "Error al registrar"
#  por lanzar Edge/Chrome cuando el backend todavia no arranco.
#
#  Uso:
#    powershell -File esperar_pocketbase.ps1 -Host 127.0.0.1 -Puerto 8090 -TimeoutSeg 60
# ============================================================

[CmdletBinding()]
param(
  [string]$HostName    = '127.0.0.1',
  [int]   $Puerto      = 8090,
  [int]   $TimeoutSeg  = 60
)

$ErrorActionPreference = 'Continue'

Write-Host "  Esperando a PocketBase en $($HostName):$($Puerto) (max $TimeoutSeg s)..."

$inicio = Get-Date
$listo = $false
$intento = 0

while ($true) {
  $intento++
  $transcurrido = (Get-Date) - $inicio
  if ($transcurrido.TotalSeconds -ge $TimeoutSeg) { break }

  try {
    $req = [System.Net.WebRequest]::Create("http://$($HostName):$($Puerto)/api/health")
    $req.Timeout = 2000
    $req.Method  = 'GET'
    $resp = $req.GetResponse()
    $resp.Close()
    $listo = $true
    break
  } catch {
    # Aun no responde, seguimos esperando.
  }

  Start-Sleep -Milliseconds 700
}

if ($listo) {
  $seg = [math]::Round(((Get-Date) - $inicio).TotalSeconds, 1)
  Write-Host "     [OK] PocketBase responde tras $seg s ($intento intentos)."
  exit 0
} else {
  Write-Host "     [ERROR] PocketBase NO respondio en $TimeoutSeg s."
  Write-Host "             Revise que pocketbase.exe este corriendo."
  exit 1
}
