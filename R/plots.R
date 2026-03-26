#' Internal plotting theme for `heteff`
#'
#' @keywords internal
theme_heteff <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    return(NULL)
  }

  ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      plot.title.position = "plot",
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(face = "bold"),
      plot.title = ggplot2::element_text(face = "bold"),
      legend.position = "none"
    )
}

build_dag_plot <- function(dag_code, coords_x, coords_y, title, subtitle) {
  if (!requireNamespace("ggdag", quietly = TRUE) || !requireNamespace("dagitty", quietly = TRUE)) {
    stop("Packages 'ggdag' and 'dagitty' are required.", call. = FALSE)
  }

  dag <- dagitty::dagitty(dag_code)
  dagitty::coordinates(dag) <- list(x = coords_x, y = coords_y)
  tidy_dag <- ggdag::tidy_dagitty(dag)
  dag_data <- tidy_dag$data
  node_data <- unique(dag_data[, c("name", "x", "y")])
  node_data$label <- node_data$name

  ggplot2::ggplot(
    dag_data,
    ggplot2::aes(x = x, y = y, xend = xend, yend = yend)
  ) +
    ggdag::geom_dag_edges_link(
      linewidth = 1.2,
      arrow = grid::arrow(length = grid::unit(12, "pt"), type = "closed")
    ) +
    ggdag::geom_dag_point(
      data = node_data,
      ggplot2::aes(x = x, y = y, fill = name),
      inherit.aes = FALSE,
      shape = 21,
      size = 21,
      color = "#1F2937",
      stroke = 0.8
    ) +
    ggdag::geom_dag_label_repel(
      data = node_data,
      ggplot2::aes(x = x, y = y, label = label),
      inherit.aes = FALSE,
      fill = "white",
      color = "#111827",
      size = 4.2,
      fontface = "bold",
      label.size = 0.2,
      seed = 123
    ) +
    ggplot2::scale_fill_manual(values = c(
      instrument = "#355070",
      treatment = "#5B8E7D",
      outcome = "#A23E48",
      covariate = "#E9C46A",
      system = "#8AB17D",
      unobserved = "#9CA3AF"
    )) +
    ggdag::theme_dag() +
    ggplot2::coord_cartesian(xlim = c(-0.6, 7.2), ylim = c(-1.8, 5.5), clip = "off") +
    ggplot2::labs(title = title, subtitle = subtitle) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle = ggplot2::element_text(color = "#4B5563", size = 11),
      legend.position = "none"
    )
}

#' Plot the observational causal DAG
#'
#' @return A `ggplot2` DAG plot.
#' @export
plot_observational_dag <- function() {
  build_dag_plot(
    dag_code = "dag {
      covariate -> treatment
      covariate -> outcome
      system -> treatment
      system -> outcome
      treatment -> outcome
    }",
    coords_x = c(covariate = 1.5, system = 1.5, treatment = 4, outcome = 6.5),
    coords_y = c(covariate = 4.0, system = 1.4, treatment = 2.7, outcome = 2.7),
    title = "Observational causal forest DAG",
    subtitle = "Baseline covariates and system factors drive treatment choice and outcome; treatment heterogeneity is learned conditional on baseline X"
  )
}

#' Plot the instrumental DAG
#'
#' @return A `ggplot2` DAG plot.
#' @export
plot_instrumental_dag <- function() {
  build_dag_plot(
    dag_code = "dag {
      covariate -> instrument
      covariate -> treatment
      covariate -> outcome
      unobserved -> treatment
      unobserved -> outcome
      instrument -> treatment
      treatment -> outcome
    }",
    coords_x = c(covariate = 1.5, instrument = 1.5, treatment = 4, outcome = 6.5, unobserved = 4),
    coords_y = c(covariate = 4.2, instrument = 1.2, treatment = 2.8, outcome = 2.8, unobserved = 0.2),
    title = "Instrumental forest DAG",
    subtitle = "Genetic instruments shift target or pathway perturbation while baseline covariates anchor subgroup-specific local IV effects"
  )
}

