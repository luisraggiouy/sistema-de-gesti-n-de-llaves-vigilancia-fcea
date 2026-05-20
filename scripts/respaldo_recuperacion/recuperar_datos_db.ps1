# Script de Recuperacion de Datos - Sistema de Gestion de Llaves FCEA
# Este script busca todas las copias de seguridad disponibles y permite restaurar
# los datos de usuarios, vigilantes y llaves a partir de ellas.

param (
    [switch]$ListarRespaldos = $false,
    [string]$RutaRespaldo = "",
    [switch]$RestaurarUltimoRespaldo = $false,
    [switch]$RestaurarTodosPocketbase = $false
)

$ErrorActionPreference = "Stop"
$rutaSistema = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$rutaPocketbase = Join-Path $rutaSistema "pocketbase"
$rutaPocketbaseData = Join-Path $rutaPocketbase "pb_data"
$rutaRespaldos = Join-Path $rutaPocketbase "respaldos"

# Colores para salida
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function MostrarEncabezado {
    Clear-Host
    Write-ColorOutput Green "====================================================================="
    Write-ColorOutput Green "  SISTEMA DE GESTION DE LLAVES FCEA - RECUPERACION DE DATOS v1.0"
    Write-ColorOutput Green "====================================================================="
    Write-Output ""
}

function DetenerServicioPocketbase {
    Write-Output "Verificando si PocketBase esta en ejecucion..."
    $procesos = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue

    if ($procesos) {
        Write-Output "Deteniendo PocketBase..."
        Stop-Process -Name "pocketbase" -Force
        Start-Sleep -Seconds 2
        Write-ColorOutput Green "[OK] PocketBase detenido correctamente."
    } else {
        Write-Output "PocketBase no esta en ejecucion."
    }
}

function IniciarServicioPocketbase {
    Write-Output ""
    Write-Output "Iniciando PocketBase..."
    Start-Process -FilePath (Join-Path $rutaPocketbase "pocketbase.exe") -ArgumentList "serve" -WindowStyle Hidden
    Write-ColorOutput Green "[OK] PocketBase iniciado correctamente."
    Write-Output ""
}

function ListarRespaldosDisponibles {
    Write-Output "Buscando respaldos disponibles..."

    $respaldosAutomaticos = @()
    $respaldosManuales = @()

    # Buscar respaldos automaticos
    if (Test-Path $rutaRespaldos) {
        $respaldosAutomaticos = Get-ChildItem -Path $rutaRespaldos -Directory | Sort-Object LastWriteTime -Descending
    }

    # Buscar respaldos en CD o memoria USB
    $unidadesExternasConRespaldo = Get-PSDrive -PSProvider FileSystem | Where-Object {
        $rutaRespaldoExterna = Join-Path $_.Root "SistemaLlavesFCEA_Respaldo"
        Test-Path $rutaRespaldoExterna
    }

    foreach ($unidad in $unidadesExternasConRespaldo) {
        $rutaRespaldoExterna = Join-Path $unidad.Root "SistemaLlavesFCEA_Respaldo"
        $respaldosExternos = Get-ChildItem -Path $rutaRespaldoExterna -Directory | Sort-Object LastWriteTime -Descending
        $respaldosManuales += $respaldosExternos
    }

    Write-Output ""
    Write-Output "--- RESPALDOS AUTOMATICOS ---"
    if ($respaldosAutomaticos.Count -gt 0) {
        Write-ColorOutput Green "Se encontraron $($respaldosAutomaticos.Count) respaldos automaticos:"
        Write-Output ""
        for ($i = 0; $i -lt $respaldosAutomaticos.Count; $i++) {
            $respaldo = $respaldosAutomaticos[$i]
            $fecha = $respaldo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Write-Output "[$($i+1)] $($respaldo.Name) - $fecha"
        }
    } else {
        Write-ColorOutput Yellow "No se encontraron respaldos automaticos."
    }

    Write-Output ""
    Write-Output "--- RESPALDOS EN UNIDADES EXTERNAS ---"
    if ($respaldosManuales.Count -gt 0) {
        Write-ColorOutput Green "Se encontraron $($respaldosManuales.Count) respaldos externos:"
        Write-Output ""
        $indice = $respaldosAutomaticos.Count + 1
        foreach ($respaldo in $respaldosManuales) {
            $fecha = $respaldo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Write-Output "[$indice] $($respaldo.Name) (en $($respaldo.FullName.Substring(0, 3))) - $fecha"
            $indice++
        }
    } else {
        Write-ColorOutput Yellow "No se encontraron respaldos en unidades externas."
    }

    $todosRespaldos = @($respaldosAutomaticos) + @($respaldosManuales)
    return $todosRespaldos
}

