module Uuid = {
  type t
  external make: string => t = "UUID"
  external toString: t => string = "%identity"
}

module Spacetime = {
  type t
  type format = [#iso | #nice | #offset | #offsetNice | #time | #timeNice | #timeShort]
  @send
  external format: (t, format) => string = "format"
}

module GraphileLogger = {
  type logger
  @send
  external error: (logger, string, exn) => unit = "error"
}

module PgResult = {
  module FieldInfo = {
    type t = private {
      name: string,
      dataTypeId: string,
    }
  }
  type t<'a> = private {
    rows: array<'a>,
    fields: array<FieldInfo.t>,
    rowCount: int,
    command: string,
  }
}
module PgError = {
  type t = private {
    message: string,
    code: string,
    name: string,
    stack: string,
  }
  external fromJsExn: Exn.t => t = "%identity"
  external toJsExn: t => Exn.t = "%identity"
  external toExn: t => exn = "%identity"

  let catch = promise =>
    Promise.catch(promise, e =>
      switch e {
      //   | Promise.JsError(e) => Result.Error(fromJsExn(e))->Promise.resolve
      | e =>
        Console.error2("Caught unexpected error in NodePostgres", e)
        Promise.reject(e)
      }
    )

  let toObject = e =>
    {
      "message": e.message,
      "code": e.code,
      "name": e.name,
      "stack": e.stack,
    }
}

type initiator<'kind>

module QueryCallback = {
  type cb<'a, 'return> = Belt.Result.t<PgResult.t<'a>, PgError.t> => 'return
  @send
  external query: (
    initiator<'kind>,
    ~statement: string,
    ~params: array<string>,
    ~cb: @uncurry (option<PgError.t>, option<PgResult.t<'a>>) => 'return,
  ) => 'return = "query"
  let query = (initator, ~statement: string, ~params: array<string>, ~cb: cb<'a, 'return>) =>
    query(initator, ~statement, ~params, ~cb=(error, res) =>
      switch (error, res) {
      | (Some(error), _) => cb(Belt.Result.Error(error))
      | (_, Some(res)) => cb(Belt.Result.Ok(res))
      | (None, None) => Exn.raiseTypeError("Invalid callback in nodePg query")
      }
    )
}

module Query = {
  @send
  external query: (
    initiator<'kind>,
    ~statement: string,
    ~params: array<string>,
  ) => Promise.t<PgResult.t<'a>> = "query"

