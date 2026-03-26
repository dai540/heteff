validate_columns <- function(data, columns, data_name = "data") {
  missing_cols <- setdiff(columns, names(data))
  if (length(missing_cols) > 0) {
    stop(
      sprintf("Missing columns in %s: %s", data_name, paste(missing_cols, collapse = ", ")),
      call. = FALSE
    )
  }
}

prepare_analysis_data <- function(data, keep_cols, sample_id = NULL, candidate = NULL) {
  analysis_data <- data[, keep_cols, drop = FALSE]
  complete_rows <- stats::complete.cases(analysis_data)
  dropped_rows <- sum(!complete_rows)
  analysis_data <- analysis_data[complete_rows, , drop = FALSE]
  rownames(analysis_data) <- NULL

  if (is.null(sample_id)) {
    analysis_data$sample_id <- sprintf("sample_%s", seq_len(nrow(analysis_data)))
    sample_id <- "sample_id"
  }

  if (is.null(candidate)) {
    analysis_data$candidate <- "analysis_target"
    candidate <- "candidate"
  }

  list(
    data = analysis_data,
    dropped_rows = dropped_rows,
    sample_id = sample_id,
    candidate = candidate
  )
}

build_iv_check_table <- function(analysis_data, outcome, treatment, instrument, dropped_rows) {
  outcome_sd <- stats::sd(analysis_data[[outcome]])
  treatment_sd <- stats::sd(analysis_data[[treatment]])
  instrument_sd <- stats::sd(analysis_data[[instrument]])
  treatment_instrument_cor <- suppressWarnings(stats::cor(analysis_data[[treatment]], analysis_data[[instrument]]))

  first_stage <- stats::lm(
    stats::as.formula(sprintf("%s ~ %s", treatment, instrument)),
    data = analysis_data
  )
  first_stage_f <- unname(summary(first_stage)$fstatistic[1])

  first_stage_status <- if (is.na(first_stage_f)) {
    "error"
  } else if (first_stage_f < 10) {
    "warn"
  } else {
    "ok"
  }

  data.frame(
    check_name = c(
      "rows_used",
      "rows_dropped_missing",
      "outcome_sd",
      "treatment_sd",
      "instrument_sd",
      "cor_treatment_instrument",
      "first_stage_f"
    ),
    value = c(
      nrow(analysis_data),
      dropped_rows,
      outcome_sd,
      treatment_sd,
      instrument_sd,
      treatment_instrument_cor,
      first_stage_f
    ),
    status = c(
      "info",
      if (dropped_rows > 0) "warn" else "ok",
      if (is.na(outcome_sd) || outcome_sd == 0) "error" else "ok",
      if (is.na(treatment_sd) || treatment_sd == 0) "error" else "ok",
      if (is.na(instrument_sd) || instrument_sd == 0) "error" else "ok",
      if (is.na(treatment_instrument_cor)) "error" else "ok",
      first_stage_status
    ),
    stringsAsFactors = FALSE
  )
}

build_rwd_check_table <- function(analysis_data, outcome, treatment, dropped_rows, survival = FALSE, event = NULL, horizon = NULL) {
  outcome_sd <- stats::sd(analysis_data[[outcome]])
  treatment_sd <- stats::sd(analysis_data[[treatment]])
  treatment_mean <- mean(analysis_data[[treatment]])
  treatment_binary <- all(na.omit(unique(analysis_data[[treatment]])) %in% c(0, 1))

  checks <- data.frame(
    check_name = c(
      "rows_used",
      "rows_dropped_missing",
      "outcome_sd",
      "treatment_sd",
      if (treatment_binary) "treatment_rate" else "treatment_mean",
      "covariate_count"
    ),
    value = c(
      nrow(analysis_data),
      dropped_rows,
      outcome_sd,
      treatment_sd,
      treatment_mean,
      ncol(analysis_data)
    ),
    status = c(
      "info",
      if (dropped_rows > 0) "warn" else "ok",
      if (is.na(outcome_sd) || outcome_sd == 0) "error" else "ok",
      if (is.na(treatment_sd) || treatment_sd == 0) "error" else "ok",
      "info",
      "info"
    ),
    stringsAsFactors = FALSE
  )

  if (survival) {
    event_rate <- mean(analysis_data[[event]])
    censor_rate <- 1 - event_rate
    checks <- rbind(
      checks,
      data.frame(
        check_name = c("event_rate", "censor_rate", "horizon"),
        value = c(event_rate, censor_rate, horizon),
        status = c(
          if (event_rate <= 0 || event_rate >= 1) "warn" else "ok",
          "info",
          "info"
        ),
        stringsAsFactors = FALSE
      )
    )
  }

  checks
}