function RestaurarUltimoRespaldo {
    $todosRespaldos = ListarRespaldosDisponibles

    if ($todosRespaldos.Count -eq 0) {
        Write-ColorOutput Red "No se encontraron respaldos disponibles para restaurar."
        return
    }

    $ultimoRespaldo = $todosRespaldos[0]

    Write-Output ""
    Write-Output ""
    Write-Output "Se restaurara el respaldo mas reciente:"
    Write-ColorOutput Yellow "- $($ultimoRespaldo.Name) ($($ultimoRespaldo.LastWriteTime))"

    $confirmacion = Read-Host "Confirma esta operacion? (S/N)"
    if ($confirmacion -ne "S") {
        Write-ColorOutput Yellow "Operacion cancelada."
        return
    }

    RestaurarRespaldo $ultimoRespaldo
}

function RestaurarRespaldoSeleccionado {
    $todosRespaldos = ListarRespaldosDisponibles

    if ($todosRespaldos.Count -eq 0) {
        Write-ColorOutput Red "No se encontraron respaldos disponibles para restaurar."
        return
    }

    Write-Output ""
    Write-Output ""
    $seleccion = Read-Host "Ingrese el numero del respaldo a restaurar (1-$($todosRespaldos.Count))"

    try {
        $indice = [int]$seleccion - 1
        if ($indice -lt 0 -or $indice -ge $todosRespaldos.Count) {
            throw "Seleccion fuera de rango"
        }

        $respaldoSeleccionado = $todosRespaldos[$indice]

        Write-Output ""
        Write-Output "Se restaurara el respaldo:"
        Write-ColorOutput Yellow "- $($respaldoSeleccionado.Name) ($($respaldoSeleccionado.LastWriteTime))"

        $confirmacion = Read-Host "Confirma esta operacion? (S/N)"
        if ($confirmacion -ne "S") {
            Write-ColorOutput Yellow "Operacion cancelada."
            return
        }

        RestaurarRespaldo $respaldoSeleccionado

    } catch {
        Write-ColorOutput Red "Error: Seleccion invalida."
    }
}

function RestaurarRespaldo($respaldoObj) {
    Write-Output ""
    Write-Output "--- INICIANDO RESTAURACION ---"

    # Detener PocketBase
    DetenerServicioPocketbase

    try {
        $rutaOrigenPbData = Join-Path $respaldoObj.FullName "pb_data"

        # Verificar que el respaldo tiene los datos necesarios
        if (-not (Test-Path $rutaOrigenPbData)) {
            Write-ColorOutput Red "Error: El respaldo seleccionado no contiene la carpeta pb_data."
            return
        }

        # Crear respaldo de seguridad de datos actuales
        $fechaActual = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $rutaRespaldoSeguridad = Join-Path $rutaPocketbase "respaldo_seguridad_$fechaActual"

        Write-Output "Creando copia de seguridad de los datos actuales en $rutaRespaldoSeguridad..."
        New-Item -ItemType Directory -Path $rutaRespaldoSeguridad -Force | Out-Null

        if (Test-Path $rutaPocketbaseData) {
            Copy-Item -Path "$rutaPocketbaseData\*" -Destination $rutaRespaldoSeguridad -Recurse -Force
        }

        # Restaurar datos desde el respaldo
        Write-Output "Restaurando datos desde $($respaldoObj.FullName)..."

        # Limpiar directorio pb_data actual
        if (Test-Path $rutaPocketbaseData) {
            Remove-Item -Path "$rutaPocketbaseData\*" -Recurse -Force
        } else {
            New-Item -ItemType Directory -Path $rutaPocketbaseData -Force | Out-Null
        }

        # Copiar datos desde el respaldo
        Copy-Item -Path "$rutaOrigenPbData\*" -Destination $rutaPocketbaseData -Recurse -Force

        Write-ColorOutput Green "[OK] Restauracion completada exitosamente."

        # Iniciar PocketBase nuevamente
        IniciarServicioPocketbase

        Write-Output "Restauracion completada. El sistema ya puede utilizarse"
        Write-Output "con los datos restaurados desde el respaldo $($respaldoObj.Name)."

    } catch {
        Write-ColorOutput Red "Error durante la restauracion: $_"
    }
}

