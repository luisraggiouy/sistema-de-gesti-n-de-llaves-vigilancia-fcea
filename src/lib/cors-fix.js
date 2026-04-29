/**
 * Script de corrección de errores CORS
 * 
 * Este archivo añade un parche de CORS a nivel de código que evita
 * los problemas de Cross-Origin Resource Sharing en el sistema.
 * 
 * El problema detectado:
 * "Unsafe attempt to load URL http://localhost:8080/monitor from frame with URL 
 * chrome-error://chromewebdata/. Domains, protocols and ports must match."
 */

// Parche de CORS para PocketBase
const patchCorsPocketBase = () => {
  const originalFetch = window.fetch;
  
  // Reemplazar la función fetch con nuestra versión con CORS habilitado
  window.fetch = function(...args) {
    // Obtener la URL que está intentando acceder
    const url = args[0];
    const options = args[1] || {};
    
    // Si no es un objeto Request, convertirlo a URL para analizar
    const targetUrl = url instanceof Request ? new URL(url.url) : new URL(url, window.location.origin);
    
    // Si la URL es para el servidor PocketBase, añadir encabezados CORS
    if (targetUrl.hostname === 'localhost' && 
       (targetUrl.port === '8080' || targetUrl.port === '8090')) {
      
      // Añadir encabezados CORS necesarios
      options.headers = options.headers || {};
      options.headers = {
        ...options.headers,
        'Access-Control-Allow-Origin': window.location.origin,
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      };
      
      // Registrar en consola que estamos aplicando el parche CORS
      console.log(`[CORS FIX] Aplicando parche CORS para: ${targetUrl.toString()}`);
    }
    
    // Llamar a la función fetch original con los nuevos encabezados
    return originalFetch.apply(this, [url, options]);
  };
  
  console.log('[CORS FIX] Parche CORS aplicado a nivel de aplicación.');
};

// Parche para el cliente PocketBase específico
const patchPocketBaseClient = () => {
  // Verificar si el módulo PocketBase existe
  if (typeof window.PocketBase !== 'undefined') {
    const originalSend = window.PocketBase.prototype.send;
    
    // Reemplazar el método send de PocketBase
    window.PocketBase.prototype.send = function(...args) {
      // Obtener las opciones de la solicitud
      const options = args[0] || {};
      
      // Añadir encabezados CORS
      options.headers = options.headers || {};
      options.headers = {
        ...options.headers,
        'Access-Control-Allow-Origin': window.location.origin,
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      };
      
      // Llamar al método send original con las opciones modificadas
      return originalSend.apply(this, [options, ...args.slice(1)]);
    };
    
    console.log('[CORS FIX] Parche CORS aplicado al cliente PocketBase.');
  }
};

// Función principal que aplica todos los parches
export function aplicarParchesCORS() {
  console.log('[CORS FIX] Iniciando aplicación de parches CORS...');
  
  // Aplicar parches
  patchCorsPocketBase();
  patchPocketBaseClient();
  
  // CORS Proxy para solicitudes a puertos específicos
  const setupCorsProxy = () => {
    const originalXHROpen = XMLHttpRequest.prototype.open;
    
    XMLHttpRequest.prototype.open = function(...args) {
      const method = args[0];
      const url = args[1];
      
      // Si es una URL a localhost con puertos específicos, añadir encabezados CORS
      if (typeof url === 'string' && 
          (url.includes('localhost:8080') || url.includes('localhost:8090'))) {
        this.addEventListener('readystatechange', function() {
          if (this.readyState === 1) { // OPENED
            this.setRequestHeader('Access-Control-Allow-Origin', window.location.origin);
            this.setRequestHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH');
            this.setRequestHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
          }
        });
        
        console.log(`[CORS FIX] Aplicando parche CORS para XMLHttpRequest: ${url}`);
      }
      
      return originalXHROpen.apply(this, args);
    };
    
    console.log('[CORS FIX] Parche CORS aplicado para XMLHttpRequests.');
  };
  
  setupCorsProxy();
  
  console.log('[CORS FIX] Todos los parches CORS han sido aplicados.');
  
  // Intentar reconectar automáticamente si la aplicación no responde
  window.addEventListener('error', function(event) {
    // Verificar si el error está relacionado con CORS
    if (event.message && event.message.includes('Access-Control-Allow-Origin')) {
      console.error('[CORS FIX] Se detectó un error CORS después de aplicar parches. Intentando reconexión...');
      setTimeout(() => window.location.reload(), 2000);
    }
  });
}

// Aplicar parches automáticamente al cargar
document.addEventListener('DOMContentLoaded', aplicarParchesCORS);

// Exportar también la función parche individual por si se necesita
export { patchCorsPocketBase };
