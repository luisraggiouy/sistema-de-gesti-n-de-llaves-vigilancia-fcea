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
    const textoNorm = norm(texto.trim());
    const celularBusqueda = texto.replace(/\D/g, '');
    const currentUsuarios = usuariosRef.current;

    // Búsqueda por celular (solo dígitos)
    if (/^\d+$/.test(texto.trim())) {
      return currentUsuarios.filter(u => u.celular && u.celular.replace(/\D/g, '').includes(celularBusqueda));
    }

    // Búsqueda por email
    if (texto.includes('@')) {
      return currentUsuarios.filter(u => u.email && norm(u.email).includes(textoNorm));
    }

    // Búsqueda general: busca en nombre, empresa y departamento
    // Todas las palabras escritas deben aparecer en algún campo del usuario
    const palabras = textoNorm.split(/\s+/).filter(p => p.length > 0);

    return currentUsuarios.filter(u => {
      const campos = [
        norm(u.nombre),
        u.celular ? u.celular.replace(/\D/g, '') : '',
        u.email ? norm(u.email) : '',
        u.nombreEmpresa ? norm(u.nombreEmpresa) : '',
        u.departamento ? norm(u.departamento) : '',
        norm(u.tipo),
      ].join(' ');

      return palabras.every(p => campos.includes(p));
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