safe_average_treatment_effect <- function(forest) {
  tryCatch(
    {
      ate <- grf::average_treatment_effect(forest)
      data.frame(
        estimand = "average_treatment_effect",
        estimate = unname(ate[["estimate"]]),
        std.err = unname(ate[["std.err"]]),
        stringsAsFactors = FALSE
      )
    },
    error = function(e) {
      data.frame(
        estimand = "average_treatment_effect",
        estimate = NA_real_,
        std.err = NA_real_,
        stringsAsFactors = FALSE
      )
    }
  )
}

build_effect_table <- function(analysis_data, sample_id_col, candidate_col, predictions) {
  effect_hat <- as.numeric(predictions$predictions)
  variance_estimates <- predictions$variance.estimates
  if (is.null(variance_estimates)) {
    effect_se <- rep(NA_real_, length(effect_hat))
  } else {
    effect_se <- sqrt(variance_estimates)
  }

  data.frame(
    sample_id = analysis_data[[sample_id_col]],
    candidate = analysis_data[[candidate_col]],
    effect_hat = effect_hat,
    effect_se = effect_se,
    effect_low = effect_hat - 1.96 * effect_se,
    effect_high = effect_hat + 1.96 * effect_se,
    stringsAsFactors = FALSE
  )
}

extract_tree_rules <- function(fit) {
  frame <- fit$frame
  leaf_nodes <- as.integer(row.names(frame))[frame$var == "<leaf>"]
  if (length(leaf_nodes) == 0) {
    return(data.frame(
      node_id = 1L,
      subgroup = "G1",
      rule = "All samples",
      stringsAsFactors = FALSE
    ))
  }

  paths <- rpart::path.rpart(fit, nodes = leaf_nodes, print.it = FALSE)
  rule_text <- vapply(paths, function(path) {
    if (length(path) <= 1) {
      "All samples"
    } else {
      paste(path[-1], collapse = " & ")
    }
  }, character(1))

  out <- data.frame(
    node_id = leaf_nodes,
    subgroup = sprintf("G%s", seq_along(leaf_nodes)),
    rule = unname(rule_text),
    stringsAsFactors = FALSE
  )
  out[order(out$node_id), , drop = FALSE]
}

build_effect_tree <- function(effect_table, covariate_data, max_depth = 3, min_bucket = 100L, trim_quantiles = c(0.05, 0.95)) {
  clipped_effect <- effect_table$effect_hat
  if (length(trim_quantiles) == 2) {
    trim_bounds <- stats::quantile(clipped_effect, probs = trim_quantiles, na.rm = TRUE)
    clipped_effect <- pmin(pmax(clipped_effect, trim_bounds[1]), trim_bounds[2])
  }

  tree_data <- cbind(effect_hat = clipped_effect, covariate_data)
  fit <- rpart::rpart(
    effect_hat ~ .,
    data = tree_data,
    method = "anova",
    control = rpart::rpart.control(
      maxdepth = max_depth,
      minbucket = min_bucket,
      cp = 0.001
    )
  )

  rule_table <- extract_tree_rules(fit)
  frame <- fit$frame
  node_ids <- as.integer(row.names(frame))
  tree_table <- data.frame(
    node_id = node_ids,
    variable = as.character(frame$var),
    n = frame$n,
    prediction = frame$yval,
    is_leaf = frame$var == "<leaf>",
    stringsAsFactors = FALSE
  )

  if (!is.null(fit$splits) && nrow(fit$splits) > 0) {
    split_table <- data.frame(
      variable = row.names(fit$splits),
      split_value = fit$splits[, "index"],
      improve = fit$splits[, "improve"],
      stringsAsFactors = FALSE
    )
    tree_table <- merge(tree_table, split_table, by = "variable", all.x = TRUE, sort = FALSE)
  } else {
    tree_table$split_value <- NA_real_
    tree_table$improve <- NA_real_
  }

  tree_table <- merge(tree_table, rule_table, by = "node_id", all.x = TRUE, sort = FALSE)
  terminal_node <- fit$where

  list(
    tree = fit,
    tree_table = tree_table,
    terminal_node = terminal_node,
    rule_table = rule_table,
    trimmed_effect = clipped_effect
  )
}

