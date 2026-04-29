/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const collection = new Collection({
    "id": "wj1v90w6ir5s4q2",
    "created": "2026-04-01 22:27:14.638Z",
    "updated": "2026-04-01 22:27:14.638Z",
    "name": "historial_llaves",
    "type": "base",
    "system": false,
    "schema": [
      {
        "system": false,
        "id": "6gjlfxfk",
        "name": "usuario_id",
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
        "id": "hwy42zv4",
        "name": "llaves",
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
    "listRule": "",
    "viewRule": "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": "",
    "options": {}
  });

  return Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("wj1v90w6ir5s4q2");

  return dao.deleteCollection(collection);
})
