import { useState, useCallback, useEffect, useMemo } from 'react';
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
}

export function useHistorialLlaves(usuarioId: string | null, lugares: Lugar[] = []) {
  const [historial, setHistorial] = useState<HistorialUsuario[]>([]);

  const cargar = useCallback(async () => {
    try {
      const records = await pb.collection('historial_llaves').getFullList();
      const lista: HistorialUsuario[] = records.map((r: any) => ({
        pbId: r.id,
        usuarioId: r.usuario_id,
        llaves: typeof r.llaves === 'string' ? JSON.parse(r.llaves) : (r.llaves ?? []),
      }));
      setHistorial(lista);
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
    const llavesOrdenadas = [...usuarioHistorial.llaves]
      .sort((a, b) => b.count - a.count)
      .slice(0, 7); // Mostrar hasta 7 llaves frecuentes
    
    console.log("Llaves ordenadas por frecuencia:", llavesOrdenadas);
    
    // Mapear a objetos Lugar y filtrar los que no existen o no están disponibles
    const llavesMapeadas = llavesOrdenadas
      .map(entry => {
        const lugar = lugares.find(l => l.id === entry.lugarId);
        if (!lugar) console.log("Llave no encontrada:", entry.lugarId);
        return lugar;
      })
      .filter((l): l is Lugar => l !== undefined && l.disponible);
    
    console.log("Llaves frecuentes disponibles:", llavesMapeadas.length);
    return llavesMapeadas;
  }, [usuarioId, historial, lugares]);

  const registrarUso = useCallback(async (lugarId: string) => {
    if (!usuarioId) {
      console.log("No se puede registrar uso sin usuario");
      return;
    }

    console.log("Registrando uso de llave:", lugarId, "para usuario:", usuarioId);
    
    setHistorial(prevHistorial => {
      const newHistorial = [...prevHistorial];
      let usuarioEntry = newHistorial.find(h => h.usuarioId === usuarioId);

      if (!usuarioEntry) {
        usuarioEntry = { usuarioId, llaves: [] };
        newHistorial.push(usuarioEntry);
      }

      const llaveEntry = usuarioEntry.llaves.find(l => l.lugarId === lugarId);
      if (llaveEntry) {
        llaveEntry.count += 1;
        llaveEntry.lastUsed = new Date().toISOString();
      } else {
        usuarioEntry.llaves.push({ lugarId, count: 1, lastUsed: new Date().toISOString() });
      }

      const entry = usuarioEntry;
      if (entry.pbId) {
        console.log("Actualizando historial existente");
        pb.collection('historial_llaves')
          .update(entry.pbId, { llaves: JSON.stringify(entry.llaves) })
          .then(() => console.log("Historial actualizado correctamente"))
          .catch(e => console.error("Error actualizando historial:", e));
      } else {
        console.log("Creando nuevo historial");
        pb.collection('historial_llaves')
          .create({ usuario_id: usuarioId, llaves: JSON.stringify(entry.llaves) })
          .then(record => { 
            entry.pbId = record.id;
            console.log("Nuevo historial creado con ID:", record.id);
          })
          .catch(e => console.error("Error creando historial:", e));
      }

      return newHistorial;
    });
  }, [usuarioId]);

  return { llavesFrecuentes, registrarUso };
}