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
