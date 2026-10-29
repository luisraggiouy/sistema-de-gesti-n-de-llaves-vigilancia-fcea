// =============================================================
// VisorInforme.tsx  —  Vista del informe exportado (modo OFFLINE)
//
// Es lo que ve la AUTORIDAD al abrir el informe exportado a pendrive
// en su propia PC (sin PocketBase). Reutiliza EXACTAMENTE los mismos
// componentes que el Monitor:
//   - <Dashboard/>  : KPIs, graficos, periodos (hoy/mensual/semestral),
//                     desempeno por vigilante y objetos olvidados.
//   - <KeyHistorySearch/> : el MISMO buscador historico de llaves, con
//                     filtro por rango de fechas y notas.
//
// Los datos vienen del snapshot embebido (window.__FCEA_SNAPSHOT__),
// que los hooks ya saben leer en "modo visor". Aqui ademas precargamos
// las autorizaciones en localStorage, porque getAutorizaciones() las
// lee de ahi.
// =============================================================
import { useState, useEffect } from 'react';
import Dashboard from './Dashboard';
import { KeyHistorySearch } from '@/components/monitor/KeyHistorySearch';
import { Button } from '@/components/ui/button';
import { Search } from 'lucide-react';
import { getVisorSnapshot } from '@/lib/visorSnapshot';

export default function VisorInforme() {
  const [historialOpen, setHistorialOpen] = useState(false);

  // Precargar autorizaciones del snapshot en localStorage (getAutorizaciones
  // las lee de ahi). Se hace una sola vez al montar.
  useEffect(() => {
    const snap = getVisorSnapshot();
    if (snap && Array.isArray(snap.autorizaciones)) {
      try {
        localStorage.setItem('fcea_autorizaciones_v1', JSON.stringify(snap.autorizaciones));
      } catch { /* noop */ }
    }
  }, []);

  return (
    <div className="relative">
      {/* Banner de contexto: deja claro que es una copia para consulta. */}
      <div className="bg-blue-900 text-white text-center text-sm py-2 px-4">
        Informe de desempeño y trazabilidad de llaves — copia para consulta
        (datos congelados al momento de la exportación). Usá el buscador para
        filtrar por fechas.
      </div>

      {/* El mismo Dashboard del Monitor, con los datos del snapshot. */}
      <Dashboard />

      {/* Boton flotante para abrir el MISMO buscador historico del Monitor. */}
      <div className="fixed bottom-6 right-6 z-50">
        <Button
          size="lg"
          className="shadow-lg gap-2"
          onClick={() => setHistorialOpen(true)}
        >
          <Search className="w-5 h-5" />
          Buscador Histórico de Llaves
        </Button>
      </div>

      <KeyHistorySearch open={historialOpen} onOpenChange={setHistorialOpen} />
    </div>
  );
}
