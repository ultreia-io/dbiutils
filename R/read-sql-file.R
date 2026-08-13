#' Read a SQL statement from a file
#'
#' Reads an explicitly located text file using UTF-8 by default and joins its
#' lines with newline characters. No assumption is made about the current
#' working directory or the location of a project-level `sql` directory.
#'
#' @param path A character scalar containing the path to a SQL file.
#' @param encoding The text encoding passed to [base::readLines()].
#'
#' @return A character scalar containing the SQL statement.
#' @export
#'
#' @examples
#' sql_file <- tempfile(fileext = ".sql")
#' writeLines(c("SELECT *", "FROM example;"), sql_file)
#' read_sql_file(sql_file)
read_sql_file <- function(path, encoding = "UTF-8") {
  invalid_path <- !is.character(path) ||
    length(path) != 1L ||
    is.na(path) ||
    !nzchar(path)

  if (invalid_path) {
    stop("`path` must be a single, non-empty character value.", call. = FALSE)
  }

  invalid_encoding <- !is.character(encoding) ||
    length(encoding) != 1L ||
    is.na(encoding) ||
    !nzchar(encoding)

  if (invalid_encoding) {
    stop("`encoding` must be a single, non-empty character value.", call. = FALSE)
  }

  expanded_path <- path.expand(path)
  if (!file.exists(expanded_path) || dir.exists(expanded_path)) {
    stop("SQL file not found: ", path, call. = FALSE)
  }

  paste(
    readLines(expanded_path, warn = FALSE, encoding = encoding),
    collapse = "\n"
  )
}
