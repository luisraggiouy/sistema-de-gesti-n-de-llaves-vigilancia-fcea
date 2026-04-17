# Prompt para generar presentación del Sistema de Gestión de Llaves FCEA

> **IA recomendada:** Google Gemini (gemini.google.com) — es gratuita, genera presentaciones con buen diseño y permite exportar a Google Slides directamente. Alternativa: Microsoft Copilot (copilot.microsoft.com) que puede generar PowerPoint.

---

## PROMPT (copiar y pegar en Gemini o Copilot):

---

Necesito que me crees una presentación profesional de entre 15 y 20 diapositivas para presentar ante las autoridades de la Facultad de Ciencias Económicas y de Administración (FCEA) de la Universidad de la República, Uruguay. La presentación es sobre un nuevo Sistema de Gestión de Llaves digital que reemplazará el sistema actual de planillas manuscritas en el área de Vigilancia.

La presentación debe tener un tono institucional, serio pero accesible, con diseño limpio y moderno. Usa colores institucionales (azul oscuro, blanco, gris). Cada diapositiva debe tener poco texto y ser muy visual.

Aquí está toda la información que necesitas para crear la presentación:

---

### DIAPOSITIVA 1 — Portada
Título: "Sistema de Gestión de Llaves — FCEA"
Subtítulo: "Modernización del control de acceso a espacios de la Facultad"
Incluir: Logo institucional, fecha 2026, "Departamento de Vigilancia"

---

### DIAPOSITIVA 2 — El problema actual
Título: "¿Cómo funciona hoy el control de llaves?"
Mostrar los problemas del sistema actual de planillas manuscritas:
- Todo se registra a mano en planillas de papel
- La letra de cada vigilante es diferente, muchas veces ilegible
- Los números de teléfono escritos a mano se confunden (¿es un 1 o un 7? ¿es un 6 o un 0?)
- Los números de salón se confunden (¿dice salón 11 o salón 17?)
- Cuando hay cambio de materia en un salón, el docente tiene que esperar a que el anterior devuelva la llave, generando demoras y colas
- No hay forma rápida de saber quién tiene una llave en este momento
- No hay estadísticas ni historial consultable

---

### DIAPOSITIVA 3 — El problema con objetos perdidos
Título: "Objetos olvidados: el sistema actual"
Mostrar:
- Cuando se encuentra un objeto olvidado, el vigilante escribe una descripción en un cuaderno
- Luego escribe lo mismo en una etiqueta de papel que pega al objeto
- Con el tiempo la etiqueta se despega, se borra o se pierde
- No hay forma de buscar rápidamente si un objeto fue encontrado
- No hay registro fotográfico
- Si el cuaderno se pierde, se pierde toda la información

---

### DIAPOSITIVA 4 — La solución
Título: "Sistema de Gestión de Llaves Digital"
Mostrar una descripción breve:
- Software diseñado específicamente para el Departamento de Vigilancia de FCEA
- Reemplaza las planillas manuscritas por un sistema digital intuitivo
- Funciona en la computadora que ya existe en el puesto de vigilancia
- No requiere equipamiento adicional ni inversión en hardware

---

### DIAPOSITIVA 5 — Arquitectura tipo Appliance
Título: "Seguridad por diseño: Sistema cerrado tipo Appliance"
Este es un punto CLAVE. Explicar:
- El sistema funciona como un "appliance": una solución autocontenida que NO se conecta a internet ni a la intranet de FCEA
- Todo funciona dentro de la misma computadora: la aplicación y la base de datos
- Al no tener conexión a redes externas, es IMPOSIBLE que sufra ataques informáticos, hackeos, ransomware o robo de datos desde el exterior
- Los datos nunca salen de la computadora del puesto de vigilancia
- Es como una caja fuerte digital: los datos están físicamente en un solo lugar controlado

---

### DIAPOSITIVA 6 — Comparativa de seguridad
Título: "¿Por qué es más seguro que un sistema en red?"
Hacer una tabla comparativa:

| Amenaza | Sistema conectado a internet | Nuestro sistema (appliance) |
|---------|------------------------------|----------------------------|
| Hackeo externo | Vulnerable | IMPOSIBLE (sin conexión) |
| Ransomware | Vulnerable | IMPOSIBLE (sin conexión) |
| Robo de datos por red | Vulnerable | IMPOSIBLE (sin conexión) |
| Caída del servidor central | Afecta al sistema | NO APLICA (es local) |
| Falla de internet/intranet | Sistema inaccesible | NO AFECTA (funciona sin red) |
| Actualizaciones que rompen el sistema | Frecuente | NO OCURRE (sin actualizaciones automáticas) |

