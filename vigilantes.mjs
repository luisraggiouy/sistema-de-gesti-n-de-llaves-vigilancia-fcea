async function cargar() {
  const vigilantes = [
    { nombre: 'Sylvia', turno: 'Matutino', es_jefe: true },
    { nombre: 'Claudia', turno: 'Matutino', es_jefe: false },
    { nombre: 'Laura', turno: 'Matutino', es_jefe: false },
    { nombre: 'Lourdes', turno: 'Matutino', es_jefe: false },
    { nombre: 'Luis', turno: 'Matutino', es_jefe: false },
    { nombre: 'Dahiana', turno: 'Matutino', es_jefe: false },
    { nombre: 'Martin', turno: 'Vespertino', es_jefe: true },
    { nombre: 'Daniel', turno: 'Vespertino', es_jefe: false },
    { nombre: 'Nathia', turno: 'Vespertino', es_jefe: false },
    { nombre: 'Silvia', turno: 'Vespertino', es_jefe: false },
    { nombre: 'Alejandro', turno: 'Vespertino', es_jefe: false },
    { nombre: 'Caterin', turno: 'Vespertino', es_jefe: false },
    { nombre: 'Gustavo', turno: 'Nocturno', es_jefe: true },
    { nombre: 'Mario', turno: 'Nocturno', es_jefe: false },
    { nombre: 'Silvana', turno: 'Nocturno', es_jefe: false },
    { nombre: 'Fernando', turno: 'Nocturno', es_jefe: false }
  ];
  for (const v of vigilantes) {
    const r = await fetch('http://127.0.0.1:8090/api/collections/vigilante/records', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(v)
    });
    const data = await r.json();
    if (r.ok) console.log('OK:', v.nombre);
    else console.error('Error:', v.nombre, data.message);
  }
  console.log('Listo!');
}
cargar();
