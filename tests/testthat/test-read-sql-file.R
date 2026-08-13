test_that("read_sql_file preserves line structure", {
  path <- tempfile(fileext = ".sql")
  writeLines(c("SELECT *", "FROM example;"), path, useBytes = TRUE)

  expect_identical(read_sql_file(path), "SELECT *\nFROM example;")
})

test_that("read_sql_file reads an empty SQL file", {
  path <- tempfile(fileext = ".sql")
  file.create(path)

  expect_identical(read_sql_file(path), "")
})

test_that("read_sql_file reports missing and invalid paths", {
  missing_path <- tempfile(fileext = ".sql")

  expect_error(read_sql_file(missing_path), "SQL file not found")
  expect_error(read_sql_file(character()), "`path`")
  expect_error(read_sql_file(""), "`path`")
  expect_error(read_sql_file(NA_character_), "`path`")
  expect_error(read_sql_file(c("one.sql", "two.sql")), "`path`")
  expect_error(read_sql_file(tempdir()), "SQL file not found")
})

test_that("read_sql_file validates encoding", {
  path <- tempfile(fileext = ".sql")
  writeLines("SELECT 1;", path, useBytes = TRUE)

  expect_error(read_sql_file(path, character()), "`encoding`")
  expect_error(read_sql_file(path, ""), "`encoding`")
  expect_error(read_sql_file(path, NA_character_), "`encoding`")
  expect_error(read_sql_file(path, c("UTF-8", "latin1")), "`encoding`")
})
