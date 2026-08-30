' ============================================================
'  run_hidden.vbs  -  Sistema de Gestion de Llaves FCEA
'  Lanza un script PowerShell SIN mostrar ninguna ventana.
'
'  Motivo: las tareas programadas FCEA-Chequeo-Salud y
'  FCEA-Watchdog se ejecutaban con "powershell.exe" en modo
'  interactivo, por lo que aparecia una consola negra ~2 seg
'  cada vez que corrian (molesta en el Monitor de Vigilancia).
'
'  WScript.Shell.Run(cmd, 0, False):
'    - 0     => ventana OCULTA (no hay parpadeo alguno)
'    - False => no espera a que termine (no bloquea)
'
'  Uso (desde la tarea programada):
'    wscript.exe "<...>\scripts\lib\run_hidden.vbs" "<...>\script.ps1"
' ============================================================
Option Explicit

Dim args, scriptPath, sh, cmd
Set args = WScript.Arguments

If args.Count < 1 Then
  WScript.Quit 1
End If

scriptPath = args(0)

Set sh = CreateObject("WScript.Shell")
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & scriptPath & """"
sh.Run cmd, 0, False
