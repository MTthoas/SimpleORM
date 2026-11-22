open Db

@scope("process") @val external exit: int => unit = "exit"

let main = async () => {
  let client = await connectToDb()

  let succeeded = try {
    await applyMigration(
      _ => Console.log("Migration applied successfully!"),
      err => Console.error2("Error applying migration:", err),
      client,
    )
    true
  } catch {
  | _ => false
  }

  // Always release the connection, otherwise the process never exits
  await closeConnection(client)
  if !succeeded {
    exit(1)
  }
}

main()
->Promise.catch(_ => {
  exit(1)
  Promise.resolve()
})
->ignore
