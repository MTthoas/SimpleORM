open PgBind
open Config

@module("fs")
external readFileSync: string => string = "readFileSync"

let connectToDb = (
  ~user=Config.defaultConfig.user,
  ~password=Config.defaultConfig.password,
  ~host=Config.defaultConfig.host,
  ~database=Config.defaultConfig.database,
  ~port=Config.defaultConfig.port,
) => {
  let client = PgClient.make(~user, ~password, ~host, ~database, ~port, ())

  PgClient.connect(client, ())
  ->Promise.then(_ => {
    Console.log("Connected to the database")
    // Here we return the client, we doesnt close the connection
    Js.Promise.resolve(client)
  })
  ->Promise.catch(e => {
    Console.error2("Failed to connect to the database", e)
    Js.Promise.reject(e)
  })
}

let closeConnection = (client: PgClient.t) => {
  PgClient.end(client, ())
  ->Promise.then(_ => {
    Console.log("Connection closed")
    Js.Promise.resolve()
  })
  ->Promise.catch(e => {
    Console.error2("Failed to close the connection", e)
    Js.Promise.reject(e)
  })
}

let applyMigration = (onSuccess, onError, client: PgClient.t) => {
  let migrationFile = "./migration.sql"
  let migrationSQL = Buffer.fromString(readFileSync(migrationFile))->Buffer.toString

  Console.log("Applying migration...")
  Console.log(migrationSQL)

  PgClient.Params.query(~statement=migrationSQL, ~params=[], client)
  ->Promise.then(res => {
    onSuccess(res)
    Js.Promise.resolve()
  })
  ->Promise.catch(err => {
    onError(err)
    Js.Promise.reject(err)
  })
}
