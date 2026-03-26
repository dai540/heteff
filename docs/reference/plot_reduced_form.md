# Plot the reduced-form outcome-instrument relationship

Plot the reduced-form outcome-instrument relationship

## Usage

``` r
plot_reduced_form(fit, main = "Reduced-form relationship")
```

## Arguments

- fit:

  A `heteff_fit` object from
  [`fit_instrumental_forest()`](https://dai540.github.io/heteff/reference/fit_instrumental_forest.md).

- main:

  Plot title.

## Value

A `ggplot2` object when available; otherwise draws a base plot.
