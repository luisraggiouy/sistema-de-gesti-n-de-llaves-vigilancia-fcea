import * as React from "react";
import * as ScrollAreaPrimitive from "@radix-ui/react-scroll-area";

import { cn } from "@/lib/utils";
import { useTouchUX } from "@/hooks/useTouchUX";

/**
 * ScrollArea táctil-friendly.
 *
 * Cuando `ui.scrollbar_ancha` (o hardware==="tactil") está activo, la
 * barra vertical pasa de ~10 px a **25 px** con contraste alto, para
 * que sea utilizable en monitores resistivos como el 3nStar TCM008
 * que NO soportan scroll por gesto.
 *
 * El thumb (parte movible) usa el color primario a 60 % de opacidad,
 * para que se vea claramente sobre cualquier fondo. Sigue siendo
 * "translucido" para no distraer del contenido.
 */
const ScrollArea = React.forwardRef<
  React.ElementRef<typeof ScrollAreaPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof ScrollAreaPrimitive.Root>
>(({ className, children, ...props }, ref) => {
  const { scrollbarAncha } = useTouchUX();
  return (
    <ScrollAreaPrimitive.Root
      ref={ref}
      className={cn("relative overflow-hidden", className)}
      {...props}
    >
      <ScrollAreaPrimitive.Viewport className="h-full w-full rounded-[inherit]">
        {children}
      </ScrollAreaPrimitive.Viewport>
      <ScrollBar ancha={scrollbarAncha} />
      <ScrollAreaPrimitive.Corner />
    </ScrollAreaPrimitive.Root>
  );
});
ScrollArea.displayName = ScrollAreaPrimitive.Root.displayName;

interface ScrollBarProps
  extends React.ComponentPropsWithoutRef<
    typeof ScrollAreaPrimitive.ScrollAreaScrollbar
  > {
  /** Si true, usa dimensiones táctiles (25 px + contraste alto). */
  ancha?: boolean;
}

const ScrollBar = React.forwardRef<
  React.ElementRef<typeof ScrollAreaPrimitive.ScrollAreaScrollbar>,
  ScrollBarProps
>(({ className, orientation = "vertical", ancha = false, ...props }, ref) => (
  <ScrollAreaPrimitive.ScrollAreaScrollbar
    ref={ref}
    orientation={orientation}
    className={cn(
      "flex touch-none select-none transition-colors",
      // Vertical
      orientation === "vertical" && !ancha && "h-full w-2.5 border-l border-l-transparent p-[1px]",
      orientation === "vertical" && ancha && "h-full w-[25px] border-l border-l-border/50 bg-muted/40 p-[2px]",
      // Horizontal
      orientation === "horizontal" && !ancha && "h-2.5 flex-col border-t border-t-transparent p-[1px]",
      orientation === "horizontal" && ancha && "h-[25px] flex-col border-t border-t-border/50 bg-muted/40 p-[2px]",
      className,
    )}
    {...props}
  >
    <ScrollAreaPrimitive.ScrollAreaThumb
      className={cn(
        "relative flex-1 rounded-full",
        ancha ? "bg-primary/60 hover:bg-primary/80" : "bg-border",
      )}
    />
  </ScrollAreaPrimitive.ScrollAreaScrollbar>
));
ScrollBar.displayName = ScrollAreaPrimitive.ScrollAreaScrollbar.displayName;

export { ScrollArea, ScrollBar };
