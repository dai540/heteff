# Plot ranked SHAP importance

Plot ranked SHAP importance

## Usage

``` r
plot_shap_importance(shap_table, top_n = 10)
```

## Arguments

- shap_table:

  Output from
  [`explain_effect_shap()`](https://dai540.github.io/heteff/reference/explain_effect_shap.md).

- top_n:

  Number of top features to display.

## Value

A `ggplot2` object when available; otherwise draws a base plot.
