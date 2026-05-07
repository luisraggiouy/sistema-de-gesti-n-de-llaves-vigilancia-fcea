# Modo Kiosk — Instrucciones para el Técnico

## ¿Qué es el modo kiosk?

En modo kiosk, el navegador ocupa toda la pantalla sin barras de herramientas, sin botones de cerrar, sin acceso al escritorio. El usuario solo ve el sistema de llaves. Es el modo de **producción normal** del sistema.

---

## ¿Cómo SALIR del modo kiosk? (para mantenimiento)

### Método 1 — Teclado (más rápido)
1. Presionar **`Alt + F4`** → cierra el navegador kiosk
2. Aparece el escritorio de Windows normalmente
3. Hacer el mantenimiento necesario
4. Cuando termine, ejecutar `C:\sistema-llaves-fcea\iniciar_sistema_kiosk.bat` para volver al modo kiosk

### Método 2 — Combinación de teclas del navegador
1. Presionar **`F11`** → sale del modo pantalla completa (puede no funcionar en kiosk estricto)
2. Si no funciona, usar **`Ctrl + Alt + Supr`** → Administrador de tareas → cerrar Chrome

### Método 3 — Administrador de tareas
1. Presionar **`Ctrl + Alt + Supr`**
2. Clic en **"Administrador de tareas"**
3. Buscar **"Google Chrome"** en la lista
4. Clic derecho → **"Finalizar tarea"**
5. Aparece el escritorio

---

## ¿Cómo REACTIVAR el modo kiosk?

### Opción A — Reiniciar la PC
El modo kiosk está configurado para iniciarse automáticamente al arrancar Windows. Simplemente reiniciar la PC y el sistema arranca solo en modo kiosk.

### Opción B — Sin reiniciar
1. Abrir el Explorador de Windows
2. Ir a `C:\sistema-llaves-fcea\`
3. Doble clic en **`iniciar_sistema_kiosk.bat`**
4. El sistema arranca en modo kiosk

---

## ¿Cómo DESACTIVAR el inicio automático permanentemente?

Solo hacer esto si se quiere dejar la PC en modo normal (desarrollo/mantenimiento prolongado):

1. Presionar **`Windows + R`**
2. Escribir `regedit` y presionar Enter
3. Navegar a: `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`
4. Buscar la entrada **`SistemaLlavesFCEA`**
5. Clic derecho → **Eliminar**
6. Reiniciar la PC — ya no arranca en kiosk automáticamente

Para **reactivar** el inicio automático después:
1. Ir a `C:\sistema-llaves-fcea\`
2. Clic derecho en **`CONFIGURAR_INICIO_DEFINITIVO.bat`** → "Ejecutar como administrador"

---

## ¿Cómo usar el pendrive de RECUPERACIÓN en una PC en modo kiosk?

Cuando la PC está en modo kiosk y algo falla:

1. Salir del kiosk con **`Ctrl + Alt + Supr`** → Administrador de tareas → cerrar Chrome
2. Conectar el pendrive de recuperación (16 GB)
3. Abrir el Explorador de Windows (**`Windows + E`**)
4. Ir al pendrive → carpeta `RECUPERACION_SISTEMA_LLAVES_FCEA\`
5. Clic derecho en **`RESTAURAR_SISTEMA.bat`** → "Ejecutar como administrador"
6. Seguir las instrucciones del wizard
7. Al terminar, la PC vuelve al modo kiosk automáticamente

---

## Resumen rápido para el técnico

| Situación | Solución |
|-----------|----------|
| Salir del kiosk para mantenimiento | `Alt + F4` o `Ctrl + Alt + Supr` |
| Volver al kiosk sin reiniciar | Ejecutar `iniciar_sistema_kiosk.bat` |
| Volver al kiosk reiniciando | Simplemente reiniciar la PC |
| Algo falla, usar pendrive recuperación | `Ctrl + Alt + Supr` → cerrar Chrome → conectar pendrive → ejecutar `RESTAURAR_SISTEMA.bat` |
| Desactivar inicio automático | Eliminar entrada en regedit o ejecutar `CONFIGURAR_INICIO_DEFINITIVO.bat` |

---

## Nota sobre Windows 10/11 y los pendrives

**Los pendrives NO se abren automáticamente** en Windows 10/11 por política de seguridad del sistema operativo (Microsoft deshabilitó el autorun de pendrives desde 2011 para prevenir virus).

**Lo que debe hacer el técnico al enchufar el pendrive:**
1. Enchufar el pendrive
2. Abrir el Explorador de Windows (**`Windows + E`**)
3. Hacer doble clic en el pendrive (aparece con el nombre "Instalador Sistema Llaves FCEA")
4. Clic derecho en **`INSTALAR_SISTEMA.bat`** → **"Ejecutar como administrador"**
5. El wizard hace todo el resto automáticamente

> ⚠️ Esta limitación es de Windows, no del sistema. No hay forma técnica de saltearla sin modificar políticas de grupo del sistema operativo (lo cual requeriría permisos de dominio).
