import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Shield, Eye, EyeOff, Key } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface AdminLoginProps {
  onLogin: (password: string, loginAsCustodian?: boolean) => void;
  onChangePassword?: (oldPassword: string, newPassword: string, type?: 'admin' | 'custodian') => void;
  isChangingPassword: boolean;
  onToggleChangePassword: () => void;
  isCustodian?: boolean;
  onCancel?: () => void;
}

export function AdminLogin({ 
  onLogin, 
  onChangePassword = () => {}, 
  isChangingPassword, 
  onToggleChangePassword,
  isCustodian = false,
  onCancel
}: AdminLoginProps) {
  const [password, setPassword] = useState('');
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [error, setError] = useState('');
  const [loginType, setLoginType] = useState<'admin' | 'custodian'>('admin');
  const { toast } = useToast();

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!password.trim()) {
      setError('Debe ingresar la contraseña');
      return;
    }
    setError('');
    onLogin(password, loginType === 'custodian');
  };

  const handleChangePassword = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!oldPassword.trim() || !newPassword.trim() || !confirmPassword.trim()) {
      setError('Todos los campos son obligatorios');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('Las contraseñas nuevas no coinciden');
      return;
    }

    if (newPassword.length < 6) {
      setError('La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }

    setError('');
    onChangePassword(oldPassword, newPassword, isCustodian ? 'custodian' : 'admin');
    
    // Limpiar formulario
    setOldPassword('');
    setNewPassword('');
    setConfirmPassword('');
    onToggleChangePassword();
    
    toast({
      title: "Contraseña actualizada",
      description: `La contraseña de ${isCustodian ? 'custodio' : 'administrador'} ha sido cambiada exitosamente`
    });
  };

  return (
    <div className="w-full">
      <Card className="w-full max-w-md mx-auto">
        <CardHeader className="text-center">
          <div className="mx-auto w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mb-4">
            {isCustodian ? (
              <Key className="w-6 h-6 text-primary" />
            ) : (
              <Shield className="w-6 h-6 text-primary" />
            )}
          </div>
          <CardTitle className="text-2xl">
            {isChangingPassword 
              ? `Cambiar Contraseña de ${isCustodian ? 'Custodio' : 'Administrador'}`
              : 'Acceso de Administrador'}
          </CardTitle>
          <CardDescription>
            {isChangingPassword 
              ? 'Ingrese la contraseña actual y la nueva contraseña'
              : 'Ingrese la contraseña para acceder al dashboard'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {error && (
            <Alert variant="destructive" className="mb-4">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {!isChangingPassword ? (
            <form onSubmit={handleLogin} className="space-y-4">
              <Tabs 
                defaultValue="admin" 
                value={loginType}
                onValueChange={(value) => setLoginType(value as 'admin' | 'custodian')}
                className="w-full"
              >
                <TabsList className="grid w-full grid-cols-2 mb-4">
                  <TabsTrigger value="admin">Administrador</TabsTrigger>
                  <TabsTrigger value="custodian">Custodio</TabsTrigger>
                </TabsList>
                
                <TabsContent value="admin" className="space-y-4">
                  <p className="text-sm text-muted-foreground">
                    Acceso para administradores del sistema con todos los permisos.
                  </p>
                </TabsContent>
                
                <TabsContent value="custodian" className="space-y-4">
                  <p className="text-sm text-muted-foreground">
                    Acceso para el custodio designado que puede llevar reportes en USB.
                  </p>
                </TabsContent>
              </Tabs>
              
              <div className="space-y-2">
                <Label htmlFor="password">
                  Contraseña de {loginType === 'admin' ? 'Administrador' : 'Custodio'}
                </Label>
                <div className="relative">
                  <Input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder={`Ingrese la contraseña de ${loginType === 'admin' ? 'administrador' : 'custodio'}`}
                    className="pr-10"
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </Button>
                </div>
              </div>
              
              <Button type="submit" className="w-full">
                Acceder al Dashboard
              </Button>
              {onCancel && (
                <Button type="button" variant="outline" className="w-full" onClick={onCancel}>
                  Cancelar
                </Button>
              )}
              
              {loginType === 'admin' && (
                <Button 
                  type="button" 
                  variant="outline" 
                  className="w-full"
                  onClick={onToggleChangePassword}
                >
                  Cambiar Contraseña
                </Button>
              )}
            </form>
          ) : (
            <form onSubmit={handleChangePassword} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="oldPassword">Contraseña Actual</Label>
                <div className="relative">
                  <Input
                    id="oldPassword"
                    type={showPassword ? 'text' : 'password'}
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                    placeholder="Contraseña actual"
                    className="pr-10"
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </Button>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="newPassword">Nueva Contraseña</Label>
                <div className="relative">
                  <Input
                    id="newPassword"
                    type={showNewPassword ? 'text' : 'password'}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    placeholder="Nueva contraseña (mín. 6 caracteres)"
                    className="pr-10"
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                    onClick={() => setShowNewPassword(!showNewPassword)}
                  >
                    {showNewPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </Button>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirmPassword">Confirmar Nueva Contraseña</Label>
                <Input
                  id="confirmPassword"
                  type={showNewPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Confirme la nueva contraseña"
                />
              </div>
              
              <div className="flex gap-2">
                <Button type="submit" className="flex-1">
                  Cambiar Contraseña
                </Button>
                <Button 
                  type="button" 
                  variant="outline" 
                  onClick={onToggleChangePassword}
                >
                  Cancelar
                </Button>
              </div>
            </form>
          )}
        </CardContent>
        
        <CardFooter className="flex justify-center border-t pt-4">
          <p className="text-xs text-muted-foreground">
            {loginType === 'custodian' 
              ? "El custodio es responsable de la gestión y resguardo de los reportes exportados" 
              : "Ingrese como custodio si necesita exportar reportes a un pendrive"}
          </p>
        </CardFooter>
      </Card>
    </div>
  );
}