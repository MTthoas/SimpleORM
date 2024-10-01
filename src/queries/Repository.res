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
      let (_, params) = QueryBuilder._buildWhereClause(~where, ~startIndex=1)
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
    let _ = await QueryBuilder._executeQuery(~statement, ~params=values, client)
    /* Get users then */
    let users = await find(~tableName, client)
    Promise.resolve(users)
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

  /* Update records */
  let update = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    ~where: option<array<(string, Query.Params.t)>>=?,
    client: PgClient.t,
  ) => {
    let (statement, params) = await QueryBuilder._buildUpdateQuery(
      ~tableName,
      ~fields,
      ~values,
      ~where,
      client,
    )

    Js.log("Statement: " ++ statement)
    Js.log(params)

    let _ = await QueryBuilder._executeQuery(~statement, ~params, client)
    /* Get users then */
    let users = await find(~tableName, client)
    Promise.resolve(users)
  }

  /* Update by ID */
  let updateById = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    ~id: int,
    client: PgClient.t,
  ) => {
    let where = [("id", Query.Params.int(id))]
    update(~tableName, ~fields, ~values, ~where, client)
  }

  /* Delete records */
  let delete = async (
    ~tableName: string,
    ~where: option<array<(string, Query.Params.t)>>=?,
    client: PgClient.t,
  ) => {
    let (statement, params) = await QueryBuilder._buildDeleteQuery(~tableName, ~where, client)
    let _ = await QueryBuilder._executeQuery(~statement, ~params, client)
    /* Get users then */
    let users = await find(~tableName, client)
    Promise.resolve(users)
  }

  /* Delete by ID */
  let deleteById = async (~tableName: string, ~id: int, client: PgClient.t) => {
    let where = [("id", Query.Params.int(id))]
    delete(~tableName, ~where, client)
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
