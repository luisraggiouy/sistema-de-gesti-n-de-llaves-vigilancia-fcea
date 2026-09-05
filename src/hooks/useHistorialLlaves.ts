import { useState, useCallback, useEffect, useMemo, useRef } from 'react';
import { Lugar } from '@/data/fceaData';
import pb from '@/lib/pocketbase';

interface HistorialEntry {
  lugarId: string;
  count: number;
  lastUsed: string;
}

interface HistorialUsuario {
  pbId?: string;
  usuarioId: string;
  llaves: HistorialEntry[];
  // Fix 2026-09-05 (llaves frecuentes): ids de registros DUPLICADOS del mismo
  // usuario_id detectados al cargar. Se borran de PocketBase en el proximo
  // registrarUsos para consolidar el historial en un unico registro canonico.
  duplicados?: string[];
}

// Fusiona una llave (lugarId) dentro de una lista de HistorialEntry, sumando el
// count si ya existe o agregandola si es nueva. Muta la lista recibida.
function fusionarLlave(llaves: HistorialEntry[], lugarId: string, cantidad = 1, lastUsed?: string) {
  const ts = lastUsed ?? new Date().toISOString();
  const existente = llaves.find(l => l.lugarId === lugarId);
  if (existente) {
    existente.count += cantidad;
    if (ts > existente.lastUsed) existente.lastUsed = ts;
  } else {
    llaves.push({ lugarId, count: cantidad, lastUsed: ts });
  }
}

