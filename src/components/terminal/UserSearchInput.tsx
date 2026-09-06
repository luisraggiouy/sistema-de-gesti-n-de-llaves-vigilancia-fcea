import { useState, useMemo, useRef, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { UsuarioRegistrado } from '@/data/fceaData';
import { Phone, User, UserPlus, Check, Mail, Search } from 'lucide-react';


interface UserSearchInputProps {
  onUserSelect: (usuario: UsuarioRegistrado) => void;
  onRegisterClick: () => void;
  selectedUser: UsuarioRegistrado | null;
  buscarUsuarios: (texto: string) => UsuarioRegistrado[];
}

// UPGRADE SEGURIDAD 2026-09-05 — Mínimo de dígitos para desplegar la lista al
// buscar por CELULAR.
//
// PROBLEMA: al tipear el primer "0" se desplegaban TODOS los celulares que
// empiezan con 0 (o "09" -> todos los "09..."), exponiendo la lista completa de
// usuarios y habilitando suplantación de identidad (cualquiera podía ver y
// elegir a otra persona).
//
// SOLUCIÓN: la lista de coincidencias por celular recién se muestra a partir
// del 5.º dígito tipeado. Así se conserva la rapidez (con 5 dígitos ya se acota
// muchísimo) pero se evita exponer todos los números con solo 1-2 dígitos.
//
// La búsqueda por EMAIL mantiene el umbral histórico de 2 caracteres, porque
// el email no expone la lista completa de la misma forma (es texto propio).
const MIN_DIGITOS_CELULAR = 5;
const MIN_CARACTERES_EMAIL = 2;

/** ¿El texto tipeado es una búsqueda por celular (solo dígitos/separadores)? */
const esBusquedaCelular = (texto: string) => /^[\d\s\-\+\(\)]+$/.test(texto.trim());

/**
 * ¿El texto alcanza el mínimo para desplegar la lista de coincidencias?
 * - Celular: al menos MIN_DIGITOS_CELULAR dígitos reales.
 * - Email / texto: al menos MIN_CARACTERES_EMAIL caracteres.
 */
const alcanzaUmbralBusqueda = (texto: string) => {
  const t = texto.trim();
  if (!t) return false;
  if (esBusquedaCelular(t)) {
    return t.replace(/\D/g, '').length >= MIN_DIGITOS_CELULAR;
  }
  return t.length >= MIN_CARACTERES_EMAIL;
};

/**
 * Buscador de usuarios por celular o email (sin autocompletar por nombre).
 *
 * v2.8 (2026-07-23) — ROLLBACK P2:
 *   Antes, en modo tactil, este componente renderizaba un `Sheet`
 *   lateral (drawer desde la derecha) con las coincidencias para
 *   que el teclado virtual del `TouchInput` no las tapara. Ese
 *   experimento se revirtio: ahora usamos siempre el Input normal +
 *   listado absolute debajo del input, aun en pantallas tactiles.
 *   El teclado on-screen de Windows (TabTip) sabe reacomodarse solo
 *   cuando aparece, y con mouse+teclado es la UX esperada.
 */
export function UserSearchInput({ onUserSelect, onRegisterClick, selectedUser, buscarUsuarios }: UserSearchInputProps) {
  const [busqueda, setBusqueda] = useState('');
  const [showSuggestions, setShowSuggestions] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const suggestionsRef = useRef<HTMLDivElement>(null);


  const sugerencias = useMemo(() => {
    if (!alcanzaUmbralBusqueda(busqueda)) return [];
    return buscarUsuarios(busqueda);
  }, [busqueda, buscarUsuarios]);

  // Determinar si el texto ingresado es celular o email.
  //
  // FIX 2026-09-03: antes, cualquier texto que no fuera dígitos puros ni
  // contuviera "@" se clasificaba como 'nombre' y se BLOQUEABA con un cartel
  // ("búsqueda por nombre no permitida"). Eso impedía identificarse a los
  // usuarios registrados SOLO con email (sin celular) que tipeaban la parte
  // local de su correo sin la "@" (ej. "katana941"). Ahora ese caso se trata
  // como 'email' (búsqueda por la parte local del correo, ver
  // useUsuariosRegistrados.buscarPorTexto). La seguridad se mantiene a nivel
  // de datos: solo se matchea contra el email, nunca contra el nombre.
  const tipoBusqueda = useMemo(() => {
    const texto = busqueda.trim();
    if (!texto) return null;
    if (/^[\d\s\-\+\(\)]+$/.test(texto)) return 'celular';
    return 'email';
  }, [busqueda]);

  // Cierre "click fuera" del listado de sugerencias.
  //
  // Usamos `pointerdown` (no `mousedown`) para captar bien tanto mouse
  // como touch en Chromium 120+. Si el click cae dentro del container
  // (input o panel) no cerramos.
  useEffect(() => {
    const handlePointerDown = (e: PointerEvent) => {
      const target = e.target as HTMLElement | null;
      if (!target) return;
      if (containerRef.current && containerRef.current.contains(target)) return;
      if (suggestionsRef.current && suggestionsRef.current.contains(target)) return;
      setShowSuggestions(false);
    };
    document.addEventListener('pointerdown', handlePointerDown);
    return () => document.removeEventListener('pointerdown', handlePointerDown);
  }, []);


  const handleSelect = (usuario: UsuarioRegistrado) => {
    onUserSelect(usuario);
    setBusqueda('');
    setShowSuggestions(false);
  };

  const handleInputChange = (value: string) => {
    setBusqueda(value);
    setShowSuggestions(alcanzaUmbralBusqueda(value));
  };

  const getContactInfo = (usuario: UsuarioRegistrado) => {
    const parts: string[] = [];
    if (usuario.celular) parts.push(usuario.celular);
    if (usuario.email) parts.push(usuario.email);
    return parts.join(' • ');
  };

  return (
    <div ref={containerRef} className="space-y-4">
      <div className="flex items-start justify-between">
        <div>
          <h3 className="text-lg font-semibold text-foreground flex items-baseline gap-2">
            <User className="w-5 h-5 text-primary self-center" />
            <span>Identificarse</span>
            <span className="text-base font-normal text-muted-foreground">
              con su número de celular o e-mail
            </span>
          </h3>
          <p className="text-sm text-muted-foreground mt-1">
            Haga click sobre su nombre una vez que lo vea en la pantalla, para solicitar la/s llaves
          </p>
        </div>

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
          {/* Icono dinámico según tipo de búsqueda */}
          {tipoBusqueda === 'celular' ? (
            <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-primary" />
          ) : tipoBusqueda === 'email' ? (
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-primary" />
          ) : (
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
          )}
          <Input
            ref={inputRef}
            placeholder="Ingrese aquí su número de celular o email..."
            value={busqueda}
            onChange={(e) => handleInputChange(e.target.value)}
            onFocus={() => alcanzaUmbralBusqueda(busqueda) && setShowSuggestions(true)}
            className="pl-10 h-12 text-lg"
          />


          {/* Sugerencias cuando hay resultados. Card absolute debajo del
              input, con scroll vertical interno si la lista es larga. */}
          {showSuggestions && sugerencias.length > 0 && (
            <Card
              ref={suggestionsRef}
              className="absolute z-50 w-full mt-1 py-2 shadow-lg overflow-y-auto max-h-60"
            >
              {sugerencias.map((usuario) => (
                <button
                  key={usuario.id}
                  onClick={() => handleSelect(usuario)}
                  className="w-full text-left hover:bg-muted/50 transition-colors flex items-center gap-3 px-4 py-3"
                >
                  <div className="rounded-full bg-muted flex items-center justify-center flex-shrink-0 w-8 h-8">
                    <User className="text-muted-foreground w-4 h-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="font-medium text-foreground truncate">
                      {usuario.nombre}
                    </p>
                    <p className="text-muted-foreground text-sm">
                      {getContactInfo(usuario)} • {usuario.tipo}
                      {usuario.tipo === 'Empresa' && usuario.nombreEmpresa && ` • Empresa: ${usuario.nombreEmpresa}`}
                      {usuario.tipo === 'Personal TAS' && usuario.departamento && ` • Depto: ${usuario.departamento}`}
                    </p>
                  </div>
                </button>
              ))}
            </Card>
          )}


          {/* Sin resultados */}
          {showSuggestions && alcanzaUmbralBusqueda(busqueda) && sugerencias.length === 0 && (
            <Card className="absolute z-50 w-full mt-1 p-4 shadow-lg">
              <p className="text-center text-muted-foreground text-sm">No se encontro ningun usuario con ese celular o email</p>
              <Button variant="link" className="w-full mt-2" onClick={onRegisterClick}>
                <UserPlus className="w-4 h-4 mr-2" />
                Registrarse ahora
              </Button>
            </Card>
          )}
        </div>
      )}

      {/* Texto de instruccion con link de registro en azul */}
      <p className="text-sm text-muted-foreground text-center leading-relaxed">
        Identifiquese con su numero de celular o con su email.{' '}
        De lo contrario{' '}
        <button
          onClick={onRegisterClick}
          className="text-blue-600 hover:text-blue-800 underline font-medium cursor-pointer"
        >
          registrese
        </button>
        {' '}para continuar.
      </p>
    </div>
  );
}
