// Fix columna field type from number to text in PocketBase
const PB_URL = 'http://127.0.0.1:8090';

// Step 1: Auth as admin
const authResp = await fetch(`${PB_URL}/api/admins/auth-with-password`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ identity: 'vigilancia@llaves.local', password: 'vigilanciamvp2026' })
});
const authData = await authResp.json();
const token = authData.token;
console.log('Authenticated as admin');

// Step 2: Get the lugares collection schema
const colResp = await fetch(`${PB_URL}/api/collections/b0nzrysmlaq9j0u`, {
  headers: { 'Authorization': token }
});
const colData = await colResp.json();
console.log('Current schema fields:', colData.schema?.map(f => `${f.name}:${f.type}`));

// Step 3: Remove the old columna (number) field, add new columna_txt (text) field
const schemaWithoutColumna = colData.schema.filter(f => f.name !== 'columna');
schemaWithoutColumna.push({
  name: 'columna_txt',
  type: 'text',
  required: false,
  options: { min: null, max: null, pattern: '' }
});

const updateResp = await fetch(`${PB_URL}/api/collections/b0nzrysmlaq9j0u`, {
  method: 'PATCH',
  headers: { 'Content-Type': 'application/json', 'Authorization': token },
  body: JSON.stringify({ schema: schemaWithoutColumna })
});
const updateData = await updateResp.json();
if (!updateResp.ok) {
  console.error('Step 3 failed:', JSON.stringify(updateData, null, 2));
  process.exit(1);
}
console.log('Step 3: Removed old columna (number), added columna_txt (text)');

// Step 4: Rename columna_txt to columna
const schema2 = updateData.schema.map(f => {
  if (f.name === 'columna_txt') {
    return { ...f, name: 'columna' };
  }
  return f;
});

const updateResp2 = await fetch(`${PB_URL}/api/collections/b0nzrysmlaq9j0u`, {
  method: 'PATCH',
  headers: { 'Content-Type': 'application/json', 'Authorization': token },
  body: JSON.stringify({ schema: schema2 })
});
const updateData2 = await updateResp2.json();
if (!updateResp2.ok) {
  console.error('Step 4 failed:', JSON.stringify(updateData2, null, 2));
  process.exit(1);
}
console.log('Step 4: Renamed columna_txt to columna');
console.log('Final schema:', updateData2.schema?.map(f => `${f.name}:${f.type}`));
console.log('Done! columna is now a text field. You can modify it from the UI.');
