import { useEffect, useRef, useState, useCallback } from "react";
import { ChevronUp, ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";
import { useTouchUX } from "@/hooks/useTouchUX";

/**
 * Contenedor scrollable con botones flotantes ▲ / ▼ para navegar listas
 * largas en monitores táctiles que NO soportan scroll por gesto
 * (típicamente 3nStar TCM008 resistivo).
 *
 * En modo no-táctil se comporta como un div común con overflow-y-auto.
 * En modo táctil:
 *   - Ensancha la scrollbar del navegador (25 px, alto contraste).
 *   - Muestra dos botones circulares en la esquina inferior derecha
 *     que scrollean 80% del alto visible por toque.
 *   - Los botones se ocultan automáticamente si ya estás al tope
 *     o al fondo, respectivamente.
 */
export interface ScrollableListProps
  extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Paso de scroll como fracción del alto visible.
   * Ej: 0.8 = scrollea el 80% del alto en cada toque.
   */
  paso?: number;
  /** Muestra los botones también en modo no-táctil (útil para testing). */
  forzarBotones?: boolean;
}

export function ScrollableList({
  className,
  children,
  paso = 0.8,
  forzarBotones = false,
  ...divProps
}: ScrollableListProps) {
  const { scrollbarAncha, isTouch } = useTouchUX();
  const scrollRef = useRef<HTMLDivElement>(null);
  const [puedeSubir, setPuedeSubir] = useState(false);
  const [puedeBajar, setPuedeBajar] = useState(false);

  const mostrarBotones = forzarBotones || isTouch;

  const actualizarEstado = useCallback(() => {
    const el = scrollRef.current;
    if (!el) return;
    const tolerancia = 2;
    setPuedeSubir(el.scrollTop > tolerancia);
    setPuedeBajar(
      el.scrollTop + el.clientHeight < el.scrollHeight - tolerancia,
    );
  }, []);

  useEffect(() => {
    actualizarEstado();
    const el = scrollRef.current;
    if (!el) return;
    el.addEventListener("scroll", actualizarEstado, { passive: true });

    // Re-evaluar cuando cambia el contenido (agregar/quitar items).
    const observer = new ResizeObserver(actualizarEstado);
    observer.observe(el);

    return () => {
      el.removeEventListener("scroll", actualizarEstado);
      observer.disconnect();
    };
  }, [actualizarEstado, children]);

  const scrollearArriba = () => {
    const el = scrollRef.current;
    if (!el) return;
    el.scrollBy({ top: -el.clientHeight * paso, behavior: "smooth" });
  };

  const scrollearAbajo = () => {
    const el = scrollRef.current;
    if (!el) return;
    el.scrollBy({ top: el.clientHeight * paso, behavior: "smooth" });
  };

  return (
    <div className="relative">
      <div
        ref={scrollRef}
        {...divProps}
        className={cn(
          "overflow-y-auto",
          // En táctil ensanchamos la scrollbar nativa (Chrome/Edge).
          scrollbarAncha && "scrollbar-touch",
          className,
        )}
      >
        {children}
      </div>

      {mostrarBotones && (
        <div className="pointer-events-none absolute right-2 bottom-2 flex flex-col gap-2">
          <button
            type="button"
            onClick={scrollearArriba}
            disabled={!puedeSubir}
            aria-label="Subir en la lista"
            className={cn(
              "pointer-events-auto h-12 w-12 rounded-full shadow-lg border-2 flex items-center justify-center",
              "transition-all",
              puedeSubir
                ? "bg-primary text-primary-foreground border-primary hover:scale-105 active:scale-95"
                : "bg-muted text-muted-foreground border-border opacity-40 cursor-not-allowed",
            )}
          >
            <ChevronUp className="h-6 w-6" />
          </button>
          <button
            type="button"
            onClick={scrollearAbajo}
            disabled={!puedeBajar}
            aria-label="Bajar en la lista"
            className={cn(
              "pointer-events-auto h-12 w-12 rounded-full shadow-lg border-2 flex items-center justify-center",
              "transition-all",
              puedeBajar
                ? "bg-primary text-primary-foreground border-primary hover:scale-105 active:scale-95"
                : "bg-muted text-muted-foreground border-border opacity-40 cursor-not-allowed",
            )}
          >
            <ChevronDown className="h-6 w-6" />
          </button>
        </div>
      )}
    </div>
  );
}
