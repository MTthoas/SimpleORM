open Config
open PgBind

module Datasource = {
    
    let connect = (~config: Config.dbConfig) => {
        let client = PgClient.make(
            ~user=config.user || dbConfig.user,
            ~password=config.password || dbConfig.password,
            ~host= config.host || dbConfig.host,
            ~database= config.database ||  dbConfig.database,
            ~port=config.database || dbConfig.port,
            (),
        )

        PgClient.connect(client, ())
        ->Promise.then(_ => {
            Console.log("Connected to the database")
            Js.Promise.resolve(client)
        })
        ->Promise.catch(e => {
            Console.error2("Failed to connect to the database", e)
            Js.Promise.reject(e)
        })
    }

}