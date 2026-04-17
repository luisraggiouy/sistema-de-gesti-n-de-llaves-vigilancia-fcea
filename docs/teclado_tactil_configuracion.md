# Configuración de Teclado Virtual para Pantallas Táctiles

## Requisitos
La solicitud requiere implementar una solución de teclado virtual para las pantallas táctiles que:
1. Se despliegue automáticamente al tocar campos de texto/números
2. Incluya sugerencias de palabras rápidas (similar a teclados Android)
3. Sea intuitivo y adaptado para el contexto del sistema de gestión de llaves

## Solución Propuesta

### 1. Instalación de Teclado Virtual Avanzado

Para resolver este requisito, el instalador automatizado incluirá la configuración e instalación de **TabletInputPanel** (una versión mejorada del teclado estándar de Windows) con las siguientes características:

- **Interfaz moderna** optimizada para pantallas táctiles
- **Predicción de texto** basada en contexto
- **Historial de palabras frecuentes** específico para el sistema
- **Autocorrección** y sugerencias de palabras
- **Personalización** para términos relacionados con gestión de llaves (nombres de salas, términos frecuentes)

![TabletInputPanel](https://ejemplo.com/teclado-virtual.png)

### 2. Implementación en el Instalador

El instalador automatizado incluirá estas fases para la configuración del teclado táctil:

```batch
:: Configuración de teclado virtual
:CONFIGURAR_TECLADO_TACTIL
echo Configurando teclado virtual optimizado...

:: Habilitar TabletInputPanel
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnableTextPrediction" /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnableAutocorrection" /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnableDoubleTapSpace" /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnablePredictionSpaceInsertion" /t REG_DWORD /d 1 /f

:: Configurar diccionario personalizado para términos de gestión de llaves
copy "%~dp0\recursos\diccionario_personalizado.dic" "%APPDATA%\Microsoft\TabletTip\1.7\UserLexicon" /Y

:: Configurar invocación automática del teclado
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnableDesktopModeAutoInvoke" /t REG_DWORD /d 1 /f

echo Teclado virtual configurado correctamente.
```

### 3. Personalización para el Sistema de Gestión de Llaves

El instalador incluirá un diccionario personalizado con términos comunes utilizados en el sistema:

```
// Extracto del diccionario personalizado
salón
oficina
laboratorio
vigilante
llave
solicitud
pendiente
entregada
devuelta
turno
matutino
vespertino
nocturno
tablero
principal
externo
híbrido
```

### 4. Configuración del Navegador Web

Para garantizar que el teclado virtual se active automáticamente al tocar campos de entrada en el navegador Chrome (donde se ejecuta la aplicación), se configurará:

```batch
:: Configurar Chrome para invocar automáticamente el teclado en pantallas táctiles
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome" /v "TouchVirtualKeyboardPolicy" /t REG_DWORD /d 1 /f
```

### 5. Adaptaciones en la Interfaz Web

Se realizarán las siguientes modificaciones en la aplicación web para mejorar la experiencia con el teclado táctil:

1. **Atributos HTML Optimizados:**
```html
<!-- Optimización para entrada numérica -->
<input 
  type="tel" 
  inputmode="numeric" 
  pattern="[0-9]*" 
  autocomplete="off"
  autocorrect="off"
  autocapitalize="off"
  spellcheck="false"
/>

<!-- Optimización para entrada de texto -->
<input 
  type="text"
  inputmode="text"
  autocomplete="on"
  autocorrect="on"
  autocapitalize="words"
/>
```

2. **CSS para facilitar el toque:**
```css
/* Aumentar tamaño de campos táctiles */
input, button, select {
  min-height: 44px;  /* Estándar para elementos táctiles */
  font-size: 16px;   /* Previene zoom en iOS */
}

/* Espacio adecuado entre elementos */
.input-group > * {
  margin: 8px 0;
}
```

### 6. Pruebas Automatizadas

El instalador incluirá una fase de pruebas para verificar el funcionamiento correcto del teclado virtual:

```batch
:: Prueba de teclado virtual
:PROBAR_TECLADO_TACTIL
echo Verificando configuración del teclado táctil...
start /wait powershell -command "Start-Process 'ms-settings:easeofaccess-keyboard' -PassThru | Wait-Process -Timeout 3; exit 0"
```

## Verificación Post-Instalación

Tras la instalación, el script realizará una verificación del funcionamiento del teclado táctil:

1. Abrirá un campo de texto de prueba
2. Verificará que el teclado virtual se active automáticamente
3. Comprobará que las sugerencias de palabras funcionen correctamente

Esta prueba puede ser ejecutada manualmente en cualquier momento con:

```
C:\sistema-llaves\scripts\verificar_teclado_tactil.bat
```

## Ventajas de Esta Solución

1. **No requiere software adicional** - Utiliza capacidades incorporadas en Windows
2. **Autocompleta palabras frecuentes** - Aprende del uso, mejorando con el tiempo
3. **Optimizado para multimonitor** - El teclado aparece en el monitor donde está el campo activo
4. **Diccionario personalizado** - Incluye términos específicos del sistema de gestión
5. **Ahorra tiempo de digitación** - Especialmente útil en campos repetitivos

## Implementación

Esta funcionalidad será implementada como parte del instalador automatizado, sin requerir pasos adicionales por parte del usuario. El sistema quedará completamente configurado para una experiencia táctil óptima al finalizar la instalación.