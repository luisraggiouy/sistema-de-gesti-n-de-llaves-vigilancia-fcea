// Script para eliminar vigilantes duplicados de PocketBase
// Uso: node fix_vigilantes_duplicados.mjs <email_admin> <password_admin>

const PB_URL = 'http://127.0.0.1:8090';
const ADMIN_EMAIL = process.argv[2] || 'admin@fcea.edu.uy';
const ADMIN_PASSWORD = process.argv[3] || 'admin123456';

async function main() {
  // Autenticar como admin
  console.log('Autenticando como admin...');
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
      console.log('Autenticado correctamente como admin.');
    } else {
      console.log('No se pudo autenticar como admin, intentando sin auth...');
    }
  } catch (e) {
    console.log('Error de autenticación, continuando sin auth...');
  }

  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': token } : {}),
  };

  // Obtener todos los vigilantes
  const res = await fetch(`${PB_URL}/api/collections/vigilante/records?perPage=200&sort=nombre,created`, { headers });
  const data = await res.json();
  const records = data.items || [];
  console.log(`Total vigilantes en BD: ${records.length}`);

  // Agrupar por nombre
  const porNombre = {};
  for (const r of records) {
    if (!porNombre[r.nombre]) porNombre[r.nombre] = [];
    porNombre[r.nombre].push(r);
  }

  let eliminados = 0;
  for (const [nombre, lista] of Object.entries(porNombre)) {
    if (lista.length > 1) {
      console.log(`"${nombre}" tiene ${lista.length} entradas - eliminando ${lista.length - 1} duplicados`);
      for (let i = 1; i < lista.length; i++) {
        const delRes = await fetch(`${PB_URL}/api/collections/vigilante/records/${lista[i].id}`, {
          method: 'DELETE',
          headers,
        });
        if (delRes.ok || delRes.status === 204) {
          eliminados++;
        } else {
          console.log(`  Error eliminando ${lista[i].id}: ${delRes.status}`);
        }
      }
    }
  }

  console.log(`\nEliminados ${eliminados} duplicados.`);

  // Verificar resultado
  const res2 = await fetch(`${PB_URL}/api/collections/vigilante/records?perPage=200&sort=nombre`, { headers });
  const data2 = await res2.json();
  const restantes = data2.items || [];
  console.log(`\nVigilantes restantes (${restantes.length}):`);
  for (const r of restantes) {
    console.log(`  - ${r.nombre} (${r.turno})${r.es_jefe ? ' [JEFE]' : ''}`);
  }
}

main().catch(console.error);
