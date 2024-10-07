open Db

let main = () => {
  connectToDb()
  ->Promise.then(client => {
    applyMigration(
      _ => {
        Console.log("Migration applied successfully!")
      },
      err => {
        Console.error2("Error applying migration:", err)
      },
      client,
    )
  })
  ->Promise.catch(err => {
    Console.log(err)
    Promise.reject(err)
  })
}

main()->ignore
