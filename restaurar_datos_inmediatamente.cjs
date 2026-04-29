// Script de restauración inmediata de datos REALES
// Sistema de Gestión de Llaves - FCEA
// ejecutar con: node restaurar_datos_inmediatamente.js

const PocketBase = require('pocketbase/cjs')
const pb = new PocketBase('http://127.0.0.1:8090');

// ============================================================
// VIGILANTES REALES POR TURNO
// ============================================================
const vigilantesPorTurno = [
    // TURNO MATUTINO
    { nombre: "Sylvia",    turno: "Matutino",    esJefe: true  },
    { nombre: "Claudia",   turno: "Matutino",    esJefe: false },
    { nombre: "Laura",     turno: "Matutino",    esJefe: false },
    { nombre: "Lourdes",   turno: "Matutino",    esJefe: false },
    { nombre: "Luis",      turno: "Matutino",    esJefe: false },
    { nombre: "Dahiana",   turno: "Matutino",    esJefe: false },
    // TURNO VESPERTINO
    { nombre: "Martín",    turno: "Vespertino",  esJefe: true  },
    { nombre: "Daniel",    turno: "Vespertino",  esJefe: false },
    { nombre: "Nathia",    turno: "Vespertino",  esJefe: false },
    { nombre: "Silvia",    turno: "Vespertino",  esJefe: false },
    { nombre: "Alejandro", turno: "Vespertino",  esJefe: false },
    { nombre: "Caterin",   turno: "Vespertino",  esJefe: false },
    // TURNO NOCTURNO
    { nombre: "Gustavo",   turno: "Nocturno",    esJefe: true  },
    { nombre: "Mario",     turno: "Nocturno",    esJefe: false },
    { nombre: "Silvana",   turno: "Nocturno",    esJefe: false },
    { nombre: "Fernando",  turno: "Nocturno",    esJefe: false },
];

