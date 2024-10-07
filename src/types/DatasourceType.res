open EntityType

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
    initialize: unit => Js.Promise.t<unit>,
  }
}
