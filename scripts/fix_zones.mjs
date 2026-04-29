/**
 * Script to add missing fields (zona, tablero, es_hibrido) to PocketBase 'lugares' collection
 * and populate them from the static fceaData.ts data by matching on nombre.
 */

const PB_URL = 'http://127.0.0.1:8090';

// Static data from fceaData.ts - mapping nombre -> { zona, tablero, es_hibrido, fila, columna }
const lugaresData = [
  { nombre: 'Intendencia', zona: 'Puerta izquierda', fila: 1, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'UGE', zona: 'Puerta izquierda', fila: 1, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Servicios.Generles', zona: 'Puerta izquierda', fila: 1, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Mantenimiento', zona: 'Puerta izquierda', fila: 1, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Reproducciones', zona: 'Puerta izquierda', fila: 1, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Electrotécnia', zona: 'Puerta izquierda', fila: 1, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Puerta vigilancia', zona: 'Puerta izquierda', fila: 1, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'entrada', zona: 'Puerta izquierda', fila: 2, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'salida patio subsuelo', zona: 'Puerta izquierda', fila: 2, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'depósito', zona: 'Puerta izquierda', fila: 2, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala de lectura', zona: 'Puerta izquierda', fila: 2, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Pasaje sale de lectura a biblioteca', zona: 'Puerta izquierda', fila: 2, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Entrepiso Biblioteca', zona: 'Puerta izquierda', fila: 2, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala A', zona: 'Puerta izquierda', fila: 2, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Decanato', zona: 'Puerta izquierda', fila: 3, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala consejo', zona: 'Puerta izquierda', fila: 3, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Oficina decano', zona: 'Puerta izquierda', fila: 3, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Decanato interior', zona: 'Puerta izquierda', fila: 3, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Comunicaciones', zona: 'Puerta izquierda', fila: 3, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Asistencia académica', zona: 'Puerta izquierda', fila: 3, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Cavida', zona: 'Puerta izquierda', fila: 3, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Decanato a sala de consejo', zona: 'Puerta izquierda', fila: 3, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Recrea subsuelo entrada', zona: 'Puerta izquierda', fila: 3, columna: 'I', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Archivo Area de recreación', zona: 'Puerta izquierda', fila: 3, columna: 'J', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Depósito cecea', zona: 'Puerta izquierda', fila: 3, columna: 'K', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Bedelía', zona: 'Puerta izquierda', fila: 4, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sistemas', zona: 'Puerta izquierda', fila: 4, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sistemas 21', zona: 'Puerta izquierda', fila: 4, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Apoyo docente', zona: 'Puerta izquierda', fila: 4, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Extensión UEAM', zona: 'Puerta izquierda', fila: 4, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Compras', zona: 'Puerta izquierda', fila: 4, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baños nuevos funcionarios', zona: 'Puerta izquierda', fila: 4, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Archivo', zona: 'Puerta izquierda', fila: 5, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala comisiones', zona: 'Puerta izquierda', fila: 5, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Comisiones reguladora', zona: 'Puerta izquierda', fila: 5, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Pasaje sala comisiones', zona: 'Puerta izquierda', fila: 5, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Consejo y suministros', zona: 'Puerta izquierda', fila: 5, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Suministros', zona: 'Puerta izquierda', fila: 5, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Dirección TAS', zona: 'Puerta izquierda', fila: 5, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Personal TAS', zona: 'Puerta izquierda', fila: 5, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Concursos', zona: 'Puerta izquierda', fila: 5, columna: 'I', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'CECEA', zona: 'Puerta izquierda', fila: 5, columna: 'J', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Rendiciones', zona: 'Puerta izquierda', fila: 6, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Contaduría', zona: 'Puerta izquierda', fila: 6, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sueldos', zona: 'Puerta izquierda', fila: 6, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Gastos', zona: 'Puerta izquierda', fila: 6, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Convenios', zona: 'Puerta izquierda', fila: 6, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Personal docente', zona: 'Puerta izquierda', fila: 6, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Reja ventana investigadores', zona: 'Puerta izquierda', fila: 6, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Bajo escalera patio EIP', zona: 'Puerta izquierda', fila: 6, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  // Puerta derecha
  { nombre: 'Entrada facultad', zona: 'Puerta derecha', fila: 1, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Entrada eduardo acevedo', zona: 'Puerta derecha', fila: 1, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Portón MSP', zona: 'Puerta derecha', fila: 1, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Azotea', zona: 'Puerta derecha', fila: 1, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Buhardilla', zona: 'Puerta derecha', fila: 1, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Patio cantina', zona: 'Puerta derecha', fila: 1, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Cortina aulario', zona: 'Puerta derecha', fila: 2, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Porta rollos baños iesta', zona: 'Puerta derecha', fila: 2, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Bicicletas', zona: 'Puerta derecha', fila: 2, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Patio reja invesigadores', zona: 'Puerta derecha', fila: 2, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Reja exterior lactancia', zona: 'Puerta derecha', fila: 2, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Reja exterior eduardo acevedo jaula', zona: 'Puerta derecha', fila: 3, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Salida patio 11-12d', zona: 'Puerta derecha', fila: 3, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Patio bicicletas', zona: 'Puerta derecha', fila: 3, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baños salón 5', zona: 'Puerta derecha', fila: 3, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Tableros', zona: 'Puerta derecha', fila: 3, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Descanso cooperativa', zona: 'Puerta derecha', fila: 3, columna: 'I', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Lactancia manojo', zona: 'Puerta derecha', fila: 4, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Lactancia vestuarios', zona: 'Puerta derecha', fila: 4, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño Hall cantina', zona: 'Puerta derecha', fila: 4, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Duchas vestuarios subsuelo', zona: 'Puerta derecha', fila: 4, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baños subsuelo', zona: 'Puerta derecha', fila: 4, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Porta rollo', zona: 'Puerta derecha', fila: 4, columna: 'I', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño PA informática', zona: 'Puerta derecha', fila: 5, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baños IESTA', zona: 'Puerta derecha', fila: 5, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baños AM', zona: 'Puerta derecha', fila: 5, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño salón 23 privado', zona: 'Puerta derecha', fila: 5, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño salón 23 lisiado', zona: 'Puerta derecha', fila: 5, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño salón 23 hombres', zona: 'Puerta derecha', fila: 5, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño salón 23 damas', zona: 'Puerta derecha', fila: 5, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño salón 6', zona: 'Puerta derecha', fila: 6, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño salón 7', zona: 'Puerta derecha', fila: 6, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baño salón 8', zona: 'Puerta derecha', fila: 6, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baños vigilancia', zona: 'Puerta derecha', fila: 6, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baños decanato hombres', zona: 'Puerta derecha', fila: 6, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Baños decanato damas', zona: 'Puerta derecha', fila: 6, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  // Lateral izquierdo
  { nombre: 'Accesos EIP manojo', zona: 'Lateral izquierdo', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Oficinas y secretaría EIP 205-201', zona: 'Lateral izquierdo', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Oficinas EIP 301-315', zona: 'Lateral izquierdo', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Oficinas EIP 302-316', zona: 'Lateral izquierdo', tablero: 'Tablero Principal', es_hibrido: false },
  // Lateral derecho
  { nombre: 'Matemáticas', zona: 'Lateral derecho', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'CGU', zona: 'Lateral derecho', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Recreación sala 1', zona: 'Lateral derecho', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Recreación entrada', zona: 'Lateral derecho', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Recreación sala 2', zona: 'Lateral derecho', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Recreación sala 3', zona: 'Lateral derecho', tablero: 'Tablero Principal', es_hibrido: false },
  // Fondo fila 1
  { nombre: 'Affur', zona: 'Fondo', fila: 1, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Ascensor américa', zona: 'Fondo', fila: 1, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Traba ascensor EIP', zona: 'Fondo', fila: 1, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Pulsadores Isai', zona: 'Fondo', fila: 1, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Bomba de agua patio', zona: 'Fondo', fila: 1, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Bomba de incendio', zona: 'Fondo', fila: 1, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Contadores ose jackson', zona: 'Fondo', fila: 1, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Medidor de ute', zona: 'Fondo', fila: 1, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Depósito garrafas', zona: 'Fondo', fila: 1, columna: 'I', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Camioneta', zona: 'Fondo', fila: 1, columna: 'J', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Mueble objetos perdidos', zona: 'Fondo', fila: 1, columna: 'Q', tablero: 'Tablero Principal', es_hibrido: false },
  // Fondo fila 2
  { nombre: 'Investigadores entrada oficinas', zona: 'Fondo', fila: 2, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores baños', zona: 'Fondo', fila: 2, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 1', zona: 'Fondo', fila: 2, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 2', zona: 'Fondo', fila: 2, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 3', zona: 'Fondo', fila: 2, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 4', zona: 'Fondo', fila: 2, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 5', zona: 'Fondo', fila: 2, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 6', zona: 'Fondo', fila: 2, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 7', zona: 'Fondo', fila: 2, columna: 'I', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 8', zona: 'Fondo', fila: 2, columna: 'J', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 9', zona: 'Fondo', fila: 2, columna: 'Q', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Investigadores of 10', zona: 'Fondo', fila: 2, columna: 'K', tablero: 'Tablero Principal', es_hibrido: false },
  // Fondo fila 3
  { nombre: 'Sala de navegación entrada', zona: 'Fondo', fila: 3, columna: 'A', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala de navegación box 1', zona: 'Fondo', fila: 3, columna: 'B', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala de navegación box 2', zona: 'Fondo', fila: 3, columna: 'C', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala de navegación box 3', zona: 'Fondo', fila: 3, columna: 'D', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala de navegación box 4', zona: 'Fondo', fila: 3, columna: 'E', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Sala de navegación box 5', zona: 'Fondo', fila: 3, columna: 'F', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Bloomberg', zona: 'Fondo', fila: 3, columna: 'G', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Informática', zona: 'Fondo', fila: 3, columna: 'H', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'UPC', zona: 'Fondo', fila: 3, columna: 'I', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'UAE', zona: 'Fondo', fila: 3, columna: 'J', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Multimedia', zona: 'Fondo', fila: 3, columna: 'Q', tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Lockers pruebas sala docente', zona: 'Fondo', fila: 3, columna: 'K', tablero: 'Tablero Principal', es_hibrido: false },
  // Fondo fila 4 - Salones
  { nombre: 'Salónes 1,2,3,5', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Salón 4', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Salón 6', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Salón 7', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Salón 8', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Salón 9', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Salón 10', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Salón 11-12', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Salones 14,15,16', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Salón 18', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'salón 19', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Salón 20', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Salo1-nes 21-25', zona: 'Fondo', fila: 4, tablero: 'Tablero Principal', es_hibrido: true },
  // Fondo fila 5 - Equipos
  { nombre: 'Equipos AM', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos VIP', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 2', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 3', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 5', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 6', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Equipos 7', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Equipos 8', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Equipos 10', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 11', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 12', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 14', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Equipos 15', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Equipos 16', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Equipos 18', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 19', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 20', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 21', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 22', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Equipos 23', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Equipos 24', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  { nombre: 'Equipos 25', zona: 'Fondo', fila: 5, tablero: 'Tablero Principal', es_hibrido: true },
  // Fondo fila 6 - IESTA
  { nombre: 'Iesta sala 17', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 18', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 19', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 20 20.a-20.b-20.c', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 21 21.a-21.b-21.c', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 22', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 23-23.a-23.b-23.c', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 24', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 25', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Iesta sala 27', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
  { nombre: 'Depósito de máquinas', zona: 'Fondo', fila: 6, tablero: 'Tablero Principal', es_hibrido: false },
];

// Build lookup by nombre (lowercase)
const lookup = {};
for (const l of lugaresData) {
  lookup[l.nombre.toLowerCase()] = l;
}

async function addFieldsToSchema() {
  // First, check if zona field already exists by trying to get schema
  try {
    const res = await fetch(`${PB_URL}/api/collections/lugares`);
    const col = await res.json();
    const existingFields = col.schema.map(f => f.name);
    
    const fieldsToAdd = [];
    if (!existingFields.includes('zona')) {
      fieldsToAdd.push({ name: 'zona', type: 'text', required: false });
    }
    if (!existingFields.includes('tablero')) {
      fieldsToAdd.push({ name: 'tablero', type: 'text', required: false });
    }
    if (!existingFields.includes('es_hibrido')) {
      fieldsToAdd.push({ name: 'es_hibrido', type: 'bool', required: false });
    }
    
    if (fieldsToAdd.length > 0) {
      const newSchema = [...col.schema, ...fieldsToAdd];
      const updateRes = await fetch(`${PB_URL}/api/collections/lugares`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ schema: newSchema }),
      });
      if (updateRes.ok) {
        console.log(`✅ Added fields: ${fieldsToAdd.map(f=>f.name).join(', ')}`);
      } else {
        const err = await updateRes.text();
        console.error('❌ Error adding fields:', err);
        return false;
      }
    } else {
      console.log('ℹ️  All fields already exist');
    }
    return true;
  } catch (e) {
    console.error('❌ Error accessing PocketBase:', e.message);
    return false;
  }
}

async function updateRecords() {
  let page = 1;
  let updated = 0;
  let notFound = 0;
  
  while (true) {
    const res = await fetch(`${PB_URL}/api/collections/lugares/records?page=${page}&perPage=50`);
    const data = await res.json();
    
    for (const record of data.items) {
      const match = lookup[record.nombre.toLowerCase()];
      if (match) {
        const update = {
          zona: match.zona,
          tablero: match.tablero || 'Tablero Principal',
          es_hibrido: match.es_hibrido || false,
        };
        
        const upRes = await fetch(`${PB_URL}/api/collections/lugares/records/${record.id}`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(update),
        });
        
        if (upRes.ok) {
          updated++;
        } else {
          console.error(`  ❌ Failed to update ${record.nombre}`);
        }
      } else {
        notFound++;
        console.log(`  ⚠️  No match for: "${record.nombre}"`);
      }
    }
    
    if (page >= data.totalPages) break;
    page++;
  }
  
  console.log(`\n✅ Updated ${updated} records`);
  if (notFound > 0) console.log(`⚠️  ${notFound} records had no match (can be fixed manually via Modificar)`);
}

async function main() {
  console.log('🔧 Adding missing fields to PocketBase schema...');
  const ok = await addFieldsToSchema();
  if (!ok) return;
  
  console.log('\n📝 Updating records with zone data...');
  await updateRecords();
  
  console.log('\n✅ Done! Refresh the app to see updated zones.');
}

main();
