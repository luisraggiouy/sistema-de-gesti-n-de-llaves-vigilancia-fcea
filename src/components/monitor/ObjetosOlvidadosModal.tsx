import { useState } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ObjetoOlvidado } from '@/types/objetoOlvidado';
import { Package, Search, Calendar, MapPin, User, CreditCard, CheckCircle2, Plus, Eye, X } from 'lucide-react';

interface ObjetosOlvidadosModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  objetos: ObjetoOlvidado[];
  objetosEnCustodia: ObjetoOlvidado[];
  objetosDevueltos: ObjetoOlvidado[];
  vigilantes: string[];
  onRegistrarClick: () => void;
  onDevolver: (objetoId: string, datos: {
    vigilanteEntrega: string;
    nombreReceptor: string;
    cedulaReceptor: string;
  }) => void;
  buscarObjetos: (filtros: {
    texto?: string;
    lugar?: string;
    fechaDesde?: Date;
    fechaHasta?: Date;
    estado?: 'custodia' | 'devuelto' | 'todos';
  }) => ObjetoOlvidado[];
}

function ObjetoCard({ objeto, vigilantes, onDevolver, showDevolucion = true }: {
  objeto: ObjetoOlvidado;
  vigilantes: string[];
  onDevolver?: (objetoId: string, datos: { vigilanteEntrega: string; nombreReceptor: string; cedulaReceptor: string }) => void;
  showDevolucion?: boolean;
}) {
  const [expanded, setExpanded] = useState(false);
  const [devolviendo, setDevolviendo] = useState(false);
  const [vigilante, setVigilante] = useState('');
  const [nombre, setNombre] = useState('');
  const [cedula, setCedula] = useState('');

  const handleDevolver = () => {
    if (!vigilante || !nombre.trim() || !cedula.trim()) return;
    onDevolver?.(objeto.id, { vigilanteEntrega: vigilante, nombreReceptor: nombre.trim(), cedulaReceptor: cedula.trim() });
    setDevolviendo(false);
  };

  return (
    <Card className={`p-4 ${objeto.estado === 'custodia' ? 'border-amber-300 bg-amber-50/50' : 'border-emerald-300 bg-emerald-50/50'}`}>
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <Package className="w-4 h-4 text-muted-foreground shrink-0" />
            <span className="font-semibold truncate">{objeto.descripcion}</span>
            <Badge variant={objeto.estado === 'custodia' ? 'default' : 'secondary'} className={
              objeto.estado === 'custodia' ? 'bg-amber-100 text-amber-800 border-amber-300' : 'bg-emerald-100 text-emerald-800 border-emerald-300'
            }>
              {objeto.estado === 'custodia' ? 'En custodia' : 'Devuelto'}
            </Badge>
          </div>
          <div className="text-sm text-muted-foreground space-y-0.5">
            {objeto.lugarEncontrado && (
              <p className="flex items-center gap-1"><MapPin className="w-3 h-3" /> {objeto.lugarEncontrado}</p>
            )}
            <p className="flex items-center gap-1">
              <Calendar className="w-3 h-3" />
              {objeto.fechaRegistro.toLocaleDateString('es-UY')} {objeto.fechaRegistro.toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' })}
            </p>
            <p>Registrado por: {(objeto as any).registradoPor || (objeto as any).vigilanteRegistra}</p>
            {objeto.devolucion && (
              <div className="mt-1 p-2 bg-emerald-100 rounded text-xs">
                <p><strong>Devuelto:</strong> {objeto.devolucion.fecha.toLocaleDateString('es-UY')}</p>
                <p>Entregó: {objeto.devolucion.vigilanteEntrega}</p>
                <p>Receptor: {objeto.devolucion.nombreReceptor} (CI: {objeto.devolucion.cedulaReceptor})</p>
              </div>
            )}
          </div>
        </div>
        <div className="flex gap-1 shrink-0">
          {(objeto as any).fotos && (
            <Button variant="outline" onClick={() => setExpanded(!expanded)} className="text-sm px-4 py-2">
              <Eye className="w-4 h-4 mr-1.5" />
              Ver fotos
            </Button>
          )}
          {showDevolucion && objeto.estado === 'custodia' && (
            <Button variant="outline" onClick={() => setDevolviendo(!devolviendo)} className="text-sm px-4 py-2">
              <CheckCircle2 className="w-4 h-4 mr-1.5" />
              Devolver
            </Button>
          )}
        </div>
      </div>

       {expanded && (objeto as any).fotos && (
        <div className="mt-3 space-y-3 border-t pt-3">
          {(objeto as any).fotos.general && (
            <div>
              <p className="text-xs text-muted-foreground mb-1 font-medium">General</p>
              <img src={(objeto as any).fotos.general} alt="General" className="w-full h-auto rounded border" />
            </div>
          )}
          {(objeto as any).fotos.marca && (
            <div>
              <p className="text-xs text-muted-foreground mb-1 font-medium">Marca</p>
              <img src={(objeto as any).fotos.marca} alt="Marca" className="w-full h-auto rounded border" />
            </div>
          )}
          {(objeto as any).fotos.adicional && (
            <div>
              <p className="text-xs text-muted-foreground mb-1 font-medium">Adicional</p>
              <img src={(objeto as any).fotos.adicional} alt="Adicional" className="w-full h-auto rounded border" />
            </div>
          )}
        </div>
      )}

      {devolviendo && (
        <div className="mt-3 border-t pt-3 space-y-3">
          <h4 className="font-medium text-sm">Datos de devolución</h4>
          <div className="space-y-2">
            <Label className="text-xs">Vigilante que entrega</Label>
            <Select value={vigilante} onValueChange={setVigilante}>
              <SelectTrigger className="h-9"><SelectValue placeholder="Seleccionar" /></SelectTrigger>
              <SelectContent>
                {vigilantes.map(v => <SelectItem key={v} value={v}>{v}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label className="text-xs flex items-center gap-1"><User className="w-3 h-3" />Nombre del receptor</Label>
            <Input className="h-9" placeholder="Nombre completo" value={nombre} onChange={e => setNombre(e.target.value)} maxLength={100} />
          </div>
          <div className="space-y-2">
            <Label className="text-xs flex items-center gap-1"><CreditCard className="w-3 h-3" />Cédula del receptor</Label>
            <Input className="h-9" placeholder="Ej: 1.234.567-8" value={cedula} onChange={e => setCedula(e.target.value)} maxLength={20} />
          </div>
          <div className="flex gap-2">
            <Button size="sm" onClick={handleDevolver} disabled={!vigilante || !nombre.trim() || !cedula.trim()}>Confirmar devolución</Button>
            <Button size="sm" variant="ghost" onClick={() => setDevolviendo(false)}>Cancelar</Button>
          </div>
        </div>
      )}
    </Card>
  );
}

export function ObjetosOlvidadosModal({
  open, onOpenChange, objetos, objetosEnCustodia, objetosDevueltos,
  vigilantes, onRegistrarClick, onDevolver, buscarObjetos,
}: ObjetosOlvidadosModalProps) {
  const [busqueda, setBusqueda] = useState('');
  const [busquedaLugar, setBusquedaLugar] = useState('');
  const [fechaDesde, setFechaDesde] = useState('');
  const [fechaHasta, setFechaHasta] = useState('');
  const [filtroEstado, setFiltroEstado] = useState<'custodia' | 'devuelto' | 'todos'>('todos');

  const resultados = buscarObjetos({
    texto: busqueda || undefined,
    lugar: busquedaLugar || undefined,
    fechaDesde: fechaDesde ? new Date(fechaDesde) : undefined,
    fechaHasta: fechaHasta ? new Date(fechaHasta) : undefined,
    estado: filtroEstado,
  });

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={() => onOpenChange(false)} />
      <div className="relative z-10 bg-white rounded-lg shadow-xl w-full max-w-2xl mx-4 flex flex-col" style={{ maxHeight: '90vh' }}>
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b flex-shrink-0">
          <h2 className="text-lg font-semibold flex items-center gap-2">
            <Package className="w-5 h-5" />
            Objetos Olvidados
            {objetosEnCustodia.length > 0 && (
              <Badge className="bg-amber-100 text-amber-800 border-amber-300">{objetosEnCustodia.length} en custodia</Badge>
            )}
          </h2>
          <button onClick={() => onOpenChange(false)} className="p-1 rounded hover:bg-gray-100">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-6 min-h-0">
          <div className="flex justify-end mb-4">
            <Button onClick={onRegistrarClick} className="gap-2" size="sm">
              <Plus className="w-4 h-4" />
              Registrar Objeto
            </Button>
          </div>

          <Tabs defaultValue="custodia">
            <TabsList className="w-full">
              <TabsTrigger value="custodia" className="flex-1">En Custodia ({objetosEnCustodia.length})</TabsTrigger>
              <TabsTrigger value="buscar" className="flex-1"><Search className="w-3 h-3 mr-1" />Buscar</TabsTrigger>
              <TabsTrigger value="devueltos" className="flex-1">Devueltos ({objetosDevueltos.length})</TabsTrigger>
            </TabsList>

            <TabsContent value="custodia" className="space-y-3 mt-3">
              {objetosEnCustodia.length === 0 ? (
                <Card className="p-8 text-center"><Package className="w-10 h-10 mx-auto text-muted-foreground/30 mb-2" /><p className="text-muted-foreground text-sm">No hay objetos en custodia</p></Card>
              ) : objetosEnCustodia.map(o => (
                <ObjetoCard key={o.id} objeto={o} vigilantes={vigilantes} onDevolver={onDevolver} />
              ))}
            </TabsContent>

            <TabsContent value="buscar" className="space-y-3 mt-3">
              <div className="grid grid-cols-2 gap-2">
                <div><Label className="text-xs">Descripción</Label><Input placeholder="Ej: jarra térmica" value={busqueda} onChange={e => setBusqueda(e.target.value)} className="h-9" /></div>
                <div><Label className="text-xs">Lugar</Label><Input placeholder="Ej: Salón 101" value={busquedaLugar} onChange={e => setBusquedaLugar(e.target.value)} className="h-9" /></div>
                <div><Label className="text-xs">Desde</Label><Input type="date" value={fechaDesde} onChange={e => setFechaDesde(e.target.value)} className="h-9" /></div>
                <div><Label className="text-xs">Hasta</Label><Input type="date" value={fechaHasta} onChange={e => setFechaHasta(e.target.value)} className="h-9" /></div>
              </div>
              <Select value={filtroEstado} onValueChange={(v) => setFiltroEstado(v as any)}>
                <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="todos">Todos los estados</SelectItem>
                  <SelectItem value="custodia">En custodia</SelectItem>
                  <SelectItem value="devuelto">Devueltos</SelectItem>
                </SelectContent>
              </Select>
              {resultados.length === 0 ? (
                <Card className="p-6 text-center"><Search className="w-8 h-8 mx-auto text-muted-foreground/30 mb-2" /><p className="text-muted-foreground text-sm">No se encontraron objetos</p></Card>
              ) : (
                <div className="space-y-2">
                  <p className="text-xs text-muted-foreground">{resultados.length} resultado{resultados.length !== 1 ? 's' : ''}</p>
                  {resultados.map(o => <ObjetoCard key={o.id} objeto={o} vigilantes={vigilantes} onDevolver={onDevolver} />)}
                </div>
              )}
            </TabsContent>

            <TabsContent value="devueltos" className="space-y-3 mt-3">
              {objetosDevueltos.length === 0 ? (
                <Card className="p-8 text-center"><CheckCircle2 className="w-10 h-10 mx-auto text-muted-foreground/30 mb-2" /><p className="text-muted-foreground text-sm">No hay objetos devueltos</p></Card>
              ) : objetosDevueltos.map(o => (
                <ObjetoCard key={o.id} objeto={o} vigilantes={vigilantes} showDevolucion={false} />
              ))}
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  );
}