#' Plot the first-stage treatment-instrument relationship
#'
#' @param fit A `heteff_fit` object from [fit_instrumental_forest()].
#' @param main Plot title.
#'
#' @return A `ggplot2` object when available; otherwise draws a base plot.
#' @export
plot_first_stage <- function(fit, main = "First-stage relationship") {
  if (!inherits(fit, "heteff_instrumental_fit")) {
    stop("`fit` must come from fit_instrumental_forest().", call. = FALSE)
  }

  dat <- fit$analysis_data
  x_col <- fit$spec$instrument
  y_col <- fit$spec$treatment
  dat$x_value <- dat[[x_col]]
  dat$y_value <- dat[[y_col]]

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    if (length(unique(dat$x_value)) <= 6) {
      dat$instrument_factor <- factor(dat$x_value)
      return(
        ggplot2::ggplot(dat, ggplot2::aes(x = instrument_factor, y = y_value)) +
          ggplot2::geom_violin(fill = "#CDE7D8", color = "#5B8E7D", alpha = 0.9, trim = FALSE) +
          ggplot2::geom_boxplot(width = 0.15, fill = "white", outlier.alpha = 0.2) +
          ggplot2::labs(title = main, x = "Instrument", y = "Exposure or perturbation proxy") +
          theme_heteff()
      )
    }

    return(
      ggplot2::ggplot(dat, ggplot2::aes(x = x_value, y = y_value)) +
        ggplot2::geom_point(color = "#355070", alpha = 0.25, size = 1.7) +
        ggplot2::geom_smooth(method = "lm", se = TRUE, color = "#A23E48", linewidth = 1.1) +
        ggplot2::labs(title = main, x = "Instrument", y = "Exposure or perturbation proxy") +
        theme_heteff()
    )
  }

  graphics::plot(dat[[x_col]], dat[[y_col]], xlab = "Instrument", ylab = "Exposure or perturbation proxy", main = main)
}

#' Plot the reduced-form outcome-instrument relationship
#'
#' @param fit A `heteff_fit` object from [fit_instrumental_forest()].
#' @param main Plot title.
#'
#' @return A `ggplot2` object when available; otherwise draws a base plot.
#' @export
plot_reduced_form <- function(fit, main = "Reduced-form relationship") {
  if (!inherits(fit, "heteff_instrumental_fit")) {
    stop("`fit` must come from fit_instrumental_forest().", call. = FALSE)
  }

  dat <- fit$analysis_data
  x_col <- fit$spec$instrument
  y_col <- fit$spec$outcome
  dat$x_value <- dat[[x_col]]
  dat$y_value <- dat[[y_col]]

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    if (length(unique(dat$x_value)) <= 6) {
      dat$instrument_factor <- factor(dat$x_value)
      return(
        ggplot2::ggplot(dat, ggplot2::aes(x = instrument_factor, y = y_value)) +
          ggplot2::geom_violin(fill = "#F4D6CC", color = "#A23E48", alpha = 0.9, trim = FALSE) +
          ggplot2::geom_boxplot(width = 0.15, fill = "white", outlier.alpha = 0.2) +
          ggplot2::labs(title = main, x = "Instrument", y = "Outcome") +
          theme_heteff()
      )
    }

    return(
      ggplot2::ggplot(dat, ggplot2::aes(x = x_value, y = y_value)) +
        ggplot2::geom_point(color = "#355070", alpha = 0.25, size = 1.7) +
        ggplot2::geom_smooth(method = "lm", se = TRUE, color = "#2A9D8F", linewidth = 1.1) +
        ggplot2::labs(title = main, x = "Instrument", y = "Outcome") +
        theme_heteff()
    )
  }

  graphics::plot(dat[[x_col]], dat[[y_col]], xlab = "Instrument", ylab = "Outcome", main = main)
}

