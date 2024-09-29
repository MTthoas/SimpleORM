open User
open Db
open PgBind

let testUser = async () => {
  Js.log("Test de la fonction find")
  let client = await connectToDb()
  let users = await User.getUsers(~limit=2, client)
  Js.log(users)
  let userById = await User.getUserById(~id=1, client)
  let createUser = await User.createUser(
    ~fields=["name", "email"],
    ~values=[Query.Params.string("John Doe"), Query.Params.string("johnDoe@gmail.com")],
    client,
  )
  createUser
}

testUser()->ignore
