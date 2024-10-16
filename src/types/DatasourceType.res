open EntityType
// open Manager
open PgBind
module ManagerType = {
  type t = {
    find: (
      EntityType.t,
      PgClient.t,
      option<array<(string, Query.Params.t)>>,
      option<int>,
    ) => promise<RescriptCore.Promise.t<array<Js.Json.t>>>,
    findOne: (EntityType.t, PgClient.t, int) => RescriptCore.Promise.t<PgResult.t<EntityType.t>>,
    save: (EntityType.t, PgClient.t) => RescriptCore.Promise.t<unit>,
  }
}

module DatasourceType = {
  type defaultConfig = {
    type_: string,
    host: string,
    port: int,
    username: string,
    password: string,
    database: string,
    entities: array<EntityType.t>,
    synchronize: bool,
    logging: bool,
  }

  type dbConfig = {
    user: string,
    password: string,
    host: string,
    database: string,
    port: int,
  }

  type t = {
    config: defaultConfig,
    initialize: unit => RescriptCore.Promise.t<PgClient.t>,
    manager: ManagerType.t,
  }
}