#' Plot the treatment-outcome relationship for an observational workflow
#'
#' @param fit A `heteff_fit` object from an observational or survival workflow.
#' @param main Plot title.
#'
#' @return A `ggplot2` object when available; otherwise draws a base plot.
#' @export
plot_treatment_outcome <- function(fit, main = "Treatment-outcome relationship") {
  if (!inherits(fit, "heteff_observational_fit") && !inherits(fit, "heteff_survival_fit")) {
    stop("`fit` must come from fit_observational_forest() or fit_survival_forest().", call. = FALSE)
  }

  dat <- fit$analysis_data
  treatment <- fit$spec$treatment
  outcome <- fit$spec$outcome
  dat$treatment_value <- dat[[treatment]]
  dat$outcome_value <- dat[[outcome]]

  if (inherits(fit, "heteff_survival_fit")) {
    event <- fit$spec$event
    dat$event_label <- factor(dat[[event]], levels = c(0, 1), labels = c("censored", "event"))
    if (requireNamespace("ggplot2", quietly = TRUE)) {
      return(
        ggplot2::ggplot(dat, ggplot2::aes(x = factor(treatment_value), y = outcome_value, fill = event_label)) +
          ggplot2::geom_boxplot(alpha = 0.85, outlier.alpha = 0.15) +
          ggplot2::labs(title = main, x = "Treatment", y = "Observed time", fill = "Status") +
          theme_heteff()
      )
    }
    graphics::boxplot(outcome_value ~ treatment_value, data = dat, xlab = "Treatment", ylab = "Observed time", main = main)
    return(invisible(NULL))
  }

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    if (all(na.omit(unique(dat$treatment_value)) %in% c(0, 1))) {
      return(
        ggplot2::ggplot(dat, ggplot2::aes(x = factor(treatment_value), y = outcome_value)) +
          ggplot2::geom_violin(fill = "#D7E7F5", color = "#355070", alpha = 0.9, trim = FALSE) +
          ggplot2::geom_boxplot(width = 0.15, fill = "white", outlier.alpha = 0.2) +
          ggplot2::labs(title = main, x = "Treatment", y = "Outcome") +
          theme_heteff()
      )
    }

    return(
      ggplot2::ggplot(dat, ggplot2::aes(x = treatment_value, y = outcome_value)) +
        ggplot2::geom_point(color = "#355070", alpha = 0.25, size = 1.7) +
        ggplot2::geom_smooth(method = "lm", se = TRUE, color = "#5B8E7D", linewidth = 1.1) +
        ggplot2::labs(title = main, x = "Treatment", y = "Outcome") +
        theme_heteff()
    )
  }

  graphics::plot(dat$treatment_value, dat$outcome_value, xlab = "Treatment", ylab = "Outcome", main = main)
}

#' Plot subgroup mean effects
#'
#' @param fit A `heteff_fit` object.
#' @param main Plot title.
#'
#' @return A `ggplot2` object when available; otherwise draws a base plot.
#' @export
plot_subgroup_effects <- function(fit, main = "Subgroup mean effects") {
  if (!inherits(fit, "heteff_fit")) {
    stop("`fit` must be a heteff_fit object.", call. = FALSE)
  }
  subgroup <- fit$subgroup_table
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    subgroup$label <- sprintf("%s: %s", subgroup$subgroup, subgroup$rule)
    subgroup$label <- factor(subgroup$label, levels = subgroup$label[order(subgroup$effect_mean)])
    return(
      ggplot2::ggplot(subgroup, ggplot2::aes(x = label, y = effect_mean)) +
        ggplot2::geom_segment(
          ggplot2::aes(x = label, xend = label, y = 0, yend = effect_mean),
          color = "#BFC7CF",
          linewidth = 1.2
        ) +
        ggplot2::geom_errorbar(
          ggplot2::aes(ymin = effect_low, ymax = effect_high),
          width = 0.18,
          color = "#355070",
          linewidth = 0.9
        ) +
        ggplot2::geom_point(size = 3.6, color = "#2A9D8F") +
        ggplot2::geom_hline(yintercept = 0, color = "#6C757D", linetype = "dashed") +
        ggplot2::coord_flip() +
        ggplot2::labs(title = main, x = "Subgroup rule", y = "Mean heterogeneous effect") +
        theme_heteff()
    )
  }
  graphics::barplot(height = subgroup$effect_mean, names.arg = subgroup$subgroup, main = main, ylab = "effect_mean", col = "steelblue")
}

