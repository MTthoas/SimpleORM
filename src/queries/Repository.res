open PgBind
open QueryBuilder

module Repository = {
  /**
   Finds rows in a PostgreSQL table.

   @param tableName exact table name
   @param where optional WHERE conditions as (column, value) pairs, joined with AND
   @param limit optional maximum number of rows, must be >= 0
   @param client connected PostgreSQL client
   @raise Failure if the query cannot be built or executed
   */
  let find = async (
    ~tableName: string,
    ~where: option<array<(string, Query.Params.t)>>=?,
    ~limit: option<int>=?,
    client: PgClient.t,
  ): array<Js.Json.t> => {
    let (statement, params) = await QueryBuilder._buildSelectQuery(
      ~tableName,
      ~where,
      ~limit,
      client,
    )
    let result = await QueryBuilder._executeQuery(~statement, ~params, client)
    result.rows
  }

  /**
   Finds the first row matching the conditions.

   @param tableName exact table name
   @param where WHERE conditions as (column, value) pairs, joined with AND
   @param client connected PostgreSQL client
   @return the row, or None if nothing matches
   */
  let findOne = async (
    ~tableName: string,
    ~where: array<(string, Query.Params.t)>,
    client: PgClient.t,
  ): option<Js.Json.t> => {
    let rows = await find(~tableName, ~where, ~limit=1, client)
    rows[0]
  }

  /**
   Inserts a row.

   @param tableName exact table name
   @param fields columns to fill
   @param values values bound to `fields`, in the same order
   @param client connected PostgreSQL client
   @return the inserted rows
   */
  let insert = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ): array<Js.Json.t> => {
    let statement = await QueryBuilder._buildInsertQuery(~tableName, ~fields, ~values, client)
    let result = await QueryBuilder._executeQuery(~statement, ~params=values, client)
    result.rows
  }

  /**
   Inserts a single row.

   @param tableName exact table name
   @param fields columns to fill
   @param values values bound to `fields`, in the same order
   @param client connected PostgreSQL client
   @return the inserted row
   */
  let insertOne = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ): option<Js.Json.t> => {
    let rows = await insert(~tableName, ~fields, ~values, client)
    rows[0]
  }

  /**
   Updates the rows matching the conditions. A WHERE clause is mandatory.

   @param tableName exact table name
   @param fields columns to update
   @param values new values bound to `fields`, in the same order
   @param where WHERE conditions, at least one
   @param client connected PostgreSQL client
   @return the updated rows
   */
  let update = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    ~where: option<array<(string, Query.Params.t)>>=?,
    client: PgClient.t,
  ): array<Js.Json.t> => {
    let (statement, params) = await QueryBuilder._buildUpdateQuery(
      ~tableName,
      ~fields,
      ~values,
      ~where,
      client,
    )
    let result = await QueryBuilder._executeQuery(~statement, ~params, client)
    result.rows
  }

  /**
   Updates a row by its `id` column.

   @param tableName exact table name
   @param fields columns to update
   @param values new values bound to `fields`, in the same order
   @param id value of the `id` column
   @param client connected PostgreSQL client
   @return the updated row, or None if no row has this id
   */
  let updateById = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    ~id: int,
    client: PgClient.t,
  ): option<Js.Json.t> => {
    let where = [("id", Query.Params.int(id))]
    let rows = await update(~tableName, ~fields, ~values, ~where, client)
    rows[0]
  }

  /**
   Deletes the rows matching the conditions. A WHERE clause is mandatory.

   @param tableName exact table name
   @param where WHERE conditions, at least one
   @param client connected PostgreSQL client
   @return the deleted rows
   */
  let delete = async (
    ~tableName: string,
    ~where: option<array<(string, Query.Params.t)>>=?,
    client: PgClient.t,
  ): array<Js.Json.t> => {
    let (statement, params) = await QueryBuilder._buildDeleteQuery(~tableName, ~where, client)
    let result = await QueryBuilder._executeQuery(~statement, ~params, client)
    result.rows
  }

  /**
   Deletes a row by its `id` column.

   @param tableName exact table name
   @param id value of the `id` column
   @param client connected PostgreSQL client
   @return the deleted row, or None if no row has this id
   */
  let deleteById = async (~tableName: string, ~id: int, client: PgClient.t): option<Js.Json.t> => {
    let where = [("id", Query.Params.int(id))]
    let rows = await delete(~tableName, ~where, client)
    rows[0]
  }
}