summarize_subgroups <- function(effect_table, terminal_node, rule_table) {
  mapped_rules <- rule_table
  names(mapped_rules)[names(mapped_rules) == "node_id"] <- "terminal_node"

  if (nrow(mapped_rules) == 0) {
    mapped_rules <- data.frame(
      terminal_node = 1L,
      subgroup = "G1",
      rule = "All samples",
      stringsAsFactors = FALSE
    )
  }

  if (length(terminal_node) == 0) {
    terminal_node <- rep(mapped_rules$terminal_node[1], nrow(effect_table))
  }

  effect_table$terminal_node <- terminal_node
  effect_table <- merge(effect_table, mapped_rules, by = "terminal_node", all.x = TRUE, sort = FALSE)
  if (!"subgroup" %in% names(effect_table) || all(is.na(effect_table$subgroup))) {
    effect_table$subgroup <- "G1"
    effect_table$rule <- "All samples"
  }

  effect_table <- effect_table[, c(
    "sample_id",
    "candidate",
    "effect_hat",
    "effect_se",
    "effect_low",
    "effect_high",
    "subgroup",
    "rule",
    "terminal_node"
  )]

  subgroup_table <- do.call(
    rbind,
    lapply(split(effect_table, effect_table$subgroup), function(part) {
      effect_mean <- mean(part$effect_hat, na.rm = TRUE)
      effect_se <- stats::sd(part$effect_hat, na.rm = TRUE) / sqrt(nrow(part))
      data.frame(
        subgroup = unique(part$subgroup),
        rule = unique(part$rule),
        n = nrow(part),
        effect_mean = effect_mean,
        effect_low = effect_mean - 1.96 * effect_se,
        effect_high = effect_mean + 1.96 * effect_se,
        stringsAsFactors = FALSE
      )
    })
  )

  rownames(subgroup_table) <- NULL
  list(effect_table = effect_table, subgroup_table = subgroup_table)
}

