import { useEffect, useState } from 'react';
import { CheckCircle, AlertTriangle, AlertCircle, Database, HardDrive, FileText, Usb, XCircle } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';

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
  documentation?: string;
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

export function SystemHealthIndicator() {
  const [healthData, setHealthData] = useState<SystemHealth | null>(null);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState(false);

  const fetchHealthData = async () => {
    try {
      const response = await fetch(`/system_health.json?t=${Date.now()}`);
      if (!response.ok) {
        setFetchError(`HTTP ${response.status}`);
        return;
      }
      // serve_dist.cjs (SPA fallback) devuelve index.html cuando no encuentra
      // un archivo. Verificamos Content-Type para evitar parsear HTML como JSON.
      const contentType = response.headers.get('content-type') || '';
      if (!contentType.includes('json')) {
        setFetchError('system_health.json no existe (servidor devolvio HTML)');
        return;
      }
      const data = await response.json();
      setHealthData(data);
      setFetchError(null);
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      console.error('Error al cargar estado de salud:', error);
      setFetchError(msg);
    }
  };

  useEffect(() => {
    fetchHealthData();
    // Refrescar cada 60s: el chequeo programado escribe el JSON cada 5 min,
    // pero el primer fetch en una instalacion nueva puede tardar varios segundos
    // hasta que la tarea FCEA-Chequeo-Salud genere el archivo por primera vez.
    const interval = setInterval(fetchHealthData, 60 * 1000);
    return () => clearInterval(interval);
  }, []);

  // Fallback visible: si todavia no se cargo el JSON (instalacion nueva o
  // chequeo de salud aun no ejecutado), mostrar un indicador "Sin datos"
  // en vez de devolver null y dejar al usuario sin saber si el sistema
  // de salud existe.
  if (!healthData) {
    return (
      <div
        className="flex items-center gap-1.5 text-xs text-muted-foreground"
        title={fetchError ? `system_health.json no disponible: ${fetchError}` : 'Esperando primer chequeo de salud...'}
      >
        <AlertTriangle className="w-3 h-3 text-yellow-500" />
        <span>Sistema: {fetchError ? 'Sin datos' : 'Cargando...'}</span>
      </div>
    );
  }

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
        return 'Crítico';
      case 'warning':
        return 'Advertencia';
      default:
        return 'OK';
    }
  };

  const criticalAlerts = healthData.alerts.filter(a => a.level === 'critical');
  const warningAlerts = healthData.alerts.filter(a => a.level === 'warning');

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-1.5 text-xs cursor-pointer hover:opacity-80 transition-opacity"
        title="Ver detalles del sistema"
      >
        {getStatusIcon()}
        <span className="text-muted-foreground">Sistema: {getStatusText()}</span>
        {healthData.alerts.length > 0 && (
          <Badge variant="destructive" className="ml-1 h-4 px-1 text-[10px]">
            {healthData.alerts.length}
          </Badge>
        )}
      </button>

      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              {getStatusIcon()}
              Estado del Sistema: {getStatusText()}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            {/* Alertas Críticas */}
            {criticalAlerts.map((alert, index) => {
              const IconComponent = iconMap[alert.icon] || AlertCircle;
              return (
                <Alert key={`critical-${index}`} variant="destructive">
                  <IconComponent className="h-4 w-4" />
                  <AlertTitle className="font-semibold">{alert.title}</AlertTitle>
                  <AlertDescription className="mt-2 space-y-2">
                    <p>{alert.message}</p>
                    <p className="text-sm font-medium bg-red-100 dark:bg-red-900/20 p-2 rounded">
                      <strong>Acción requerida:</strong> {alert.action}
                    </p>
                    {alert.documentation && (
                      <p className="text-xs bg-blue-50 border border-blue-200 p-2 rounded text-blue-800">
                        📖 <strong>Consultar:</strong> <code className="bg-blue-100 px-1 py-0.5 rounded">{alert.documentation}</code>
                      </p>
                    )}
                  </AlertDescription>
                </Alert>
              );
            })}

            {/* Alertas de Advertencia */}
            {warningAlerts.map((alert, index) => {
              const IconComponent = iconMap[alert.icon] || AlertTriangle;
              return (
                <Alert key={`warning-${index}`} className="border-yellow-300 bg-yellow-50">
                  <IconComponent className="h-4 w-4 text-yellow-600" />
                  <AlertTitle className="font-semibold text-yellow-800">{alert.title}</AlertTitle>
                  <AlertDescription className="mt-2 space-y-2">
                    <p className="text-yellow-700">{alert.message}</p>
                    <p className="text-sm font-medium bg-yellow-100 p-2 rounded text-yellow-800">
                      <strong>Recomendación:</strong> {alert.action}
                    </p>
                    {alert.documentation && (
                      <p className="text-xs bg-blue-50 border border-blue-200 p-2 rounded text-blue-800">
                        📖 <strong>Consultar:</strong> <code className="bg-blue-100 px-1 py-0.5 rounded">{alert.documentation}</code>
                      </p>
                    )}
                  </AlertDescription>
                </Alert>
              );
            })}

            {/* Mensaje cuando no hay alertas */}
            {healthData.alerts.length === 0 && (
              <Alert className="border-green-300 bg-green-50">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <AlertTitle className="font-semibold text-green-800">Sistema Saludable</AlertTitle>
                <AlertDescription className="text-green-700">
                  Todos los sistemas funcionando correctamente. No se requiere ninguna acción.
                </AlertDescription>
              </Alert>
            )}

            {/* Métricas del Sistema */}
            <div className="mt-4 p-4 bg-gray-50 rounded-lg border">
              <h4 className="font-semibold text-sm mb-3 text-gray-700">Métricas del Sistema</h4>
              <div className="grid grid-cols-2 gap-3 text-sm">
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
              </div>
            </div>

            {/* Bloque "Necesita ayuda?" eliminado a pedido del usuario (FCEA v4.4).
                El sistema es autoservicio: las acciones necesarias ya se detallan
                dentro de cada alerta ("Accion requerida" / "Recomendacion" +
                enlace a la guia de mantenimiento). No hay Personal de Sistemas
                dedicado al que contactar. */}
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
