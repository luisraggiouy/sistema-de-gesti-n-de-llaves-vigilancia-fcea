' ============================================================
'  SPLASH_ARRANQUE.vbs  (Sistema FCEA - Monitor Vigilancia)
'  Lanza splash_arranque.ps1 SIN ventana de consola (oculto),
'  para que solo se vea el cartel de espera lindo.
'  Se ejecuta desde la carpeta Inicio de Windows al iniciar sesion.
' ============================================================
Option Explicit
Dim sh, fso, carpeta, ps1, cmd
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
carpeta = fso.GetParentFolderName(WScript.ScriptFullName)
ps1     = carpeta & "\splash_arranque.ps1"
cmd = "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """"
' 0 = ventana oculta (la de PowerShell); False = no esperar
sh.Run cmd, 0, False
