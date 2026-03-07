// Datos reales de FCEA UdelaR según SRS v3.6

export type TipoLugar = 
  | 'Salón' 
  | 'Salón Híbrido' 
  | 'Oficina' 
  | 'Sala' 
  | 'Depósito' 
  | 'Baño' 
  | 'Área Común' 
  | 'Biblioteca' 
  | 'Auditorio';

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
  | 'Vigilancia';

export const departamentosTAS: DepartamentoTAS[] = [
  'Electrotecnia', 'Servicios Generales', 'Compras', 'Gastos', 'UPC',
  'Decanato', 'Suministros', 'Apoyo Docente', 'Bedelía', 'Contaduría',
  'Sueldos', 'CAVIDA', 'Convenios', 'Concursos', 'Sistemas', 'Mantenimiento', 'Vigilancia'
];

export type ZonaTablero = 
  | 'Puerta derecha' 
  | 'Puerta izquierda' 
  | 'Fondo' 
  | 'Lateral derecho' 
  | 'Lateral izquierdo';

export type TipoTablero = 'Tablero Principal' | 'Tablero Copias' | 'Tablero Jefes';

export const tiposTablero: TipoTablero[] = ['Tablero Principal', 'Tablero Copias', 'Tablero Jefes'];

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

export interface SolicitudLlave {
  id: string;
  lugarId: string;
  usuario: {
    nombre: string;
    celular: string;
    tipo: TipoUsuario;
  };
  terminal: string;
  horaSolicitud: Date;
  horaEntrega?: Date;
  horaDevolucion?: Date;
  entregadoPor?: string;
  recibidoPor?: string;
  esIntercambio: boolean;
  estado: 'pendiente' | 'entregada' | 'devuelta';
}

// Personal de vigilancia REAL de FCEA
export const vigilantes: Vigilante[] = [
  // Turno Matutino (06:00 - 14:00)
  { id: 'v1', nombre: 'Sylvia', esJefe: true, turno: 'Matutino' },
  { id: 'v2', nombre: 'Claudia', esJefe: false, turno: 'Matutino' },
  { id: 'v3', nombre: 'Laura', esJefe: false, turno: 'Matutino' },
  { id: 'v4', nombre: 'Lourdes', esJefe: false, turno: 'Matutino' },
  { id: 'v5', nombre: 'Luis', esJefe: false, turno: 'Matutino' },
  { id: 'v6', nombre: 'Dahiana', esJefe: false, turno: 'Matutino' },
  
  // Turno Vespertino (14:00 - 22:00)
  { id: 'v7', nombre: 'Martín', esJefe: true, turno: 'Vespertino' },
  { id: 'v8', nombre: 'Daniel', esJefe: false, turno: 'Vespertino' },
  { id: 'v9', nombre: 'Nathia', esJefe: false, turno: 'Vespertino' },
  { id: 'v10', nombre: 'Silvia', esJefe: false, turno: 'Vespertino' },
  { id: 'v11', nombre: 'Alejandro', esJefe: false, turno: 'Vespertino' },
  { id: 'v12', nombre: 'Caterin', esJefe: false, turno: 'Vespertino' },
  
  // Turno Nocturno (22:00 - 06:00)
  { id: 'v13', nombre: 'Gustavo', esJefe: true, turno: 'Nocturno' },
  { id: 'v14', nombre: 'Mario', esJefe: false, turno: 'Nocturno' },
  { id: 'v15', nombre: 'Silvana', esJefe: false, turno: 'Nocturno' },
  { id: 'v16', nombre: 'Fernando', esJefe: false, turno: 'Nocturno' },
];

