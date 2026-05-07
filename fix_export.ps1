$file = 'c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\src\utils\exportUtils.ts'
$content = Get-Content $file -Raw -Encoding UTF8

# Buscar el marcador del bloque duplicado
$marker = '// -- bloque eliminado'
$marker2 = [char]0x2500  # ─
$marker3 = "// $([char]0x2500)$([char]0x2500) bloque eliminado"

$idx = $content.IndexOf($marker)
if ($idx -lt 0) {
    # Buscar con caracteres especiales
    $lines = $content -split "`n"
    $lineIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'bloque eliminado') {
            $lineIdx = $i
            break
        }
    }
    if ($lineIdx -ge 0) {
        $cleanLines = $lines[0..($lineIdx-1)]
        $clean = ($cleanLines -join "`n").TrimEnd()
        [System.IO.File]::WriteAllText($file, $clean, [System.Text.Encoding]::UTF8)
        Write-Host "OK - truncated at line $lineIdx"
    } else {
        Write-Host "MARKER NOT FOUND - searching for _noop"
        $idx2 = $content.IndexOf('const _noop')
        if ($idx2 -ge 0) {
            $clean = $content.Substring(0, $idx2).TrimEnd()
            [System.IO.File]::WriteAllText($file, $clean, [System.Text.Encoding]::UTF8)
            Write-Host "OK - truncated at _noop position $idx2"
        } else {
            Write-Host "NOTHING FOUND"
        }
    }
} else {
    $clean = $content.Substring(0, $idx).TrimEnd()
    [System.IO.File]::WriteAllText($file, $clean, [System.Text.Encoding]::UTF8)
    Write-Host "OK - truncated at position $idx"
}
