# ============================================================
# scripts\lib\asegurar_permisos_datadb.ps1
# ------------------------------------------------------------
# FIX RAIZ readonly (2026-08-02):
#   PocketBase corre como el usuario ESTANDAR 'vigilancia'. Si data.db
#   queda con permiso solo-lectura para 'Usuarios' (RX), SQLite abre la
#   base en modo SOLO LECTURA y TODA escritura falla:
#     - "Failed to write log" / "Logs delete failed"
#     - "Failed to update/create record (400)" al crear solicitudes.
#   Esta funcion GARANTIZA escritura otorgando 'Modify' a BUILTIN\Usuarios
#   (SID S-1-5-32-545, independiente del idioma) sobre TODO pb_data.
#
# Debe llamarse ELEVADO (admin) desde Instalar / Recuperar / Actualizar
# semilla, DESPUES de crear/copiar pb_data.
# ============================================================
param(
  [string]$PbData = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
)
$ErrorActionPreference = "Continue"

if (-not (Test-Path $PbData)) {
  New-Item -ItemType Directory -Force -Path $PbData | Out-Null
}

Write-Host "[..] Asegurando permisos de ESCRITURA sobre $PbData ..."

# Quitar atributo read-only de las bases (por si vino de un pendrive de solo lectura)
cmd /c "attrib -r `"$PbData\*.db`" 2>nul"
cmd /c "attrib -r `"$PbData\*.db-wal`" 2>nul"
cmd /c "attrib -r `"$PbData\*.db-shm`" 2>nul"

# Otorgar Modify a BUILTIN\Usuarios (S-1-5-32-545) recursivo.
$out = cmd /c "icacls `"$PbData`" /grant `"*S-1-5-32-545:(OI)(CI)M`" /T /C 2>&1"
Write-Host $out

if ($out -match "correctamente" -or $out -match "successfully") {
  Write-Host "[OK] data.db y pb_data quedaron ESCRIBIBLES para Usuarios."
} else {
  Write-Host "[AVISO] icacls no confirmo exito. Revisar salida de arriba."
}
