open PgBind

@module("fs")
external readFileSync: string => string = "readFileSync"

let connectToDb = () => {
  let client = PgClient.make(
    ~user="admin",
    ~password="adminpwd",
    ~host="localhost",
    ~database="db",
    ~port=5432,
    (),
  )

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
