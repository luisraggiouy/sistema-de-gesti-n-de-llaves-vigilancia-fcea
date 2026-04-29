const resp = await fetch('http://127.0.0.1:8090/api/collections/lugares/records?filter=nombre=%22Intendencia%22');
const data = await resp.json();
for (const i of data.items) {
  console.log(JSON.stringify(i, null, 2));
}