---

### DIAPOSITIVA 7 — Respuesta a la preocupación de Sistemas
Título: "Mantenimiento prácticamente inexistente"
Este punto responde directamente a la preocupación del departamento de Sistemas que argumenta: "hay cosas que se actualizan y después el sistema queda fuera de servicio". Explicar:
- Este sistema NO recibe actualizaciones automáticas de ningún tipo
- No depende de Windows Update, ni de actualizaciones de navegador, ni de parches de seguridad de red
- El software está "congelado" en una versión estable y probada
- No hay servidores externos que puedan cambiar o dejar de funcionar
- No hay licencias que venzan ni suscripciones que renovar
- El único mantenimiento es un respaldo automático semanal que la computadora hace sola
- En 5 años de funcionamiento, el sistema no necesitará ninguna intervención del departamento de Sistemas

---

### DIAPOSITIVA 8 — Respaldos automáticos
Título: "Los datos nunca se pierden"
Explicar el sistema de respaldos:
- Cada domingo a las 8 AM, la computadora hace automáticamente una copia completa de toda la base de datos
- La copia se comprime y se guarda en una carpeta especial
- Se mantienen las últimas 52 copias (1 año completo de historial de respaldos)
- Si algo falla, se puede restaurar el sistema completo en minutos
- Adicionalmente, se recomienda copiar los respaldos a un pendrive una vez al mes como medida extra

---

### DIAPOSITIVA 9 — Recuperación ante fallas
Título: "Si el sistema falla: recuperación en minutos"
Explicar:
- Se prepara un pendrive de recuperación con todo el sistema
- Si la computadora falla, se conecta el pendrive y se ejecuta un archivo
- En 5-10 minutos el sistema queda restaurado con todos los datos históricos
- No se necesita llamar a nadie de Sistemas ni esperar días para la reparación
- El propio jefe de vigilancia puede restaurar el sistema

---

### DIAPOSITIVA 10 — Ventajas operativas: Préstamo de llaves
Título: "Préstamo de llaves: antes vs. ahora"
Comparar:

ANTES (planilla manuscrita):
- El vigilante busca la llave en el tablero
- Escribe a mano: nombre, teléfono, salón, hora
- La letra puede ser ilegible
- No se sabe si la llave ya está prestada hasta buscar en la planilla

AHORA (sistema digital):
- El usuario solicita la llave desde una pantalla táctil
- El sistema muestra automáticamente si la llave está disponible
- Los datos se registran digitalmente sin errores de escritura
- El vigilante ve en tiempo real todas las llaves prestadas y disponibles

---

### DIAPOSITIVA 11 — Ventajas operativas: Cambio de salón
Título: "Cambios de materia en salones: sin demoras"
Explicar el problema actual y la solución:

ANTES: Cuando termina una clase y empieza otra en el mismo salón, el docente saliente tiene que devolver la llave y el entrante tiene que esperar. Si el saliente se demora, se genera una cola y el entrante pierde minutos de clase.

AHORA: El sistema muestra en tiempo real quién tiene cada llave. El vigilante puede gestionar el intercambio de forma inmediata. El sistema registra automáticamente la devolución y el nuevo préstamo en segundos.

---

### DIAPOSITIVA 12 — Ventajas operativas: Objetos olvidados
Título: "Objetos olvidados: registro digital con foto"
Comparar:

ANTES:
- Se escribe en un cuaderno a mano
- Se pega una etiqueta de papel al objeto (se despega, se borra)
- No hay foto del objeto
- Buscar un objeto requiere revisar páginas del cuaderno

AHORA:
- Se registra digitalmente con descripción y foto
- Se puede buscar instantáneamente por fecha, descripción o ubicación
- El registro es permanente y no se deteriora
- Se puede marcar cuando el objeto es reclamado por su dueño

---

### DIAPOSITIVA 13 — Ventajas operativas: Estadísticas
Título: "Información para la toma de decisiones"
Mostrar que el sistema genera automáticamente:
- Estadísticas de uso por salón (cuáles son los más usados)
- Estadísticas por turno (mañana, tarde, noche)
- Historial completo de préstamos consultable por fecha
- Reportes exportables en Excel y PDF
- Acceso protegido por contraseña (solo jefes autorizados)

