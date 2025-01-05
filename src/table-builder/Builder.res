open Schema
open PgBind

let _foreignKeyToSql = (
  ~columnName: string,
  ~referencedTable: string,
  ~referencedColumn: string,
): string =>
  ",\n\tFOREIGN KEY (\"" ++
  columnName ++
  "\") REFERENCES \"" ++
  referencedTable ++
  "\"(\"" ++
  referencedColumn ++ "\")"

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
  | true => " SERIAL PRIMARY KEY"
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

let _columnsToSql = (
  ~schema: array<columnSchema>,
  ~foreignKeys: option<array<foreignKey>>,
): string =>
  schema
  ->Array.map(column => {
    let primaryKey = _primaryKeyToSql(column)
    // Ne pas inclure "NULL" ou "NOT NULL" si c'est une primary key
    let schemaType = switch primaryKey {
    | "" => _typeToSql(column.name, column._type)
    | _ => "" // Pas de NULL ou NOT NULL pour les clés primaires
    }
    let optionnal = switch primaryKey {
    | "" => _optionalToSql(column)
    | _ => "" // Pas de NULL ou NOT NULL pour les clés primaires
    }
    let default = _defaultToSql(column)
    switch default {
    | Some(d) => "\t\"" ++ column.name ++ "\" " ++ schemaType ++ primaryKey ++ optionnal ++ d
    | None => "\t\"" ++ column.name ++ "\" " ++ schemaType ++ primaryKey ++ optionnal
    }
  })
  ->Array.join(",\n") ++
    switch foreignKeys {
    | Some(keys) =>
      keys
      ->Array.map(({columnName, referencedTable, referencedColumn}) =>
        _foreignKeyToSql(~columnName, ~referencedTable, ~referencedColumn)
      )
      ->Array.join(",\n")
    | None => ""
    }

@module("fs")
external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs")
external readFileSync: string => string = "readFileSync"

let _saveSchemaToFile = (~fileName: string, ~toWrite: string): bool => {
  writeFileSync(fileName, toWrite)
  Console.log("Saving schema to file " ++ fileName)
  true
}

let createTable = (
  ~tableName: string,
  ~schema: array<columnSchema>,
  ~foreignKey: option<array<foreignKey>>,
): string => {
  let uniqueIndexes = _uniqueIndexToSql(schema, tableName)
  let columnsToSql = _columnsToSql(~schema, ~foreignKeys=foreignKey)
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
  let userSchema = "\n" ++ "CREATE TABLE \"" ++ tableName ++ "\" (\n" ++ columnsToSql ++ "\n);\n"
  roles ++ "\n" ++ userSchema ++ "\n" ++ uniqueIndexes
}

// let dropTable = (~tableName: string): bool => true
// let updateTable = (~tableName: string, ~updates: columnSchema, ~conditions: columnSchema): bool =>
//   true

let migrate = (~toWrite: string, ~client: PgClient.t) => {
  _saveSchemaToFile(~fileName="migration.sql", ~toWrite)->ignore
  let migrationSQL = Buffer.fromString(readFileSync("migration.sql"))->Buffer.toString

  Console.log("Applying migration...")
  Console.log(migrationSQL)

  PgClient.Params.query(~statement=migrationSQL, ~params=[], client)
  ->Promise.then(_ => {
    Console.log("Migration applied")
    Promise.resolve()
  })
  ->Promise.catch(err => {
    Console.log("Failed to apply migration")
    Promise.reject(err)
  })
}

let tableOperations: tableOperations = {
  create: (~tableSchema) =>
    createTable(
      ~tableName=tableSchema.tableName,
      ~schema=tableSchema.schema,
      ~foreignKey=tableSchema.foreignKeys,
    ),
  migrate: (~toWrite: string, ~client: PgClient.t) =>
    migrate(~toWrite: string, ~client: PgClient.t),
  // drop: (~tableName) => dropTable(~tableName),
  // update: (~tableName, ~updates, ~conditions) => updateTable(~tableName, ~updates, ~conditions),
}
