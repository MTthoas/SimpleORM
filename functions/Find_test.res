// open Find
// open Config
// open Utils
// open PgBind

// let testFind = async () => {
//   try {
//     Js.Console.log("Test de la fonction find")
//     let client = await Utils.connectToDb(~config=Config.defaultConfig)
//     let pgResult: PgBind.PgResult.t<'a> = await find(~tableName="users", client)

//     let formattedRows = Utils.formatRows(pgResult)
//     Js.Console.log("Résultats de la requête : " ++ formattedRows)
//   } catch {
//     | pgError => Utils.handlePgError(pgError)
//   }
// }

// let testFindWithParams = async () => {
//   try {
//     Js.Console.log("Test de la fonction find avec paramètres")
//     let client = await Utils.connectToDb(~config=Config.defaultConfig)

//     let pgResult: PgBind.PgResult.t<'a> = await find(
//       ~tableName="users",
//       ~where=[("id", Query.Params.int(1))],
//       ~limit=10,
//       client
//     )

//     let formattedRows = Utils.formatRows(pgResult)
//     Js.Console.log("Résultats de la requête : " ++ formattedRows)
//   } catch {
//     | pgError => Utils.handlePgError(pgError) 
//   }
// }

// let testFindAll = async () => {
//   try {
//     Js.Console.log("Test de la fonction findAll")
//     let client = await Utils.connectToDb(~config=Config.defaultConfig)
//     let pgResult: PgBind.PgResult.t<'a> = await findAll(~tableName="users", client)

//     let formattedRows = Utils.formatRows(pgResult)
//     Js.Console.log("Résultats de la requête : " ++ formattedRows)
//   } catch {
//     | pgError => Utils.handlePgError(pgError)
//   }
// }

// // Exécuter la fonction de test
// testFind()->ignore
// testFindWithParams()->ignore
// testFindAll()->ignore
