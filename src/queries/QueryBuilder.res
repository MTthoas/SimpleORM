open PgBind
open SqlEscape

module QueryBuilder = {
  exception InvalidTableName(string)
  exception TableDoesNotExist(string)
  exception InvalidLimit(int)
  exception InvalidWhereCondition

  /**
   Turns any error raised while building or running a query into a readable message.

   @param err the caught exception (ReScript or JS)
   */
  let _errorMessage = (err: exn): string =>
    switch err {
    | TableDoesNotExist(tableName) => "Table " ++ tableName ++ " does not exist."
    | InvalidLimit(limit) => "Invalid limit: " ++ Int.toString(limit)
    | InvalidTableName(message) => "Invalid table name: " ++ message
    | InvalidWhereCondition => "Invalid WHERE condition."
    | SqlEscape.InvalidIdentifier(name) => "Invalid identifier: " ++ name
    | Failure(message) => message
    | Exn.Error(jsError) => Exn.message(jsError)->Option.getOr("Unknown JS error")
    | _ => "Unknown error"
    }

  /**
   Logs the error and raises it again as a `Failure`, so callers only have one exception to handle.

   @param err the caught exception
   @raise Failure always
   */
  let _fail = (err: exn) => {
    let message = _errorMessage(err)
    Console.error("Error: " ++ message)
    raise(Failure(message))
  }

  /**
   Checks that a table exists in the current search path.

   @param tableName exact (case-sensitive) table name
   @param client connected PostgreSQL client
   @raise TableDoesNotExist if the table cannot be found
   */
  let _checkIfTableExists = async (~tableName: string, client: PgClient.t): bool => {
    let statement = "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = $1 AND table_schema = ANY(current_schemas(false))) AS table_exists"
    let params = [Query.Params.string(tableName)]

    let result = await PgClient.Params.query(client, ~statement, ~params)
    switch result.rows[0]->Option.flatMap(row => row->Dict.get("table_exists")) {
    | Some(Js.Json.Boolean(true)) => true
    | Some(Js.Json.Boolean(false)) => raise(TableDoesNotExist(tableName))
    | _ => raise(Failure("Unexpected result format: missing or invalid 'table_exists' key."))
    }
  }

  /**
   Checks if a column exists in the given table.

   @param tableName exact (case-sensitive) table name
   @param columnName exact (case-sensitive) column name
   @param client connected PostgreSQL client
   */
  let _isColumnExists = async (
    ~tableName: string,
    ~columnName: string,
    client: PgClient.t,
  ): bool => {
    let statement = "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = $1 AND column_name = $2 AND table_schema = ANY(current_schemas(false))) AS column_exists"
    let params = [Query.Params.string(tableName), Query.Params.string(columnName)]

    let result = await PgClient.Params.query(client, ~statement, ~params)
    switch result.rows[0]->Option.flatMap(row => row->Dict.get("column_exists")) {
    | Some(Js.Json.Boolean(exists)) => exists
    | _ => raise(Failure("Unexpected result format: missing or invalid 'column_exists' key."))
    }
  }

  /**
   Checks that every field is an existing column of the table.

   @param tableName exact table name
   @param fields column names to check
   @param client connected PostgreSQL client
   @raise Failure on the first missing column
   */
  let _validateFields = async (~tableName: string, ~fields: array<string>, client: PgClient.t) => {
    let checks = await Promise.all(
      fields->Array.map(columnName => _isColumnExists(~tableName, ~columnName, client)),
    )
    checks->Array.forEachWithIndex((exists, index) =>
      if !exists {
        raise(
          Failure(
            "Column " ++ fields->Array.getUnsafe(index) ++ " does not exist in table " ++ tableName,
          ),
        )
      }
    )
  }

  /**
   @param tableName table name to check
   @raise InvalidTableName if the name is empty
   */
  let _assertTableName = (~tableName: string) =>
    if tableName === "" {
      raise(InvalidTableName("Table name cannot be empty"))
    }

  /**
   @param limit optional LIMIT value
   @raise InvalidLimit if the limit is negative
   */
  let _assertLimit = (~limit: option<int>) =>
    switch limit {
    | Some(limit) if limit < 0 => raise(InvalidLimit(limit))
    | _ => ()
    }

  /**
   Returns the conditions of a mandatory WHERE clause (UPDATE / DELETE),
   to never touch a whole table by mistake.

   @param where WHERE conditions as (column, value) pairs
   @raise InvalidWhereCondition if there is no condition
   */
  let _requireWhere = (~where: option<array<(string, Query.Params.t)>>) =>
    switch where {
    | Some(conditions) if conditions->Array.length > 0 => conditions
    | _ => raise(InvalidWhereCondition)
    }

  /**
   Builds the WHERE clause and its bound parameters. Column names are quoted,
   values are never inlined in the SQL.

   @param where WHERE conditions as (column, value) pairs, joined with AND
   @param startIndex index of the first placeholder ($1, $2, ...)
   @return (" WHERE ...", params), or ("", []) if there is no condition
   */
  let _buildWhereClause = (~where: option<array<(string, Query.Params.t)>>, ~startIndex: int) =>
    switch where {
    | Some(conditions) if conditions->Array.length > 0 =>
      let clauses =
        conditions->Array.mapWithIndex(((field, _), index) =>
          SqlEscape.quoteIdentifier(field) ++ " = $" ++ Int.toString(index + startIndex)
        )
      let params = conditions->Array.map(((_, value)) => value)
      (" WHERE " ++ clauses->Array.join(" AND "), params)
    | _ => ("", [])
    }

