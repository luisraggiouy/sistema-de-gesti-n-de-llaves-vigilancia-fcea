@echo off
REM Verificar conectividad de red entre las 3 PCs
setlocal

echo === Verificacion de red ===
echo.
echo Ingrese las IPs de las PCs de la red local:
set /p IP_SRV="  IP SERVIDOR / MONITOR (cabina): "
set /p IP_A="  IP TERMINAL-A: "
set /p IP_B="  IP TERMINAL-B: "

echo.
echo --- Ping SERVIDOR (%IP_SRV%) ---
ping -n 3 %IP_SRV%
echo.
echo --- Ping TERMINAL-A (%IP_A%) ---
ping -n 3 %IP_A%
echo.
echo --- Ping TERMINAL-B (%IP_B%) ---
ping -n 3 %IP_B%
echo.
echo --- HTTP a PocketBase del servidor ---
powershell -NoProfile -Command "try { $r = Invoke-WebRequest 'http://%IP_SRV%:8090/api/health' -TimeoutSec 5 -UseBasicParsing; Write-Host ('PocketBase OK - status ' + $r.StatusCode) } catch { Write-Host ('PocketBase NO RESPONDE - ' + $_.Exception.Message) }"

echo.
echo === Fin verificacion ===
endlocal
