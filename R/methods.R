#' Common Methods for `heteff_fit` Objects
#'
#' @param x A `heteff_fit` object.
#' @param ... Not used.
#'
#' @name heteff_fit_methods
NULL

#' @rdname heteff_fit_methods
#' @export
print.heteff_fit <- function(x, ...) {
  cat("heteff_fit\n")
  cat("  type: ", x$type, "\n", sep = "")
  cat("  samples: ", nrow(x$effect_table), "\n", sep = "")
  cat(
    "  estimate mean (sd): ",
    format(mean(x$effect_table$estimate), digits = 4),
    " (",
    format(stats::sd(x$effect_table$estimate), digits = 4),
    ")\n",
    sep = ""
  )
  invisible(x)
}

#' @rdname heteff_fit_methods
#' @export
as.data.frame.heteff_fit <- function(x, ...) {
  x$effect_table
}

#' @rdname heteff_fit_methods
#' @export
plot.heteff_fit <- function(x, ...) {
  graphics::hist(
    x$effect_table$estimate,
    main = sprintf("Estimated Effects (%s)", x$type),
    xlab = "Estimated effect",
    border = "white",
    col = "#377eb8"
  )
  invisible(x)
}
