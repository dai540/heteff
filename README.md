# heteff

`heteff` is a minimal R package for heterogeneous effect estimation with
selected generalized random forest workflows from `grf`.

https://dai540.github.io/heteff/

## 1. Purpose

The package is designed for a narrow scope:

- fit heterogeneous effect models with forest estimators,
- return simple per-sample effect tables,
- rank high-effect subgroups without adding large dependencies or large datasets.

This repository is intentionally compact and avoids bundled heavy data.

## 2. Core Design

`heteff` keeps only three estimators as first-class APIs:

- observational effect heterogeneity (`causal_forest`)
- right-censored heterogeneous effects (`causal_survival_forest`)
- IV-based local heterogeneous effects (`instrumental_forest`)

The package does not redefine the estimation theory in `grf`; it provides a
consistent interface and output format for day-to-day analysis.

## 3. Installation

Install from CRAN (after CRAN publication):

```r
install.packages("heteff")
```

Install development version from GitHub:

```r
pak::pak("dai540/heteff")
remotes::install_github("dai540/heteff")
```

## 4. Input Contract

All fitters use one rectangular data frame and column names.

Required fields depend on the estimator:

1. `fit_observational_forest()`
- `outcome`, `treatment`, `covariates`
2. `fit_survival_forest()`
- `time`, `status`, `treatment`, `covariates`
3. `fit_instrumental_forest()`
- `outcome`, `treatment`, `instrument`, `covariates`

`covariates` is a character vector of baseline columns used as `X`.

## 5. Output Contract

Each fitter returns an S3 object (`heteff_fit`) with:

- `type`: model type (`observational`, `survival`, `instrumental`)
- `fit`: raw `grf` model object
- `effect_table`: per-sample estimates (`sample`, `estimate`, `std.error`)
- `variable_importance`: `grf::variable_importance` named vector
- `columns`: column mapping used to fit the model

`as.data.frame()` returns `effect_table`, and `rank_effects()` returns top rows.

## 6. Statistical Target (High-Level)

The package wraps three common targets:

1. Conditional treatment effect:
   $\tau(x) = E[Y(1)-Y(0)\mid X=x]$
2. Conditional survival effect surrogate (target/horizon via `predict`)
3. Conditional local IV effect surrogate:
   $\tau_{IV}(x) = \mathrm{Cov}(Y,Z\mid X=x) / \mathrm{Cov}(W,Z\mid X=x)$

Interpretation still depends on identification assumptions in each design.

## 7. Quick Start

```r
library(heteff)

set.seed(1)
n <- 400
df <- data.frame(
  outcome = rnorm(n),
  treatment = rbinom(n, 1, 0.5),
  instrument = rbinom(n, 1, 0.5),
  x1 = rnorm(n),
  x2 = rnorm(n),
  x3 = rnorm(n)
)

fit_obs <- fit_observational_forest(
  data = df,
  outcome = "outcome",
  treatment = "treatment",
  covariates = c("x1", "x2", "x3")
)

head(as.data.frame(fit_obs))
rank_effects(fit_obs, n = 10)
plot(fit_obs)
```

## 8. What Is Implemented

- unified wrappers for three `grf` heterogeneous-effect estimators
- unified result object and table format
- minimal ranking helper
- pkgdown site with Getting Started / Guides / Tutorials / Reference articles

## 9. What Is Not Implemented Yet

- policy learning and treatment assignment optimization
- SHAP-based explanation
- automatic causal tree rule extraction
- latent treatment modeling or proxy-treatment calibration
- built-in instrument construction module for domain-specific pipelines

## 10. Repository Structure

Minimal structure used in this repository:

- `R/`: package functions
- `vignettes/`: articles for pkgdown
- `.github/workflows/pkgdown.yaml`: website deployment
- `README.md`: user-facing package overview

No large data files are stored in this package.
