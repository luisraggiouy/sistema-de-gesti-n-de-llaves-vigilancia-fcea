# REGLAS CLINE - LEE ESTO PRIMERO EN CADA NUEVA TAREA
**Creado: 28/07/2026 16:56**

## Restricciones Técnicas
No accedas ni leas archivos dentro de la carpeta `node_modules/` ya que contiene dependencias de terceros que están pre-auditadas y funcionando correctamente. Leer estos archivos consume tokens innecesarios, aumenta el contexto sin aportar valor al desarrollo, y puede causar errores de límite de contexto. Las dependencias de JavaScript/TypeScript en node_modules son estables y no requieren modificación ni revisión.

## Contexto del Sistema
Este es un sistema de gestión de llaves para vigilancia de la FCEA (Facultad de Ciencias Económicas y de Administración). Incluye tres interfaces principales: Terminal de Usuario A, y B (para solicitar llaves), Monitor de Vigilancia (para gestionar entregas/devoluciones), y Dashboard Administrativo (para reportes y configuración). Utiliza React/TypeScript en el frontend, PocketBase como backend, y tiene un sistema robusto de instalación via pendrives, scripts de mantenimiento automatizado, manejo de objetos olvidados, sistema de autorizaciones, y funcionalidades de backup/recuperación. El sistema está diseñado para funcionar en modo kiosko en equipos dedicados.

**Hardware:** Si bien los monitores son táctiles, tienen tecnología resistiva por lo tanto no van a ser utilizados como táctiles van a ser usados como monitores convencionales, cada pc va a tener su teclado y su mouse. Usar siempre modo "tradicional" en lugar de "tactil" para lanzamiento de navegadores.

## Workflow de Desarrollo
Trabajemos de la siguiente manera: esta es la laptop de desarrollo siempre tiene internet, el sistema de 3 pc (una terminal de usuario A, una terminal de usuario B que están ubicadas fuera de la cabina de vigilancia y un monitor vigilancia que hace de servidor también que está dentro de la cabina) de facultad no tiene internet ni va a tener nunca, por lo tanto el pendrive es el "cable" entre la laptop de desarrollo y el sistema en producción de facultad. 

Entonces: aquí conmigo Luis tu haces el fix (arreglo) o el upgrade (nueva funcionalidad o mejora que hasta puede ser quitar algo), lo pruebas internamente, me dices que está pronto, lo grabas en el pendrive en la carpeta fix o en la carpeta upgrades, con un nombre específico representativo fecha y hora, me das un instructivo paso a paso con nombre representativo fecha y hora, yo desenchufo el pendrive de la laptop voy a la pc del sistema que me digas lo enchufo y ejecuto en la pc que corresponde tus instrucciones y si funciona bien te digo que funcionó ya con el pendrive nuevamente enchufado en la laptop de desarrollo, y ahí tu ahí lo integras el fix o el upgrade a los archivos más importantes.

## Scripts Críticos
Los archivos más importantes que deben actualizarse SIEMPRE son:
- Instalar sistema
- Desinstalar sistema  
- Recuperar sistema
- Actualizar semilla
**SOLO SON ESOS**

## Regla de Oro
Una mejora/upgrade o fix debe quedar grabada en todas partes, eso significa aquí en la laptop de desarrollo, en github, y en el pendrive también. Todo tiene que ser un proceso de mejora incremental y que vaya quedando comiteada y respaldada para que sirva de respaldo de rollback y **nunca olvidar hacer commit con timestamp y subir a github**.