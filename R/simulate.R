#' Simulate data for an instrumental-forest workflow
#'
#' @param n Number of rows.
#' @param seed Random seed.
#'
#' @return A synthetic `data.frame` for `fit_instrumental_forest()`.
#' @export
simulate_instrumental_data <- function(n = 1500, seed = 123) {
  set.seed(seed)

  age <- round(stats::rnorm(n, mean = 57, sd = 8))
  sex <- stats::rbinom(n, 1, 0.48)
  bmi <- stats::rnorm(n, mean = 27.2, sd = 4.6)
  smoking <- stats::rbinom(n, 1, stats::plogis(-1 + 0.04 * (age - 55) + 0.12 * sex))
  pc1 <- stats::rnorm(n)
  pc2 <- stats::rnorm(n)
  center <- stats::rbinom(n, 1, 0.45)
  batch <- stats::rbinom(n, 1, 0.40)
  baseline_risk <- stats::plogis(-2 + 0.05 * age + 0.25 * smoking + 0.12 * bmi)

  z1 <- stats::rbinom(n, 2, 0.30)
  z2 <- stats::rbinom(n, 2, stats::plogis(-0.2 + 0.15 * center))
  z3 <- stats::rnorm(n, mean = 0.2 * batch, sd = 1)

  built <- build_instrument_score(
    data = data.frame(z1 = z1, z2 = z2, z3 = z3),
    instrument_cols = c("z1", "z2", "z3"),
    method = "z_mean",
    weights = c(0.45, 0.35, 0.20),
    new_col = "instrument"
  )
  instrument <- built$data$instrument

  unobserved <- stats::rnorm(n)
  treatment <- 0.85 * instrument - 0.18 * smoking + 0.12 * bmi - 0.10 * baseline_risk + 0.35 * unobserved + stats::rnorm(n, sd = 0.9)

  true_effect <- -0.10 -
    0.20 * (bmi >= 30) -
    0.12 * (smoking == 1) -
    0.14 * (baseline_risk > 0.65) +
    0.10 * (sex == 0 & age < 60)

  outcome <- 1.3 + 0.04 * age + 0.28 * bmi + 0.55 * smoking + 0.25 * baseline_risk + 0.20 * unobserved + true_effect * treatment + stats::rnorm(n, sd = 1.0)

  data.frame(
    sample_id = sprintf("inst_%05d", seq_len(n)),
    outcome = outcome,
    treatment = treatment,
    instrument = instrument,
    z1 = z1,
    z2 = z2,
    z3 = z3,
    age = age,
    sex = sex,
    bmi = bmi,
    smoking = smoking,
    pc1 = pc1,
    pc2 = pc2,
    center = center,
    batch = batch,
    baseline_risk = baseline_risk,
    true_effect = true_effect,
    stringsAsFactors = FALSE
  )
}

