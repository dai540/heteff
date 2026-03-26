.libPaths(c("C:/Users/daiki/Desktop/codex/.r-lib", .libPaths()))
pkg_root <- normalizePath(file.path(getwd(), "heteff"), mustWork = FALSE)
if (!dir.exists(pkg_root)) {
  stop("Run this script from the workspace root so that ./heteff exists.", call. = FALSE)
}

source(file.path(pkg_root, "R", "heteff-package.R"))
source(file.path(pkg_root, "R", "fit.R"))
source(file.path(pkg_root, "R", "instrument.R"))
source(file.path(pkg_root, "R", "io.R"))
source(file.path(pkg_root, "R", "methods.R"))
source(file.path(pkg_root, "R", "plots.R"))
source(file.path(pkg_root, "R", "simulate.R"))
source(file.path(pkg_root, "R", "cases.R"))
source(file.path(pkg_root, "R", "explain.R"))

catalog <- case_study_catalog()
output_root <- file.path(pkg_root, "inst", "case-studies")

for (i in seq_len(nrow(catalog))) {
  case_name <- catalog$case[i]
  case_dir <- file.path(output_root, gsub("_", "-", case_name))
  fit <- run_case_study(case_name, num_trees = 400, seed = 123)
  dir.create(case_dir, recursive = TRUE, showWarnings = FALSE)
  export_tables(fit, case_dir)
  export_plots(fit, case_dir)
}