build_ranking_table <- function(effect_table) {
  ranking_input <- effect_table[stats::complete.cases(effect_table[, c("subgroup", "candidate", "effect_hat")]), , drop = FALSE]
  if (nrow(ranking_input) == 0) {
    return(data.frame(
      subgroup = character(0),
      candidate = character(0),
      rank = integer(0),
      effect_mean = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  ranking_table <- stats::aggregate(effect_hat ~ subgroup + candidate, data = ranking_input, FUN = mean)
  names(ranking_table)[names(ranking_table) == "effect_hat"] <- "effect_mean"
  ranking_table <- ranking_table[order(ranking_table$subgroup, -ranking_table$effect_mean), , drop = FALSE]
  ranking_table$rank <- stats::ave(
    ranking_table$effect_mean,
    ranking_table$subgroup,
    FUN = function(x) rank(-x, ties.method = "first")
  )
  ranking_table <- ranking_table[, c("subgroup", "candidate", "rank", "effect_mean")]
  rownames(ranking_table) <- NULL
  ranking_table
}

build_variable_importance_table <- function(forest, covariates) {
  vi <- tryCatch(grf::variable_importance(forest), error = function(e) NULL)
  if (is.null(vi)) {
    return(data.frame(
      covariate = covariates,
      importance = NA_real_,
      rank = seq_along(covariates),
      stringsAsFactors = FALSE
    ))
  }

  out <- data.frame(
    covariate = covariates,
    importance = as.numeric(vi),
    stringsAsFactors = FALSE
  )
  out <- out[order(out$importance, decreasing = TRUE), , drop = FALSE]
  out$rank <- seq_len(nrow(out))
  rownames(out) <- NULL
  out
}

new_heteff_fit <- function(
    analysis_type,
    estimand_label,
    analysis_data,
    spec,
    config,
    forest,
    effect_table,
    subgroup_table,
    tree,
    tree_table,
    ranking_table,
    check_table,
    estimand_table,
    variable_importance) {
  result <- list(
    analysis_type = analysis_type,
    estimand_label = estimand_label,
    analysis_data = analysis_data,
    spec = spec,
    config = config,
    forest = forest,
    effect_table = effect_table,
    subgroup_table = subgroup_table,
    tree = tree,
    tree_table = tree_table,
    ranking_table = ranking_table,
    check_table = check_table,
    estimand_table = estimand_table,
    variable_importance = variable_importance
  )
  class(result) <- c("heteff_fit", paste0("heteff_", analysis_type, "_fit"))
  result
}

run_effect_pipeline <- function(
    analysis_type,
    estimand_label,
    analysis_data,
    outcome,
    treatment,
    covariates,
    sample_id,
    candidate,
    forest,
    check_table,
    config) {
  predictions <- stats::predict(forest, estimate.variance = TRUE)
  effect_table <- build_effect_table(
    analysis_data = analysis_data,
    sample_id_col = sample_id,
    candidate_col = candidate,
    predictions = predictions
  )

  tree_object <- build_effect_tree(
    effect_table = effect_table,
    covariate_data = analysis_data[, covariates, drop = FALSE],
    max_depth = config$tree_depth,
    min_bucket = config$tree_minbucket,
    trim_quantiles = config$tree_trim_quantiles
  )

  subgroup_results <- summarize_subgroups(
    effect_table,
    terminal_node = tree_object$terminal_node,
    rule_table = tree_object$rule_table
  )

  new_heteff_fit(
    analysis_type = analysis_type,
    estimand_label = estimand_label,
    analysis_data = analysis_data,
    spec = list(
      outcome = outcome,
      treatment = treatment,
      covariates = covariates,
      sample_id = sample_id,
      candidate = candidate
    ),
    config = config,
    forest = forest,
    effect_table = subgroup_results$effect_table,
    subgroup_table = subgroup_results$subgroup_table,
    tree = tree_object$tree,
    tree_table = tree_object$tree_table,
    ranking_table = build_ranking_table(subgroup_results$effect_table),
    check_table = check_table,
    estimand_table = safe_average_treatment_effect(forest),
    variable_importance = build_variable_importance_table(forest, covariates)
  )
}

#' Fit an instrumental forest workflow
#'
#' @param data A single analysis `data.frame`.
#' @param outcome Outcome column.
#' @param treatment Exposure or perturbation proxy column.
#' @param instrument Instrument column.
#' @param covariates Baseline adjustment or subgroup covariates.
#' @param sample_id Optional sample identifier column.
#' @param candidate Optional candidate label column.
#' @param num_trees Number of trees for `grf::instrumental_forest()`.
#' @param min_node_size Minimum node size for `grf::instrumental_forest()`.
#' @param tree_depth Maximum depth of the explanation tree.
#' @param tree_minbucket Minimum leaf size of the explanation tree.
#' @param tree_trim_quantiles Quantiles used to clip extreme effect estimates
#'   before fitting the explanation tree.
#' @param seed Optional random seed.
#'
#' @return A `heteff_fit` object.
#' @export
fit_instrumental_forest <- function(
    data,
    outcome = "outcome",
    treatment = "treatment",
    instrument = "instrument",
    covariates,
    sample_id = NULL,
    candidate = NULL,
    num_trees = 2000,
    min_node_size = 5,
    tree_depth = 3,
    tree_minbucket = 100L,
    tree_trim_quantiles = c(0.05, 0.95),
    seed = NULL) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  required_cols <- unique(stats::na.omit(c(outcome, treatment, instrument, covariates, sample_id, candidate)))
  validate_columns(data, required_cols)

  prepared <- prepare_analysis_data(data, required_cols, sample_id = sample_id, candidate = candidate)
  analysis_data <- prepared$data

  check_table <- build_iv_check_table(
    analysis_data = analysis_data,
    outcome = outcome,
    treatment = treatment,
    instrument = instrument,
    dropped_rows = prepared$dropped_rows
  )
  if (any(check_table$status == "error")) {
    stop("Input data failed validation. Inspect `check_table` for details.", call. = FALSE)
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }
  forest <- grf::instrumental_forest(
    X = as.matrix(analysis_data[, covariates, drop = FALSE]),
    Y = analysis_data[[outcome]],
    W = analysis_data[[treatment]],
    Z = analysis_data[[instrument]],
    num.trees = num_trees,
    min.node.size = min_node_size
  )

  fit <- run_effect_pipeline(
    analysis_type = "instrumental",
    estimand_label = "conditional_local_iv_effect",
    analysis_data = analysis_data,
    outcome = outcome,
    treatment = treatment,
    covariates = covariates,
    sample_id = prepared$sample_id,
    candidate = prepared$candidate,
    forest = forest,
    check_table = check_table,
    config = list(
      instrument = instrument,
      num_trees = num_trees,
      min_node_size = min_node_size,
      tree_depth = tree_depth,
      tree_minbucket = tree_minbucket,
      tree_trim_quantiles = tree_trim_quantiles,
      seed = seed
    )
  )
  fit$spec$instrument <- instrument
  fit
}

#' Fit an observational causal forest workflow
#'
#' @param data A single analysis `data.frame`.
#' @param outcome Outcome column.
#' @param treatment Treatment assignment column.
#' @param covariates Baseline covariates for confounding adjustment and
#'   heterogeneity discovery.
#' @param sample_id Optional sample identifier column.
#' @param candidate Optional treatment-comparison label column.
#' @param num_trees Number of trees for `grf::causal_forest()`.
#' @param min_node_size Minimum node size for `grf::causal_forest()`.
#' @param tree_depth Maximum depth of the explanation tree.
#' @param tree_minbucket Minimum leaf size of the explanation tree.
#' @param tree_trim_quantiles Quantiles used to clip extreme effect estimates
#'   before fitting the explanation tree.
#' @param seed Optional random seed.
#'
#' @return A `heteff_fit` object.
#' @export
fit_observational_forest <- function(
    data,
    outcome = "outcome",
    treatment = "treatment",
    covariates,
    sample_id = NULL,
    candidate = NULL,
    num_trees = 2000,
    min_node_size = 5,
    tree_depth = 3,
    tree_minbucket = 100L,
    tree_trim_quantiles = c(0.05, 0.95),
    seed = NULL) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  required_cols <- unique(stats::na.omit(c(outcome, treatment, covariates, sample_id, candidate)))
  validate_columns(data, required_cols)

  prepared <- prepare_analysis_data(data, required_cols, sample_id = sample_id, candidate = candidate)
  analysis_data <- prepared$data
  check_table <- build_rwd_check_table(
    analysis_data = analysis_data,
    outcome = outcome,
    treatment = treatment,
    dropped_rows = prepared$dropped_rows
  )
  if (any(check_table$status == "error")) {
    stop("Input data failed validation. Inspect `check_table` for details.", call. = FALSE)
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }
  forest <- grf::causal_forest(
    X = as.matrix(analysis_data[, covariates, drop = FALSE]),
    Y = analysis_data[[outcome]],
    W = analysis_data[[treatment]],
    num.trees = num_trees,
    min.node.size = min_node_size
  )

  run_effect_pipeline(
    analysis_type = "observational",
    estimand_label = "conditional_average_treatment_effect",
    analysis_data = analysis_data,
    outcome = outcome,
    treatment = treatment,
    covariates = covariates,
    sample_id = prepared$sample_id,
    candidate = prepared$candidate,
    forest = forest,
    check_table = check_table,
    config = list(
      num_trees = num_trees,
      min_node_size = min_node_size,
      tree_depth = tree_depth,
      tree_minbucket = tree_minbucket,
      tree_trim_quantiles = tree_trim_quantiles,
      seed = seed
    )
  )
}

#' Fit a survival causal forest workflow
#'
#' @param data A single analysis `data.frame`.
#' @param time Observed event or censoring time column.
#' @param event Event indicator column. Use `1` for event and `0` for censoring.
#' @param treatment Treatment assignment column.
#' @param covariates Baseline covariates for confounding adjustment and
#'   heterogeneity discovery.
#' @param horizon Horizon used by `grf::causal_survival_forest()`.
#' @param target Survival estimand. Either `"RMST"` or `"survival.probability"`.
#' @param sample_id Optional sample identifier column.
#' @param candidate Optional treatment-comparison label column.
#' @param num_trees Number of trees for `grf::causal_survival_forest()`.
#' @param min_node_size Minimum node size for `grf::causal_survival_forest()`.
#' @param tree_depth Maximum depth of the explanation tree.
#' @param tree_minbucket Minimum leaf size of the explanation tree.
#' @param tree_trim_quantiles Quantiles used to clip extreme effect estimates
#'   before fitting the explanation tree.
#' @param seed Optional random seed.
#'
#' @return A `heteff_fit` object.
#' @export
fit_survival_forest <- function(
    data,
    time = "time",
    event = "event",
    treatment = "treatment",
    covariates,
    horizon,
    target = c("RMST", "survival.probability"),
    sample_id = NULL,
    candidate = NULL,
    num_trees = 2000,
    min_node_size = 5,
    tree_depth = 3,
    tree_minbucket = 100L,
    tree_trim_quantiles = c(0.05, 0.95),
    seed = NULL) {
  target <- match.arg(target)
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  required_cols <- unique(stats::na.omit(c(time, event, treatment, covariates, sample_id, candidate)))
  validate_columns(data, required_cols)

  prepared <- prepare_analysis_data(data, required_cols, sample_id = sample_id, candidate = candidate)
  analysis_data <- prepared$data
  check_table <- build_rwd_check_table(
    analysis_data = analysis_data,
    outcome = time,
    treatment = treatment,
    dropped_rows = prepared$dropped_rows,
    survival = TRUE,
    event = event,
    horizon = horizon
  )
  if (any(check_table$status == "error")) {
    stop("Input data failed validation. Inspect `check_table` for details.", call. = FALSE)
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }
  forest <- grf::causal_survival_forest(
    X = as.matrix(analysis_data[, covariates, drop = FALSE]),
    Y = analysis_data[[time]],
    W = analysis_data[[treatment]],
    D = analysis_data[[event]],
    target = target,
    horizon = horizon,
    num.trees = num_trees,
    min.node.size = min_node_size
  )

  fit <- run_effect_pipeline(
    analysis_type = "survival",
    estimand_label = if (target == "RMST") "conditional_rmst_difference" else "conditional_survival_probability_difference",
    analysis_data = analysis_data,
    outcome = time,
    treatment = treatment,
    covariates = covariates,
    sample_id = prepared$sample_id,
    candidate = prepared$candidate,
    forest = forest,
    check_table = check_table,
    config = list(
      event = event,
      target = target,
      horizon = horizon,
      num_trees = num_trees,
      min_node_size = min_node_size,
      tree_depth = tree_depth,
      tree_minbucket = tree_minbucket,
      tree_trim_quantiles = tree_trim_quantiles,
      seed = seed
    )
  )
  fit$spec$event <- event
  fit
}
