import { useState, useMemo, useCallback, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Textarea } from '@/components/ui/textarea';
import { Search, Plus, Pencil, Trash2, X, Check, ShieldCheck, ShieldX, Mail, Clock, CalendarDays, UserCheck, AlertTriangle } from 'lucide-react';
import {
  Autorizacion, getAutorizaciones, guardarAutorizacion,
  actualizarAutorizacion, eliminarAutorizacion, buscarAutorizacionEnVivo,
  purgarAutorizacionesVencidas, normalizarTexto
} from '@/data/fceaData';
import { useToast } from '@/hooks/use-toast';

export function AutorizacionesTab() {
  const { toast } = useToast();
  const [refreshKey, setRefreshKey] = useState(0);
  const [modo, setModo] = useState<'buscar' | 'nueva'>('buscar');

  // Búsqueda
  const [busqPersona, setBusqPersona] = useState('');
  const [busqLugar, setBusqLugar] = useState('');

  // Form nueva/editar
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState({
    personaNombre: '', personaCI: '', lugarAutorizado: '', autorizadoPor: '',
    fechaAutorizacion: '', fechaDesde: '', fechaHasta: '',
    horario: '', emailReferencia: '', observaciones: ''
  });

  const refresh = useCallback(() => setRefreshKey(k => k + 1), []);

  // Auto-purge expired authorizations on mount and refresh
  useEffect(() => {
    const eliminadas = purgarAutorizacionesVencidas();
    if (eliminadas > 0) {
      toast({ title: `${eliminadas} autorización${eliminadas > 1 ? 'es' : ''} vencida${eliminadas > 1 ? 's' : ''} eliminada${eliminadas > 1 ? 's' : ''}` });
      refresh();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Live search results - updates as user types
  const resultados = useMemo(() => {
    if (!busqPersona.trim() && !busqLugar.trim()) return [];
    return buscarAutorizacionEnVivo(busqPersona, busqLugar);
  }, [busqPersona, busqLugar, refreshKey]);

  const todasLasAutorizaciones = useMemo(() => getAutorizaciones(), [refreshKey]);

  const resetForm = () => {
    setForm({ personaNombre: '', personaCI: '', lugarAutorizado: '', autorizadoPor: '', fechaAutorizacion: '', fechaDesde: '', fechaHasta: '', horario: '', emailReferencia: '', observaciones: '' });
    setEditingId(null);
  };

  const startEdit = (a: Autorizacion) => {
    setEditingId(a.id);
    setForm({
      personaNombre: a.personaNombre,
      personaCI: a.personaCI || '',
      lugarAutorizado: a.lugarAutorizado,
      autorizadoPor: a.autorizadoPor,
      fechaAutorizacion: a.fechaAutorizacion?.split('T')[0] || '',
      fechaDesde: a.fechaDesde?.split('T')[0] || '',
      fechaHasta: a.fechaHasta?.split('T')[0] || '',
      horario: a.horario || '',
      emailReferencia: a.emailReferencia || '',
      observaciones: a.observaciones || '',
    });
    setModo('nueva');
  };

  const handleGuardar = () => {
    if (!form.personaNombre.trim() || !form.lugarAutorizado.trim() || !form.autorizadoPor.trim()) {
      toast({ title: 'Campos requeridos', description: 'Nombre, lugar y autorizado por son obligatorios', variant: 'destructive' });
      return;
    }
    const data = {
      personaNombre: form.personaNombre.trim(),
      personaCI: form.personaCI.trim() || undefined,
      lugarAutorizado: form.lugarAutorizado.trim(),
      autorizadoPor: form.autorizadoPor.trim(),
      fechaAutorizacion: form.fechaAutorizacion || new Date().toISOString().split('T')[0],
      fechaDesde: form.fechaDesde || undefined,
      fechaHasta: form.fechaHasta || undefined,
      horario: form.horario.trim() || undefined,
      emailReferencia: form.emailReferencia.trim() || undefined,
      observaciones: form.observaciones.trim() || undefined,
    };

    if (editingId) {
      actualizarAutorizacion(editingId, data);
      toast({ title: 'Autorización actualizada', description: `${data.personaNombre} — ${data.lugarAutorizado}` });
    } else {
      guardarAutorizacion(data);
      toast({ title: 'Autorización registrada', description: `${data.personaNombre} — ${data.lugarAutorizado}` });
    }
    resetForm();
    setModo('buscar');
    refresh();
  };

  const handleEliminar = (a: Autorizacion) => {
    if (!confirm(`¿Eliminar autorización de ${a.personaNombre} para ${a.lugarAutorizado}?`)) return;
    eliminarAutorizacion(a.id);
    toast({ title: 'Autorización eliminada', variant: 'destructive' });
    refresh();
  };

  const hayBusqueda = busqPersona.trim().length > 0 || busqLugar.trim().length > 0;

  return (
    <div className="space-y-3">
      {/* Toggle modo */}
      <div className="flex gap-2">
        <Button
          variant={modo === 'buscar' ? 'default' : 'outline'}
          size="sm"
          onClick={() => { setModo('buscar'); resetForm(); }}
          className="gap-1.5"
        >
          <Search className="w-3.5 h-3.5" />Verificar
        </Button>
        <Button
          variant={modo === 'nueva' ? 'default' : 'outline'}
          size="sm"
          onClick={() => { setModo('nueva'); resetForm(); }}
          className="gap-1.5"
        >
          <Plus className="w-3.5 h-3.5" />{editingId ? 'Editando' : 'Nueva'}
        </Button>
      </div>

      {modo === 'buscar' ? (
        <>
          {/* Smart search fields */}
          <div className="grid grid-cols-2 gap-2">
            <div className="space-y-1">
              <Label className="text-xs">Nombre o CI de la persona</Label>
              <Input
                placeholder="Ej: María López o 12345678"
                value={busqPersona}
                onChange={e => setBusqPersona(e.target.value)}
                className="h-9"
              />
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Llave / Lugar</Label>
              <Input
                placeholder="Ej: Sala 21-C"
                value={busqLugar}
                onChange={e => setBusqLugar(e.target.value)}
                className="h-9"
              />
            </div>
          </div>

          {hayBusqueda && (
            <p className="text-xs text-muted-foreground">
              Mostrando resultados en tiempo real...
            </p>
          )}

          <ScrollArea className="h-[260px] -mx-1 px-1">
            {hayBusqueda && resultados.length === 0 ? (
              <div className="text-center py-6 space-y-2">
                <ShieldX className="w-10 h-10 mx-auto text-destructive/60" />
                <p className="font-medium text-destructive">No se encontró autorización</p>
                <p className="text-sm text-muted-foreground">
                  No hay registros que coincidan con "{busqPersona}" {busqLugar && `para "${busqLugar}"`}
                </p>
              </div>
            ) : hayBusqueda && resultados.length > 0 ? (
              <div className="space-y-2">
                <div className="flex items-center gap-2 py-1">
                  <ShieldCheck className="w-5 h-5 text-green-500" />
                  <span className="font-medium text-green-600 dark:text-green-400">
                    {resultados.length} autorización{resultados.length > 1 ? 'es' : ''} encontrada{resultados.length > 1 ? 's' : ''}
                  </span>
                </div>
                {resultados.map(a => (
                  <AutorizacionCard key={a.id} auth={a} onEdit={startEdit} onDelete={handleEliminar} />
                ))}
              </div>
            ) : !hayBusqueda && todasLasAutorizaciones.length > 0 ? (
              <div className="text-center py-8 text-muted-foreground space-y-2">
                <Search className="w-8 h-8 mx-auto opacity-40" />
                <p className="text-sm">Escriba un nombre o lugar para buscar autorizaciones</p>
                <p className="text-xs">{todasLasAutorizaciones.length} autorización{todasLasAutorizaciones.length > 1 ? 'es' : ''} registrada{todasLasAutorizaciones.length > 1 ? 's' : ''}</p>
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                No hay autorizaciones registradas aún
              </div>
            )}
          </ScrollArea>
        </>
      ) : (
        /* Formulario nueva/editar */
        <ScrollArea className="h-[320px] -mx-1 px-1">
          <div className="space-y-3 pr-2">
            <div className="grid grid-cols-2 gap-2">
              <div className="space-y-1">
                <Label className="text-xs">Nombre de la persona *</Label>
                <Input value={form.personaNombre} onChange={e => setForm(f => ({ ...f, personaNombre: e.target.value }))} placeholder="Ej: María López" className="h-9" />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">CI (opcional)</Label>
                <div className="relative">
                  <Input 
                    value={form.personaCI} 
                    onChange={e => setForm(f => ({ ...f, personaCI: e.target.value }))} 
                    placeholder="Ej: 12345678" 
                    className="h-9" 
                  />
                  <p className="text-[10px] text-muted-foreground absolute -bottom-4 left-0">Sin puntos ni guiones</p>
                </div>
              </div>
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Llave / Lugar autorizado *</Label>
              <Input value={form.lugarAutorizado} onChange={e => setForm(f => ({ ...f, lugarAutorizado: e.target.value }))} placeholder="Ej: Sala 21-C, Oficina Concursos" className="h-9" />
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Autorizado por *</Label>
              <Input value={form.autorizadoPor} onChange={e => setForm(f => ({ ...f, autorizadoPor: e.target.value }))} placeholder="Ej: Director del IESTA Juan González" className="h-9" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className="space-y-1">
                <Label className="text-xs">Fecha de autorización</Label>
                <Input type="date" value={form.fechaAutorizacion} onChange={e => setForm(f => ({ ...f, fechaAutorizacion: e.target.value }))} className="h-9" />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">Email de referencia</Label>
                <Input value={form.emailReferencia} onChange={e => setForm(f => ({ ...f, emailReferencia: e.target.value }))} placeholder="correo@fcea.edu.uy" className="h-9" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className="space-y-1">
                <Label className="text-xs">Vigencia desde (opcional)</Label>
                <Input type="date" value={form.fechaDesde} onChange={e => setForm(f => ({ ...f, fechaDesde: e.target.value }))} className="h-9" />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">Vigencia hasta (opcional)</Label>
                <Input type="date" value={form.fechaHasta} onChange={e => setForm(f => ({ ...f, fechaHasta: e.target.value }))} className="h-9" />
              </div>
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Horario autorizado</Label>
              <Input value={form.horario} onChange={e => setForm(f => ({ ...f, horario: e.target.value }))} placeholder="Ej: Lunes a Viernes de 9 a 18" className="h-9" />
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Observaciones</Label>
              <Textarea value={form.observaciones} onChange={e => setForm(f => ({ ...f, observaciones: e.target.value }))} placeholder="Notas adicionales..." rows={2} className="text-sm" />
            </div>
            <div className="flex gap-2 justify-end pt-1">
              <Button variant="ghost" size="sm" onClick={() => { resetForm(); setModo('buscar'); }} className="h-8 gap-1">
                <X className="w-3.5 h-3.5" />Cancelar
              </Button>
              <Button size="sm" onClick={handleGuardar} className="h-8 gap-1">
                <Check className="w-3.5 h-3.5" />{editingId ? 'Actualizar' : 'Registrar'}
              </Button>
            </div>
          </div>
        </ScrollArea>
      )}
    </div>
  );
}

function AutorizacionCard({ auth, onEdit, onDelete }: { auth: Autorizacion; onEdit: (a: Autorizacion) => void; onDelete: (a: Autorizacion) => void }) {
  const hoy = new Date().toISOString().split('T')[0];
  const proximaAVencer = auth.fechaHasta && auth.fechaHasta >= hoy && auth.fechaHasta <= new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0];

  return (
    <div className="p-3 rounded-lg border bg-card hover:bg-accent/50 transition-colors space-y-1.5">
      <div className="flex items-start justify-between gap-2">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <p className="font-medium truncate">{auth.personaNombre}</p>
            {auth.personaCI && (
              <Badge variant="outline" className="bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/30">
                CI: {auth.personaCI}
              </Badge>
            )}
          </div>
          <p className="text-sm text-muted-foreground">
            <Badge variant="outline" className="bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/30 mr-1.5">
              {auth.lugarAutorizado}
            </Badge>
            {proximaAVencer && (
              <Badge variant="outline" className="bg-warning/10 text-warning border-warning/30 gap-1">
                <AlertTriangle className="w-3 h-3" />Vence pronto
              </Badge>
            )}
          </p>
        </div>
        <div className="flex gap-1 shrink-0">
          <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => onEdit(auth)}>
            <Pencil className="w-3.5 h-3.5" />
          </Button>
          <Button variant="ghost" size="icon" className="h-7 w-7 text-destructive hover:text-destructive" onClick={() => onDelete(auth)}>
            <Trash2 className="w-3.5 h-3.5" />
          </Button>
        </div>
      </div>
      <div className="flex flex-wrap gap-x-3 gap-y-1 text-xs text-muted-foreground">
        <span className="flex items-center gap-1">
          <UserCheck className="w-3 h-3" />{auth.autorizadoPor}
        </span>
        {auth.fechaAutorizacion && (
          <span className="flex items-center gap-1">
            <CalendarDays className="w-3 h-3" />{new Date(auth.fechaAutorizacion).toLocaleDateString('es-UY')}
          </span>
        )}
        {(auth.fechaDesde || auth.fechaHasta) && (
          <span className="flex items-center gap-1">
            <CalendarDays className="w-3 h-3" />
            Vigencia: {auth.fechaDesde ? new Date(auth.fechaDesde).toLocaleDateString('es-UY') : '...'} — {auth.fechaHasta ? new Date(auth.fechaHasta).toLocaleDateString('es-UY') : '...'}
          </span>
        )}
        {auth.horario && (
          <span className="flex items-center gap-1">
            <Clock className="w-3 h-3" />{auth.horario}
          </span>
        )}
        {auth.emailReferencia && (
          <span className="flex items-center gap-1">
            <Mail className="w-3 h-3" />{auth.emailReferencia}
          </span>
        )}
      </div>
      {auth.observaciones && (
        <p className="text-xs text-muted-foreground italic">{auth.observaciones}</p>
      )}
    </div>
  );
}
