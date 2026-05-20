# Valida sintaxis de TODOS los .ps1 en el pendrive recuperador
# y escribe el resultado a archivo (no requiere Read-Host).

[CmdletBinding()]
param(
    [string]$Letra = "D"
)

$pendrive = "${Letra}:\RECUPERACION_SISTEMA_LLAVES_FCEA"
$reportFile = Join-Path $PSScriptRoot "..\REPORTE_VALIDACION_PENDRIVE.txt"

if (-not (Test-Path $pendrive)) {
    "ERROR: no existe $pendrive" | Tee-Object -FilePath $reportFile
    exit 1
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("=== Validacion de sintaxis .ps1 en pendrive ===")
$lines.Add("Pendrive: $pendrive")
$lines.Add("Fecha:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("")

$ps1 = Get-ChildItem -Path $pendrive -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue
$lines.Add("Archivos .ps1 encontrados: $($ps1.Count)")
$lines.Add("")

$ok = 0; $fail = 0
$bad = New-Object System.Collections.Generic.List[object]

foreach ($f in $ps1) {
    $errs = $null; $tk = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tk, [ref]$errs) | Out-Null
    $rel = $f.FullName.Replace($pendrive, "").TrimStart('\')
    if ($errs -and $errs.Count -gt 0) {
        $fail++
        $bad.Add([PSCustomObject]@{ Path=$rel; Errors=$errs.Count; FirstLine=$errs[0].Extent.StartLineNumber; FirstMsg=$errs[0].Message })
        $lines.Add(("FAIL  L{0,-4} ({1} errs)  {2}" -f $errs[0].Extent.StartLineNumber, $errs.Count, $rel))
    } else {
        $ok++
        $lines.Add(("OK                       {0}" -f $rel))
    }
}

$lines.Add("")
$lines.Add("=== RESUMEN ===")
$lines.Add("OK:   $ok")
$lines.Add("FAIL: $fail")

if ($fail -gt 0) {
    $lines.Add("")
    $lines.Add("=== DETALLE DE FALLOS ===")
    foreach ($b in $bad) {
        $lines.Add("--- $($b.Path) ---")
        $lines.Add("  L$($b.FirstLine): $($b.FirstMsg)")
    }
}

$lines | Set-Content -Path $reportFile -Encoding UTF8
$lines | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Reporte guardado en: $reportFile"

if ($fail -gt 0) { exit 2 } else { exit 0 }
