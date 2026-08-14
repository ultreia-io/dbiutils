#' Connect to a database using YAML configuration
#'
#' Reads connection arguments from a YAML file and passes them to
#' [DBI::dbConnect()]. The YAML document must contain a top-level mapping whose
#' keys are connection argument names supported by the selected DBI driver.
#'
#' Values tagged with `!env` are read from environment variables. For example,
#' `password: !env APPLICATION_DB_PASSWORD` keeps the password out of the YAML
#' file. An error is raised if the referenced variable is not set.
#'
#' For local development, the optional `keyring` package can retrieve a secret
#' from the operating system credential store. Copy that value into the
#' referenced environment variable for the duration of the R session, then
#' unset the variable when the database work is complete. CI and production
#' should inject the same variable from their secret manager.
#'
#' `dbiutils` does not select or import a database driver. The consuming
#' application supplies the driver and remains responsible for installing it.
#'
#' @param drv A [DBI::DBIDriver-class] object created by the consuming
#'   application.
#' @param config_file A path to a UTF-8 YAML file containing named connection
#'   arguments.
#'
#' @return A [DBI::DBIConnection-class] object returned by [DBI::dbConnect()].
#' @export
#'
#' @examples
#' if (requireNamespace("RSQLite", quietly = TRUE)) {
#'   config_file <- tempfile(fileext = ".yaml")
#'   writeLines("dbname: ':memory:'", config_file, useBytes = TRUE)
#'
#'   connection <- db_connect_from_yaml(RSQLite::SQLite(), config_file)
#'   DBI::dbDisconnect(connection)
#' }
db_connect_from_yaml <- function(drv, config_file) {
  if (!inherits(drv, "DBIDriver")) {
    stop("`drv` must be a DBI driver.", call. = FALSE)
  }
  if (
    !is.character(config_file) || length(config_file) != 1L ||
      is.na(config_file) || !nzchar(config_file)
  ) {
    stop("`config_file` must be one non-empty path.", call. = FALSE)
  }
  if (!file.exists(config_file) || dir.exists(config_file)) {
    stop("YAML configuration file not found: ", config_file, call. = FALSE)
  }

  config <- yaml::read_yaml(
    config_file,
    fileEncoding = "UTF-8",
    handlers = list(env = mark_yaml_environment_variable)
  )
  if (
    !is.list(config) || is.null(names(config)) || !length(config) ||
      any(is.na(names(config))) || any(!nzchar(names(config)))
  ) {
    stop(
      "YAML configuration must contain a non-empty top-level mapping.",
      call. = FALSE
    )
  }
  if ("drv" %in% names(config)) {
    stop("YAML configuration must not contain a `drv` entry.", call. = FALSE)
  }

  config <- lapply(config, resolve_yaml_environment_variables)
  do.call(DBI::dbConnect, c(list(drv = drv), config))
}

mark_yaml_environment_variable <- function(variable) {
  structure(
    variable,
    class = c("dbiutils_yaml_environment_variable", "character")
  )
}

resolve_yaml_environment_variables <- function(value) {
  if (inherits(value, "dbiutils_yaml_environment_variable")) {
    return(read_yaml_environment_variable(unclass(value)))
  }
  if (is.list(value)) {
    return(lapply(value, resolve_yaml_environment_variables))
  }
  value
}

read_yaml_environment_variable <- function(variable) {
  if (
    !is.character(variable) || length(variable) != 1L ||
      is.na(variable) ||
      !grepl("^[A-Za-z_][A-Za-z0-9_]*$", variable)
  ) {
    stop("`!env` must name one valid environment variable.", call. = FALSE)
  }

  value <- Sys.getenv(variable, unset = NA_character_)
  if (is.na(value)) {
    stop(
      "Environment variable `", variable,
      "` referenced by YAML configuration is not set.",
      call. = FALSE
    )
  }
  value
}
