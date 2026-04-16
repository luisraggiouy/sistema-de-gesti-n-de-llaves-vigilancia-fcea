export type TipoLugar = 
  | 'Salón' 
  | 'Salón Híbrido' 
  | 'Oficina' 
  | 'Sala' 
  | 'Depósito' 
  | 'Baño' 
  | 'Área Común' 
  | 'Biblioteca'
  | 'Taller'
  | 'Recreación'
  | 'Guardería'
  | 'Acceso'
  | 'Espacio Común'
  | 'Otro';

export type TipoUsuario = 'Docente' | 'Alumno' | 'Personal TAS' | 'Empresa';

export type DepartamentoTAS = 
  | 'Electrotecnia'
  | 'Servicios Generales'
  | 'Compras'
  | 'Gastos'
  | 'UPC'
  | 'Decanato'
  | 'Suministros'
  | 'Apoyo Docente'
  | 'Bedelía'
  | 'Contaduría'
  | 'Sueldos'
  | 'CAVIDA'
  | 'Convenios'
  | 'Concursos'
  | 'Sistemas'
  | 'Mantenimiento'
  | 'Vigilancia'
  | 'UGE'
  | 'UEAM'
  | 'UAE'
  | 'Otro';

export const departamentosTAS: DepartamentoTAS[] = [
  'Apoyo Docente', 'Bedelía', 'CAVIDA', 'Compras', 'Concursos', 'Contaduría',
  'Convenios', 'Decanato', 'Electrotecnia', 'Gastos', 'Mantenimiento',
  'Servicios Generales', 'Sistemas', 'Sueldos', 'Suministros',
  'UAE', 'UEAM', 'UGE', 'UPC', 'Vigilancia', 'Otro'
];

export type ZonaTablero = 
  | 'Puerta derecha' 
  | 'Puerta izquierda' 
  | 'Fondo' 
  | 'Lateral derecho' 
  | 'Lateral izquierdo';

export type TipoTablero = 'Tablero Principal' | 'Tablero Copias' | 'Tablero Jefes';

export const tiposTablero: TipoTablero[] = ['Tablero Copias', 'Tablero Jefes', 'Tablero Principal'];

export type EstadoLicencia = 'activo' | 'licencia' | 'licencia_medica';

export const estadosLicencia: { value: EstadoLicencia; label: string }[] = [
  { value: 'activo', label: 'Activo' },
  { value: 'licencia', label: 'Licencia' },
  { value: 'licencia_medica', label: 'Licencia Médica' },
];

export type Turno = 'Matutino' | 'Vespertino' | 'Nocturno';

export interface Lugar {
  id: string;
  nombre: string;
  tipo: TipoLugar;
  edificio: string;
  tablero: TipoTablero;
  ubicacion: {
    zona: ZonaTablero;
    fila?: number;
    columna?: string;
  };
  disponible: boolean;
  esHibrido: boolean;
}

export interface Vigilante {
  id: string;
  nombre: string;
  esJefe: boolean;
  turno: Turno;
  estadoLicencia?: EstadoLicencia;
}

export interface UsuarioRegistrado {
  id: string;
  nombre: string;
  celular: string;
  email?: string;
  tipo: TipoUsuario;
  departamento?: DepartamentoTAS;
  nombreEmpresa?: string;
  fechaRegistro: string;
}

// SolicitudLlave se define en src/types/solicitud.ts
// Re-exportamos desde ahí para compatibilidad
export type { SolicitudLlave } from '@/types/solicitud';

export const vigilantes: Vigilante[] = [
  { id: 'v1', nombre: 'Sylvia', esJefe: true, turno: 'Matutino' },
  { id: 'v2', nombre: 'Claudia', esJefe: false, turno: 'Matutino' },
  { id: 'v3', nombre: 'Laura', esJefe: false, turno: 'Matutino' },
  { id: 'v4', nombre: 'Lourdes', esJefe: false, turno: 'Matutino' },
  { id: 'v5', nombre: 'Luis', esJefe: false, turno: 'Matutino' },
  { id: 'v6', nombre: 'Dahiana', esJefe: false, turno: 'Matutino' },
  { id: 'v7', nombre: 'Martín', esJefe: true, turno: 'Vespertino' },
  { id: 'v8', nombre: 'Daniel', esJefe: false, turno: 'Vespertino' },
  { id: 'v9', nombre: 'Nathia', esJefe: false, turno: 'Vespertino' },
  { id: 'v10', nombre: 'Silvia', esJefe: false, turno: 'Vespertino' },
  { id: 'v11', nombre: 'Alejandro', esJefe: false, turno: 'Vespertino' },
  { id: 'v12', nombre: 'Caterin', esJefe: false, turno: 'Vespertino' },
  { id: 'v13', nombre: 'Gustavo', esJefe: true, turno: 'Nocturno' },
  { id: 'v14', nombre: 'Mario', esJefe: false, turno: 'Nocturno' },
  { id: 'v15', nombre: 'Silvana', esJefe: false, turno: 'Nocturno' },
  { id: 'v16', nombre: 'Fernando', esJefe: false, turno: 'Nocturno' },
];

