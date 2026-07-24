import { useEffect, useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { AlertTriangle, Trash2, Pencil } from "lucide-react";

/**
 * Modal de confirmacion para acciones destructivas o de edicion
 * sensible del sistema.
 *
 * v2.8 (2026-07-23): se agrega a raiz del incidente del piloto donde
 * el vigilante borro por error una llave activa. Se usa en acciones
 * sobre: LLAVES, VIGILANTES, AGENDA, AUTORIZACIONES, HISTORIAL, tanto
 * al EDITAR como al BORRAR.
 *
 * v2.8.1 (2026-07-23 tarde): se simplifica a DOS BOTONES GRANDES en
 * lugar de pedir tipear "CONFIRMAR". El objetivo sigue siendo el
 * mismo (evitar borrado con un solo click), pero mas rapido para
 * un monitor tactil: "Cancelar" (grande, gris) o "Si, BORRAR"
 * (grande, rojo). Ambos botones estan lo suficientemente separados
 * y son lo suficientemente distintos como para que no sea un
 * accidente.
 *
 * Layout:
 *   ┌─────────────────────────────────────────────┐
 *   │ ⚠  ATENCION — Accion sensible               │
 *   ├─────────────────────────────────────────────┤
 *   │ Vas a BORRAR la llave "Salon 12".           │
 *   │                                              │
 *   │ Esta accion NO se puede deshacer desde la   │
 *   │ interfaz. Los registros historicos que      │
 *   │ referencian esta llave pueden quedar        │
 *   │ inconsistentes.                             │
 *   ├─────────────────────────────────────────────┤
 *   │  [  Cancelar  ]         [ 🗑  SI, BORRAR ]  │
 *   └─────────────────────────────────────────────┘
 */
export type TipoAccionSensible = "editar" | "borrar";

export type EntidadSensible =
  | "llave"
  | "vigilante"
  | "agenda"
  | "autorizacion"
  | "historial"
  | "otro";

export interface ConfirmarAccionSensibleProps {
  /** Si el modal esta visible. */
  open: boolean;
  /** Handler para cerrar el modal (cancelar o confirmar exitoso). */
  onOpenChange: (open: boolean) => void;
  /** "editar" u "borrar". Define color y verbo del boton primario. */
  tipoAccion: TipoAccionSensible;
  /** Entidad que se manipula (llave/vigilante/agenda/...). Cambia el
      texto del banner y el icono. */
  entidad: EntidadSensible;
  /** Descripcion corta del objeto concreto (ej: 'Salon 12',
      'Juan Perez', 'Autorizacion #42'). Se muestra entrecomillado. */
  detalle?: string;
  /** Mensaje adicional debajo del banner. Puede tener saltos de linea.
      Se recomienda explicar las consecuencias (ej. "Los registros
      historicos que referencian esta llave pueden quedar
      inconsistentes."). */
  descripcionExtra?: string;
  /** Callback que se ejecuta cuando el usuario toca el boton rojo.
      Puede ser async. Mientras corre, los botones se deshabilitan
      y muestran "Procesando..." */
  onConfirmar: () => void | Promise<void>;
  /** Compat con la version 2.8.0 que exigia tipear una frase. Se
      ignora: el modal ahora es doble-boton. Se mantiene el prop
      para no romper los callers. */
  fraseRequerida?: string;
}

const NOMBRE_ENTIDAD: Record<EntidadSensible, string> = {
  llave: "la llave",
  vigilante: "el vigilante",
  agenda: "el registro de agenda",
  autorizacion: "la autorizacion",
  historial: "el registro del historial",
  otro: "el registro",
};

export function ConfirmarAccionSensible({
  open,
  onOpenChange,
  tipoAccion,
  entidad,
  detalle,
  descripcionExtra,
  onConfirmar,
}: ConfirmarAccionSensibleProps) {
  const [procesando, setProcesando] = useState(false);

  // Reset del estado cada vez que se abre.
  useEffect(() => {
    if (open) {
      setProcesando(false);
    }
  }, [open]);

  const esBorrar = tipoAccion === "borrar";
  const nombreEnt = NOMBRE_ENTIDAD[entidad];

  const verboTitulo = esBorrar ? "BORRAR" : "EDITAR";
  const verboBoton = esBorrar ? "Si, BORRAR" : "Si, aplicar cambios";
  const Icono = esBorrar ? Trash2 : Pencil;

  // Mensaje principal: se arma segun accion + entidad + detalle.
  // Ej: "Vas a BORRAR la llave \"Salon 12\"."
  const mensajePrincipal =
    `Vas a ${verboTitulo} ${nombreEnt}` +
    (detalle ? ` "${detalle}"` : "") +
    ".";

  // Consecuencias por defecto segun accion + entidad. El caller puede
  // sobreescribir con `descripcionExtra` si quiere algo mas especifico.
  const consecuenciasDefault = esBorrar
    ? "Esta accion NO se puede deshacer desde la interfaz. Si hay registros historicos que referencian este item, pueden quedar inconsistentes."
    : "Los cambios se aplican inmediatamente sobre datos vivos del sistema. Verifica que los datos nuevos sean correctos antes de continuar.";

  const handleConfirmar = async () => {
    if (procesando) return;
    try {
      setProcesando(true);
      await Promise.resolve(onConfirmar());
      onOpenChange(false);
    } finally {
      setProcesando(false);
    }
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        // Mientras procesamos, no permitir cerrar por click afuera.
        if (procesando && !v) return;
        onOpenChange(v);
      }}
    >
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle
            className={
              "flex items-center gap-2 text-lg " +
              (esBorrar ? "text-destructive" : "text-amber-700")
            }
          >
            <AlertTriangle className="w-6 h-6" />
            ATENCION — Accion sensible
          </DialogTitle>
          <DialogDescription className="text-foreground text-base pt-2">
            <span className="font-semibold">{mensajePrincipal}</span>
          </DialogDescription>
        </DialogHeader>

        <div
          className={
            "rounded-md border p-4 text-sm leading-relaxed " +
            (esBorrar
              ? "border-destructive/40 bg-destructive/5 text-destructive"
              : "border-amber-400/50 bg-amber-50 text-amber-900")
          }
        >
          {descripcionExtra || consecuenciasDefault}
        </div>

        {/*
          v2.8.2 (2026-07-24): banner de autorizacion + trazabilidad.
          Requerido explicitamente por la usuaria: TODOS los modales de
          accion sensible (borrar/editar llave, vigilante, agenda,
          autorizacion, historial) deben mostrar exactamente este texto.
          Es una politica del sistema, no una descripcion opcional; por
          eso vive dentro del propio componente y NO en cada caller.
        */}
        <div
          className="rounded-md border border-amber-500/60 bg-amber-100/70 p-3 text-sm text-amber-900 font-medium"
          role="note"
          aria-label="Aviso de autorizacion"
        >
          Para realizar este cambio se necesita autorización de jefaturas,
          quedará registro en el sistema de esta acción.
        </div>


        {/*
          Layout de botones optimizado para monitor tactil:
            - Ambos botones ocupan ancho completo en fila.
            - "Cancelar" a la izquierda (el que suele apretar el que
              se arrepintio) es amplio y neutro.
            - "Si, BORRAR" a la derecha, rojo, con icono. Requiere
              un toque deliberado en el lado opuesto -> no es un
              accidente.
            - Ambos son h-12 (48px) que es el minimo tocable comodo
              con dedo.
        */}
        <DialogFooter className="gap-3 sm:gap-3 flex-col sm:flex-row pt-2">
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={procesando}
            className="h-12 text-base flex-1"
          >
            Cancelar
          </Button>
          <Button
            variant={esBorrar ? "destructive" : "default"}
            onClick={handleConfirmar}
            disabled={procesando}
            className="h-12 text-base flex-1 gap-2 font-semibold"
          >
            <Icono className="w-5 h-5" />
            {procesando ? "Procesando..." : verboBoton}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
