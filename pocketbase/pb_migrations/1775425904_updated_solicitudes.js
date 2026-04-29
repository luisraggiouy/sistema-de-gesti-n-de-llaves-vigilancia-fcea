/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("xs0cv066kyekpav")

  // add
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "uarbdgmt",
    "name": "departamento",
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

  // add
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "3rmsqx2w",
    "name": "nombre_empresa",
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
  const collection = dao.findCollectionByNameOrId("xs0cv066kyekpav")

  // remove
  collection.schema.removeField("uarbdgmt")

  // remove
  collection.schema.removeField("3rmsqx2w")

  return dao.saveCollection(collection)
})
