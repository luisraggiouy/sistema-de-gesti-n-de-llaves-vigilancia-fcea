/**
 * DateInput — input de fecha con formato DD/MM/AAAA garantizado + picker de calendario.
 *
 * - El campo de texto acepta escritura manual con máscara DD/MM/AAAA
 * - El ícono de calendario abre un Popover con el componente Calendar de shadcn/ui
 * - Al seleccionar una fecha en el calendario, se completa el campo automáticamente
 * - Siempre trabaja con YYYY-MM-DD internamente (compatible con el backend)
 */
import { useState, useEffect, useRef } from 'react';
import { CalendarIcon } from 'lucide-react';
import { format, parse, isValid } from 'date-fns';
import { es } from 'date-fns/locale';
import { cn } from '@/lib/utils';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Button } from '@/components/ui/button';

interface DateInputProps {
  value: string;                   // YYYY-MM-DD
  onChange: (v: string) => void;   // YYYY-MM-DD
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

/** Convierte YYYY-MM-DD → Date object (o undefined) */
function isoToDate(iso: string): Date | undefined {
  if (!iso) return undefined;
  const d = new Date(iso + 'T12:00:00');
  return isValid(d) ? d : undefined;
}

export function DateInput({ value, onChange, className, id, disabled, placeholder }: DateInputProps) {
  const [display, setDisplay] = useState(() => isoToDisplay(value));
  const [open, setOpen] = useState(false);
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

  const handleCalendarSelect = (date: Date | undefined) => {
    if (!date) return;
    const iso = format(date, 'yyyy-MM-dd');
    prevValueRef.current = iso;
    setDisplay(isoToDisplay(iso));
    onChange(iso);
    setOpen(false);
  };

  const selectedDate = isoToDate(value);

  return (
    <div className="relative w-full">
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
          'flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 pr-9 text-sm shadow-sm transition-colors',
          'placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring',
          'disabled:cursor-not-allowed disabled:opacity-50',
          className
        )}
      />
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <button
            type="button"
            disabled={disabled}
            className="absolute right-2 top-1/2 -translate-y-1/2 p-0.5 rounded text-muted-foreground hover:text-foreground hover:bg-accent transition-colors disabled:pointer-events-none disabled:opacity-50"
            tabIndex={-1}
            aria-label="Abrir calendario"
          >
            <CalendarIcon className="w-4 h-4" />
          </button>
        </PopoverTrigger>
        <PopoverContent className="w-auto p-0" align="end">
          <Calendar
            mode="single"
            selected={selectedDate}
            onSelect={handleCalendarSelect}
            defaultMonth={selectedDate}
            locale={es}
            initialFocus
          />
        </PopoverContent>
      </Popover>
    </div>
  );
}