  module Params: {
    type t
    type preparedQuery = {
      name: string,
      text: string,
      values: array<t>,
      rowMode: [#object | #array],
    }
    let int: int => t
    let string: string => t
    let uuid: Uuid.t => t
    let spacetime: Spacetime.t => t
    let intArray: array<int> => t
    let stringArray: array<string> => t
    let array: array<t> => t
    let option: option<t> => t
    let json: Js.Json.t => t
    let dict: Js.Dict.t<'a> => t
    let obj: 'a => t
    let interval: (int, [#second | #minute | #hour | #day | #week | #month | #year]) => t
    let null: t
    let nullable: option<t> => t
    type queryObject = {
      text: string,
      values: array<t>,
      rowMode: option<[#object | #array]>,
    }
    @send
    external queryPrepared: (initiator<'kind>, preparedQuery) => Promise.t<PgResult.t<'a>> = "query"
    let query: (
      ~rowMode: [#object | #array]=?,
      initiator<'kind>,
      ~statement: string,
      ~params: array<t>,
    ) => Promise.t<PgResult.t<'a>>
  } = {
    @unboxed type rec t = Param('a): t
    let int = (int: int) => Param(int)
    let string = (string: string) => Param(string)
    let uuid = (uuid: Uuid.t) => Param(Uuid.toString(uuid))
    let spacetime = (date: Spacetime.t) => Param(Spacetime.format(date, #iso))
    let array = (array: array<t>) => Param(array)
    let intArray = (array: array<int>) => Param(array)
    let stringArray = (array: array<string>) => Param(array)
    let option = (option: option<t>) => Param(option)
    let json = (json: Js.Json.t) => Param(Js.Json.stringify(json))
    let dict = (dict: Js.Dict.t<'a>) => Param(dict)
    let obj = obj => Param(obj)
    let interval = (
      quantity,
      unit: [#day | #hour | #minute | #month | #second | #week | #year],
    ) => {
      let q = quantity->Js.Int.toString
      let s = switch quantity {
      | 1 => ""
      | _ => "s"
      }
      let string = `${q} ${(unit :> string)}${s}`
      Param(string)
    }
    let null = Param(Js.Nullable.null)
    let nullable = param =>
      switch param {
      | Some(param) => param
      | None => null
      }
    type queryObject = {
      text: string,
      values: array<t>,
      rowMode: option<[#object | #array]>,
    }
    @send
    external query: (initiator<'kind>, queryObject) => Promise.t<PgResult.t<'a>> = "query"

    let query = (~rowMode=?, initiator, ~statement, ~params) => {
      query(
        initiator,
        {
          text: statement,
          values: params,
          rowMode,
        },
      )
    }
    type preparedQuery = {
      name: string,
      text: string,
      values: array<t>,
      rowMode: [#object | #array],
    }
    @send
    external queryPrepared: (initiator<'kind>, preparedQuery) => Promise.t<PgResult.t<'a>> = "query"
  }

  let getFirst = (res: Promise.t<PgResult.t<'a>>) => res->Promise.thenResolve(({rows}) => rows[0])

  let getUnique = (
    res: Promise.t<PgResult.t<'a>>,
    ~logger: GraphileLogger.logger,
    ~itemId: string,
    ~itemName: string,
  ) =>
    getFirst(res)->Promise.catch(e => {
      GraphileLogger.error(logger, `error while retrieving ${itemName} with ID ${itemId}`, e)
      Promise.reject(e)
    })

  exception PgNotFound({name: string, id: option<string>})

  let getUniqueExn = (
    res: Promise.t<PgResult.t<'a>>,
    ~logger: GraphileLogger.logger,
    ~itemId: string,
    ~itemName: string,
  ) =>
    getUnique(res, ~logger, ~itemId, ~itemName)->Promise.then(item =>
      switch item {
      | None =>
        GraphileLogger.error(
          logger,
          `no ${itemName} with ID ${itemId}`,
          Exn.raiseError("Not found"),
        )
        Promise.reject(PgNotFound({name: itemName, id: Some(itemId)}))
      | Some(item) => Promise.resolve(item)
      }
    )

  let getFirstValueExn = (
    res: Promise.t<PgResult.t<'a>>,
    ~logger: GraphileLogger.logger,
    ~valueName: string,
  ) =>
    getFirst(res)
    ->Promise.catch(e => {
      GraphileLogger.error(logger, `error while retrieving ${valueName}`, e)
      Promise.reject(e)
    })
    ->Promise.then(item =>
      switch item {
      | None =>
        GraphileLogger.error(
          logger,
          "Got no result when looking for " ++ valueName,
          Exn.raiseError("Not found"),
        )
        Promise.reject(PgNotFound({name: valueName, id: None}))
      | Some(item) =>
        switch Js.Dict.values(item) {
        | [value] => Promise.resolve(value)
        | _ =>
          GraphileLogger.error(
            logger,
            `Result is supposed to have only one field to get ${valueName}, got `,
            Exn.raiseError(Js.Dict.keys(item)->Array.join(", ")),
          )
          Promise.reject(PgNotFound({name: valueName, id: None}))
        }
      }
    )

  let getFirstValue = (
    res: Promise.t<PgResult.t<'a>>,
    ~logger: GraphileLogger.logger,
    ~valueName: string,
  ) =>
    getFirst(res)
    ->Promise.catch(e => {
      GraphileLogger.error(logger, `error while retrieving ${valueName}`, e)
      Promise.reject(e)
    })
    ->Promise.then(item =>
      switch item {
      | None => Promise.resolve(None)
      | Some(item) =>
        switch Js.Dict.values(item) {
        | [value] => Promise.resolve(Some(value))
        | _ =>
          GraphileLogger.error(
            logger,
            `Result is supposed to have only one field to get ${valueName}, got `,
            Exn.raiseError(Js.Dict.keys(item)->Array.join(", ")),
          )
          Promise.reject(PgNotFound({name: valueName, id: None}))
        }
      }
    )

  module Res = {
    let query = (initator, ~statement: string, ~params: array<string>) =>
      query(initator, ~statement, ~params)
      ->Promise.thenResolve(res => Belt.Result.Ok(res))
      ->PgError.catch
  }
}

module TypeOverrides = {
  type t
  module Builtins = {
    @scope(("default", "types", "builtins")) @module("pg") external bool: int = "BOOL"
    @scope(("default", "types", "builtins")) @module("pg") external bytea: int = "BYTEA"
    @scope(("default", "types", "builtins")) @module("pg") external char: int = "CHAR"
    @scope(("default", "types", "builtins")) @module("pg") external int8: int = "INT8"
    @scope(("default", "types", "builtins")) @module("pg") external int2: int = "INT2"
    @scope(("default", "types", "builtins")) @module("pg") external int4: int = "INT4"
    @scope(("default", "types", "builtins")) @module("pg") external regproc: int = "REGPROC"
    @scope(("default", "types", "builtins")) @module("pg") external text: int = "TEXT"
    @scope(("default", "types", "builtins")) @module("pg") external oid: int = "OID"
    @scope(("default", "types", "builtins")) @module("pg") external tid: int = "TID"
    @scope(("default", "types", "builtins")) @module("pg") external xid: int = "XID"
    @scope(("default", "types", "builtins")) @module("pg") external cid: int = "CID"
    @scope(("default", "types", "builtins")) @module("pg") external json: int = "JSON"
    @scope(("default", "types", "builtins")) @module("pg") external xml: int = "XML"
    @scope(("default", "types", "builtins")) @module("pg") external pgNodeTree: int = "PG_NODE_TREE"
    @scope(("default", "types", "builtins")) @module("pg") external jsonArray: int = "JSON_ARRAY"
    @scope(("default", "types", "builtins")) @module("pg") external smgr: int = "SMGR"
    @scope(("default", "types", "builtins")) @module("pg") external path: int = "PATH"
    @scope(("default", "types", "builtins")) @module("pg") external polygon: int = "POLYGON"
    @scope(("default", "types", "builtins")) @module("pg") external cidr: int = "CIDR"
    @scope(("default", "types", "builtins")) @module("pg") external float4: int = "FLOAT4"
    @scope(("default", "types", "builtins")) @module("pg") external float8: int = "FLOAT8"
    @scope(("default", "types", "builtins")) @module("pg") external abstime: int = "ABSTIME"
    @scope(("default", "types", "builtins")) @module("pg") external reltime: int = "RELTIME"
    @scope(("default", "types", "builtins")) @module("pg") external tinterval: int = "TINTERVAL"
    @scope(("default", "types", "builtins")) @module("pg") external circle: int = "CIRCLE"
    @scope(("default", "types", "builtins")) @module("pg") external macaddr8: int = "MACADDR8"
    @scope(("default", "types", "builtins")) @module("pg") external money: int = "MONEY"
    @scope(("default", "types", "builtins")) @module("pg") external macaddr: int = "MACADDR"
    @scope(("default", "types", "builtins")) @module("pg") external inet: int = "INET"
    @scope(("default", "types", "builtins")) @module("pg") external aclitem: int = "ACLITEM"
    @scope(("default", "types", "builtins")) @module("pg") external bpchar: int = "BPCHAR"
    @scope(("default", "types", "builtins")) @module("pg") external varchar: int = "VARCHAR"
    @scope(("default", "types", "builtins")) @module("pg") external date: int = "DATE"
    @scope(("default", "types", "builtins")) @module("pg") external time: int = "TIME"
    @scope(("default", "types", "builtins")) @module("pg") external timestamp: int = "TIMESTAMP"
    @scope(("default", "types", "builtins")) @module("pg") external timestamptz: int = "TIMESTAMPTZ"
    @scope(("default", "types", "builtins")) @module("pg") external interval: int = "INTERVAL"
    @scope(("default", "types", "builtins")) @module("pg") external timetz: int = "TIMETZ"
    @scope(("default", "types", "builtins")) @module("pg") external bit: int = "BIT"
    @scope(("default", "types", "builtins")) @module("pg") external varbit: int = "VARBIT"
    @scope(("default", "types", "builtins")) @module("pg") external numeric: int = "NUMERIC"
    @scope(("default", "types", "builtins")) @module("pg") external refcursor: int = "REFCURSOR"
    @scope(("default", "types", "builtins")) @module("pg")
    external regprocedure: int = "REGPROCEDURE"
    @scope(("default", "types", "builtins")) @module("pg") external regoper: int = "REGOPER"
    @scope(("default", "types", "builtins")) @module("pg") external regoperator: int = "REGOPERATOR"
    @scope(("default", "types", "builtins")) @module("pg") external regclass: int = "REGCLASS"
    @scope(("default", "types", "builtins")) @module("pg") external regtype: int = "REGTYPE"
    @scope(("default", "types", "builtins")) @module("pg") external uuid: int = "UUID"
    @scope(("default", "types", "builtins")) @module("pg")
    external txidSnapshot: int = "TXID_SNAPSHOT"
    @scope(("default", "types", "builtins")) @module("pg") external pg_lsn: int = "PG_LSN"
    @scope(("default", "types", "builtins")) @module("pg")
    external pgNdistinct: int = "PG_NDISTINCT"
    @scope(("default", "types", "builtins")) @module("pg")
    external pgDependencies: int = "PG_DEPENDENCIES"
    @scope(("default", "types", "builtins")) @module("pg") external tsvector: int = "TSVECTOR"
    @scope(("default", "types", "builtins")) @module("pg") external tsquery: int = "TSQUERY"
    @scope(("default", "types", "builtins")) @module("pg") external gtsvector: int = "GTSVECTOR"
    @scope(("default", "types", "builtins")) @module("pg") external regconfig: int = "REGCONFIG"
    @scope(("default", "types", "builtins")) @module("pg")
    external regdictionary: int = "REGDICTIONARY"
    @scope(("default", "types", "builtins")) @module("pg") external jsonb: int = "JSONB"
    @scope(("default", "types", "builtins")) @module("pg") external jsonbArray: int = "JSONB_ARRAY"
    @scope(("default", "types", "builtins")) @module("pg")
    external regnamespace: int = "REGNAMESPACE"
    @scope(("default", "types", "builtins")) @module("pg") external regrole: int = "REGROLE"
  }
  @module("pg/lib/type-overrides") @new external make: unit => t = "default"
  @send external setTypeParser: (t, int, @uncurry string => 'a) => unit = "setTypeParser"
}

type sslConfig
type config

module PgClient = {
  type client
  type t = initiator<client>

  @obj
  external makeConfig: (
    ~user: string=?, // default process.env.PGUSER || process.env.USER
    ~password: string=?, //default process.env.PGPASSWORD
    ~host: string=?, // default process.env.PGHOST
    ~database: string=?, // default process.env.PGDATABASE || process.env.USER
    ~port: int=?, // default process.env.PGPORT
    ~connectionString: string=?, // e.g. postgres://user:password@host:5432/database
    ~ssl: sslConfig=?, // passed directly to node.TLSSocket=? supports all tls.connect options
    ~types: TypeOverrides.t=?, // custom type parsers
    ~statement_timeout: int=?, // number of milliseconds before a statement in query will time out=? default is no timeout
    ~query_timeout: int=?, // number of milliseconds before a query call will timeout=? default is no timeout
    ~application_name: string=?, // The name of the application that created this Client instance
    ~connectionTimeoutMillis: int=?, // number of milliseconds to wait for connection=? default is no timeout
    ~idle_in_transaction_session_timeout: int=?, // number of milliseconds before terminating any session with an open idle transaction=? default is no timeout
    ~connectionTimeoutMillis: int=?, // number of milliseconds to wait for connection, default is no timeout
    ~idle_in_transaction_session_timeout: int=?, // number of milliseconds before terminating any session with an open idle transaction, default is no timeout
    unit,
  ) => config = ""

  @scope("default") @new @module("pg") external make: config => t = "Pool"

  let make = (
    ~user=?, // default process.env.PGUSER || process.env.USER
    ~password=?, //default process.env.PGPASSWORD
    ~host=?, // default process.env.PGHOST
    ~database=?, // default process.env.PGDATABASE || process.env.USER
    ~port=?, // default process.env.PGPORT
    ~connectionString=?, // e.g. postgres://user:password@host:5432/database
    ~ssl=?, // passed directly to node.TLSSocket=? supports all tls.connect options
    ~types=?, // custom type parsers
    ~statement_timeout=?, // number of milliseconds before a statement in query will time out=? default is no timeout
    ~query_timeout=?, // number of milliseconds before a query call will timeout=? default is no timeout
    ~application_name=?, // The name of the application that created this Client instance
    ~connectionTimeoutMillis=?, // number of milliseconds to wait for connection, default is no timeout
    ~idle_in_transaction_session_timeout=?, // number of milliseconds before terminating any session with an open idle transaction=? default is no timeout
    // number of milliseconds a client must sit idle in the pool and not be checked out
    // before it is disconnected from the backend and discarded
    // default is 10000 (10 seconds) - set to 0 to disable auto-disconnection of idle clients
    (),
  ) =>
    make(
      makeConfig(
        ~user?,
        ~password?,
        ~host?,
        ~database?,
        ~port?,
        ~connectionString?,
        ~ssl?,
        ~types?,
        ~statement_timeout?,
        ~query_timeout?,
        ~application_name?,
        ~connectionTimeoutMillis?,
        ~idle_in_transaction_session_timeout?,
        (),
      ),
    )

  @send external connect: (t, unit) => Js.Promise.t<unit> = "connect"

  @send external end: (t, unit) => Js.Promise.t<unit> = "end"

  include Query
  module Callback = QueryCallback
}

module PgPool = {
  type pool
  type t = initiator<pool>

  include Query

  @send external end: (t, unit) => Js.Promise.t<unit> = "end"

  @obj
  external makeConfig: (
    ~user: string=?, // default process.env.PGUSER || process.env.USER
    ~password: string=?, //default process.env.PGPASSWORD
    ~host: string=?, // default process.env.PGHOST
    ~database: string=?, // default process.env.PGDATABASE || process.env.USER
    ~port: int=?, // default process.env.PGPORT
    ~connectionString: string=?, // e.g. postgres://user:password@host:5432/database
    ~ssl: sslConfig=?, // passed directly to node.TLSSocket=? supports all tls.connect options
    ~types: TypeOverrides.t=?, // custom type parsers
    ~statement_timeout: int=?, // number of milliseconds before a statement in query will time out=? default is no timeout
    ~query_timeout: int=?, // number of milliseconds before a query call will timeout=? default is no timeout
    ~application_name: string=?, // The name of the application that created this Client instance
    ~connectionTimeoutMillis: int=?, // number of milliseconds to wait for connection=? default is no timeout
    ~idle_in_transaction_session_timeout: int=?, // number of milliseconds before terminating any session with an open idle transaction=? default is no timeout
    ~connectionTimeoutMillis: int=?, // number of milliseconds to wait for connection, default is no timeout
    ~idle_in_transaction_session_timeout: int=?, // number of milliseconds before terminating any session with an open idle transaction, default is no timeout
    ~idleTimeoutMillis: int=?, // number of milliseconds a client must sit idle in the pool and not be checked out
    // before it is disconnected from the backend and discarded
    // default is 10000 (10 seconds) - set to 0 to disable auto-disconnection of idle clients
    ~max: int=?, // maximum number of clients the pool should contain
    // by default this is set to 10.
    // Default behavior is the pool will keep clients open & connected to the backend
    ~allowExitOnIdle: bool=?, // until idleTimeoutMillis expire for each client and node will maintain a ref
    // to the socket on the client, keeping the event loop alive until all clients are closed
    // after being idle or the pool is manually shutdown with `pool.end()`.
    //
    // Setting `allowExitOnIdle: true` in the config will allow the node event loop to exit
    // as soon as all clients in the pool are idle, even if their socket is still open
    // to the postgres server.  This can be handy in scripts & tests
    // where you don't want to wait for your clients to go idle before your process exits.
    unit,
  ) => config = ""

  @scope("default") @new @module("pg") external make: config => t = "Pool"

  let make = (
    ~user=?, // default process.env.PGUSER || process.env.USER
    ~password=?, //default process.env.PGPASSWORD
    ~host=?, // default process.env.PGHOST
    ~database=?, // default process.env.PGDATABASE || process.env.USER
    ~port=?, // default process.env.PGPORT
    ~connectionString=?, // e.g. postgres://user:password@host:5432/database
    ~ssl=?, // passed directly to node.TLSSocket=? supports all tls.connect options
    ~types=?, // custom type parsers
    ~statement_timeout=?, // number of milliseconds before a statement in query will time out=? default is no timeout
    ~query_timeout=?, // number of milliseconds before a query call will timeout=? default is no timeout
    ~application_name=?, // The name of the application that created this Client instance
    ~connectionTimeoutMillis=?, // number of milliseconds to wait for connection, default is no timeout
    ~idle_in_transaction_session_timeout=?, // number of milliseconds before terminating any session with an open idle transaction=? default is no timeout
    // number of milliseconds a client must sit idle in the pool and not be checked out
    // before it is disconnected from the backend and discarded
    // default is 10000 (10 seconds) - set to 0 to disable auto-disconnection of idle clients
    ~idleTimeoutMillis=?,
    // maximum number of clients the pool should contain
    // by default this is set to 10.
    ~max=?,
    // until idleTimeoutMillis expire for each client and node will maintain a ref
    // to the socket on the client, keeping the event loop alive until all clients are closed
    // after being idle or the pool is manually shutdown with `pool.end()`.
    //
    // Setting `allowExitOnIdle: true` in the config will allow the node event loop to exit
    // as soon as all clients in the pool are idle, even if their socket is still open
    // to the postgres server.  This can be handy in scripts & tests
    // where you don't want to wait for your clients to go idle before your process exits.
    ~allowExitOnIdle=?,
    (),
  ) =>
    make(
      makeConfig(
        ~user?,
        ~password?,
        ~host?,
        ~database?,
        ~port?,
        ~connectionString?,
        ~ssl?,
        ~types?,
        ~statement_timeout?,
        ~query_timeout?,
        ~application_name?,
        ~connectionTimeoutMillis?,
        ~idle_in_transaction_session_timeout?,
        ~idleTimeoutMillis?,
        ~max?,
        ~allowExitOnIdle?,
        (),
      ),
    )

  @send
  external onError: (t, @as("error") _, ~cb: @uncurry (PgError.t, PgClient.t) => unit) => unit =
    "on"

  module Callback = {
    include QueryCallback
    @send
    external connect: (
      t,
      ~cb: @uncurry (option<PgError.t>, option<PgClient.t>, @uncurry unit => unit) => unit,
    ) => unit = "connect"

    let connect = (pgPool, ~cb: (Belt.Result.t<PgClient.t, PgError.t>, unit => unit) => unit) => {
      connect(pgPool, ~cb=(error, client, release) => {
        switch (error, client) {
        | (Some(error), _) =>
          release()
          cb(Belt.Result.Error(error), release)
        | (_, Some(client)) => cb(Belt.Result.Ok(client), release)
        | (None, None) =>
          // should not happen
          release()
          let error =
            Error.TypeError.make("Invalid callback in nodePg Pool.connect")->PgError.fromJsExn
          cb(Belt.Result.Error(error), release)
        }
      })
    }
  }

  @send
  external connect: t => Js.Promise.t<PgClient.t> = "connect"
  let connect = (pgPool, ~withPgClient) => {
    connect(pgPool)
    ->Promise.thenResolve(pgClient => Ok(pgClient))
    ->PgError.catch
    ->Promise.then(result =>
      switch result {
      | Ok(pgClient) =>
        withPgClient(pgClient)
        ->Promise.thenResolve(x => Ok(x))
        ->PgError.catch
        ->Promise.then(result => {
          PgClient.end(pgClient, ())->Promise.thenResolve(() => result)->PgError.catch
        })
      | Error(e) => Promise.reject(e)
      }
    )
  }
}
