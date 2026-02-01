// Configuración del sistema de vigilancia

export interface ConfiguracionSistema {
  tiempoAlertaMinutos: number; // Por defecto 135 (2h 15min)
  mensajeWhatsApp: string;
  transicionTurnoMinutos: number; // Por defecto 30 minutos
}

export const CONFIGURACION_DEFAULT: ConfiguracionSistema = {
  tiempoAlertaMinutos: 135, // 2 horas 15 minutos
  mensajeWhatsApp: 'Lo saludamos desde vigilancia de FCEA, tenemos en registro que usted tiene la llave de {{LLAVE}} le agradecemos si la pueda devolver a la cabina de vigilancia, muchas gracias y saludos cordiales.',
  transicionTurnoMinutos: 30
};

// Storage key para persistir configuración
export const CONFIG_STORAGE_KEY = 'fcea_configuracion_sistema';

// Storage key para vigilantes personalizados
export const VIGILANTES_STORAGE_KEY = 'fcea_vigilantes_personalizados';
