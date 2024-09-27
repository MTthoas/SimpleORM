module Config = {
  type dbConfig = {
    user: string,
    password: string,
    host: string,
    database: string,
    port: int,
  }

  let defaultConfig: dbConfig = {
    user: "admin",
    password: "adminpwd",
    host: "localhost",
    database: "db",
    port: 5432,
  }

  type client = PgBind.PgClient.t
}
