import { useState, useEffect, useCallback } from 'react';
import pb from '@/lib/pocketbase';
import { useToast } from '@/hooks/use-toast';

interface AdminAuthState {
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  isCustodian: boolean;
}

const DEFAULT_ADMIN_PASSWORD = 'admin123'; // Contraseña por defecto
const DEFAULT_CUSTODIAN_PASSWORD = 'custodio2026'; // Contraseña de custodio por defecto
const SESSION_DURATION = 4 * 60 * 60 * 1000; // 4 horas en milisegundos

export function useAdminAuth() {
  const [authState, setAuthState] = useState<AdminAuthState>({
    isAuthenticated: false,
    isLoading: true,
    error: null,
    isCustodian: false
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
        const { timestamp, authenticated, isCustodian } = JSON.parse(sessionData);
        const now = Date.now();
        
        // Verificar si la sesión no ha expirado
        if (authenticated && (now - timestamp) < SESSION_DURATION) {
          setAuthState({
            isAuthenticated: true,
            isLoading: false,
            error: null,
            isCustodian: !!isCustodian
          });
          return;
        } else {
          // Sesión expirada
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
      isCustodian: false
    });
  }, []);

  const getStoredPassword = useCallback(async (type: 'admin' | 'custodian' = 'admin'): Promise<string> => {
    try {
      // Intentar obtener la contraseña de PocketBase
      const records = await pb.collection('admin_config').getFullList();
      const configKey = type === 'admin' ? 'admin_password' : 'custodian_password';
      const adminConfig = records.find(r => r.key === configKey);
      
      if (adminConfig && adminConfig.value) {
        return adminConfig.value;
      }
    } catch (error) {
      console.warn(`No se pudo obtener contraseña de ${type} de la base de datos, usando por defecto`);
    }
    
    return type === 'admin' ? DEFAULT_ADMIN_PASSWORD : DEFAULT_CUSTODIAN_PASSWORD;
  }, []);

  const savePassword = useCallback(async (newPassword: string, type: 'admin' | 'custodian' = 'admin'): Promise<void> => {
    try {
      // Buscar si ya existe una configuración
      const records = await pb.collection('admin_config').getFullList();
      const configKey = type === 'admin' ? 'admin_password' : 'custodian_password';
      const adminConfig = records.find(r => r.key === configKey);
      
      if (adminConfig) {
        // Actualizar contraseña existente
        await pb.collection('admin_config').update(adminConfig.id, {
          value: newPassword,
          updated_at: new Date().toISOString()
        });
      } else {
        // Crear nueva configuración
        await pb.collection('admin_config').create({
          key: configKey,
          value: newPassword,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
      }
    } catch (error) {
      console.error('Error saving password:', error);
      throw new Error('No se pudo guardar la nueva contraseña');
    }
  }, []);

  const login = useCallback(async (password: string, loginAsCustodian: boolean = false): Promise<boolean> => {
    setAuthState(prev => ({ ...prev, isLoading: true, error: null }));
    
    try {
      const adminPassword = await getStoredPassword('admin');
      const custodianPassword = await getStoredPassword('custodian');
      
      const isCustodian = loginAsCustodian && password === custodianPassword;
      const isAdmin = !loginAsCustodian && password === adminPassword;
      
      if (isAdmin || isCustodian) {
        // Guardar sesión
        const sessionData = {
          authenticated: true,
          isCustodian: isCustodian,
          timestamp: Date.now()
        };
        localStorage.setItem('admin_session', JSON.stringify(sessionData));
        
        setAuthState({
          isAuthenticated: true,
          isLoading: false,
          error: null,
          isCustodian
        });
        
        toast({
          title: "Acceso autorizado",
          description: isCustodian 
            ? "Bienvenido al dashboard de administración (modo Custodio)"
            : "Bienvenido al dashboard de administración"
        });
        
        return true;
      } else {
        setAuthState({
          isAuthenticated: false,
          isLoading: false,
          error: 'Contraseña incorrecta',
          isCustodian: false
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
        isCustodian: false
      });
      
      toast({
        title: "Error de autenticación",
        description: "Ocurrió un error al verificar las credenciales",
        variant: "destructive"
      });
      
      return false;
    }
  }, [getStoredPassword, toast]);

  const changePassword = useCallback(async (oldPassword: string, newPassword: string, type: 'admin' | 'custodian' = 'admin'): Promise<boolean> => {
    try {
      const storedPassword = await getStoredPassword(type);
      
      if (oldPassword !== storedPassword) {
        toast({
          title: "Error",
          description: `La contraseña actual de ${type === 'admin' ? 'administrador' : 'custodio'} es incorrecta`,
          variant: "destructive"
        });
        return false;
      }
      
      await savePassword(newPassword, type);
      
      toast({
        title: "Contraseña actualizada",
        description: `La contraseña de ${type === 'admin' ? 'administrador' : 'custodio'} ha sido cambiada exitosamente`
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
      isCustodian: false
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
        isCustodian: authState.isCustodian,
        timestamp: Date.now()
      };
      localStorage.setItem('admin_session', JSON.stringify(sessionData));
    }
  }, [authState.isAuthenticated, authState.isCustodian]);

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
      
      const interval = setInterval(checkSession, 60000); // Verificar cada minuto
      return () => clearInterval(interval);
    }
  }, [authState.isAuthenticated, logout, toast]);

  return {
    isAuthenticated: authState.isAuthenticated,
    isLoading: authState.isLoading,
    error: authState.error,
    isCustodian: authState.isCustodian,
    login,
    logout,
    changePassword,
    extendSession
  };
}