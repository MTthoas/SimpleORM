type sqlType =
  | Int
  | String
  | Enum(array<string>)

type foreignKey = {
  columnName: string,
  referencedTable: string,
  referencedColumn: string,
}

type columnSchema = {
  name: string,
  _type: sqlType,
  primaryKey: bool,
  optionnal: bool,
  default: option<string>,
  unique: bool,
}

type tableSchema = {
  tableName: string,
  schema: array<columnSchema>,
  foreignKeys: option<array<foreignKey>>,
}

type tableOperations = {
  create: (~tableSchema: tableSchema) => string,
  drop: (~tableName: string) => bool,
  update: (~tableName: string, ~updates: columnSchema, ~conditions: columnSchema) => bool,
}

type queryOperations = {
  select: (
    ~tableName: string,
    ~columns: array<string>,
    ~conditions: Js.Dict.t<string>,
  ) => Promise.t<Js.Dict.t<string>>,
  insert: (~tableName: string, ~data: Js.Dict.t<string>) => Promise.t<unit>,
  delete: (~tableName: string, ~conditions: Js.Dict.t<string>) => Promise.t<unit>,
}

type orm = {
  table: tableOperations,
  query: queryOperations,
}
