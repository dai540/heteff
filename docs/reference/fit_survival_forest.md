# Fit a survival causal forest workflow

Fit a survival causal forest workflow

## Usage

``` r
fit_survival_forest(
  data,
  time = "time",
  event = "event",
  treatment = "treatment",
  covariates,
  horizon,
  target = c("RMST", "survival.probability"),
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

- time:

  Observed event or censoring time column.

- event:

  Event indicator column. Use `1` for event and `0` for censoring.

- treatment:

  Treatment assignment column.

- covariates:

  Baseline covariates for confounding adjustment and heterogeneity
  discovery.

- horizon:

  Horizon used by
  [`grf::causal_survival_forest()`](https://rdrr.io/pkg/grf/man/causal_survival_forest.html).

- target:

  Survival estimand. Either `"RMST"` or `"survival.probability"`.

- sample_id:

  Optional sample identifier column.

- candidate:

  Optional treatment-comparison label column.

- num_trees:

  Number of trees for
  [`grf::causal_survival_forest()`](https://rdrr.io/pkg/grf/man/causal_survival_forest.html).

- min_node_size:

  Minimum node size for
  [`grf::causal_survival_forest()`](https://rdrr.io/pkg/grf/man/causal_survival_forest.html).

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
