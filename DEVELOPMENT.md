# Maintaining dbiutils

This document records the package-maintenance workflow. Contributor-facing
instructions are in [CONTRIBUTING.md](CONTRIBUTING.md).

## Routine validation

Run these commands from the package root:

```r
devtools::load_all()
devtools::build_readme()
devtools::document()
devtools::test()
devtools::check()
```

Run the coverage report when behavior or tests change:

```r
install.packages(c("covr", "DT", "htmltools"))
coverage <- covr::package_coverage()
coverage
covr::report(coverage)
```

## GitHub repository setup

The repository uses the following GitHub features:

- **Actions** for package checks, coverage, releases, and site publication;
- **Pages**, with **GitHub Actions** selected as the deployment source;
- a repository secret named `CODECOV_TOKEN` for Codecov uploads;
- Dependabot for monthly GitHub Actions update proposals.

To configure Codecov:

1. Add `ultreia-io/dbiutils` at <https://app.codecov.io/>.
2. Copy its repository upload token.
3. Open **GitHub → Settings → Secrets and variables → Actions**.
4. Create the repository secret `CODECOV_TOKEN`.

The coverage workflow always creates downloadable HTML and Cobertura reports.
The Codecov upload step runs only when the secret is available.

## Package website

Build and preview the pkgdown site locally:

```r
pkgdown::build_site()
pkgdown::preview_site()
```

The generated `docs/` directory is intentionally ignored. The Website workflow
publishes the site from a `v*` release tag. Perform Release starts it after a
successful release; it can also be run manually from the Actions page.

## Release procedure

Before the first automated release, ensure `PerformRelease.yaml` is present on
the default branch (`develop`); GitHub only exposes manual workflows from the
default branch.

Prepare the release on the default `develop` branch:

1. Add a `# dbiutils x.y.z` section to `NEWS.md` and describe the release.
2. Regenerate documentation and run the complete validation sequence.
3. Commit and push `develop`.
4. Open **GitHub → Actions → Perform Release**, choose **Run workflow**, enter
   `x.y.z`, and start the workflow.

Do not create the release branch or update `DESCRIPTION` locally. Perform
Release owns the complete Gitflow operation:

1. It creates `release/x.y.z` from `develop`, updates `DESCRIPTION`, and pushes
   the release candidate.
2. It calls the Build and Test workflows in parallel against the exact release
   commit.
3. If either workflow fails, it stops without changing `main` or creating a
   tag. The release branch remains available for inspection and fixes.
4. If both workflows succeed, it verifies that the branch still points to the
   tested commit, merges it into `main`, creates `v<version>`, and merges the tag
   back into `develop`.
5. It atomically pushes `main`, `develop`, and the tag, deletes the release
   branch, and starts the Website and Release workflows.

To retry a failed release, check out `release/x.y.z`, commit and push the fix,
then run Perform Release again with the same version.

GitHub does not trigger new workflows for ordinary pushes created with
`GITHUB_TOKEN`, so Perform Release explicitly starts Website and Release after
the tag has been created. Tags pushed outside GitHub Actions continue to trigger
those workflows normally.

The Release workflow verifies that the tag matches `DESCRIPTION` and points to
a commit on `main`, builds and checks the source archive, creates the GitHub
release, and attaches both the archive and its SHA-256 checksum.

Do not create the tag or GitHub release manually. Repository rules must allow
the Perform Release workflow to create `release/*` branches and update `main`
and `develop`.

## Starting the next development cycle

After a release:

1. Increase `Version` in `DESCRIPTION` to the next development version.
2. Add a new development heading to `NEWS.md`.
3. Commit the change to `develop`.
