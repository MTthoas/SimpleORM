open Db
open Find
open Builder

let success = createTable(
  ~tableName="User",
  ~schema=[
    {
      name: "id",
      _type: Int,
      primaryKey: true,
      optionnal: false,
      default: None,
      unique: false,
    },
    {
      name: "name",
      _type: String,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: true,
    },
    {
      name: "email",
      _type: String,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: true,
    },
    {
      name: "role",
      _type: Enum(["USER", "ADMIN"]),
      primaryKey: false,
      optionnal: false,
      default: Some("USER"),
      unique: false,
    },
    {
      name: "status",
      _type: Enum(["BANNED", "STANDARD", "PREMIUM"]),
      primaryKey: false,
      optionnal: true,
      default: None,
      unique: false,
    },
  ],
)

Console.log(success)

// let testFind = async () => {
//   try {
//     Console.log("Test de la fonction find")
//     let client = await connectToDb()
//     let pgResult = await find(~tableName="users", client)

//     let formattedRows =
//       pgResult.rows
//       ->Belt.Array.map(row => Js.Json.stringify(row)) // Convertir chaque ligne en JSON
//       ->Array.join(", ")

//     Console.log("Résultats de la requête : " ++ formattedRows)
//   } catch {
//   | pgError =>
//     let errorMessage = switch Js.Exn.asJsExn(pgError) {
//     | Some(jsExn) => Js.Exn.message(jsExn)->Belt.Option.getWithDefault("Erreur inconnue")
//     | None => "Erreur inconnue"
//     }
//     Console.error("Erreur lors de l'exécution de la requête : " ++ errorMessage)
//   }
// }

// let testFindAll = async () => {
//   try {
//     Console.log("Test de la fonction findAll")
//     let client = await connectToDb()
//     let pgResult = await findAll(~tableName="users", client)

//     let formattedRows =
//       pgResult.rows
//       ->Belt.Array.map(row => Js.Json.stringify(row))
//       ->Array.join(", ")

//     Console.log("Résultats de la requête : " ++ formattedRows)
//   } catch {
//   | pgError =>
//     let errorMessage = switch Js.Exn.asJsExn(pgError) {
//     | Some(jsExn) => Js.Exn.message(jsExn)->Belt.Option.getWithDefault("Erreur inconnue")
//     | None => "Erreur inconnue"
//     }
//     Console.error("Erreur lors de l'exécution de la requête : " ++ errorMessage)
//   }
// }

// // Exécuter la fonction de test
// testFind()->ignore
// testFindAll()->ignore
