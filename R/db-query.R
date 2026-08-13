#' Execute a query and return a data table
#'
#' Executes a SQL query through a [DBI::DBIConnection-class] and converts the result
#' to a [data.table::data.table]. The function is independent of the concrete
#' DBI backend used by the connection.
#'
#' @param connection A valid [DBI::DBIConnection-class].
#' @param sql A character scalar containing the SQL statement to execute.
#' @param params An optional list of values to bind to parameter placeholders.
#'   The placeholder syntax is defined by the DBI backend.
#' @param ... Additional arguments passed to [DBI::dbGetQuery()].
#'
#' @return A [data.table::data.table] containing the query result.
#' @export
#'
#' @examples
#' if (requireNamespace("RSQLite", quietly = TRUE)) {
#'   connection <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
#'
#'   DBI::dbWriteTable(connection, "numbers", data.frame(value = 1:3))
#'   db_query(connection, "SELECT * FROM numbers WHERE value > ?", list(1))
#'   DBI::dbDisconnect(connection)
#' }
db_query <- function(connection, sql, params = NULL, ...) {
  invalid_sql <- !is.character(sql) ||
    length(sql) != 1L ||
    is.na(sql) ||
    !nzchar(sql)

  if (invalid_sql) {
    stop("`sql` must be a single, non-empty character value.", call. = FALSE)
  }

  result <- DBI::dbGetQuery(
    conn = connection,
    statement = sql,
    params = params,
    ...
  )

  data.table::as.data.table(result)
}
