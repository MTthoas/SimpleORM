open ColumnType
open ForeignKeyType

module EntityType = {
  // Generic type
  type t = {
    name: string,
    fields: array<string>,
  }

  let user: t = {
    name: "users",
    fields: ["id", "name", "email"],
  }
}
