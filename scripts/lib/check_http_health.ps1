# ============================================================
#  check_http_health.ps1
# ============================================================
#  Helper para el RECUPERADOR (y otros bat) que necesitan
#  verificar si una URL HTTP responde con codigo 200.
#
#  Se creo para EVITAR one-liners PowerShell embebidos en .bat
#  con `;` como separador de sentencias, que rompian el parser
#  de cmd.exe al ejecutarse dentro de `for /f ... backticks`.
#
#  Uso:
#    powershell -NoProfile -ExecutionPolicy Bypass -File check_http_health.ps1 -Url "http://1.2.3.4:8090/api/health" [-TimeoutSec 3]
#
#  Salida (por stdout, en una unica linea):
#    OK   -> respondio 200
#    FAIL -> no responde, timeout, otro codigo, error
#
#  Exit code:
#    0 -> siempre 0 (el llamador parsea stdout, no depende de exit code)
# ============================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [int]$TimeoutSec = 3
)

$ErrorActionPreference = 'Stop'

try {
    $r = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
    if ($r.StatusCode -eq 200) {
        Write-Output 'OK'
    } else {
        Write-Output 'FAIL'
    }
} catch {
    Write-Output 'FAIL'
}

exit 0
