#' Fit a Heterogeneous Instrumental-Variable Forest
#'
#' Wraps `grf::instrumental_forest()` with a column-name interface.
#'
#' @param data A data frame containing all required columns.
#' @param outcome Name of outcome column.
#' @param treatment Name of exposure or treatment column.
#' @param instrument Name of instrument column.
#' @param covariates Character vector of baseline covariate column names.
#' @param num.trees Number of trees passed to `grf::instrumental_forest()`.
#' @param seed Random seed passed to `grf::instrumental_forest()`.
#' @param ... Additional arguments passed to `grf::instrumental_forest()`.
#'
#' @return A `heteff_fit` object.
#' @export
#'
#' @examples
#' \dontrun{
#' set.seed(3)
#' n <- 400
#' z <- rbinom(n, 1, 0.5)
#' x1 <- rnorm(n)
#' x2 <- rnorm(n)
#' w <- 0.6 * z + 0.4 * x1 + rnorm(n)
#' y <- 1.2 * w + 0.5 * x2 + rnorm(n)
#' df <- data.frame(y = y, w = w, z = z, x1 = x1, x2 = x2)
#'
#' fit <- fit_instrumental_forest(
#'   data = df,
#'   outcome = "y",
#'   treatment = "w",
#'   instrument = "z",
#'   covariates = c("x1", "x2")
#' )
#' head(as.data.frame(fit))
#' }
fit_instrumental_forest <- function(
    data,
    outcome,
    treatment,
    instrument,
    covariates,
    num.trees = 2000,
    seed = 1,
    ...) {
  .validate_data_columns(data, c(outcome, treatment, instrument, covariates))
  x <- .to_numeric_matrix(data, covariates)
  y <- as.numeric(data[[outcome]])
  w <- as.numeric(data[[treatment]])
  z <- as.numeric(data[[instrument]])

  forest <- grf::instrumental_forest(
    X = x,
    Y = y,
    W = w,
    Z = z,
    num.trees = num.trees,
    seed = seed,
    ...
  )
  pred <- stats::predict(forest)
  table <- .build_effect_table(pred)
  .new_heteff_fit(
    type = "instrumental",
    forest = forest,
    effect_table = table,
    columns = list(
      outcome = outcome,
      treatment = treatment,
      instrument = instrument,
      covariates = covariates
    )
  )
}
