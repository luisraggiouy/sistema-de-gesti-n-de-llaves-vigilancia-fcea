@echo off
title Abrir Sistema de Llaves FCEA
color 0B

echo ===================================
echo  ABRIR SISTEMA DE LLAVES FCEA
echo ===================================
echo.
echo  Abriendo Monitor...
explorer.exe http://localhost:8080/monitor
echo  Monitor abierto.
timeout /t 3 /nobreak >nul
echo  Abriendo Terminal...
explorer.exe http://localhost:8080/terminal
echo  Terminal abierto.
echo.
echo  Si no se abrio el navegador, abra Chrome manualmente
echo  y vaya a: http://localhost:8080/monitor
echo.
echo  Presione cualquier tecla para cerrar...
pause > nul
