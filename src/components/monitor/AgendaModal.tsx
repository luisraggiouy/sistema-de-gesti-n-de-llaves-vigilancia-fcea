import { useState, useMemo } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Search, Phone, Mail, User } from 'lucide-react';
import { getUsuariosRegistrados, normalizarTexto, UsuarioRegistrado } from '@/data/fceaData';

interface AgendaModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AgendaModal({ open, onOpenChange }: AgendaModalProps) {
  const [busqueda, setBusqueda] = useState('');
  const usuarios = useMemo(() => getUsuariosRegistrados(), [open]);

  const resultados = useMemo(() => {
    if (!busqueda.trim()) return usuarios;
    const term = normalizarTexto(busqueda);
    return usuarios.filter(u =>
      normalizarTexto(u.nombre).includes(term) ||
      (u.celular && u.celular.includes(busqueda)) ||
      (u.email && normalizarTexto(u.email).includes(term)) ||
      normalizarTexto(u.tipo).includes(term) ||
      (u.departamento && normalizarTexto(u.departamento).includes(term))
    );
  }, [busqueda, usuarios]);

  const getBadgeColor = (tipo: string) => {
    switch (tipo) {
      case 'Docente': return 'bg-primary/20 text-primary border-primary/30';
      case 'Personal TAS': return 'bg-warning/20 text-warning border-warning/30';
      case 'Alumno': return 'bg-info/20 text-info border-info/30';
      case 'Empresa': return 'bg-muted text-muted-foreground border-border';
      default: return '';
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <User className="w-5 h-5" />
            Agenda de Contactos
          </DialogTitle>
        </DialogHeader>

        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Buscar por nombre, teléfono, email o función..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="pl-10"
            autoFocus
          />
        </div>

        <ScrollArea className="h-[400px] -mx-2 px-2">
          {resultados.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              {usuarios.length === 0
                ? 'No hay usuarios registrados aún'
                : 'Sin resultados para esta búsqueda'}
            </div>
          ) : (
            <div className="space-y-2">
              {resultados.map((u: UsuarioRegistrado) => (
                <div key={u.id} className="p-3 rounded-lg border bg-card hover:bg-accent/50 transition-colors">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <p className="font-medium truncate">{u.nombre}</p>
                      <div className="flex items-center gap-3 mt-1 text-sm text-muted-foreground">
                        {u.celular && (
                          <a href={`tel:${u.celular}`} className="flex items-center gap-1 hover:text-primary">
                            <Phone className="w-3 h-3" />
                            {u.celular}
                          </a>
                        )}
                        {u.email && (
                          <a href={`mailto:${u.email}`} className="flex items-center gap-1 hover:text-primary truncate">
                            <Mail className="w-3 h-3" />
                            {u.email}
                          </a>
                        )}
                      </div>
                    </div>
                    <div className="flex flex-col items-end gap-1">
                      <Badge variant="outline" className={getBadgeColor(u.tipo)}>
                        {u.tipo}
                      </Badge>
                      {u.departamento && (
                        <span className="text-xs text-muted-foreground">{u.departamento}</span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </ScrollArea>

        <p className="text-xs text-muted-foreground text-center">
          {resultados.length} de {usuarios.length} contacto{usuarios.length !== 1 ? 's' : ''}
        </p>
      </DialogContent>
    </Dialog>
  );
}
