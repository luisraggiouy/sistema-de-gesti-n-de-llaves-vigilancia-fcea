/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("b0nzrysmlaq9j0u")

  // remove
  collection.schema.removeField("7ac2owya")

  // add
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "pm1o6pj2",
    "name": "columna_txt",
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

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("b0nzrysmlaq9j0u")

  // add
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "7ac2owya",
    "name": "columna",
    "type": "number",
    "required": false,
    "presentable": false,
    "unique": false,
    "options": {
      "min": null,
      "max": null,
      "noDecimal": false
    }
  }))

  // remove
  collection.schema.removeField("pm1o6pj2")

  return dao.saveCollection(collection)
})
