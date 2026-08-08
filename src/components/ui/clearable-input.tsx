import * as React from "react";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

/**
 * ClearableInput / ClearableTextarea
 * (Upgrade 2026-08-08) Campos de texto de carga manual con un boton "X"
 * a la derecha que borra TODO el texto de un solo click, ademas del
 * backspace habitual (que sigue borrando letra por letra).
 *
 * Diseño de bajo riesgo:
 *  - Envuelve al <Input>/<Textarea> base SIN modificarlos, por lo que el
 *    resto del sistema (buscadores, etc.) queda intacto.
 *  - La "X" solo aparece cuando hay texto y el campo no esta deshabilitado.
 *  - Al hacer click llama a `onClear` (que normalmente hace setX('')).
 *    Si no se pasa `onClear` pero hay `onChange`, dispara un onChange
 *    sintetico con value = '' para inputs controlados.
 */

export interface ClearableInputProps extends React.ComponentProps<"input"> {
  onClear?: () => void;
}

function buildValue(value: React.ComponentProps<"input">["value"]): string {
  if (value === undefined || value === null) return "";
  return String(value);
}

const ClearableInput = React.forwardRef<HTMLInputElement, ClearableInputProps>(
  ({ className, onClear, onChange, value, disabled, ...props }, ref) => {
    const hasValue = buildValue(value).length > 0;

    const handleClear = () => {
      if (onClear) {
        onClear();
      } else if (onChange) {
        // Fallback: onChange sintetico con value vacio (input controlado).
        const fakeEvent = {
          target: { value: "" },
          currentTarget: { value: "" },
        } as unknown as React.ChangeEvent<HTMLInputElement>;
        onChange(fakeEvent);
      }
    };

    return (
      <div className="relative w-full">
        <Input
          ref={ref}
          value={value}
          onChange={onChange}
          disabled={disabled}
          className={cn(hasValue && "pr-9", className)}
          {...props}
        />
        {hasValue && !disabled && (
          <button
            type="button"
            tabIndex={-1}
            aria-label="Borrar todo el texto"
            title="Borrar todo"
            onClick={handleClear}
            className="absolute right-1 top-1/2 -translate-y-1/2 inline-flex h-7 w-7 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground focus:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>
    );
  },
);
ClearableInput.displayName = "ClearableInput";

export interface ClearableTextareaProps
  extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  onClear?: () => void;
}

const ClearableTextarea = React.forwardRef<
  HTMLTextAreaElement,
  ClearableTextareaProps
>(({ className, onClear, onChange, value, disabled, ...props }, ref) => {
  const hasValue = buildValue(value as string).length > 0;

  const handleClear = () => {
    if (onClear) {
      onClear();
    } else if (onChange) {
      const fakeEvent = {
        target: { value: "" },
        currentTarget: { value: "" },
      } as unknown as React.ChangeEvent<HTMLTextAreaElement>;
      onChange(fakeEvent);
    }
  };

  return (
    <div className="relative w-full">
      <Textarea
        ref={ref}
        value={value}
        onChange={onChange}
        disabled={disabled}
        className={cn(hasValue && "pr-9", className)}
        {...props}
      />
      {hasValue && !disabled && (
        <button
          type="button"
          tabIndex={-1}
          aria-label="Borrar todo el texto"
          title="Borrar todo"
          onClick={handleClear}
          className="absolute right-1 top-1.5 inline-flex h-7 w-7 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground focus:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <X className="h-4 w-4" />
        </button>
      )}
    </div>
  );
});
ClearableTextarea.displayName = "ClearableTextarea";

export { ClearableInput, ClearableTextarea };
