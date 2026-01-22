import { Key } from 'lucide-react';

export function TerminalHeader() {
  const ahora = new Date();
  const fecha = ahora.toLocaleDateString('es-UY', { 
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });
  const hora = ahora.toLocaleTimeString('es-UY', { 
    hour: '2-digit', 
    minute: '2-digit' 
  });

  return (
    <header className="bg-primary text-primary-foreground py-6 px-8 shadow-lg">
      <div className="max-w-4xl mx-auto flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="bg-primary-foreground/10 p-3 rounded-xl">
            <Key className="w-8 h-8" />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">
              Sistema de Gestión de Llaves
            </h1>
            <p className="text-primary-foreground/80 text-sm">
              FCEA - Universidad de la República
            </p>
          </div>
        </div>
        <div className="text-right">
          <p className="text-lg font-semibold">{hora}</p>
          <p className="text-primary-foreground/80 text-sm capitalize">{fecha}</p>
        </div>
      </div>
    </header>
  );
}
