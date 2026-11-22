open Schema
open PgBind
open SqlEscape.SqlEscape

/**
 @param columnName column holding the reference
 @param referencedTable referenced table
 @param referencedColumn referenced column
 @return the FOREIGN KEY constraint of a CREATE TABLE
 */
let _foreignKeyToSql = (
  ~columnName: string,
  ~referencedTable: string,
  ~referencedColumn: string,
): string =>
  "\tFOREIGN KEY (" ++
  quoteIdentifier(columnName) ++
  ") REFERENCES " ++
  quoteIdentifier(referencedTable) ++
  "(" ++
  quoteIdentifier(referencedColumn) ++ ")"

/**
 @param schema columns of the table
 @param tableName table name
 @return one CREATE UNIQUE INDEX per unique column, idempotent
 */
let _uniqueIndexToSql = (schema: array<columnSchema>, tableName: string): string =>
  schema
  ->Array.filter(column => column.unique)
  ->Array.map(column =>
    "CREATE UNIQUE INDEX IF NOT EXISTS " ++
    quoteIdentifier(tableName ++ "_" ++ column.name ++ "_key") ++
    " ON " ++
    quoteIdentifier(tableName) ++
    "(" ++
    quoteIdentifier(column.name) ++ ");"
  )
  ->Array.join("\n")

/**
 Enum types are named after their column, with the first letter capitalized ("role" -> "Role").

 @param name column name
 @return the quoted enum type name
 */
let _customizedTypeToSql = (name: string): string =>
  quoteIdentifier(String.charAt(name, 0)->String.toUpperCase ++ String.sliceToEnd(name, ~start=1))

/**
 @param name column name, used to name enum types
 @param sqlType column type
 */
let _typeToSql = (name: string, sqlType: sqlType): string =>
  switch sqlType {
  | Int => "INTEGER"
  | String => "TEXT"
  | Enum(_) => _customizedTypeToSql(name)
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

let _defaultToSql = (column: columnSchema): string =>
  switch column.default {
  | Some(default) => " DEFAULT " ++ quoteLiteral(default)
  | None => ""
  }

// Dollar-quote tag of the DO blocks creating the enums
let _enumBlockTag = "$enum$"

/**
 Creates an enum type, skipped if it already exists so the migration can be replayed.

 @param name column name, used to name the type
 @param sqlType column type
 @return the DO block, or None if the type is not an enum
 @raise InvalidLiteral if a value contains the DO block tag
 */
let _createEnum = (name: string, sqlType: sqlType): option<string> =>
  switch sqlType {
  | Enum(values) =>
    let typeName = _customizedTypeToSql(name)
    let labels = values->Array.map(quoteLiteral)->Array.join(", ")
    if String.includes(typeName ++ labels, _enumBlockTag) {
      raise(InvalidLiteral(typeName ++ " " ++ labels))
    }
    Some(
      "DO " ++
      _enumBlockTag ++
      " BEGIN\n\tCREATE TYPE " ++
      typeName ++
      " AS ENUM (" ++
      labels ++
      ");\nEXCEPTION\n\tWHEN duplicate_object THEN NULL;\nEND " ++
      _enumBlockTag ++ ";",
    )
  | _ => None
  }

/**
 @param schema columns of the table
 @param foreignKeys optional foreign key constraints
 @return the body of a CREATE TABLE
 */
let _columnsToSql = (
  ~schema: array<columnSchema>,
  ~foreignKeys: option<array<foreignKey>>,
): string => {
  let columns = schema->Array.map(column => {
    let primaryKey = _primaryKeyToSql(column)
    // SERIAL gives the type, and a primary key is never NULL
    let (schemaType, optionnal) = switch primaryKey {
    | "" => (_typeToSql(column.name, column._type), _optionalToSql(column))
    | _ => ("", "")
    }
    "\t" ++
    quoteIdentifier(column.name) ++
    " " ++
    String.trimStart(schemaType ++ primaryKey ++ optionnal) ++
    _defaultToSql(column)
  })
  let constraints =
    foreignKeys
    ->Option.getOr([])
    ->Array.map(({columnName, referencedTable, referencedColumn}) =>
      _foreignKeyToSql(~columnName, ~referencedTable, ~referencedColumn)
    )
  columns->Array.concat(constraints)->Array.join(",\n")
}

@module("fs")
external writeFileSync: (string, string) => unit = "writeFileSync"

let _saveSchemaToFile = (~fileName: string, ~toWrite: string): bool => {
  writeFileSync(fileName, toWrite)
  Console.log("Saving schema to file " ++ fileName)
  true
}

/**
 Generates the migration SQL of a table: its enums, the table and its unique indexes.
 Every statement is idempotent, so the migration can be replayed.

 @param tableName table name
 @param schema columns of the table
 @param foreignKey optional foreign key constraints
 */
let createTable = (
  ~tableName: string,
  ~schema: array<columnSchema>,
  ~foreignKey: option<array<foreignKey>>,
): string => {
  let enums =
    schema
    ->Array.filterMap(column => _createEnum(column.name, column._type))
    ->Array.join("\n")
  let table =
    "CREATE TABLE IF NOT EXISTS " ++
    quoteIdentifier(tableName) ++
    " (\n" ++
    _columnsToSql(~schema, ~foreignKeys=foreignKey) ++ "\n);"
  [enums, table, _uniqueIndexToSql(schema, tableName)]
  ->Array.filter(statement => statement !== "")
  ->Array.join("\n")
  ->String.concat("\n")
}

// let dropTable = (~tableName: string): bool => true
// let updateTable = (~tableName: string, ~updates: columnSchema, ~conditions: columnSchema): bool =>
//   true

/**
 Saves the SQL to migration.sql, then runs it on the database.

 @param toWrite SQL generated by `createTable`
 @param client connected PostgreSQL client
 */
let migrate = (~toWrite: string, ~client: PgClient.t) => {
  _saveSchemaToFile(~fileName="migration.sql", ~toWrite)->ignore

  Console.log("Applying migration...")
  Console.log(toWrite)

  PgClient.Params.query(~statement=toWrite, ~params=[], client)
  ->Promise.then(_ => {
    Console.log("Migration applied")
    Promise.resolve()
  })
  ->Promise.catch(err => {
    Console.error("Failed to apply migration")
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
  migrate,
  // drop: (~tableName) => dropTable(~tableName),
  // update: (~tableName, ~updates, ~conditions) => updateTable(~tableName, ~updates, ~conditions),
}