// ============================================================
// LLAVES REALES CON SUS UBICACIONES EN EL TABLERO
// ============================================================
const llaves = [
    // --- TABLERO PRINCIPAL - PUERTA IZQUIERDA ---
    // Fila 1
    { nombre: 'Intendencia',                          tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'UGE',                                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Servicios.Generles',                   tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Mantenimiento',                        tipo: 'Taller',        edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Reproducciones',                       tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Electrotécnia',                        tipo: 'Taller',        edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Puerta vigilancia',                    tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 1, columna: 'G', disponible: true, esHibrido: false },
    // Fila 2
    { nombre: 'entrada',                              tipo: 'Biblioteca',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'salida patio subsuelo',                tipo: 'Biblioteca',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'depósito',                             tipo: 'Biblioteca',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Sala de lectura',                      tipo: 'Biblioteca',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Pasaje sale de lectura a biblioteca',  tipo: 'Biblioteca',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Entrepiso Biblioteca',                 tipo: 'Biblioteca',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Sala A',                               tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 2, columna: 'G', disponible: true, esHibrido: false },
    // Fila 3
    { nombre: 'Decanato',                             tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'Sala consejo',                         tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Oficina decano',                       tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Decanato interior',                    tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Comunicaciones',                       tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Asistencia académica',                 tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Cavida',                               tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Decanato a sala de consejo',           tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'H', disponible: true, esHibrido: false },
    { nombre: 'Recrea subsuelo entrada',              tipo: 'Recreación',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'I', disponible: true, esHibrido: false },
    { nombre: 'Archivo Area de recreación',           tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'J', disponible: true, esHibrido: false },
    { nombre: 'Depósito cecea',                       tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 3, columna: 'K', disponible: true, esHibrido: false },
    // Fila 4
    { nombre: 'Bedelía',                              tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'Sistemas',                             tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Sistemas 21',                          tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Apoyo docente',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Extensión UEAM',                       tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Compras',                              tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Baños nuevos funcionarios',            tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 4, columna: 'G', disponible: true, esHibrido: false },
    // Fila 5
    { nombre: 'Archivo',                              tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'Sala comisiones',                      tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Comisiones reguladora',                tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Pasaje sala comisiones',               tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Consejo y suministros',                tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Suministros',                          tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Dirección TAS',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Personal TAS',                         tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'H', disponible: true, esHibrido: false },
    { nombre: 'Concursos',                            tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'I', disponible: true, esHibrido: false },
    { nombre: 'CECEA',                                tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 5, columna: 'J', disponible: true, esHibrido: false },
    // Fila 6
    { nombre: 'Rendiciones',                          tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'Contaduría',                           tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Sueldos',                              tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Gastos',                               tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Convenios',                            tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Personal docente',                     tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Reja ventana investigadores',          tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Bajo escalera patio EIP',              tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta izquierda', fila: 6, columna: 'H', disponible: true, esHibrido: false },

    // --- TABLERO PRINCIPAL - PUERTA DERECHA ---
    // Fila 1
    { nombre: 'Entrada facultad',                     tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Entrada eduardo acevedo',              tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Portón MSP',                           tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Azotea',                               tipo: 'Área Común',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Buhardilla',                           tipo: 'Área Común',    edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Patio cantina',                        tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 1, columna: 'H', disponible: true, esHibrido: false },
    // Fila 2
    { nombre: 'Cortina aulario',                      tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Porta rollos baños iesta',             tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Bicicletas',                           tipo: 'Espacio Común', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Patio reja invesigadores',             tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Reja exterior lactancia',              tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 2, columna: 'H', disponible: true, esHibrido: false },
    // Fila 3
    { nombre: 'Reja exterior eduardo acevedo jaula', tipo: 'Otro',           edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Salida patio 11-12d',                  tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Patio bicicletas',                     tipo: 'Espacio Común', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Baños salón 5',                        tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Tableros',                             tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'H', disponible: true, esHibrido: false },
    { nombre: 'Descanso cooperativa',                 tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 3, columna: 'I', disponible: true, esHibrido: false },
    // Fila 4
    { nombre: 'Lactancia manojo',                     tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Lactancia vestuarios',                 tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Baño Hall cantina',                    tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Duchas vestuarios subsuelo',           tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Baños subsuelo',                       tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'H', disponible: true, esHibrido: false },
    { nombre: 'Porta rollo',                          tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 4, columna: 'I', disponible: true, esHibrido: false },
    // Fila 5
    { nombre: 'Baño PA informática',                  tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Baños IESTA',                          tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Baños AM',                             tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Baño salón 23 privado',                tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Baño salón 23 lisiado',                tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Baño salón 23 hombres',                tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Baño salón 23 damas',                  tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 5, columna: 'H', disponible: true, esHibrido: false },
    // Fila 6
    { nombre: 'Baño salón 6',                         tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Baño salón 7',                         tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Baño salón 8',                         tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Baños vigilancia',                     tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Baños decanato hombres',               tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Baños decanato damas',                 tipo: 'Baño',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Puerta derecha', fila: 6, columna: 'G', disponible: true, esHibrido: false },

    // --- TABLERO PRINCIPAL - LATERAL IZQUIERDO ---
    { nombre: 'Accesos EIP manojo',                   tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral izquierdo', disponible: true, esHibrido: false },
    { nombre: 'Oficinas y secretaría EIP 205-201',    tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral izquierdo', disponible: true, esHibrido: false },
    { nombre: 'Oficinas EIP 301-315',                 tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral izquierdo', disponible: true, esHibrido: false },
    { nombre: 'Oficinas EIP 302-316',                 tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral izquierdo', disponible: true, esHibrido: false },

    // --- TABLERO PRINCIPAL - LATERAL DERECHO ---
    { nombre: 'Matemáticas',                          tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', disponible: true, esHibrido: false },
    { nombre: 'CGU',                                  tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', disponible: true, esHibrido: false },
    { nombre: 'Recreación sala 1',                    tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', disponible: true, esHibrido: false },
    { nombre: 'Recreación entrada',                   tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', disponible: true, esHibrido: false },
    { nombre: 'Recreación sala 2',                    tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', disponible: true, esHibrido: false },
    { nombre: 'Recreación sala 3',                    tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Lateral derecho', disponible: true, esHibrido: false },

    // --- TABLERO PRINCIPAL - FONDO ---
    // Fila 1
    { nombre: 'Affur',                                tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'Ascensor américa',                     tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Traba ascensor EIP',                   tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Pulsadores Isai',                      tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Bomba de agua patio',                  tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Bomba de incendio',                    tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Contadores ose jackson',               tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Medidor de ute',                       tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'H', disponible: true, esHibrido: false },
    { nombre: 'Depósito garrafas',                    tipo: 'Depósito',      edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'I', disponible: true, esHibrido: false },
    { nombre: 'Camioneta',                            tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'J', disponible: true, esHibrido: false },
    { nombre: 'Mueble objetos perdidos',              tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 1, columna: 'Q', disponible: true, esHibrido: false },
    // Fila 2
    { nombre: 'Investigadores entrada oficinas',      tipo: 'Acceso',        edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'Investigadores baños',                 tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 1',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 2',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 3',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 4',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 5',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 6',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'H', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 7',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'I', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 8',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'J', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 9',                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'Q', disponible: true, esHibrido: false },
    { nombre: 'Investigadores of 10',                 tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 2, columna: 'K', disponible: true, esHibrido: false },
    // Fila 3
    { nombre: 'Sala de navegación entrada',           tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'A', disponible: true, esHibrido: false },
    { nombre: 'Sala de navegación box 1',             tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'B', disponible: true, esHibrido: false },
    { nombre: 'Sala de navegación box 2',             tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'C', disponible: true, esHibrido: false },
    { nombre: 'Sala de navegación box 3',             tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'D', disponible: true, esHibrido: false },
    { nombre: 'Sala de navegación box 4',             tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'E', disponible: true, esHibrido: false },
    { nombre: 'Sala de navegación box 5',             tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'F', disponible: true, esHibrido: false },
    { nombre: 'Bloomberg',                            tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'G', disponible: true, esHibrido: false },
    { nombre: 'Informática',                          tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'H', disponible: true, esHibrido: false },
    { nombre: 'UPC',                                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'I', disponible: true, esHibrido: false },
    { nombre: 'UAE',                                  tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'J', disponible: true, esHibrido: false },
    { nombre: 'Multimedia',                           tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'Q', disponible: true, esHibrido: false },
    { nombre: 'Lockers pruebas sala docente',         tipo: 'Sala',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 3, columna: 'K', disponible: true, esHibrido: false },
    // Fila 4 (salones - sin columna)
    { nombre: 'Salónes 1,2,3,5',                      tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: false },
    { nombre: 'Salón 4',                              tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: true  },
    { nombre: 'Salón 6',                              tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: true  },
    { nombre: 'Salón 7',                              tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: true  },
    { nombre: 'Salón 8',                              tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: true  },
    { nombre: 'Salón 9',                              tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: true  },
    { nombre: 'Salón 10',                             tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: false },
    { nombre: 'Salón 11-12',                          tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: false },
    { nombre: 'Salones 14,15,16',                     tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: true  },
    { nombre: 'Salón 18',                             tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: false },
    { nombre: 'salón 19',                             tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: false },
    { nombre: 'Salón 20',                             tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: false },
    { nombre: 'Salo1-nes 21-25',                      tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 4, disponible: true, esHibrido: true  },
    // Fila 5 (equipos - sin columna)
    { nombre: 'Salón AM equipos',                           tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón VIP equipos',                          tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón AM equipos',                           tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 2 equipos',                            tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 3 equipos',                            tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 5 equipos',                            tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 6 equipos',                            tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    { nombre: 'Salón 7 equipos',                            tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    { nombre: 'Salón 8 equipos',                            tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    { nombre: 'Salón 10 equipos',                           tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 11 equipos',                           tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 12 equipos',                           tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 14 equipos',                           tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    { nombre: 'Salón 15 equipos',                           tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    { nombre: 'Salón 16 equipos',                           tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    { nombre: 'Salón 18 equipos',                           tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 19 equipos',                           tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 20 equipos',                           tipo: 'Salón',         edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 21 equipos',                           tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 22 equipos',                           tipo: 'Otro',          edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: false },
    { nombre: 'Salón 23 equipos',                           tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    { nombre: 'Salón 24 equipos',                           tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    { nombre: 'Salón 25 equipos',                           tipo: 'Salón Híbrido', edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 5, disponible: true, esHibrido: true  },
    // Fila 6 (IESTA - sin columna)
    { nombre: 'Iesta sala 17',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 18',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 19',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 20 20.a-20.b-20.c',         tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 21 21.a-21.b-21.c',         tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 22',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 23-23.a-23.b-23.c',         tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 24',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 25',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Iesta sala 27',                        tipo: 'Oficina',       edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
    { nombre: 'Depósito de máquinas',                 tipo: 'Depósito',      edificio: 'Central', tablero: 'Tablero Principal', zona: 'Fondo', fila: 6, disponible: true, esHibrido: false },
];

// ============================================================
// FUNCIÓN PARA CREAR USUARIO ADMINISTRADOR
// ============================================================
async function crearAdminInicial() {
    try {
        console.log("Verificando usuario administrador...");
        const adminEmail = "admin@fcea.edu.uy";
        const adminPassword = "fceallaves2026";
        
        try {
            await pb.collection('users').getFirstListItem(`email="${adminEmail}"`);
            console.log("Usuario administrador ya existe, omitiendo creación");
        } catch (err) {
            const adminData = {
                email: adminEmail,
                password: adminPassword,
                passwordConfirm: adminPassword,
                name: "Administrador",
                role: "admin"
            };
            await pb.collection('users').create(adminData);
            console.log("Usuario administrador creado exitosamente");
        }
    } catch (error) {
        console.error("Error al crear usuario administrador:", error);
    }
}

// ============================================================
// FUNCIÓN PRINCIPAL DE RESTAURACIÓN
// ============================================================
async function restaurarDatos() {
    console.log("==========================================================");
    console.log("  RESTAURACIÓN DE DATOS REALES - SISTEMA LLAVES FCEA");
    console.log("==========================================================");
    console.log("");
    
    try {
        // Autenticar como admin
        try {
            console.log("Autenticando como administrador...");
            await pb.admins.authWithPassword("admin@fcea.edu.uy", "fceallaves2026");
            console.log("✓ Autenticación exitosa");
        } catch (error) {
            console.log("No se pudo autenticar. Intentando crear admin...");
            await crearAdminInicial();
            try {
                await pb.admins.authWithPassword("admin@fcea.edu.uy", "fceallaves2026");
                console.log("✓ Autenticación exitosa después de creación");
            } catch (authError) {
                console.warn("⚠ No se pudo autenticar. Procediendo sin autenticación...");
            }
        }
        
        // ---- RESTAURAR VIGILANTES ----
        console.log("");
        console.log("----------------------------------------------------------");
        console.log("RESTAURANDO VIGILANTES POR TURNO...");
        console.log("----------------------------------------------------------");
        let vigilantesCreados = 0;
        let vigilantesOmitidos = 0;
        
        for (const v of vigilantesPorTurno) {
            try {
                // Verificar si ya existe
                try {
                    await pb.collection('vigilantes').getFirstListItem(
                        `nombre="${v.nombre}" && turno="${v.turno}"`
                    );
                    console.log(`  (ya existe) ${v.nombre} - ${v.turno}`);
                    vigilantesOmitidos++;
                } catch (notFound) {
                    // No existe, crear
                    await pb.collection('vigilantes').create({
                        nombre: v.nombre,
                        turno: v.turno,
                        esJefe: v.esJefe,
                        estadoLicencia: 'activo'
                    });
                    vigilantesCreados++;
                    console.log(`  ✓ ${v.nombre} - ${v.turno}${v.esJefe ? ' (Jefe)' : ''}`);
                }
            } catch (error) {
                console.error(`  ✗ Error con vigilante ${v.nombre}:`, error.message);
            }
        }
        
        console.log(`  → Creados: ${vigilantesCreados} | Ya existían: ${vigilantesOmitidos} | Total: ${vigilantesPorTurno.length}`);
        
        // ---- RESTAURAR LLAVES / LUGARES ----
        console.log("");
        console.log("----------------------------------------------------------");
        console.log("RESTAURANDO LLAVES CON SUS UBICACIONES...");
        console.log("----------------------------------------------------------");
        let llavesCreadas = 0;
        let llavesOmitidas = 0;
        
        for (const l of llaves) {
            try {
                // Verificar si ya existe
                try {
                    await pb.collection('lugares').getFirstListItem(
                        `nombre="${l.nombre.replace(/"/g, '\\"')}" && zona="${l.zona}"`
                    );
                    console.log(`  (ya existe) ${l.nombre}`);
                    llavesOmitidas++;
                } catch (notFound) {
                    // Construir objeto de ubicación
                    const ubicacion = { zona: l.zona };
                    if (l.fila !== undefined) ubicacion.fila = l.fila;
                    if (l.columna !== undefined) ubicacion.columna = l.columna;
                    
                    await pb.collection('lugares').create({
                        nombre: l.nombre,
                        tipo: l.tipo,
                        edificio: l.edificio,
                        tablero: l.tablero,
                        zona: l.zona,
                        fila: l.fila || null,
                        columna: l.columna || null,
                        disponible: l.disponible,
                        esHibrido: l.esHibrido
                    });
                    llavesCreadas++;
                    console.log(`  ✓ ${l.nombre} [${l.zona}${l.fila ? ', fila ' + l.fila : ''}${l.columna ? ', col ' + l.columna : ''}]`);
                }
            } catch (error) {
                console.error(`  ✗ Error con llave "${l.nombre}":`, error.message);
            }
        }
        
        console.log(`  → Creadas: ${llavesCreadas} | Ya existían: ${llavesOmitidas} | Total: ${llaves.length}`);
        
        // ---- RESUMEN FINAL ----
        console.log("");
        console.log("==========================================================");
        console.log("  RESTAURACIÓN COMPLETADA");
        console.log("==========================================================");
        console.log(`  Vigilantes: ${vigilantesCreados} creados (${vigilantesOmitidos} ya existían)`);
        console.log(`  Llaves:     ${llavesCreadas} creadas (${llavesOmitidas} ya existían)`);
        console.log("");
        console.log("  VIGILANTES POR TURNO:");
        console.log("  Matutino:   Sylvia (Jefa), Claudia, Laura, Lourdes, Luis, Dahiana");
        console.log("  Vespertino: Martín (Jefe), Daniel, Nathia, Silvia, Alejandro, Caterin");
        console.log("  Nocturno:   Gustavo (Jefe), Mario, Silvana, Fernando");
        console.log("");
        console.log("  Actualice la página del sistema para ver los cambios.");
        console.log("==========================================================");
        
    } catch (error) {
        console.error("Error general durante la restauración:", error);
    }
}

// Ejecutar la restauración
restaurarDatos();
