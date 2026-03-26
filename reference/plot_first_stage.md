# Plot the first-stage treatment-instrument relationship

Plot the first-stage treatment-instrument relationship

## Usage

``` r
plot_first_stage(fit, main = "First-stage relationship")
```

## Arguments

- fit:

  A `heteff_fit` object from
  [`fit_instrumental_forest()`](https://dai540.github.io/heteff/reference/fit_instrumental_forest.md).

- main:

  Plot title.

## Value

A `ggplot2` object when available; otherwise draws a base plot.
