import { ReactNode } from 'react';
import { Clock, Users, Key, BarChart3 } from 'lucide-react';
import fceaLogo from '@/assets/fcea-logo.png';
import { Link } from 'react-router-dom';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { useDeviceConfig } from '@/hooks/useDeviceConfig';
import { obtenerTurnoActual, obtenerVigilantesActuales } from '@/data/fceaData';
import { SystemHealthIndicator } from './SystemHealthIndicator';

interface MonitorHeaderProps {
  pendientes: number;
  enUso: number;
  children?: ReactNode;
}

export function MonitorHeader({ pendientes, enUso, children }: MonitorHeaderProps) {
  const { shouldShowNavigationButtons, shouldShowDashboardButton } = useDeviceConfig();
  const turnoActual = obtenerTurnoActual();
  const vigilantes = obtenerVigilantesActuales();
  const jefe = vigilantes.find(v => v.esJefe);
  
  const ahora = new Date();
  const hora = ahora.toLocaleTimeString('es-UY', { 
    hour: '2-digit', 
    minute: '2-digit',
    second: '2-digit'
  });
  const fecha = ahora.toLocaleDateString('es-UY', { 
    weekday: 'long', 
    day: 'numeric',
    month: 'long'
  });

  const getTurnoInfo = () => {
    switch (turnoActual) {
      case 'Matutino':
        return { label: 'Matutino', horario: '06:00 - 14:00', color: 'bg-amber-500' };
      case 'Vespertino':
        return { label: 'Vespertino', horario: '14:00 - 22:00', color: 'bg-blue-500' };
      case 'Nocturno':
        return { label: 'Nocturno', horario: '22:00 - 06:00', color: 'bg-indigo-900' };
    }
  };

  const turnoInfo = getTurnoInfo();

  return (
    <header className="bg-card border-b py-4 px-6 shadow-sm">
      <div className="max-w-7xl mx-auto space-y-3">
        {/* Fila 1: Logo, info turno, hora */}
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <img src={fceaLogo} alt="FCEA - Universidad de la República" className="h-[5.85rem] w-auto" />
            <div>
              <h1 className="text-2xl font-bold tracking-tight">
                Monitor de Vigilancia
              </h1>
              <p className="text-muted-foreground text-sm">
                FCEA - Sistema de Gestión de Llaves
              </p>
            </div>
          </div>

          <div className="flex items-center gap-6">
            <div className="flex items-center gap-3">
              <Badge className={`${turnoInfo.color} text-white px-3 py-1`}>
                {turnoInfo.label}
              </Badge>
              <div className="text-sm">
                <p className="font-medium">{turnoInfo.horario}</p>
                {jefe && (
                  <p className="text-muted-foreground">Jefe: {jefe.nombre}</p>
                )}
              </div>
            </div>

            <div className="flex items-center gap-2 text-sm">
              <Users className="w-4 h-4 text-muted-foreground" />
              <span className="font-medium">{vigilantes.length}</span>
              <span className="text-muted-foreground">vigilantes</span>
            </div>

            <div className="flex items-center gap-4">
              <div className="text-center px-4 py-2 bg-warning/10 rounded-lg">
                <p className="text-2xl font-bold text-warning">{pendientes}</p>
                <p className="text-xs text-muted-foreground">Pendientes</p>
              </div>
              <div className="text-center px-4 py-2 bg-success/10 rounded-lg">
                <p className="text-2xl font-bold text-success">{enUso}</p>
                <p className="text-xs text-muted-foreground">En uso</p>
              </div>
            </div>

            <div className="text-right space-y-1">
              <p className="text-xl font-mono font-bold flex items-center gap-2 justify-end">
                <Clock className="w-5 h-5 text-muted-foreground" />
                {hora}
              </p>
              <p className="text-sm text-muted-foreground capitalize">{fecha}</p>
              <SystemHealthIndicator />
            </div>
          </div>
        </div>

        {/*
          Fila 2: Botones de navegación y funcionalidades.

          v2.6 (P7 - piloto FCEA jueves 2026-07-23):
          `shouldShowNavigationButtons` viene de useDeviceConfig() y es
          FALSE cuando `hardware === "tactil"` (Terminal en modo kiosk).
          Es decir:
            - En Terminal A / Terminal B (kiosk tactil): NO se muestran
              los botones "Terminal Usuario" ni "Dashboard". Esto es
              intencional para producción: los usuarios finales no
              tienen que poder saltar entre pantallas. Si un vigilante
              necesita el Dashboard va desde el navegador manualmente
              (Ctrl+L → URL).
            - En Monitor Vigilancia (PC con monitor + teclado + mouse,
              hardware="estandar"): SÍ se muestran, porque ese equipo
              lo maneja el jefe de vigilancia y precisa poder navegar.
          Si en el jueves esto no se cumple, revisar el config.json de
          cada máquina y confirmar que las Terminales tienen
          `"hardware": "tactil"`.
        */}
        {/*
          v2.7 (P6): En producción el botón "Terminal Usuario" se OCULTA
          siempre en el Monitor de Vigilancia. Era útil solo en desarrollo
          para saltar entre pantallas. Los vigilantes NO deben navegar al
          Terminal desde acá (los Terminales A/B tienen su propia PC en
          modo kiosk). Se mantiene solo bajo `import.meta.env.DEV` — en
          build de producción Vite tree-shakea el nodo entero.

          El botón "Dashboard" sí se mantiene: el jefe de vigilancia
          precisa poder ver estadísticas. La condición
          `shouldShowNavigationButtons` sigue vigente para el caso de
          Terminales en modo kiosk (allí no se muestra ninguno).
        */}
        <div className="flex flex-wrap items-center gap-2 pt-2 border-t border-border/50">
          {shouldShowNavigationButtons && import.meta.env.DEV && (
            <Button
              asChild
              variant="outline"
              size="sm"
              className="gap-2"
            >
              <Link to="/">
                <Key className="w-4 h-4" />
                Terminal Usuario
              </Link>
            </Button>
          )}
          {/*
            v2.8 (piloto domingo 2026-07-26): el boton Dashboard usa su
            propia flag `shouldShowDashboardButton` en vez de la general
            `shouldShowNavigationButtons`. La diferencia importa cuando el
            Monitor corre en una PC con touchscreen (hardware="tactil"):
            en ese caso `shouldShowNavigationButtons` era FALSE y el
            Dashboard desaparecia del header, obligando al jefe a
            escribir la URL a mano. Con `shouldShowDashboardButton`
            (isDevMode || isTradicional || hardware === undefined) el
            boton reaparece en el Monitor y sigue oculto en las
            Terminales de usuario (que no muestran este header).
          */}
          {shouldShowDashboardButton && (
            <Button
              asChild
              variant="outline"
              size="sm"
              className="gap-2"
            >
              <Link to="/dashboard">
                <BarChart3 className="w-4 h-4" />
                Dashboard
              </Link>
            </Button>
          )}
          {children}
        </div>
      </div>
    </header>
  );
}
