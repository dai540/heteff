#' Fit a Heterogeneous Survival Effect Forest
#'
#' Wraps `grf::causal_survival_forest()` with a column-name interface and
#' computes out-of-bag effect predictions through `predict()`.
#'
#' @param data A data frame containing all required columns.
#' @param time Name of observed time column.
#' @param status Name of event indicator column (1 = event, 0 = censored).
#' @param treatment Name of treatment column.
#' @param covariates Character vector of baseline covariate column names.
#' @param target Prediction target passed to `grf::predict()`.
#' @param horizon Optional horizon passed to `grf::predict()`.
#' @param num.trees Number of trees passed to `grf::causal_survival_forest()`.
#' @param seed Random seed passed to `grf::causal_survival_forest()`.
#' @param ... Additional arguments passed to `grf::causal_survival_forest()`.
#'
#' @return A `heteff_fit` object.
#' @export
#'
#' @examples
#' \dontrun{
#' set.seed(2)
#' n <- 300
#' df <- data.frame(
#'   time = rexp(n, 0.2),
#'   status = rbinom(n, 1, 0.8),
#'   trt = rbinom(n, 1, 0.5),
#'   x1 = rnorm(n),
#'   x2 = rnorm(n)
#' )
#' fit <- fit_survival_forest(
#'   data = df,
#'   time = "time",
#'   status = "status",
#'   treatment = "trt",
#'   covariates = c("x1", "x2"),
#'   target = "RMST",
#'   horizon = 5
#' )
#' head(as.data.frame(fit))
#' }
fit_survival_forest <- function(
    data,
    time,
    status,
    treatment,
    covariates,
    target = "RMST",
    horizon = NULL,
    num.trees = 2000,
    seed = 1,
    ...) {
  .validate_data_columns(data, c(time, status, treatment, covariates))
  x <- .to_numeric_matrix(data, covariates)
  y <- as.numeric(data[[time]])
  d <- as.numeric(data[[status]])
  w <- as.numeric(data[[treatment]])

  forest <- grf::causal_survival_forest(
    X = x,
    Y = y,
    W = w,
    D = d,
    num.trees = num.trees,
    seed = seed,
    ...
  )

  pred <- if (is.null(horizon)) {
    stats::predict(forest, target = target)
  } else {
    stats::predict(forest, target = target, horizon = horizon)
  }
  table <- .build_effect_table(pred)
  .new_heteff_fit(
    type = "survival",
    forest = forest,
    effect_table = table,
    columns = list(
      time = time,
      status = status,
      treatment = treatment,
      covariates = covariates,
      target = target,
      horizon = horizon
    )
  )
}
