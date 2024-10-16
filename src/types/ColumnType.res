module ColumnType = {
  type t = {
    name: string,
    type_: string,
    primaryKey: bool,
    optionnal: bool,
    default: option<string>,
    unique: bool,
  }
}
