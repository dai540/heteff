#' heteff: simple GRF workflows for heterogeneous effects
#'
#' `heteff` is a small R package built around three generalized random forest
#' estimators:
#'
#' - `grf::causal_forest()`
#' - `grf::causal_survival_forest()`
#' - `grf::instrumental_forest()`
#'
#' The package keeps the interface deliberately simple:
#'
#' - one analysis table
#' - one method-specific fitting call
#' - reusable output tables
#' - a shallow explanation tree
#' - a compact set of diagnostic plots
#'
#' The main exported workflows are:
#'
#' - `fit_observational_forest()`
#' - `fit_survival_forest()`
#' - `fit_instrumental_forest()`
#'
#' @import survival
#' @importFrom utils globalVariables
#' @importFrom stats na.omit
#' @keywords internal
"_PACKAGE"

utils::globalVariables(c(
  "effect_hat",
  "effect_high",
  "effect_low",
  "effect_mean",
  "event_label",
  "covariate",
  "feature",
  "importance",
  "label",
  "mean_abs_shap",
  "outcome_value",
  "treatment_value",
  "x_value",
  "y_value"
))