export const lugares: Lugar[] = [
  { id: 'l1', nombre: 'Intendencia', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 1, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l2', nombre: 'UGE', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 1, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l3', nombre: 'Servicios.Generles', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 1, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l4', nombre: 'Mantenimiento', tipo: 'Taller', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 1, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l5', nombre: 'Reproducciones', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 1, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l6', nombre: 'Electrotécnia', tipo: 'Taller', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 1, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l7', nombre: 'Puerta vigilancia', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 1, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l8', nombre: 'entrada', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 2, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l9', nombre: 'salida patio subsuelo', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 2, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l10', nombre: 'depósito', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 2, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l11', nombre: 'Sala de lectura', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 2, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l12', nombre: 'Pasaje sale de lectura a biblioteca', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 2, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l13', nombre: 'Entrepiso Biblioteca', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 2, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l14', nombre: 'Sala A', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 2, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l15', nombre: 'Decanato', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l16', nombre: 'Sala consejo', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l17', nombre: 'Oficina decano', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l18', nombre: 'Decanato interior', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l19', nombre: 'Comunicaciones', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l20', nombre: 'Asistencia académica', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l21', nombre: 'Cavida', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l22', nombre: 'Decanato a sala de consejo', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l23', nombre: 'Recrea subsuelo entrada', tipo: 'Recreación', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'I' }, disponible: true, esHibrido: false },
  { id: 'l24', nombre: 'Archivo Area de recreación', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'J' }, disponible: true, esHibrido: false },
  { id: 'l25', nombre: 'Depósito cecea', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 3, columna: 'K' }, disponible: true, esHibrido: false },
  { id: 'l26', nombre: 'Bedelía', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 4, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l27', nombre: 'Sistemas', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 4, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l28', nombre: 'Sistemas 21', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 4, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l29', nombre: 'Apoyo docente', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 4, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l30', nombre: 'Extensión UEAM', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 4, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l31', nombre: 'Compras', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 4, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l32', nombre: 'Baños nuevos funcionarios', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 4, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l33', nombre: 'Archivo', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l34', nombre: 'Sala comisiones', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l35', nombre: 'Comisiones reguladora', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l36', nombre: 'Pasaje sala comisiones', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l37', nombre: 'Consejo y suministros', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l38', nombre: 'Suministros', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l39', nombre: 'Dirección TAS', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l40', nombre: 'Personal TAS', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l41', nombre: 'Concursos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'I' }, disponible: true, esHibrido: false },
  { id: 'l42', nombre: 'CECEA', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'J' }, disponible: true, esHibrido: false },
  { id: 'l43', nombre: 'Rendiciones', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l44', nombre: 'Contaduría', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l45', nombre: 'Sueldos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l46', nombre: 'Gastos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l47', nombre: 'Convenios', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l48', nombre: 'Personal docente', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l49', nombre: 'Reja ventana investigadores', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l50', nombre: 'Bajo escalera patio EIP', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l51', nombre: 'Entrada facultad', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 1, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l52', nombre: 'Entrada eduardo acevedo', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 1, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l53', nombre: 'Portón MSP', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 1, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l54', nombre: 'Azotea', tipo: 'Área Común', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 1, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l55', nombre: 'Buhardilla', tipo: 'Área Común', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 1, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l56', nombre: 'Patio cantina', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 1, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l57', nombre: 'Cortina aulario', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 2, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l58', nombre: 'Porta rollos baños iesta', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 2, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l59', nombre: 'Bicicletas', tipo: 'Espacio Común', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 2, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l60', nombre: 'Patio reja invesigadores', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 2, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l61', nombre: 'Reja exterior lactancia', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 2, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l62', nombre: 'Reja exterior eduardo acevedo jaula', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 3, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l63', nombre: 'Salida patio 11-12d', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 3, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l64', nombre: 'Patio bicicletas', tipo: 'Espacio Común', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 3, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l65', nombre: 'Baños salón 5', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 3, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l66', nombre: 'Tableros', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 3, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l67', nombre: 'Descanso cooperativa', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 3, columna: 'I' }, disponible: true, esHibrido: false },
  { id: 'l68', nombre: 'Lactancia manojo', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 4, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l69', nombre: 'Lactancia vestuarios', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 4, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l70', nombre: 'Baño Hall cantina', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 4, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l71', nombre: 'Duchas vestuarios subsuelo', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 4, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l72', nombre: 'Baños subsuelo', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 4, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l73', nombre: 'Porta rollo', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 4, columna: 'I' }, disponible: true, esHibrido: false },
  { id: 'l74', nombre: 'Baño PA informática', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 5, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l75', nombre: 'Baños IESTA', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 5, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l76', nombre: 'Baños AM', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 5, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l77', nombre: 'Baño salón 23 privado', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 5, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l78', nombre: 'Baño salón 23 lisiado', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 5, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l79', nombre: 'Baño salón 23 hombres', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 5, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l80', nombre: 'Baño salón 23 damas', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 5, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l81', nombre: 'Baño salón 6', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 6, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l82', nombre: 'Baño salón 7', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 6, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l83', nombre: 'Baño salón 8', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 6, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l84', nombre: 'Baños vigilancia', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 6, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l85', nombre: 'Baños decanato hombres', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 6, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l86', nombre: 'Baños decanato damas', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 6, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l87', nombre: 'Accesos EIP manojo', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral izquierdo' }, disponible: true, esHibrido: false },
  { id: 'l88', nombre: 'Oficinas y secretaría EIP 205-201', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral izquierdo' }, disponible: true, esHibrido: false },
  { id: 'l89', nombre: 'Oficinas EIP 301-315', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral izquierdo' }, disponible: true, esHibrido: false },
  { id: 'l90', nombre: 'Oficinas EIP 302-316', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral izquierdo' }, disponible: true, esHibrido: false },
  { id: 'l91', nombre: 'Matemáticas', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l92', nombre: 'CGU', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l93', nombre: 'Recreación sala 1', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l94', nombre: 'Recreación entrada', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l95', nombre: 'Recreación sala 2', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l96', nombre: 'Recreación sala 3', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l97', nombre: 'Affur', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l98', nombre: 'Ascensor américa', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l99', nombre: 'Traba ascensor EIP', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l100', nombre: 'Pulsadores Isai', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l101', nombre: 'Bomba de agua patio', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l102', nombre: 'Bomba de incendio', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l103', nombre: 'Contadores ose jackson', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l104', nombre: 'Medidor de ute', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l105', nombre: 'Depósito garrafas', tipo: 'Depósito', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'I' }, disponible: true, esHibrido: false },
  { id: 'l106', nombre: 'Camioneta', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'J' }, disponible: true, esHibrido: false },
  { id: 'l107', nombre: 'Mueble objetos perdidos', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'Q' }, disponible: true, esHibrido: false },
  { id: 'l108', nombre: 'Investigadores entrada oficinas', tipo: 'Acceso', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l109', nombre: 'Investigadores baños', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l110', nombre: 'Investigadores of 1', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l111', nombre: 'Investigadores of 2', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l112', nombre: 'Investigadores of 3', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l113', nombre: 'Investigadores of 4', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l114', nombre: 'Investigadores of 5', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l115', nombre: 'Investigadores of 6', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l116', nombre: 'Investigadores of 7', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'I' }, disponible: true, esHibrido: false },
  { id: 'l117', nombre: 'Investigadores of 8', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'J' }, disponible: true, esHibrido: false },
  { id: 'l118', nombre: 'Investigadores of 9', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'Q' }, disponible: true, esHibrido: false },
  { id: 'l119', nombre: 'Investigadores of 10', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'K' }, disponible: true, esHibrido: false },
  { id: 'l120', nombre: 'Sala de navegación entrada', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l121', nombre: 'Sala de navegación box 1', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l122', nombre: 'Sala de navegación box 2', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l123', nombre: 'Sala de navegación box 3', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l124', nombre: 'Sala de navegación box 4', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l125', nombre: 'Sala de navegación box 5', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'F' }, disponible: true, esHibrido: false },
  { id: 'l126', nombre: 'Bloomberg', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'G' }, disponible: true, esHibrido: false },
  { id: 'l127', nombre: 'Informática', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l128', nombre: 'UPC', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'I' }, disponible: true, esHibrido: false },
  { id: 'l129', nombre: 'UAE', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'J' }, disponible: true, esHibrido: false },
  { id: 'l130', nombre: 'Multimedia', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'Q' }, disponible: true, esHibrido: false },
  { id: 'l131', nombre: 'Lockers pruebas sala docente', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'K' }, disponible: true, esHibrido: false },
  { id: 'l132', nombre: 'Salónes 1,2,3,5', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: false },
  { id: 'l133', nombre: 'Salón 4', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: true },
  { id: 'l134', nombre: 'Salón 6', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: true },
  { id: 'l135', nombre: 'Salón 7', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: true },
  { id: 'l136', nombre: 'Salón 8', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: true },
  { id: 'l137', nombre: 'Salón 9', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: true },
  { id: 'l138', nombre: 'Salón 10', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: false },
  { id: 'l139', nombre: 'Salón 11-12', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: false },
  { id: 'l140', nombre: 'Salones 14,15,16', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: true },
  { id: 'l141', nombre: 'Salón 18', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: false },
  { id: 'l142', nombre: 'salón 19', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: false },
  { id: 'l143', nombre: 'Salón 20', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: false },
  { id: 'l144', nombre: 'Salo1-nes 21-25', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 4 }, disponible: true, esHibrido: true },
  { id: 'l145', nombre: 'Equipos AM', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l146', nombre: 'Equipos VIP', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l147', nombre: 'Equipos AM', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l148', nombre: 'Equipos 2', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l149', nombre: 'Equipos 3', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l150', nombre: 'Equipos 5', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l151', nombre: 'Equipos 6', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l152', nombre: 'Equipos 7', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l153', nombre: 'Equipos 8', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l154', nombre: 'Equipos 10', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l155', nombre: 'Equipos 11', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l156', nombre: 'Equipos 12', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l157', nombre: 'Equipos 14', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l158', nombre: 'Equipos 15', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l159', nombre: 'Equipos 16', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l160', nombre: 'Equipos 18', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l161', nombre: 'Equipos 19', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l162', nombre: 'Equipos 20', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l163', nombre: 'Equipos 21', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l164', nombre: 'Equipos 22', tipo: 'Otro', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: false },
  { id: 'l165', nombre: 'Equipos 23', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l166', nombre: 'Equipos 24', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l167', nombre: 'Equipos 25', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5 }, disponible: true, esHibrido: true },
  { id: 'l168', nombre: 'Iesta sala 17', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l169', nombre: 'Iesta sala 18', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l170', nombre: 'Iesta sala 19', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l171', nombre: 'Iesta sala 20 20.a-20.b-20.c', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l172', nombre: 'Iesta sala 21 21.a-21.b-21.c', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l173', nombre: 'Iesta sala 22', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l174', nombre: 'Iesta sala 23-23.a-23.b-23.c', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l175', nombre: 'Iesta sala 24', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l176', nombre: 'Iesta sala 25', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l177', nombre: 'Iesta sala 27', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
  { id: 'l178', nombre: 'Depósito de máquinas', tipo: 'Depósito', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6 }, disponible: true, esHibrido: false },
];

