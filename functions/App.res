open User
open Db
open PgBind

let testUser = async () => {
  Js.log("Functionnal test for the User module, calling Repository functions")
  /* Connection to the DB */
  let client = await connectToDb()

  /* Get users */
  let users = await User.getUsers(~limit=2, client)
  Js.log(users)

  /* Get user by ID */
  let userById = await User.getUserById(~id=1, client)
  Js.log(userById)

  /* Create a user */
  let createUser = await User.createUser(
    ~fields=["name", "email"],
    ~values=[Query.Params.string("John Doe"), Query.Params.string("johnDoe@gmail.com")],
    client,
  )
  Js.log(createUser)

  /* Update user */
  let updateUser = await User.updateUser(
    ~fields=["name"],
    ~values=[Query.Params.string("Jane Doe for ID 1")],
    ~where=[("id", Query.Params.int(12))],
    client,
  )
  Js.log(updateUser)

  /* Update user by id, its more simple to use */
  let updateUserById = await User.updateUserById(
    ~fields=["name"],
    ~values=[Query.Params.string("Vans 1")],
    ~id=14,
    client,
  )
  Js.log(updateUserById)

  /* Delete user */
  let deleteUser = await User.deleteUserById(~id=15, client)
  Js.log(deleteUser)

  /* Close the connection */
  await closeConnection(client)
}

testUser()->ignore
