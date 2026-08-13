#' Use and automatically close a DBI connection
#'
#' Obtains a connection from `connection_provider`, passes it to `code`, and
#' closes it when `code` finishes. The connection is also closed when `code`
#' raises an error. A connection that has already been closed by `code` is not
#' closed a second time.
#'
#' `with_db_connection()` owns the connection returned by the provider. Do not
#' use it when the provider returns a shared connection whose lifecycle is
#' managed elsewhere.
#'
#' @param connection_provider A zero-argument function returning a valid
#'   [DBI::DBIConnection-class].
#' @param code A function taking the connection as its only argument.
#'
#' @return The value returned by `code`.
#' @export
#'
#' @examples
#' if (requireNamespace("RSQLite", quietly = TRUE)) {
#'   connection_provider <- function() {
#'     DBI::dbConnect(RSQLite::SQLite(), ":memory:")
#'   }
#'
#'   with_db_connection(connection_provider, function(connection) {
#'     DBI::dbGetQuery(connection, "SELECT 1 AS value")
#'   })
#' }
with_db_connection <- function(connection_provider, code) {
  if (!is.function(connection_provider)) {
    stop("`connection_provider` must be a function.", call. = FALSE)
  }
  if (!is.function(code)) {
    stop("`code` must be a function.", call. = FALSE)
  }

  connection <- connection_provider()
  if (!is_valid_db_connection(connection)) {
    stop(
      "`connection_provider` did not return a valid DBI connection.",
      call. = FALSE
    )
  }

  on.exit(disconnect_db_connection(connection), add = TRUE)
  code(connection)
}

is_valid_db_connection <- function(connection) {
  tryCatch(
    isTRUE(DBI::dbIsValid(connection)),
    error = function(error) FALSE
  )
}

disconnect_db_connection <- function(connection) {
  if (!is_valid_db_connection(connection)) {
    return(invisible(FALSE))
  }

  tryCatch(
    {
      DBI::dbDisconnect(connection)
      invisible(TRUE)
    },
    error = function(error) {
      warning(
        "Could not disconnect the DBI connection: ",
        conditionMessage(error),
        call. = FALSE
      )
      invisible(FALSE)
    }
  )
}
