open PgBind
open Repository

module User = {
  exception ExceptionObject(string)

  /* Fonction pour rechercher des utilisateurs avec des options WHERE et LIMIT */
  let getUsers = async (
    ~where: option<array<(string, Query.Params.t)>>=?,
    ~limit: option<int>=?,
    client: PgClient.t,
  ) => {
    try {
      let result = await Repository.find(
        ~tableName="users",
        ~where=where->Belt.Option.getWithDefault([]),
        ~limit=limit->Belt.Option.getWithDefault(0),
        client,
      )
      Promise.resolve(result)
    } catch {
    | Exn.Error(err) =>
      let errorMessage = switch Exn.message(err) {
      | Some(message) => message
      | None => "Erreur JS inconnue"
      }
      raise(ExceptionObject(errorMessage))
    | Failure(message) => raise(ExceptionObject(message))
    | _ => raise(ExceptionObject("Erreur inconnue"))
    }
  }

  /* Fonction pour rechercher un utilisateur par son identifiant */
  let getUserById = async (~id: int, client: PgClient.t) => {
    try {
      let whereClause = [("id", Query.Params.int(id))]
      let result = await Repository.findOne(~tableName="users", ~where=whereClause, client)
      Promise.resolve(result)
    } catch {
    | Exn.Error(err) =>
      let errorMessage = switch Exn.message(err) {
      | Some(message) => message
      | None => "Erreur JS inconnue"
      }
      raise(ExceptionObject(errorMessage))
    | Failure(message) => raise(ExceptionObject(message))
    | _ => raise(ExceptionObject("Erreur inconnue"))
    }
  }

  /* Fonction pour créer un utilisateur */
  let createUser = async (
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ) => {
    try {
      // Appeler la fonction insert dans le repository
      let result = await Repository.insertOne(~tableName="users", ~fields, ~values, client)
      Promise.resolve(result)
    } catch {
    | Exn.Error(err) =>
      let errorMessage = switch Exn.message(err) {
      | Some(message) => message
      | None => "Erreur JS inconnue"
      }
      raise(ExceptionObject(errorMessage))
    | Failure(message) => raise(ExceptionObject(message))
    | _ => raise(ExceptionObject("Erreur inconnue"))
    }
  }

  /* Fonction pour mettre à jour un utilisateur */
  let updateUser = async (
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    ~where: option<array<(string, Query.Params.t)>>=?,
    client: PgClient.t,
  ) => {
    try {
      let whereConditions = where->Belt.Option.getWithDefault([])

      // Vérifier que la clause WHERE n'est pas vide si elle est attendue
      if whereConditions->Array.length === 0 {
        raise(ExceptionObject("La clause WHERE ne peut pas être vide pour une mise à jour."))
      }

      // Appeler la fonction save dans le repository
      let result = await Repository.update(
        ~tableName="users",
        ~fields,
        ~values,
        ~where=whereConditions,
        client,
      )
      Promise.resolve(result)
    } catch {
    | Exn.Error(err) =>
      let errorMessage = switch Exn.message(err) {
      | Some(message) => message
      | None => "Erreur JS inconnue"
      }
      raise(ExceptionObject(errorMessage))
    | Failure(message) => raise(ExceptionObject(message))
    | _ => raise(ExceptionObject("Erreur inconnue"))
    }
  }

  /* Fonction pour mettre à jour un utilisateur par un ID */
  let updateUserById = async (
    ~id: int,
    ~fields: array<string>,
    ~values: array<Query.Params.t>,
    client: PgClient.t,
  ) => {
    try {
      let whereClause = [("id", Query.Params.int(id))]
      let result = await Repository.update(
        ~tableName="users",
        ~fields,
        ~values,
        ~where=whereClause,
        client,
      )
      Promise.resolve(result)
    } catch {
    | Exn.Error(err) =>
      let errorMessage = switch Exn.message(err) {
      | Some(message) => message
      | None => "Erreur JS inconnue"
      }
      raise(ExceptionObject(errorMessage))
    | Failure(message) => raise(ExceptionObject(message))
    | _ => raise(ExceptionObject("Erreur inconnue"))
    }
  }

  /* Fonction pour supprimer un utilisateur */
  let deleteUserById = async (~id: int, client: PgClient.t) => {
    try {
      let whereClause = [("id", Query.Params.int(id))]
      let result = await Repository.delete(~tableName="users", ~where=whereClause, client)
      Promise.resolve(result)
    } catch {
    | Exn.Error(err) =>
      let errorMessage = switch Exn.message(err) {
      | Some(message) => message
      | None => "Erreur JS inconnue"
      }
      raise(ExceptionObject(errorMessage))
    | Failure(message) => raise(ExceptionObject(message))
    | _ => raise(ExceptionObject("Erreur inconnue"))
    }
  }
}
