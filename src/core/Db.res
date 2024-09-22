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

  client
  ->PgClient.connect()
  ->Promise.then(_ => {
    Console.log("Connected to the database")
    PgClient.end(client, ())
  })
  ->Promise.catch(e => {
    Console.error2("Failed to connect to the database", e)
    Promise.resolve()
  })
}