type ConfigSql = {
  host: string
  user: string
  password: string
  database: string
}

type ColumnSchema = {
  name: string
  type: string
  primaryKey: boolean
  nullable: boolean
  default: string
}

type TableSchema = {
  tableName: string
  schema: ColumnSchema[]
}

type TableOperations<T> = {
  create: (tableName: keyof T, schema: Record<string, string>) => Promise<void>
  drop: (tableName: keyof T) => Promise<void>
  update: (
    tableName: keyof T,
    updates: Partial<T[keyof T]>,
    conditions: Partial<T[keyof T]>,
  ) => Promise<void>
}

type QueryOperations<T> = {
  select: <K extends keyof T[keyof T]>(
    tableName: keyof T,
    columns: K[],
    conditions?: Partial<T[keyof T]>,
  ) => Promise<Pick<T[keyof T], K>[]>
  insert: (tableName: keyof T, data: T[keyof T]) => Promise<void>
  delete: (tableName: keyof T, conditions: Partial<T[keyof T]>) => Promise<void>
}

type Orm<T> = {
  table: TableOperations<T>
  query: QueryOperations<T>
}

const createTable = async (
  tableName: string,
  schema: Record<string, string>,
) => {
  // TODO: implémenter la création de table
}

export const useOrmSql = <T>(
  config: ConfigSql,
  configTable: TableSchema[],
): Orm<T> => {
  // TODO: connect to sql database using config

  // TODO: créer les tables en db
  configTable.forEach(async ({tableName, schema}) => {
    await createTable(
      tableName,
      schema.reduce(
        (acc, col) => {
          acc[col.name] = col.type
          return acc
        },
        {} as Record<string, string>,
      ),
    )
  })

  return {
    table: {
      create: async (tableName, schema) => {
        // TODO: implémenter la création de table
      },
      drop: async tableName => {
        // TODO: implémenter la suppression de table
      },
      update: async (tableName, updates, conditions) => {
        // TODO: implémenter la mise à jour de table
      },
    },
    query: {
      select: async (tableName, columns, conditions) => {
        // TODO: implémenter la sélection de données
        return [] as Pick<T[keyof T], (typeof columns)[number]>[]
      },
      insert: async (tableName, data) => {
        // TODO: implémenter l'insertion de données
      },
      delete: async (tableName, conditions) => {
        // TODO: implémenter la suppression de données
      },
    },
  }
}
