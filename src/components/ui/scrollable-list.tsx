import { cn } from "@/lib/utils";

/**
 * Contenedor scrollable simple con `overflow-y-auto`.
 *
 * v2.8 (2026-07-23) — ROLLBACK P2/P3/P4/P5:
 *   Antes este componente:
 *     - Consumia `useTouchUX` para engordar la scrollbar en tactil
 *       (agregando la clase `scrollbar-touch`).
 *     - Renderizaba dos botones ▲/▼ flotantes en la esquina inferior
 *       derecha para poder scrollear la lista con el dedo.
 *   Ese experimento se revirtio: las 3 PCs corren con mouse+teclado y
 *   usan la scrollbar nativa del navegador. Este componente quedo
 *   como un simple wrapper con overflow-y-auto, para no romper a los
 *   callers que ya lo importan.
 */
export interface ScrollableListProps
  extends React.HTMLAttributes<HTMLDivElement> {
  /** @deprecated ignorado tras el rollback v2.8, se mantiene por API compat. */
  paso?: number;
  /** @deprecated ignorado tras el rollback v2.8, se mantiene por API compat. */
  forzarBotones?: boolean;
}

export function ScrollableList({
  className,
  children,
  paso: _paso,
  forzarBotones: _forzarBotones,
  ...divProps
}: ScrollableListProps) {
  // Los dos parametros marcados con `_` se aceptan solo para no romper
  // los llamadores viejos. Ya no hacen nada.
  void _paso;
  void _forzarBotones;
  return (
    <div {...divProps} className={cn("overflow-y-auto", className)}>
      {children}
    </div>
  );
}
