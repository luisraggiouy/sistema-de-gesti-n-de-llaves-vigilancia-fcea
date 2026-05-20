import { useState, useCallback, useMemo } from "react";
import { Button } from "@/components/ui/button";
import { Delete, ArrowUp, Space, X } from "lucide-react";
import { cn } from "@/lib/utils";

/**
 * Teclado virtual en pantalla (QWERTY-ES) para monitores táctiles.
 *
 * - Sin dependencias externas: render puro, teclas grandes (≥ 44px tap target).
 * - Soporta mayúsculas, minúsculas, números y símbolos comunes.
 * - Inserta texto a través del callback `onKey`/`onBackspace`/`onSubmit` para
 *   que el componente padre controle el estado del input (controlled).
 * - Acepta una lista opcional de `predicciones` que se renderizan en una
 *   barra superior; al tocar una predicción se llama a `onSuggestion`.
 */

export interface VirtualKeyboardProps {
  /** Texto actual del input (solo para mostrar predicciones contextuales). */
  value?: string;
  /** Predicciones a mostrar como chips arriba del teclado. */
  predicciones?: string[];
  /** Inserción de un carácter (string de 1+ chars). */
  onKey: (char: string) => void;
  /** Borrar último carácter. */
  onBackspace: () => void;
  /** Enter / submit. */
  onSubmit?: () => void;
  /** Cuando el usuario toca una predicción. */
  onSuggestion?: (sugerencia: string) => void;
  /** Cerrar / minimizar el teclado. */
  onClose?: () => void;
  /** Layout reducido (sin fila de números). */
  compacto?: boolean;
  className?: string;
}

type Modo = "minuscula" | "mayuscula" | "simbolos";

const FILAS_LETRAS_ES: string[][] = [
  ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
  ["a", "s", "d", "f", "g", "h", "j", "k", "l", "ñ"],
  ["z", "x", "c", "v", "b", "n", "m"],
];

const FILA_NUMEROS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"];

const FILAS_SIMBOLOS: string[][] = [
  ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
  ["@", "#", "$", "%", "&", "-", "_", "+", "(", ")"],
  [".", ",", ";", ":", "/", "?", "!", "'"],
];

export function VirtualKeyboard({
  predicciones = [],
  onKey,
  onBackspace,
  onSubmit,
  onSuggestion,
  onClose,
  compacto = false,
  className,
}: VirtualKeyboardProps) {
  const [modo, setModo] = useState<Modo>("minuscula");

  const filas = useMemo<string[][]>(() => {
    if (modo === "simbolos") return FILAS_SIMBOLOS;
    const letras =
      modo === "mayuscula"
        ? FILAS_LETRAS_ES.map((row) => row.map((c) => c.toUpperCase()))
        : FILAS_LETRAS_ES;
    return compacto ? letras : [FILA_NUMEROS, ...letras];
  }, [modo, compacto]);

  const handleKey = useCallback(
    (char: string) => {
      onKey(char);
      // Auto-volver a minúscula después de una mayúscula (comportamiento shift-temporal).
      if (modo === "mayuscula") setModo("minuscula");
    },
    [onKey, modo],
  );

  return (
    <div
      className={cn(
        "rounded-lg border bg-card shadow-lg p-2 sm:p-3 select-none",
        "w-full max-w-3xl mx-auto",
        className,
      )}
      // Evita perder el foco del input al tocar el teclado.
      onMouseDown={(e) => e.preventDefault()}
      onTouchStart={(e) => {
        // Solo prevenir si el target NO es un input editable
        const target = e.target as HTMLElement;
        if (target.tagName !== "INPUT" && target.tagName !== "TEXTAREA") {
          e.preventDefault();
        }
      }}
      role="application"
      aria-label="Teclado virtual"
    >
      {/* Barra de predicciones */}
      {predicciones.length > 0 && (
        <div className="flex gap-2 overflow-x-auto pb-2 mb-2 border-b">
          {predicciones.slice(0, 6).map((p, i) => (
            <Button
              key={`${p}-${i}`}
              type="button"
              variant="secondary"
              size="sm"
              className="shrink-0 text-sm"
              onClick={() => onSuggestion?.(p)}
            >
              {p}
            </Button>
          ))}
        </div>
      )}

      {/* Filas de teclas */}
      <div className="flex flex-col gap-1.5">
        {filas.map((fila, idx) => (
          <div key={idx} className="flex gap-1.5 justify-center">
            {fila.map((char) => (
              <button
                key={char}
                type="button"
                onClick={() => handleKey(char)}
                className={cn(
                  "min-w-[2.5rem] sm:min-w-[2.75rem] h-11 sm:h-12 px-2",
                  "rounded-md border bg-background hover:bg-accent active:bg-accent/80",
                  "text-base sm:text-lg font-medium transition-colors",
                  "flex items-center justify-center",
                )}
              >
                {char}
              </button>
            ))}
          </div>
        ))}

        {/* Fila inferior: shift, espacio, backspace, enter, cerrar */}
        <div className="flex gap-1.5 justify-center mt-1">
          <button
            type="button"
            onClick={() =>
              setModo(modo === "mayuscula" ? "minuscula" : "mayuscula")
            }
            className={cn(
              "h-11 sm:h-12 px-3 rounded-md border text-sm font-medium",
              "flex items-center gap-1 transition-colors",
              modo === "mayuscula"
                ? "bg-primary text-primary-foreground"
                : "bg-background hover:bg-accent",
            )}
            aria-label="Mayúsculas"
          >
            <ArrowUp className="w-4 h-4" />
          </button>

          <button
            type="button"
            onClick={() =>
              setModo(modo === "simbolos" ? "minuscula" : "simbolos")
            }
            className={cn(
              "h-11 sm:h-12 px-3 rounded-md border text-sm font-medium",
              "transition-colors",
              modo === "simbolos"
                ? "bg-primary text-primary-foreground"
                : "bg-background hover:bg-accent",
            )}
          >
            123
          </button>

          <button
            type="button"
            onClick={() => handleKey(" ")}
            className="h-11 sm:h-12 flex-1 max-w-md rounded-md border bg-background hover:bg-accent active:bg-accent/80 flex items-center justify-center transition-colors"
            aria-label="Espacio"
          >
            <Space className="w-5 h-5" />
          </button>

          <button
            type="button"
            onClick={onBackspace}
            className="h-11 sm:h-12 px-3 rounded-md border bg-background hover:bg-destructive/10 active:bg-destructive/20 flex items-center transition-colors"
            aria-label="Borrar"
          >
            <Delete className="w-5 h-5" />
          </button>

          {onSubmit && (
            <button
              type="button"
              onClick={onSubmit}
              className="h-11 sm:h-12 px-4 rounded-md bg-primary text-primary-foreground hover:bg-primary/90 text-sm font-semibold transition-colors"
            >
              Entrar
            </button>
          )}

          {onClose && (
            <button
              type="button"
              onClick={onClose}
              className="h-11 sm:h-12 px-3 rounded-md border bg-background hover:bg-accent flex items-center transition-colors"
              aria-label="Cerrar teclado"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
