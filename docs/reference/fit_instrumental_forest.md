# Fit an instrumental forest workflow

Fit an instrumental forest workflow

## Usage

``` r
fit_instrumental_forest(
  data,
  outcome = "outcome",
  treatment = "treatment",
  instrument = "instrument",
  covariates,
  sample_id = NULL,
  candidate = NULL,
  num_trees = 2000,
  min_node_size = 5,
  tree_depth = 3,
  tree_minbucket = 100L,
  tree_trim_quantiles = c(0.05, 0.95),
  seed = NULL
)
```

## Arguments

- data:

  A single analysis `data.frame`.

- outcome:

  Outcome column.

- treatment:

  Exposure or perturbation proxy column.

- instrument:

  Instrument column.

- covariates:

  Baseline adjustment or subgroup covariates.

- sample_id:

  Optional sample identifier column.

- candidate:

  Optional candidate label column.

- num_trees:

  Number of trees for
  [`grf::instrumental_forest()`](https://rdrr.io/pkg/grf/man/instrumental_forest.html).

- min_node_size:

  Minimum node size for
  [`grf::instrumental_forest()`](https://rdrr.io/pkg/grf/man/instrumental_forest.html).

- tree_depth:

  Maximum depth of the explanation tree.

- tree_minbucket:

  Minimum leaf size of the explanation tree.

- tree_trim_quantiles:

  Quantiles used to clip extreme effect estimates before fitting the
  explanation tree.

- seed:

  Optional random seed.

## Value

A `heteff_fit` object.
