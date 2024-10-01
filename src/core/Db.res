open PgBind
open Config

let connectToDb = () => {
  let client = PgClient.make(
    ~user=Config.defaultConfig.user,
    ~password=Config.defaultConfig.password,
    ~host=Config.defaultConfig.host,
    ~database=Config.defaultConfig.database,
    ~port=Config.defaultConfig.port,
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
