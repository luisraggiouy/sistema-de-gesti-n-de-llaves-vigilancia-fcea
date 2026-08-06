# ============================================================
#  splash_arranque.ps1   (Sistema FCEA - Monitor Vigilancia)
#  "Cartel de espera" a pantalla completa, SIEMPRE AL FRENTE, con
#  spinner en MOVIMIENTO + barra + contador de segundos, para que
#  quien mire NO piense que esta colgado y NO reinicie.
#
#  - Consulta sola http://127.0.0.1:8090/api/health cada 1 s.
#  - Cuando PocketBase responde, muestra "Listo" y SE CIERRA sola.
#  - Es ADITIVO y SOLO LECTURA: no toca PocketBase, ni la base, ni
#    la config, ni el orquestador de arranque. Solo mira /api/health.
#  - Nunca queda trabado: tope de seguridad (-MaxSeconds) y tecla ESC
#    para cerrarlo a mano.
# ============================================================
[CmdletBinding()]
param(
  [string]$PbHost    = '127.0.0.1',
  [int]   $PbPort    = 8090,
  [int]   $MaxSeconds = 900    # 15 min de tope de seguridad
)

$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Colores ---
$cBg     = [System.Drawing.Color]::FromArgb(15, 23, 42)     # navy oscuro
$cAccent = [System.Drawing.Color]::FromArgb(56, 189, 248)   # celeste
$cText   = [System.Drawing.Color]::White
$cSub    = [System.Drawing.Color]::FromArgb(148, 163, 184)  # gris
$cOk     = [System.Drawing.Color]::FromArgb(74, 222, 128)   # verde

# --- Formulario a pantalla completa, sin bordes, al frente ---
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.WindowState     = 'Maximized'
$form.TopMost         = $true
$form.BackColor       = $cBg
$form.StartPosition   = 'CenterScreen'
$form.KeyPreview      = $true
$form.ShowInTaskbar   = $false
$form.Cursor          = [System.Windows.Forms.Cursors]::WaitCursor

# --- Titulo ---
$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text      = "Sistema de Gestion de Llaves - FCEA"
$lblTitulo.ForeColor = $cSub
$lblTitulo.Font      = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Regular)
$lblTitulo.AutoSize  = $false
$lblTitulo.TextAlign = 'MiddleCenter'
$lblTitulo.Dock      = 'Top'
$lblTitulo.Height    = 120
$form.Controls.Add($lblTitulo)

# --- Spinner (PictureBox donde dibujamos un arco que gira) ---
$pic = New-Object System.Windows.Forms.PictureBox
$pic.Size     = New-Object System.Drawing.Size(160,160)
$pic.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($pic)

# --- Mensaje grande ---
$lblMsg = New-Object System.Windows.Forms.Label
$lblMsg.Text      = "El sistema se esta iniciando..."
$lblMsg.ForeColor = $cText
$lblMsg.Font      = New-Object System.Drawing.Font("Segoe UI", 34, [System.Drawing.FontStyle]::Bold)
$lblMsg.AutoSize  = $false
$lblMsg.TextAlign = 'MiddleCenter'
$form.Controls.Add($lblMsg)

# --- Submensaje tranquilizador ---
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = "Puede tardar 1 o 2 minutos.  POR FAVOR NO REINICIE, aguarde."
$lblSub.ForeColor = $cSub
$lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Regular)
$lblSub.AutoSize  = $false
$lblSub.TextAlign = 'MiddleCenter'
$form.Controls.Add($lblSub)

# --- Barra de progreso (marquee = movimiento continuo) ---
$bar = New-Object System.Windows.Forms.ProgressBar
$bar.Style        = 'Marquee'
$bar.MarqueeAnimationSpeed = 30
$bar.Height       = 26
$form.Controls.Add($bar)

# --- Contador de segundos ---
$lblSeg = New-Object System.Windows.Forms.Label
$lblSeg.Text      = "Iniciando... 0 s"
$lblSeg.ForeColor = $cAccent
$lblSeg.Font      = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
$lblSeg.AutoSize  = $false
$lblSeg.TextAlign = 'MiddleCenter'
$form.Controls.Add($lblSeg)

