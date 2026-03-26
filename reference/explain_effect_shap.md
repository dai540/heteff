# Compute SHAP-style explanations for fitted local IV effects

Compute SHAP-style explanations for fitted local IV effects

## Usage

``` r
explain_effect_shap(fit, nsim = 64)
```

## Arguments

- fit:

  A `heteff_fit` object.

- nsim:

  Number of Monte Carlo repetitions used by `fastshap`.

## Value

A `data.frame` with one row per sample and one SHAP column per
covariate.
