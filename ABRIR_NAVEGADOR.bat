@echo off
title Abrir Sistema de Llaves FCEA
color 0B

echo ===================================
echo  ABRIR SISTEMA DE LLAVES FCEA
echo ===================================
echo.
echo  Abriendo Monitor de Vigilancia...
start "" /B "http://localhost:8080/monitor"
echo  Monitor abierto.
echo.
echo  Esperando 3 segundos...
ping -n 4 127.0.0.1 >nul
echo  Abriendo Terminal de Usuarios...
start "" /B "http://localhost:8080/terminal"
echo  Terminal abierto.
echo.
echo  Si no se abrio alguna ventana, abra Chrome manualmente:
echo    Monitor:  http://localhost:8080/monitor
echo    Terminal: http://localhost:8080/terminal
echo.
echo  Presione cualquier tecla para cerrar...
pause > nul
