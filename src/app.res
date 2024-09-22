open Db
open Find

let testFind = async () => {
  try {
    JS.log("Test de la fonction find")
    let client = await connectToDb()
    let pgResult = await find(~tableName="users", client)
    
    let formattedRows = pgResult.rows
    ->Belt.Array.map(row => Js.Json.stringify(row)) // Convertir chaque ligne en JSON
    ->Array.join(", ")

    Js.Console.log("Résultats de la requête : " ++ formattedRows)
  } catch {
    | pgError =>
      let errorMessage = switch Js.Exn.asJsExn(pgError) {
        | Some(jsExn) => Js.Exn.message(jsExn)->Belt.Option.getWithDefault("Erreur inconnue")
        | None => "Erreur inconnue"
      }
      Js.Console.error("Erreur lors de l'exécution de la requête : " ++ errorMessage)
  }
}

let testFindAll = async () => {
  try {
    JS.Console.log("Test de la fonction findAll")
    let client = await connectToDb()
    let pgResult = await findAll(~tableName="users", client)
    
    let formattedRows = pgResult.rows
    ->Belt.Array.map(row => Js.Json.stringify(row))
    ->Array.join(", ") 

    Js.Console.log("Résultats de la requête : " ++ formattedRows)
  } catch {
    | pgError =>
      let errorMessage = switch Js.Exn.asJsExn(pgError) {
        | Some(jsExn) => Js.Exn.message(jsExn)->Belt.Option.getWithDefault("Erreur inconnue")
        | None => "Erreur inconnue"
      }
      Js.Console.error("Erreur lors de l'exécution de la requête : " ++ errorMessage)
  }
}

// Exécuter la fonction de test
testFind()->ignore
testFindAll()