export const edificios = ['Central', 'EIP'];  // Already alphabetical

export const tiposLugar: TipoLugar[] = [
  'Acceso', 'Área Común', 'Baño', 'Biblioteca', 'Depósito',
  'Espacio Común', 'Guardería', 'Oficina', 'Otro', 'Recreación',
  'Sala', 'Salón', 'Salón Híbrido', 'Taller'
];

export const tiposUsuario: TipoUsuario[] = ['Alumno', 'Docente', 'Empresa', 'Personal TAS'];

export const zonasTablero: ZonaTablero[] = [
  'Fondo', 'Lateral derecho', 'Lateral izquierdo', 'Puerta derecha', 'Puerta izquierda'
];

export function formatearUbicacion(ubicacion: Lugar['ubicacion']): string {
  const zonaCorta = ubicacion.zona
    .replace('Puerta derecha', 'Puerta der.')
    .replace('Puerta izquierda', 'Puerta izq.')
    .replace('Lateral derecho', 'Lateral der.')
    .replace('Lateral izquierdo', 'Lateral izq.');
  const fila = ubicacion.fila;
  const columna = ubicacion.columna;
  if (fila && columna) {
    return `${zonaCorta}, ${columna}${fila}`;
  }
  if (fila) {
    return `${zonaCorta}, Fila ${fila}`;
  }
  return zonaCorta;
}