export function useHistorialLlaves(usuarioId: string | null, lugares: Lugar[] = []) {
  const [historial, setHistorial] = useState<HistorialUsuario[]>([]);
  // Ref con el ultimo historial para poder leer el estado actual dentro de
  // registrarUsos sin depender de closures viejos (evita la condicion de carrera
  // que generaba multiples registros al pedir varias llaves de golpe).
  const historialRef = useRef<HistorialUsuario[]>([]);
  useEffect(() => { historialRef.current = historial; }, [historial]);

  const cargar = useCallback(async () => {
    try {
      // Ordenamos por 'created' para que el registro MAS ANTIGUO de cada usuario
      // sea el canonico (el que conserva su pbId); los demas se marcan como
      // duplicados a limpiar.
      const records = await pb.collection('historial_llaves').getFullList({ sort: 'created' });
      const porUsuario = new Map<string, HistorialUsuario>();

      for (const r of records as any[]) {
        const llaves: HistorialEntry[] = typeof r.llaves === 'string'
          ? JSON.parse(r.llaves)
          : (r.llaves ?? []);
        const existente = porUsuario.get(r.usuario_id);
        if (!existente) {
          porUsuario.set(r.usuario_id, {
            pbId: r.id,
            usuarioId: r.usuario_id,
            llaves: llaves.map(l => ({ ...l })),
            duplicados: [],
          });
        } else {
          // Fix 2026-09-05: MERGE de registros duplicados del mismo usuario.
          // Antes el frontend tomaba solo el primer registro (parcial) y el
          // usuario "perdia" llaves frecuentes (caso Milton de Souza: 10
          // registros, se veian 3 de 11 llaves).
          for (const ll of llaves) {
            fusionarLlave(existente.llaves, ll.lugarId, ll.count, ll.lastUsed);
          }
          existente.duplicados!.push(r.id);
        }
      }

      const lista = [...porUsuario.values()];
      setHistorial(lista);
      historialRef.current = lista;
    } catch (e) {
      console.warn('historial_llaves no disponible:', e);
    }
  }, []);

  useEffect(() => {
    cargar();
  }, [cargar]);

  // Forzar recarga cuando cambia el usuario
  useEffect(() => {
    if (usuarioId) {
      console.log("Cargando historial para usuario:", usuarioId);
      cargar();
    }
  }, [usuarioId, cargar]);

  const llavesFrecuentes = useMemo((): Lugar[] => {
    if (!usuarioId) {
      console.log("No hay usuario seleccionado para llaves frecuentes");
      return [];
    }
    
    if (lugares.length === 0) {
      console.log("No hay lugares disponibles");
      return [];
    }
    
    const usuarioHistorial = historial.find(h => h.usuarioId === usuarioId);
    if (!usuarioHistorial) {
      console.log("No se encontró historial para el usuario:", usuarioId);
      return [];
    }
    
    console.log("Historial encontrado:", usuarioHistorial.llaves.length, "llaves");
    
    // Ordenar por frecuencia de uso (count) de mayor a menor
    // Cambio 2026-09-05: se muestran hasta 50 llaves frecuentes (antes 7). El
    // historial se guarda SIN limite; este slice es solo cuantas se muestran en
    // pantalla, ordenadas de la mas usada a la menos usada.
    const llavesOrdenadas = [...usuarioHistorial.llaves]
      .sort((a, b) => b.count - a.count)
      .slice(0, 50); // Mostrar hasta 50 llaves frecuentes
    
    console.log("Llaves ordenadas por frecuencia:", llavesOrdenadas);
    
    // Mapear a objetos Lugar y filtrar los que no existen
    // NOTA: No filtramos por disponibilidad aquí porque lugaresDisponibles del contexto
    // ya contiene solo las llaves disponibles (filtradas dinámicamente)
    const llavesMapeadas = llavesOrdenadas
      .map(entry => {
        const lugar = lugares.find(l => l.id === entry.lugarId);
        if (!lugar) console.log("Llave no encontrada:", entry.lugarId);
        return lugar;
      })
      .filter((l): l is Lugar => l !== undefined);
    
    console.log("Llaves frecuentes disponibles:", llavesMapeadas.length);
    return llavesMapeadas;
  }, [usuarioId, historial, lugares]);

  // Fix 2026-09-05 (CLAVE): registra el uso de VARIAS llaves en UNA sola
  // operacion contra PocketBase. Antes TerminalUsuario hacia
  // selectedKeys.forEach(k => registrarUso(k.id)), disparando N llamadas casi
  // simultaneas; como la primera aun no tenia pbId, se creaban N registros
  // duplicados (condicion de carrera). Ahora es una unica llamada atomica.
  // Ademas, si el usuario tenia registros duplicados de antes, los borra para
  // dejar un unico registro canonico consolidado.
  const registrarUsos = useCallback(async (lugarIds: string[]) => {
    if (!usuarioId) {
      console.log("No se puede registrar uso sin usuario");
      return;
    }
    if (!lugarIds || lugarIds.length === 0) return;

    // Clonar el historial actual (desde la ref, siempre al dia)
    const actual = historialRef.current;
    const nuevo = actual.map(h => ({
      ...h,
      llaves: h.llaves.map(l => ({ ...l })),
      duplicados: [...(h.duplicados ?? [])],
    }));

    let entry = nuevo.find(h => h.usuarioId === usuarioId);
    if (!entry) {
      entry = { usuarioId, llaves: [], duplicados: [] };
      nuevo.push(entry);
    }

    for (const lugarId of lugarIds) {
      fusionarLlave(entry.llaves, lugarId);
    }

    // Actualizar estado local inmediatamente
    historialRef.current = nuevo;
    setHistorial(nuevo);

    // Persistir en PocketBase con UNA sola operacion
    try {
      if (entry.pbId) {
        await pb.collection('historial_llaves').update(entry.pbId, {
          llaves: JSON.stringify(entry.llaves),
        });
        console.log("Historial actualizado (canonico):", entry.pbId);
      } else {
        const record = await pb.collection('historial_llaves').create({
          usuario_id: usuarioId,
          llaves: JSON.stringify(entry.llaves),
        });
        entry.pbId = record.id;
        console.log("Nuevo historial creado con ID:", record.id);
      }

      // Limpiar registros duplicados viejos de este usuario (si los habia).
      const dups = entry.duplicados ?? [];
      if (dups.length > 0) {
        console.log(`Limpiando ${dups.length} registro(s) duplicado(s) de historial`);
        for (const dupId of dups) {
          try {
            await pb.collection('historial_llaves').delete(dupId);
          } catch (e) {
            console.warn("No se pudo borrar duplicado", dupId, e);
          }
        }
        entry.duplicados = [];
      }
    } catch (e) {
      console.error("Error persistiendo historial:", e);
    }
  }, [usuarioId]);

  // Compatibilidad: registrar el uso de UNA sola llave (usado por el intercambio).
  const registrarUso = useCallback((lugarId: string) => {
    return registrarUsos([lugarId]);
  }, [registrarUsos]);

  return { llavesFrecuentes, registrarUso, registrarUsos };
}