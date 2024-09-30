# SimpleOrm

SimpleORM - A Lightweight JavaScript ORM for REST APIs build in Rescript.

## Description

A lightweight, customizable Object-Relational Mapping (ORM) tool built in Rescript for working with RESTful APIs.

## Development

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

## Usage

### Schema Builder

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

### Query Builder
