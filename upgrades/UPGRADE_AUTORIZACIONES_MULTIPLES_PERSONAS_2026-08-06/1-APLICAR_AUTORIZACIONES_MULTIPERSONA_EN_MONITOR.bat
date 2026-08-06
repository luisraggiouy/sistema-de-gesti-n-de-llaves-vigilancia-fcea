@echo off
REM ============================================================
REM  UPGRADE: "Autorizaciones con VARIAS personas"
REM  Modulo: Monitor de Vigilancia -> Agenda / Autorizaciones -> Nueva
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
