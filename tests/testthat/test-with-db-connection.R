test_that("with_db_connection returns the callback value and disconnects", {
  supplied_connection <- NULL
  provider <- function() {
    supplied_connection <<- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
    supplied_connection
  }

  result <- with_db_connection(provider, function(connection) {
    DBI::dbGetQuery(connection, "SELECT 42 AS value")$value[[1]]
  })

  expect_equal(result, 42)
  expect_false(DBI::dbIsValid(supplied_connection))
})

test_that("with_db_connection disconnects when callback code fails", {
  supplied_connection <- NULL
  provider <- function() {
    supplied_connection <<- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
    supplied_connection
  }

  expect_error(
    with_db_connection(provider, function(connection) stop("callback failed")),
    "callback failed"
  )
  expect_false(DBI::dbIsValid(supplied_connection))
})

test_that("with_db_connection tolerates callback-managed disconnection", {
  supplied_connection <- NULL
  provider <- function() {
    supplied_connection <<- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
    supplied_connection
  }

  expect_no_warning(
    result <- with_db_connection(provider, function(connection) {
      DBI::dbDisconnect(connection)
      "done"
    })
  )

  expect_identical(result, "done")
  expect_false(DBI::dbIsValid(supplied_connection))
})

test_that("with_db_connection validates its arguments", {
  expect_error(with_db_connection("not a function", identity), "connection_provider")
  expect_error(with_db_connection(identity, "not a function"), "code")
  expect_error(
    with_db_connection(function() "not a connection", identity),
    "valid DBI connection"
  )
})
