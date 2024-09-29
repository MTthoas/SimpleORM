open Schema

let _uniqueIndexToSql = (schema: array<columnSchema>, tableName: string): string => {
  schema
  ->Array.filter(column => column.unique == true)
  ->Array.map(column =>
    "CREATE UNIQUE INDEX " ++
    tableName ++
    "_" ++
    column.name ++
    "_key ON \"" ++
    tableName ++
    "\"(\"" ++
    column.name ++ "\");"
  )
  ->Array.join("\n")
}

let _customizedTypeToSql = (name: string): string =>
  "\"" ++
  switch String.get(name, 0) {
  | Some(char) => String.toUpperCase(char)
  | None => ""
  } ++
  String.slice(name, ~start=1, ~end=String.length(name)) ++ "\""

let _typeToSql = (name: string, sqlType: sqlType): string => {
  switch sqlType {
  | Int => "INTEGER"
  | String => "TEXT"
  | Enum(_) => _customizedTypeToSql(name)
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

let _defaultToSql = (column: columnSchema): option<string> =>
  switch column.default {
  | Some(default) => Some(" DEFAULT " ++ "\'" ++ default ++ "\'")
  | None => None
  }

let _createEnum = (name: string, sqlType: sqlType): option<string> => {
  switch sqlType {
  | Enum(values) =>
    Some(
      "CREATE TYPE " ++
      _customizedTypeToSql(name) ++
      " AS ENUM (\'" ++
      Array.join(values, "\', \'") ++ "\');",
    )
  | _ => None
  }
}

let _columnsToSql = (~schema: array<columnSchema>): string =>
  schema
  ->Array.map(column => {
    let schemaType = _typeToSql(column.name, column._type)
    let primaryKey = _primaryKeyToSql(column)
    let optionnal = _optionalToSql(column)
    let default = _defaultToSql(column)
    switch default {
    | Some(d) => "\t" ++ column.name ++ " " ++ schemaType ++ primaryKey ++ optionnal ++ d
    | None => "\t" ++ column.name ++ " " ++ schemaType ++ primaryKey ++ optionnal
    }
  })
  ->Array.join(",\n")

let createTable = (~tableName: string, ~schema: array<columnSchema>): (string, string, string) => {
  let uniqueIndexes = _uniqueIndexToSql(schema, tableName)
  let columnsToSql = _columnsToSql(~schema)
  let roles =
    Array.map(schema, column => {
      switch column._type {
      | Enum(_) => _createEnum(column.name, column._type)
      | _ => None
      }
    })
    ->Array.filter(x => x->Belt.Option.isSome)
    ->Array.map(x => x->Belt.Option.getExn)
    ->Array.join("\n")
  (roles, "CREATE TABLE " ++ tableName ++ " (\n" ++ columnsToSql ++ "\n);", uniqueIndexes)
}
/*
Result with the input in Example.res:
CREATE TYPE "Role" AS ENUM ('USER', 'ADMIN');
CREATE TYPE "Status" AS ENUM ('BANNED', 'STANDARD', 'PREMIUM');
CREATE TABLE users (
        id INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role "Role" NOT NULL DEFAULT 'USER',
        status "Status" NULL
);
CREATE UNIQUE INDEX User_name_key ON "User"("name");
CREATE UNIQUE INDEX User_email_key ON "User"("email");
*/
