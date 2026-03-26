#' Case-study catalog for `heteff`
#'
#' @return A data frame describing built-in case studies.
#' @export
case_study_catalog <- function() {
  data.frame(
    case = c(
      "observational_nhefs",
      "observational_nsw",
      "survival_veteran",
      "survival_rotterdam",
      "instrumental_card",
      "instrumental_schooling"
    ),
    workflow = c(
      "observational",
      "observational",
      "survival",
      "survival",
      "instrumental",
      "instrumental"
    ),
    title = c(
      "NHEFS smoking cessation and weight change",
      "NSW job training and earnings",
      "Veterans' lung cancer survival trial",
      "Rotterdam breast cancer survival",
      "Card returns to schooling",
      "Schooling returns and college proximity"
    ),
    domain = c(
      "epidemiology",
      "labor economics",
      "clinical survival",
      "clinical survival",
      "education economics",
      "education economics"
    ),
    source = c(
      "causaldata::nhefs_complete",
      "causaldata::nsw_mixtape",
      "survival::veteran",
      "survival::rotterdam",
      "ivmodel::card.data",
      "ivreg::SchoolingReturns"
    ),
    stringsAsFactors = FALSE
  )
}

#' List built-in case study names
#'
#' @return Character vector of built-in case study names.
#' @export
available_case_studies <- function() {
  case_study_catalog()$case
}

encode_case_covariates <- function(data, columns) {
  encoded <- stats::model.matrix(~ . - 1, data = data[, columns, drop = FALSE])
  out <- as.data.frame(encoded, stringsAsFactors = FALSE, check.names = FALSE)
  rownames(out) <- NULL
  out
}

#' Prepare the NHEFS observational case study
#'
#' @importFrom utils data
#'
#' @return A numeric analysis data frame ready for `fit_observational_forest()`.
#' @export
prepare_case_nhefs <- function() {
  if (!requireNamespace("causaldata", quietly = TRUE)) {
    stop("Package 'causaldata' is required for this case study.", call. = FALSE)
  }

  raw <- causaldata::nhefs_complete
  base_cols <- c(
    "qsmk", "wt82_71", "sex", "age", "race", "income", "education",
    "smokeintensity", "smokeyrs", "exercise", "active", "wt71"
  )
  raw <- raw[stats::complete.cases(raw[, base_cols, drop = FALSE]), , drop = FALSE]
  covariates <- encode_case_covariates(
    raw,
    c("sex", "age", "race", "income", "education", "smokeintensity", "smokeyrs", "exercise", "active", "wt71")
  )

  cbind(
    data.frame(
      sample_id = sprintf("nhefs_%s", seq_len(nrow(raw))),
      outcome = raw$wt82_71,
      treatment = raw$qsmk,
      stringsAsFactors = FALSE
    ),
    covariates
  )
}

