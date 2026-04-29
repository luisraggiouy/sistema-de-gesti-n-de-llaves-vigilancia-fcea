/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const collection = new Collection({
    "id": "qno9mzmfadh1xgs",
    "created": "2026-03-27 22:10:25.998Z",
    "updated": "2026-03-27 22:10:25.998Z",
    "name": "configuracion",
    "type": "base",
    "system": false,
    "schema": [
      {
        "system": false,
        "id": "pnvbxvpm",
        "name": "clave",
        "type": "text",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      },
      {
        "system": false,
        "id": "xegxynhi",
        "name": "valor",
        "type": "text",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      }
    ],
    "indexes": [],
    "listRule": null,
    "viewRule": null,
    "createRule": null,
    "updateRule": null,
    "deleteRule": null,
    "options": {}
  });

  return Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("qno9mzmfadh1xgs");

  return dao.deleteCollection(collection);
})
