/// <reference path="../pb_data/types.d.ts" />
// ============================================================================
// Migracion: Coleccion sistema_config
// ----------------------------------------------------------------------------
// Almacena la configuracion de instalacion del sistema (modo, hardware,
// monitores, dispositivos detectados). Funciona como respaldo del archivo
// install_config.json que vive en C:\sistema-llaves-fcea\config\.
//
// Solo deberia existir UN registro en esta coleccion. El instalador y el
// recuperador hacen UPSERT (buscan por id="install_config" y crean/actualizan).
//
// Generada como parte del rediseno del instalador unificado (mayo 2026).
// ============================================================================
migrate((db) => {
  // IDs en PocketBase deben tener exactamente 15 caracteres alfanumericos.
  // sysconfg00000001 tiene 16 -> usamos sysconfg0000001 (15).
  const collection = new Collection({
    "id": "sysconfg0000001",
    "created": "2026-05-13 11:30:00.000Z",
    "updated": "2026-05-13 11:30:00.000Z",
    "name": "sistema_config",
    "type": "base",
    "system": false,
    "schema": [
      {
        "system": false,
        "id": "scfg_modo",
        "name": "modo",
        "type": "select",
        "required": true,
        "presentable": true,
        "unique": false,
        "options": {
          "maxSelect": 1,
          "values": ["produccion", "desarrollo"]
        }
      },
      {
        "system": false,
        "id": "scfg_hw",
        "name": "hardware",
        "type": "select",
        "required": true,
        "presentable": true,
        "unique": false,
        "options": {
          "maxSelect": 1,
          "values": ["tactil", "tradicional", "desarrollo"]
        }
      },
      {
        "system": false,
        "id": "scfg_monit",
        "name": "monitores_json",
        "type": "json",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "maxSize": 2000000
        }
      },
      {
        "system": false,
        "id": "scfg_devs",
        "name": "dispositivos_json",
        "type": "json",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "maxSize": 2000000
        }
      },
      {
        "system": false,
        "id": "scfg_ver",
        "name": "version",
        "type": "text",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "min": null,
          "max": 20,
          "pattern": ""
        }
      },
      {
        "system": false,
        "id": "scfg_finst",
        "name": "fecha_instalacion",
        "type": "date",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "min": "",
          "max": ""
        }
      },
      {
        "system": false,
        "id": "scfg_pcid",
        "name": "pc_identifier",
        "type": "text",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "min": null,
          "max": 200,
          "pattern": ""
        }
      },
      {
        "system": false,
        "id": "scfg_notes",
        "name": "notas",
        "type": "text",
        "required": false,
        "presentable": false,
        "unique": false,
        "options": {
          "min": null,
          "max": 1000,
          "pattern": ""
        }
      }
    ],
    "indexes": [],
    // Reglas: cualquiera puede leer/crear/actualizar (es config local de
    // instalacion, el recuperador la escribe sin autenticarse). NO se
    // permite borrar (deleteRule = null = solo admins).
    "listRule":   "",
    "viewRule":   "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": null,
    "options": {}
  });

  return Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("sysconfg0000001");

  return dao.deleteCollection(collection);
})