#' Prepare the NSW observational case study
#'
#' @return A numeric analysis data frame ready for `fit_observational_forest()`.
#' @export
prepare_case_nsw <- function() {
  if (!requireNamespace("causaldata", quietly = TRUE)) {
    stop("Package 'causaldata' is required for this case study.", call. = FALSE)
  }

  raw <- causaldata::nsw_mixtape
  raw <- raw[stats::complete.cases(raw), , drop = FALSE]

  data.frame(
    sample_id = sprintf("nsw_%s", seq_len(nrow(raw))),
    outcome = raw$re78,
    treatment = raw$treat,
    age = raw$age,
    educ = raw$educ,
    black = raw$black,
    hisp = raw$hisp,
    marr = raw$marr,
    nodegree = raw$nodegree,
    re74 = raw$re74,
    re75 = raw$re75,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Prepare the veteran survival case study
#'
#' @return A numeric analysis data frame ready for `fit_survival_forest()`.
#' @export
prepare_case_veteran <- function() {
  raw <- survival::veteran
  keep <- c("time", "status", "trt", "celltype", "karno", "diagtime", "age", "prior")
  raw <- raw[stats::complete.cases(raw[, keep, drop = FALSE]), , drop = FALSE]

  data.frame(
    sample_id = sprintf("veteran_%s", seq_len(nrow(raw))),
    time = raw$time / 30.4,
    event = as.integer(raw$status == 1),
    treatment = as.integer(raw$trt == 2),
    karno = raw$karno,
    diagtime = raw$diagtime,
    age = raw$age,
    prior = raw$prior,
    cell_adeno = as.integer(raw$celltype == "adeno"),
    cell_large = as.integer(raw$celltype == "large"),
    cell_small = as.integer(raw$celltype == "smallcell"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Prepare the Rotterdam survival case study
#'
#' @return A numeric analysis data frame ready for `fit_survival_forest()`.
#' @export
prepare_case_rotterdam <- function() {
  raw <- survival::rotterdam
  keep <- c("age", "meno", "size", "grade", "nodes", "pgr", "er", "hormon", "chemo", "dtime", "death", "year")
  raw <- raw[stats::complete.cases(raw[, keep, drop = FALSE]), , drop = FALSE]

  data.frame(
    sample_id = sprintf("rotterdam_%s", seq_len(nrow(raw))),
    time = raw$dtime / 365.25,
    event = raw$death,
    treatment = raw$chemo,
    age = raw$age,
    meno = raw$meno,
    size = as.integer(raw$size == "20-50") + 2L * as.integer(raw$size == ">50"),
    grade = raw$grade,
    nodes = raw$nodes,
    pgr = log1p(raw$pgr),
    er = log1p(raw$er),
    hormon = raw$hormon,
    year = raw$year,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Prepare the Card returns-to-schooling case study
#'
#' @return A numeric analysis data frame ready for `fit_instrumental_forest()`.
#' @export
prepare_case_card_data <- function() {
  if (!requireNamespace("ivmodel", quietly = TRUE)) {
    stop("Package 'ivmodel' is required for this case study.", call. = FALSE)
  }

  raw <- ivmodel::card.data
  keep <- c(
    "lwage", "educ", "nearc4", "exper", "expersq", "age", "black", "south",
    "smsa", "smsa66", "fatheduc", "motheduc", "momdad14", "sinmom14", "step14"
  )
  raw <- raw[stats::complete.cases(raw[, keep, drop = FALSE]), , drop = FALSE]

  data.frame(
    sample_id = sprintf("card_%s", seq_len(nrow(raw))),
    outcome = raw$lwage,
    treatment = raw$educ,
    instrument = raw$nearc4,
    exper = raw$exper,
    expersq = raw$expersq,
    age = raw$age,
    black = raw$black,
    south = raw$south,
    smsa = raw$smsa,
    smsa66 = raw$smsa66,
    fatheduc = raw$fatheduc,
    motheduc = raw$motheduc,
    momdad14 = raw$momdad14,
    sinmom14 = raw$sinmom14,
    step14 = raw$step14,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Prepare the SchoolingReturns case study
#'
#' @return A numeric analysis data frame ready for `fit_instrumental_forest()`.
#' @export
prepare_case_schooling_returns <- function() {
  if (!requireNamespace("ivreg", quietly = TRUE)) {
    stop("Package 'ivreg' is required for this case study.", call. = FALSE)
  }

  raw <- ivreg::SchoolingReturns
  raw <- raw[stats::complete.cases(raw), , drop = FALSE]

  data.frame(
    sample_id = sprintf("sr_%s", seq_len(nrow(raw))),
    outcome = log(raw$wage),
    treatment = raw$education,
    instrument = as.integer(raw$nearcollege == "yes"),
    experience = raw$experience,
    experience_sq = raw$experience^2,
    age = raw$age,
    ethnicity_afam = as.integer(raw$ethnicity == "afam"),
    smsa = as.integer(raw$smsa == "yes"),
    south = as.integer(raw$south == "yes"),
    enrolled = as.integer(raw$enrolled == "yes"),
    married = as.integer(raw$married == "yes"),
    education66 = raw$education66,
    smsa66 = as.integer(raw$smsa66 == "yes"),
    south66 = as.integer(raw$south66 == "yes"),
    feducation = raw$feducation,
    meducation = raw$meducation,
    kww = raw$kww,
    iq = raw$iq,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Run a built-in case study
#'
#' @param case Study name. One of `available_case_studies()`.
#' @param num_trees Number of trees for the selected workflow.
#' @param seed Optional seed.
#'
#' @return A `heteff_fit` object.
#' @export
run_case_study <- function(case = available_case_studies(), num_trees = 500, seed = 123) {
  case <- match.arg(case)

  if (case == "observational_nhefs") {
    data <- prepare_case_nhefs()
    return(
      fit_observational_forest(
        data = data,
        outcome = "outcome",
        treatment = "treatment",
        covariates = setdiff(names(data), c("sample_id", "outcome", "treatment")),
        sample_id = "sample_id",
        seed = seed,
        num_trees = num_trees,
        tree_depth = 3L,
        tree_minbucket = 100L,
        tree_trim_quantiles = c(0.05, 0.95)
      )
    )
  }

  if (case == "observational_nsw") {
    data <- prepare_case_nsw()
    return(
      fit_observational_forest(
        data = data,
        outcome = "outcome",
        treatment = "treatment",
        covariates = setdiff(names(data), c("sample_id", "outcome", "treatment")),
        sample_id = "sample_id",
        seed = seed,
        num_trees = num_trees,
        tree_depth = 3L,
        tree_minbucket = 50L,
        tree_trim_quantiles = c(0.05, 0.95)
      )
    )
  }

  if (case == "survival_veteran") {
    data <- prepare_case_veteran()
    return(
      fit_survival_forest(
        data = data,
        time = "time",
        event = "event",
        treatment = "treatment",
        covariates = setdiff(names(data), c("sample_id", "time", "event", "treatment")),
        sample_id = "sample_id",
        horizon = 6,
        seed = seed,
        num_trees = num_trees,
        tree_depth = 3L,
        tree_minbucket = 25L,
        tree_trim_quantiles = c(0.05, 0.95)
      )
    )
  }

  if (case == "survival_rotterdam") {
    data <- prepare_case_rotterdam()
    return(
      fit_survival_forest(
        data = data,
        time = "time",
        event = "event",
        treatment = "treatment",
        covariates = setdiff(names(data), c("sample_id", "time", "event", "treatment")),
        sample_id = "sample_id",
        horizon = 8,
        seed = seed,
        num_trees = num_trees,
        tree_depth = 3L,
        tree_minbucket = 120L,
        tree_trim_quantiles = c(0.05, 0.95)
      )
    )
  }

  if (case == "instrumental_card") {
    data <- prepare_case_card_data()
    return(
      fit_instrumental_forest(
        data = data,
        outcome = "outcome",
        treatment = "treatment",
        instrument = "instrument",
        covariates = setdiff(names(data), c("sample_id", "outcome", "treatment", "instrument")),
        sample_id = "sample_id",
        seed = seed,
        num_trees = num_trees,
        tree_depth = 3L,
        tree_minbucket = 160L,
        tree_trim_quantiles = c(0.05, 0.95)
      )
    )
  }

  data <- prepare_case_schooling_returns()
  fit_instrumental_forest(
    data = data,
    outcome = "outcome",
    treatment = "treatment",
    instrument = "instrument",
    covariates = setdiff(names(data), c("sample_id", "outcome", "treatment", "instrument")),
    sample_id = "sample_id",
    seed = seed,
    num_trees = num_trees,
    tree_depth = 3L,
    tree_minbucket = 80L,
    tree_trim_quantiles = c(0.05, 0.95)
  )
}
