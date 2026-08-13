test_that("db_query returns a data table", {
  connection <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  on.exit(DBI::dbDisconnect(connection))

  DBI::dbWriteTable(connection, "numbers", data.frame(value = 1:3))
  result <- db_query(
    connection,
    "SELECT value FROM numbers WHERE value > ? ORDER BY value",
    params = list(1)
  )

  expect_s3_class(result, "data.table")
  expect_equal(result$value, 2:3)
})

test_that("db_query preserves columns for an empty result", {
  connection <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  on.exit(DBI::dbDisconnect(connection))

  DBI::dbWriteTable(connection, "numbers", data.frame(value = 1:3))
  result <- db_query(
    connection,
    "SELECT value FROM numbers WHERE value > ?",
    params = list(99)
  )

  expect_s3_class(result, "data.table")
  expect_identical(names(result), "value")
  expect_equal(nrow(result), 0L)
})

test_that("db_query validates SQL input", {
  connection <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  on.exit(DBI::dbDisconnect(connection))

  expect_error(db_query(connection, character()), "`sql`")
  expect_error(db_query(connection, ""), "`sql`")
  expect_error(db_query(connection, NA_character_), "`sql`")
  expect_error(db_query(connection, c("SELECT 1", "SELECT 2")), "`sql`")
})
