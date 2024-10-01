# SimpleOrm

SimpleORM - A Lightweight JavaScript ORM for REST APIs build in Rescript.

![ReScript](https://img.shields.io/badge/rescript-%2314162c?style=for-the-badge&logo=rescript&logoColor=e34c4c)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Bun](https://img.shields.io/badge/Bun-%23000000.svg?style=for-the-badge&logo=bun&logoColor=white)

### Description

A lightweight, customizable Object-Relational Mapping (ORM) tool built in Rescript for working with RESTful APIs.

 <ins>***NOTES***</ins> : Currently only available for PostgresSQL

# File Structure

Here is the file structure of the project:

```
simpleorm/
├── functions/
│   └── user/
│       ├── User.res
│       ├── User.res.js
│       └── App.res
├── lib/
├── node_modules/
├── src/
│   ├── bindings/
│   │   ├── PgBind.res
│   │   └── PgBind.res.js
│   ├── config/
│   │   ├── config.res
│   │   └── config.res.js
│   ├── core/
│   │   ├── ApplyMigration.res
│   │   ├── ApplyMigration.res.js
│   │   ├── Db.res
│   │   └── Db.res.js
│   ├── queries/
│   │   ├── QueryBuilder.res
│   │   ├── QueryBuilder.res.js
│   │   ├── Repository.res
│   │   └── Repository.res.js
│   └── table-builder/
│       ├── Builder.res
│       ├── Builder.res.js
│       └── Schema.res
│       └── Schema.res.js
├── tests/
│   ├── DbTest.test.res
│   ├── DbTest.test.res.js
│   └── Find.test.res
│   └── Find.test.res.js
├── .env.development
├── docker-compose.yaml
├── migration.sql
├── rescript.json
└── README.md
```

---

## Description of Key Folders:

### `functions/`

This folder contains example functions that demonstrate how to use the SimpleORM library in a real-world scenario. Specifically, the `user/` directory contains:

- **`User.res`**: Implements user-specific operations such as inserting or querying user records in the database using SimpleORM.
- **`App.res`**: The main entry point for the example application, showcasing how the ORM can be used to manage users.

The `functions` directory is intended for showcasing example usage of the ORM in application logic.

### `src/`

The main source folder of the SimpleORM project, organized into subdirectories for specific functionalities:

- **`bindings/`**: Contains Rescript bindings for PostgreSQL. For example, `PgBind.res` defines how Rescript interacts with the PostgreSQL client.

- **`config/`**: Includes configuration files like `config.res`, which manages loading environment variables and default settings for database connections.

- **`core/`**: Core functionalities of the ORM are implemented here. For example:
  - `Db.res`: Manages the database connection and closure.
  - `ApplyMigration.res`: Applies migration scripts to modify the database schema.

- **`queries/`**: Contains query-building logic:
  - `QueryBuilder.res`: Constructs SQL queries dynamically for operations like `SELECT`, `INSERT`, `UPDATE`, and `DELETE`.
  - `Repository.res`: Provides an abstraction layer that simplifies database interactions using CRUD operations.

- **`table-builder/`**: Utilities for constructing database tables, including schema and migration scripts:
  - `Builder.res`: Handles building table creation queries.
  - `Schema.res`: Manages table schema definitions.

### `tests/`

Contains the test files for verifying the behavior of various components, such as database interactions and query builders:

- **`DbTest.test.res`**: Tests related to database connection and operations.
- **`Find.test.res`**: Tests for querying and finding records in the database.


# Development

To get started with development, clone the repository and run the following commands:

```bash
bun install
```

The example is directly in the `src/app.res` folder.
To build & run the project, run:

```bash
bun res:build
bun start
```

This will create the migration.sql based on the schema defined in the `src/app.res` file.
Once the migration.sql file is created run a local postgres database using docker-compose:

```bash
docker compose up --build
```

Then, you can apply the migration to your database, run:

```bash
bun apply
```

This will create the tables in the database.

# Usage

## Schema Builder

Using the `schema` function, you can define the following properties:

- `tableName`: The name of the table in the database.
- `schema`: An array of columns in the table.
- `foreignKeys`: An array of foreign keys in the table.

Example:

```rescript
let userSchema: tableSchema = {
  tableName: "Users",
  schema: [{
      name: "id",
      _type: Int,
      primaryKey: true,
      optionnal: false,
      default: None,
      unique: false,
    }],
  foreignKeys: None,
}
```

With a foreign key:

```rescript
let userSchema: tableSchema = {
  tableName: "Posts",
  schema: [{
      name: "id",
      _type: Int,
      primaryKey: true,
      optionnal: false,
      default: None,
      unique: false,
    },
    {
      name: "user_id",
      _type: Int,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: false,
    }],
  foreignKeys: Some([{
    column: "id",
    referenceTable: "Users",
    referenceColumn: "user_id",
  }]),
}
```

Then you can use the `tableOperations` and the `saveSchemaToFilefunctions` functions to create the migration.sql file:

```rescript
let userSQL = tableOperations.create(~tableSchema=userSchema)
let userPostSQL = tableOperations.create(~tableSchema=postSchema)
saveSchemaToFile(~fileName="migration.sql", ~toWrite=userSQL ++ userPostSQL)->ignore
```

## Repository Module

The `Repository` module is a core component of **SimpleORM**, designed to provide simple database interaction functionality for PostgreSQL. It leverages the `QueryBuilder` module to generate and execute SQL queries, making it easy to perform CRUD operations (Create, Read, Update, Delete) on database tables. The `Repository` exposes several functions that abstract the complexity of raw SQL operations and provide a convenient API for developers.

### Key Features:

- **Find records**: Fetch one or more records from a PostgreSQL table based on conditions (`WHERE`) and limit constraints.
- **Insert records**: Insert new records into a table, either one record or multiple records at once.
- **Update records**: Update one or more records in a table using a `WHERE` clause or by a specific `ID`.
- **Delete records**: Delete one or more records from a table, or delete by `ID`.
- **Handle errors**: Graceful error handling for cases like invalid table names, limits, or WHERE conditions.

---

### Repository Functions

1. **`find`** - Retrieve Records from a Table

   This function allows you to retrieve records from a specified table. You can optionally pass `WHERE` conditions and limit the number of results.

   ```rescript
   let find = async (
     ~tableName: string,
     ~where: option<array<(string, Query.Params.t)>>=?,
     ~limit: option<int>=?,
     client: PgClient.t,
   ) => { ... }
   ```

   - **Parameters:**

     - `tableName`: The name of the table.
     - `where`: Optional `WHERE` clause conditions.
     - `limit`: Optional limit on the number of records returned.
     - `client`: The PostgreSQL client.

   - **Usage Example:**

     ```rescript
     let users = await Repository.find(~tableName="users", client)
     ```

2. **`findOne`** - Retrieve a Single Record

   This function is a shorthand to fetch a single record from the table, using a `WHERE` clause.

   ```rescript
   let findOne = async (
     ~tableName: string,
     ~where: array<(string, Query.Params.t)>,
     client: PgClient.t,
   ) => { ... }
   ```

   - **Usage Example:**

     ```rescript
     let user = await Repository.findOne(~tableName="users", ~where=[("email", Query.Params.string("john@example.com"))], client)
     ```

3. **`insert`** - Insert Records into a Table

   This function allows you to insert one or multiple records into a table.

   ```rescript
   let insert = async (
     ~tableName: string,
     ~fields: array<string>,
     ~values: array<Query.Params.t>,
     client: PgClient.t,
   ) => { ... }
   ```

   - **Parameters:**

     - `tableName`: The name of the table.
     - `fields`: Array of field names to insert values into.
     - `values`: Array of values corresponding to the fields.
     - `client`: The PostgreSQL client.

   - **Usage Example:**

     ```rescript
     let result = await Repository.insert(
       ~tableName="users",
       ~fields=["name", "email"],
       ~values=[Query.Params.string("Jane Doe"), Query.Params.string("jane@example.com")],
       client
     )
     ```

4. **`insertOne`** - Insert a Single Record

   This is a convenience function to insert a single record into the database.

   ```rescript
   let insertOne = async (
     ~tableName: string,
     ~fields: array<string>,
     ~values: array<Query.Params.t>,
     client: PgClient.t,
   ) => { ... }
   ```

   - **Usage Example:**

     ```rescript
     await Repository.insertOne(
       ~tableName="posts",
       ~fields=["title", "content"],
       ~values=[Query.Params.string("My Post"), Query.Params.string("Post content...")],
       client
     )
     ```

5. **`update`** - Update Records in a Table

   This function updates one or more records based on the provided `WHERE` conditions.

   ```rescript
   let update = async (
     ~tableName: string,
     ~fields: array<string>,
     ~values: array<Query.Params.t>,
     ~where: option<array<(string, Query.Params.t)>>=?,
     client: PgClient.t,
   ) => { ... }
   ```

   - **Parameters:**

     - `tableName`: The name of the table.
     - `fields`: Array of field names to update.
     - `values`: Array of new values corresponding to the fields.
     - `where`: Optional `WHERE` clause to filter the records.
     - `client`: The PostgreSQL client.

   - **Usage Example:**

     ```rescript
     await Repository.update(
       ~tableName="users",
       ~fields=["name"],
       ~values=[Query.Params.string("John Doe")],
       ~where=[("id", Query.Params.int(1))],
       client
     )
     ```

6. **`updateById`** - Update a Record by ID

   This is a convenience function for updating a record by its `ID`.

   ```rescript
   let updateById = async (
     ~tableName: string,
     ~fields: array<string>,
     ~values: array<Query.Params.t>,
     ~id: int,
     client: PgClient.t,
   ) => { ... }
   ```

   - **Usage Example:**

     ```rescript
     await Repository.updateById(
       ~tableName="users",
       ~fields=["email"],
       ~values=[Query.Params.string("new_email@example.com")],
       ~id=1,
       client
     )
     ```

7. **`delete`** - Delete Records

   This function deletes one or more records from a table based on the provided `WHERE` conditions.

   ```rescript
   let delete = async (
     ~tableName: string,
     ~where: option<array<(string, Query.Params.t)>>=?,
     client: PgClient.t,
   ) => { ... }
   ```

   - **Usage Example:**

     ```rescript
     await Repository.delete(
       ~tableName="users",
       ~where=[("id", Query.Params.int(1))],
       client
     )
     ```

8. **`deleteById`** - Delete a Record by ID

   This is a convenience function to delete a record by its `ID`.

   ```rescript
   let deleteById = async (
     ~tableName: string,
     ~id: int,
     client: PgClient.t,
   ) => { ... }
   ```

   - **Usage Example:**

     ```rescript
     await Repository.deleteById(~tableName="users", ~id=1, client)
     ```

---

### QueryBuilder Module

The `QueryBuilder` module is responsible for dynamically generating SQL queries like `SELECT`, `INSERT`, `UPDATE`, and `DELETE` based on the inputs provided to the `Repository`. Functions like `_buildSelectQuery`, `_buildInsertQuery`, and `_buildUpdateQuery` help to assemble the appropriate SQL syntax with placeholders for parameters, ensuring that the queries are secure and efficient.

### Error Handling

Each function in the `Repository` module raises exceptions in case of errors, such as:

- Invalid table name
- Invalid query limit
- Non-existent table
- Invalid `WHERE` conditions

This allows for robust error handling in your application logic.

---

This documentation gives an overview of the `Repository` module and shows how the `QueryBuilder` is used internally to manage the query construction process. You can extend or customize these functions to fit your specific use cases.


## DB Module

The **DB** module is responsible for managing the connection to a PostgreSQL database and handling database operations like applying migrations and closing the connection. It exposes a few key functions to help establish and manage database connections, execute SQL queries, and perform cleanup operations when needed.

### Key Features:

- **Connect to the database**: Establish a connection to a PostgreSQL database with configurable parameters (e.g., user, password, host).
- **Close the database connection**: Cleanly close the database connection after operations are completed.
- **Apply migrations**: Execute SQL migration scripts to set up or update the database schema.

---

### DB Functions

1. **`connectToDb`** - Connect to the PostgreSQL Database

   This function establishes a connection to the PostgreSQL database using the provided configuration values (such as `user`, `password`, `host`, `database`, and `port`). If the connection is successful, it returns the `PgClient.t` client instance, which can be used to execute queries on the database.

   ```rescript
   let connectToDb = (
     ~user=Config.defaultConfig.user,
     ~password=Config.defaultConfig.password,
     ~host=Config.defaultConfig.host,
     ~database=Config.defaultConfig.database,
     ~port=Config.defaultConfig.port,
   ) => { ... }
   ```

   - **Parameters:**
     - `user`: The database user (defaulted from `Config`).
     - `password`: The password for the database user (defaulted from `Config`).
     - `host`: The host where the PostgreSQL server is running (defaulted from `Config`).
     - `database`: The name of the database to connect to (defaulted from `Config`).
     - `port`: The port on which PostgreSQL is running (defaulted from `Config`).

   - **Returns**: A `Promise` that resolves with the connected `PgClient.t` client.

   - **Usage Example:**

     ```rescript
     let client = await DB.connectToDb()
     ```

2. **`closeConnection`** - Close the Database Connection

   This function closes an active PostgreSQL connection by calling the `PgClient.end` method. It logs the result and returns a `Promise` that resolves when the connection is successfully closed.

   ```rescript
   let closeConnection = (client: PgClient.t) => { ... }
   ```

   - **Parameters:**
     - `client`: The active `PgClient.t` client instance to be closed.

   - **Returns**: A `Promise` that resolves when the connection is successfully closed.

   - **Usage Example:**

     ```rescript
     await DB.closeConnection(client)
     ```

3. **`applyMigration`** - Apply SQL Migrations

   The `applyMigration` function reads the migration SQL from a file (usually named `migration.sql`) and executes it on the connected database. It uses `PgClient.Params.query` to run the migration. If the migration succeeds, it calls `onSuccess`; otherwise, it calls `onError`.

   ```rescript
   let applyMigration = (onSuccess, onError, client: PgClient.t) => { ... }
   ```

   - **Parameters:**
     - `onSuccess`: A callback function that is called when the migration is successful.
     - `onError`: A callback function that is called when an error occurs during the migration.
     - `client`: The active `PgClient.t` client instance to run the migration.

   - **Returns**: A `Promise` that resolves when the migration is successfully applied.

   - **Usage Example:**

     ```rescript
     DB.applyMigration(
       ~onSuccess=(res => Js.log("Migration applied successfully")),
       ~onError=(err => Js.log("Migration failed: " ++ Js.Exn.message(err))),
       client
     )
     ```

## Example Usage of the DB Module

Here’s an example of how you can use the **DB** module to connect to the database, apply migrations, and close the connection:

```rescript
let handleMigrations = async () => {
  try {
    // Step 1: Connect to the database
    let client = await DB.connectToDb()

    // Step 2: Apply migration
    await DB.applyMigration(
      ~onSuccess=(res => Console.log("Migration successfully applied")),
      ~onError=(err => Console.error("Migration failed: " ++ err)),
      client
    )

    // Step 3: Close the connection
    await DB.closeConnection(client)
  } catch (error) {
    Console.error("An error occurred: " ++ Js.Exn.message(error))
  }
}

handleMigrations()
```

### How It Works:
1. **`connectToDb`**: Establishes a connection to the database using the default or provided configuration.
2. **`applyMigration`**: Executes the migration SQL script on the database to update or create schema changes.
3. **`closeConnection`**: Closes the database connection to release resources after the migration is complete.

### Error Handling:
The module logs errors to the console and supports custom error-handling logic via callbacks in the `applyMigration` function. It ensures that any issues with connecting to the database, executing queries, or closing connections are handled gracefully.



## Local development :

- **Environment Variables**: The configuration values for `user`, `password`, `host`, `database`, and `port` are read from environment variables:
  - `DB_USER` for the database username.
  - `DB_PASSWORD` for the password.
  - `DB_HOST` for the database host.
  - `DB_NAME` for the name of the database.
  - `DB_PORT` for the database port.

  If these variables are not set in the environment, the code will fall back to the default values provided in the `Config` module (e.g., `admin`, `localhost`, etc.).

- **Default Values**: If the environment variable is missing, the code provides a default value. This ensures the application can still run in local development environments without needing to configure every environment variable explicitly.

### Environment Variables for Development:

For developers working locally, it’s common to use a file like `.env.development` to manage environment variables specific to the development environment. This file will contain all the necessary variables needed for local development. When deploying to production, a separate `.env` or `process.env` setup on the server will be used.

#### Example `.env.development`:

```
DB_USER=admin
DB_PASSWORD=adminpwd
DB_HOST=localhost
DB_NAME=db
DB_PORT=5432
```


