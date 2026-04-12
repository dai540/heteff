#' Fit a Heterogeneous Effect Forest for Observational Data
#'
#' Wraps `grf::causal_forest()` with a column-name interface and returns a
#' unified `heteff_fit` object.
#'
#' @param data A data frame containing all required columns.
#' @param outcome Name of the numeric outcome column.
#' @param treatment Name of the binary or continuous treatment column.
#' @param covariates Character vector of baseline covariate column names.
#' @param num.trees Number of trees passed to `grf::causal_forest()`.
#' @param seed Random seed passed to `grf::causal_forest()`.
#' @param ... Additional arguments passed to `grf::causal_forest()`.
#'
#' @return A `heteff_fit` object with `effect_table`, fitted forest, and
#'   variable importance.
#' @export
#'
#' @examples
#' \dontrun{
#' set.seed(1)
#' n <- 300
#' df <- data.frame(
#'   y = rnorm(n),
#'   w = rbinom(n, 1, 0.5),
#'   x1 = rnorm(n),
#'   x2 = rnorm(n)
#' )
#' fit <- fit_observational_forest(df, "y", "w", c("x1", "x2"))
#' head(as.data.frame(fit))
#' }
fit_observational_forest <- function(
    data,
    outcome,
    treatment,
    covariates,
    num.trees = 2000,
    seed = 1,
    ...) {
  .validate_data_columns(data, c(outcome, treatment, covariates))
  x <- .to_numeric_matrix(data, covariates)
  y <- as.numeric(data[[outcome]])
  w <- as.numeric(data[[treatment]])

  forest <- grf::causal_forest(
    X = x,
    Y = y,
    W = w,
    num.trees = num.trees,
    seed = seed,
    ...
  )
  pred <- stats::predict(forest)
  table <- .build_effect_table(pred)
  .new_heteff_fit(
    type = "observational",
    forest = forest,
    effect_table = table,
    columns = list(
      outcome = outcome,
      treatment = treatment,
      covariates = covariates
    )
  )
}
