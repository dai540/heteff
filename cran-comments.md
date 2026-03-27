## Resubmission

Initial submission.

## Test environments

- local Windows 11 x64, R 4.5.1

## R CMD check results

0 errors | 1 warning | 4 notes

### Notes

- URL-related notes were produced in a network-restricted local environment.
  The package URLs are valid project URLs:
  - https://dai540.github.io/heteff/
  - https://github.com/dai540/heteff
  - https://github.com/dai540/heteff/issues
- A note about `README.md` / `NEWS.md` being unchecked without `pandoc` was
  produced by the local Windows check environment.
- A note about HTML validation was produced because `tidy` is not installed
  locally.
- A note about current time verification was produced by the local check
  environment.

### Warning

- A warning about `qpdf` was produced because the `qpdf` system utility is not
  installed in the local Windows check environment.

## Additional comments

- The package provides a focused interface to three `grf` workflows:
  `causal_forest()`, `causal_survival_forest()`, and `instrumental_forest()`.
- The package includes tutorials, case studies, reusable effect tables, and
  compact visualization helpers for heterogeneous effect analysis.
