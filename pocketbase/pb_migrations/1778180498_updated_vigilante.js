/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("prqcxifwwworjgi")

  // add
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "mh4apvqi",
    "name": "estadoLicencia",
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
    "id": "jd9yhzyj",
    "name": "diasLaborales",
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
  const collection = dao.findCollectionByNameOrId("prqcxifwwworjgi")

  // remove
  collection.schema.removeField("mh4apvqi")

  // remove
  collection.schema.removeField("jd9yhzyj")

  return dao.saveCollection(collection)
})
