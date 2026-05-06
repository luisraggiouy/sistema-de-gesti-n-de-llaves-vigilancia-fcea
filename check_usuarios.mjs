import PocketBase from 'pocketbase';
const pb = new PocketBase('http://127.0.0.1:8090');
const records = await pb.collection('usuarios_registrados').getFullList({ sort: 'nombre' });
console.log('Total usuarios en PocketBase:', records.length);
records.forEach(u => console.log(` - ${u.nombre} | ${u.tipo} | ${u.celular}`));
