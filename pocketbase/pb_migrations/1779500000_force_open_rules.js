/// <reference path="../pb_data/types.d.ts" />
// ============================================================================
// Migracion: Forzar reglas abiertas en las colecciones que usa el frontend.
// ----------------------------------------------------------------------------
// Contexto (2026-07-25):
//   En algunas instalaciones el pb_data de C:\ProgramData\FCEA-Sistema-Llaves\
//   quedo con las collections creadas pero SIN las reglas abiertas aplicadas
//   (listRule / createRule / updateRule / deleteRule = null en la DB, aunque
//   la migracion 1774653523_updated_vigilante.js las setea a "").
//   Sintoma visible: el modal "Agregar vigilante" del monitor devolvia 400
//   porque createRule=null significa "solo admins" y el frontend NO se
//   autentica como admin (usa acceso publico).
//
//   Diagnosticar por que la migracion anterior no persistio en ese pb_data
//   especifico (probable: DB restaurada desde un backup previo a esa
//   migracion, o migraciones marcadas como aplicadas sin ejecutarse) llevaria
//   mucho tiempo. Este archivo garantiza el estado deseado de forma
//   IDEMPOTENTE: se ejecuta una vez al arrancar PocketBase, deja las reglas
//   como corresponde, y en corridas futuras no hace daño porque las reglas
//   ya estan como queremos.
//
// NO toca schemas, NO toca datos, NO requiere admin logueado. Solo modifica
// los campos listRule/viewRule/createRule/updateRule/deleteRule del metadata
// de cada coleccion.
//
// Colecciones cubiertas: exactamente las que el frontend (src/hooks/*)
// consulta o escribe sin autenticarse.
// ============================================================================
migrate((db) => {
  const dao = new Dao(db);

  // Colecciones que el frontend usa. Todas deberian permitir list/view/create/
  // update publicos. delete tambien queda abierto porque el monitor permite
  // borrar vigilantes / usuarios registrados desde la UI de vigilancia.
  const nombres = [
    "vigilante",
    "solicitudes",
    "lugares",
    "usuarios_solicitantes",
    "usuarios_registrados",
    "configuracion",
    "objetos_olvidados",
    "historial_llaves",
    "auditoria_llaves",
    "sistema_config",
  ];

  for (const nombre of nombres) {
    let collection;
    try {
      collection = dao.findCollectionByNameOrId(nombre);
    } catch (e) {
      // Si por algun motivo esta coleccion no existe en esta instalacion,
      // NO abortar la migracion: solo saltarla. Ej: bases muy viejas.
      console.log("[force_open_rules] coleccion no encontrada, se salta: " + nombre);
      continue;
    }

    collection.listRule = "";
    collection.viewRule = "";
    collection.createRule = "";
    collection.updateRule = "";
    // deleteRule tambien abierto: el monitor de vigilancia elimina desde UI.
    collection.deleteRule = "";

    dao.saveCollection(collection);
    console.log("[force_open_rules] reglas abiertas aplicadas a: " + nombre);
  }

  return null;
}, (db) => {
  // Down migration: intencionalmente NO revierte las reglas.
  // Si alguien hace pb_migrations down no queremos volver a dejar la
  // instalacion productiva rota. Es una operacion de un solo sentido.
  return null;
})
