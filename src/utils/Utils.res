module Utils = {
  let add = (a, b) => a + b

  let handlePgError = pgError => {
    let errorMessage = switch Js.Exn.asJsExn(pgError) {
    | Some(jsExn) => Js.Exn.message(jsExn)->Belt.Option.getWithDefault("Erreur inconnue")
    | None => "Erreur inconnue"
    }
    Js.Console.error("Erreur lors de l'exécution de la requête : " ++ errorMessage)
  }

  let formatRows = (pgResult: PgBind.PgResult.t<'a>) => {
    pgResult.rows
    ->Belt.Array.map(row => Js.Json.stringify(row))
    ->Array.join(", ")
  }
}
