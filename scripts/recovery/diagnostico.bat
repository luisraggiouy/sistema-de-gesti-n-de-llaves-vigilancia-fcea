@echo off
REM Diagnostico basico del sistema FCEA
echo.
echo === DIAGNOSTICO ===
echo.
echo [Sistema operativo]
ver
echo.
echo [Node.js / npm]
where node && node --version 2>nul
where npm  && npm --version  2>nul
echo.
echo [PocketBase]
if exist pocketbase\pocketbase.exe (
  echo OK - pocketbase.exe encontrado
) else (
  echo FALTA - pocketbase.exe no esta en pocketbase\
)
echo.
echo [Config runtime]
if exist public\config.json (
  type public\config.json
) else (
  echo FALTA - public\config.json
)
echo.
echo [Puerto 8090 en uso?]
netstat -ano | findstr ":8090"
echo.
echo [Regla de firewall FCEA-PocketBase-8090?]
netsh advfirewall firewall show rule name="FCEA-PocketBase-8090"
echo.
echo === FIN DIAGNOSTICO ===
