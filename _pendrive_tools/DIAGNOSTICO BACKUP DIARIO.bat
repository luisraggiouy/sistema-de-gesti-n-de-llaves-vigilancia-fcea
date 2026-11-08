@echo off
REM ============================================================
REM  DIAGNOSTICO DEL BACKUP DIARIO - SOLO LECTURA
REM  Sistema de Gestion de Llaves FCEA
REM
REM  Ejecutar en el MONITOR DE VIGILANCIA (cabina). NO modifica
REM  nada: no toca tareas, backups, PocketBase ni la base.
REM  Deja el resultado en _RESULTADOS\ (al lado, en el pendrive).
REM
REM  Se auto-eleva a Administrador (igual que DIAGNOSTICAR_READONLY)
REM  para poder leer el detalle COMPLETO de la tarea programada.
REM  Aun elevado, sigue siendo SOLO LECTURA.
REM ============================================================
cd /d "%~dp0"
echo.
echo  Ejecutando diagnostico del backup diario (solo lectura)...
echo  (si Windows pide permiso de Administrador, aceptar)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0DIAGNOSTICO_BACKUP_DIARIO.ps1\"'"
echo.
echo  Se abrio una ventana (como Administrador) con el diagnostico.
echo  Al terminar, el resultado quedo en la carpeta _RESULTADOS de este
echo  pendrive (archivo LOG_BACKUP_DIARIO_...). Traelo a la laptop.
echo.
pause


