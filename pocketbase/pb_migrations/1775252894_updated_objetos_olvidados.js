/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("2fmzv2aioh6ts61")

  // add
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "zilkvpqy",
    "name": "foto_general",
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
    "id": "vh5uk4la",
    "name": "foto_marca",
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
    "id": "nzusqgu9",
    "name": "foto_adicional",
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
    "id": "ppar6oyr",
    "name": "registrado_por",
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
  const collection = dao.findCollectionByNameOrId("2fmzv2aioh6ts61")

  // remove
  collection.schema.removeField("zilkvpqy")

  // remove
  collection.schema.removeField("vh5uk4la")

  // remove
  collection.schema.removeField("nzusqgu9")

  // remove
  collection.schema.removeField("ppar6oyr")

  return dao.saveCollection(collection)
})
