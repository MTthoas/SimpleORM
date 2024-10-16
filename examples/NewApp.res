open Datasource
open EntityType
open PgBind

let testDatasource = async () => {
  Js.log("Test de la fonction connect")
  let dataSource = Datasource.make(
    ~config={
      type_: "postgres",
      host: "localhost",
      port: 5432,
      username: "admin",
      password: "adminpwd",
      database: "db",
      entities: [],
      synchronize: true,
      logging: false,
    },
  )

  let client = await dataSource.initialize()

  let result = await dataSource.manager.find(EntityType.user, client, None, None)
  Js.log(result)

  // Call find
  //     let result = await dataSource.manager.find(EntityType.user, client)
  //   Js.log(result)
}

testDatasource()->ignore
