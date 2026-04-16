const resp = await fetch('http://127.0.0.1:8090/api/collections');
const data = await resp.json();
const items = data.items || data;
const c = (Array.isArray(items) ? items : []).find(x => x.name === 'lugares');
if (c) {
  c.schema.forEach(f => console.log(f.name, f.type));
} else {
  console.log('not found, keys:', Object.keys(data));
}
