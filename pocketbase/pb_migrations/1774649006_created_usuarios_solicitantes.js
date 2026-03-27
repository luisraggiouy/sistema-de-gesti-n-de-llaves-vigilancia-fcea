/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const collection = new Collection({
    "id": "pnufb9ppcakhpem",
    "created": "2026-03-27 22:03:26.345Z",
    "updated": "2026-03-27 22:03:26.345Z",
    "name": "usuarios_solicitantes",
    "type": "base",
    "system": false,
    "schema": [
      {
        "system": false,
        "id": "2oodui6w",
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
        "id": "h741cu0i",
        "name": "celular",
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
        "id": "chqp2ep0",
        "name": "tipo_usuario",
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
  const collection = dao.findCollectionByNameOrId("pnufb9ppcakhpem");

  return dao.deleteCollection(collection);
})
