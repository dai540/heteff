#' Compute SHAP-style explanations for fitted local IV effects
#'
#' @param fit A `heteff_fit` object.
#' @param nsim Number of Monte Carlo repetitions used by `fastshap`.
#'
#' @return A `data.frame` with one row per sample and one SHAP column per covariate.
#' @export
explain_effect_shap <- function(fit, nsim = 64) {
  if (!inherits(fit, "heteff_fit")) {
    stop("`fit` must be a heteff_fit object.", call. = FALSE)
  }
  if (!requireNamespace("fastshap", quietly = TRUE)) {
    stop("Package 'fastshap' is required for explain_effect_shap().", call. = FALSE)
  }

  x <- fit$analysis_data[, fit$spec$covariates, drop = FALSE]
  pred_wrapper <- function(object, newdata) {
    preds <- stats::predict(object, newdata = as.matrix(newdata))
    as.numeric(preds$predictions)
  }

  shap_values <- fastshap::explain(
    object = fit$forest,
    X = x,
    pred_wrapper = pred_wrapper,
    nsim = nsim,
    adjust = TRUE
  )

  shap_table <- data.frame(
    sample_id = fit$effect_table$sample_id,
    shap_values,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  shap_table
}

extract_causal_tree_rules <- function(tree_fit) {
  frame <- tree_fit$frame
  leaf_nodes <- as.integer(row.names(frame))[frame$var == "<leaf>"]
  paths <- rpart::path.rpart(tree_fit, nodes = leaf_nodes, print.it = FALSE)

  data.frame(
    node_id = leaf_nodes,
    subgroup = sprintf("CT%s", seq_along(leaf_nodes)),
    rule = vapply(paths, function(path) {
      if (length(path) <= 1) {
        "All samples"
      } else {
        paste(path[-1], collapse = " & ")
      }
    }, character(1)),
    stringsAsFactors = FALSE
  )
}

#' Run a causalTree-style exploratory analysis
#'
#' @param data A `data.frame`.
#' @param outcome Name of the outcome column.
#' @param treatment Name of the treatment column.
#' @param covariates Character vector of covariate column names.
#' @param sample_id Optional sample identifier column.
#' @param treatment_binary Optional binary treatment column. If `NULL`, a binary
#'   treatment is created from `treatment_cut`.
#' @param treatment_cut One of `"median"`, `"mean"`, or `"zero"` when a binary
#'   treatment must be derived from a continuous treatment.
#' @param split_rule Split rule passed to `htetree::causalTree()`.
#' @param honest Whether to request honest splitting.
#' @param minsize Minimum treated and control size per leaf.
#' @param xval Number of cross-validation folds.
#' @param prune Whether to prune to the cross-validated optimal cp.
#'
#' @return A list containing the `causal_tree`, `tree_table`, and the analysis
#'   data used by the explorer.
#' @export
fit_causal_tree_explorer <- function(
    data,
    outcome = "outcome",
    treatment = "treatment",
    covariates,
    sample_id = NULL,
    treatment_binary = NULL,
    treatment_cut = c("median", "mean", "zero"),
    split_rule = "CT",
    honest = TRUE,
    minsize = 20,
    xval = 5,
    prune = TRUE) {
  if (!requireNamespace("htetree", quietly = TRUE)) {
    stop("Package 'htetree' is required for fit_causal_tree_explorer().", call. = FALSE)
  }

  treatment_cut <- match.arg(treatment_cut)
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  validate_columns(data, unique(stats::na.omit(c(outcome, treatment, covariates, sample_id))), data_name = "data")

  use_data <- data

  if (is.null(treatment_binary)) {
    cutoff <- switch(
      treatment_cut,
      median = stats::median(use_data[[treatment]], na.rm = TRUE),
      mean = mean(use_data[[treatment]], na.rm = TRUE),
      zero = 0
    )
    use_data$treatment_binary <- as.integer(use_data[[treatment]] > cutoff)
    treatment_binary <- "treatment_binary"
  }

  validate_columns(use_data, c(outcome, treatment_binary, covariates))
  if (!all(use_data[[treatment_binary]] %in% c(0, 1))) {
    stop("`treatment_binary` must contain only 0 and 1.", call. = FALSE)
  }

  form <- stats::as.formula(
    sprintf("%s ~ %s", outcome, paste(covariates, collapse = " + "))
  )

  rpart_attached <- "package:rpart" %in% search()
  if (!rpart_attached) {
    attachNamespace(asNamespace("rpart"))
    on.exit(detach("package:rpart", unload = FALSE, character.only = TRUE), add = TRUE)
  }

  tree_fit <- htetree::causalTree(
    formula = form,
    data = use_data,
    treatment = use_data[[treatment_binary]],
    split.Rule = split_rule,
    cv.option = split_rule,
    split.Honest = honest,
    cv.Honest = honest,
    split.Bucket = FALSE,
    xval = xval,
    cp = 0,
    minsize = minsize,
    propensity = mean(use_data[[treatment_binary]])
  )

  if (prune && !is.null(tree_fit$cptable) && nrow(tree_fit$cptable) > 0) {
    cp_star <- tree_fit$cptable[which.min(tree_fit$cptable[, "xerror"]), "CP"]
    tree_fit <- rpart::prune(tree_fit, cp = cp_star)
  }

  rule_table <- extract_causal_tree_rules(tree_fit)
  tree_table <- data.frame(
    node_id = as.integer(row.names(tree_fit$frame)),
    variable = as.character(tree_fit$frame$var),
    n = tree_fit$frame$n,
    prediction = tree_fit$frame$yval,
    is_leaf = tree_fit$frame$var == "<leaf>",
    stringsAsFactors = FALSE
  )
  tree_table <- merge(tree_table, rule_table, by = "node_id", all.x = TRUE, sort = FALSE)

  list(
    causal_tree = tree_fit,
    tree_table = tree_table,
    rule_table = rule_table,
    analysis_data = use_data
  )
}

#' Plot a causalTree explorer result
#'
#' @param x Output from `fit_causal_tree_explorer()`.
#' @param main Plot title.
#' @param ... Reserved for future use.
#'
#' @return Draws a tree plot.
#' @export
plot_causal_tree_explorer <- function(x, main = "Causal tree explorer", ...) {
  tree_fit <- if (inherits(x, "rpart")) x else x$causal_tree
  if (is.null(tree_fit)) {
    stop("`x` must be a causalTree explorer result or an rpart tree.", call. = FALSE)
  }

  if (requireNamespace("rpart.plot", quietly = TRUE)) {
    rpart.plot::rpart.plot(
      tree_fit,
      type = 4,
      extra = 101,
      under = TRUE,
      fallen.leaves = TRUE,
      box.palette = "RdYlGn",
      branch = 0.45,
      tweak = 1.45,
      clip.right.labs = FALSE,
      roundint = FALSE,
      main = main
    )
    return(invisible(NULL))
  }

  plot(tree_fit)
  graphics::text(tree_fit, use.n = TRUE)
  invisible(NULL)
}
