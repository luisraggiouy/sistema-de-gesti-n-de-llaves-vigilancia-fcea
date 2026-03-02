import { useState, useCallback, useRef, useEffect } from 'react';

const SONIDO_STORAGE_KEY = 'fcea_sonido_config';

export interface SonidoConfig {
  volumen: number; // 0-1
  muted: boolean;
}

const DEFAULT_CONFIG: SonidoConfig = {
  volumen: 0.5,
  muted: false,
};

// Frecuencias base para generar sonidos únicos por vigilante
const FRECUENCIAS_VIGILANTE = [
  523.25, // C5
  587.33, // D5
  659.25, // E5
  698.46, // F5
  783.99, // G5
  880.00, // A5
  987.77, // B5
  1046.50, // C6
  554.37, // C#5
  622.25, // D#5
  739.99, // F#5
  830.61, // G#5
  932.33, // A#5
  493.88, // B4
  440.00, // A4
  415.30, // G#4
];

function crearContextoAudio(): AudioContext | null {
  try {
    return new (window.AudioContext || (window as any).webkitAudioContext)();
  } catch {
    return null;
  }
}

// Sonido de campana/ding suave
function reproducirCampana(ctx: AudioContext, frecuencia: number, volumen: number, duracion = 0.8) {
  const now = ctx.currentTime;

  // Oscilador principal
  const osc = ctx.createOscillator();
  osc.type = 'sine';
  osc.frequency.setValueAtTime(frecuencia, now);
  osc.frequency.exponentialRampToValueAtTime(frecuencia * 0.98, now + duracion);

  // Armónico (para que suene a campana)
  const osc2 = ctx.createOscillator();
  osc2.type = 'sine';
  osc2.frequency.setValueAtTime(frecuencia * 2.5, now);

  // Envolvente principal
  const gainNode = ctx.createGain();
  gainNode.gain.setValueAtTime(0, now);
  gainNode.gain.linearRampToValueAtTime(volumen * 0.4, now + 0.01);
  gainNode.gain.exponentialRampToValueAtTime(0.001, now + duracion);

  // Envolvente armónico (decae más rápido)
  const gainNode2 = ctx.createGain();
  gainNode2.gain.setValueAtTime(0, now);
  gainNode2.gain.linearRampToValueAtTime(volumen * 0.15, now + 0.005);
  gainNode2.gain.exponentialRampToValueAtTime(0.001, now + duracion * 0.4);

  osc.connect(gainNode);
  osc2.connect(gainNode2);
  gainNode.connect(ctx.destination);
  gainNode2.connect(ctx.destination);

  osc.start(now);
  osc2.start(now);
  osc.stop(now + duracion);
  osc2.stop(now + duracion);
}

// Sonido de nueva solicitud (doble ding ascendente)
function reproducirNuevaSolicitud(ctx: AudioContext, volumen: number) {
  reproducirCampana(ctx, 659.25, volumen, 0.4); // E5
  setTimeout(() => {
    reproducirCampana(ctx, 880.00, volumen, 0.6); // A5
  }, 200);
}

// Sonido de entrega (ding descendente suave)  
function reproducirEntrega(ctx: AudioContext, frecuenciaBase: number, volumen: number) {
  reproducirCampana(ctx, frecuenciaBase * 1.5, volumen, 0.3);
  setTimeout(() => {
    reproducirCampana(ctx, frecuenciaBase, volumen, 0.5);
  }, 150);
}

// Sonido de devolución (triple ding ascendente)
function reproducirDevolucion(ctx: AudioContext, frecuenciaBase: number, volumen: number) {
  reproducirCampana(ctx, frecuenciaBase, volumen, 0.25);
  setTimeout(() => {
    reproducirCampana(ctx, frecuenciaBase * 1.25, volumen, 0.25);
  }, 120);
  setTimeout(() => {
    reproducirCampana(ctx, frecuenciaBase * 1.5, volumen, 0.5);
  }, 240);
}

export function useSonidos() {
  const [config, setConfig] = useState<SonidoConfig>(() => {
    try {
      const stored = localStorage.getItem(SONIDO_STORAGE_KEY);
      return stored ? { ...DEFAULT_CONFIG, ...JSON.parse(stored) } : DEFAULT_CONFIG;
    } catch {
      return DEFAULT_CONFIG;
    }
  });

  const audioCtxRef = useRef<AudioContext | null>(null);

  // Inicializar AudioContext en primera interacción
  const ensureAudioContext = useCallback(() => {
    if (!audioCtxRef.current) {
      audioCtxRef.current = crearContextoAudio();
    }
    if (audioCtxRef.current?.state === 'suspended') {
      audioCtxRef.current.resume();
    }
    return audioCtxRef.current;
  }, []);

  const guardarConfig = useCallback((newConfig: SonidoConfig) => {
    setConfig(newConfig);
    localStorage.setItem(SONIDO_STORAGE_KEY, JSON.stringify(newConfig));
  }, []);

  const setVolumen = useCallback((volumen: number) => {
    guardarConfig({ ...config, volumen: Math.max(0, Math.min(1, volumen)) });
  }, [config, guardarConfig]);

  const toggleMute = useCallback(() => {
    guardarConfig({ ...config, muted: !config.muted });
  }, [config, guardarConfig]);

  const getVolumenEfectivo = useCallback(() => {
    return config.muted ? 0 : config.volumen;
  }, [config]);

  // Obtener frecuencia única para un vigilante basándose en su índice
  const getFrecuenciaVigilante = useCallback((vigilanteNombre: string): number => {
    let hash = 0;
    for (let i = 0; i < vigilanteNombre.length; i++) {
      hash = ((hash << 5) - hash) + vigilanteNombre.charCodeAt(i);
      hash |= 0;
    }
    const index = Math.abs(hash) % FRECUENCIAS_VIGILANTE.length;
    return FRECUENCIAS_VIGILANTE[index];
  }, []);

  const sonarNuevaSolicitud = useCallback(() => {
    const vol = getVolumenEfectivo();
    if (vol === 0) return;
    const ctx = ensureAudioContext();
    if (!ctx) return;
    reproducirNuevaSolicitud(ctx, vol);
  }, [getVolumenEfectivo, ensureAudioContext]);

  const sonarEntrega = useCallback((vigilanteNombre: string) => {
    const vol = getVolumenEfectivo();
    if (vol === 0) return;
    const ctx = ensureAudioContext();
    if (!ctx) return;
    const freq = getFrecuenciaVigilante(vigilanteNombre);
    reproducirEntrega(ctx, freq, vol);
  }, [getVolumenEfectivo, ensureAudioContext, getFrecuenciaVigilante]);

  const sonarDevolucion = useCallback((vigilanteNombre: string) => {
    const vol = getVolumenEfectivo();
    if (vol === 0) return;
    const ctx = ensureAudioContext();
    if (!ctx) return;
    const freq = getFrecuenciaVigilante(vigilanteNombre);
    reproducirDevolucion(ctx, freq, vol);
  }, [getVolumenEfectivo, ensureAudioContext, getFrecuenciaVigilante]);

  // Sonido de prueba
  const sonarPrueba = useCallback(() => {
    const ctx = ensureAudioContext();
    if (!ctx) return;
    const vol = config.muted ? 0.3 : config.volumen; // Incluso si está muted, prueba suena
    reproducirCampana(ctx, 783.99, vol, 0.6);
  }, [ensureAudioContext, config]);

  return {
    config,
    setVolumen,
    toggleMute,
    sonarNuevaSolicitud,
    sonarEntrega,
    sonarDevolucion,
    sonarPrueba,
  };
}
