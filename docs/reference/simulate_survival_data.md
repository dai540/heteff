# Simulate data for a survival-forest workflow

Simulate data for a survival-forest workflow

## Usage

``` r
simulate_survival_data(n = 1500, seed = 123, horizon = 18)
```

## Arguments

- n:

  Number of rows.

- seed:

  Random seed.

- horizon:

  Truncation horizon used in the design.

## Value

A synthetic `data.frame` for
[`fit_survival_forest()`](https://dai540.github.io/heteff/reference/fit_survival_forest.md).
