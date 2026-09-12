@echo off
REM ============================================================
REM  ROLLBACK del upgrade "Contraste + celular negrita + textos +15%"
REM  Restaura el dist anterior (ultimo backup dist_backup_*)
REM  EJECUTAR en la misma PC donde se aplico (Monitor / Terminal A o B)
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
