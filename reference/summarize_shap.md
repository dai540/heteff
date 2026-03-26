# Summarize SHAP values into a ranked importance table

Summarize SHAP values into a ranked importance table

## Usage

``` r
summarize_shap(shap_table)
```

## Arguments

- shap_table:

  Output from
  [`explain_effect_shap()`](https://dai540.github.io/heteff/reference/explain_effect_shap.md).

## Value

A data frame with one row per covariate and its mean absolute SHAP
value.
