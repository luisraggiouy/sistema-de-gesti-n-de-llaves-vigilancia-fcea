@echo off
REM ============================================================
REM  UPGRADE: "Lista de Llaves Colapsable (aparece al buscar)"
REM  Modulo: Terminal A / Terminal B -> pantalla "Buscar Llaves"
REM  APLICAR en las PC: TERMINAL A y TERMINAL B (una por vez)
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
