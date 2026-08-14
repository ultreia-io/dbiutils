
<!-- README.md is generated from README.Rmd. Please edit README.Rmd. -->

# dbiutils

**Production (`main`)**
[![Codecov](https://codecov.io/gh/ultreia-io/dbiutils/branch/main/graph/badge.svg)](https://app.codecov.io/gh/ultreia-io/dbiutils/tree/main)
[![Latest
release](https://img.shields.io/github/v/release/ultreia-io/dbiutils?display_name=tag&sort=semver)](https://github.com/ultreia-io/dbiutils/releases/latest)

**Development (`develop`)**
[![Build](https://github.com/ultreia-io/dbiutils/actions/workflows/Build.yaml/badge.svg?branch=develop)](https://github.com/ultreia-io/dbiutils/actions/workflows/Build.yaml?query=branch%3Adevelop)
[![Test](https://github.com/ultreia-io/dbiutils/actions/workflows/Test.yaml/badge.svg?branch=develop)](https://github.com/ultreia-io/dbiutils/actions/workflows/Test.yaml?query=branch%3Adevelop)
[![Codecov](https://codecov.io/gh/ultreia-io/dbiutils/branch/develop/graph/badge.svg)](https://app.codecov.io/gh/ultreia-io/dbiutils/tree/develop)

[![Website](https://github.com/ultreia-io/dbiutils/actions/workflows/Website.yaml/badge.svg)](https://github.com/ultreia-io/dbiutils/actions/workflows/Website.yaml)
[![License](https://img.shields.io/github/license/ultreia-io/dbiutils)](https://github.com/ultreia-io/dbiutils/blob/main/LICENSE)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

`dbiutils` is a small, driver-independent R package providing reusable
helpers for common [DBI](https://dbi.r-dbi.org/) workflows. It
deliberately contains no database-specific, schema-specific, or
application-specific logic.

Package website: <https://ultreia-io.github.io/dbiutils/>

## Features

- `db_query()` executes a parameterized query and returns a
  `data.table`.
- `db_connect_from_yaml()` creates a connection from YAML configuration.
- `with_db_connection()` safely manages a short-lived DBI connection.
- `read_sql_file()` reads a SQL statement from an explicit UTF-8 file.
- No database driver is imposed on applications using the package.

## Documentation

- [Getting
  started](https://ultreia-io.github.io/dbiutils/articles/dbiutils.html)
- [Function reference](https://ultreia-io.github.io/dbiutils/reference/)
- [Changelog](https://ultreia-io.github.io/dbiutils/news/)

## Installation

Install the latest released version from GitHub:

``` r
install.packages("pak")
pak::pak("ultreia-io/dbiutils@*release")
```

Install the current development version from the default `develop`
branch:

``` r
pak::pak("ultreia-io/dbiutils")
```

## Usage

``` r
library(dbiutils)
```

A connection can be configured in an application-owned YAML file:

``` yaml
host: localhost
port: 5432
dbname: application
user: application
password: !env APPLICATION_DB_PASSWORD
client_encoding: UTF8
```

The `!env` tag resolves the value at connection time and fails if the
named environment variable is not set. This keeps credentials out of
project files and allows development, CI, and production to provide
different secrets.

### Store local passwords in the operating system keyring

For local development, install the optional `keyring` package and
register the password once. `key_set()` prompts securely, so the
password is not typed into R code or recorded in `.Rhistory`:

``` r
install.packages("keyring")
keyring::key_set("application-db")
```

At the beginning of each R session, retrieve the password and expose it
under the name referenced by the YAML file:

``` r
Sys.setenv(
  APPLICATION_DB_PASSWORD = keyring::key_get("application-db")
)
```

The resulting flow is: operating system keyring → `key_get()` → process
environment → `!env` → `DBI::dbConnect()`. The keyring entry persists
between R sessions, while the environment variable exists only in the
current R process. Remove it when the database work is complete:

``` r
Sys.unsetenv("APPLICATION_DB_PASSWORD")
```

Use `keyring::default_backend()` to inspect the active credential
backend. In CI and production, inject the environment variable from the
platform’s secret manager instead of using a local keyring. Do not place
the literal password in YAML, `.Renviron`, R source code, or shell
history.

The application supplies its DBI driver when opening the connection:

``` r
postgres_connection <- function() {
  db_connect_from_yaml(RPostgres::Postgres(), "database.yaml")
}
```

``` r
sqlite_connection <- function() {
  DBI::dbConnect(RSQLite::SQLite(), ":memory:")
}

result <- with_db_connection(sqlite_connection, function(connection) {
  DBI::dbWriteTable(connection, "numbers", data.frame(value = 1:5))

  db_query(
    connection,
    "SELECT value FROM numbers WHERE value > ? ORDER BY value",
    params = list(2)
  )
})

result
```

SQL statements can be kept in separate files:

``` r
sql <- read_sql_file(file.path("sql", "find_numbers.sql"))
```

The package imports `DBI`, `data.table`, and `yaml`, but no database
driver. Applications remain responsible for selecting and configuring
`RPostgres`, `RSQLite`, `odbc`, or another DBI-compatible backend.

## Relationship with db-schema-atlas

The `db-schema-atlas` project can replace its original helpers as
follows:

| Original function  | `dbiutils` function    |
|:-------------------|:-----------------------|
| `query()`          | `db_query()`           |
| `use_connection()` | `with_db_connection()` |
| `read_sql()`       | `read_sql_file()`      |

Unlike the original `read_sql()`, `read_sql_file()` receives the
complete file path. Atlas should locate packaged SQL resources with
`system.file()` and pass the resolved path to this function.

## Development

From the package root, run:

``` r
devtools::load_all()     # Load changes without installing
devtools::build_readme() # Rebuild README.md from README.Rmd
devtools::document()     # Regenerate NAMESPACE and man/
devtools::test()         # Run the test suite
devtools::check()        # Perform a complete package check
devtools::install()      # Install the package locally
```

### Using RStudio

RStudio is optional. RStudio users can run the R commands above in the
Console and use the Git pane to switch branches, commit, and push. The
same workflow works with any editor, R console, and Git client.

Generate an interactive test coverage report with:

``` r
install.packages(c("covr", "DT", "htmltools"))
coverage <- covr::package_coverage()
coverage
covr::report(coverage)
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution requirements and
[DEVELOPMENT.md](DEVELOPMENT.md) for the complete maintainer workflow.

### Build the website locally

The package website is built with [pkgdown](https://pkgdown.r-lib.org/):

``` r
install.packages("pkgdown")
pkgdown::build_site()
pkgdown::preview_site()
```

The generated website is written to `docs/`. The
`.github/workflows/Website.yaml` workflow builds and publishes it
automatically from release tags. It can also be run manually from the
GitHub Actions page.

### Create a release

Releases follow Gitflow and are performed through the [Perform Release
workflow](https://github.com/ultreia-io/dbiutils/actions/workflows/PerformRelease.yaml).

Prepare the release on the default `develop` branch:

1.  Add the release section to `NEWS.md`:

``` markdown
# dbiutils 0.1.1

- Describe the changes included in this release.
```

2.  Validate the package locally:

``` r
devtools::build_readme()
devtools::document()
devtools::test()
devtools::check()
```

3.  Commit and push `develop`.
4.  Open **GitHub → Actions → Perform Release**, select **Run
    workflow**, enter `0.1.1`, and start the workflow.

GitHub then owns the complete release cycle. It creates `release/0.1.1`,
sets the version in `DESCRIPTION`, and runs Build and Test in parallel
against the same immutable release commit. A failure leaves the release
branch available for correction and does not modify `main` or create a
tag.

After both validations succeed, the workflow merges the candidate into
`main`, creates `v0.1.1`, merges it back into `develop`, atomically
pushes all release references, deletes the release branch, and starts
the Website and Release workflows.

The tag-driven Release workflow builds and checks the source package,
creates the GitHub release, and attaches the package archive and its
SHA-256 checksum. Do not create the tag or GitHub release manually.

## Contributing

Bug reports and focused contributions are welcome. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Please
report security vulnerabilities privately as described in
[SECURITY.md](SECURITY.md).

## License

See the [LICENSE](LICENSE) file.
