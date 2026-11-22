open Config
open PgBind
open DatasourceType
open EntityType
open ManagerType
open QueryBuilder
open SqlEscape

module Datasource = {
  module Manager = {
    /**
     Récupère les lignes de la table d'une entité.

     @param entity entité dont la table est lue
     @param client client PostgreSQL connecté
     @param where conditions WHERE optionnelles, (colonne, valeur) reliées par AND
     @param limit nombre maximum de lignes, optionnel
     */
    let find = async (
      entity: EntityType.t,
      client: PgClient.t,
      where: option<array<(string, Query.Params.t)>>,
      limit: option<int>,
    ): array<Js.Json.t> => {
      let (statement, params) = await QueryBuilder._buildSelectQuery(
        ~tableName=entity.name,
        ~where,
        ~limit,
        client,
      )
      let result = await QueryBuilder._executeQuery(~statement, ~params, client)
      result.rows
    }

    /**
     Récupère un élément de la table par sa colonne `id`.

     @param entity entité dont la table est lue
     @param client client PostgreSQL connecté
     @param id valeur de la colonne `id`
     @return l'élément, ou None s'il n'existe pas
     */
    let findOne = async (entity: EntityType.t, client: PgClient.t, id: int): option<Js.Json.t> => {
      let rows = await find(entity, client, Some([("id", Query.Params.int(id))]), Some(1))
      rows[0]
    }

    /**
     Insère un nouvel élément avec les valeurs par défaut de la table.

     @param entity entité dont la table est remplie
     @param client client PostgreSQL connecté
     */
    let save = async (entity: EntityType.t, client: PgClient.t): unit => {
      let statement = "INSERT INTO " ++ SqlEscape.quoteIdentifier(entity.name) ++ " DEFAULT VALUES"
      let _ = await PgClient.query(client, ~statement, ~params=[])
    }

    let make = (): ManagerType.t => {
      find,
      findOne,
      save,
    }
  }

  /**
   Choisit une valeur de connexion : celle de la config si elle est renseignée,
   sinon la variable d'environnement en local, sinon la valeur par défaut.

   @param value valeur fournie par la config, ignorée si vide
   @param envKey variable d'environnement lue en local
   @param default valeur par défaut
   @param isLocalEnv lit les variables d'environnement si true
   */
  let _resolveSetting = (
    ~value: option<string>,
    ~envKey: string,
    ~default: string,
    ~isLocalEnv: bool,
  ) =>
    switch value {
    | Some(value) if value !== "" => value
    | _ if isLocalEnv => Config.getEnvVar(envKey, default)
    | _ => default
    }

  /**
   Ouvre une connexion à PostgreSQL. La connexion reste ouverte : la fermer avec `closeConnection`.

   @param config paramètres de connexion, les champs vides prennent la valeur par défaut
   @param isLocalEnv lit les variables d'environnement (DB_USER, DB_PASSWORD...) pour les champs vides
   */
  let connect = (~config: option<Config.dbConfig>=?, ~isLocalEnv: option<bool>=?) => {
    let isLocalEnv = isLocalEnv->Option.getOr(false)
    let setting = (field, ~envKey, ~default) =>
      _resolveSetting(~value=config->Option.map(field), ~envKey, ~default, ~isLocalEnv)

    let port =
      setting(cfg => cfg.port > 0 ? Int.toString(cfg.port) : "", ~envKey="DB_PORT", ~default="5432")
      ->Int.fromString
      ->Option.getOr(5432)

    Db.connectToDb(
      ~user=setting(cfg => cfg.user, ~envKey="DB_USER", ~default="admin"),
      ~password=setting(cfg => cfg.password, ~envKey="DB_PASSWORD", ~default="adminpwd"),
      ~database=setting(cfg => cfg.database, ~envKey="DB_NAME", ~default="db"),
      ~host=setting(cfg => cfg.host, ~envKey="DB_HOST", ~default="localhost"),
      ~port,
    )
  }

  /**
   @param client connexion ouverte par `connect` ou `initialize`
   */
  let closeConnection = (client: PgClient.t): promise<unit> => Db.closeConnection(client)

  /**
   Crée une datasource. La connexion n'est ouverte qu'à l'appel de `initialize`.

   @param config configuration de la base et des entités
   */
  let make = (~config: DatasourceType.defaultConfig): DatasourceType.t => {
    let initialize = () => {
      Console.log("Initializing connection to DB: " ++ config.database)
      if config.synchronize {
        Console.log("Synchronizing database schema...")
      }

      Db.connectToDb(
        ~user=config.username,
        ~password=config.password,
        ~database=config.database,
        ~host=config.host,
        ~port=config.port,
      )
    }

    {
      config,
      initialize,
      manager: Manager.make(),
    }
  }
}
