export type EstadoObjeto = 'custodia' | 'devuelto';

export interface ObjetoOlvidado {
  id: string;
  descripcion: string;
  lugarEncontrado?: string;
  fechaRegistro: Date;
  fotos: {
    general: string; // base64
    marca: string; // base64
    adicional?: string; // base64 (opcional)
  };
  registradoPor: string; // vigilante
  estado: EstadoObjeto;
  // Datos de devolución
  devolucion?: {
    fecha: Date;
    vigilanteEntrega: string;
    nombreReceptor: string;
    cedulaReceptor: string;
  };
}
