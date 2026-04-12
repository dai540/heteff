.validate_data_columns <- function(data, columns) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  if (!is.character(columns) || length(columns) == 0L) {
    stop("Column names must be a non-empty character vector.", call. = FALSE)
  }
  missing_columns <- setdiff(columns, colnames(data))
  if (length(missing_columns) > 0L) {
    stop(
      sprintf("Missing columns: %s", paste(missing_columns, collapse = ", ")),
      call. = FALSE
    )
  }
}

.to_numeric_matrix <- function(data, covariates) {
  x <- as.matrix(data[, covariates, drop = FALSE])
  storage.mode(x) <- "double"
  x
}

.build_effect_table <- function(pred) {
  estimate <- as.numeric(pred$predictions)
  var_est <- pred$variance.estimates
  if (is.null(var_est)) {
    std_error <- rep(NA_real_, length(estimate))
  } else {
    std_error <- sqrt(pmax(as.numeric(var_est), 0))
  }
  data.frame(
    sample = seq_along(estimate),
    estimate = estimate,
    std.error = std_error,
    row.names = NULL
  )
}

.new_heteff_fit <- function(type, forest, effect_table, columns) {
  structure(
    list(
      type = type,
      fit = forest,
      effect_table = effect_table,
      variable_importance = grf::variable_importance(forest),
      columns = columns
    ),
    class = c("heteff_fit", paste0("heteff_", type, "_fit"))
  )
}
