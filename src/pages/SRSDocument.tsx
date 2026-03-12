import { useEffect } from "react";
import terminalScreenshot from "@/docs/screenshots/terminal-usuario.png";
import monitorScreenshot from "@/docs/screenshots/monitor-vigilancia.png";
import dashboardScreenshot from "@/docs/screenshots/dashboard-estadistico.png";
import fceaLogo from "@/assets/fcea-logo.png";

const SRSDocument = () => {
  useEffect(() => {
    document.title = "SRS - Sistema de Gestion de Llaves FCEA";
  }, []);

  return (
    <div className="bg-white text-gray-900 min-h-screen print:bg-white">
      <style>{`
        @media print {
          @page {
            size: A4;
            margin: 2cm;
          }
          body {
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
          .page-break {
            page-break-before: always;
          }
          .no-print {
            display: none !important;
          }
          .print-section {
            page-break-inside: avoid;
          }
        }
        .diagram {
          font-family: 'Courier New', monospace;
          font-size: 11px;
          line-height: 1.2;
          background: #f8f9fa;
          padding: 16px;
          border-radius: 8px;
          overflow-x: auto;
          white-space: pre;
        }
        table {
          border-collapse: collapse;
          width: 100%;
        }
        th, td {
          border: 1px solid #d1d5db;
          padding: 8px 12px;
          text-align: left;
        }
        th {
          background-color: #1e3a5f;
          color: white;
          font-weight: 600;
        }
        tr:nth-child(even) {
          background-color: #f9fafb;
        }
      `}</style>

      {/* Boton de impresion */}
      <div className="no-print fixed top-4 right-4 z-50 flex gap-2">
        <button
          onClick={() => {
            const content = document.querySelector('.max-w-4xl')?.innerHTML || '';
            const html = `<!DOCTYPE html><html><head><meta charset="utf-8"><title>SRS - Sistema de Gestion de Llaves FCEA</title><style>body{font-family:Georgia,serif;max-width:800px;margin:0 auto;padding:40px;color:#1a1a1a}h2{color:#1e3a5f;border-bottom:2px solid #1e3a5f;padding-bottom:8px}h3{color:#333}table{border-collapse:collapse;width:100%}th,td{border:1px solid #d1d5db;padding:8px 12px;text-align:left}th{background:#1e3a5f;color:white}.diagram{font-family:monospace;font-size:11px;background:#f8f9fa;padding:16px;border-radius:8px;white-space:pre;overflow-x:auto}img{max-width:100%;height:auto}</style></head><body>${content}</body></html>`;
            const blob = new Blob([html], { type: 'text/html' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'SRS_Sistema_Gestion_Llaves_FCEA_v4.4.html';
            a.click();
            URL.revokeObjectURL(url);
          }}
          className="bg-green-700 text-white px-6 py-3 rounded-lg shadow-lg hover:bg-green-600 transition-colors font-semibold"
        >
          Descargar HTML
        </button>
        <button
          onClick={() => window.print()}
          className="bg-blue-900 text-white px-6 py-3 rounded-lg shadow-lg hover:bg-blue-800 transition-colors font-semibold"
        >
          Imprimir / Guardar PDF
        </button>
        <button
          onClick={() => window.history.back()}
          className="bg-gray-600 text-white px-6 py-3 rounded-lg shadow-lg hover:bg-gray-500 transition-colors font-semibold"
        >
          Volver
        </button>
      </div>

      <div className="max-w-4xl mx-auto px-8 py-12">
        {/* Portada */}
        <div className="text-center mb-16 print-section">
          <div className="border-4 border-blue-900 p-12 rounded-lg">
            <img src={fceaLogo} alt="FCEA - Universidad de la República" className="h-32 w-auto mx-auto mb-4" />
            <div className="text-gray-600 text-lg mb-8">Universidad de la Republica</div>
            
            <h1 className="text-3xl font-bold text-gray-900 mb-4">
              Especificacion de Requisitos de Software
            </h1>
            <h2 className="text-xl text-gray-700 mb-8">
              Sistema de Gestion de Llaves
            </h2>
            
            <div className="border-t-2 border-gray-300 pt-8 mt-8 text-left max-w-sm mx-auto">
              <p className="mb-2"><strong>Version:</strong> 4.3</p>
              <p className="mb-2"><strong>Fecha:</strong> 8 de Marzo de 2026</p>
              <p className="mb-2"><strong>Elaborado por:</strong> Equipo de Desarrollo</p>
              <p><strong>Institucion:</strong> Facultad de Ciencias Economicas y de Administracion</p>
            </div>
          </div>
        </div>

        {/* Tabla de Contenidos */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            Tabla de Contenidos
          </h2>
          <div className="space-y-2 text-gray-700">
            <p className="flex justify-between"><span>1. Introduccion</span><span className="border-b border-dotted border-gray-400 flex-1 mx-2"></span></p>
            <p className="flex justify-between pl-4"><span>1.1 Proposito</span></p>
            <p className="flex justify-between pl-4"><span>1.2 Alcance</span></p>
            <p className="flex justify-between pl-4"><span>1.3 Definiciones y Acronimos</span></p>
            <p className="flex justify-between"><span>2. Descripcion General</span></p>
            <p className="flex justify-between pl-4"><span>2.1 Perspectiva del Producto</span></p>
            <p className="flex justify-between pl-4"><span>2.2 Funciones del Producto</span></p>
            <p className="flex justify-between pl-4"><span>2.3 Caracteristicas de los Usuarios</span></p>
            <p className="flex justify-between"><span>3. Requisitos Especificos</span></p>
            <p className="flex justify-between pl-4"><span>3.1 Requisitos Funcionales</span></p>
            <p className="flex justify-between pl-4"><span>3.2 Requisitos No Funcionales</span></p>
            <p className="flex justify-between"><span>4. Arquitectura del Sistema</span></p>
            <p className="flex justify-between"><span>5. Casos de Uso</span></p>
            <p className="flex justify-between"><span>6. Diagramas de Flujo</span></p>
            <p className="flex justify-between"><span>7. Interfaces de Usuario</span></p>
            <p className="flex justify-between"><span>8. Capturas de Pantalla</span></p>
            <p className="flex justify-between"><span>9. Seguridad y Control de Acceso</span></p>
            <p className="flex justify-between"><span>10. Glosario</span></p>
          </div>
        </div>

        {/* Seccion 1: Introduccion */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            1. Introduccion
          </h2>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">1.1 Proposito</h3>
          <p className="text-gray-700 leading-relaxed mb-4">
            El presente documento tiene como objetivo definir de manera integral los requisitos funcionales y no funcionales del <strong>Sistema de Gestion de Llaves</strong> para la Facultad de Ciencias Economicas y de Administracion (FCEA) de la Universidad de la Republica.
          </p>
          <p className="text-gray-700 leading-relaxed mb-4">
            Este sistema busca modernizar y optimizar el proceso de prestamo, control y devolucion de llaves de los distintos espacios fisicos de la facultad (salones, oficinas, laboratorios, depositos), proporcionando trazabilidad completa, alertas automatizadas y reportes estadisticos para la toma de decisiones administrativas.
          </p>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">1.2 Alcance</h3>
          <p className="text-gray-700 leading-relaxed mb-4">El Sistema de Gestion de Llaves abarca:</p>
          <ul className="list-disc list-inside text-gray-700 mb-4 space-y-1 pl-4">
            <li>Registro e identificacion de usuarios por celular o email</li>
            <li>Solicitud de llaves por parte de docentes, alumnos, personal TAS y empresas</li>
            <li>Gestion de entregas, devoluciones e intercambios por parte del personal de vigilancia</li>
            <li>Control de tiempos de uso con alertas automatizadas y notificaciones sonoras</li>
            <li>Registro historico de todas las operaciones</li>
            <li>Generacion de reportes para la administracion con exportacion CSV</li>
            <li>Gestion de personal de vigilancia por turnos con control de licencias</li>
            <li>Modulo de autorizaciones temporales con busqueda inteligente y purga automatica</li>
            <li>Agenda de contactos con edicion y eliminacion de usuarios</li>
          </ul>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">1.3 Definiciones y Acronimos</h3>
          <table className="mb-6">
            <thead>
              <tr>
                <th>Termino</th>
                <th>Definicion</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>FCEA</td><td>Facultad de Ciencias Economicas y de Administracion</td></tr>
              <tr><td>UdelaR</td><td>Universidad de la Republica</td></tr>
              <tr><td>SRS</td><td>Software Requirements Specification</td></tr>
              <tr><td>Terminal</td><td>Punto de acceso donde los usuarios solicitan llaves</td></tr>
              <tr><td>Monitor</td><td>Interfaz utilizada por el personal de vigilancia</td></tr>
              <tr><td>Turno</td><td>Periodo de trabajo del personal (Matutino, Vespertino, Nocturno)</td></tr>
            </tbody>
          </table>
        </div>

        {/* Seccion 2: Descripcion General */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            2. Descripcion General
          </h2>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">2.1 Perspectiva del Producto</h3>
          <p className="text-gray-700 leading-relaxed mb-4">
            El Sistema de Gestion de Llaves es una aplicacion web responsiva que opera de forma independiente, diseñada para ser accedida desde multiples dispositivos simultaneamente. Se compone de tres modulos principales interconectados:
          </p>

          <div className="diagram mb-6">{`
+------------------------------------------------------------------+
|                    SISTEMA DE GESTION DE LLAVES                   |
+------------------------------------------------------------------+
|                                                                   |
|  +------------------+  +------------------+  +------------------+ |
|  |                  |  |                  |  |                  | |
|  |    TERMINAL      |  |    MONITOR DE    |  |    DASHBOARD     | |
|  |    DE USUARIO    |  |    VIGILANCIA    |  |    ESTADISTICO   | |
|  |                  |  |                  |  |                  | |
|  +--------+---------+  +--------+---------+  +--------+---------+ |
|           |                     |                     |           |
|           +----------+----------+----------+----------+           |
|                      |                     |                      |
|              +-------v-------+     +-------v-------+              |
|              |   CONTEXTO    |     |  ALMACENAMIENTO|             |
|              |   COMPARTIDO  |     |    LOCAL       |             |
|              +---------------+     +----------------+              |
|                                                                   |
+------------------------------------------------------------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">2.2 Funciones del Producto</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Gestion de Solicitudes</h4>
              <ul className="text-sm text-gray-700 space-y-1">
                <li>Registro de solicitudes por usuarios</li>
                <li>Cola de solicitudes en tiempo real</li>
                <li>Busqueda y seleccion de llaves</li>
              </ul>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Control de Entregas</h4>
              <ul className="text-sm text-gray-700 space-y-1">
                <li>Registro con identificacion del vigilante</li>
                <li>Calculo automatico de tiempo de uso</li>
                <li>Funcion de deshacer (2 minutos)</li>
              </ul>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Sistema de Alertas</h4>
              <ul className="text-sm text-gray-700 space-y-1">
                <li>Notificacion visual por tiempo excedido</li>
                <li>Mensaje WhatsApp automatico</li>
              </ul>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Reportes y Estadisticas</h4>
              <ul className="text-sm text-gray-700 space-y-1">
                <li>Dashboard con metricas en tiempo real</li>
                <li>Exportacion CSV mensual</li>
              </ul>
            </div>
          </div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">2.3 Caracteristicas de los Usuarios</h3>
          <table className="mb-6">
            <thead>
              <tr>
                <th>Tipo de Usuario</th>
                <th>Perfil</th>
                <th>Frecuencia de Uso</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><strong>Docente</strong></td>
                <td>Personal docente de la facultad</td>
                <td>Diaria</td>
              </tr>
              <tr>
                <td><strong>Alumno</strong></td>
                <td>Estudiantes de la facultad</td>
                <td>Variable (diaria a esporadica)</td>
              </tr>
              <tr>
                <td><strong>Personal TAS</strong></td>
                <td>Personal no docente: Electrotecnia, Servicios Generales, Compras, Gastos, UPC, Decanato, Suministros, Apoyo Docente, Bedelia, Contaduria, Sueldos, CAVIDA, Convenios, Concursos, Sistemas, Mantenimiento</td>
                <td>Diaria</td>
              </tr>
              <tr>
                <td><strong>Empresa</strong></td>
                <td>Personal externo o empresas tercerizadas</td>
                <td>Esporadica</td>
              </tr>
              <tr>
                <td><strong>Vigilante</strong></td>
                <td>Personal de seguridad de la facultad</td>
                <td>Continua durante su turno</td>
              </tr>
            </tbody>
          </table>
        </div>

        {/* Seccion 3: Requisitos Especificos */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            3. Requisitos Especificos
          </h2>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">3.1 Requisitos Funcionales</h3>

          <div className="space-y-4 mb-8">
            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-001: Solicitud de Llaves</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El sistema debe permitir a los usuarios solicitar una o mas llaves simultaneamente.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Entrada:</strong> Datos del usuario (nombre, celular, tipo), llaves seleccionadas</p>
                <p><strong>Salida:</strong> Confirmacion de solicitud, notificacion a vigilancia</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-002: Busqueda de Llaves</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El sistema debe permitir buscar llaves por nombre, codigo o tipo de espacio.</p>
                <p><strong>Prioridad:</strong> Alta</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-003: Entrega de Llave</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El vigilante debe poder registrar la entrega de una llave a un usuario.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Postcondiciones:</strong> Llave marcada como "en uso", registro de actividad creado</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-004: Devolucion de Llave</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El vigilante debe poder registrar la devolucion de una llave.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Salida:</strong> Registro de devolucion con calculo de tiempo total de uso</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-005: Funcion Deshacer</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Permitir revertir una entrega o devolucion dentro de los 2 minutos siguientes.</p>
                <p><strong>Prioridad:</strong> Media</p>
                <p><strong>Restricciones:</strong> Solo disponible dentro de ventana de 2 minutos</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-006: Alerta por Tiempo Excedido</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Mostrar alerta visual cuando una llave excede el tiempo limite de uso.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Salida:</strong> Indicador visual (punto rojo pulsante), boton de WhatsApp</p>
                <p><strong>Configuracion:</strong> Tiempo limite configurable (por defecto: 2h 15min)</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-007: Mensaje WhatsApp</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Generar enlace de WhatsApp con mensaje predefinido para contactar al usuario.</p>
                <p><strong>Prioridad:</strong> Media</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-008: Gestion de Vigilantes</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Administrar el registro de vigilantes asignados a cada turno.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Operaciones:</strong> Agregar, editar, eliminar vigilantes; asignar turno; designar jefe de turno</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-009: Busqueda en Historial</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Permitir buscar en el historial de operaciones con filtros multiples.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Filtros:</strong> Nombre de llave, usuario, vigilante, rango de fechas</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-010: Exportacion de Reportes Mensuales</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Generar reportes en formato CSV con estadisticas mensuales.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Contenido:</strong> Resumen general, estadisticas por turno, detalle por vigilante, log de operaciones</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-011: Intercambio de Llaves entre Usuarios</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Permitir la transferencia directa de llaves entre usuarios sin devolucion al mostrador de vigilancia.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Flujo:</strong> El nuevo usuario busca la llave en uso, visualiza quien la posee, confirma la responsabilidad mediante checkbox obligatorio, y el sistema cierra la sesion anterior y abre una nueva.</p>
                <p><strong>Restriccion:</strong> El nuevo usuario debe aceptar explicitamente la responsabilidad sobre la llave.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-012: Restriccion de Alertas por Tipo de Espacio</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Las alertas por tiempo excedido y mensajes WhatsApp solo aplican a llaves de tipo Salon y Salon Hibrido.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Justificacion:</strong> Las oficinas y otros espacios requieren posesion prolongada de llaves por naturaleza del trabajo.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-013: Identificacion por Email</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Permitir que los usuarios se identifiquen con email como alternativa al celular.</p>
                <p><strong>Prioridad:</strong> Media</p>
                <p><strong>Justificacion:</strong> Usuarios que prefieran no registrar su numero de celular pueden usar su correo electronico.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-014: Agenda de Contactos</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Modulo de busqueda de contactos registrados accesible desde el Monitor de Vigilancia.</p>
                <p><strong>Prioridad:</strong> Media</p>
                <p><strong>Funcionalidad:</strong> Permite buscar por nombre, telefono, email, tipo de usuario o departamento. Muestra informacion de contacto y funcion del usuario.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-015: Notas en Llaves Entregadas</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Campo de notas editable en cada llave en uso para registrar observaciones.</p>
                <p><strong>Prioridad:</strong> Baja</p>
                <p><strong>Justificacion:</strong> Los vigilantes pueden anotar particularidades relevantes sobre cada entrega de llave.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-016: Gestion de Vigilantes con Confirmacion</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El modulo de gestion de vigilantes incluye confirmacion visual de cambios, opcion de maximizar pantalla completa, y boton "Listo" para finalizar el proceso.</p>
                <p><strong>Prioridad:</strong> Media</p>
                <p><strong>Mejoras UX:</strong> Toast de confirmacion al agregar/eliminar vigilantes, contador de cambios realizados, scroll completo del listado.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-017: Restriccion Horaria de Solicitudes</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El sistema restringe la solicitud de llaves fuera del horario permitido (antes de las 7:00 AM y despues de las 23:00 PM).</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Usuarios afectados:</strong> Docentes, Alumnos, Personal TAS (excepto Servicios Generales), Empresas</p>
                <p><strong>Usuarios exentos:</strong> Personal de Vigilancia y Servicios Generales</p>
                <p><strong>Justificacion:</strong> Por orden del Decano, se restringe la entrega de llaves en horarios no laborales para garantizar la seguridad del edificio.</p>
                <p><strong>Implementacion:</strong> Banner visual de alerta cuando un usuario no autorizado intenta solicitar llaves fuera del horario, bloqueando el envio de la solicitud.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-018: Clasificacion de Tableros</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Las llaves se organizan en tres tableros fisicos diferenciados.</p>
                <p><strong>Prioridad:</strong> Media</p>
                <p><strong>Tableros:</strong></p>
                <ul className="list-disc pl-6 mt-1 space-y-1">
                  <li><strong>Tablero Principal:</strong> Llaves de uso general (salones, oficinas, salas)</li>
                  <li><strong>Tablero Copias:</strong> Copias de seguridad de las llaves principales</li>
                  <li><strong>Tablero Jefes:</strong> Llaves de acceso restringido para jefes de turno</li>
                </ul>
                <p className="mt-2"><strong>Implementacion:</strong> Menu desplegable en la gestion de llaves para seleccionar el tablero antes de definir la ubicacion.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-019: Gestion de Licencias de Vigilantes</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Registrar y visualizar el estado de licencia del personal de vigilancia.</p>
                <p><strong>Prioridad:</strong> Media</p>
                <p><strong>Estados:</strong> Activo, Licencia (vacaciones/personal), Licencia Medica</p>
                <p><strong>Impacto:</strong> Los vigilantes en licencia no aparecen en los botones de entrega/devolucion del monitor. El dashboard refleja las ausencias por turno.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-020: Sistema de Notificaciones Sonoras</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El Monitor de Vigilancia emite señales sonoras delicadas (tipo campana/ding) para eventos clave.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Eventos sonoros:</strong></p>
                <ul className="list-disc pl-6 mt-1 space-y-1">
                  <li><strong>Nueva solicitud:</strong> Doble campana ascendente al recibir un nuevo pedido de llave</li>
                  <li><strong>Entrega de llave:</strong> Sonido unico por vigilante (ding descendente con frecuencia personalizada)</li>
                  <li><strong>Devolucion de llave:</strong> Triple campana ascendente con frecuencia unica del vigilante receptor</li>
                </ul>
                <p className="mt-2"><strong>Controles:</strong> Control de volumen (slider 0-100%), boton de silenciar/activar (mute), boton de prueba de sonido. Configuracion persistida en localStorage.</p>
                <p><strong>Implementacion:</strong> Generacion de sonidos via Web Audio API sin archivos externos. Cada vigilante tiene una frecuencia musical unica derivada de su nombre.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-021: Registro de Usuarios con Empresa</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Cuando un usuario selecciona el tipo "Empresa" durante el registro, el sistema muestra un campo obligatorio para ingresar el nombre de la empresa. Este dato se almacena y se muestra en todas las vistas del sistema.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Validacion:</strong> El campo "Nombre de empresa" es obligatorio cuando el tipo es Empresa; el registro no puede completarse sin este dato.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-022: Gestion de Usuarios Registrados (Agenda)</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El modulo Agenda del Monitor de Vigilancia permite editar y eliminar usuarios registrados. Los vigilantes pueden modificar nombre, telefono, email, tipo de usuario, departamento y nombre de empresa.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Operaciones:</strong> Editar datos de usuario (inline), eliminar usuario con confirmacion, buscar por nombre/telefono/email/empresa</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-023: Reinicio de Terminal tras Registro</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Al completar el registro de un nuevo usuario, el terminal muestra un mensaje de exito y se reinicia completamente, permitiendo al usuario probar su registro ingresando su telefono o email.</p>
                <p><strong>Prioridad:</strong> Media</p>
                <p><strong>Justificacion:</strong> Permite al usuario verificar inmediatamente que su registro fue exitoso antes de solicitar llaves.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-024: Modulo de Autorizaciones Temporales</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El sistema permite registrar autorizaciones temporales que habilitan a personas especificas a retirar llaves de lugares determinados. Cada autorizacion incluye: persona, lugar, autorizante, fecha de autorizacion, periodo de vigencia opcional (desde-hasta), horario, email de referencia y observaciones.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Ubicacion:</strong> Pestaña "Autorizaciones" dentro del modulo "Agenda / Autorizaciones" del Monitor de Vigilancia.</p>
                <p><strong>Justificacion:</strong> Sustituye la busqueda manual en correos electronicos que realizaban los vigilantes para verificar permisos temporales.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-025: Busqueda Inteligente en Autorizaciones</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Los campos de busqueda de nombre y lugar en el verificador de autorizaciones funcionan como buscador inteligente en tiempo real. A medida que el vigilante escribe, el sistema filtra y muestra coincidencias parciales del listado de autorizaciones registradas.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Ejemplo:</strong> Al escribir "S" se muestran todos los nombres con S; al escribir "Sh" se filtran nombres que contienen "Sh".</p>
                <p><strong>Implementacion:</strong> Busqueda insensible a acentos (NFD normalization) ejecutada en cada cambio de caracter.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-026: Baja Automatica de Autorizaciones Vencidas</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Las autorizaciones que tengan fecha de finalizacion (fechaHasta) anterior a la fecha actual se eliminan automaticamente al abrir el modulo. El sistema notifica al vigilante cuantas autorizaciones fueron purgadas.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Complemento:</strong> Se muestra un badge de "Vence pronto" para autorizaciones que expiran dentro de los proximos 7 dias.</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-027: Edicion y Eliminacion de Autorizaciones</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> Desde el verificador de autorizaciones, el vigilante puede editar todos los campos de una autorizacion existente o eliminarla con confirmacion previa.</p>
                <p><strong>Prioridad:</strong> Alta</p>
                <p><strong>Operaciones:</strong> Editar (abre formulario precargado), Eliminar (con dialogo de confirmacion).</p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">RF-028: Historial de Autorizaciones</div>
              <div className="p-4 text-gray-700">
                <p><strong>Descripcion:</strong> El sistema mantiene un historial permanente de todas las autorizaciones que fueron eliminadas manualmente o purgadas por vencimiento. El vigilante puede consultar este historial desde la pestaña "Historial" del modulo Agenda/Autorizaciones.</p>
                <p><strong>Prioridad:</strong> Media</p>
                <p><strong>Funcionalidades:</strong></p>
                <ul className="list-disc list-inside mt-1 space-y-1 pl-4">
                  <li>Busqueda por lugar o persona con filtrado en tiempo real (insensible a acentos)</li>
                  <li>Filtrado por rango de fechas (fecha de autorizacion)</li>
                  <li>Visualizacion de todos los datos originales: persona, lugar, quien autorizo, horario, vigencia, email de referencia y observaciones</li>
                  <li>Indicador del motivo de baja (vencida o eliminada) y fecha de baja</li>
                  <li>Las autorizaciones eliminadas manualmente y las purgadas automaticamente por vencimiento se preservan en el historial</li>
                </ul>
              </div>
            </div>
          </div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">3.2 Requisitos No Funcionales</h3>
          <table className="mb-6">
            <thead>
              <tr>
                <th>ID</th>
                <th>Requisito</th>
                <th>Especificacion</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>RNF-001</td>
                <td>Rendimiento</td>
                <td>Respuesta en menos de 2 segundos; actualizacion en tiempo real (&lt;500ms)</td>
              </tr>
              <tr>
                <td>RNF-002</td>
                <td>Disponibilidad</td>
                <td>24/7 con uptime minimo del 99%</td>
              </tr>
              <tr>
                <td>RNF-003</td>
                <td>Usabilidad</td>
                <td>Interfaz intuitiva; textos legibles a 1 metro; diseño responsivo</td>
              </tr>
              <tr>
                <td>RNF-004</td>
                <td>Compatibilidad</td>
                <td>Chrome 90+, Firefox 88+, Safari 14+, Edge 90+</td>
              </tr>
              <tr>
                <td>RNF-005</td>
                <td>Escalabilidad</td>
                <td>100+ llaves; 500+ operaciones diarias</td>
              </tr>
            </tbody>
          </table>
        </div>

        {/* Seccion 4: Arquitectura */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            4. Arquitectura del Sistema
          </h2>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">4.1 Diagrama de Arquitectura</h3>
          <div className="diagram mb-6">{`
+------------------------------------------------------------------+
|                         CAPA DE PRESENTACION                      |
+------------------------------------------------------------------+
|   +-----------------+  +-----------------+  +-----------------+   |
|   |   Terminal de   |  |   Monitor de    |  |   Dashboard     |   |
|   |     Usuario     |  |   Vigilancia    |  |  Estadistico    |   |
|   |  (/terminal)    |  |   (/monitor)    |  |  (/dashboard)   |   |
|   +-----------------+  +-----------------+  +-----------------+   |
+-----------+--------------------+--------------------+-------------+
            |                    |                    |
+-----------v--------------------v--------------------v-------------+
|                         CAPA DE LOGICA                            |
+------------------------------------------------------------------+
|   +------------------+  +------------------+  +------------------+ |
|   | useSolicitudes   |  | useVigilantes    |  | useConfiguracion| |
|   | Context          |  | Hook             |  | Hook            | |
|   +------------------+  +------------------+  +------------------+ |
|   +------------------+  +------------------+  +------------------+ |
|   | useSonidos       |  | useHistorial     |  | useUsuarios     | |
|   | Hook             |  | Llaves Hook      |  | Registrados Hook| |
|   +------------------+  +------------------+  +------------------+ |
+------------------------------------------------------------------+
            |                    |                    |
+-----------v--------------------v--------------------v-------------+
|                         CAPA DE DATOS                             |
+------------------------------------------------------------------+
|   +------------------+  +------------------+  +------------------+ |
|   | localStorage     |  | Tipos TypeScript |  | Datos Iniciales | |
|   | (persistencia)   |  | (interfaces)     |  | (fceaData)      | |
|   +------------------+  +------------------+  +------------------+ |
+------------------------------------------------------------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">4.2 Modelo de Datos</h3>
          <div className="diagram mb-6">{`
+------------------+       +------------------+       +------------------+
|     Lugar        |       |  SolicitudLlave  |       |    Vigilante     |
+------------------+       +------------------+       +------------------+
| id: string       |       | id: string       |       | id: string       |
| nombre: string   |<------| lugar: Lugar     |       | nombre: string   |
| tipo: TipoLugar  |       | usuario: Usuario |       | turno: Turno     |
| tablero: Tablero |       | terminal: string |       | esJefe: boolean  |
| edificio: string |       | horaSolicitud    |       | estadoLicencia?: |
| disponible: bool |       | horaEntrega?     |       |   EstadoLicencia |
| esHibrido: bool  |       | horaDevolucion?  |       +------------------+
| ubicacion:       |       | entregadoPor?    |
|   zona: string   |       | recibidoPor?     |       +------------------+
|   fila?: number  |       | estado: Estado   |       | UsuarioRegistrado|
|   columna?:string|       | esIntercambio?   |       +------------------+
+------------------+       | usuarioAnterior? |       | id: string       |
                           | notas?: string   |       | nombre: string   |
                           +------------------+       | celular: string  |
                                                      | email?: string   |
+------------------+                                  | tipo: TipoUsuario|
|  Autorizacion    |                                  | departamento?    |
+------------------+                                  | nombreEmpresa?   |
| id: string       |                                  | fechaRegistro    |
| personaNombre    |                                  +------------------+
| lugarAutorizado  |
| autorizadoPor    |       EstadoLicencia:
| fechaAutorizacion|       - activo
| fechaDesde?      |       - licencia
| fechaHasta?      |       - licencia_medica
| horario?         |
| emailReferencia? |
| observaciones?   |
| fechaCreacion    |
+------------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">4.3 Enumeraciones</h3>
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Tipos de Lugar (TipoLugar)</h4>
              <code className="text-sm">Salon | Salon Hibrido | Oficina | Sala | Deposito | Baño | Area Comun | Biblioteca | Auditorio</code>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Tipos de Usuario (TipoUsuario)</h4>
              <code className="text-sm">Docente | Alumno | Personal TAS (con departamento) | Empresa (con nombre empresa)</code>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Estados de Solicitud</h4>
              <code className="text-sm">pendiente | entregada | devuelta</code>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Turnos de Vigilancia</h4>
              <code className="text-sm">Matutino (06-14) | Vespertino (14-22) | Nocturno (22-06)</code>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Tipos de Tablero (TipoTablero)</h4>
              <code className="text-sm">Tablero Principal | Tablero Copias | Tablero Jefes</code>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Estado de Licencia</h4>
              <code className="text-sm">activo | licencia | licencia_medica</code>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Zonas del Tablero</h4>
              <code className="text-sm">Puerta derecha | Puerta izquierda | Fondo | Lateral derecho | Lateral izquierdo</code>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-blue-900 mb-2">Departamentos TAS</h4>
              <code className="text-sm">Electrotecnia | Servicios Generales | Compras | Gastos | UPC | Decanato | Suministros | Apoyo Docente | Bedelia | Contaduria | Sueldos | CAVIDA | Convenios | Concursos | Sistemas | Mantenimiento | Vigilancia</code>
            </div>
          </div>
        </div>

        {/* Seccion 5: Casos de Uso */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            5. Casos de Uso
          </h2>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">5.1 Diagrama General de Casos de Uso</h3>
          <div className="diagram mb-6">{`
+------------------------------------------------------------------+
|                    SISTEMA DE GESTION DE LLAVES                   |
+------------------------------------------------------------------+
|                                                                   |
|                         +------------------+                      |
|                         |    Solicitar     |                      |
|     +--------+          |     Llave        |                      |
|     |Usuario |--------->+------------------+                      |
|     |Solic.  |                                                    |
|     +--------+          +------------------+                      |
|         |               |    Buscar        |                      |
|         +-------------->|    Llave         |                      |
|                         +------------------+                      |
|                                                                   |
|     +--------+          +------------------+                      |
|     |        |--------->|  Entregar Llave  |                      |
|     |        |          +------------------+                      |
|     |        |          +------------------+                      |
|     |        |--------->|  Devolver Llave  |                      |
|     |Vigilante          +------------------+                      |
|     |        |          +------------------+                      |
|     |        |--------->|  Deshacer Accion |                      |
|     |        |          +------------------+                      |
|     |        |          +------------------+                      |
|     |        |--------->| Enviar WhatsApp  |                      |
|     +--------+          +------------------+                      |
|                                                                   |
|     +--------+          +------------------+                      |
|     |        |--------->| Gestionar        |                      |
|     |        |          | Vigilantes       |                      |
|     |        |          +------------------+                      |
|     |Admin   |          +------------------+                      |
|     |        |--------->| Exportar         |                      |
|     |        |          | Reportes         |                      |
|     +--------+          +------------------+                      |
|                                                                   |
+------------------------------------------------------------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">5.2 Especificacion de Casos de Uso</h3>

          <div className="space-y-6">
            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">CU-001: Solicitar Llave</div>
              <div className="p-4">
                <table className="text-sm">
                  <tbody>
                    <tr><td className="font-semibold pr-4 align-top">Actor Principal</td><td>Usuario Solicitante</td></tr>
                    <tr><td className="font-semibold pr-4 align-top">Descripcion</td><td>El usuario solicita una o mas llaves desde el terminal</td></tr>
                    <tr><td className="font-semibold pr-4 align-top">Flujo Principal</td><td>
                      1. Usuario ingresa celular o email en el campo de busqueda<br/>
                      2. Sistema busca en usuarios registrados<br/>
                      3. Si no existe, presiona "Registrarse" y completa el formulario<br/>
                      4. Busca la llave deseada (con filtros de tipo y edificio)<br/>
                      5. Selecciona una o mas llaves (o usa llaves frecuentes)<br/>
                      6. Confirma la solicitud<br/>
                      7. Sistema registra, emite sonido y notifica a vigilancia
                    </td></tr>
                    <tr><td className="font-semibold pr-4 align-top">Flujo Alterno</td><td>
                      Si la llave esta en uso, el usuario puede solicitar un intercambio aceptando responsabilidad
                    </td></tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">CU-002: Entregar Llave</div>
              <div className="p-4">
                <table className="text-sm">
                  <tbody>
                    <tr><td className="font-semibold pr-4 align-top">Actor Principal</td><td>Vigilante</td></tr>
                    <tr><td className="font-semibold pr-4 align-top">Descripcion</td><td>El vigilante entrega fisicamente la llave y registra la operacion</td></tr>
                    <tr><td className="font-semibold pr-4 align-top">Flujo Principal</td><td>
                      1. Visualiza solicitud pendiente<br/>
                      2. Verifica identidad del solicitante<br/>
                      3. Localiza llave en tablero<br/>
                      4. Presiona boton con su nombre<br/>
                      5. Sistema registra y mueve a "En Uso"
                    </td></tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-blue-900 text-white px-4 py-2 font-semibold">CU-003: Devolver Llave</div>
              <div className="p-4">
                <table className="text-sm">
                  <tbody>
                    <tr><td className="font-semibold pr-4 align-top">Actor Principal</td><td>Vigilante</td></tr>
                    <tr><td className="font-semibold pr-4 align-top">Descripcion</td><td>El vigilante recibe la llave y registra la devolucion</td></tr>
                    <tr><td className="font-semibold pr-4 align-top">Flujo Principal</td><td>
                      1. Recibe llave fisica<br/>
                      2. Localiza tarjeta en monitor<br/>
                      3. Presiona boton para recibir<br/>
                      4. Sistema registra con tiempo total<br/>
                      5. Ubica llave en tablero
                    </td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        {/* Seccion 6: Diagramas de Flujo */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            6. Diagramas de Flujo
          </h2>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">6.1 Flujo de Solicitud de Llave</h3>
          <div className="diagram mb-6">{`
                          +-------------+
                          |   INICIO    |
                          +------+------+
                                 |
                                 v
                    +------------------------+
                    | Usuario accede a       |
                    | Terminal (/terminal)   |
                    +------------------------+
                                 |
                                 v
               +----------------------------------+
               | Se identifica con celular o     |
               | email (busqueda en registrados) |
               +----------------------------------+
                       |                |
                   ENCONTRADO       NO ENCONTRADO
                       |                |
                       v                v
              +-----------------+  +-----------------+
              | Seleccion       |  | Presiona boton  |
              | automatica      |  | "Registrarse"   |
              | del usuario     |  | (ver flujo 6.5) |
              +-----------------+  +-----------------+
                       |                |
                       +-------+--------+
                               |
                               v
               +----------------------------------+
               | Busca llave por nombre o        |
               | selecciona de llaves frecuentes |
               | (filtro por tipo y edificio)    |
               +----------------------------------+
                                 |
                                 v
               +----------------------------------+
               | Hora actual entre 7:00 y 23:00? |
               | (o usuario exento?)             |
               +----------------------------------+
                       |                |
                      SI               NO
                       |                |
                       v                v
              +-----------------+  +-----------------+
              | Confirmar       |  | Banner "Horario |
              | seleccion       |  | restringido"    |
              |                 |  | Bloquear envio  |
              +-----------------+  +-----------------+
                       |
                       v
                    +------------------------+
                    | Sistema genera         |
                    | solicitud + sonido     |
                    +------------------------+
                                 |
                                 v
                    +------------------------+
                    | Notificacion enviada   |
                    | a Monitor Vigilancia   |
                    +------------------------+
                                 |
                                 v
                          +-------------+
                          |     FIN     |
                          +-------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">6.2 Flujo de Alerta por Tiempo Excedido</h3>
          <div className="diagram mb-6">{`
                          +-------------+
                          |   INICIO    |
                          +------+------+
                                 |
                                 v
                    +------------------------+
                    | Llave entregada        |
                    | Contador activo        |
                    +------------------------+
                                 |
                                 v
               +----------------------------------+
               | Tiempo >= Limite (2h 15min)?    |
               +----------------------------------+
                      |                |
                     NO               SI
                      |                |
                      v                v
          +-----------------+  +-----------------+
          | Continuar       |  | Activar alerta  |
          | monitoreando    |  | visual (punto   |
          |                 |  | rojo pulsante)  |
          +-----------------+  +-----------------+
                      |                |
                      |                v
                      |     +-----------------+
                      |     | Mostrar boton   |
                      |     | "Enviar WhatsApp"|
                      |     +-----------------+
                      |                |
                      +-------+--------+
                              |
                              v
                        +-------------+
                        |     FIN     |
                        +-------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">6.3 Flujo de Intercambio de Llaves</h3>
          <div className="diagram mb-6">{`
                          +-------------+
                          |   INICIO    |
                          +------+------+
                                 |
                                 v
                    +------------------------+
                    | Usuario B busca llave  |
                    | en Terminal            |
                    +------------------------+
                                 |
                                 v
               +----------------------------------+
               | Llave esta en uso por Usuario A? |
               +----------------------------------+
                      |                |
                     NO               SI
                      |                |
                      v                v
          +-----------------+  +-----------------+
          | Solicitar       |  | Mostrar nombre  |
          | normalmente     |  | de Usuario A +  |
          |                 |  | boton Intercambio|
          +-----------------+  +-----------------+
                                       |
                                       v
                          +------------------------+
                          | Usuario B acepta       |
                          | responsabilidad        |
                          | (checkbox obligatorio) |
                          +------------------------+
                                       |
                                       v
                          +------------------------+
                          | Sistema cierra sesion  |
                          | de Usuario A           |
                          +------------------------+
                                       |
                                       v
                          +------------------------+
                          | Sistema abre sesion    |
                          | para Usuario B         |
                          +------------------------+
                                       |
                                       v
                            +-------------+
                            |     FIN     |
                            +-------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">6.4 Flujo de Restriccion Horaria</h3>
          <div className="diagram mb-6">{`
                          +-------------+
                          |   INICIO    |
                          +------+------+
                                 |
                                 v
                    +------------------------+
                    | Usuario solicita llave |
                    +------------------------+
                                 |
                                 v
               +----------------------------------+
               | Hora actual entre 7:00 y 23:00?  |
               +----------------------------------+
                      |                |
                     SI               NO
                      |                |
                      v                v
          +-----------------+  +-----------------+
          | Procesar        |  | Verificar tipo  |
          | solicitud       |  | de usuario      |
          | normalmente     |  +-----------------+
          +-----------------+          |
                                       v
                          +------------------------+
                          | Es Vigilancia o        |
                          | Servicios Generales?   |
                          +------------------------+
                                 |          |
                                SI         NO
                                 |          |
                                 v          v
                    +-------------+  +-----------------+
                    | Permitir    |  | Mostrar banner  |
                    | solicitud   |  | "No permitido"  |
                    +-------------+  | Bloquear envio  |
                                     +-----------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">6.5 Flujo de Registro de Usuario (con Empresa)</h3>
          <div className="diagram mb-6">{`
                          +-------------+
                          |   INICIO    |
                          +------+------+
                                 |
                                 v
                    +------------------------+
                    | Usuario accede a       |
                    | Terminal y presiona    |
                    | "Registrarse"          |
                    +------------------------+
                                 |
                                 v
                    +------------------------+
                    | Ingresa nombre,        |
                    | celular, email (opc.)  |
                    +------------------------+
                                 |
                                 v
                    +------------------------+
                    | Selecciona tipo de     |
                    | usuario                |
                    +------------------------+
                                 |
                                 v
               +----------------------------------+
               | Tipo seleccionado = "Empresa"?  |
               +----------------------------------+
                      |                |
                     NO               SI
                      |                |
                      v                v
          +-----------------+  +-----------------+
          | Continuar       |  | Mostrar campo   |
          | registro        |  | "Nombre de la   |
          |                 |  |  empresa" (req.) |
          +-----------------+  +-----------------+
                      |                |
                      +-------+--------+
                              |
                              v
                    +------------------------+
                    | Guardar usuario en     |
                    | sistema                |
                    +------------------------+
                              |
                              v
                    +------------------------+
                    | Mostrar toast:         |
                    | "Registrado con exito" |
                    +------------------------+
                              |
                              v
                    +------------------------+
                    | Reiniciar terminal     |
                    | para probar registro   |
                    +------------------------+
                              |
                              v
                        +-------------+
                        |     FIN     |
                        +-------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">6.6 Flujo de Gestion de Usuarios en Agenda</h3>
          <div className="diagram mb-6">{`
                          +-------------+
                          |   INICIO    |
                          +------+------+
                                 |
                                 v
                    +------------------------+
                    | Vigilante abre modulo  |
                    | "Agenda" en Monitor    |
                    +------------------------+
                                 |
                                 v
                    +------------------------+
                    | Buscar usuario por     |
                    | nombre/tel/email/empresa|
                    +------------------------+
                                 |
                                 v
               +----------------------------------+
               | Accion deseada?                  |
               +----------------------------------+
                  |          |           |
                EDITAR    ELIMINAR    CONSULTAR
                  |          |           |
                  v          v           v
          +----------+  +----------+  +----------+
          | Formulario|  | Confirmar|  | Mostrar  |
          | inline de |  | elimina- |  | datos de |
          | edicion   |  | cion     |  | contacto |
          +----------+  +----------+  +----------+
                  |          |           |
                  v          v           |
          +----------+  +----------+    |
          | Guardar  |  | Eliminar |    |
          | cambios  |  | registro |    |
          +----------+  +----------+    |
                  |          |           |
                  +----+-----+-----------+
                       |
                       v
                 +-------------+
                 |     FIN     |
                 +-------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">6.7 Flujo de Notificaciones Sonoras</h3>
          <div className="diagram mb-6">{`
                          +-------------+
                          |   EVENTO    |
                          +------+------+
                                 |
                                 v
               +----------------------------------+
               | Tipo de evento?                  |
               +----------------------------------+
                  |            |            |
              SOLICITUD    ENTREGA    DEVOLUCION
                  |            |            |
                  v            v            v
          +----------+  +----------+  +----------+
          | Doble    |  | Ding     |  | Triple   |
          | campana  |  | descend. |  | campana  |
          | ascend.  |  | unico    |  | ascend.  |
          |          |  | x vigil. |  | x vigil. |
          +----------+  +----------+  +----------+
                  |            |            |
                  +-----+------+-----+------+
                        |            |
                        v            v
               +-------------+  +----------+
               | Silenciado? |  | Ajustar  |
               | (muted)     |  | volumen  |
               +-------------+  +----------+
                     |
                    SI -> No reproducir
                     NO -> Reproducir sonido
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">6.8 Flujo de Verificacion de Autorizaciones</h3>
          <div className="diagram mb-6">{`
                          +-------------+
                          |   INICIO    |
                          +------+------+
                                 |
                                 v
                    +------------------------+
                    | Vigilante abre modulo  |
                    | "Agenda/Autorizaciones"|
                    +------------------------+
                                 |
                                 v
                    +------------------------+
                    | Sistema purga          |
                    | autorizaciones vencidas|
                    | (fechaHasta < hoy)     |
                    +------------------------+
                                 |
                                 v
                    +------------------------+
                    | Vigilante escribe      |
                    | nombre o lugar         |
                    +------------------------+
                                 |
                                 v
               +----------------------------------+
               | Busqueda inteligente en         |
               | tiempo real (filtrado parcial)  |
               +----------------------------------+
                                 |
                                 v
               +----------------------------------+
               | Se encontraron resultados?       |
               +----------------------------------+
                      |                |
                     SI               NO
                      |                |
                      v                v
            +-----------------+  +-----------------+
            | Mostrar         |  | Mostrar "No se  |
            | autorizaciones  |  | encontro        |
            | con editar/     |  | autorizacion"   |
            | eliminar        |  +-----------------+
            +-----------------+
                      |
                      v
               +----------------------------------+
               | Accion deseada?                  |
               +----------------------------------+
                  |          |           |
                EDITAR    ELIMINAR    CONSULTAR
                  |          |           |
                  v          v           v
          +----------+  +----------+  +----------+
          | Formulario|  | Confirmar|  | Ver      |
          | edicion   |  | elimina- |  | detalles |
          | precargado|  | cion     |  | vigencia |
          +----------+  +----------+  +----------+
                  |          |           |
                  +----+-----+-----------+
                       |
                       v
                 +-------------+
                 |     FIN     |
                 +-------------+
          `}</div>
        </div>


        {/* Seccion 7: Interfaces de Usuario */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            7. Interfaces de Usuario
          </h2>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">7.1 Terminal de Usuario</h3>
          <p className="text-gray-700 mb-4">
            El Terminal de Usuario es la interfaz publica donde los docentes, alumnos, personal TAS y empresas solicitan las llaves. Los usuarios se identifican ingresando su celular o email en un campo de busqueda. Si no estan registrados, pueden hacerlo mediante el boton "Registrarse".
          </p>
          <div className="diagram mb-6">{`
+------------------------------------------------------------------+
|  [Logo FCEA]        TERMINAL DE LLAVES           [Hora: 14:35]   |
+------------------------------------------------------------------+
|                                                                   |
|  +------------------------------------------------------------+  |
|  |              IDENTIFICACION DE USUARIO                      |  |
|  +------------------------------------------------------------+  |
|  |  [Ingrese su celular o email...     ]  [Registrarse]        |  |
|  |  (busca en usuarios registrados por celular/email)          |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  | LLAVES FRECUENTES (basadas en historial del usuario):       |  |
|  | +----------+ +----------+ +----------+ +----------+         |  |
|  | | Salon 101| | Ofi.Conc | | Sala Prof| | Auditor. |         |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  |                    BUSQUEDA DE LLAVES                       |  |
|  +------------------------------------------------------------+  |
|  |  [Buscar llave...] Tipo:[Todos v] Edificio:[Todos v]       |  |
|  |                                                             |  |
|  |  Salon 101 [Disponible]  Salon 102 [Disponible]            |  |
|  |  Salon 201 [En uso por: Maria Lopez] [Intercambiar]        |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  | [!] Banner restriccion horaria (si aplica, 23:00-07:00)    |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  | CONFIRMACION: 2 llaves seleccionadas  [Enviar] [Cancelar]  |  |
|  +------------------------------------------------------------+  |
|                                                                   |
+------------------------------------------------------------------+
          `}</div>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">7.2 Monitor de Vigilancia</h3>
          <p className="text-gray-700 mb-4">
            El Monitor de Vigilancia es la interfaz principal para el personal de seguridad.
          </p>

          <h4 className="font-semibold text-gray-800 mt-4 mb-2">Estados Visuales</h4>
          <table className="mb-6">
            <thead>
              <tr>
                <th>Estado</th>
                <th>Indicador Visual</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>Solicitud pendiente</td><td>Borde amarillo/naranja</td></tr>
              <tr><td>Llave en uso (normal)</td><td>Fondo rosa, borde rosa</td></tr>
              <tr><td>Llave en uso (tiempo excedido)</td><td>Punto rojo pulsante + boton WhatsApp (solo Salones y Salones Hibridos)</td></tr>
              <tr><td>Llave devuelta</td><td>Fondo verde, borde verde</td></tr>
              <tr><td>Intercambio de llave</td><td>Badge "Intercambio" + nombre del usuario anterior</td></tr>
              <tr><td>Opcion deshacer disponible</td><td>Barra de progreso con cuenta regresiva (2 minutos)</td></tr>
              <tr><td>Vigilante jefe de turno</td><td>Punto de color junto al nombre</td></tr>
              <tr><td>Vigilante en licencia</td><td>No aparece en botones de entrega/devolucion; visible en Dashboard con icono</td></tr>
              <tr><td>Nueva solicitud recibida</td><td>Señal sonora de doble campana ascendente</td></tr>
              <tr><td>Entrega de llave</td><td>Sonido unico del vigilante (ding descendente con frecuencia personalizada)</td></tr>
              <tr><td>Devolucion de llave</td><td>Triple campana ascendente del vigilante receptor</td></tr>
              <tr><td>Autorizacion vigente</td><td>Badge verde con nombre del lugar autorizado</td></tr>
              <tr><td>Autorizacion proxima a vencer</td><td>Badge "Vence pronto" con icono de alerta</td></tr>
              <tr><td>Restriccion horaria activa</td><td>Banner rojo con mensaje y bloqueo del boton de envio</td></tr>
            </tbody>
          </table>
        </div>

        {/* Seccion 8: Capturas de Pantalla */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            8. Capturas de Pantalla del Sistema
          </h2>

          <p className="text-gray-700 mb-6">
            Esta seccion presenta capturas de pantalla reales de cada modulo del sistema, proporcionando una vision concreta de la interfaz de usuario implementada.
          </p>

          <div className="space-y-8">
            <div className="border rounded-lg overflow-hidden">
              <div className="bg-gray-100 px-4 py-2 font-semibold">Figura 8.1: Terminal de Usuario</div>
              <div className="p-4">
                <img 
                  src={terminalScreenshot} 
                  alt="Terminal de Usuario" 
                  className="w-full rounded border shadow-sm"
                />
                <p className="text-sm text-gray-600 mt-2">
                  Interfaz del Terminal de Usuario mostrando campo de busqueda, selector de edificio y panel de llaves seleccionadas.
                </p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-gray-100 px-4 py-2 font-semibold">Figura 8.2: Monitor de Vigilancia</div>
              <div className="p-4">
                <img 
                  src={monitorScreenshot} 
                  alt="Monitor de Vigilancia" 
                  className="w-full rounded border shadow-sm"
                />
                <p className="text-sm text-gray-600 mt-2">
                  Interfaz del Monitor de Vigilancia con cola de solicitudes pendientes y seccion de llaves en uso.
                </p>
              </div>
            </div>

            <div className="border rounded-lg overflow-hidden">
              <div className="bg-gray-100 px-4 py-2 font-semibold">Figura 8.3: Dashboard Estadistico</div>
              <div className="p-4">
                <img 
                  src={dashboardScreenshot} 
                  alt="Dashboard Estadistico" 
                  className="w-full rounded border shadow-sm"
                />
                <p className="text-sm text-gray-600 mt-2">
                  Interfaz del Dashboard mostrando KPIs principales, estadisticas por turno y rendimiento de vigilantes.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Seccion 9: Seguridad */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            9. Seguridad y Control de Acceso
          </h2>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">9.1 Modelo de Seguridad Actual</h3>
          <p className="text-gray-700 mb-4">
            El sistema actualmente opera bajo un modelo de seguridad basado en confianza:
          </p>
          <ul className="list-disc list-inside text-gray-700 mb-4 space-y-1 pl-4">
            <li>Acceso abierto al terminal de usuario (autoservicio)</li>
            <li>Acceso al monitor restringido a personal de vigilancia (por ubicacion fisica)</li>
            <li>Dashboard disponible para personal administrativo autorizado</li>
            <li>No requiere autenticacion con credenciales</li>
          </ul>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">9.2 Trazabilidad</h3>
          <p className="text-gray-700 mb-4">El sistema mantiene trazabilidad completa de:</p>
          <ul className="list-disc list-inside text-gray-700 mb-4 space-y-1 pl-4">
            <li>Quien solicito cada llave (nombre, celular, tipo de usuario)</li>
            <li>Quien entrego la llave (vigilante responsable)</li>
            <li>Quien recibio la devolucion (vigilante responsable)</li>
            <li>Timestamps exactos de cada operacion</li>
            <li>Tiempo total de uso de cada llave</li>
          </ul>

          <h3 className="text-xl font-semibold text-gray-800 mt-6 mb-3">9.3 Mejoras Futuras Recomendadas</h3>
          <ul className="list-disc list-inside text-gray-700 mb-4 space-y-1 pl-4">
            <li>Implementacion de autenticacion con credenciales institucionales</li>
            <li>Roles y permisos diferenciados</li>
            <li>Auditoria de accesos al sistema</li>
            <li>Encriptacion de datos sensibles</li>
            <li>Backup automatico en la nube</li>
          </ul>
        </div>

        {/* Seccion 10: Glosario */}
        <div className="page-break print-section mb-12">
          <h2 className="text-2xl font-bold text-blue-900 border-b-2 border-blue-900 pb-2 mb-6">
            10. Glosario
          </h2>

          <table>
            <thead>
              <tr>
                <th>Termino</th>
                <th>Definicion</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>Cola de Solicitudes</td><td>Lista ordenada de peticiones de llaves pendientes de atencion</td></tr>
              <tr><td>Dashboard</td><td>Panel de control con visualizaciones estadisticas por turno y por vigilante</td></tr>
              <tr><td>Deshacer</td><td>Funcion para revertir una entrega o devolucion dentro de los 2 minutos siguientes</td></tr>
              <tr><td>Intercambio</td><td>Transferencia directa de una llave entre usuarios sin devolucion al mostrador, con aceptacion de responsabilidad</td></tr>
              <tr><td>Jefe de Turno</td><td>Vigilante designado como responsable durante un turno especifico, indicado visualmente</td></tr>
              <tr><td>Llaves Frecuentes</td><td>Sugerencias personalizadas basadas en el historial de uso de cada usuario registrado</td></tr>
              <tr><td>localStorage</td><td>Mecanismo de almacenamiento del navegador para persistencia de datos (usuarios, vigilantes, configuracion, autorizaciones)</td></tr>
              <tr><td>Monitor</td><td>Interfaz de vigilancia para gestion de entregas, devoluciones, intercambios, agenda y autorizaciones</td></tr>
              <tr><td>Responsivo</td><td>Diseño que se adapta a diferentes tamaños de pantalla</td></tr>
              <tr><td>Tablero</td><td>Panel fisico donde se almacenan las llaves organizadas por filas y columnas. Existen tres tipos: Principal, Copias y Jefes</td></tr>
              <tr><td>Terminal</td><td>Punto de acceso donde usuarios se identifican por celular/email y solicitan llaves</td></tr>
              <tr><td>Tiempo Excedido</td><td>Condicion cuando una llave de tipo Salon o Salon Hibrido supera el tiempo limite configurado (por defecto 2h 15min)</td></tr>
              <tr><td>Transicion</td><td>Periodo de superposicion entre turnos saliente y entrante, configurable en minutos</td></tr>
              <tr><td>Turno</td><td>Periodo de trabajo: Matutino (06:00-14:00), Vespertino (14:00-22:00), Nocturno (22:00-06:00)</td></tr>
              <tr><td>Agenda</td><td>Modulo de busqueda, edicion y eliminacion de contactos registrados para consulta rapida por vigilantes</td></tr>
              <tr><td>Notas</td><td>Campo de texto libre en cada llave entregada para registrar observaciones del vigilante</td></tr>
              <tr><td>Restriccion Horaria</td><td>Politica que impide solicitar llaves antes de las 7:00 AM y despues de las 23:00 PM, excepto para vigilancia y servicios generales</td></tr>
              <tr><td>Licencia</td><td>Estado de ausencia temporal de un vigilante: licencia (vacaciones/personal) o licencia medica. Los vigilantes en licencia no aparecen en botones de entrega/devolucion</td></tr>
              <tr><td>Notificacion Sonora</td><td>Señal acustica generada via Web Audio API: doble campana (nueva solicitud), ding unico por vigilante (entrega), triple campana por vigilante (devolucion)</td></tr>
              <tr><td>Autorizacion Temporal</td><td>Permiso registrado que habilita a una persona a retirar llaves de un lugar especifico, con vigencia opcional (desde-hasta) y purga automatica</td></tr>
              <tr><td>Busqueda Inteligente</td><td>Filtrado en tiempo real insensible a acentos (normalizacion NFD) que muestra coincidencias parciales a medida que el usuario escribe</td></tr>
              <tr><td>Purga Automatica</td><td>Eliminacion automatica de autorizaciones cuya fecha de finalizacion (fechaHasta) es anterior a la fecha actual</td></tr>
              <tr><td>Usuario Registrado</td><td>Persona que completo el formulario de registro con nombre, celular/email, tipo y datos opcionales (departamento TAS o nombre empresa)</td></tr>
              <tr><td>Web Audio API</td><td>API del navegador utilizada para generar sonidos programaticos sin archivos de audio externos</td></tr>
            </tbody>
          </table>
        </div>

        {/* Pie de pagina del documento */}
        <div className="border-t-2 border-gray-300 pt-8 mt-12 text-center text-gray-600">
          <p className="font-semibold">Sistema de Gestion de Llaves - FCEA UdelaR</p>
          <p className="text-sm">Documento de Especificacion de Requisitos de Software - Version 4.3</p>
          <p className="text-sm">8 de Marzo de 2026</p>
        </div>
      </div>
    </div>
  );
};

export default SRSDocument;
