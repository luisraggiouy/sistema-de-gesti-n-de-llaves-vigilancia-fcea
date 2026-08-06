@echo off
REM ============================================================================
REM  PROBAR_ENTREGA.bat - Herramienta de diagnostico (HERRAMIENTAS_RED)
REM  Averigua por que el Monitor no puede marcar una llave como "entregada".
REM  Ejecutar en la PC del MONITOR VIGILANCIA. Doble clic.
REM ============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PROBAR_ENTREGA.ps1"
