import { useState, useCallback, useEffect, createContext, useContext, useRef } from 'react';
import { TipoUsuario, DepartamentoTAS, UsuarioRegistrado } from '@/data/fceaData';
import pb from '@/lib/pocketbase';
import React from 'react';

const mapRecord = (r: any): UsuarioRegistrado => ({
  id: r.id,
  nombre: r.nombre,
  celular: r.celular ?? '',
  email: r.email || undefined,
  tipo: r.tipo as TipoUsuario,
  departamento: r.departamento || undefined,
  nombreEmpresa: r.nombre_empresa || undefined,
  fechaRegistro: r.created,
});

interface UsuariosRegistradosContextType {
  usuarios: UsuarioRegistrado[];
  registrarUsuario: (datos: {
    nombre: string;
    celular: string;
    email?: string;
    tipo: TipoUsuario;
    departamento?: DepartamentoTAS;
    nombreEmpresa?: string;
  }) => Promise<UsuarioRegistrado>;
  buscarPorCelular: (celular: string) => UsuarioRegistrado | undefined;
  buscarPorTexto: (texto: string) => UsuarioRegistrado[];
}

const UsuariosRegistradosContext = createContext<UsuariosRegistradosContextType | null>(null);

export function UsuariosRegistradosProvider({ children }: { children: React.ReactNode }) {
  const [usuarios, setUsuarios] = useState<UsuarioRegistrado[]>([]);
  const usuariosRef = useRef<UsuarioRegistrado[]>([]);

  // Keep ref in sync
  useEffect(() => {
    usuariosRef.current = usuarios;
  }, [usuarios]);

  const cargar = useCallback(async () => {
    try {
      const records = await pb.collection('usuarios_registrados').getFullList({ sort: 'nombre' });
      const lista = records.map(mapRecord);
      setUsuarios(lista);
      usuariosRef.current = lista;
    } catch (e) {
      console.error('Error cargando usuarios:', e);
    }
  }, []);

  useEffect(() => { cargar(); }, [cargar]);

  const registrarUsuario = useCallback(async (datos: {
    nombre: string;
    celular: string;
    email?: string;
    tipo: TipoUsuario;
    departamento?: DepartamentoTAS;
    nombreEmpresa?: string;
  }): Promise<UsuarioRegistrado> => {
    // Verificar si ya existe por celular
    if (datos.celular) {
      const celularNorm = datos.celular.replace(/\D/g, '');
      const existente = usuariosRef.current.find(u => u.celular.replace(/\D/g, '') === celularNorm);
      if (existente) return existente;
    }
    // Verificar si ya existe por email
    if (datos.email) {
      const existente = usuariosRef.current.find(u => u.email?.toLowerCase() === datos.email!.toLowerCase());
      if (existente) return existente;
    }

    try {
      const record = await pb.collection('usuarios_registrados').create({
        nombre: datos.nombre,
        celular: datos.celular,
        email: datos.email ?? '',
        tipo: datos.tipo,
        departamento: datos.departamento ?? '',
        nombre_empresa: datos.nombreEmpresa ?? '',
      });
      const nuevo = mapRecord(record);
      const updated = [...usuariosRef.current, nuevo].sort((a, b) => a.nombre.localeCompare(b.nombre));
      setUsuarios(updated);
      usuariosRef.current = updated;
      return nuevo;
    } catch (e) {
      console.error('Error registrando usuario:', e);
      throw e;
    }
  }, []);

  const buscarPorCelular = useCallback((celular: string): UsuarioRegistrado | undefined => {
    const celularNorm = celular.replace(/\D/g, '');
    return usuariosRef.current.find(u => u.celular.replace(/\D/g, '') === celularNorm);
  }, []);

  const buscarPorTexto = useCallback((texto: string): UsuarioRegistrado[] => {
    if (!texto.trim()) return [];
    
    const norm = (t: string) => t.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    const textoNorm = norm(texto);
    const celularBusqueda = texto.replace(/\D/g, '');
    const currentUsuarios = usuariosRef.current;
    
    // Verificar si es búsqueda por celular (solo números)
    if (/^\d+$/.test(texto)) {
      return currentUsuarios.filter(u => u.celular && u.celular.replace(/\D/g, '').includes(celularBusqueda));
    }
    
    // Verificar si es búsqueda por email
    if (texto.includes('@')) {
      return currentUsuarios.filter(u => u.email && norm(u.email).includes(textoNorm));
    }
    
    // Búsqueda por nombre y apellido
    const palabras = textoNorm.split(' ').filter(p => p.length > 0);
    
    if (palabras.length === 1) {
      const palabra = palabras[0];
      return currentUsuarios.filter(u => {
        const nombreNorm = norm(u.nombre);
        const nombreParts = nombreNorm.split(' ');
        
        if (palabra.length === 1) {
          return nombreParts[0].startsWith(palabra);
        }
        
        return nombreParts[0] === palabra || nombreNorm.includes(palabra);
      });
    } else if (palabras.length >= 2) {
      const nombre = palabras[0];
      const apellido = palabras.slice(1).join(' ');
      
      return currentUsuarios.filter(u => {
        const nombreNorm = norm(u.nombre);
        const nombreParts = nombreNorm.split(' ');
        
        const primerNombreCoincide = nombreParts[0] === nombre || nombreParts[0].startsWith(nombre);
        
        if (apellido.length === 1) {
          const posibleApellido = nombreParts.length > 1 ? nombreParts[1] : '';
          return primerNombreCoincide && posibleApellido.startsWith(apellido);
        }
        
        const restoNombre = nombreParts.slice(1).join(' ');
        return primerNombreCoincide && restoNombre.includes(apellido);
      });
    }
    
    // Fallback
    return currentUsuarios.filter(u => {
      const nombreMatch = norm(u.nombre).includes(textoNorm);
      const celularMatch = u.celular && u.celular.replace(/\D/g, '').includes(celularBusqueda);
      const emailMatch = u.email && norm(u.email).includes(textoNorm);
      return nombreMatch || celularMatch || emailMatch;
    });
  }, []);

  const value = { usuarios, registrarUsuario, buscarPorCelular, buscarPorTexto };

  return React.createElement(UsuariosRegistradosContext.Provider, { value }, children);
}

export function useUsuariosRegistrados() {
  const context = useContext(UsuariosRegistradosContext);
  if (!context) {
    // Fallback for backward compatibility - create standalone instance
    // This should not happen if UsuariosRegistradosProvider is used
    throw new Error('useUsuariosRegistrados must be used within UsuariosRegistradosProvider');
  }
  return context;
}
