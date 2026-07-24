/**
 * useDepartamentosCustom
 * -----------------------------------------------------------
 * Catalogo persistente de departamentos/secciones TAS.
 *
 * Devuelve una lista MERGE entre:
 *   - La base fija definida en fceaData.departamentosTAS (26 valores).
 *   - Los departamentos "custom" que un usuario agrego alguna vez con
 *     la opcion "Otro / Agregar nuevo departamento" en el registro.
 *
 * Los custom viven en localStorage bajo la key `fcea_departamentos_custom_v1`,
 * asi que:
 *   - Sobreviven a un F5 del navegador.
 *   - Sobreviven a un RECUPERAR SISTEMA.bat (no borramos localStorage).
 *   - Sobreviven a un DESINSTALAR + INSTALAR (Windows preserva localStorage
 *     mientras no se toque el perfil de Edge/Chrome).
 *   - NO se sincronizan (todavia) entre Terminal-A y Terminal-B: cada
 *     terminal aprende sus propios custom. Es un fallback offline-first
 *     razonable para el piloto; la sync via PocketBase queda como TODO.
 *
 * API:
 *   const { departamentos, agregar, existe } = useDepartamentosCustom();
 *
 *   - departamentos: string[]  → lista final (base + custom + 'Otro' al final)
 *                                ordenada alfabeticamente, sin duplicados.
 *   - agregar(nombre):  agrega un depto custom (normaliza, deduplica).
 *   - existe(nombre):   true si ya esta en la base o en custom.
 */
import { useCallback, useEffect, useState } from 'react';
import { departamentosTAS, normalizarTexto } from '@/data/fceaData';

const LS_KEY = 'fcea_departamentos_custom_v1';

// Base sin "Otro" (para que "Otro" quede siempre al final del array final).
const DEPARTAMENTOS_BASE = departamentosTAS.filter((d) => d !== 'Otro');

/** Capitaliza cada palabra: "servicios generales" → "Servicios Generales" */
function capitalizarPalabras(texto: string): string {
  return texto
    .split(/\s+/)
    .map((p) => (p.length > 0 ? p[0].toUpperCase() + p.slice(1).toLowerCase() : ''))
    .join(' ');
}

/** Normaliza un nombre de depto: trim + colapsa espacios + Capitaliza. */
function normalizarNombre(nombre: string): string {
  const trimmed = nombre.trim().replace(/\s+/g, ' ');
  return capitalizarPalabras(trimmed);
}

function cargarCustomDesdeLS(): string[] {
  try {
    const raw = localStorage.getItem(LS_KEY);
    if (!raw) return [];
    const arr = JSON.parse(raw);
    if (!Array.isArray(arr)) return [];
    // Filtrar solo strings validos y unicos
    return arr
      .filter((x): x is string => typeof x === 'string' && x.trim().length > 0)
      .map(normalizarNombre);
  } catch {
    return [];
  }
}

function guardarCustomEnLS(custom: string[]): void {
  try {
    localStorage.setItem(LS_KEY, JSON.stringify(custom));
  } catch {
    // localStorage puede estar bloqueado (modo privado, cuota llena, etc.).
    // No es critico: el usuario simplemente no vera el depto persistido.
  }
}

/**
 * Combina base + custom, dedup case-insensitive (usando normalizarTexto que
 * quita acentos y baja a minusculas). Ordena alfabeticamente y pone "Otro"
 * al final SIEMPRE (el modal lo trata como botón especial amarillo).
 */
function combinar(base: string[], custom: string[]): string[] {
  const vistas = new Set<string>();
  const resultado: string[] = [];
  for (const nombre of [...base, ...custom]) {
    const clave = normalizarTexto(nombre);
    if (vistas.has(clave)) continue;
    vistas.add(clave);
    resultado.push(nombre);
  }
  resultado.sort((a, b) => a.localeCompare(b, 'es', { sensitivity: 'base' }));
  resultado.push('Otro'); // siempre al final
  return resultado;
}

export function useDepartamentosCustom() {
  const [custom, setCustom] = useState<string[]>(() => cargarCustomDesdeLS());

  // Escuchar cambios en localStorage desde OTRAS pestañas (ej: registro
  // simultaneo en dos ventanas de Edge en el Monitor). Es un caso borde
  // pero cuesta 3 lineas y evita divergencias.
  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key === LS_KEY) {
        setCustom(cargarCustomDesdeLS());
      }
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, []);

  const existe = useCallback(
    (nombre: string): boolean => {
      const clave = normalizarTexto(nombre.trim());
      if (!clave) return false;
      return (
        DEPARTAMENTOS_BASE.some((d) => normalizarTexto(d) === clave) ||
        custom.some((d) => normalizarTexto(d) === clave)
      );
    },
    [custom],
  );

  const agregar = useCallback(
    (nombreCrudo: string): string | null => {
      const nombre = normalizarNombre(nombreCrudo);
      if (!nombre) return null;
      const clave = normalizarTexto(nombre);
      // Si ya esta en la base O en custom (case-insensitive, sin acentos),
      // no lo agrego pero devuelvo el nombre existente para que el caller
      // lo use como valor del campo `departamento`.
      const enBase = DEPARTAMENTOS_BASE.find((d) => normalizarTexto(d) === clave);
      if (enBase) return enBase;
      const enCustom = custom.find((d) => normalizarTexto(d) === clave);
      if (enCustom) return enCustom;
      // Nuevo → persistir
      const nuevoCustom = [...custom, nombre];
      setCustom(nuevoCustom);
      guardarCustomEnLS(nuevoCustom);
      return nombre;
    },
    [custom],
  );

  const departamentos = combinar(DEPARTAMENTOS_BASE, custom);

  return { departamentos, agregar, existe };
}
