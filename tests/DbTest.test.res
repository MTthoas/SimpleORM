open Jest

type client

// Mock des fonctions PgClient.make et PgClient.connect
let mockPgClientMake = JestJs.fn(() => {
  {"client": "mockClient"}
})

let mockPgClientConnect = JestJs.fn(() => {
  Promise.resolve()
})

let mockPgClientConnectFailure: unit => Promise.t<unit> = () => {
  Promise.reject(Js.Exn.raiseError("Connection error"))
}

// Injecter les mocks dans PgClient
@module("PgClient")
external make: (
  ~user: string,
  ~password: string,
  ~host: string,
  ~database: string,
  ~port: int,
  unit,
) => client = "make"

@module("PgClient")
external connect: (client, unit) => Promise.t<unit> = "connect"

// Les tests
describe("connectToDb", () => {
  beforeAll(() => {
    // On mocke les méthodes de PgClient
    JestJs.mockWithFactory(
      "PgClient",
      () => {
        {
          "make": mockPgClientMake,
          "connect": mockPgClientConnect,
        }
      },
    )
  })

  afterEach(() => {
    JestJs.clearAllMocks()
  })
})
