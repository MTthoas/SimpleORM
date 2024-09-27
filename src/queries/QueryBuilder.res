open PgBind

module QueryBuilder = {
  /* Where clause if present in the arguments 
      The where argument is an optional array of tuples (field, value) to filter the rows.
      We build the WHERE clause by mapping each tuple to a condition "field = $n" where n is the index of the tuple in the array.
  */
  let _buildWhereClause = (~where: option<array<(string, Query.Params.t)>>) => {
    switch where {
    | Some(conditions) => {
        let clauses = conditions->Belt.Array.mapWithIndex((index, (field, _)) =>
            field ++ " = $" ++ Js.Int.toString(index + 1)
        )
        let whereClause = " WHERE " ++ clauses->Array.join(" AND ")
        let params = conditions->Array.map(((_, value)) => value)
        (whereClause, params)
      }
    | None => ("", [])
    }
  }

  let _buildSelectQuery = (~tableName: string, ~where: option<array<(string, Query.Params.t)>>, ~limit: option<int>) => {
    let baseQuery = "SELECT * FROM " ++ tableName

    // Vérification si `where` contient des conditions
    let whereClause = switch where {
      | Some(conditions) =>
          let (clause, _) = _buildWhereClause(~where=Some(conditions))
          clause
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

    // Retourner la requête finale avec les clauses WHERE et LIMIT si elles existent
    baseQuery ++ whereClause ++ limitClause
  }


  let _buildInsertQuery =  (~tableName: string, ~fields: array<string>, ~values: array<Query.Params.t>) => {
    let baseQuery = "INSERT INTO " ++ tableName ++ " (" ++ fields->Array.join(", ") ++ ") VALUES ("
    let valuePlaceholders = values->Belt.Array.mapWithIndex((index, _) => "$" ++ Js.Int.toString(index + 1))
    let query = baseQuery ++ valuePlaceholders->Array.join(", ") ++ ") RETURNING *"
    query
  }

  let _buildQueryParams  = (~where: option<array<(string, Query.Params.t)>>) => { 
    switch where {
    | Some(conditions) => conditions->Array.map(((_, value)) => value)
    | None => []
    }
  }

  // Exécuter une requête SQL avec les paramètres
  let _executeQuery = (~statement: string, ~params: array<Query.Params.t>, client: PgClient.t) => {
    PgClient.Params.query(client, ~statement, ~params)
  }
  
}
