# SimpleORM — contexte

ORM PostgreSQL en ReScript 11 (uncurried, `-open RescriptCore`), compilé en ESM `*.res.js` à côté des sources (ignorés par git, sauf `src/bindings/PgBind.res.js`, suivi : le garder à jour).

## Où est quoi
- `src/queries/QueryBuilder.res` : construction SQL + validation (table/colonnes via information_schema), `_fail` normalise toute erreur en `Failure(message)`.
- `src/queries/Repository.res` : CRUD générique au-dessus de QueryBuilder (`delete` est exporté `$$delete` en JS).
- `src/table-builder/Builder.res` : génération DDL (enums, CREATE TABLE, index uniques), idempotente ; `migrate` écrit `migration.sql` dans le cwd.
- `src/utils/SqlEscape.res` : `quoteIdentifier` / `quoteLiteral`, à utiliser pour tout nom ou littéral injecté dans du SQL.
- `src/datasource/Datasource.res` : API style TypeORM (`make`, `initialize`, `manager`), réutilise `Db.connectToDb`.
- `src/bindings/PgBind.res` : bindings `pg` (`PgClient` = `pg.Client`, `PgPool` = `pg.Pool`).

## Conventions / pièges
- Identifiants toujours entre guillemets : les noms de tables/colonnes sont sensibles à la casse.
- `update` / `delete` refusent de tourner sans WHERE (`InvalidWhereCondition`).
- Doc comments `/** @param ... */` seulement sur les déclarations de fonctions ; commentaires en français dans Datasource et les exemples, en anglais ailleurs.
- Ni bun ni Postgres en local par défaut : compiler avec `npx rescript` (node dans /usr/local/bin), tester contre un `docker run postgres` sur un autre port avec `DB_PORT`.
