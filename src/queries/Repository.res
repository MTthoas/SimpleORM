open PgBind
open QueryBuilder

module Repository = {
  exception InvalidTableName(string)
  exception TableDoesNotExist(string)
  exception InvalidLimit(int)
  exception InvalidWhereCondition

  /* Generic function to find records in a PostgreSQL table */
  let find = async (
    ~tableName: string,
    ~where: option<array<(string, Query.Params.t)>>=?,
    ~limit: option<int>=?,
    client: PgClient.t,
  ) => {
    try {
      let (_, params) = QueryBuilder._buildWhereClause(~where)
      let statement = await QueryBuilder._buildSelectQuery(~tableName, ~where, ~limit, client)
      let result = await QueryBuilder._executeQuery(~statement, ~params, client)
      Promise.resolve(result.rows)
    } catch {
    | TableDoesNotExist(tableName) =>
      let errorMsg = "Table " ++ tableName ++ " does not exist."
      Promise.reject(Failure(errorMsg))
    | InvalidLimit(limit) =>
      let errorMsg = "Invalid limit: " ++ Js.Int.toString(limit)
      Js.log("Error: " ++ errorMsg)
      Promise.reject(Failure(errorMsg))
    | InvalidTableName(message) =>
      let errorMsg = "Invalid table name: " ++ message
      Js.log("Error: " ++ errorMsg)
      Promise.reject(Failure(errorMsg))
    | InvalidWhereCondition =>
      let errorMsg = "Invalid WHERE condition."
      Js.log("Error: " ++ errorMsg)
      Promise.reject(Failure(errorMsg))
    | Failure(message) =>
      Js.log("Error: " ++ message)
      Promise.reject(Failure(message))
    | Exn.Error(jsError) =>
      let errorMessage = switch Exn.message(jsError) {
      | Some(message) => message
      | None => "Unknown JS error"
      }
      Js.log("Error: " ++ errorMessage)
      Promise.reject(Failure(errorMessage))
    | _ => Promise.reject(Failure("Unknown error"))
    }
  }

  /* Find a single record */
  let findOne = async (
    ~tableName: string,
    ~where: array<(string, Query.Params.t)>,
    client: PgClient.t,
  ) => {
    find(~tableName, ~where, ~limit=1, client)
  }

  /* Insert records into a PostgreSQL table */
  let insert = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ) => {
    let statement = await QueryBuilder._buildInsertQuery(~tableName, ~fields, ~values, client)
    let insert = await QueryBuilder._executeQuery(~statement, ~params=values, client)
    Promise.resolve(insert)
  }

  /* Insert a single record */
  let insertOne = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ) => {
    insert(~tableName, ~fields, ~values, client)
  }

  /* Update a PostgreSQL table */
  let save = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ) => {
    let statement = await QueryBuilder._buildInsertQuery(~tableName, ~fields, ~values, client)
    await QueryBuilder._executeQuery(~statement, ~params=values, client)
  }
}
