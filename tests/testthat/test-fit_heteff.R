test_that("synthetic generators return workflow-specific analysis tables", {
  inst <- simulate_instrumental_data(n = 50, seed = 1)
  obs <- simulate_observational_data(n = 50, seed = 2)
  surv <- simulate_survival_data(n = 50, seed = 3)

  expect_true(all(c("sample_id", "outcome", "treatment", "instrument", "age", "bmi") %in% names(inst)))
  expect_true(all(c("sample_id", "outcome", "treatment", "ecog", "msi", "baseline_ctdna") %in% names(obs)))
  expect_true(all(c("sample_id", "time", "event", "treatment", "pathway_score") %in% names(surv)))
  expect_equal(nrow(inst), 50)
  expect_equal(nrow(obs), 50)
  expect_equal(nrow(surv), 50)
})

test_that("build_instrument_score creates a usable score", {
  x <- simulate_instrumental_data(n = 50, seed = 11)

  built <- build_instrument_score(
    data = x,
    instrument_cols = c("z1", "z2", "z3"),
    method = "z_mean",
    new_col = "instrument_score"
  )

  expect_true("instrument_score" %in% names(built$data))
  expect_equal(nrow(built$instrument_map), 3)
})

test_that("case study catalog exposes all workflows", {
  catalog <- case_study_catalog()
  expect_true(all(c("case", "workflow", "title", "domain", "source") %in% names(catalog)))
  expect_true(all(c("observational", "survival", "instrumental") %in% catalog$workflow))
  expect_equal(sort(available_case_studies()), sort(catalog$case))
})

test_that("public case-study data can be prepared when source packages are available", {
  skip_if_not_installed("causaldata")
  skip_if_not_installed("ivmodel")
  skip_if_not_installed("ivreg")

  nhefs <- prepare_case_nhefs()
  nsw <- prepare_case_nsw()
  veteran <- prepare_case_veteran()
  rotterdam <- prepare_case_rotterdam()
  card <- prepare_case_card_data()
  schooling <- prepare_case_schooling_returns()

  expect_true(all(c("sample_id", "outcome", "treatment") %in% names(nhefs)))
  expect_true(all(c("sample_id", "outcome", "treatment") %in% names(nsw)))
  expect_true(all(c("sample_id", "time", "event", "treatment") %in% names(veteran)))
  expect_true(all(c("sample_id", "time", "event", "treatment") %in% names(rotterdam)))
  expect_true(all(c("sample_id", "outcome", "treatment", "instrument") %in% names(card)))
  expect_true(all(c("sample_id", "outcome", "treatment", "instrument") %in% names(schooling)))
})

test_that("fit_instrumental_forest returns core outputs", {
  skip_if_not_installed("grf")

  x <- simulate_instrumental_data(n = 300, seed = 12)
  covariates <- c("age", "sex", "bmi", "smoking", "pc1", "pc2", "center", "batch", "baseline_risk")

  fit <- fit_instrumental_forest(
    data = x,
    outcome = "outcome",
    treatment = "treatment",
    instrument = "instrument",
    covariates = covariates,
    sample_id = "sample_id",
    seed = 12,
    num_trees = 200,
    tree_minbucket = 30
  )

  expect_s3_class(fit, "heteff_instrumental_fit")
  expect_true(all(c("effect_table", "subgroup_table", "tree_table", "ranking_table", "estimand_table", "variable_importance") %in% names(fit)))
  expect_true("first_stage_f" %in% fit$check_table$check_name)
})

test_that("fit_observational_forest returns core outputs", {
  skip_if_not_installed("grf")

  x <- simulate_observational_data(n = 300, seed = 22)
  covariates <- c("age", "sex", "ecog", "line", "liver_met", "tmb", "msi", "signature_ifn", "baseline_ctdna", "albumin", "crp", "site_volume")

  fit <- fit_observational_forest(
    data = x,
    outcome = "outcome",
    treatment = "treatment",
    covariates = covariates,
    sample_id = "sample_id",
    seed = 22,
    num_trees = 200,
    tree_minbucket = 30
  )

  expect_s3_class(fit, "heteff_observational_fit")
  expect_true(nrow(fit$subgroup_table) >= 1)
  expect_true("average_treatment_effect" %in% fit$estimand_table$estimand)
})

test_that("fit_survival_forest returns core outputs", {
  skip_if_not_installed("grf")

  x <- simulate_survival_data(n = 300, seed = 32, horizon = 12)
  covariates <- c("age", "sex", "ecog", "line", "liver_met", "inflammation", "biomarker", "pathway_score", "steroid")

  fit <- fit_survival_forest(
    data = x,
    time = "time",
    event = "event",
    treatment = "treatment",
    covariates = covariates,
    horizon = 12,
    sample_id = "sample_id",
    seed = 32,
    num_trees = 200,
    tree_minbucket = 30
  )

  expect_s3_class(fit, "heteff_survival_fit")
  expect_true("event_rate" %in% fit$check_table$check_name)
  expect_true(nrow(fit$subgroup_table) >= 1)
})

test_that("run_case_study covers representative workflows", {
  skip_if_not_installed("causaldata")
  skip_if_not_installed("ivmodel")
  skip_if_not_installed("grf")

  fit_obs <- run_case_study("observational_nhefs", num_trees = 200, seed = 123)
  fit_surv <- run_case_study("survival_veteran", num_trees = 200, seed = 123)
  fit_iv <- run_case_study("instrumental_card", num_trees = 200, seed = 123)

  expect_s3_class(fit_obs, "heteff_observational_fit")
  expect_s3_class(fit_surv, "heteff_survival_fit")
  expect_s3_class(fit_iv, "heteff_instrumental_fit")
})
