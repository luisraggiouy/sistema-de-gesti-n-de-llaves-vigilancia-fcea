@echo off
REM ==========================================================================
REM DIAGNOSTICO_DUPLICADOS_USUARIOS (SOLO LECTURA - NO MODIFICA NADA)
REM Sistema de Gestion de Llaves FCEA - 2026-07-31
REM
REM Ejecutar en el MONITOR DE VIGILANCIA (con el sistema/PocketBase encendido).
REM Doble clic aqui. Lanza el .ps1 que consulta la base y reporta duplicados.
REM ==========================================================================
setlocal
set "AQUI=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%AQUI%DIAGNOSTICO_DUPLICADOS_USUARIOS_2026-07-31.ps1"
endlocal
