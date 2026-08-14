# dbiutils 0.1.1

- Added `db_connect_from_yaml()` to create driver-independent DBI connections
  from application-owned YAML configuration files, including explicit `!env`
  references for credentials and deployment-specific values.

# dbiutils 0.1.0

- Added `db_query()` to return DBI query results as `data.table` objects.
- Added `with_db_connection()` for scoped connection lifecycle management.
- Added `read_sql_file()` for explicit, UTF-8 SQL resource loading.
- Added complete package documentation, a getting-started vignette, and a
  pkgdown website.
- Added automated checks, coverage reporting, GitHub Pages deployment, and
  GitHub releases.