function RestaurarBotonEmergencia {
    # Esta funcion intenta reconstruir la base de datos a partir de los datos existentes
    # e informacion del repositorio. Es un ultimo recurso.

    Write-ColorOutput Red ""
    Write-ColorOutput Red "ADVERTENCIA! Este es un procedimiento de emergencia que intentara"
    Write-ColorOutput Red "reconstruir la base de datos con los usuarios y llaves originales."
    Write-ColorOutput Red "Solo debe usarse si todos los respaldos fallan."
    Write-Output ""

    $confirmacion = Read-Host "Esta seguro que desea continuar? (S/N)"
    if ($confirmacion -ne "S") {
        Write-ColorOutput Yellow "Operacion cancelada."
        return
    }

    $directorioRepositorio = Read-Host "Ingrese la ruta del repositorio git (presione enter para usar '$rutaSistema')"
    if ([string]::IsNullOrWhiteSpace($directorioRepositorio)) {
        $directorioRepositorio = $rutaSistema
    }

    if (-not (Test-Path $directorioRepositorio)) {
        Write-ColorOutput Red "Error: La ruta del repositorio no existe."
        return
    }

    DetenerServicioPocketbase

    try {
        # Crear copia de seguridad de la base actual
        $fechaActual = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $rutaRespaldoSeguridad = Join-Path $rutaPocketbase "respaldo_antes_emergencia_$fechaActual"

        Write-Output "Creando copia de seguridad de los datos actuales..."
        if (Test-Path $rutaPocketbaseData) {
            New-Item -ItemType Directory -Path $rutaRespaldoSeguridad -Force | Out-Null
            Copy-Item -Path "$rutaPocketbaseData\*" -Destination $rutaRespaldoSeguridad -Recurse -Force
        }

        # Verificar si hay archivo de datos iniciales en el repositorio
        $rutaDatosIniciales = Join-Path $directorioRepositorio "scripts\inicializacion\datos_iniciales"

        if (Test-Path $rutaDatosIniciales) {
            Write-Output "Encontrados datos iniciales en el repositorio. Restaurando..."

            # Limpiar directorio pb_data actual
            if (Test-Path $rutaPocketbaseData) {
                Remove-Item -Path "$rutaPocketbaseData\*" -Recurse -Force
            } else {
                New-Item -ItemType Directory -Path $rutaPocketbaseData -Force | Out-Null
            }

            # Copiar datos iniciales
            Copy-Item -Path "$rutaDatosIniciales\*" -Destination $rutaPocketbaseData -Recurse -Force

            Write-ColorOutput Green "[OK] Datos iniciales restaurados."
        } else {
            Write-ColorOutput Yellow "No se encontraron datos iniciales en el repositorio."
            Write-Output "Iniciando restauracion manual de estructuras minimas..."

            # Recrear datos minimos
            $rutaMinima = Join-Path $directorioRepositorio "pocketbase\pb_data_minimo"
            if (Test-Path $rutaMinima) {
                Copy-Item -Path "$rutaMinima\*" -Destination $rutaPocketbaseData -Recurse -Force
            } else {
                # Crear estructura minima
                New-Item -ItemType Directory -Path "$rutaPocketbaseData\data" -Force | Out-Null
                New-Item -ItemType Directory -Path "$rutaPocketbaseData\logs" -Force | Out-Null
            }
        }

        Write-Output "Buscando migraciones en el repositorio..."
        $rutaMigraciones = Join-Path $directorioRepositorio "pocketbase\pb_migrations"

        if (Test-Path $rutaMigraciones) {
            Write-Output "Encontradas migraciones. Copiando..."
            New-Item -ItemType Directory -Path "$rutaPocketbaseData\migrations" -Force | Out-Null
            Copy-Item -Path "$rutaMigraciones\*" -Destination "$rutaPocketbaseData\migrations" -Recurse -Force
        }

        Write-Output ""
        Write-ColorOutput Green "[OK] Procedimiento de emergencia completado."
        Write-Output "Los datos basicos han sido restaurados. Se ejecutaran las migraciones"
        Write-Output "cuando inicie PocketBase."
        Write-Output ""

        # Iniciar PocketBase nuevamente
        IniciarServicioPocketbase

        Write-Output "Procedimiento de emergencia completado. Ahora debe:"
        Write-Output "1. Acceder al sistema y verificar que funciona correctamente"
        Write-Output "2. Para restaurar los DATOS REALES del sistema (16 vigilantes y 161 llaves"
        Write-Output "   con sus ubicaciones), ejecute desde la raiz del proyecto:"
        Write-Output "       RESTAURAR_DATOS_URGENTE.bat"
        Write-Output "   Esto recreara automaticamente:"
        Write-Output "       - Vigilantes Matutino:   Sylvia (Jefa), Claudia, Laura, Lourdes, Luis, Dahiana"
        Write-Output "       - Vigilantes Vespertino: Martin (Jefe), Daniel, Nathia, Silvia, Alejandro, Caterin"
        Write-Output "       - Vigilantes Nocturno:   Gustavo (Jefe), Mario, Silvana, Fernando"
        Write-Output "       - Las 161 llaves del Tablero Principal con sus posiciones reales"
        Write-Output "3. Los usuarios solicitantes (docentes, alumnos, TAS) se cargan progresivamente"
        Write-Output "   al usar el sistema desde la terminal de usuario."

    } catch {
        Write-ColorOutput Red "Error durante el procedimiento de emergencia: $_"
    }
}