#' Simulate data for an observational causal-forest workflow
#'
#' @param n Number of rows.
#' @param seed Random seed.
#'
#' @return A synthetic `data.frame` for `fit_observational_forest()`.
#' @export
simulate_observational_data <- function(n = 1500, seed = 123) {
  set.seed(seed)

  age <- round(stats::rnorm(n, mean = 63, sd = 10))
  sex <- stats::rbinom(n, 1, 0.46)
  ecog <- sample(0:2, n, replace = TRUE, prob = c(0.45, 0.40, 0.15))
  line <- sample(1:3, n, replace = TRUE, prob = c(0.40, 0.35, 0.25))
  liver_met <- stats::rbinom(n, 1, 0.35)
  tmb <- pmax(0, stats::rnorm(n, mean = 8, sd = 4))
  msi <- stats::rbinom(n, 1, 0.08)
  signature_ifn <- stats::rnorm(n)
  baseline_ctdna <- pmax(0, stats::rlnorm(n, meanlog = 1.5, sdlog = 0.55))
  albumin <- stats::rnorm(n, mean = 3.9, sd = 0.45)
  crp <- pmax(0, stats::rlnorm(n, meanlog = 0.6, sdlog = 0.7))
  site_volume <- stats::rnorm(n)

  linear_ps <- -0.5 + 0.03 * age + 0.40 * ecog + 0.25 * line + 0.35 * liver_met - 0.45 * msi + 0.25 * crp - 0.20 * albumin + 0.20 * site_volume
  propensity <- stats::plogis(scale(linear_ps)[, 1])
  treatment <- stats::rbinom(n, 1, propensity)

  true_effect <- 0.05 +
    0.30 * (msi == 1) +
    0.18 * (signature_ifn > 0.6) -
    0.16 * (baseline_ctdna > stats::quantile(baseline_ctdna, 0.75)) -
    0.12 * (ecog >= 2) +
    0.10 * (tmb > 10)

  baseline_outcome <- -0.4 - 0.02 * age - 0.30 * ecog - 0.18 * line - 0.28 * liver_met + 0.16 * albumin - 0.10 * crp + 0.25 * signature_ifn
  outcome <- baseline_outcome + true_effect * treatment + stats::rnorm(n, sd = 0.7)

  data.frame(
    sample_id = sprintf("obs_%05d", seq_len(n)),
    outcome = outcome,
    treatment = treatment,
    age = age,
    sex = sex,
    ecog = ecog,
    line = line,
    liver_met = liver_met,
    tmb = tmb,
    msi = msi,
    signature_ifn = signature_ifn,
    baseline_ctdna = baseline_ctdna,
    albumin = albumin,
    crp = crp,
    site_volume = site_volume,
    propensity = propensity,
    true_effect = true_effect,
    stringsAsFactors = FALSE
  )
}

#' Simulate data for a survival-forest workflow
#'
#' @param n Number of rows.
#' @param seed Random seed.
#' @param horizon Truncation horizon used in the design.
#'
#' @return A synthetic `data.frame` for `fit_survival_forest()`.
#' @export
simulate_survival_data <- function(n = 1500, seed = 123, horizon = 18) {
  set.seed(seed)

  age <- round(stats::rnorm(n, mean = 64, sd = 9))
  sex <- stats::rbinom(n, 1, 0.47)
  ecog <- sample(0:2, n, replace = TRUE, prob = c(0.48, 0.38, 0.14))
  line <- sample(1:3, n, replace = TRUE, prob = c(0.42, 0.33, 0.25))
  liver_met <- stats::rbinom(n, 1, 0.32)
  inflammation <- stats::rnorm(n)
  biomarker <- stats::rnorm(n)
  pathway_score <- stats::rnorm(n)
  steroid <- stats::rbinom(n, 1, stats::plogis(-1 + 0.3 * ecog + 0.2 * liver_met))

  linear_ps <- -0.4 + 0.02 * age + 0.35 * ecog + 0.22 * line + 0.20 * liver_met + 0.15 * steroid - 0.25 * pathway_score
  treatment <- stats::rbinom(n, 1, stats::plogis(scale(linear_ps)[, 1]))

  true_effect <- 0.8 +
    1.4 * (pathway_score > 0.7) +
    1.1 * (biomarker > 0.6) -
    0.9 * (ecog >= 2) -
    0.7 * (steroid == 1)

  baseline_hazard <- exp(-2.5 + 0.03 * age + 0.35 * ecog + 0.18 * line + 0.40 * liver_met + 0.25 * inflammation - 0.20 * biomarker)
  treatment_hazard <- pmax(0.15, exp(-0.12 * true_effect * treatment))
  failure_time <- stats::rexp(n, rate = baseline_hazard * treatment_hazard)
  censor_time <- stats::runif(n, min = 4, max = horizon + 4)
  time <- pmin(failure_time, censor_time, horizon)
  event <- as.integer(failure_time <= censor_time & failure_time <= horizon)

  data.frame(
    sample_id = sprintf("surv_%05d", seq_len(n)),
    time = time,
    event = event,
    treatment = treatment,
    age = age,
    sex = sex,
    ecog = ecog,
    line = line,
    liver_met = liver_met,
    inflammation = inflammation,
    biomarker = biomarker,
    pathway_score = pathway_score,
    steroid = steroid,
    true_effect = true_effect,
    stringsAsFactors = FALSE
  )
}
