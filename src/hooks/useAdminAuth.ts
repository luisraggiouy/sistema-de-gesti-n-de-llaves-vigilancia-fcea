import { useState, useEffect, useCallback } from 'react';
import pb from '@/lib/pocketbase';
import { useToast } from '@/hooks/use-toast';

interface AdminAuthState {
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

const DEFAULT_CUSTODIAN_PASSWORD = 'custodio2026'; // Contraseña compartida por defecto
const SESSION_DURATION = 5 * 60 * 1000; // 5 minutos en milisegundos
const PASSWORD_STORAGE_KEY = 'admin_custodian_password'; // clave localStorage para la contraseña

export function useAdminAuth() {
  const [authState, setAuthState] = useState<AdminAuthState>({
    isAuthenticated: false,
    isLoading: true,
    error: null,
  });
  const { toast } = useToast();

  // Verificar si hay una sesión activa al cargar
  useEffect(() => {
    checkExistingSession();
  }, []);

  const checkExistingSession = useCallback(() => {
    try {
      const sessionData = localStorage.getItem('admin_session');
      if (sessionData) {
        const { timestamp, authenticated } = JSON.parse(sessionData);
        const now = Date.now();

        if (authenticated && (now - timestamp) < SESSION_DURATION) {
          setAuthState({
            isAuthenticated: true,
            isLoading: false,
            error: null,
          });
          return;
        } else {
          localStorage.removeItem('admin_session');
        }
      }
    } catch (error) {
      console.error('Error checking session:', error);
      localStorage.removeItem('admin_session');
    }

    setAuthState({
      isAuthenticated: false,
      isLoading: false,
      error: null,
    });
  }, []);

  const getStoredPassword = useCallback(async (): Promise<string> => {
    // 1. Primero intentar localStorage (siempre disponible)
    const localPwd = localStorage.getItem(PASSWORD_STORAGE_KEY);
    if (localPwd) return localPwd;

    // 2. Intentar PocketBase como fuente secundaria
    try {
      const records = await pb.collection('admin_config').getFullList();
      const config = records.find(r => r.key === 'custodian_password');
      if (config && config.value) {
        // Sincronizar a localStorage para próximas consultas
        localStorage.setItem(PASSWORD_STORAGE_KEY, config.value);
        return config.value;
      }
    } catch (error) {
      console.warn('No se pudo obtener contraseña de PocketBase, usando por defecto');
    }

    return DEFAULT_CUSTODIAN_PASSWORD;
  }, []);

  const savePassword = useCallback(async (newPassword: string): Promise<void> => {
    // 1. Guardar siempre en localStorage (fuente primaria, nunca falla)
    localStorage.setItem(PASSWORD_STORAGE_KEY, newPassword);

    // 2. Intentar sincronizar con PocketBase (opcional, no bloquea)
    try {
      const records = await pb.collection('admin_config').getFullList();
      const config = records.find(r => r.key === 'custodian_password');

      if (config) {
        await pb.collection('admin_config').update(config.id, {
          value: newPassword,
          updated_at: new Date().toISOString()
        });
      } else {
        await pb.collection('admin_config').create({
          key: 'custodian_password',
          value: newPassword,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
      }
    } catch (error) {
      // No lanzar error — localStorage ya guardó la contraseña
      console.warn('No se pudo sincronizar contraseña con PocketBase (guardada localmente)');
    }
  }, []);

  const login = useCallback(async (password: string): Promise<boolean> => {
    setAuthState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      const storedPassword = await getStoredPassword();

      if (password === storedPassword) {
        const sessionData = {
          authenticated: true,
          timestamp: Date.now()
        };
        localStorage.setItem('admin_session', JSON.stringify(sessionData));

        setAuthState({
          isAuthenticated: true,
          isLoading: false,
          error: null,
        });

        toast({
          title: "Acceso autorizado",
          description: "Bienvenido al Dashboard de Actividad"
        });

        return true;
      } else {
        setAuthState({
          isAuthenticated: false,
          isLoading: false,
          error: 'Contraseña incorrecta',
        });

        toast({
          title: "Acceso denegado",
          description: "La contraseña ingresada es incorrecta",
          variant: "destructive"
        });

        return false;
      }
    } catch (error) {
      console.error('Login error:', error);
      setAuthState({
        isAuthenticated: false,
        isLoading: false,
        error: 'Error al verificar credenciales',
      });

      toast({
        title: "Error de autenticación",
        description: "Ocurrió un error al verificar las credenciales",
        variant: "destructive"
      });

      return false;
    }
  }, [getStoredPassword, toast]);

  const changePassword = useCallback(async (oldPassword: string, newPassword: string): Promise<boolean> => {
    try {
      const storedPassword = await getStoredPassword();

      if (oldPassword !== storedPassword) {
        toast({
          title: "Error",
          description: "La contraseña actual es incorrecta",
          variant: "destructive"
        });
        return false;
      }

      await savePassword(newPassword);

      toast({
        title: "Contraseña actualizada",
        description: "La contraseña ha sido cambiada exitosamente"
      });

      return true;
    } catch (error) {
      console.error('Change password error:', error);
      toast({
        title: "Error",
        description: "No se pudo cambiar la contraseña",
        variant: "destructive"
      });
      return false;
    }
  }, [getStoredPassword, savePassword, toast]);

  const logout = useCallback(() => {
    localStorage.removeItem('admin_session');
    setAuthState({
      isAuthenticated: false,
      isLoading: false,
      error: null,
    });

    toast({
      title: "Sesión cerrada",
      description: "Ha cerrado sesión correctamente"
    });
  }, [toast]);

  const extendSession = useCallback(() => {
    if (authState.isAuthenticated) {
      const sessionData = {
        authenticated: true,
        timestamp: Date.now()
      };
      localStorage.setItem('admin_session', JSON.stringify(sessionData));
    }
  }, [authState.isAuthenticated]);

  // Auto-logout cuando la sesión expira
  useEffect(() => {
    if (authState.isAuthenticated) {
      const checkSession = () => {
        const sessionData = localStorage.getItem('admin_session');
        if (sessionData) {
          const { timestamp } = JSON.parse(sessionData);
          const now = Date.now();

          if ((now - timestamp) >= SESSION_DURATION) {
            logout();
            toast({
              title: "Sesión expirada",
              description: "Su sesión ha expirado. Por favor, inicie sesión nuevamente.",
              variant: "destructive"
            });
          }
        }
      };

      const interval = setInterval(checkSession, 60000);
      return () => clearInterval(interval);
    }
  }, [authState.isAuthenticated, logout, toast]);

  return {
    isAuthenticated: authState.isAuthenticated,
    isLoading: authState.isLoading,
    error: authState.error,
    // isCustodian siempre true para compatibilidad con código existente
    isCustodian: true,
    login,
    logout,
    changePassword,
    extendSession
  };
}
