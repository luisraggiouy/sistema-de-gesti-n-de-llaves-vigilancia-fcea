import { useState, useMemo, useRef, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { UsuarioRegistrado } from '@/data/fceaData';
import { Phone, User, UserPlus, Check, Mail, Search } from 'lucide-react';
import { cn } from '@/lib/utils';

interface UserSearchInputProps {
  onUserSelect: (usuario: UsuarioRegistrado) => void;
  onRegisterClick: () => void;
  selectedUser: UsuarioRegistrado | null;
  buscarUsuarios: (texto: string) => UsuarioRegistrado[];
}

export function UserSearchInput({ onUserSelect, onRegisterClick, selectedUser, buscarUsuarios }: UserSearchInputProps) {
  const [busqueda, setBusqueda] = useState('');
  const [showSuggestions, setShowSuggestions] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const sugerencias = useMemo(() => {
    if (busqueda.length < 2) return [];
    // Usamos el texto de búsqueda tal como está, la función buscarPorTexto
    // ya se encarga de normalizar y hacer la búsqueda insensible a mayúsculas/minúsculas
    return buscarUsuarios(busqueda).slice(0, 5);
  }, [busqueda, buscarUsuarios]);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setShowSuggestions(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSelect = (usuario: UsuarioRegistrado) => {
    onUserSelect(usuario);
    setBusqueda('');
    setShowSuggestions(false);
  };

  const handleInputChange = (value: string) => {
    setBusqueda(value);
    setShowSuggestions(value.length >= 2);
  };

  const getContactInfo = (usuario: UsuarioRegistrado) => {
    const parts: string[] = [];
    if (usuario.celular) parts.push(usuario.celular);
    if (usuario.email) parts.push(usuario.email);
    return parts.join(' • ');
  };

  return (
    <div ref={containerRef} className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-foreground flex items-center gap-2">
          <User className="w-5 h-5 text-primary" />
          Identificarse
        </h3>
        <Button variant="outline" size="sm" onClick={onRegisterClick} className="gap-2">
          <UserPlus className="w-4 h-4" />
          Primera vez? Registrarse
        </Button>
      </div>

      {selectedUser ? (
        <Card className="p-4 bg-primary/5 border-primary">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
                <User className="w-5 h-5 text-primary" />
              </div>
              <div>
                <p className="font-semibold text-foreground">{selectedUser.nombre}</p>
                <p className="text-sm text-muted-foreground flex items-center gap-1 flex-wrap">
                  {selectedUser.celular && (<><Phone className="w-3 h-3" />{selectedUser.celular}</>)}
                  {selectedUser.celular && selectedUser.email && <span>•</span>}
                  {selectedUser.email && (<><Mail className="w-3 h-3" />{selectedUser.email}</>)}
                  <span>•</span> {selectedUser.tipo}
                  {selectedUser.departamento && <span>({selectedUser.departamento})</span>}
                  {selectedUser.tipo === 'Empresa' && selectedUser.nombreEmpresa && <span>• Empresa: {selectedUser.nombreEmpresa}</span>}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Check className="w-5 h-5 text-primary" />
              <Button variant="ghost" size="sm" onClick={() => { onUserSelect(null as unknown as UsuarioRegistrado); setBusqueda(''); }}>
                Cambiar
              </Button>
            </div>
          </div>
        </Card>
      ) : (
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
          <Input
            ref={inputRef}
            placeholder="Ingrese su celular, email o nombre..."
            value={busqueda}
            onChange={(e) => handleInputChange(e.target.value)}
            onFocus={() => busqueda.length >= 2 && setShowSuggestions(true)}
            className="pl-10 h-12 text-lg"
          />
          {showSuggestions && sugerencias.length > 0 && (
            <Card className="absolute z-50 w-full mt-1 py-2 shadow-lg max-h-60 overflow-y-auto">
              {sugerencias.map((usuario) => (
                <button
                  key={usuario.id}
                  onClick={() => handleSelect(usuario)}
                  className={cn("w-full px-4 py-3 text-left hover:bg-muted/50 transition-colors", "flex items-center gap-3")}
                >
                  <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center flex-shrink-0">
                    <User className="w-4 h-4 text-muted-foreground" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="font-medium text-foreground truncate">{usuario.nombre}</p>
                    <p className="text-sm text-muted-foreground">
                      {getContactInfo(usuario)} • {usuario.tipo}
                      {usuario.tipo === 'Empresa' && usuario.nombreEmpresa && ` • Empresa: ${usuario.nombreEmpresa}`}
                      {usuario.tipo === 'Personal TAS' && usuario.departamento && ` • Depto: ${usuario.departamento}`}
                    </p>
                  </div>
                </button>
              ))}
            </Card>
          )}
          {showSuggestions && busqueda.length >= 2 && sugerencias.length === 0 && (
            <Card className="absolute z-50 w-full mt-1 p-4 shadow-lg">
              <p className="text-center text-muted-foreground text-sm">No se encontró ningún usuario registrado</p>
              <Button variant="link" className="w-full mt-2" onClick={onRegisterClick}>
                <UserPlus className="w-4 h-4 mr-2" />
                Registrarse ahora
              </Button>
            </Card>
          )}
        </div>
      )}
      <p className="text-xs text-muted-foreground text-center">
        Ingrese al menos 2 caracteres (celular, email o nombre) para buscar
      </p>
    </div>
  );
}