open ColumnType
open ForeignKeyType

module EntityType = {
  type t = {
    name: string,
    columns: list<ColumnType.t>,
    foreignKeys: option<list<ForeignKeyType.t>>,
  }
}
