import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Lugar } from '@/data/fceaData';
import { CheckCircle2, Key, Building2, ArrowRightLeft, User } from 'lucide-react';

interface ExchangeSuccessProps {
  lugar: Lugar;
  usuarioSaliente: string;
  usuarioEntrante: string;
  onFinish: () => void;
}

/**
 * Pantalla de confirmacion de intercambio de llave.
 *
 * Fix 2026-08-25: Antes, al confirmar un intercambio, la Terminal se quedaba
 * en el paso 'main' con el usuario logueado y la lista de llaves desplegada
 * (solo se limpiaba con F5). Otro profesor podia llegar y usar por error la
 * sesion del anterior. Ahora el intercambio pasa por esta pantalla de exito
 * con cuenta regresiva que, al terminar (o al tocar el boton), ejecuta
 * onFinish() para cerrar la sesion del usuario, limpiar las llaves y volver
 * al inicio con la Terminal "limpia" para el proximo usuario.
 */
export function ExchangeSuccess({ lugar, usuarioSaliente, usuarioEntrante, onFinish }: ExchangeSuccessProps) {
  const [contador, setContador] = useState(6);

  useEffect(() => {
    if (contador <= 0) {
      onFinish();
      return;
    }
    const timer = setTimeout(() => setContador(c => c - 1), 1000);
    return () => clearTimeout(timer);
  }, [contador, onFinish]);

  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
      <Card className="p-8 max-w-md w-full bg-gradient-to-br from-success/10 to-card border-success/20">
        <div className="mb-6">
          <div className="mx-auto w-20 h-20 bg-success/20 rounded-full flex items-center justify-center mb-4">
            <CheckCircle2 className="w-12 h-12 text-success" />
          </div>
          <h2 className="text-2xl font-bold text-foreground mb-2">
            ¡Intercambio Confirmado!
          </h2>
          <p className="text-lg font-medium text-success mt-1">
            La llave pasa a estar a su nombre
          </p>
        </div>

        <div className="bg-card rounded-xl p-4 border mb-6 space-y-3">
          <div className="flex items-center gap-2 text-left">
            <Key className="w-4 h-4 text-primary flex-shrink-0" />
            <span className="font-medium truncate">{lugar.nombre}</span>
            <Badge variant="outline" className="text-xs">{lugar.tipo}</Badge>
            <span className="flex items-center gap-1 text-xs text-muted-foreground">
              <Building2 className="w-3 h-3" />
              {lugar.edificio}
            </span>
          </div>
          <div className="flex items-center justify-center gap-3 text-sm text-muted-foreground pt-1">
            <span className="flex items-center gap-1">
              <User className="w-3.5 h-3.5" />
              {usuarioSaliente}
            </span>
            <ArrowRightLeft className="w-4 h-4 text-primary" />
            <span className="flex items-center gap-1 font-medium text-foreground">
              <User className="w-3.5 h-3.5" />
              {usuarioEntrante}
            </span>
          </div>
        </div>

        {/* Recordatorio para el usuario */}
        <div className="mb-6 p-3 bg-primary/5 border border-primary/20 rounded-lg text-sm text-muted-foreground">
          Recuerde solicitar la llave directamente al usuario saliente. En unos segundos
          la Terminal volverá al inicio para el próximo usuario.
        </div>

        {/* Contador */}
        <div className="mb-4">
          <div className="w-12 h-12 mx-auto rounded-full border-4 border-success flex items-center justify-center">
            <span className="text-xl font-bold text-success">{contador}</span>
          </div>
          <p className="text-xs text-muted-foreground mt-1">Vuelve al inicio en {contador}s</p>
        </div>

        <Button
          onClick={onFinish}
          variant="outline"
          className="w-full h-12"
        >
          Volver al inicio ahora
        </Button>
      </Card>
    </div>
  );
}
