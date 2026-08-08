/// <reference path="../pb_data/types.d.ts" />
// =============================================================
// Agrega a la coleccion 'solicitudes' los campos necesarios para
// que el INTERCAMBIO de llave se persista y se muestre el cartel
// "Intercambio de llave" en la tarjeta de "Llaves en Uso".
//
// Origen: UPGRADE_BADGE_INTERCAMBIO_LLAVE_2026-08-07
//         (probado OK en produccion el 2026-08-08).
//
// Sin estos campos, PocketBase ignoraba el flag es_intercambio y los
// datos del usuario anterior, por eso un intercambio se mostraba como
// una entrega comun. Esta migracion deja el schema al dia para toda
// instalacion/recuperacion nueva.
//
// Idempotente: si el campo ya existe, no lo vuelve a agregar.
// =============================================================
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("xs0cv066kyekpav")

  const existe = (name) => collection.schema.fields().some((f) => f.name === name)

  if (!existe("es_intercambio")) {
    collection.schema.addField(new SchemaField({
      "system": false,
      "id": "esintcmb01",
      "name": "es_intercambio",
      "type": "bool",
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {}
    }))
  }

  const camposTexto = [
    { id: "usranttnom", name: "usuario_anterior_nombre" },
    { id: "usranttcel", name: "usuario_anterior_celular" },
    { id: "usrantttip", name: "usuario_anterior_tipo" },
    { id: "usranttdep", name: "usuario_anterior_departamento" },
    { id: "usranttemp", name: "usuario_anterior_empresa" }
  ]

  camposTexto.forEach((c) => {
    if (!existe(c.name)) {
      collection.schema.addField(new SchemaField({
        "system": false,
        "id": c.id,
        "name": c.name,
        "type": "text",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      }))
    }
  })

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("xs0cv066kyekpav")

  const quitar = (name) => {
    const f = collection.schema.fields().find((x) => x.name === name)
    if (f) collection.schema.removeField(f.id)
  }

  quitar("es_intercambio")
  quitar("usuario_anterior_nombre")
  quitar("usuario_anterior_celular")
  quitar("usuario_anterior_tipo")
  quitar("usuario_anterior_departamento")
  quitar("usuario_anterior_empresa")

  return dao.saveCollection(collection)
})
