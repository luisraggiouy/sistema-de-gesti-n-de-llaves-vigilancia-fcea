import { useCallback, useMemo, useRef, useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { VirtualKeyboard } from "@/components/ui/virtual-keyboard";
import { useTouchDetection } from "@/hooks/useTouchDetection";
import { cn } from "@/lib/utils";

/**
 * Input controlado que muestra automáticamente un teclado virtual cuando:
 *   - El dispositivo es táctil (detectado por `useTouchDetection`), o
 *   - `config.json` tiene `ui.teclado_virtual_forzado: true`.
 *
 * Acepta una `sugerencias` (lista completa de candidatos) y filtra
 * predicciones por prefijo / substring case-insensitive sin acentos.
 */

export interface TouchInputProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, "onChange" | "value"> {
  value: string;
  onChange: (newValue: string) => void;
  /** Lista completa de strings desde donde se derivan predicciones. */
  sugerencias?: string[];
  /** Máximo de predicciones a mostrar. Default 6. */
  maxPredicciones?: number;
  /** Permite forzar la apertura del teclado. */
  forzarTeclado?: boolean;
  /** Submit (Enter). */
  onSubmit?: () => void;
  /** Texto adicional para mostrar arriba del teclado. */
  wrapperClassName?: string;
}

/** Normaliza un string: minúsculas + sin acentos. */
function normalizar(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

export function TouchInput({
  value,
  onChange,
  sugerencias = [],
  maxPredicciones = 6,
  forzarTeclado = false,
  onSubmit,
  wrapperClassName,
  className,
  onFocus,
  onBlur,
  ...inputProps
}: TouchInputProps) {
  const esTouch = useTouchDetection();
  const debeMostrarTeclado = forzarTeclado || esTouch;

  const [tieneFoco, setTieneFoco] = useState(false);
  const [tecladoVisible, setTecladoVisible] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  // El teclado se abre al hacer foco; se oculta al perder foco fuera de él.
  useEffect(() => {
    if (debeMostrarTeclado && tieneFoco) {
      setTecladoVisible(true);
    }
  }, [debeMostrarTeclado, tieneFoco]);

  // Calcular predicciones por prefijo + substring.
  const predicciones = useMemo<string[]>(() => {
    if (!debeMostrarTeclado || !value.trim() || sugerencias.length === 0) {
      return [];
    }
    const q = normalizar(value);
    const prefix: string[] = [];
    const substr: string[] = [];
    for (const s of sugerencias) {
      const n = normalizar(s);
      if (n === q) continue;
      if (n.startsWith(q)) {
        prefix.push(s);
      } else if (n.includes(q)) {
        substr.push(s);
      }
      if (prefix.length >= maxPredicciones) break;
    }
    return [...prefix, ...substr].slice(0, maxPredicciones);
  }, [value, sugerencias, debeMostrarTeclado, maxPredicciones]);

  const handleKey = useCallback(
    (char: string) => {
      onChange(value + char);
    },
    [onChange, value],
  );

  const handleBackspace = useCallback(() => {
    onChange(value.slice(0, -1));
  }, [onChange, value]);

  const handleSuggestion = useCallback(
    (s: string) => {
      onChange(s);
    },
    [onChange],
  );

  return (
    <div className={cn("flex flex-col gap-2", wrapperClassName)}>
      <Input
        {...inputProps}
        ref={inputRef}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onFocus={(e) => {
          setTieneFoco(true);
          onFocus?.(e);
        }}
        onBlur={(e) => {
          setTieneFoco(false);
          onBlur?.(e);
        }}
        onKeyDown={(e) => {
          if (e.key === "Enter" && onSubmit) {
            e.preventDefault();
            onSubmit();
          }
        }}
        // En modo táctil, no queremos que se abra el teclado nativo del SO
        // sobre el teclado virtual del sistema. Lo logramos con readOnly
        // condicional + dejar focus manual.
        readOnly={debeMostrarTeclado}
        className={className}
        autoComplete="off"
      />

      {debeMostrarTeclado && tecladoVisible && (
        <VirtualKeyboard
          value={value}
          predicciones={predicciones}
          onKey={handleKey}
          onBackspace={handleBackspace}
          onSuggestion={handleSuggestion}
          onSubmit={onSubmit}
          onClose={() => {
            setTecladoVisible(false);
            inputRef.current?.blur();
          }}
        />
      )}
    </div>
  );
}
