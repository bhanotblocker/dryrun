# Changelog

All notable changes to Dry Run are recorded here. The format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] – 2026-04-20

### Added
- **`dryrun validate`** — static lint for `databricks.yml`. Catches missing
  entry-point files, duplicate task keys, undeclared variables and
  suspicious cloud data sources before you push to Databricks.
- **`dryrun doctor`** — single-command health check. Prints version,
  workspace, dependency versions, catalog reachability, port 8000 status,
  and surfaces the most common startup footguns (Colima `/tmp` quirk,
  port conflicts, missing `databricks.yml`).
- **`dryrun --version` / `-V`** — show the installed version and exit.
- **Notebook `%run ./other_notebook`** — chained notebooks now execute
  inline with a shared namespace, matching Databricks semantics.
- **Friendly errors for unsupported PySpark functions.** Unknown
  `F.<name>` calls (e.g. `F.percentile_approx`) now raise an
  `AttributeError` with a concrete workaround instead of a bare
  Python traceback.

### Improved
- Expanded SQL error diagnostics: unknown functions, type mismatches,
  ambiguous columns, missing catalogs, `USING DELTA` parse failures
  now all return specific hints.
- `dryrun up` warns up-front if port 8000 is already taken on the host,
  instead of silently handing the traffic to another process.
- `dryrun up` and `dryrun init` warn if you're inside `/tmp` on macOS
  (Colima does not mount `/tmp` by default).
- Notebook cell failures now surface the cell index and source snippet
  instead of a raw traceback.

### Fixed
- Notebook runner no longer crashes on unsupported cell magics
  (`%fs`, `%sh`, `%scala`, `%r`); it skips them with a log line.

## [0.1.1] – 2026-04-20

- Ship the `retail` example inside the Docker image so
  `dryrun init --example retail` works on fresh installs.
- Point the installer at `raw.githubusercontent.com` instead of an
  unrelated domain.

## [0.1.0] – 2026-04-19

- Initial public release.