# --- Pie con ayuda discreta ---
$lblPie = New-Object System.Windows.Forms.Label
$lblPie.Text      = "(Si fuera necesario, un tecnico puede cerrar esta pantalla con la tecla ESC)"
$lblPie.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
$lblPie.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$lblPie.AutoSize  = $false
$lblPie.TextAlign = 'MiddleCenter'
$lblPie.Dock      = 'Bottom'
$lblPie.Height    = 60
$form.Controls.Add($lblPie)

# --- Reposicionar controles centrados segun tamano de pantalla ---
$reposicionar = {
  $w = $form.ClientSize.Width
  $h = $form.ClientSize.Height
  $cx = [int]($w/2)
  $pic.Location    = New-Object System.Drawing.Point(($cx - 80), [int]($h*0.26))
  $lblMsg.SetBounds(0, [int]($h*0.26)+180, $w, 70)
  $lblSub.SetBounds(0, [int]($h*0.26)+260, $w, 40)
  $bar.SetBounds([int]($w*0.25), [int]($h*0.26)+330, [int]($w*0.5), 26)
  $lblSeg.SetBounds(0, [int]($h*0.26)+370, $w, 30)
}
$form.Add_Shown({ & $reposicionar; $form.Activate() })
$form.Add_Resize({ & $reposicionar })

# --- Estado compartido ---
$script:inicio   = Get-Date
$script:angulo   = 0
$script:listo    = $false
$script:cerrando = $false

# --- Timer de ANIMACION (spinner + contador) cada 80 ms ---
$anim = New-Object System.Windows.Forms.Timer
$anim.Interval = 80
$anim.Add_Tick({
  $script:angulo = ($script:angulo + 24) % 360
  $bmp = New-Object System.Drawing.Bitmap(160,160)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear($cBg)
  if ($script:listo) {
    $penOk = New-Object System.Drawing.Pen($cOk, 12)
    $g.DrawArc($penOk, 15, 15, 130, 130, 0, 360)
    $penOk.Dispose()
  } else {
    $pen = New-Object System.Drawing.Pen($cAccent, 12)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawArc($pen, 15, 15, 130, 130, $script:angulo, 280)
    $pen.Dispose()
  }
  $g.Dispose()
  $old = $pic.Image
  $pic.Image = $bmp
  if ($old) { $old.Dispose() }

  $seg = [int]((Get-Date) - $script:inicio).TotalSeconds
  if (-not $script:listo) {
    $m = [int]($seg/60); $s = $seg % 60
    $lblSeg.Text = ("Iniciando...  {0:00}:{1:00}" -f $m, $s)
  }
  if ($seg -ge $MaxSeconds -and -not $script:cerrando) {
    $script:cerrando = $true
    $form.Close()
  }
})

# --- Timer de SALUD (poll /api/health) cada 1000 ms ---
$salud = New-Object System.Windows.Forms.Timer
$salud.Interval = 1000
$salud.Add_Tick({
  if ($script:listo -or $script:cerrando) { return }
  $ok = $false
  try {
    $client = New-Object System.Net.Sockets.TcpClient
    $iar = $client.BeginConnect($PbHost, $PbPort, $null, $null)
    if ($iar.AsyncWaitHandle.WaitOne(200, $false) -and $client.Connected) { $ok = $true }
    $client.Close()
  } catch { $ok = $false }

  if ($ok) {
    $script:listo = $true
    $lblMsg.Text      = "Listo! El sistema ya esta disponible"
    $lblMsg.ForeColor = $cOk
    $lblSub.Text      = ""
    $lblSeg.ForeColor = $cOk
    $seg = [int]((Get-Date) - $script:inicio).TotalSeconds
    $m = [int]($seg/60); $s = $seg % 60
    $lblSeg.Text = ("Listo en {0:00}:{1:00}" -f $m, $s)
    $bar.Style = 'Continuous'
    $bar.Value = 100
    # Cerrar solo tras un instante para que se vea el "Listo!"
    $cerrar = New-Object System.Windows.Forms.Timer
    $cerrar.Interval = 1600
    $cerrar.Add_Tick({ $cerrar.Stop(); $script:cerrando = $true; $form.Close() })
    $cerrar.Start()
  }
})

# --- ESC para cerrar a mano (nunca atrapa a un tecnico) ---
$form.Add_KeyDown({
  if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
    $script:cerrando = $true
    $form.Close()
  }
})

$form.Add_FormClosing({ $anim.Stop(); $salud.Stop() })

$anim.Start()
$salud.Start()
[void]$form.ShowDialog()
