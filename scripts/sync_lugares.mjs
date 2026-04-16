// Script to sync lugares from fceaData.ts to PocketBase
// Run with: node scripts/sync_lugares.mjs

const PB_URL = 'http://127.0.0.1:8090';

const lugares = [
  { nombre: 'Intendencia', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'UGE', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Servicios.Generles', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Mantenimiento', tipo: 'Taller', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Reproducciones', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Electrotécnia', tipo: 'Taller', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Puerta vigilancia', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'entrada', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'salida patio subsuelo', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'depósito', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Sala de lectura', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Pasaje sale de lectura a biblioteca', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Entrepiso Biblioteca', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Sala A', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Decanato', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'Sala consejo', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Oficina decano', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Decanato interior', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Comunicaciones', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Asistencia académica', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Cavida', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Decanato a sala de consejo', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Recrea subsuelo entrada', tipo: 'Recreación', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'I', disponible: true, es_hibrido: false },
  { nombre: 'Archivo Area de recreación', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'J', disponible: true, es_hibrido: false },
  { nombre: 'Depósito cecea', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'K', disponible: true, es_hibrido: false },
  { nombre: 'Bedelía', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'Sistemas', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Sistemas 21', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Apoyo docente', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Extensión UEAM', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Compras', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Baños nuevos funcionarios', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Archivo', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'Sala comisiones', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Comisiones reguladora', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Pasaje sala comisiones', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Consejo y suministros', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Suministros', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Dirección TAS', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Personal TAS', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Concursos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'I', disponible: true, es_hibrido: false },
  { nombre: 'CECEA', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'J', disponible: true, es_hibrido: false },
  { nombre: 'Rendiciones', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'Contaduría', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Sueldos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Gastos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Convenios', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Personal docente', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Reja ventana investigadores', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Bajo escalera patio EIP', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'H', disponible: true, es_hibrido: false },
  // Puerta derecha
  { nombre: 'Entrada facultad', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Entrada eduardo acevedo', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Portón MSP', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Azotea', tipo: 'Área Común', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Buhardilla', tipo: 'Área Común', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Patio cantina', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Cortina aulario', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Porta rollos baños iesta', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Bicicletas', tipo: 'Espacio Común', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Patio reja invesigadores', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Reja exterior lactancia', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Reja exterior eduardo acevedo jaula', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Salida patio 11-12d', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Patio bicicletas', tipo: 'Espacio Común', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Baños salón 5', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Tableros', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Descanso cooperativa', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'I', disponible: true, es_hibrido: false },
  { nombre: 'Lactancia manojo', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Lactancia vestuarios', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Baño Hall cantina', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Duchas vestuarios subsuelo', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Baños subsuelo', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Porta rollo', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'I', disponible: true, es_hibrido: false },
  { nombre: 'Baño PA informática', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Baños IESTA', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Baños AM', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Baño salón 23 privado', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Baño salón 23 lisiado', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Baño salón 23 hombres', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Baño salón 23 damas', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Baño salón 6', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Baño salón 7', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Baño salón 8', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Baños vigilancia', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Baños decanato hombres', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Baños decanato damas', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'G', disponible: true, es_hibrido: false },
  // Lateral izquierdo
  { nombre: 'Accesos EIP manojo', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral izquierdo', fila: null, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Oficinas y secretaría EIP 205-201', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral izquierdo', fila: null, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Oficinas EIP 301-315', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral izquierdo', fila: null, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Oficinas EIP 302-316', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral izquierdo', fila: null, columna: null, disponible: true, es_hibrido: false },
  // Lateral derecho
  { nombre: 'Matemáticas', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', fila: null, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'CGU', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', fila: null, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Recreación sala 1', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', fila: null, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Recreación entrada', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', fila: null, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Recreación sala 2', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', fila: null, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Recreación sala 3', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', fila: null, columna: null, disponible: true, es_hibrido: false },
  // Fondo filas 1-3
  { nombre: 'Affur', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'Ascensor américa', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Traba ascensor EIP', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Pulsadores Isai', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Bomba de agua patio', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Bomba de incendio', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Contadores ose jackson', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Medidor de ute', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Depósito garrafas', tipo: 'Depósito', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'I', disponible: true, es_hibrido: false },
  { nombre: 'Camioneta', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'J', disponible: true, es_hibrido: false },
  { nombre: 'Mueble objetos perdidos', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'Q', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores entrada oficinas', tipo: 'Acceso', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores baños', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 1', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 2', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 3', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 4', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 5', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 6', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 7', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'I', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 8', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'J', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 9', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'Q', disponible: true, es_hibrido: false },
  { nombre: 'Investigadores of 10', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'K', disponible: true, es_hibrido: false },
  { nombre: 'Sala de navegación entrada', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'A', disponible: true, es_hibrido: false },
  { nombre: 'Sala de navegación box 1', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'B', disponible: true, es_hibrido: false },
  { nombre: 'Sala de navegación box 2', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'C', disponible: true, es_hibrido: false },
  { nombre: 'Sala de navegación box 3', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'D', disponible: true, es_hibrido: false },
  { nombre: 'Sala de navegación box 4', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'E', disponible: true, es_hibrido: false },
  { nombre: 'Sala de navegación box 5', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'F', disponible: true, es_hibrido: false },
  { nombre: 'Bloomberg', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'G', disponible: true, es_hibrido: false },
  { nombre: 'Informática', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'H', disponible: true, es_hibrido: false },
  { nombre: 'UPC', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'I', disponible: true, es_hibrido: false },
  { nombre: 'UAE', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'J', disponible: true, es_hibrido: false },
  { nombre: 'Multimedia', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'Q', disponible: true, es_hibrido: false },
  { nombre: 'Lockers pruebas sala docente', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'K', disponible: true, es_hibrido: false },
  // Fondo fila 4 - Salones (solo fila, sin columna)
  { nombre: 'Salónes 1,2,3,5', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Salón 4', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Salón 6', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Salón 7', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Salón 8', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Salón 9', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Salón 10', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Salón 11-12', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Salones 14,15,16', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Salón 18', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'salón 19', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Salón 20', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Salones 21-25', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, columna: null, disponible: true, es_hibrido: true },
  // Fondo fila 5 - Equipos
  { nombre: 'Equipos AM', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos VIP', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 2', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 3', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 5', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 6', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Equipos 7', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Equipos 8', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Equipos 10', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 11', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 12', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 14', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Equipos 15', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Equipos 16', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Equipos 18', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 19', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 20', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 21', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 22', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Equipos 23', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Equipos 24', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  { nombre: 'Equipos 25', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, columna: null, disponible: true, es_hibrido: true },
  // Fondo fila 6 - IESTA
  { nombre: 'Iesta sala 17', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 18', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 19', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 20 20.a-20.b-20.c', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 21 21.a-21.b-21.c', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 22', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 23-23.a-23.b-23.c', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 24', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 25', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Iesta sala 27', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
  { nombre: 'Depósito de máquinas', tipo: 'Depósito', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, columna: null, disponible: true, es_hibrido: false },
];

async function main() {
  console.log(`Connecting to PocketBase at ${PB_URL}...`);
  
  // Step 1: Get all existing lugares
  console.log('Step 1: Fetching existing lugares...');
  const existingRes = await fetch(`${PB_URL}/api/collections/lugares/records?perPage=500`);
  if (!existingRes.ok) {
    console.error('Failed to fetch existing lugares:', existingRes.status, await existingRes.text());
    process.exit(1);
  }
  const existingData = await existingRes.json();
  console.log(`Found ${existingData.items.length} existing records.`);
  
  // Step 2: Delete all existing records
  console.log('Step 2: Deleting all existing records...');
  for (const item of existingData.items) {
    const delRes = await fetch(`${PB_URL}/api/collections/lugares/records/${item.id}`, { method: 'DELETE' });
    if (!delRes.ok) {
      console.error(`Failed to delete record ${item.id}:`, delRes.status);
    }
  }
  console.log('All existing records deleted.');
  
  // Step 3: Insert new records
  console.log(`Step 3: Inserting ${lugares.length} new records...`);
  let inserted = 0;
  for (const lugar of lugares) {
    const body = {
      nombre: lugar.nombre,
      tipo: lugar.tipo,
      edificio: lugar.edificio,
      tablero: lugar.tablero,
      zona: lugar.zona,
      fila: lugar.fila || '',
      columna: lugar.columna || '',
      disponible: lugar.disponible,
      es_hibrido: lugar.es_hibrido,
    };
    
    const createRes = await fetch(`${PB_URL}/api/collections/lugares/records`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    
    if (!createRes.ok) {
      const errText = await createRes.text();
      console.error(`Failed to create "${lugar.nombre}":`, createRes.status, errText);
    } else {
      inserted++;
    }
  }
  
  console.log(`Done! Inserted ${inserted}/${lugares.length} records.`);
}

main().catch(console.error);
