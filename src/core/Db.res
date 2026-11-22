open PgBind
open Config

@module("fs")
external readFileSync: (string, @as("utf8") _) => string = "readFileSync"

/**
 Opens a connection to PostgreSQL. Every setting defaults to the environment (see Config).
 The connection stays open: close it with `closeConnection`.

 @param user database user
 @param password user password
 @param host database host
 @param database database name
 @param port database port
 */
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
    Promise.resolve(client)
  })
  ->Promise.catch(e => {
    Console.error2("Failed to connect to the database", e)
    Promise.reject(e)
  })
}

/**
 @param client connection opened by `connectToDb`
 */
let closeConnection = (client: PgClient.t) => {
  PgClient.end(client, ())
  ->Promise.then(_ => {
    Console.log("Connection closed")
    Promise.resolve()
  })
  ->Promise.catch(e => {
    Console.error2("Failed to close the connection", e)
    Promise.reject(e)
  })
}

/**
 Runs ./migration.sql on the database.

 @param onSuccess called with the query result
 @param onError called with the error, which is then rethrown
 @param client connected PostgreSQL client
 */
let applyMigration = async (onSuccess, onError, client: PgClient.t) => {
  try {
    let migrationSQL = readFileSync("./migration.sql")

    Console.log("Applying migration...")
    Console.log(migrationSQL)

    let result = await PgClient.Params.query(~statement=migrationSQL, ~params=[], client)
    onSuccess(result)
  } catch {
  | err =>
    onError(err)
    raise(err)
  }
}