#' Plot an explanation tree with a publication-style layout
#'
#' @param fit A `heteff_fit` object.
#' @param main Plot title.
#'
#' @return Draws a tree plot.
#' @export
plot_effect_tree <- function(fit, main = "Explanation tree") {
  if (!inherits(fit, "heteff_fit")) {
    stop("`fit` must be a heteff_fit object.", call. = FALSE)
  }
  if (requireNamespace("rpart.plot", quietly = TRUE)) {
    palette_name <- if (anyNA(fit$tree$frame$yval)) "Blues" else "BuGn"
    rpart.plot::rpart.plot(
      fit$tree,
      main = main,
      type = 4,
      extra = 101,
      under = TRUE,
      fallen.leaves = TRUE,
      box.palette = palette_name,
      branch = 0.35,
      shadow.col = "gray80",
      tweak = 1.15,
      clip.right.labs = FALSE,
      roundint = FALSE
    )
    return(invisible(NULL))
  }
  plot(fit$tree)
  graphics::text(fit$tree, use.n = TRUE)
}

#' Plot ranked variable importance
#'
#' @param fit A `heteff_fit` object.
#' @param top_n Number of top covariates to show.
#'
#' @return A `ggplot2` object when available; otherwise draws a base plot.
#' @export
plot_variable_importance <- function(fit, top_n = 12) {
  if (!inherits(fit, "heteff_fit")) {
    stop("`fit` must be a heteff_fit object.", call. = FALSE)
  }
  table <- utils::head(fit$variable_importance, top_n)
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    table$covariate <- factor(table$covariate, levels = rev(table$covariate))
    return(
      ggplot2::ggplot(table, ggplot2::aes(x = covariate, y = importance)) +
        ggplot2::geom_col(fill = "#355070", alpha = 0.9) +
        ggplot2::coord_flip() +
        ggplot2::labs(title = "Variable importance", x = "Covariate", y = "Importance") +
        theme_heteff()
    )
  }
  graphics::barplot(table$importance, names.arg = table$covariate, horiz = TRUE, las = 1)
}

#' Plot the distribution of estimated sample-level effects
#'
#' @param fit A `heteff_fit` object.
#' @param main Plot title.
#'
#' @return A `ggplot2` object when available; otherwise draws a base plot.
#' @export
plot_effect_distribution <- function(fit, main = "Estimated heterogeneous effects") {
  if (!inherits(fit, "heteff_fit")) {
    stop("`fit` must be a heteff_fit object.", call. = FALSE)
  }
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    effect_mean <- mean(fit$effect_table$effect_hat, na.rm = TRUE)
    effect_median <- stats::median(fit$effect_table$effect_hat, na.rm = TRUE)
    return(
      ggplot2::ggplot(fit$effect_table, ggplot2::aes(x = effect_hat)) +
        ggplot2::geom_histogram(
          bins = 32,
          fill = "#5B8E7D",
          color = "white",
          alpha = 0.9
        ) +
        ggplot2::geom_density(color = "#A23E48", linewidth = 1.1) +
        ggplot2::geom_vline(xintercept = effect_mean, color = "#264653", linewidth = 0.8, linetype = "dashed") +
        ggplot2::geom_vline(xintercept = effect_median, color = "#E76F51", linewidth = 0.8, linetype = "dotdash") +
        ggplot2::labs(title = main, x = "Estimated heterogeneous effect", y = "Count") +
        theme_heteff()
    )
  }
  graphics::hist(fit$effect_table$effect_hat, main = main, xlab = "effect_hat", col = "grey80", border = "white")
}

