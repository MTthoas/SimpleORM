open PgBind
open Repository

module User = {
  exception ExceptionObject(string)

  /**
   Convertit une erreur du repository en ExceptionObject, en gardant son message.

   @param err l'exception attrapée
   */
  let _toExceptionObject = (err: exn): exn =>
    switch err {
    | ExceptionObject(_) => err
    | Failure(message) => ExceptionObject(message)
    | Exn.Error(jsError) =>
      ExceptionObject(Exn.message(jsError)->Option.getOr("Erreur JS inconnue"))
    | _ => ExceptionObject("Erreur inconnue")
    }

  /**
   Recherche des utilisateurs.

   @param where conditions WHERE optionnelles
   @param limit nombre maximum d'utilisateurs, optionnel
   @param client client PostgreSQL connecté
   */
  let getUsers = async (
    ~where: option<array<(string, Query.Params.t)>>=?,
    ~limit: option<int>=?,
    client: PgClient.t,
  ) =>
    try {
      await Repository.find(~tableName="users", ~where?, ~limit?, client)
    } catch {
    | err => raise(_toExceptionObject(err))
    }

  /**
   Recherche un utilisateur par son identifiant.

   @param id identifiant de l'utilisateur
   @param client client PostgreSQL connecté
   @return l'utilisateur, ou None s'il n'existe pas
   */
  let getUserById = async (~id: int, client: PgClient.t) =>
    try {
      await Repository.findOne(~tableName="users", ~where=[("id", Query.Params.int(id))], client)
    } catch {
    | err => raise(_toExceptionObject(err))
    }

  /**
   Crée un utilisateur.

   @param fields colonnes à remplir
   @param values valeurs des colonnes, dans le même ordre
   @param client client PostgreSQL connecté
   @return l'utilisateur créé
   */
  let createUser = async (
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ) =>
    try {
      await Repository.insertOne(~tableName="users", ~fields, ~values, client)
    } catch {
    | err => raise(_toExceptionObject(err))
    }

  /**
   Met à jour les utilisateurs qui correspondent aux conditions.

   @param fields colonnes à modifier
   @param values nouvelles valeurs, dans le même ordre
   @param where conditions WHERE, au moins une
   @param client client PostgreSQL connecté
   @return les utilisateurs modifiés
   */
  let updateUser = async (
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    ~where: option<array<(string, Query.Params.t)>>=?,
    client: PgClient.t,
  ) =>
    try {
      if where->Option.getOr([])->Array.length === 0 {
        raise(ExceptionObject("La clause WHERE ne peut pas être vide pour une mise à jour."))
      }
      await Repository.update(~tableName="users", ~fields, ~values, ~where?, client)
    } catch {
    | err => raise(_toExceptionObject(err))
    }

  /**
   Met à jour un utilisateur par son identifiant.

   @param id identifiant de l'utilisateur
   @param fields colonnes à modifier
   @param values nouvelles valeurs, dans le même ordre
   @param client client PostgreSQL connecté
   @return l'utilisateur modifié, ou None s'il n'existe pas
   */
  let updateUserById = async (
    ~id: int,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ) =>
    try {
      await Repository.updateById(~tableName="users", ~fields, ~values, ~id, client)
    } catch {
    | err => raise(_toExceptionObject(err))
    }

  /**
   Supprime un utilisateur par son identifiant.

   @param id identifiant de l'utilisateur
   @param client client PostgreSQL connecté
   @return l'utilisateur supprimé, ou None s'il n'existe pas
   */
  let deleteUserById = async (~id: int, client: PgClient.t) =>
    try {
      await Repository.deleteById(~tableName="users", ~id, client)
    } catch {
    | err => raise(_toExceptionObject(err))
    }
}