export function normalizarTexto(texto: string): string {
  return texto.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
}

/**
 * Comparador de orden natural: ordena textos alfabéticamente pero trata
 * secuencias numéricas como números (ej: "Salón 2" < "Salón 10" < "Salón 25").
 * Usar con Array.sort(): items.sort((a, b) => ordenNatural(a.nombre, b.nombre))
 */
export function ordenNatural(a: string, b: string): number {
  const na = normalizarTexto(a);
  const nb = normalizarTexto(b);
  const re = /(\d+)|(\D+)/g;
  const partsA = na.match(re) || [];
  const partsB = nb.match(re) || [];
  const len = Math.min(partsA.length, partsB.length);
  for (let i = 0; i < len; i++) {
    const pa = partsA[i];
    const pb = partsB[i];
    const numA = Number(pa);
    const numB = Number(pb);
    if (!isNaN(numA) && !isNaN(numB)) {
      if (numA !== numB) return numA - numB;
    } else {
      const cmp = pa.localeCompare(pb);
      if (cmp !== 0) return cmp;
    }
  }
  return partsA.length - partsB.length;
}

export function obtenerTurnoActual(): Turno {
  const hora = new Date().getHours();
  if (hora >= 6 && hora < 14) return 'Matutino';
  if (hora >= 14 && hora < 22) return 'Vespertino';
  return 'Nocturno';
}

