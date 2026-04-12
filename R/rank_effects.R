#' Rank Per-Sample Effect Estimates
#'
#' Returns top (or bottom) rows from a fitted `heteff_fit` object.
#'
#' @param fit A `heteff_fit` object.
#' @param n Number of rows to return.
#' @param decreasing If `TRUE`, returns largest estimated effects first.
#'
#' @return A data frame subset of `fit$effect_table`.
#' @export
#'
#' @examples
#' \dontrun{
#' top10 <- rank_effects(fit_object, n = 10)
#' }
rank_effects <- function(fit, n = 20, decreasing = TRUE) {
  if (!inherits(fit, "heteff_fit")) {
    stop("`fit` must be a heteff_fit object.", call. = FALSE)
  }
  n <- as.integer(n)
  if (is.na(n) || n <= 0L) {
    stop("`n` must be a positive integer.", call. = FALSE)
  }
  tab <- fit$effect_table
  ord <- order(tab$estimate, decreasing = isTRUE(decreasing))
  tab[utils::head(ord, n), , drop = FALSE]
}
