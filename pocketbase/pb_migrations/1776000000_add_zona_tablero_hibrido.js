/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("b0nzrysmlaq9j0u")

  // add zona field
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "zona_field_01",
    "name": "zona",
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

  // add tablero field
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "tablero_field_01",
    "name": "tablero",
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

  // add es_hibrido field
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "hibrido_field_01",
    "name": "es_hibrido",
    "type": "bool",
    "required": false,
    "presentable": false,
    "unique": false,
    "options": {}
  }))

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("b0nzrysmlaq9j0u")

  collection.schema.removeField("zona_field_01")
  collection.schema.removeField("tablero_field_01")
  collection.schema.removeField("hibrido_field_01")

  return dao.saveCollection(collection)
})
