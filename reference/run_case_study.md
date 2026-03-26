# Run a built-in case study

Run a built-in case study

## Usage

``` r
run_case_study(case = available_case_studies(), num_trees = 500, seed = 123)
```

## Arguments

- case:

  Study name. One of
  [`available_case_studies()`](https://dai540.github.io/heteff/reference/available_case_studies.md).

- num_trees:

  Number of trees for the selected workflow.

- seed:

  Optional seed.

## Value

A `heteff_fit` object.
