# Resolución de Error CORS en el Sistema de Gestión de Llaves

## Problema Detectado

Se ha identificado un error crítico en el sistema relacionado con CORS (Cross-Origin Resource Sharing) que genera el siguiente mensaje de error:

```
Unsafe attempt to load URL http://localhost:8080/monitor from frame with URL chrome-error://chromewebdata/. Domains, protocols and ports must match.
```

## ¿Qué es CORS?

CORS (Intercambio de Recursos de Origen Cruzado) es un mecanismo de seguridad implementado en los navegadores web modernos. Su propósito es proteger a los usuarios impidiendo que un sitio web acceda a recursos desde otro origen diferente sin los permisos adecuados.

En términos simples, cuando tu aplicación frontend intenta comunicarse con un backend (como nuestro servidor PocketBase), el navegador verifica si el backend permite explícitamente esta comunicación. Si no está configurado correctamente, el navegador bloquea la petición y genera un error CORS.

## Causa del Problema

El problema ocurre porque PocketBase no está correctamente configurado para permitir solicitudes desde la aplicación frontend. Específicamente:

1. PocketBase necesita una configuración explícita de CORS para permitir que la aplicación web acceda a sus recursos
2. Esta configuración debe especificar qué orígenes, métodos y cabeceras están permitidos
3. En nuestro caso, al no tener esta configuración o tenerla incompleta, el navegador bloquea las peticiones por seguridad

## Solución Implementada

Para resolver este problema, se han creado dos herramientas:

### 1. Script de Corrección Rápida CORS

Se ha desarrollado el script `scripts/fix_cors_issue.bat` que:

- Verifica si PocketBase está en ejecución y lo inicia si es necesario
- Crea un archivo de configuración CORS (`pb_config.json`) con los parámetros necesarios:
  - Habilita CORS (`enabled: true`)
  - Permite solicitudes desde cualquier origen (`allowOrigin: "*"`)
  - Configura los métodos HTTP permitidos
  - Establece las cabeceras permitidas
- Reinicia PocketBase para aplicar la nueva configuración

### 2. Herramienta de Diagnóstico Completo

Adicionalmente, se ha creado una herramienta más exhaustiva (`scripts/diagnostico_sistema_completo.bat`) que:

- Verifica múltiples aspectos del sistema (procesos, conexiones, archivos, configuración)
- Detecta automáticamente problemas CORS y los corrige
- Genera un informe detallado de los problemas encontrados y solucionados
- Proporciona recomendaciones específicas según el estado del sistema

## Cómo Aplicar la Solución

1. **Solución rápida:**
   - Ejecute el script `scripts/fix_cors_issue.bat` haciendo doble clic en él
   - Espere a que el script complete la corrección CORS
   - Reinicie cualquier navegador web que esté utilizando para acceder al sistema

2. **Diagnóstico completo (si la solución rápida no funciona):**
   - Ejecute el script `scripts/diagnostico_sistema_completo.bat`
   - Revise el informe generado para identificar posibles problemas adicionales
   - Siga las recomendaciones proporcionadas en el informe

## Prevención de Futuros Errores CORS

Para evitar que este problema vuelva a ocurrir en el futuro:

1. **No modifique el archivo pb_config.json** a menos que esté absolutamente seguro de lo que hace
2. **No elimine el archivo pb_config.json**, ya que contiene la configuración CORS necesaria
3. **Si actualiza PocketBase**, asegúrese de copiar el archivo pb_config.json al nuevo directorio
4. **Si migra el sistema a otro servidor**, asegúrese de transferir el archivo pb_config.json

## Detalles Técnicos de la Configuración CORS

La configuración aplicada incluye:

```json
{
  "options": {
    "http": {
      "cors": {
        "enabled": true,
        "allowOrigin": "*",
        "allowMethods": ["GET", "POST", "PUT", "PATCH", "DELETE"],
        "allowHeaders": ["Content-Type", "Authorization"],
        "exposeHeaders": [],
        "maxAge": 86400
      }
    }
  }
}
```

- `enabled: true`: Activa la funcionalidad CORS
- `allowOrigin: "*"`: Permite solicitudes desde cualquier origen (en producción podría limitarse a dominios específicos)
- `allowMethods`: Especifica los métodos HTTP permitidos
- `allowHeaders`: Define qué cabeceras HTTP puede enviar el cliente
- `maxAge`: Tiempo en segundos que el navegador puede almacenar la respuesta preflight CORS