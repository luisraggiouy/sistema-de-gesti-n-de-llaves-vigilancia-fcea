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

// -------------------------------------------------------------------------
// FIX 2026-07-31 — Duplicados en la busqueda por telefono (Terminal A).
//
// CAUSA RAIZ: la suscripcion en tiempo real (create/update) agregaba
// registros a la lista SIN deduplicar por id. Como PocketBase le manda el
// evento 'create' al MISMO cliente que ya lo agrego en registrarUsuario, el
// mismo registro quedaba 2-3 veces en memoria, con el MISMO React key
// (usuario.id) -> React renderizaba filas repetidas y "fantasma" (p.ej. un
// usuario que NO coincidia con el filtro). En la base NO hay duplicados
// (confirmado con DIAGNOSTICO_DUPLICADOS_USUARIOS_2026-07-31).
//
// SOLUCION: mantener SIEMPRE la lista deduplicada por id (upsert) y ordenada
// por nombre. dedupeById conserva el ULTIMO valor visto (el mas fresco), asi
// que agregar al final = upsert.
// -------------------------------------------------------------------------
const dedupeById = (lista: UsuarioRegistrado[]): UsuarioRegistrado[] => {
  const map = new Map<string, UsuarioRegistrado>();
  for (const u of lista) map.set(u.id, u);
  return Array.from(map.values());
};

const ordenarPorNombre = (lista: UsuarioRegistrado[]): UsuarioRegistrado[] =>
  [...lista].sort((a, b) => a.nombre.localeCompare(b.nombre));

const normalizarLista = (lista: UsuarioRegistrado[]): UsuarioRegistrado[] =>
  ordenarPorNombre(dedupeById(lista));


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
      const lista = normalizarLista(records.map(mapRecord));
      setUsuarios(lista);
      usuariosRef.current = lista;

    } catch (e) {
      console.error('Error cargando usuarios:', e);
    }
  }, []);

  useEffect(() => { cargar(); }, [cargar]);

  // Suscripción en tiempo real: si un usuario es creado, editado o borrado
  // desde la agenda del monitor, la terminal se actualiza automáticamente.
  useEffect(() => {
    let unsubscribe: (() => void) | null = null;

    const suscribir = async () => {
      try {
        unsubscribe = await pb.collection('usuarios_registrados').subscribe('*', (e) => {
          if (e.action === 'delete') {
            // Eliminar el usuario borrado de la lista en memoria
            const updated = usuariosRef.current.filter(u => u.id !== e.record.id);
            setUsuarios(updated);
            usuariosRef.current = updated;
            console.log('[Usuarios] Usuario eliminado de la agenda, actualizado en terminal:', e.record.id);
          } else if (e.action === 'create') {
            // Agregar el nuevo usuario. dedupeById evita que quede repetido si
            // este mismo cliente ya lo agrego en registrarUsuario (o si el
            // evento llega mas de una vez tras una reconexion).
            const nuevo = mapRecord(e.record);
            const updated = normalizarLista([...usuariosRef.current, nuevo]);
            setUsuarios(updated);
            usuariosRef.current = updated;
          } else if (e.action === 'update') {
            // Actualizar el usuario modificado (upsert: reemplaza si existe,
            // agrega si no; siempre sin duplicar por id).
            const nuevo = mapRecord(e.record);
            const updated = normalizarLista([...usuariosRef.current, nuevo]);
            setUsuarios(updated);
            usuariosRef.current = updated;
          }

        }) as unknown as () => void;
      } catch (e) {
        console.warn('[Usuarios] No se pudo suscribir a cambios en tiempo real:', e);
      }
    };

    suscribir();

    return () => {
      if (unsubscribe) {
        try { unsubscribe(); } catch (_) {}
      }
    };
  }, []);

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
      const updated = normalizarLista([...usuariosRef.current, nuevo]);
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

    // SEGURIDAD: Solo se permite buscar por celular o por email.
    // La busqueda por nombre esta deshabilitada para evitar suplantacion de identidad.

    // Busqueda por celular: si el texto contiene solo digitos (y posibles espacios/guiones)
    // FIX 2026-07-31: coincidencia ESTRICTA por prefijo (startsWith) en vez de
    // subcadena (includes). Asi, al tipear "099098765" solo matchean numeros que
    // EMPIEZAN con esos digitos, no que los contengan en el medio. Se deduplica
    // por id como red de seguridad extra.
    if (/^[\d\s\-\+\(\)]+$/.test(texto.trim()) && celularBusqueda.length >= 2) {
      return dedupeById(
        currentUsuarios.filter(u => u.celular && u.celular.replace(/\D/g, '').startsWith(celularBusqueda))
      );
    }

    // Busqueda por email: si el texto contiene @
    if (texto.includes('@')) {
      return dedupeById(currentUsuarios.filter(u => u.email && norm(u.email).includes(textoNorm)));
    }


    // Si el texto no es celular ni email, no devolver resultados
    // (evita busqueda por nombre que permitiria suplantacion de identidad)
    return [];
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