// Lugares de ejemplo basados en FCEA
export const lugares: Lugar[] = [
  // Salones Comunes - Edificio Central
  { id: 'l1', nombre: 'Salón 101', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 6, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l2', nombre: 'Salón 102', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 5, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l3', nombre: 'Salón 103', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 4, columna: 'B' }, disponible: true, esHibrido: false },
  { id: 'l4', nombre: 'Salón 201', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 3, columna: 'C' }, disponible: true, esHibrido: false },
  { id: 'l5', nombre: 'Salón 202', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 4, columna: 'C' }, disponible: false, esHibrido: false },
  // Salones Híbridos
  { id: 'l6', nombre: 'Salón Híbrido A', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 7, columna: 'G' }, disponible: true, esHibrido: true },
  { id: 'l7', nombre: 'Salón Híbrido B', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 8, columna: 'G' }, disponible: true, esHibrido: true },
  { id: 'l8', nombre: 'Sala de Videoconferencias', tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 6, columna: 'F' }, disponible: true, esHibrido: true },
  { id: 'l9', nombre: 'Informática', tipo: 'Salón', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 2, columna: 'A' }, disponible: true, esHibrido: false },
  // Oficinas
  { id: 'l10', nombre: 'Oficina Concursos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 1, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l11', nombre: 'Oficina Gastos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 2, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l12', nombre: 'Oficina Sueldos', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta derecha', fila: 3, columna: 'D' }, disponible: true, esHibrido: false },
  { id: 'l13', nombre: 'Decanato', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l14', nombre: 'Secretaría Académica', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l15', nombre: 'Bedelía', tipo: 'Oficina', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 1, columna: 'A' }, disponible: true, esHibrido: false },
  // Biblioteca
  { id: 'l16', nombre: 'Biblioteca Principal', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral izquierdo' }, disponible: true, esHibrido: false },
  { id: 'l17', nombre: 'Sala de Lectura', tipo: 'Biblioteca', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral izquierdo' }, disponible: true, esHibrido: false },
  // Salas
  { id: 'l18', nombre: 'Sala de Profesores', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'E' }, disponible: true, esHibrido: false },
  { id: 'l19', nombre: 'Sala de Reuniones', tipo: 'Sala', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 3, columna: 'E' }, disponible: true, esHibrido: false },
  // Áreas Comunes
  { id: 'l20', nombre: 'Azotea', tipo: 'Área Común', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l21', nombre: 'Buhardilla', tipo: 'Área Común', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral derecho' }, disponible: true, esHibrido: false },
  { id: 'l22', nombre: 'Comedor', tipo: 'Área Común', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Lateral izquierdo' }, disponible: true, esHibrido: false },
  // Depósitos
  { id: 'l23', nombre: 'Depósito General', tipo: 'Depósito', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 1, columna: 'H' }, disponible: true, esHibrido: false },
  { id: 'l24', nombre: 'Depósito Limpieza', tipo: 'Depósito', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 2, columna: 'H' }, disponible: true, esHibrido: false },
  // Baños
  { id: 'l25', nombre: 'Baño PB', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 7, columna: 'A' }, disponible: true, esHibrido: false },
  { id: 'l26', nombre: 'Baño 1er piso', tipo: 'Baño', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Puerta izquierda', fila: 8, columna: 'A' }, disponible: true, esHibrido: false },
  // Auditorio
  { id: 'l27', nombre: 'Auditorio Principal', tipo: 'Auditorio', edificio: 'Central', tablero: 'Tablero Principal', ubicacion: { zona: 'Fondo', fila: 5, columna: 'F' }, disponible: true, esHibrido: false },
];

// Edificios disponibles
export const edificios = ['Central', 'Anexo', 'Biblioteca'];

// Tipos de lugares
export const tiposLugar: TipoLugar[] = [
  'Salón',
  'Salón Híbrido',
  'Oficina',
  'Sala',
  'Depósito',
  'Baño',
  'Área Común',
  'Biblioteca',
  'Auditorio'
];

// Tipos de usuario
export const tiposUsuario: TipoUsuario[] = [
  'Docente',
  'Alumno',
  'Personal TAS',
  'Empresa'
];

// Zonas del tablero
export const zonasTablero: ZonaTablero[] = [
  'Puerta derecha',
  'Puerta izquierda',
  'Fondo',
  'Lateral derecho',
  'Lateral izquierdo'
];

// Helper: Formatear ubicación
export function formatearUbicacion(ubicacion: Lugar['ubicacion']): string {
  const zonaCorta = ubicacion.zona
    .replace('Puerta derecha', 'Puerta der.')
    .replace('Puerta izquierda', 'Puerta izq.')
    .replace('Lateral derecho', 'Lateral der.')
    .replace('Lateral izquierdo', 'Lateral izq.');
  
  if (ubicacion.fila && ubicacion.columna) {
    return `${zonaCorta}, ${ubicacion.columna}${ubicacion.fila}`;
  }
  return zonaCorta;
}

// Helper: Normalizar texto para búsqueda (insensible a acentos)
export function normalizarTexto(texto: string): string {
  return texto
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

// Helper: Obtener turno actual
export function obtenerTurnoActual(): Turno {
  const hora = new Date().getHours();
  if (hora >= 6 && hora < 14) return 'Matutino';
  if (hora >= 14 && hora < 22) return 'Vespertino';
  return 'Nocturno';
}

// Helper: Obtener vigilantes del turno actual
export function obtenerVigilantesActuales(): Vigilante[] {
  const turno = obtenerTurnoActual();
  return vigilantes.filter(v => v.turno === turno);
}

// Helper: Color por tipo de lugar
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
    'Auditorio': 'bg-accent'
  };
  return colores[tipo] || 'bg-muted';
}

// ============= GESTIÓN DE USUARIOS REGISTRADOS =============
const STORAGE_KEY = 'fcea_usuarios_registrados';

export function getUsuariosRegistrados(): UsuarioRegistrado[] {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : [];
  } catch {
    return [];
  }
}

