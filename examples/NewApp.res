open Datasource

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
  let result = await dataSource.initialize()
  Js.log(result)
}

testDatasource()->ignore
