# Run a causalTree-style exploratory analysis

Run a causalTree-style exploratory analysis

## Usage

``` r
fit_causal_tree_explorer(
  data,
  outcome = "outcome",
  treatment = "treatment",
  covariates,
  sample_id = NULL,
  treatment_binary = NULL,
  treatment_cut = c("median", "mean", "zero"),
  split_rule = "CT",
  honest = TRUE,
  minsize = 20,
  xval = 5,
  prune = TRUE
)
```

## Arguments

- data:

  A `data.frame`.

- outcome:

  Name of the outcome column.

- treatment:

  Name of the treatment column.

- covariates:

  Character vector of covariate column names.

- sample_id:

  Optional sample identifier column.

- treatment_binary:

  Optional binary treatment column. If `NULL`, a binary treatment is
  created from `treatment_cut`.

- treatment_cut:

  One of `"median"`, `"mean"`, or `"zero"` when a binary treatment must
  be derived from a continuous treatment.

- split_rule:

  Split rule passed to
  [`htetree::causalTree()`](https://rdrr.io/pkg/htetree/man/causalTree.html).

- honest:

  Whether to request honest splitting.

- minsize:

  Minimum treated and control size per leaf.

- xval:

  Number of cross-validation folds.

- prune:

  Whether to prune to the cross-validated optimal cp.

## Value

A list containing the `causal_tree`, `tree_table`, and the analysis data
used by the explorer.