export function obtenerVigilantesActuales(): Vigilante[] {
  const turno = obtenerTurnoActual();
  return vigilantes.filter(v => v.turno === turno);
}

export function getColorTipoLugar(tipo: TipoLugar): string {
  const colores: Record<TipoLugar, string> = {
    'Salón': 'bg-salon-comun',
    'Salón Híbrido': 'bg-salon-hibrido',
    'Oficina': 'bg-oficina',
    'Sala': 'bg-primary',
    'Depósito': 'bg-muted-foreground',
    'Baño': 'bg-info',
    'Área Común': 'bg-areaComun',
    'Biblioteca': 'bg-biblioteca',
    'Taller': 'bg-orange-500',
    'Recreación': 'bg-lime-500',
    'Guardería': 'bg-pink-500',
    'Acceso': 'bg-gray-500',
    'Espacio Común': 'bg-purple-500',
    'Otro': 'bg-slate-400'
  };
  return colores[tipo] || 'bg-muted';
}

// ============= AUTORIZACIONES =============
export interface Autorizacion {
  id: string;
  personaNombre: string;
  personaCI?: string; // Campo opcional para cédula de identidad
  lugarAutorizado: string;
  autorizadoPor: string;
  fechaAutorizacion: string;
  fechaDesde?: string;
  fechaHasta?: string;
  horario?: string;
  emailReferencia?: string;
  observaciones?: string;
  fechaCreacion: string;
}

export interface AutorizacionHistorial extends Autorizacion {
  motivoBaja: 'vencida' | 'eliminada';
  fechaBaja: string;
}

export function getAutorizaciones(): Autorizacion[] { return []; }
export function getHistorialAutorizaciones(): AutorizacionHistorial[] { return []; }
export function buscarAutorizacion(_persona: string, _lugar: string): Autorizacion[] { return []; }
export function buscarAutorizacionEnVivo(_persona: string, _lugar: string): Autorizacion[] { 
  // Nota: En una implementación real, esta función buscaría por nombre o CI
  // _persona puede ser nombre o CI
  return []; 
}
export function buscarHistorialAutorizaciones(_lugar: string): AutorizacionHistorial[] { return []; }
export function guardarAutorizacion(_auth: Omit<Autorizacion, 'id' | 'fechaCreacion'>): Autorizacion {
  throw new Error('Usar useAutorizaciones hook en su lugar');
}
export function actualizarAutorizacion(_id: string, _datos: any): Autorizacion | null { return null; }
export function eliminarAutorizacion(_id: string): boolean { return false; }
export function purgarAutorizacionesVencidas(): number { return 0; }

// ============= USUARIOS REGISTRADOS =============
export function getUsuariosRegistrados(): UsuarioRegistrado[] { return []; }
export function guardarUsuario(_u: Omit<UsuarioRegistrado, 'id' | 'fechaRegistro'>): UsuarioRegistrado {
  throw new Error('Usar useUsuariosRegistrados hook en su lugar');
}
export function buscarUsuarioPorCelular(_celular: string): UsuarioRegistrado | undefined { return undefined; }
export function buscarUsuariosPorTexto(_texto: string): UsuarioRegistrado[] { return []; }
export function actualizarUsuario(_id: string, _datos: any): UsuarioRegistrado | null { return null; }
export function eliminarUsuario(_id: string): boolean { return false; }