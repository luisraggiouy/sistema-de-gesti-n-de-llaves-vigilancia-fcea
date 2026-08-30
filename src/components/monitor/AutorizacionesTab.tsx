import { useState, useMemo, useCallback, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { ClearableInput, ClearableTextarea } from '@/components/ui/clearable-input';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Textarea } from '@/components/ui/textarea';
import { Search, Plus, Pencil, Trash2, X, Check, ShieldCheck, ShieldX, Mail, Clock, CalendarDays, UserCheck, AlertTriangle, Users } from 'lucide-react';
import {
  Autorizacion, getAutorizaciones, guardarAutorizacion,
  actualizarAutorizacion, eliminarAutorizacion, buscarAutorizacionEnVivo,
  purgarAutorizacionesVencidas, getPersonasAutorizadas
} from '@/data/fceaData';
import { useToast } from '@/hooks/use-toast';
import { DateInput } from '@/components/ui/date-input';
import { ConfirmarAccionSensible } from '@/components/ConfirmarAccionSensible';

// Fila de persona en el formulario (upgrade multi-persona 2026-08-06).
interface PersonaForm {
  nombre: string;
  ci: string;
}

export function AutorizacionesTab() {
  const { toast } = useToast();
  const [refreshKey, setRefreshKey] = useState(0);
  const [modo, setModo] = useState<'buscar' | 'nueva'>('buscar');

  // v2.8 (2026-07-23): estados para el modal `ConfirmarAccionSensible`.
  //   - `confirmDelete`: autorizacion que se va a borrar (pendiente).
  //   - `confirmGuardarEdit`: bandera para confirmar edicion; los datos
  //     ya viven en `form` + `editingId`.
  const [confirmDelete, setConfirmDelete] = useState<Autorizacion | null>(null);
  const [confirmGuardarEdit, setConfirmGuardarEdit] = useState(false);

  // Búsqueda
  const [busqPersona, setBusqPersona] = useState('');
  const [busqLugar, setBusqLugar] = useState('');

  // Form nueva/editar
  // Upgrade 2026-08-06: `personas` es una lista (una o varias personas
  // pueden quedar autorizadas en la misma autorizacion).
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState({
    personas: [{ nombre: '', ci: '' }] as PersonaForm[],
    lugarAutorizado: '', autorizadoPor: '',
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
    setForm({ personas: [{ nombre: '', ci: '' }], lugarAutorizado: '', autorizadoPor: '', fechaAutorizacion: '', fechaDesde: '', fechaHasta: '', horario: '', emailReferencia: '', observaciones: '' });
    setEditingId(null);
  };

  // ---- Helpers de la lista de personas ----
  const updatePersona = (idx: number, campo: keyof PersonaForm, valor: string) => {
    setForm(f => ({
      ...f,
      personas: f.personas.map((p, i) => i === idx ? { ...p, [campo]: valor } : p),
    }));
  };

  const agregarPersona = () => {
    setForm(f => ({ ...f, personas: [...f.personas, { nombre: '', ci: '' }] }));
  };

  const quitarPersona = (idx: number) => {
    setForm(f => ({
      ...f,
      // Siempre queda al menos una fila.
      personas: f.personas.length > 1 ? f.personas.filter((_, i) => i !== idx) : f.personas,
    }));
  };

  const startEdit = (a: Autorizacion) => {
    setEditingId(a.id);
    const personas = getPersonasAutorizadas(a).map(p => ({ nombre: p.nombre, ci: p.ci || '' }));
    setForm({
      personas: personas.length > 0 ? personas : [{ nombre: '', ci: '' }],
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

  // v2.8 (2026-07-23): armado del payload separado del guardado real
  // para poder pasar por el modal `ConfirmarAccionSensible` cuando se
  // trata de una EDICION (`editingId` presente). Crear nueva no exige
  // confirmacion (no es destructivo: siempre se puede borrar despues).
  const buildAutorizacionData = () => {
    // Limpiar y descartar filas vacias. Upgrade multi-persona 2026-08-06.
    const personasLimpias = form.personas
      .map(p => ({ nombre: p.nombre.trim(), ci: p.ci.trim() || undefined }))
      .filter(p => p.nombre.length > 0);
    return {
      // Campos legacy = primera persona (compat busqueda/historial/export).
      personaNombre: personasLimpias[0]?.nombre || '',
      personaCI: personasLimpias[0]?.ci,
      personas: personasLimpias,
      lugarAutorizado: form.lugarAutorizado.trim(),
      autorizadoPor: form.autorizadoPor.trim(),
      fechaAutorizacion: form.fechaAutorizacion || new Date().toISOString().split('T')[0],
      fechaDesde: form.fechaDesde || undefined,
      fechaHasta: form.fechaHasta || undefined,
      horario: form.horario.trim() || undefined,
      emailReferencia: form.emailReferencia.trim() || undefined,
      observaciones: form.observaciones.trim() || undefined,
    };
  };

  const hayAlgunaPersona = form.personas.some(p => p.nombre.trim().length > 0);

  const handleGuardar = () => {
    if (!hayAlgunaPersona || !form.lugarAutorizado.trim() || !form.autorizadoPor.trim()) {
      toast({ title: 'Campos requeridos', description: 'Al menos una persona (nombre), lugar y autorizado por son obligatorios', variant: 'destructive' });
      return;
    }

    // Si estoy editando -> pasar por modal intimidatorio.
    // Si es autorizacion nueva -> guardar directo (no es destructivo).
    if (editingId) {
      setConfirmGuardarEdit(true);
      return;
    }

    const data = buildAutorizacionData();
    guardarAutorizacion(data);
    const extra = data.personas.length > 1 ? ` (+${data.personas.length - 1} más)` : '';
    toast({ title: 'Autorización registrada', description: `${data.personaNombre}${extra} — ${data.lugarAutorizado}` });
    resetForm();
    setModo('buscar');
    refresh();
  };

  const confirmarGuardarEdit = () => {
    if (!editingId) return;
    const data = buildAutorizacionData();
    actualizarAutorizacion(editingId, data);
    const extra = data.personas.length > 1 ? ` (+${data.personas.length - 1} más)` : '';
    toast({ title: 'Autorización actualizada', description: `${data.personaNombre}${extra} — ${data.lugarAutorizado}` });
    resetForm();
    setModo('buscar');
    refresh();
  };

  // v2.8 (2026-07-23): borrar ahora pasa por `ConfirmarAccionSensible`
  // en vez del `window.confirm()` viejo.
  const handleEliminar = (a: Autorizacion) => {
    setConfirmDelete(a);
  };

  const confirmarEliminar = () => {
    const a = confirmDelete;
    if (!a) return;
    eliminarAutorizacion(a.id);
    toast({ title: 'Autorización eliminada', variant: 'destructive' });
    refresh();
  };

  const hayBusqueda = busqPersona.trim().length > 0 || busqLugar.trim().length > 0;

  return (
    <div className="flex flex-col flex-1 min-h-0 space-y-3">
      {/* Toggle modo */}
      <div className="flex gap-2 flex-shrink-0">
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
              <ClearableInput
                placeholder="Ej: María López o 12345678"
                value={busqPersona}
                onChange={e => setBusqPersona(e.target.value)}
                onClear={() => setBusqPersona('')}
                className="h-9"
              />
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Llave / Lugar</Label>
              <ClearableInput
                placeholder="Ej: Sala 21-C"
                value={busqLugar}
                onChange={e => setBusqLugar(e.target.value)}
                onClear={() => setBusqLugar('')}
                className="h-9"
              />
            </div>
          </div>

          {hayBusqueda && (
            <p className="text-xs text-muted-foreground">
              Mostrando resultados en tiempo real...
            </p>
          )}

          <ScrollArea className="flex-1 min-h-0 -mx-1 px-1">
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
              <div className="space-y-2">
                <div className="flex items-center gap-2 py-1">
                  <ShieldCheck className="w-4 h-4 text-muted-foreground" />
                  <span className="text-xs text-muted-foreground">
                    {todasLasAutorizaciones.length} autorización{todasLasAutorizaciones.length > 1 ? 'es' : ''} vigente{todasLasAutorizaciones.length > 1 ? 's' : ''} — más reciente primero
                  </span>
                </div>
                {[...todasLasAutorizaciones]
                  .sort((a, b) => b.fechaCreacion.localeCompare(a.fechaCreacion))
                  .map(a => (
                    <AutorizacionCard key={a.id} auth={a} onEdit={startEdit} onDelete={handleEliminar} />
                  ))}
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
        <ScrollArea className="flex-1 min-h-0 -mx-1 px-1">
          <div className="space-y-3 pr-2">
            {/* Lista de personas autorizadas (una o varias) */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label className="text-xs flex items-center gap-1.5">
                  <Users className="w-3.5 h-3.5" />
                  Personas autorizadas *
                </Label>
                {form.personas.length > 1 && (
                  <span className="text-[10px] text-muted-foreground">{form.personas.length} personas</span>
                )}
              </div>

              {form.personas.map((persona, idx) => (
                <div key={idx} className="flex gap-2 items-start">
                  <div className="flex-1 grid grid-cols-2 gap-2">
                    <Input
                      value={persona.nombre}
                      onChange={e => updatePersona(idx, 'nombre', e.target.value)}
                      placeholder={idx === 0 ? 'Nombre (ej: María López)' : 'Otra persona...'}
                      className="h-9"
                    />
                    <Input
                      value={persona.ci}
                      onChange={e => updatePersona(idx, 'ci', e.target.value)}
                      placeholder="CI (opcional)"
                      className="h-9"
                    />
                  </div>
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="h-9 w-9 shrink-0 text-destructive hover:text-destructive disabled:opacity-30"
                    onClick={() => quitarPersona(idx)}
                    disabled={form.personas.length === 1}
                    title="Quitar persona"
                  >
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </div>
              ))}

              <div className="flex items-center justify-between">
                <Button type="button" variant="outline" size="sm" onClick={agregarPersona} className="h-8 gap-1.5">
                  <Plus className="w-3.5 h-3.5" />Agregar otra persona
                </Button>
                <p className="text-[10px] text-muted-foreground">CI: sin puntos ni guiones</p>
              </div>
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Llave / Lugar autorizado *</Label>
              <ClearableInput value={form.lugarAutorizado} onChange={e => setForm(f => ({ ...f, lugarAutorizado: e.target.value }))} onClear={() => setForm(f => ({ ...f, lugarAutorizado: '' }))} placeholder="Ej: Sala 21-C, Oficina Concursos" className="h-9" />
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Autorizado por *</Label>
              <ClearableInput value={form.autorizadoPor} onChange={e => setForm(f => ({ ...f, autorizadoPor: e.target.value }))} onClear={() => setForm(f => ({ ...f, autorizadoPor: '' }))} placeholder="Ej: Director del IESTA Juan González" className="h-9" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className="space-y-1">
                <Label className="text-xs">Fecha de autorización</Label>
                <DateInput value={form.fechaAutorizacion} onChange={v => setForm(f => ({ ...f, fechaAutorizacion: v }))} className="h-9" />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">Email de referencia</Label>
                <ClearableInput value={form.emailReferencia} onChange={e => setForm(f => ({ ...f, emailReferencia: e.target.value }))} onClear={() => setForm(f => ({ ...f, emailReferencia: '' }))} placeholder="correo@fcea.edu.uy" className="h-9" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className="space-y-1">
                <Label className="text-xs">Vigencia desde (opcional)</Label>
                <DateInput value={form.fechaDesde} onChange={v => setForm(f => ({ ...f, fechaDesde: v }))} className="h-9" />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">Vigencia hasta (opcional)</Label>
                <DateInput value={form.fechaHasta} onChange={v => setForm(f => ({ ...f, fechaHasta: v }))} className="h-9" />
              </div>
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Horario autorizado</Label>
              <ClearableInput value={form.horario} onChange={e => setForm(f => ({ ...f, horario: e.target.value }))} onClear={() => setForm(f => ({ ...f, horario: '' }))} placeholder="Ej: Lunes a Viernes de 9 a 18" className="h-9" />
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Observaciones</Label>
              <ClearableTextarea value={form.observaciones} onChange={e => setForm(f => ({ ...f, observaciones: e.target.value }))} onClear={() => setForm(f => ({ ...f, observaciones: '' }))} placeholder="Notas adicionales..." rows={2} className="text-sm" />
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

      {/* v2.8 (2026-07-23): modales `ConfirmarAccionSensible` para
          proteger BORRAR autorizacion y EDITAR autorizacion (crear
          nueva no requiere confirmacion). */}
      <ConfirmarAccionSensible
        open={!!confirmDelete}
        onOpenChange={(v) => { if (!v) setConfirmDelete(null); }}
        tipoAccion="borrar"
        entidad="autorizacion"
        detalle={confirmDelete ? `${confirmDelete.personaNombre} — ${confirmDelete.lugarAutorizado}` : undefined}
        descripcionExtra={
          "Vas a eliminar esta autorizacion. La persona ya no aparecera al verificar autorizaciones para ese lugar. Esta accion NO se puede deshacer."
        }
        onConfirmar={() => {
          confirmarEliminar();
          setConfirmDelete(null);
        }}
      />

      <ConfirmarAccionSensible
        open={confirmGuardarEdit}
        onOpenChange={(v) => { if (!v) setConfirmGuardarEdit(false); }}
        tipoAccion="editar"
        entidad="autorizacion"
        detalle={hayAlgunaPersona ? `${form.personas.find(p => p.nombre.trim())?.nombre || ''} — ${form.lugarAutorizado}` : undefined}
        descripcionExtra={
          "Vas a modificar los datos de una autorizacion existente. Los cambios reemplazan a los datos anteriores en el momento; verifica bien nombre, CI, lugar, vigencia y autorizante antes de guardar."
        }
        onConfirmar={() => {
          confirmarGuardarEdit();
          setConfirmGuardarEdit(false);
        }}
      />
    </div>
  );
}

/**
 * Formatea una fecha (YYYY-MM-DD o ISO completo) a DD/MM/AAAA local.
 * Fix 2026-08-30: `new Date('2026-08-30')` se interpreta como UTC medianoche;
 * al formatear en zona horaria de Uruguay (UTC-3) mostraba UN DÍA ANTES.
 * Anclamos a las 12:00 para las fechas YYYY-MM-DD y así evitar el corrimiento.
 */
function fmtFecha(fecha: string): string {
  if (!fecha) return '';
  const d = fecha.includes('T') ? new Date(fecha) : new Date(fecha + 'T12:00:00');
  return isNaN(d.getTime()) ? fecha : d.toLocaleDateString('es-UY');
}

function AutorizacionCard({ auth, onEdit, onDelete }: { auth: Autorizacion; onEdit: (a: Autorizacion) => void; onDelete: (a: Autorizacion) => void }) {
  const hoy = new Date().toISOString().split('T')[0];
  const proximaAVencer = auth.fechaHasta && auth.fechaHasta >= hoy && auth.fechaHasta <= new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0];
  // Upgrade 2026-08-06: mostrar TODAS las personas autorizadas.
  const personas = getPersonasAutorizadas(auth);

  return (
    <div className="p-3 rounded-lg border bg-card hover:bg-accent/50 transition-colors space-y-1.5">
      <div className="flex items-start justify-between gap-2">
        <div className="flex-1 min-w-0">
          {personas.length > 1 && (
            <Badge variant="outline" className="mb-1 gap-1 bg-primary/10 text-primary border-primary/30">
              <Users className="w-3 h-3" />{personas.length} personas autorizadas
            </Badge>
          )}
          <div className="space-y-1">
            {personas.map((p, i) => (
              <div key={i} className="flex items-center gap-2 flex-wrap">
                <p className="font-medium truncate">{p.nombre}</p>
                {p.ci && (
                  <Badge variant="outline" className="bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/30">
                    CI: {p.ci}
                  </Badge>
                )}
              </div>
            ))}
          </div>
          <p className="text-sm text-muted-foreground mt-1">
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
            <CalendarDays className="w-3 h-3" />{fmtFecha(auth.fechaAutorizacion)}
          </span>
        )}
        {(auth.fechaDesde || auth.fechaHasta) && (
          <span className="flex items-center gap-1">
            <CalendarDays className="w-3 h-3" />
            Vigencia: {auth.fechaDesde ? fmtFecha(auth.fechaDesde) : '...'} — {auth.fechaHasta ? fmtFecha(auth.fechaHasta) : '...'}
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
