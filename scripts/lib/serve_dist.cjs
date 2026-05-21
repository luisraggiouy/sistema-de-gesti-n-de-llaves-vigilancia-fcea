// ============================================================
//  scripts/lib/serve_dist.cjs
//  Mini servidor HTTP estatico para servir la carpeta dist/
//  del frontend del Sistema de Gestion de Llaves FCEA.
//
//  Por que no usamos `npx serve`?
//    - `npx serve` requiere descargar el paquete la primera vez
//      (necesita Internet) y puede tardar mucho. Si falla, el
//      arranque del sistema queda colgado y Chrome muestra
//      "ERR_CONNECTION_REFUSED". Este script no tiene NINGUNA
//      dependencia externa, usa solo el modulo `http` que viene
//      con Node, por lo que es instantaneo y 100% offline.
//
//  Uso:
//    node scripts/lib/serve_dist.cjs [puerto] [carpeta]
//    node scripts/lib/serve_dist.cjs 5173 dist
//
//  Comportamiento tipo SPA:
//    - Si el archivo solicitado no existe, devuelve index.html
//      (necesario para React Router en /monitor, /terminal, etc).
// ============================================================

const http = require('http');
const fs   = require('fs');
const path = require('path');
const url  = require('url');

const PORT = parseInt(process.argv[2] || '5173', 10);
const ROOT = path.resolve(process.argv[3] || 'dist');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.htm':  'text/html; charset=utf-8',
  '.js':   'application/javascript; charset=utf-8',
  '.mjs':  'application/javascript; charset=utf-8',
  '.cjs':  'application/javascript; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif':  'image/gif',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
  '.webp': 'image/webp',
  '.woff': 'font/woff',
  '.woff2':'font/woff2',
  '.ttf':  'font/ttf',
  '.eot':  'application/vnd.ms-fontobject',
  '.otf':  'font/otf',
  '.map':  'application/json; charset=utf-8',
  '.txt':  'text/plain; charset=utf-8',
  '.webmanifest': 'application/manifest+json',
  '.wav':  'audio/wav',
  '.mp3':  'audio/mpeg',
  '.mp4':  'video/mp4'
};

if (!fs.existsSync(ROOT)) {
  console.error(`[serve_dist] ERROR: la carpeta '${ROOT}' no existe.`);
  console.error(`[serve_dist] Ejecute 'npm run build' antes de iniciar.`);
  process.exit(1);
}

const indexHtml = path.join(ROOT, 'index.html');
if (!fs.existsSync(indexHtml)) {
  console.error(`[serve_dist] ERROR: no se encontro index.html en ${ROOT}.`);
  process.exit(1);
}

function sendFile(res, filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const mime = MIME[ext] || 'application/octet-stream';

  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      return sendIndex(res);
    }
    res.writeHead(200, {
      'Content-Type': mime,
      'Content-Length': stat.size,
      'Cache-Control': 'no-cache, no-store, must-revalidate'
    });
    fs.createReadStream(filePath).pipe(res);
  });
}

function sendIndex(res) {
  fs.readFile(indexHtml, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      return res.end('500 Internal Server Error');
    }
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-cache, no-store, must-revalidate'
    });
    res.end(data);
  });
}

const server = http.createServer((req, res) => {
  try {
    const parsed = url.parse(req.url);
    let pathname = decodeURIComponent(parsed.pathname || '/');

    // Seguridad basica: nada de salir de ROOT con ../
    if (pathname.includes('\0')) {
      res.writeHead(400); return res.end('Bad Request');
    }

    // Normalizar
    if (pathname === '/' || pathname === '') {
      return sendIndex(res);
    }

    const filePath = path.normalize(path.join(ROOT, pathname));
    if (!filePath.startsWith(ROOT)) {
      res.writeHead(403); return res.end('Forbidden');
    }

    fs.stat(filePath, (err, stat) => {
      if (err) {
        // SPA fallback: cualquier ruta inexistente => index.html
        return sendIndex(res);
      }
      if (stat.isDirectory()) {
        // Si es directorio, buscar index.html dentro
        const idx = path.join(filePath, 'index.html');
        return fs.existsSync(idx) ? sendFile(res, idx) : sendIndex(res);
      }
      sendFile(res, filePath);
    });
  } catch (e) {
    res.writeHead(500); res.end('500');
  }
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`[serve_dist] ERROR: el puerto ${PORT} ya esta en uso.`);
  } else {
    console.error(`[serve_dist] ERROR: ${err.message}`);
  }
  process.exit(1);
});

// Escuchar en 0.0.0.0 para que sea accesible desde otras PCs de la LAN
// (necesario para las terminales que apuntan al servidor monitor).
server.listen(PORT, '0.0.0.0', () => {
  console.log(`[serve_dist] Sirviendo '${ROOT}' en:`);
  console.log(`[serve_dist]   http://127.0.0.1:${PORT}/`);
  console.log(`[serve_dist]   http://0.0.0.0:${PORT}/  (LAN)`);
  console.log(`[serve_dist] Presione Ctrl+C para detener.`);
});
