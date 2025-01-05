open Builder
open Schema
open Db
open User
open PgBind

let userSchema: tableSchema = {
  tableName: "users",
  schema: [
    {
      name: "id",
      _type: Int,
      primaryKey: true,
      optionnal: false,
      default: None,
      unique: false,
    },
    {
      name: "name",
      _type: String,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: true,
    },
    {
      name: "email",
      _type: String,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: true,
    },
    {
      name: "role",
      _type: Enum(["USER", "ADMIN"]),
      primaryKey: false,
      optionnal: false,
      default: Some("USER"),
      unique: false,
    },
    {
      name: "status",
      _type: Enum(["BANNED", "STANDARD", "PREMIUM"]),
      primaryKey: false,
      optionnal: true,
      default: None,
      unique: false,
    },
  ],
  foreignKeys: None,
}

let postSchema: tableSchema = {
  tableName: "posts",
  schema: [
    {
      name: "id",
      _type: Int,
      primaryKey: true,
      optionnal: false,
      default: None,
      unique: false,
    },
    {
      name: "user_id",
      _type: Int,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: false, // user_id will not be unique since multiple posts can belong to one user
    },
    {
      name: "title",
      _type: String,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: false,
    },
    {
      name: "content",
      _type: String,
      primaryKey: false,
      optionnal: true,
      default: None,
      unique: false,
    },
  ],
  foreignKeys: Some([
    {
      columnName: "user_id",
      referencedTable: "users",
      referencedColumn: "id",
    },
  ]),
}

let userSQL = tableOperations.create(~tableSchema=userSchema)
let userPostSQL = tableOperations.create(~tableSchema=postSchema)

let testUser = async () => {
  let client = await connectToDb()
  await tableOperations.migrate(~toWrite=userSQL ++ userPostSQL, ~client)

  let createUser = await User.createUser(
    ~fields=["name", "email"],
    ~values=[Query.Params.string("John Doe"), Query.Params.string("johnDoe@gmail.com")],
    client,
  )
  Console.log(createUser)

  let users = await User.getUsers(~limit=2, client)
  Console.log(users)

  let userById = await User.getUserById(~id=1, client)
  Console.log(userById)

  let updateUser = await User.updateUser(
    ~fields=["name"],
    ~values=[Query.Params.string("Jane Doe for ID 1")],
    ~where=[("id", Query.Params.int(12))],
    client,
  )
  Console.log(updateUser)

  let updateUserById = await User.updateUserById(
    ~fields=["name"],
    ~values=[Query.Params.string("Vans 1")],
    ~id=14,
    client,
  )
  Console.log(updateUserById)

  let deleteUser = await User.deleteUserById(~id=15, client)
  Console.log(deleteUser)

  await closeConnection(client)
}

testUser()->ignore
