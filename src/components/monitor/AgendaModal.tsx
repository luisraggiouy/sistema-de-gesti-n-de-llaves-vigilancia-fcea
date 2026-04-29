import { useState, useMemo, useCallback, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Search, Phone, Mail, User, Pencil, Trash2, X, Check, Building, ShieldCheck, History, RefreshCw } from 'lucide-react';
import { 
  normalizarTexto, UsuarioRegistrado, 
  TipoUsuario, tiposUsuario, DepartamentoTAS, departamentosTAS 
} from '@/data/fceaData';
import { useToast } from '@/hooks/use-toast';
import pb from '@/lib/pocketbase';
import { AutorizacionesTab } from './AutorizacionesTab';
import { HistorialAutorizacionesTab } from './HistorialAutorizacionesTab';

const mapRecord = (r: any): UsuarioRegistrado => ({
  id: r.id,
  nombre: r.nombre,
  celular: r.celular ?? '',
  email: r.email || undefined,
  tipo: r.tipo as TipoUsuario,
  departamento: r.departamento || undefined,
  nombreEmpresa: r.nombre_empresa || undefined,
  fechaRegistro: r.created,
});

interface AgendaModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AgendaModal({ open, onOpenChange }: AgendaModalProps) {
  const { toast } = useToast();
  const [busqueda, setBusqueda] = useState('');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editData, setEditData] = useState<Partial<UsuarioRegistrado>>({});
  const [usuarios, setUsuarios] = useState<UsuarioRegistrado[]>([]);
  const [loading, setLoading] = useState(false);

  // Fetch fresh data from PocketBase every time the modal opens
  const fetchUsuarios = useCallback(async () => {
    setLoading(true);
    try {
      const records = await pb.collection('usuarios_registrados').getFullList({ sort: 'nombre' });
      setUsuarios(records.map(mapRecord));
    } catch (e) {
      console.error('Error cargando usuarios:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (open) {
      fetchUsuarios();
    }
  }, [open, fetchUsuarios]);

  const resultados = useMemo(() => {
    if (!busqueda.trim()) return usuarios;
    const term = normalizarTexto(busqueda);
    return usuarios.filter(u =>
      normalizarTexto(u.nombre).includes(term) ||
      (u.celular && u.celular.includes(busqueda)) ||
      (u.email && normalizarTexto(u.email).includes(term)) ||
      normalizarTexto(u.tipo).includes(term) ||
      (u.departamento && normalizarTexto(u.departamento).includes(term)) ||
      (u.nombreEmpresa && normalizarTexto(u.nombreEmpresa).includes(term))
    );
  }, [busqueda, usuarios]);

  const startEdit = (u: UsuarioRegistrado) => {
    setEditingId(u.id);
    setEditData({ nombre: u.nombre, celular: u.celular, email: u.email || '', tipo: u.tipo, departamento: u.departamento, nombreEmpresa: u.nombreEmpresa });
  };

  const cancelEdit = () => {
    setEditingId(null);
    setEditData({});
  };

  const saveEdit = async () => {
    if (!editingId || !editData.nombre?.trim()) return;
    try {
      await pb.collection('usuarios_registrados').update(editingId, {
        nombre: editData.nombre.trim(),
        celular: editData.celular?.trim() || '',
        email: editData.email?.trim() || '',
        tipo: editData.tipo,
        departamento: editData.tipo === 'Personal TAS' ? editData.departamento || '' : '',
        nombre_empresa: editData.tipo === 'Empresa' ? editData.nombreEmpresa?.trim() || '' : '',
      });
      toast({ title: "Usuario actualizado", description: `${editData.nombre} fue modificado correctamente` });
      cancelEdit();
      await fetchUsuarios();
    } catch (e) {
      console.error('Error actualizando usuario:', e);
      toast({ title: "Error", description: "No se pudo actualizar el usuario", variant: "destructive" });
    }
  };

  const handleDelete = async (u: UsuarioRegistrado) => {
    if (!confirm(`¿Eliminar a ${u.nombre}? Esta acción no se puede deshacer.`)) return;
    try {
      await pb.collection('usuarios_registrados').delete(u.id);
      toast({ title: "Usuario eliminado", description: `${u.nombre} fue eliminado de la agenda`, variant: "destructive" });
      await fetchUsuarios();
    } catch (e) {
      console.error('Error eliminando usuario:', e);
      toast({ title: "Error", description: "No se pudo eliminar el usuario", variant: "destructive" });
    }
  };

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
      <DialogContent className="max-w-lg max-h-[85vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <User className="w-5 h-5" />
            Agenda / Autorizaciones
          </DialogTitle>
        </DialogHeader>

        <Tabs defaultValue="contactos" className="w-full">
          <TabsList className="w-full grid grid-cols-3">
            <TabsTrigger value="contactos" className="gap-1 text-xs">
              <User className="w-3.5 h-3.5" />Contactos
            </TabsTrigger>
            <TabsTrigger value="autorizaciones" className="gap-1 text-xs">
              <ShieldCheck className="w-3.5 h-3.5" />Autorizaciones
            </TabsTrigger>
            <TabsTrigger value="historial" className="gap-1 text-xs">
              <History className="w-3.5 h-3.5" />Historial
            </TabsTrigger>
          </TabsList>

          <TabsContent value="contactos" className="space-y-3 mt-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por nombre, teléfono, email o función..."
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                className="pl-10"
              />
            </div>

            <ScrollArea className="h-[370px] -mx-2 px-2">
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
                      {editingId === u.id ? (
                        <div className="space-y-3">
                          <div className="space-y-1">
                            <Label className="text-xs">Nombre</Label>
                            <Input value={editData.nombre || ''} onChange={e => setEditData(d => ({ ...d, nombre: e.target.value }))} className="h-9" />
                          </div>
                          <div className="grid grid-cols-2 gap-2">
                            <div className="space-y-1">
                              <Label className="text-xs">Celular</Label>
                              <Input value={editData.celular || ''} onChange={e => setEditData(d => ({ ...d, celular: e.target.value }))} className="h-9" />
                            </div>
                            <div className="space-y-1">
                              <Label className="text-xs">Email</Label>
                              <Input value={editData.email || ''} onChange={e => setEditData(d => ({ ...d, email: e.target.value }))} className="h-9" />
                            </div>
                          </div>
                          <div className="space-y-1">
                            <Label className="text-xs">Tipo</Label>
                            <Select value={editData.tipo} onValueChange={v => setEditData(d => ({ ...d, tipo: v as TipoUsuario, departamento: v !== 'Personal TAS' ? undefined : d.departamento, nombreEmpresa: v !== 'Empresa' ? undefined : d.nombreEmpresa }))}>
                              <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                              <SelectContent>
                                {tiposUsuario.map(t => <SelectItem key={t} value={t}>{t}</SelectItem>)}
                              </SelectContent>
                            </Select>
                          </div>
                          {editData.tipo === 'Personal TAS' && (
                            <div className="space-y-1">
                              <Label className="text-xs">Departamento</Label>
                              <Select value={editData.departamento || ''} onValueChange={v => setEditData(d => ({ ...d, departamento: v as DepartamentoTAS }))}>
                                <SelectTrigger className="h-9"><SelectValue placeholder="Seleccionar" /></SelectTrigger>
                                <SelectContent className="max-h-48">
                                  {departamentosTAS.map(d => <SelectItem key={d} value={d}>{d}</SelectItem>)}
                                </SelectContent>
                              </Select>
                            </div>
                          )}
                          {editData.tipo === 'Empresa' && (
                            <div className="space-y-1">
                              <Label className="text-xs">Empresa</Label>
                              <Input value={editData.nombreEmpresa || ''} onChange={e => setEditData(d => ({ ...d, nombreEmpresa: e.target.value }))} className="h-9" placeholder="Nombre de la empresa" />
                            </div>
                          )}
                          <div className="flex gap-2 justify-end">
                            <Button variant="ghost" size="sm" onClick={cancelEdit} className="h-8 gap-1"><X className="w-3.5 h-3.5" />Cancelar</Button>
                            <Button size="sm" onClick={saveEdit} className="h-8 gap-1"><Check className="w-3.5 h-3.5" />Guardar</Button>
                          </div>
                        </div>
                      ) : (
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex-1 min-w-0">
                            <p className="font-medium truncate">{u.nombre}</p>
                            <div className="flex items-center gap-3 mt-1 text-sm text-muted-foreground flex-wrap">
                              {u.celular && (
                                <a href={`tel:${u.celular}`} className="flex items-center gap-1 hover:text-primary">
                                  <Phone className="w-3 h-3" />{u.celular}
                                </a>
                              )}
                              {u.email && (
                                <a href={`mailto:${u.email}`} className="flex items-center gap-1 hover:text-primary truncate">
                                  <Mail className="w-3 h-3" />{u.email}
                                </a>
                              )}
                              {u.nombreEmpresa && (
                                <span className="flex items-center gap-1">
                                  <Building className="w-3 h-3" />{u.nombreEmpresa}
                                </span>
                              )}
                            </div>
                          </div>
                          <div className="flex items-center gap-1">
                            <div className="flex flex-col items-end gap-1 mr-2">
                              <Badge variant="outline" className={getBadgeColor(u.tipo)}>{u.tipo}</Badge>
                              {u.departamento && <span className="text-xs text-muted-foreground">{u.departamento}</span>}
                            </div>
                            <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => startEdit(u)}>
                              <Pencil className="w-3.5 h-3.5" />
                            </Button>
                            <Button variant="ghost" size="icon" className="h-7 w-7 text-destructive hover:text-destructive" onClick={() => handleDelete(u)}>
                              <Trash2 className="w-3.5 h-3.5" />
                            </Button>
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </ScrollArea>

            <p className="text-xs text-muted-foreground text-center">
              {resultados.length} de {usuarios.length} contacto{usuarios.length !== 1 ? 's' : ''}
            </p>
          </TabsContent>

          <TabsContent value="autorizaciones" className="mt-3">
            <AutorizacionesTab />
          </TabsContent>

          <TabsContent value="historial" className="mt-3">
            <HistorialAutorizacionesTab />
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
}