function MostrarMenu {
    MostrarEncabezado
    Write-Output "MENU PRINCIPAL"
    Write-Output "------------------"
    Write-Output "1. Listar respaldos disponibles"
    Write-Output "2. Restaurar ultimo respaldo (mas reciente)"
    Write-Output "3. Seleccionar respaldo especifico para restaurar"
    Write-Output "4. Restauracion de emergencia (ultimo recurso)"
    Write-Output "5. Reiniciar PocketBase"
    Write-Output "6. Salir"
    Write-Output ""
    Write-Output ""

    $opcion = Read-Host "Seleccione una opcion (1-6)"

    switch ($opcion) {
        "1" {
            MostrarEncabezado
            ListarRespaldosDisponibles
            Write-Output ""
            Write-Output ""
            Read-Host "Presione ENTER para continuar"
            MostrarMenu
        }
        "2" {
            MostrarEncabezado
            RestaurarUltimoRespaldo
            Write-Output ""
            Write-Output ""
            Read-Host "Presione ENTER para continuar"
            MostrarMenu
        }
        "3" {
            MostrarEncabezado
            RestaurarRespaldoSeleccionado
            Write-Output ""
            Write-Output ""
            Read-Host "Presione ENTER para continuar"
            MostrarMenu
        }
        "4" {
            MostrarEncabezado
            RestaurarBotonEmergencia
            Write-Output ""
            Write-Output ""
            Read-Host "Presione ENTER para continuar"
            MostrarMenu
        }
        "5" {
            MostrarEncabezado
            DetenerServicioPocketbase
            IniciarServicioPocketbase
            Write-Output ""
            Write-Output ""
            Read-Host "Presione ENTER para continuar"
            MostrarMenu
        }
        "6" {
            MostrarEncabezado
            Write-Output "Gracias por utilizar el Sistema de Recuperacion!"
            Write-Output "Asegurese de que PocketBase este ejecutandose antes de usar el sistema."
            Write-Output ""
            break
        }
        default {
            Write-ColorOutput Red "Opcion invalida. Intente nuevamente."
            Start-Sleep -Seconds 1
            MostrarMenu
        }
    }
}

# EJECUCION PRINCIPAL
if ($ListarRespaldos) {
    MostrarEncabezado
    ListarRespaldosDisponibles
    exit
}

if ($RestaurarUltimoRespaldo) {
    MostrarEncabezado
    RestaurarUltimoRespaldo
    exit
}

if (-not [string]::IsNullOrEmpty($RutaRespaldo)) {
    MostrarEncabezado
    if (Test-Path $RutaRespaldo) {
        $respaldo = Get-Item $RutaRespaldo
        RestaurarRespaldo $respaldo
    } else {
        Write-ColorOutput Red "Error: La ruta del respaldo especificada no existe."
    }
    exit
}

# Modo interactivo por defecto
MostrarMenu