#' Summarize SHAP values into a ranked importance table
#'
#' @param shap_table Output from `explain_effect_shap()`.
#'
#' @return A data frame with one row per covariate and its mean absolute SHAP value.
#' @export
summarize_shap <- function(shap_table) {
  if (!"sample_id" %in% names(shap_table)) {
    stop("`shap_table` must include a sample_id column.", call. = FALSE)
  }
  feature_cols <- setdiff(names(shap_table), "sample_id")
  out <- data.frame(
    feature = feature_cols,
    mean_abs_shap = vapply(feature_cols, function(col) mean(abs(shap_table[[col]]), na.rm = TRUE), numeric(1)),
    stringsAsFactors = FALSE
  )
  out[order(out$mean_abs_shap, decreasing = TRUE), , drop = FALSE]
}

#' Plot ranked SHAP importance
#'
#' @param shap_table Output from `explain_effect_shap()`.
#' @param top_n Number of top features to display.
#'
#' @return A `ggplot2` object when available; otherwise draws a base plot.
#' @export
plot_shap_importance <- function(shap_table, top_n = 10) {
  summary_table <- summarize_shap(shap_table)
  summary_table <- utils::head(summary_table, top_n)
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    summary_table$feature <- factor(summary_table$feature, levels = rev(summary_table$feature))
    return(
      ggplot2::ggplot(summary_table, ggplot2::aes(x = feature, y = mean_abs_shap)) +
        ggplot2::geom_col(fill = "#E76F51", alpha = 0.9) +
        ggplot2::coord_flip() +
        ggplot2::labs(title = "SHAP importance for estimated effects", x = "Covariate", y = "Mean |SHAP|") +
        theme_heteff()
    )
  }
  graphics::barplot(summary_table$mean_abs_shap, names.arg = summary_table$feature, horiz = TRUE, las = 1)
}

#' Write standard plots for a `heteff_fit`
#'
#' @param fit A `heteff_fit` object.
#' @param output_dir Directory for PNG files.
#'
#' @return Invisibly returns the output directory.
#' @export
export_plots <- function(fit, output_dir) {
  if (!inherits(fit, "heteff_fit")) {
    stop("`fit` must be a heteff_fit object.", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  subgroup_plot <- plot_subgroup_effects(fit)
  if (inherits(subgroup_plot, "ggplot")) {
    ggplot2::ggsave(file.path(output_dir, "subgroup_effects.png"), subgroup_plot, width = 10, height = 7, dpi = 160)
  }

  importance_plot <- plot_variable_importance(fit)
  if (inherits(importance_plot, "ggplot")) {
    ggplot2::ggsave(file.path(output_dir, "variable_importance.png"), importance_plot, width = 9, height = 6, dpi = 160)
  }

  effect_distribution <- plot_effect_distribution(fit)
  if (inherits(effect_distribution, "ggplot")) {
    ggplot2::ggsave(file.path(output_dir, "effect_distribution.png"), effect_distribution, width = 9, height = 6, dpi = 160)
  }

  grDevices::png(file.path(output_dir, "effect_tree.png"), width = 1200, height = 800)
  plot_effect_tree(fit)
  grDevices::dev.off()

  if (inherits(fit, "heteff_instrumental_fit")) {
    first_stage_plot <- plot_first_stage(fit)
    reduced_form_plot <- plot_reduced_form(fit)
    dag_plot <- plot_instrumental_dag()
    ggplot2::ggsave(file.path(output_dir, "first_stage.png"), first_stage_plot, width = 10, height = 7, dpi = 160)
    ggplot2::ggsave(file.path(output_dir, "reduced_form.png"), reduced_form_plot, width = 10, height = 7, dpi = 160)
    ggplot2::ggsave(file.path(output_dir, "instrumental_dag.png"), dag_plot, width = 12, height = 8, dpi = 180)
  }

  if (inherits(fit, "heteff_observational_fit") || inherits(fit, "heteff_survival_fit")) {
    treatment_plot <- plot_treatment_outcome(fit)
    dag_plot <- plot_observational_dag()
    if (inherits(treatment_plot, "ggplot")) {
      ggplot2::ggsave(file.path(output_dir, "treatment_outcome.png"), treatment_plot, width = 10, height = 7, dpi = 160)
    }
    ggplot2::ggsave(file.path(output_dir, "observational_dag.png"), dag_plot, width = 12, height = 8, dpi = 180)
  }

  invisible(output_dir)
}
