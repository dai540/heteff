#' Build a single instrument score from multiple columns
#'
#' @param data A `data.frame`.
#' @param instrument_cols Character vector of raw instrument column names.
#' @param method One of `"z_mean"`, `"mean"`, `"sum"`, or `"pca1"`.
#' @param weights Optional numeric weights.
#' @param new_col Name of the generated instrument score column.
#'
#' @return A list with `data` and `instrument_map`.
#' @export
build_instrument_score <- function(
    data,
    instrument_cols,
    method = c("z_mean", "mean", "sum", "pca1"),
    weights = NULL,
    new_col = "instrument") {
  method <- match.arg(method)
  validate_columns(data, instrument_cols, data_name = "data")

  raw_matrix <- as.matrix(data[, instrument_cols, drop = FALSE])
  if (!all(stats::complete.cases(raw_matrix))) {
    stop("Raw instrument columns must be complete for score construction.", call. = FALSE)
  }

  if (is.null(weights)) {
    weights <- rep(1, length(instrument_cols))
  }
  if (length(weights) != length(instrument_cols)) {
    stop("`weights` must have the same length as `instrument_cols`.", call. = FALSE)
  }

  score <- switch(
    method,
    z_mean = {
      scaled <- scale(raw_matrix)
      drop((scaled %*% matrix(weights / sum(weights), ncol = 1)))
    },
    mean = {
      drop((raw_matrix %*% matrix(weights / sum(weights), ncol = 1)))
    },
    sum = {
      drop((raw_matrix %*% matrix(weights, ncol = 1)))
    },
    pca1 = {
      pca <- stats::prcomp(raw_matrix, center = TRUE, scale. = TRUE)
      pca$x[, 1]
    }
  )

  out <- data
  out[[new_col]] <- as.numeric(score)

  instrument_map <- data.frame(
    raw_instrument = instrument_cols,
    weight = weights,
    method = method,
    output_column = new_col,
    stringsAsFactors = FALSE
  )

  list(data = out, instrument_map = instrument_map)
}