export function guardarUsuario(usuario: Omit<UsuarioRegistrado, 'id' | 'fechaRegistro'>): UsuarioRegistrado {
  const usuarios = getUsuariosRegistrados();
  
  // Verificar si ya existe por celular
  if (usuario.celular) {
    const celularNorm = usuario.celular.replace(/\D/g, '');
    if (celularNorm) {
      const existente = usuarios.find(u => u.celular && u.celular.replace(/\D/g, '') === celularNorm);
      if (existente) {
        return existente;
      }
    }
  }
  
  // Verificar si ya existe por email
  if (usuario.email) {
    const existente = usuarios.find(u => u.email && u.email.toLowerCase() === usuario.email!.toLowerCase());
    if (existente) {
      return existente;
    }
  }
  
  const nuevoUsuario: UsuarioRegistrado = {
    ...usuario,
    id: `u${Date.now()}`,
    fechaRegistro: new Date().toISOString()
  };
  
  usuarios.push(nuevoUsuario);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(usuarios));
  
  return nuevoUsuario;
}

export function buscarUsuarioPorCelular(celular: string): UsuarioRegistrado | undefined {
  const usuarios = getUsuariosRegistrados();
  const celularNormalizado = celular.replace(/\D/g, '');
  return usuarios.find(u => u.celular.replace(/\D/g, '') === celularNormalizado);
}

export function buscarUsuariosPorTexto(texto: string): UsuarioRegistrado[] {
  if (!texto.trim()) return [];
  
  const usuarios = getUsuariosRegistrados();
  const textoNormalizado = normalizarTexto(texto);
  const celularBusqueda = texto.replace(/\D/g, '');
  
  return usuarios.filter(u => {
    const nombreMatch = normalizarTexto(u.nombre).includes(textoNormalizado);
    const celularMatch = u.celular && u.celular.replace(/\D/g, '').includes(celularBusqueda);
    const emailMatch = u.email && normalizarTexto(u.email).includes(textoNormalizado);
    return nombreMatch || celularMatch || emailMatch;
  });
}

export function actualizarUsuario(id: string, datos: Partial<Omit<UsuarioRegistrado, 'id' | 'fechaRegistro'>>): UsuarioRegistrado | null {
  const usuarios = getUsuariosRegistrados();
  const idx = usuarios.findIndex(u => u.id === id);
  if (idx === -1) return null;
  usuarios[idx] = { ...usuarios[idx], ...datos };
  localStorage.setItem(STORAGE_KEY, JSON.stringify(usuarios));
  return usuarios[idx];
}

export function eliminarUsuario(id: string): boolean {
  const usuarios = getUsuariosRegistrados();
  const filtered = usuarios.filter(u => u.id !== id);
  if (filtered.length === usuarios.length) return false;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(filtered));
  return true;
}

// ============= GESTIÓN DE AUTORIZACIONES =============
const AUTORIZACIONES_KEY = 'fcea_autorizaciones';

export interface Autorizacion {
  id: string;
  personaNombre: string;
  lugarAutorizado: string; // nombre de llave/lugar
  autorizadoPor: string; // quién autoriza (ej: "Director del IESTA Juan González")
  fechaAutorizacion: string; // ISO date
  fechaDesde?: string; // ISO date - vigencia desde
  fechaHasta?: string; // ISO date - vigencia hasta
  horario?: string; // ej: "Lunes a Viernes de 9 a 18"
  emailReferencia?: string; // mail de referencia
  observaciones?: string;
  fechaCreacion: string;
}

export function getAutorizaciones(): Autorizacion[] {
  try {
    const data = localStorage.getItem(AUTORIZACIONES_KEY);
    return data ? JSON.parse(data) : [];
  } catch {
    return [];
  }
}

export function guardarAutorizacion(auth: Omit<Autorizacion, 'id' | 'fechaCreacion'>): Autorizacion {
  const auths = getAutorizaciones();
  const nueva: Autorizacion = {
    ...auth,
    id: `auth${Date.now()}`,
    fechaCreacion: new Date().toISOString(),
  };
  auths.push(nueva);
  localStorage.setItem(AUTORIZACIONES_KEY, JSON.stringify(auths));
  return nueva;
}

export function actualizarAutorizacion(id: string, datos: Partial<Omit<Autorizacion, 'id' | 'fechaCreacion'>>): Autorizacion | null {
  const auths = getAutorizaciones();
  const idx = auths.findIndex(a => a.id === id);
  if (idx === -1) return null;
  auths[idx] = { ...auths[idx], ...datos };
  localStorage.setItem(AUTORIZACIONES_KEY, JSON.stringify(auths));
  return auths[idx];
}

export function eliminarAutorizacion(id: string): boolean {
  const auths = getAutorizaciones();
  const filtered = auths.filter(a => a.id !== id);
  if (filtered.length === auths.length) return false;
  localStorage.setItem(AUTORIZACIONES_KEY, JSON.stringify(filtered));
  return true;
}

export function buscarAutorizacion(persona: string, lugar: string): Autorizacion[] {
  const auths = getAutorizaciones();
  const pNorm = normalizarTexto(persona);
  const lNorm = normalizarTexto(lugar);
  return auths.filter(a => {
    const matchPersona = !persona.trim() || normalizarTexto(a.personaNombre).includes(pNorm);
    const matchLugar = !lugar.trim() || normalizarTexto(a.lugarAutorizado).includes(lNorm);
    return matchPersona && matchLugar;
  });
}
