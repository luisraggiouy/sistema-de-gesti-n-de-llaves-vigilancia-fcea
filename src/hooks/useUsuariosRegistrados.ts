import { useState, useCallback, useEffect } from 'react';
import { 
  UsuarioRegistrado, 
  getUsuariosRegistrados, 
  guardarUsuario, 
  buscarUsuarioPorCelular,
  buscarUsuariosPorTexto,
  TipoUsuario,
  DepartamentoTAS
} from '@/data/fceaData';

export function useUsuariosRegistrados() {
  const [usuarios, setUsuarios] = useState<UsuarioRegistrado[]>([]);

  // Cargar usuarios al montar
  useEffect(() => {
    setUsuarios(getUsuariosRegistrados());
  }, []);

  const registrarUsuario = useCallback((datos: {
    nombre: string;
    celular: string;
    email?: string;
    tipo: TipoUsuario;
    departamento?: DepartamentoTAS;
    nombreEmpresa?: string;
  }) => {
    const nuevoUsuario = guardarUsuario(datos);
    setUsuarios(getUsuariosRegistrados());
    return nuevoUsuario;
  }, []);

  const buscarPorCelular = useCallback((celular: string) => {
    return buscarUsuarioPorCelular(celular);
  }, []);

  const buscarPorTexto = useCallback((texto: string) => {
    return buscarUsuariosPorTexto(texto);
  }, []);

  return {
    usuarios,
    registrarUsuario,
    buscarPorCelular,
    buscarPorTexto
  };
}
