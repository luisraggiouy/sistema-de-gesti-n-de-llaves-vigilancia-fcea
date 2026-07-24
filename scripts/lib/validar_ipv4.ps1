# ============================================================
#  validar_ipv4.ps1
# ============================================================
#  Helper para el RECUPERADOR (y otros bat) que validan si un
#  string es una direccion IPv4 sintacticamente correcta
#  (4 octetos 0-255 separados por puntos).
#
#  Se creo para EVITAR one-liners PowerShell embebidos en .bat
#  con expresiones regulares dentro de `for /f ... backticks`,
#  que dependen de expansion de variables y de escape de `%`
#  y `^` en cmd.exe.
#
#  Uso:
#    powershell -NoProfile -ExecutionPolicy Bypass -File validar_ipv4.ps1 -Ip "192.168.1.50"
#
#  Salida (stdout, una unica linea):
#    OK   -> es IPv4 valida
#    BAD  -> no es IPv4 valida
#
#  Exit code: siempre 0 (el llamador parsea stdout).
# ============================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Ip
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Ip)) {
    Write-Output 'BAD'
    exit 0
}

# Chequeo de formato: 4 grupos de 1 a 3 digitos separados por punto.
if ($Ip -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
    Write-Output 'BAD'
    exit 0
}

# Chequeo de rango: cada octeto entre 0 y 255.
$partes = $Ip -split '\.'
foreach ($p in $partes) {
    $n = 0
    if (-not [int]::TryParse($p, [ref]$n)) {
        Write-Output 'BAD'
        exit 0
    }
    if ($n -lt 0 -or $n -gt 255) {
        Write-Output 'BAD'
        exit 0
    }
}

Write-Output 'OK'
exit 0
