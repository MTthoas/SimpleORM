@module("dotenv")
external config: unit => unit = "config"

// Bindings for process.env
module NodeProcess = {
  @bs.val external env: Js.Dict.t<string> = "process.env"
}

module Config = {
  type dbConfig = {
    user: string,
    password: string,
    host: string,
    database: string,
    port: int,
  }

  // Load environment variables from .env file
  config({"path": ".env.development"})

  let getEnvVar = (key: string, defaultValue: string) => {
    switch Js.Dict.get(NodeProcess.env, key) {
    | Some(value) => value
    | None => defaultValue
    }
  }

  let defaultConfig: dbConfig = {
    user: getEnvVar("DB_USER", "admin"),
    password: getEnvVar("DB_PASSWORD", "adminpwd"),
    host: getEnvVar("DB_HOST", "localhost"),
    database: getEnvVar("DB_NAME", "db"),
    port: switch Js.Dict.get(NodeProcess.env, "DB_PORT") {
      | Some(portString) => switch Int.fromString(portString) {
          | Some(port) => port
          | None => 5432
        }
      | None => 5432
    },
  }
}
