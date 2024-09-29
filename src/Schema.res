type columnSchema = {
  name: string,
  _type: string,
  primaryKey: bool,
  optionnal: bool,
  default: string,
}

type tableSchema = {
  tableName: string,
  schema: array<columnSchema>,
}

type tableOperations = {
  create: (~tableName: string, ~schema: array<columnSchema>) => bool,
  drop: (~tableName: string) => Promise.t<unit>,
  update: (
    ~tableName: string,
    ~updates: columnSchema,
    ~conditions: columnSchema,
  ) => Promise.t<unit>,
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
