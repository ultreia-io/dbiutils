test_that("db_connect_from_yaml creates a DBI connection", {
  config_file <- tempfile(fileext = ".yaml")
  writeLines("dbname: ':memory:'", config_file, useBytes = TRUE)

  connection <- db_connect_from_yaml(RSQLite::SQLite(), config_file)
  on.exit(DBI::dbDisconnect(connection), add = TRUE)

  expect_true(DBI::dbIsValid(connection))
  expect_identical(DBI::dbGetQuery(connection, "SELECT 1 AS value")$value, 1L)
})

test_that("db_connect_from_yaml validates its inputs", {
  config_file <- tempfile(fileext = ".yaml")
  writeLines("dbname: ':memory:'", config_file, useBytes = TRUE)

  expect_error(db_connect_from_yaml(NULL, config_file), "`drv`")
  expect_error(
    db_connect_from_yaml(RSQLite::SQLite(), character()),
    "`config_file`"
  )
  expect_error(
    db_connect_from_yaml(RSQLite::SQLite(), tempfile(fileext = ".yaml")),
    "not found"
  )
  expect_error(
    db_connect_from_yaml(RSQLite::SQLite(), tempdir()),
    "not found"
  )
})

test_that("db_connect_from_yaml requires a connection mapping", {
  config_file <- tempfile(fileext = ".yaml")

  writeLines("- one\n- two", config_file, useBytes = TRUE)
  expect_error(
    db_connect_from_yaml(RSQLite::SQLite(), config_file),
    "top-level mapping"
  )

  writeLines("drv: forbidden", config_file, useBytes = TRUE)
  expect_error(
    db_connect_from_yaml(RSQLite::SQLite(), config_file),
    "must not contain a `drv`"
  )
})

test_that("YAML configuration resolves explicit environment references", {
  variable <- "DBIUTILS_TEST_DBNAME"
  old_value <- Sys.getenv(variable, unset = NA_character_)
  on.exit({
    if (is.na(old_value)) {
      Sys.unsetenv(variable)
    } else {
      do.call(Sys.setenv, stats::setNames(list(old_value), variable))
    }
  }, add = TRUE)

  do.call(Sys.setenv, stats::setNames(list(":memory:"), variable))
  config_file <- tempfile(fileext = ".yaml")
  writeLines(
    paste("dbname: !env", variable),
    config_file,
    useBytes = TRUE
  )

  connection <- db_connect_from_yaml(RSQLite::SQLite(), config_file)
  on.exit(DBI::dbDisconnect(connection), add = TRUE)
  expect_true(DBI::dbIsValid(connection))
})

test_that("YAML environment references must be valid and available", {
  variable <- "DBIUTILS_TEST_MISSING_VALUE"
  old_value <- Sys.getenv(variable, unset = NA_character_)
  on.exit({
    if (!is.na(old_value)) {
      do.call(Sys.setenv, stats::setNames(list(old_value), variable))
    }
  }, add = TRUE)
  Sys.unsetenv(variable)

  config_file <- tempfile(fileext = ".yaml")
  writeLines(paste("dbname: !env", variable), config_file, useBytes = TRUE)
  expect_error(
    db_connect_from_yaml(RSQLite::SQLite(), config_file),
    paste0("Environment variable `", variable, "`.*not set")
  )

  writeLines("dbname: !env invalid-name", config_file, useBytes = TRUE)
  expect_error(
    db_connect_from_yaml(RSQLite::SQLite(), config_file),
    "must name one valid environment variable"
  )
})
