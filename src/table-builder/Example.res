open Builder

let userSchema = createTable(
  ~tableName="users",
  ~schema=[
    {
      name: "id",
      _type: "int",
      primaryKey: true,
      optionnal: false,
      default: "''",
    },
    {
      name: "name",
      _type: "string",
      primaryKey: false,
      optionnal: false,
      default: "''",
    },
    {
      name: "email",
      _type: "string",
      primaryKey: false,
      optionnal: false,
      default: "''",
    },
  ],
)

Console.log(userSchema)
