# 🔧 Instructivo: Fix Usuarios Duplicados Terminal A

**Fecha:** 27/07/2026  
**Problema:** Al buscar "095" en Terminal A, aparece "Juan Peiras" repetido 3 veces  
**Causa:** La función `buscarPorTexto()` retorna todos los registros sin deduplicación

---

## ⚡ Ejecución Rápida

```powershell
# Cambiar a la carpeta del fix
cd "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\fix\20260727_usuarios_duplicados_fix"

# Aplicar el fix
.\FIX_USUARIOS_DUPLICADOS_v1.ps1

# Reiniciar servidor de desarrollo
cd "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
npm run dev
```

---

## 📋 Pasos Detallados

### 1. Pre-verificación (Opcional)
```powershell
.\FIX_USUARIOS_DUPLICADOS_v1.ps1 -Test
```
- ✅ Verifica que el archivo objetivo existe
- ✅ Confirma que el problema está presente
- ✅ No hace cambios

### 2. Aplicar Fix
```powershell
.\FIX_USUARIOS_DUPLICADOS_v1.ps1
```
- 🔄 Crea backup automático
- 🔧 Aplica deduplicación en `buscarPorTexto()`
- ✅ Verifica que el fix se aplicó correctamente

### 3. Validación Manual
```powershell
# Reiniciar servidor
cd "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
npm run dev
```
1. Abrir http://localhost:5173 en Chrome
2. Ir a la Terminal A (cambiar rol si es necesario)
3. En "Identificarse", escribir "095"
4. **Resultado esperado:** Solo 1 "Juan Peiras" en lugar de 3

### 4. Rollback (Si algo sale mal)
```powershell
.\FIX_USUARIOS_DUPLICADOS_v1.ps1 -Rollback
```

---

## 🎯 Qué Hace Este Fix

### **Antes:**
```javascript
// Retornaba TODOS los registros que coincidían
return currentUsuarios.filter(u => 
  u.celular && u.celular.replace(/\D/g, '').includes(celularBusqueda)
);
```

### **Después:**
```javascript  
// Aplica deduplicación por celular + email
const deduplicados = new Map<string, UsuarioRegistrado>();

resultados.forEach(usuario => {
  const key = `${usuario.celular.replace(/\D/g, '')}_${usuario.email || ''}`;
  const existing = deduplicados.get(key);
  
  // Prioriza el registro más reciente
  if (!existing || new Date(usuario.fechaRegistro) > new Date(existing.fechaRegistro)) {
    deduplicados.set(key, usuario);
  }
});

return Array.from(deduplicados.values());
```

---

## 📂 Archivos Modificados

- `src/hooks/useUsuariosRegistrados.ts` - Función `buscarPorTexto()` línea 143

---

## 🚨 Troubleshooting

### Error: "No se encontró el archivo"
```powershell
# Verificar que estás en el directorio correcto
pwd
cd "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\fix\20260727_usuarios_duplicados_fix"
```

### Fix no se aplica
```powershell
# Rollback y volver a intentar
.\FIX_USUARIOS_DUPLICADOS_v1.ps1 -Rollback
.\FIX_USUARIOS_DUPLICADOS_v1.ps1
```

### El problema persiste después del fix
1. Verificar que el servidor se reinició (`npm run dev`)
2. Hacer hard refresh en Chrome (Ctrl+Shift+R)
3. Revisar que no hay errores en la consola del navegador

---

## ✅ Criterios de Éxito

- [ ] Al buscar "095" aparece solo 1 "Juan Peiras"
- [ ] La búsqueda por email también funciona sin duplicados
- [ ] No hay errores en la consola del navegador
- [ ] La funcionalidad de registro sigue funcionando normalmente