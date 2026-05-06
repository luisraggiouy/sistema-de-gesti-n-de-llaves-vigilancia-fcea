/**
 * DateInput — input de fecha con formato DD/MM/AAAA garantizado.
 *
 * Los <input type="date"> nativos muestran el formato según el idioma del
 * navegador/SO (en Windows en inglés aparece MM/DD/AAAA). Este componente
 * usa type="text" con máscara automática para garantizar DD/MM/AAAA en
 * cualquier navegador, y convierte internamente a/desde YYYY-MM-DD que es
 * el formato que espera el backend.
 *
 * Props:
 *   value    — string en formato YYYY-MM-DD (o vacío)
 *   onChange — recibe string en formato YYYY-MM-DD (o vacío)
 *   className, id, disabled — se pasan al input
 */
import { useState, useEffect, useRef } from 'react';
import { cn } from '@/lib/utils';

interface DateInputProps {
  value: string;           // YYYY-MM-DD
  onChange: (v: string) => void; // YYYY-MM-DD
  className?: string;
  id?: string;
  disabled?: boolean;
  placeholder?: string;
}

/** Convierte YYYY-MM-DD → DD/MM/AAAA para mostrar */
function isoToDisplay(iso: string): string {
  if (!iso) return '';
  const [y, m, d] = iso.split('-');
  if (!y || !m || !d) return '';
  return `${d}/${m}/${y}`;
}

/** Convierte DD/MM/AAAA → YYYY-MM-DD para guardar */
function displayToIso(display: string): string {
  const clean = display.replace(/\D/g, '');
  if (clean.length < 8) return '';
  const d = clean.slice(0, 2);
  const m = clean.slice(2, 4);
  const y = clean.slice(4, 8);
  // Validación básica
  const day = parseInt(d, 10);
  const month = parseInt(m, 10);
  const year = parseInt(y, 10);
  if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900 || year > 2100) return '';
  return `${y}-${m}-${d}`;
}

/** Aplica máscara DD/MM/AAAA mientras el usuario escribe */
function applyMask(raw: string): string {
  const digits = raw.replace(/\D/g, '').slice(0, 8);
  let result = '';
  for (let i = 0; i < digits.length; i++) {
    if (i === 2 || i === 4) result += '/';
    result += digits[i];
  }
  return result;
}

export function DateInput({ value, onChange, className, id, disabled, placeholder }: DateInputProps) {
  const [display, setDisplay] = useState(() => isoToDisplay(value));
  const prevValueRef = useRef(value);

  // Sincronizar cuando el valor externo cambia (ej: resetForm)
  useEffect(() => {
    if (value !== prevValueRef.current) {
      prevValueRef.current = value;
      setDisplay(isoToDisplay(value));
    }
  }, [value]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const masked = applyMask(e.target.value);
    setDisplay(masked);
    const iso = displayToIso(masked);
    prevValueRef.current = iso;
    onChange(iso);
  };

  return (
    <input
      id={id}
      type="text"
      inputMode="numeric"
      value={display}
      onChange={handleChange}
      disabled={disabled}
      placeholder={placeholder ?? 'DD/MM/AAAA'}
      maxLength={10}
      className={cn(
        'flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors',
        'placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring',
        'disabled:cursor-not-allowed disabled:opacity-50',
        className
      )}
    />
  );
}
