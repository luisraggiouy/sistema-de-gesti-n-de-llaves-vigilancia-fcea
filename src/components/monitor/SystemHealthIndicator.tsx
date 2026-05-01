import { useEffect, useState } from 'react';
import { CheckCircle, AlertTriangle, AlertCircle } from 'lucide-react';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

interface SystemHealth {
  timestamp: string;
  overallStatus: 'healthy' | 'warning' | 'critical';
  alerts: Array<{
    level: string;
    title: string;
  }>;
}

export function SystemHealthIndicator() {
  const [healthData, setHealthData] = useState<SystemHealth | null>(null);

  const fetchHealthData = async () => {
    try {
      const response = await fetch(`/system_health.json?t=${Date.now()}`);
      if (response.ok) {
        const data = await response.json();
        setHealthData(data);
      }
    } catch (error) {
      console.error('Error al cargar estado de salud:', error);
    }
  };

  useEffect(() => {
    fetchHealthData();
    const interval = setInterval(fetchHealthData, 5 * 60 * 1000); // Cada 5 minutos
    return () => clearInterval(interval);
  }, []);

  if (!healthData) return null;

  const getStatusIcon = () => {
    switch (healthData.overallStatus) {
      case 'critical':
        return <AlertCircle className="w-3 h-3 text-red-500" />;
      case 'warning':
        return <AlertTriangle className="w-3 h-3 text-yellow-500" />;
      default:
        return <CheckCircle className="w-3 h-3 text-green-500" />;
    }
  };

  const getStatusText = () => {
    switch (healthData.overallStatus) {
      case 'critical':
        return 'Sistema: Crítico';
      case 'warning':
        return 'Sistema: Advertencia';
      default:
        return 'Sistema: OK';
    }
  };

  const getTooltipContent = () => {
    if (healthData.alerts.length === 0) {
      return 'Sistema funcionando correctamente';
    }
    return `${healthData.alerts.length} alerta${healthData.alerts.length > 1 ? 's' : ''} - Ver Monitor para detalles`;
  };

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <div className="flex items-center gap-1.5 text-xs cursor-help">
            {getStatusIcon()}
            <span className="text-muted-foreground">{getStatusText()}</span>
          </div>
        </TooltipTrigger>
        <TooltipContent>
          <p>{getTooltipContent()}</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
