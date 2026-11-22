module SqlEscape = {
  exception InvalidIdentifier(string)
  exception InvalidLiteral(string)

  /**
   Quotes a SQL identifier (table, column, type or index name).
   Inner double quotes are doubled, so the result can never break out of the identifier.

   @param name raw identifier, must be non-empty and free of NUL bytes
   @raise InvalidIdentifier if the name is empty or contains a NUL byte
   */
  let quoteIdentifier = (name: string): string => {
    if name === "" || name->String.includes("\x00") {
      raise(InvalidIdentifier(name))
    }
    "\"" ++ name->String.replaceAll("\"", "\"\"") ++ "\""
  }

  /**
   Quotes a SQL string literal. Only used for DDL (defaults, enum values),
   data queries must always go through bound parameters.

   @param value raw value, must be free of NUL bytes
   @raise InvalidLiteral if the value contains a NUL byte
   */
  let quoteLiteral = (value: string): string => {
    if value->String.includes("\x00") {
      raise(InvalidLiteral(value))
    }
    "'" ++ value->String.replaceAll("'", "''") ++ "'"
  }
}
