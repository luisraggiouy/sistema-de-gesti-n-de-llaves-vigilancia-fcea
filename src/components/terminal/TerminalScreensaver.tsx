import { useEffect, useState, useCallback, useRef } from "react";
import { Hand } from "lucide-react";
import { useTouchUX } from "@/hooks/useTouchUX";

/**
 * Overlay a pantalla completa que se muestra en la Terminal cuando
 * la PC lleva N segundos sin interacción del usuario.
 *
 * Propósito:
 *   1. Impedir que el monitor entre en DPMS-off (apagado por energía).
 *      Como pintamos pixels a pantalla completa con animación suave,
 *      Windows / el monitor ven actividad y no cortan la señal.
 *   2. Dar una pista visual inmediata al próximo usuario: cartel gigante
 *      "TOQUE LA PANTALLA PARA SOLICITAR SU/S LLAVES" con animación de
 *      latido. Elimina el escenario "el monitor está apagado y el usuario
 *      no sabe cómo prenderlo".
 *   3. Al tocar cualquier lado, el overlay se cierra y la Terminal
 *      queda lista para operar.
 *
 * Se activa solo cuando `useTouchUX().screensaverActivo` es true
 * (default: `hardware === "tactil"`).
 */
export function TerminalScreensaver() {
  const { screensaverActivo, screensaverDelayMs, screensaverTexto } =
    useTouchUX();
  const [visible, setVisible] = useState(false);
  const timerRef = useRef<number | null>(null);

  const resetTimer = useCallback(() => {
    if (!screensaverActivo) return;
    if (timerRef.current !== null) {
      window.clearTimeout(timerRef.current);
    }
    timerRef.current = window.setTimeout(() => {
      setVisible(true);
    }, screensaverDelayMs);
  }, [screensaverActivo, screensaverDelayMs]);

  const ocultar = useCallback(() => {
    setVisible(false);
    resetTimer();
  }, [resetTimer]);

  useEffect(() => {
    if (!screensaverActivo) {
      setVisible(false);
      return;
    }
    resetTimer();

    const eventos: (keyof WindowEventMap)[] = [
      "mousemove",
      "mousedown",
      "keydown",
      "touchstart",
      "wheel",
    ];
    const handleActividad = () => {
      if (visible) return; // Si está visible, dejo que el usuario lo cierre con click.
      resetTimer();
    };
    eventos.forEach((ev) =>
      window.addEventListener(ev, handleActividad, { passive: true }),
    );

    return () => {
      eventos.forEach((ev) =>
        window.removeEventListener(ev, handleActividad),
      );
      if (timerRef.current !== null) {
        window.clearTimeout(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [screensaverActivo, resetTimer, visible]);

  if (!screensaverActivo || !visible) return null;

  return (
    <div
      role="button"
      aria-label="Toque la pantalla para comenzar"
      onClick={ocultar}
      onTouchStart={ocultar}
      className="fixed inset-0 z-[9999] flex flex-col items-center justify-center cursor-pointer select-none"
      style={{
        // Gradiente institucional FCEA sobre fondo primario.
        background:
          "linear-gradient(135deg, hsl(var(--primary)) 0%, hsl(210 85% 25%) 100%)",
        color: "hsl(var(--primary-foreground))",
      }}
    >
      {/* Icono grande de mano con animación */}
      <div className="animate-screensaver-pulse flex flex-col items-center gap-8 px-6 text-center">
        <Hand
          className="w-40 h-40 sm:w-56 sm:h-56 drop-shadow-lg"
          strokeWidth={1.5}
          aria-hidden
        />
        <div className="max-w-3xl">
          <p className="text-3xl sm:text-5xl md:text-6xl font-bold leading-tight tracking-wide drop-shadow-md">
            {screensaverTexto}
          </p>
        </div>
      </div>

      {/* Pie discreto */}
      <div className="absolute bottom-6 text-center opacity-80">
        <p className="text-sm sm:text-base">
          Sistema de Gestión de Llaves — Sección Vigilancia FCEA
        </p>
      </div>
    </div>
  );
}
