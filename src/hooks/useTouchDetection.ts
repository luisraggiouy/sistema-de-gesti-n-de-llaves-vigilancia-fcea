import { useEffect, useState } from "react";
import { getRuntimeConfig } from "@/lib/runtimeConfig";

/**
 * Detecta si la PC actual tiene una interfaz táctil disponible.
 *
 * La detección combina varias señales:
 *   - `navigator.maxTouchPoints > 0`
 *   - `window.matchMedia('(pointer: coarse)').matches` (apunta a touch o stylus
 *     como puntero principal)
 *   - El override `ui.teclado_virtual_forzado` del runtime config
 *
 * Devuelve `true` cuando el sistema debería mostrar el teclado virtual
 * automáticamente (sin requerir conexión de teclado físico).
 */
export function useTouchDetection(): boolean {
  const [isTouch, setIsTouch] = useState<boolean>(() => detectarTouch());

  useEffect(() => {
    // Re-evaluar si cambia el media query (por ejemplo, monitor externo).
    const mq = window.matchMedia("(pointer: coarse)");
    const handler = () => setIsTouch(detectarTouch());
    if (mq.addEventListener) {
      mq.addEventListener("change", handler);
      return () => mq.removeEventListener("change", handler);
    }
    // Fallback para navegadores muy viejos (no debería pasar en Chrome moderno).
    mq.addListener(handler);
    return () => mq.removeListener(handler);
  }, []);

  return isTouch;
}

function detectarTouch(): boolean {
  try {
    const cfg = getRuntimeConfig();

    // Prioridad 1: hardware explícito definido por el instalador.
    //   - "tactil"      → forzar true (es un kiosk táctil).
    //   - "tradicional" → forzar false (PC de oficina con mouse/teclado).
    //   - "desarrollo"  → false por defecto, salvo override manual abajo.
    if (cfg.hardware === "tactil") return true;
    if (cfg.hardware === "tradicional") return false;

    // Prioridad 2: override manual (útil para QA y pruebas).
    if (cfg.ui.teclado_virtual_forzado) return true;
  } catch {
    // Si runtime config aún no cargó, seguimos con la detección automática.
  }

  if (typeof window === "undefined") return false;

  const maxTouchPoints =
    (navigator as Navigator & { maxTouchPoints?: number }).maxTouchPoints ?? 0;
  if (maxTouchPoints > 0) return true;

  // pointer:coarse → puntero "grueso" (dedo / stylus). pointer:fine → mouse.
  if (window.matchMedia && window.matchMedia("(pointer: coarse)").matches) {
    return true;
  }

  return false;
}
