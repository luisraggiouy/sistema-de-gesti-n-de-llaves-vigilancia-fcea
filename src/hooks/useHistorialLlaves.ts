import { useState, useEffect, useCallback, useMemo } from 'react';
import { Lugar, lugares } from '@/data/fceaData';

const STORAGE_KEY = 'fcea_historial_llaves';

interface HistorialEntry {
  lugarId: string;
  count: number;
  lastUsed: string;
}

interface HistorialUsuario {
  usuarioId: string;
  llaves: HistorialEntry[];
}

function getHistorial(): HistorialUsuario[] {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : [];
  } catch {
    return [];
  }
}

function saveHistorial(historial: HistorialUsuario[]): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(historial));
}

export function useHistorialLlaves(usuarioId: string | null) {
  const [historial, setHistorial] = useState<HistorialUsuario[]>(getHistorial);

  // Recargar cuando cambia el usuario
  useEffect(() => {
    setHistorial(getHistorial());
  }, [usuarioId]);

  // Obtener llaves frecuentes para el usuario actual
  const llavesFrecuentes = useMemo((): Lugar[] => {
    if (!usuarioId) return [];
    
    const usuarioHistorial = historial.find(h => h.usuarioId === usuarioId);
    if (!usuarioHistorial) return [];

    // Ordenar por frecuencia y tomar las top 5
    const sorted = [...usuarioHistorial.llaves]
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    // Mapear a Lugares reales (solo disponibles)
    return sorted
      .map(entry => lugares.find(l => l.id === entry.lugarId))
      .filter((l): l is Lugar => l !== undefined && l.disponible);
  }, [usuarioId, historial]);

  // Registrar uso de una llave
  const registrarUso = useCallback((lugarId: string) => {
    if (!usuarioId) return;

    setHistorial(prevHistorial => {
      const newHistorial = [...prevHistorial];
      let usuarioEntry = newHistorial.find(h => h.usuarioId === usuarioId);

      if (!usuarioEntry) {
        usuarioEntry = { usuarioId, llaves: [] };
        newHistorial.push(usuarioEntry);
      }

      let llaveEntry = usuarioEntry.llaves.find(l => l.lugarId === lugarId);

      if (llaveEntry) {
        llaveEntry.count += 1;
        llaveEntry.lastUsed = new Date().toISOString();
      } else {
        usuarioEntry.llaves.push({
          lugarId,
          count: 1,
          lastUsed: new Date().toISOString()
        });
      }

      saveHistorial(newHistorial);
      return newHistorial;
    });
  }, [usuarioId]);

  return {
    llavesFrecuentes,
    registrarUso
  };
}