---

### DIAPOSITIVA 14 — Acceso restringido a estadísticas
Título: "Información confidencial protegida"
Explicar:
- Las estadísticas y reportes solo son accesibles con contraseña
- Existen dos niveles: Administrador (acceso total) y Custodio (acceso limitado)
- Los vigilantes comunes NO pueden ver las estadísticas
- La sesión se cierra automáticamente después de 4 horas
- Las contraseñas se pueden cambiar en cualquier momento

---

### DIAPOSITIVA 15 — Costo del sistema
Título: "Inversión: cero pesos"
Destacar:
- El software fue desarrollado internamente, sin costo de licencias
- Funciona en la computadora existente del puesto de vigilancia
- No requiere servidores adicionales
- No requiere conexión a internet
- No tiene costos de suscripción mensual ni anual
- No requiere soporte técnico externo
- El código fuente queda en propiedad de la Facultad

---

### DIAPOSITIVA 16 — Independencia del departamento de Sistemas
Título: "Autonomía operativa total"
Explicar:
- El sistema no depende de la infraestructura de red de la Facultad
- Si la red de FCEA se cae, el sistema sigue funcionando normalmente
- Si hay un corte de internet, el sistema sigue funcionando normalmente
- No compite por recursos con otros sistemas de la Facultad
- No genera carga de trabajo para el departamento de Sistemas
- El departamento de Vigilancia tiene control total sobre su herramienta

---

### DIAPOSITIVA 17 — Respuesta a objeciones comunes
Título: "Preguntas frecuentes"

"¿Y si se actualiza algo y deja de funcionar?"
→ El sistema no recibe actualizaciones automáticas. Solo se actualiza manualmente cuando se decide hacerlo, y siempre con respaldo previo.

"¿Y si la computadora se rompe?"
→ Se conecta el pendrive de recuperación a otra computadora y en 10 minutos está funcionando con todos los datos.

"¿Y si se va la luz?"
→ Al volver la luz, se ejecuta un archivo y el sistema arranca solo. Los datos no se pierden.

"¿Quién le da mantenimiento?"
→ El sistema se mantiene solo. El único mantenimiento es un respaldo automático semanal. No requiere intervención humana.

---

### DIAPOSITIVA 18 — Resumen de beneficios
Título: "Resumen: ¿Por qué implementar este sistema?"
Lista de beneficios clave:
✅ Elimina errores de escritura manual
✅ Datos siempre legibles y consultables
✅ Historial completo y permanente
✅ Estadísticas automáticas para la toma de decisiones
✅ Seguridad absoluta (sin conexión a redes)
✅ Mantenimiento prácticamente inexistente
✅ Recuperación rápida ante fallas
✅ Costo cero en licencias y hardware
✅ Independencia total del departamento de Sistemas
✅ Registro fotográfico de objetos olvidados

---

### DIAPOSITIVA 19 — Próximos pasos
Título: "Implementación propuesta"
- Fase 1: Instalación en la computadora del puesto de vigilancia (1 día)
- Fase 2: Capacitación de los vigilantes (2-3 días, durante el turno)
- Fase 3: Período de prueba en paralelo con planillas (2 semanas)
- Fase 4: Transición completa al sistema digital
- Preparación del pendrive de recuperación
- Configuración del respaldo automático

---

### DIAPOSITIVA 20 — Cierre
Título: "Sistema de Gestión de Llaves FCEA"
Subtítulo: "Modernización, seguridad y eficiencia para el Departamento de Vigilancia"
Incluir: "¿Preguntas?" y datos de contacto

---

INSTRUCCIONES DE DISEÑO:
- Usa un diseño profesional e institucional
- Colores principales: azul oscuro (#1a365d), blanco, gris claro
- Color de acento: dorado o amarillo suave para destacar puntos importantes
- Tipografía limpia y grande (mínimo 24pt para texto, 36pt para títulos)
- Máximo 6 líneas de texto por diapositiva
- Usa íconos simples para ilustrar conceptos
- En las comparativas "antes vs ahora", usa rojo para "antes" y verde para "ahora"
- Incluye diagramas simples donde sea posible en lugar de texto largo

---
