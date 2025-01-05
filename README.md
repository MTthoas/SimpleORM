Voici une mise à jour du fichier `README.md` avec l'architecture corrigée :

---

# SimpleOrm

SimpleORM - A Lightweight JavaScript ORM for REST APIs built in ReScript.

![ReScript](https://img.shields.io/badge/rescript-%2314162c?style=for-the-badge&logo=rescript&logoColor=e34c4c) ![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white) ![Bun](https://img.shields.io/badge/Bun-%23000000.svg?style=for-the-badge&logo=bun&logoColor=white)

---

## Description

SimpleORM is a lightweight and customizable Object-Relational Mapping (ORM) library, designed specifically for ReScript to simplify interactions with PostgreSQL databases. It offers a straightforward interface for CRUD operations, query building, and schema management.

> **Note**: Currently supports only PostgreSQL.

---

## File Structure

Here is the updated file structure of the project:

```
simpleorm/
├── lib/
├── node_modules/
├── sql/
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
│   ├── datasource/
│   │   ├── Datasource.res
│   │   └── Datasource.res.js
│   ├── queries/
│   │   ├── QueryBuilder.res
│   │   ├── QueryBuilder.res.js
│   │   ├── Repository.res
│   │   └── Repository.res.js
│   ├── table-builder/
│   │   ├── Builder.res
│   │   ├── Builder.res.js
│   │   └── Schema.res
│   │   └── Schema.res.js
│   ├── types/
│   │   ├── prof-helper.ts
│   │   └── Schema.res
├── tests/
│   ├── Datasource.test.res
│   └── Datasource.test.res.js
├── .env.development
├── docker-compose.yaml
├── migration.sql
├── rescript.json
└── README.md
```

---

### Description of Key Folders:

#### `src/`

The main source folder of the SimpleORM project is organized as follows:

- **`bindings/`**: Contains ReScript bindings for PostgreSQL, such as `PgBind.res`.

- **`config/`**: Includes configuration files like `config.res` for managing environment variables and database connection settings.

- **`core/`**: Contains core functionalities of the ORM, including:
  - `Db.res`: Manages database connections.
  - `ApplyMigration.res`: Handles database migrations.

- **`datasource/`**: Manages the connection pooling and data source setup.
  - `Datasource.res`: Centralizes data source configuration.

- **`queries/`**: Contains query-building logic and repository abstractions:
  - `QueryBuilder.res`: Constructs SQL queries dynamically.
  - `Repository.res`: Implements CRUD operations for database interactions.

- **`table-builder/`**: Handles schema definitions and table management:
  - `Builder.res`: Builds SQL queries for table creation.
  - `Schema.res`: Manages table schema structures.

- **`types/`**: Defines types and helpers, such as:
  - `prof-helper.ts`: Helper functions or types for utility purposes.
  - `Schema.res`: Type definitions for schemas.

#### `tests/`

Contains test files to ensure correctness of database interactions and query operations:
- `Datasource.test.res`: Verifies the `Datasource` functionality.

---

## Development

To start the project:

1. **Install dependencies**:
   ```bash
   bun install
   ```

2. **Build and run**:
   ```bash
   bun res:build
   bun start
   ```

3. **Start the database with Docker**:
   ```bash
   docker compose up --build
   ```

4. **Apply migrations**:
   ```bash
   bun apply
   ```

# Example Use Case

The following example demonstrates how to use **SimpleORM** to manage `users` and `posts` tables in a PostgreSQL database. It includes schema creation, table migrations, and CRUD operations such as inserting, retrieving, updating, and deleting records.

---

## Schema Definition

First, we define the schemas for the `users` and `posts` tables. The `users` table contains fields like `id`, `name`, `email`, and enums for `role` and `status`. The `posts` table includes a foreign key reference to `users`.

### Users Table Schema

```rescript
let userSchema: tableSchema = {
  tableName: "users",
  schema: [
    {
      name: "id",
      _type: Int,
      primaryKey: true,
      optionnal: false,
      default: None,
      unique: false,
    },
    {
      name: "name",
      _type: String,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: true,
    },
    {
      name: "email",
      _type: String,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: true,
    },
    {
      name: "role",
      _type: Enum(["USER", "ADMIN"]),
      primaryKey: false,
      optionnal: false,
      default: Some("USER"),
      unique: false,
    },
    {
      name: "status",
      _type: Enum(["BANNED", "STANDARD", "PREMIUM"]),
      primaryKey: false,
      optionnal: true,
      default: None,
      unique: false,
    },
  ],
  foreignKeys: None,
}
```

### Posts Table Schema

```rescript
let postSchema: tableSchema = {
  tableName: "posts",
  schema: [
    {
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
    },
    {
      name: "title",
      _type: String,
      primaryKey: false,
      optionnal: false,
      default: None,
      unique: false,
    },
    {
      name: "content",
      _type: String,
      primaryKey: false,
      optionnal: true,
      default: None,
      unique: false,
    },
  ],
  foreignKeys: Some([
    {
      columnName: "user_id",
      referencedTable: "users",
      referencedColumn: "id",
    },
  ]),
}
```

---

## Migration Script

Generate the SQL scripts for table creation and apply the migrations:

```rescript
let userSQL = tableOperations.create(~tableSchema=userSchema)
let userPostSQL = tableOperations.create(~tableSchema=postSchema)

let client = await connectToDb()
await tableOperations.migrate(~toWrite=userSQL ++ userPostSQL, ~client)
await closeConnection(client)
```

This creates the `users` and `posts` tables in the PostgreSQL database.

---

## Using the `User` Module

### 1. **Create a User**

To create a new user in the `users` table:

```rescript
let client = await connectToDb()

let createUser = await User.createUser(
  ~fields=["name", "email"],
  ~values=[Query.Params.string("John Doe"), Query.Params.string("johnDoe@gmail.com")],
  client,
)

Console.log(createUser) // Logs the newly created user
await closeConnection(client)
```

---

### 2. **Retrieve Users**

#### Retrieve All Users with a Limit:

```rescript
let users = await User.getUsers(~limit=2, client)
Console.log(users) // Logs up to 2 users
```

#### Retrieve a User by ID:

```rescript
let userById = await User.getUserById(~id=1, client)
Console.log(userById) // Logs the user with ID 1
```

---

### 3. **Update Users**

#### Update Users with a Condition:

```rescript
let updateUser = await User.updateUser(
  ~fields=["name"],
  ~values=[Query.Params.string("Jane Doe for ID 1")],
  ~where=[("id", Query.Params.int(1))],
  client,
)

Console.log(updateUser) // Logs the updated user(s)
```

#### Update a User by ID:

```rescript
let updateUserById = await User.updateUserById(
  ~fields=["name"],
  ~values=[Query.Params.string("Updated Name")],
  ~id=1,
  client,
)

Console.log(updateUserById) // Logs the updated user
```

---

### 4. **Delete Users**

#### Delete a User by ID:

```rescript
let deleteUser = await User.deleteUserById(~id=1, client)
Console.log(deleteUser) // Logs confirmation of deletion
```

---

## Full Example

Here’s the full `testUser` example function to illustrate all CRUD operations:

```rescript
let testUser = async () => {
  let client = await connectToDb()

  // Apply migrations
  await tableOperations.migrate(~toWrite=userSQL ++ userPostSQL, ~client)

  // Create a user
  let createUser = await User.createUser(
    ~fields=["name", "email"],
    ~values=[Query.Params.string("John Doe"), Query.Params.string("johnDoe@gmail.com")],
    client,
  )
  Console.log(createUser)

  // Retrieve users
  let users = await User.getUsers(~limit=2, client)
  Console.log(users)

  // Retrieve user by ID
  let userById = await User.getUserById(~id=1, client)
  Console.log(userById)

  // Update user
  let updateUser = await User.updateUser(
    ~fields=["name"],
    ~values=[Query.Params.string("Jane Doe for ID 1")],
    ~where=[("id", Query.Params.int(1))],
    client,
  )
  Console.log(updateUser)

  // Update user by ID
  let updateUserById = await User.updateUserById(
    ~fields=["name"],
    ~values=[Query.Params.string("Updated Name")],
    ~id=1,
    client,
  )
  Console.log(updateUserById)

  // Delete user by ID
  let deleteUser = await User.deleteUserById(~id=1, client)
  Console.log(deleteUser)

  await closeConnection(client)
}
```

---

## Error Handling

Each function in the `User` module includes error handling to catch and handle issues such as:

- Invalid table names
- Missing `WHERE` clauses for updates
- Non-existent records

Errors are raised as exceptions (e.g., `ExceptionObject`) to ensure robust error reporting.

Example of handling errors:

```rescript
try {
  let user = await User.getUserById(~id=999, client)
  Console.log(user)
} catch {
| User.ExceptionObject(message) => Console.error("Error: " ++ message)
| _ => Console.error("An unknown error occurred")
}
```