  /**
   @param limit optional LIMIT value
   @return " LIMIT n", or "" if there is no limit
   */
  let _buildLimitClause = (~limit: option<int>) =>
    switch limit {
    | Some(limit) => " LIMIT " ++ Int.toString(limit)
    | None => ""
    }

  /**
   Builds a SELECT query after checking that the table exists.

   @param tableName exact table name
   @param where optional WHERE conditions
   @param limit optional maximum number of rows, must be >= 0
   @param client connected PostgreSQL client
   @return (statement, params)
   @raise Failure if the table or the arguments are invalid
   */
  let _buildSelectQuery = async (
    ~tableName: string,
    ~where: option<array<(string, Query.Params.t)>>,
    ~limit: option<int>,
    client: PgClient.t,
  ): (string, array<Query.Params.t>) =>
    try {
      _assertTableName(~tableName)
      _assertLimit(~limit)
      let _ = await _checkIfTableExists(~tableName, client)

      let (whereClause, params) = _buildWhereClause(~where, ~startIndex=1)
      let statement =
        "SELECT * FROM " ++
        SqlEscape.quoteIdentifier(tableName) ++
        whereClause ++
        _buildLimitClause(~limit)
      (statement, params)
    } catch {
    | err => _fail(err)
    }

  /**
   Builds an INSERT query returning the inserted row.

   @param tableName exact table name
   @param fields columns to fill
   @param values values bound to `fields`, in the same order
   @param client connected PostgreSQL client
   @raise Failure if the table, the columns or the arguments are invalid
   */
  let _buildInsertQuery = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ): string =>
    try {
      _assertTableName(~tableName)
      if fields->Array.length === 0 || values->Array.length === 0 {
        raise(Failure("Fields or values cannot be empty"))
      }
      if fields->Array.length !== values->Array.length {
        raise(Failure("The number of fields and values do not match"))
      }
      let _ = await _checkIfTableExists(~tableName, client)
      await _validateFields(~tableName, ~fields, client)

      let columns = fields->Array.map(SqlEscape.quoteIdentifier)->Array.join(", ")
      let placeholders =
        values->Array.mapWithIndex((_, index) => "$" ++ Int.toString(index + 1))->Array.join(", ")
      "INSERT INTO " ++
      SqlEscape.quoteIdentifier(tableName) ++
      " (" ++
      columns ++
      ") VALUES (" ++
      placeholders ++ ") RETURNING *"
    } catch {
    | err => _fail(err)
    }

  /**
   Builds an UPDATE query returning the updated rows. A WHERE clause is mandatory.

   @param tableName exact table name
   @param fields columns to update
   @param values new values bound to `fields`, in the same order
   @param where WHERE conditions, at least one
   @param client connected PostgreSQL client
   @return (statement, params) where params = values followed by the WHERE values
   @raise Failure if the table, the columns or the arguments are invalid
   */
  let _buildUpdateQuery = async (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    ~where: option<array<(string, Query.Params.t)>>,
    client: PgClient.t,
  ): (string, array<Query.Params.t>) =>
    try {
      _assertTableName(~tableName)
      if fields->Array.length === 0 || values->Array.length === 0 {
        raise(Failure("Fields or values cannot be empty"))
      }
      if fields->Array.length !== values->Array.length {
        raise(Failure("The number of fields and values do not match"))
      }
      let conditions = _requireWhere(~where)
      let _ = await _checkIfTableExists(~tableName, client)
      await _validateFields(~tableName, ~fields, client)

      let setClause =
        fields
        ->Array.mapWithIndex((field, index) =>
          SqlEscape.quoteIdentifier(field) ++ " = $" ++ Int.toString(index + 1)
        )
        ->Array.join(", ")
      let (whereClause, whereParams) = _buildWhereClause(
        ~where=Some(conditions),
        ~startIndex=fields->Array.length + 1,
      )
      let statement =
        "UPDATE " ++
        SqlEscape.quoteIdentifier(tableName) ++
        " SET " ++
        setClause ++
        whereClause ++ " RETURNING *"
      (statement, values->Array.concat(whereParams))
    } catch {
    | err => _fail(err)
    }

  /**
   Builds a DELETE query returning the deleted rows. A WHERE clause is mandatory.

   @param tableName exact table name
   @param where WHERE conditions, at least one
   @param client connected PostgreSQL client
   @return (statement, params)
   @raise Failure if the table or the arguments are invalid
   */
  let _buildDeleteQuery = async (
    ~tableName: string,
    ~where: option<array<(string, Query.Params.t)>>,
    client: PgClient.t,
  ): (string, array<Query.Params.t>) =>
    try {
      _assertTableName(~tableName)
      let conditions = _requireWhere(~where)
      let _ = await _checkIfTableExists(~tableName, client)

      let (whereClause, params) = _buildWhereClause(~where=Some(conditions), ~startIndex=1)
      (
        "DELETE FROM " ++ SqlEscape.quoteIdentifier(tableName) ++ whereClause ++ " RETURNING *",
        params,
      )
    } catch {
    | err => _fail(err)
    }

  /**
   Runs a parameterized query.

   @param statement SQL with $1, $2... placeholders
   @param params values bound to the placeholders
   @param client connected PostgreSQL client
   @raise Failure if PostgreSQL rejects the query
   */
  let _executeQuery = async (
    ~statement: string,
    ~params: array<Query.Params.t>,
    client: PgClient.t,
  ): PgResult.t<Js.Json.t> => {
    Console.log("Executing query: " ++ statement)
    try {
      await PgClient.Params.query(client, ~statement, ~params)
    } catch {
    | err => _fail(Failure("Query execution error: " ++ _errorMessage(err)))
    }
  }
}
