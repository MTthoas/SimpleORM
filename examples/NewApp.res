open Datasource

let testDatasource = async () => {
    Js.log("Test de la fonction connect")
    let client = await Datasource.connect()
    Js.log(client)
}