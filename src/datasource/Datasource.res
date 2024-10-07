open Config
open PgBind
open DatasourceType
module Datasource = {
  let connect = (~config: option<Config.dbConfig>=?, ~isLocalEnv: option<bool>=?) => {
    let isLocalEnv = Belt.Option.getWithDefault(isLocalEnv, false)

    let user = switch config {
    | Some(cfg) =>
      if Js.String2.length(cfg.user) > 0 {
        cfg.user
      } else if isLocalEnv {
        Config.getEnvVar("DB_USER", "admin")
      } else {
        "admin"
      }
    | None =>
      if isLocalEnv {
        Config.getEnvVar("DB_USER", "admin")
      } else {
        "admin"
      }
    }

    let password = switch config {
    | Some(cfg) =>
      if Js.String2.length(cfg.password) > 0 {
        cfg.password
      } else if isLocalEnv {
        Config.getEnvVar("DB_PASSWORD", "adminpwd")
      } else {
        "adminpwd"
      }
    | None =>
      if isLocalEnv {
        Config.getEnvVar("DB_PASSWORD", "adminpwd")
      } else {
        "adminpwd"
      }
    }

    let database = switch config {
    | Some(cfg) =>
      if Js.String2.length(cfg.database) > 0 {
        cfg.database
      } else if isLocalEnv {
        Config.getEnvVar("DB_NAME", "db")
      } else {
        "db"
      }
    | None =>
      if isLocalEnv {
        Config.getEnvVar("DB_NAME", "db")
      } else {
        "db"
      }
    }

    let host = switch config {
    | Some(cfg) =>
      if Js.String2.length(cfg.host) > 0 {
        cfg.host
      } else if isLocalEnv {
        Config.getEnvVar("DB_HOST", "localhost")
      } else {
        "localhost"
      }
    | None =>
      if isLocalEnv {
        Config.getEnvVar("DB_HOST", "localhost")
      } else {
        "localhost"
      }
    }

    let port = switch config {
    | Some(cfg) =>
      if cfg.port > 0 {
        cfg.port
      } else if isLocalEnv {
        switch Int.fromString(Config.getEnvVar("DB_PORT", "5432")) {
        | Some(port) => port
        | None => 5432
        }
      } else {
        5432
      }
    | None =>
      if isLocalEnv {
        switch Int.fromString(Config.getEnvVar("DB_PORT", "5432")) {
        | Some(port) => port
        | None => 5432
        }
      } else {
        5432
      }
    }

    let client = PgClient.make(~user, ~password, ~database, ~host, ~port, ())

    PgClient.connect(client, ())
    ->Promise.then(_ => {
      Console.log("Connected to the database")
      Js.Promise.resolve(client) // Retourner le client PostgreSQL
    })
    ->Promise.catch(e => {
      Console.error2("Failed to connect to the database", e)
      Js.Promise.reject(e)
    })
  }

  let closeConnection = (client: PgClient.t) => {
    PgClient.end(client, ())
    ->Promise.then(_ => {
      Console.log("Connection closed")
      Js.Promise.resolve()
    })
    ->Promise.catch(e => {
      Console.error2("Failed to close the connection", e)
      Js.Promise.reject(e)
    })
  }

  let make = (~config: DatasourceType.defaultConfig): DatasourceType.t => {
    let initialize = (): Js.Promise.t<unit> => {
      Js.Promise.make((~resolve, ~reject) => {
        Js.log("Initializing connection to DB: " ++ config.database)
        if config.synchronize {
          Js.log("Synchronizing database schema...")
        }

        let client = PgClient.make(
          ~user=config.username,
          ~password=config.password,
          ~database=config.database,
          ~host=config.host,
          ~port=config.port,
          (),
        )

        // Connexion du client
        PgClient.connect(client, ())
        ->Promise.then(_ => {
          Console.log("Connected to the database")
          resolve()
          Js.Promise.resolve()
        })
        ->Promise.catch(e => {
          Console.error2("Failed to connect to the database", e)
          reject(e)
          Js.Promise.resolve()
        })
        ->ignore
      })
    }

    {
      config, // Retourner la configuration
      initialize, // Retourner la fonction d'initialisation
    }
  }
}
