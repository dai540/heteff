#' Export output tables to CSV files
#'
#' @param fit A `heteff_fit` object.
#' @param output_dir Directory to write outputs into.
#'
#' @return Invisibly returns the output directory.
#' @export
export_tables <- function(fit, output_dir) {
  if (!inherits(fit, "heteff_fit")) {
    stop("`fit` must be a heteff_fit object.", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(fit$effect_table, file.path(output_dir, "effect_table.csv"), row.names = FALSE)
  utils::write.csv(fit$subgroup_table, file.path(output_dir, "subgroup_table.csv"), row.names = FALSE)
  utils::write.csv(fit$ranking_table, file.path(output_dir, "ranking_table.csv"), row.names = FALSE)
  utils::write.csv(fit$check_table, file.path(output_dir, "check_table.csv"), row.names = FALSE)
  utils::write.csv(fit$tree_table, file.path(output_dir, "tree_table.csv"), row.names = FALSE)
  utils::write.csv(fit$estimand_table, file.path(output_dir, "estimand_table.csv"), row.names = FALSE)
  utils::write.csv(fit$variable_importance, file.path(output_dir, "variable_importance.csv"), row.names = FALSE)
  invisible(output_dir)
}
