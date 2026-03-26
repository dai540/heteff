# Plot the treatment-outcome relationship for an observational workflow

Plot the treatment-outcome relationship for an observational workflow

## Usage

``` r
plot_treatment_outcome(fit, main = "Treatment-outcome relationship")
```

## Arguments

- fit:

  A `heteff_fit` object from an observational or survival workflow.

- main:

  Plot title.

## Value

A `ggplot2` object when available; otherwise draws a base plot.
