open PgBind
open QueryBuilder

module Repository = {
  /*
    Fonction générique pour trouver des enregistrements dans une table PostgreSQL avec des conditions WHERE et une limite optionnelles.
    @param tableName: Le nom de la table.
    @param where: Conditions WHERE optionnelles sous forme de tableau de tuples (champ, valeur).
    @param limit: Limite optionnelle pour le nombre d'enregistrements retournés.
  */
  let find = (~tableName: string, ~where: option<array<(string, Query.Params.t)>>=?, ~limit: option<int>=?, client: PgClient.t) => {
    let (_, params) = QueryBuilder._buildWhereClause(~where)
    let statement = QueryBuilder._buildSelectQuery(~tableName, ~where, ~limit)
    QueryBuilder._executeQuery(~statement, ~params, client)
  }

  let findOne = (~tableName: string, ~where: array<(string, Query.Params.t)>, client: PgClient.t) => {
    find(~tableName, ~where=where, ~limit=1, client)
  }

  let insert = (~tableName: string, ~fields: array<string>, ~values: array<Query.Params.t>, client: PgClient.t) => {
    let statement = QueryBuilder._buildInsertQuery(~tableName, ~fields, ~values)
    QueryBuilder._executeQuery(~statement, ~params=values, client)
  }

  let insertOne = (~tableName: string, ~fields: array<string>, ~values: array<Query.Params.t>, client: PgClient.t) => {
    insert(~tableName, ~fields, ~values, client)
  }

  let save = (~tableName: string, ~fields: array<string>, ~values: array<Query.Params.t>, client: PgClient.t) => {
    let statement = QueryBuilder._buildInsertQuery(~tableName, ~fields, ~values)
    QueryBuilder._executeQuery(~statement, ~params=values, client)
  }
}
