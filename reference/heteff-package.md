# heteff: simple GRF workflows for heterogeneous effects

`heteff` is a small R package built around three generalized random
forest estimators:

## Details

- [`grf::causal_forest()`](https://rdrr.io/pkg/grf/man/causal_forest.html)

- [`grf::causal_survival_forest()`](https://rdrr.io/pkg/grf/man/causal_survival_forest.html)

- [`grf::instrumental_forest()`](https://rdrr.io/pkg/grf/man/instrumental_forest.html)

The package keeps the interface deliberately simple:

- one analysis table

- one method-specific fitting call

- reusable output tables

- a shallow explanation tree

- a compact set of diagnostic plots

The main exported workflows are:

- [`fit_observational_forest()`](https://dai540.github.io/heteff/reference/fit_observational_forest.md)

- [`fit_survival_forest()`](https://dai540.github.io/heteff/reference/fit_survival_forest.md)

- [`fit_instrumental_forest()`](https://dai540.github.io/heteff/reference/fit_instrumental_forest.md)

## Author

**Maintainer**: Dai <dai@example.com>
