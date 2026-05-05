// Script para cargar vigilantes iniciales en PocketBase
// SEGURO: verifica existencia antes de crear (no genera duplicados)
// Uso: node vigilantes.mjs

const PB_URL = 'http://127.0.0.1:8090';
const ADMIN_EMAIL = 'vigilancia@llaves.local';
const ADMIN_PASSWORD = 'vigilanciamvp2026';

const vigilantes = [
  { nombre: 'Sylvia',    turno: 'Matutino',   es_jefe: true  },
  { nombre: 'Claudia',   turno: 'Matutino',   es_jefe: false },
  { nombre: 'Laura',     turno: 'Matutino',   es_jefe: false },
  { nombre: 'Lourdes',   turno: 'Matutino',   es_jefe: false },
  { nombre: 'Luis',      turno: 'Matutino',   es_jefe: false },
  { nombre: 'Dahiana',   turno: 'Matutino',   es_jefe: false },
  { nombre: 'Martin',    turno: 'Vespertino', es_jefe: true  },
  { nombre: 'Daniel',    turno: 'Vespertino', es_jefe: false },
  { nombre: 'Nathia',    turno: 'Vespertino', es_jefe: false },
  { nombre: 'Silvia',    turno: 'Vespertino', es_jefe: false },
  { nombre: 'Alejandro', turno: 'Vespertino', es_jefe: false },
  { nombre: 'Caterin',   turno: 'Vespertino', es_jefe: false },
  { nombre: 'Gustavo',   turno: 'Nocturno',   es_jefe: true  },
  { nombre: 'Mario',     turno: 'Nocturno',   es_jefe: false },
  { nombre: 'Silvana',   turno: 'Nocturno',   es_jefe: false },
  { nombre: 'Fernando',  turno: 'Nocturno',   es_jefe: false },
];

async function cargar() {
  // Autenticar como admin
  let token = '';
  try {
    const authRes = await fetch(`${PB_URL}/api/admins/auth-with-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identity: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
    });
    if (authRes.ok) {
      const authData = await authRes.json();
      token = authData.token;
      console.log('Autenticado como admin.');
    }
  } catch (e) {
    console.log('Sin autenticación admin, continuando...');
  }

  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': token } : {}),
  };

  // Obtener vigilantes existentes
  const existRes = await fetch(`${PB_URL}/api/collections/vigilante/records?perPage=200`, { headers });
  const existData = await existRes.json();
  const existentes = (existData.items || []).map(r => r.nombre.toLowerCase());

  let creados = 0;
  let omitidos = 0;

  for (const v of vigilantes) {
    if (existentes.includes(v.nombre.toLowerCase())) {
      console.log(`  (ya existe) ${v.nombre}`);
      omitidos++;
      continue;
    }
    const r = await fetch(`${PB_URL}/api/collections/vigilante/records`, {
      method: 'POST',
      headers,
      body: JSON.stringify(v),
    });
    if (r.ok) {
      console.log(`  ✓ Creado: ${v.nombre} (${v.turno})`);
      creados++;
    } else {
      const err = await r.json();
      console.error(`  ✗ Error: ${v.nombre} - ${err.message}`);
    }
  }

  console.log(`\nListo! Creados: ${creados} | Ya existían: ${omitidos}`);
}

cargar();
