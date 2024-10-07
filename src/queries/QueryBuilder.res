open PgBind

module QueryBuilder = {
  exception InvalidTableName(string)
  exception TableDoesNotExist(string)
  exception InvalidLimit(int)
  exception InvalidWhereCondition

  /* Check if a table exists, otherwise raise an error */
  let _checkIfTableExists = (~tableName: string, client: PgClient.t): Promise.t<bool> => {
    let statement = "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = $1) AS table_exists"
    let params: array<Query.Params.t> = [Query.Params.string(tableName)]

    PgClient.Params.query(client, ~statement, ~params)
    ->Promise.then(result => {
      switch result.rows->Belt.Array.get(0) {
      | Some(row) =>
        switch Js.Dict.get(row, "table_exists") {
        | Some(Js.Json.Boolean(true)) => Promise.resolve(true) // Table exists
        | Some(Js.Json.Boolean(false)) => Promise.reject(TableDoesNotExist(tableName)) // Raise exception if the table doesn't exist
        | _ => {
            let errMsg = "Unexpected result format: missing or invalid 'table_exists' key."
            Promise.reject(Failure(errMsg))
          }
        }
      | None => {
          let errMsg = "Unexpected result format: No rows returned"
          Promise.reject(Failure(errMsg))
        }
      }
    })
    ->Promise.catch(err => {
      Promise.reject(err)
    })
  }

  let _isTableValid = (~tableName: string) => {
    if tableName === "" {
      raise(InvalidTableName("Table name cannot be empty")) // Raise exception if table name is invalid
    } else {
      true
    }
  }

  let _isWhereValid = (~where: option<array<(string, Query.Params.t)>>) => {
    switch where {
    | Some(conditions) =>
      if conditions->Array.length === 0 {
        raise(InvalidWhereCondition) // Raise exception if WHERE condition is empty
      } else {
        true
      }
    | None => true
    }
  }

  /* Check if a column exists in the specified table */
  let _isColumnExists = (~tableName: string, ~columnName: string, client: PgClient.t): Promise.t<
    bool,
  > => {
    let statement = "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = $1 AND column_name = $2) AS column_exists"
    let params: array<Query.Params.t> = [
      Query.Params.string(tableName),
      Query.Params.string(columnName),
    ]

    PgClient.Params.query(client, ~statement, ~params)
    ->Promise.then(result => {
      switch result.rows->Belt.Array.get(0) {
      | Some(row) =>
        switch Js.Dict.get(row, "column_exists") {
        | Some(Js.Json.Boolean(true)) => Promise.resolve(true) // Column exists
        | Some(Js.Json.Boolean(false)) => Promise.resolve(false) // Column doesn't exist
        | _ => {
            let errMsg = "Unexpected result format: missing or invalid 'column_exists' key."
            Promise.reject(Failure(errMsg))
          }
        }
      | None => {
          let errMsg = "Unexpected result format: No rows returned"
          Promise.reject(Failure(errMsg))
        }
      }
    })
    ->Promise.catch(err => {
      Promise.reject(err)
    })
  }

  /* Validate that all fields exist in the table */
  let _validateFields = (~tableName: string, ~fields: array<string>, client: PgClient.t) => {
    Promise.all(
      fields->Belt.Array.map(field =>
        _isColumnExists(~tableName, ~columnName=field, client)->Promise.then(columnExists =>
          if columnExists {
            Promise.resolve(true)
          } else {
            Promise.reject(Failure("Column " ++ field ++ " does not exist in table " ++ tableName))
          }
        )
      ),
    )
  }

  /* Build the WHERE clause with a starting index for placeholders */
  let _buildWhereClause = (~where: option<array<(string, Query.Params.t)>>, ~startIndex: int) => {
    switch where {
    | Some(conditions) =>
      if conditions->Array.length > 0 {
        let clauses =
          conditions->Belt.Array.mapWithIndex((index, (field, _)) =>
            field ++ " = $" ++ Js.Int.toString(index + startIndex)
          )
        let whereClause = " WHERE " ++ clauses->Array.join(" AND ")
        let params = conditions->Array.map(((_, value)) => value)
        (whereClause, params)
      } else {
        ("", []) // No WHERE clause if no conditions
      }
    | None => ("", [])
    }
  }

  /* Build the LIMIT clause if a limit is present */
  let _buildLimitClause = (~limit: option<int>) => {
    switch limit {
    | Some(limit) => " LIMIT " ++ Js.Int.toString(limit)
    | None => ""
    }
  }

  let _buildSelectQuery = (
    ~tableName: string,
    ~where: option<array<(string, Query.Params.t)>>,
    ~limit: option<int>,
    client: PgClient.t,
  ) => {
    _checkIfTableExists(~tableName, client)
    ->Promise.then(_ => {
      let baseQuery = "SELECT * FROM " ++ tableName
      let (whereClause, _) = _buildWhereClause(~where, ~startIndex=1)
      let limitClause = _buildLimitClause(~limit)

      let finalQuery = baseQuery ++ whereClause ++ limitClause
      Js.log("SELECT QUERY: " ++ finalQuery)
      Promise.resolve(finalQuery)
    })
    ->Promise.catch(err => {
      // Handle exceptions in ReScript and JS
      let errMessage = switch err {
      | TableDoesNotExist(tableName) => "Table " ++ tableName ++ " does not exist."
      | InvalidLimit(limit) => "Invalid limit: " ++ Js.Int.toString(limit)
      | InvalidTableName(message) => "Invalid table name: " ++ message
      | InvalidWhereCondition => "Invalid WHERE condition."
      | Exn.Error(jsError) =>
        switch Exn.message(jsError) {
        | Some(message) => message
        | None => "Unknown JS error"
        }
      | _ => "Unknown error"
      }

      Js.log("Error occurred: " ++ errMessage)
      // Reject with the constructed error message
      raise(Failure(errMessage))
    })
  }

