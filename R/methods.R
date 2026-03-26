#' Print a `heteff_fit` summary
#'
#' @param x A `heteff_fit` object.
#' @param ... Unused.
#'
#' @return The input object, invisibly.
#' @export
print.heteff_fit <- function(x, ...) {
  cat("heteff analysis\n")
  cat("  workflow:", x$analysis_type, "\n")
  cat("  estimand:", x$estimand_label, "\n")
  cat("  rows:", nrow(x$analysis_data), "\n")
  cat("  outcome:", x$spec$outcome, "\n")
  cat("  treatment:", x$spec$treatment, "\n")
  if (!is.null(x$spec$instrument)) {
    cat("  instrument:", x$spec$instrument, "\n")
  }
  if (!is.null(x$spec$event)) {
    cat("  event indicator:", x$spec$event, "\n")
  }
  cat("  covariates:", length(x$spec$covariates), "\n")
  cat("  subgroups:", nrow(x$subgroup_table), "\n")
  if (!is.null(x$estimand_table) && nrow(x$estimand_table) > 0) {
    cat("  average estimate:", round(x$estimand_table$estimate[1], 4), "\n")
  }
  invisible(x)
}

#' Plot a default subgroup-effect summary from a `heteff_fit`
#'
#' @param x A `heteff_fit` object.
#' @param ... Passed to [plot_subgroup_effects()].
#'
#' @return Draws a subgroup summary plot.
#' @export
plot.heteff_fit <- function(x, ...) {
  plot_subgroup_effects(x, ...)
}
