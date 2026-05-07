/**
 * Script para agregar las columnas diasLaborales y estadoLicencia
 * a la colección 'vigilante' en PocketBase.
 *
 * Uso: node agregar_columnas_vigilante.mjs
 */

const PB_URL = 'http://127.0.0.1:8090';
const ADMIN_EMAIL = 'vigilancia@llaves.local';
const ADMIN_PASSWORD = 'vigilanciamvp2026';

async function main() {
  // 1. Autenticar como admin
  console.log('Autenticando como admin...');
  const authRes = await fetch(`${PB_URL}/api/admins/auth-with-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
  });
  if (!authRes.ok) {
    const err = await authRes.text();
    throw new Error(`Error autenticando: ${err}`);
  }
  const { token } = await authRes.json();
  console.log('✅ Autenticado correctamente');

  // 2. Obtener el schema actual de la colección vigilante
  console.log('Obteniendo schema de la colección vigilante...');
  const colRes = await fetch(`${PB_URL}/api/collections/vigilante`, {
    headers: { Authorization: token },
  });
  if (!colRes.ok) throw new Error('No se pudo obtener la colección vigilante');
  const colData = await colRes.json();
  
  const camposActuales = colData.schema || [];
  console.log('Campos actuales:', camposActuales.map(f => f.name).join(', '));

  // 3. Verificar qué columnas faltan
  const tieneEstadoLicencia = camposActuales.some(f => f.name === 'estadoLicencia');
  const tieneDiasLaborales = camposActuales.some(f => f.name === 'diasLaborales');

  if (tieneEstadoLicencia && tieneDiasLaborales) {
    console.log('✅ Ambas columnas ya existen. No se necesita hacer nada.');
    return;
  }

  // 4. Construir nuevo schema con las columnas faltantes
  const nuevoSchema = [...camposActuales];

  if (!tieneEstadoLicencia) {
    console.log('➕ Agregando columna estadoLicencia...');
    nuevoSchema.push({
      name: 'estadoLicencia',
      type: 'text',
      required: false,
      options: { min: null, max: null, pattern: '' },
    });
  } else {
    console.log('✅ estadoLicencia ya existe');
  }

  if (!tieneDiasLaborales) {
    console.log('➕ Agregando columna diasLaborales...');
    nuevoSchema.push({
      name: 'diasLaborales',
      type: 'text',
      required: false,
      options: { min: null, max: null, pattern: '' },
    });
  } else {
    console.log('✅ diasLaborales ya existe');
  }

  // 5. Actualizar la colección con el nuevo schema
  console.log('Actualizando schema de la colección...');
  const updateRes = await fetch(`${PB_URL}/api/collections/${colData.id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: token,
    },
    body: JSON.stringify({ schema: nuevoSchema }),
  });

  if (!updateRes.ok) {
    const err = await updateRes.text();
    throw new Error(`Error actualizando schema: ${err}`);
  }

  const updated = await updateRes.json();
  console.log('✅ Schema actualizado. Campos ahora:', updated.schema.map(f => f.name).join(', '));
  console.log('\n🎉 Listo! Ahora puede guardar diasLaborales y estadoLicencia en PocketBase.');
}

main().catch(e => {
  console.error('❌ Error:', e.message);
  process.exit(1);
});
