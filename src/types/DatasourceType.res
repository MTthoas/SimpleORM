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
    ) => promise<array<Js.Json.t>>,
    findOne: (EntityType.t, PgClient.t, int) => promise<option<Js.Json.t>>,
    save: (EntityType.t, PgClient.t) => promise<unit>,
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
    initialize: unit => promise<PgClient.t>,
    manager: ManagerType.t,
  }
}
