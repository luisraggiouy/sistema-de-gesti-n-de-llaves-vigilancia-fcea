/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const collection = new Collection({
    "id": "prqcxifwwworjgi",
    "created": "2026-03-27 22:01:28.420Z",
    "updated": "2026-03-27 22:01:28.420Z",
    "name": "vigilante",
    "type": "base",
    "system": false,
    "schema": [
      {
        "system": false,
        "id": "cv9oz45y",
        "name": "nombre",
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
        "id": "13rjjfxx",
        "name": "turno",
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
        "id": "s0zffdic",
        "name": "es_jefe",
        "type": "bool",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {}
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
  const collection = dao.findCollectionByNameOrId("prqcxifwwworjgi");

  return dao.deleteCollection(collection);
})
