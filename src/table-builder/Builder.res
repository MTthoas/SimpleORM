open Schema

let _parseSchemaType = (schemaType: string): string => {
  switch schemaType {
  | "int" => "INTEGER"
  | "string" => "TEXT"
  | _ => failwith("Unsupported schema type: " ++ schemaType)
  }
}

let create = (~tableName, ~schema) => {
  Console.log("Creating table: " ++ tableName)
  let start = "CREATE TABLE " ++ tableName ++ " ("
  let columns =
    schema
    ->Array.map(column => {
      let val = _parseSchemaType(column._type)
      let primaryKey = if column.primaryKey {
        " PRIMARY KEY"
      } else {
        ""
      }
      let optionnal = if column.optionnal {
        " NOT NULL"
      } else {
        ""
      }
      let default = if column.default != "" {
        " DEFAULT " ++ column.default
      } else {
        ""
      }
      column.name ++ " " ++ val ++ primaryKey ++ optionnal ++ default
    })
    ->Array.join(", ")
  start ++ columns ++ ");"
}
