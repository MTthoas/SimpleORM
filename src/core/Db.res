open PgBind

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
