open Config

module Db = {

  @module("PgClient")
  external makeClient: (
    ~user: string,
    ~password: string,
    ~host: string,
    ~database: string,
    ~port: int,
    unit
  ) => Config.client = "make"

  @module("PgClient")
  external connectClient: (Config.client, unit) => Js.Promise.t<unit> = "connect"

  // Fonction pour se connecter à la base de données avec des paramètres
  let connectToDb = (~config: Config.dbConfig) => {
    let client = makeClient(
      ~user=config.user,
      ~password=config.password,
      ~host=config.host,
      ~database=config.database,
      ~port=config.port,
      ()
    )

    connectClient(client, ())
    ->Promise.then(_ => {
      Console.log("Connected to the database")
      // Retourner le client sans fermer la connexion
      Js.Promise.resolve(client)
    })
    ->Promise.catch(e => {
      Console.error2("Failed to connect to the database", e)
      Js.Promise.reject(e)
    })
  }
}
