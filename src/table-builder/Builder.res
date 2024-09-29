open Schema

let _typeToSql = (schemaType: string): string => {
  switch schemaType {
  | "int" => "INTEGER"
  | "string" => "TEXT"
  | _ => failwith("Unsupported schema type: " ++ schemaType)
  }
}

let _primaryKeyToSql = (column: columnSchema): string =>
  switch column.primaryKey {
  | true => " PRIMARY KEY"
  | false => ""
  }

let _optionalToSql = (column: columnSchema): string =>
  switch column.optionnal {
  | true => " NULL"
  | false => " NOT NULL"
  }

let _defaultToSql = (column: columnSchema): string =>
  switch column.default {
  | "" => ""
  | default => " DEFAULT " ++ default
  }

let _columnsToSql = (~schema: array<columnSchema>): string =>
  schema
  ->Array.map(column => {
    let schemaType = _typeToSql(column._type)
    let primaryKey = _primaryKeyToSql(column)
    let optionnal = _optionalToSql(column)
    let default = _defaultToSql(column)
    "\t" ++ column.name ++ " " ++ schemaType ++ primaryKey ++ optionnal ++ default
  })
  ->Array.join(",\n")

let createTable = (~tableName: string, ~schema: array<columnSchema>): string => {
  let columnsToSql = _columnsToSql(~schema)
  "CREATE TABLE " ++ tableName ++ " (\n" ++ columnsToSql ++ "\n);"
}
/*
Result with the input in Example.res:
CREATE TABLE users (
      id INTEGER PRIMARY KEY NOT NULL DEFAULT '',
      name TEXT NOT NULL DEFAULT '',
      email TEXT NOT NULL DEFAULT ''
);
*/