  /* Build an INSERT query with table name validation */
  let _buildInsertQuery = (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ): Promise.t<string> => {
    // Check if the table exists before building the query
    _checkIfTableExists(~tableName, client)
    ->Promise.then(_ => {
      _validateFields(~tableName, ~fields, client)
    })
    ->Promise.then(_ => {
      // Validate that fields and values match
      if fields->Array.length === 0 || values->Array.length === 0 {
        Promise.reject(Failure("Fields or values cannot be empty"))
      } else if fields->Array.length !== values->Array.length {
        Promise.reject(Failure("The number of fields and values do not match"))
      } else {
        // Build the insert query
        let baseQuery =
          "INSERT INTO " ++ tableName ++ " (" ++ fields->Array.join(", ") ++ ") VALUES ("
        let valuePlaceholders =
          values->Belt.Array.mapWithIndex((index, _) => "$" ++ Js.Int.toString(index + 1))
        let query = baseQuery ++ valuePlaceholders->Array.join(", ") ++ ") RETURNING *"
        Promise.resolve(query)
      }
    })
    ->Promise.catch(err => {
      let errMessage = switch err {
      | Failure(message) => message
      | _ => "Unknown error during insert query construction"
      }
      Js.log("Error: " ++ errMessage)
      Promise.reject(Failure(errMessage))
    })
  }

  /* Build an UPDATE query with a WHERE clause and validation */
  let _buildUpdateQuery = (
    ~tableName: string,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    ~where: option<array<(string, Query.Params.t)>>,
    client: PgClient.t,
  ): Promise.t<(string, array<Query.Params.t>)> => {
    // Check if the table exists before building the query
    _checkIfTableExists(~tableName, client)
    ->Promise.then(_ => {
      // Validate the fields exist in the table
      _validateFields(~tableName, ~fields, client)
    })
    ->Promise.then(_ => {
      // Validate that fields and values match
      if fields->Array.length === 0 || values->Array.length === 0 {
        Promise.reject(Failure("Fields or values cannot be empty"))
      } else if fields->Array.length !== values->Array.length {
        Promise.reject(Failure("The number of fields and values do not match"))
      } else {
        // Build the base update query
        let baseQuery = "UPDATE " ++ tableName ++ " SET "

        // Construct the SET clause
        let setClause =
          fields
          ->Belt.Array.mapWithIndex((index, field) => field ++ " = $" ++ Js.Int.toString(index + 1))
          ->Array.join(", ")

        // Construct the WHERE clause
        let (whereClause, whereParams) = _buildWhereClause(
          ~where,
          ~startIndex=fields->Array.length + 1,
        )
        Js.log("WHERE CLAUSE: " ++ whereClause)

        // Combine the SET and WHERE clauses
        let query = baseQuery ++ setClause ++ whereClause ++ " RETURNING *"

        Promise.resolve((query, values->Array.concat(whereParams)))
      }
    })
    ->Promise.catch(err => {
      let errMessage = switch err {
      | Failure(message) => message
      | _ => "Unknown error during update query construction"
      }
      Js.log("Error: " ++ errMessage)
      Promise.reject(Failure(errMessage))
    })
  }

  /* Build a DELETE query with validation */
  let _buildDeleteQuery = (
    ~tableName: string,
    ~where: option<array<(string, Query.Params.t)>>,
    client: PgClient.t,
  ) => {
    // Check if the table exists before building the query
    _checkIfTableExists(~tableName, client)->Promise.then(_ => {
      let (whereClause, params) = _buildWhereClause(~where, ~startIndex=1)
      let baseQuery = "DELETE FROM " ++ tableName
      let query = baseQuery ++ whereClause ++ " RETURNING *"
      Promise.resolve((query, params))
    })
  }

  let _executeQuery = (
    ~statement: string,
    ~params: array<Query.Params.t>,
    client: PgClient.t,
  ): Promise.t<PgBind.PgResult.t<Js.Json.t>> => {
    Js.log("Executing query: " ++ statement)

    // Execute the query with error handling
    PgClient.Params.query(client, ~statement, ~params)
    ->Promise.then(result => {
      if result.rows->Belt.Array.length === 0 {
        Promise.resolve(result)
      } else {
        Promise.resolve(result)
      }
    })
    ->Promise.catch(err => {
      let errMessage = switch err {
      | Failure(message) => "Query execution error: " ++ message
      | Exn.Error(jsError) => {
          let errorMessage = switch Exn.message(jsError) {
          | Some(message) => message
          | None => "Unknown JS error"
          }
          "JS error: " ++ errorMessage
        }
      | _ => "Unknown error during query execution"
      }

      Js.log("Error during query execution: " ++ errMessage)
      Promise.reject(Failure(errMessage))
    })
  }
}
