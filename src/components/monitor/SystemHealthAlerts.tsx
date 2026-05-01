import { useEffect, useState } from 'react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  AlertCircle,
  AlertTriangle,
  CheckCircle,
  Database,
  HardDrive,
  FileText,
  Usb,
  XCircle,
  ChevronDown,
  ChevronUp,
  RefreshCw,
} from 'lucide-react';

interface SystemMetrics {
  diskSpacePercent: number;
  diskSpaceFreeGB: number;
  lastBackupDaysAgo: number;
  databaseSizeMB: number;
  lastMaintenanceDaysAgo: number;
  pendriveDaysOutdated: number;
}

interface SystemAlert {
  level: 'critical' | 'warning' | 'info';
  title: string;
  message: string;
  action: string;
  icon: string;
}

interface SystemHealth {
  timestamp: string;
  overallStatus: 'healthy' | 'warning' | 'critical';
  alerts: SystemAlert[];
  metrics: SystemMetrics;
}

const iconMap: Record<string, React.ComponentType<{ className?: string }>> = {
  'alert-circle': AlertCircle,
  'alert-triangle': AlertTriangle,
  'database': Database,
  'hard-drive': HardDrive,
  'file-text': FileText,
  'usb': Usb,
  'x-circle': XCircle,
};

export function SystemHealthAlerts() {
  const [healthData, setHealthData] = useState<SystemHealth | null>(null);
  const [isExpanded, setIsExpanded] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);

  const fetchHealthData = async () => {
    try {
      // Agregar timestamp para evitar caché
      const response = await fetch(`/system_health.json?t=${Date.now()}`);
      if (response.ok) {
        const data = await response.json();
        setHealthData(data);
        setLastUpdate(new Date());
        setIsLoading(false);
      }
    } catch (error) {
      console.error('Error al cargar estado de salud del sistema:', error);
      setIsLoading(false);
    }
  };

  useEffect(() => {
    // Cargar datos inicialmente
    fetchHealthData();

    // Actualizar cada 5 minutos
    const interval = setInterval(fetchHealthData, 5 * 60 * 1000);

    return () => clearInterval(interval);
  }, []);

  if (isLoading) {
    return null; // No mostrar nada mientras carga
  }

  if (!healthData || healthData.alerts.length === 0) {
    return null; // No mostrar si no hay alertas
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'critical':
        return 'bg-red-500';
      case 'warning':
        return 'bg-yellow-500';
      default:
        return 'bg-green-500';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'critical':
        return 'Crítico';
      case 'warning':
        return 'Advertencia';
      default:
        return 'Saludable';
    }
  };

  const getAlertVariant = (level: string): 'default' | 'destructive' => {
    return level === 'critical' ? 'destructive' : 'default';
  };

  const criticalAlerts = healthData.alerts.filter(a => a.level === 'critical');
  const warningAlerts = healthData.alerts.filter(a => a.level === 'warning');

  return (
    <Card className="border-2 border-orange-200 bg-orange-50/50">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`w-3 h-3 rounded-full ${getStatusColor(healthData.overallStatus)} animate-pulse`} />
            <CardTitle className="text-lg">
              Estado del Sistema: {getStatusText(healthData.overallStatus)}
            </CardTitle>
            {criticalAlerts.length > 0 && (
              <Badge variant="destructive" className="ml-2">
                {criticalAlerts.length} Crítico{criticalAlerts.length > 1 ? 's' : ''}
              </Badge>
            )}
            {warningAlerts.length > 0 && (
              <Badge variant="secondary" className="ml-2 bg-yellow-100 text-yellow-800">
                {warningAlerts.length} Advertencia{warningAlerts.length > 1 ? 's' : ''}
              </Badge>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={fetchHealthData}
              className="h-8"
            >
              <RefreshCw className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsExpanded(!isExpanded)}
              className="h-8"
            >
              {isExpanded ? (
                <ChevronUp className="h-4 w-4" />
              ) : (
                <ChevronDown className="h-4 w-4" />
              )}
            </Button>
          </div>
        </div>
        {lastUpdate && (
          <p className="text-xs text-muted-foreground mt-1">
            Última actualización: {lastUpdate.toLocaleTimeString('es-UY')}
          </p>
        )}
      </CardHeader>

      {isExpanded && (
        <CardContent className="space-y-3">
          {/* Alertas Críticas */}
          {criticalAlerts.map((alert, index) => {
            const IconComponent = iconMap[alert.icon] || AlertCircle;
            return (
              <Alert key={`critical-${index}`} variant={getAlertVariant(alert.level)}>
                <IconComponent className="h-4 w-4" />
                <AlertTitle className="font-semibold">{alert.title}</AlertTitle>
                <AlertDescription className="mt-2 space-y-2">
                  <p>{alert.message}</p>
                  <p className="text-sm font-medium bg-red-100 dark:bg-red-900/20 p-2 rounded">
                    <strong>Acción requerida:</strong> {alert.action}
                  </p>
                </AlertDescription>
              </Alert>
            );
          })}

          {/* Alertas de Advertencia */}
          {warningAlerts.map((alert, index) => {
            const IconComponent = iconMap[alert.icon] || AlertTriangle;
            return (
              <Alert key={`warning-${index}`} variant={getAlertVariant(alert.level)} className="border-yellow-300 bg-yellow-50">
                <IconComponent className="h-4 w-4 text-yellow-600" />
                <AlertTitle className="font-semibold text-yellow-800">{alert.title}</AlertTitle>
                <AlertDescription className="mt-2 space-y-2">
                  <p className="text-yellow-700">{alert.message}</p>
                  <p className="text-sm font-medium bg-yellow-100 p-2 rounded text-yellow-800">
                    <strong>Recomendación:</strong> {alert.action}
                  </p>
                </AlertDescription>
              </Alert>
            );
          })}

          {/* Métricas del Sistema */}
          <div className="mt-4 p-4 bg-gray-50 rounded-lg">
            <h4 className="font-semibold text-sm mb-3 text-gray-700">Métricas del Sistema</h4>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3 text-sm">
              <div>
                <p className="text-gray-600">Espacio en disco</p>
                <p className="font-semibold">
                  {healthData.metrics.diskSpacePercent.toFixed(1)}% libre
                  <span className="text-xs text-gray-500 ml-1">
                    ({healthData.metrics.diskSpaceFreeGB} GB)
                  </span>
                </p>
              </div>
              <div>
                <p className="text-gray-600">Último backup</p>
                <p className="font-semibold">
                  Hace {healthData.metrics.lastBackupDaysAgo} día{healthData.metrics.lastBackupDaysAgo !== 1 ? 's' : ''}
                </p>
              </div>
              <div>
                <p className="text-gray-600">Base de datos</p>
                <p className="font-semibold">{healthData.metrics.databaseSizeMB} MB</p>
              </div>
              <div>
                <p className="text-gray-600">Último mantenimiento</p>
                <p className="font-semibold">
                  Hace {healthData.metrics.lastMaintenanceDaysAgo} día{healthData.metrics.lastMaintenanceDaysAgo !== 1 ? 's' : ''}
                </p>
              </div>
              <div>
                <p className="text-gray-600">Pendrive recuperación</p>
                <p className="font-semibold">
                  {healthData.metrics.pendriveDaysOutdated > 0
                    ? `Hace ${healthData.metrics.pendriveDaysOutdated} días`
                    : 'Actualizado'}
                </p>
              </div>
            </div>
          </div>

          {/* Información de contacto */}
          {(criticalAlerts.length > 0 || warningAlerts.length > 0) && (
            <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
              <p className="text-sm text-blue-800">
                <strong>¿Necesita ayuda?</strong> Contacte a Personal de Sistemas de FCEA para resolver estos problemas.
              </p>
            </div>
          )}
        </CardContent>
      )}
    </Card>
  );
}
