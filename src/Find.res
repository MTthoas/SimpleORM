open PgBind

/*
    Generic function to find rows in a PostgreSQL table with optional WHERE conditions and limit.
        @param tableName: The name of the table to query.
        @param where: Optional WHERE conditions as an array of tuples (field, value).
        @param limit: Optional limit on the number of rows to return.
 */
let find = (~tableName: string, ~where: option<array<(string, Query.Params.t)>>=?, ~limit: option<int>=?, client: PgClient.t) => {
  let baseQuery = "SELECT * FROM " ++ tableName

  /* Where clause if present in the arguments 
    The where argument is an optional array of tuples (field, value) to filter the rows.
    We build the WHERE clause by mapping each tuple to a condition "field = $n" where n is the index of the tuple in the array.
  */
  let whereClause = switch where {
    | Some(conditions) => {
      let clauses = conditions->Belt.Array.mapWithIndex((index, (field, _)) => 
        field ++ " = $" ++ Js.Int.toString(index + 1)
      )
      " WHERE " ++ clauses->Array.join(" AND ")
    }
    | None => ""
  }

  /*
    Limit clause if present in the arguments
    The limit argument is an optional integer to limit the number of rows returned by the query.
    We add a LIMIT clause to the query if the limit is specified.
   */
  let limitClause = switch limit {
    | Some(n) => " LIMIT " ++ Js.Int.toString(n)
    | None => ""
  }

  // Final query statement with base query, where clause, and limit clause
  let statement = baseQuery ++ whereClause ++ limitClause

  /*
    Parameters for the query
    The parameters are extracted from the where conditions if present.
    We map the conditions to extract the values and build an array of parameters for the query.
    For example : [(field1, value1), (field2, value2)] => [value1, value2]
   */
  let params = where->Belt.Option.mapWithDefault([], (conds) => conds->Array.map(((_, value)) => value))

  PgClient.Params.query(client, ~statement, ~params)
}

let findAll = (~tableName: string, client: PgClient.t) => {
    let statement = "SELECT * FROM " ++ tableName
    let params = []
    PgClient.Params.query(client, ~statement, ~params)
}





