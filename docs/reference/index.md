# Package index

## Core workflows

- [`fit_observational_forest()`](https://dai540.github.io/heteff/reference/fit_observational_forest.md)
  : Fit an observational causal forest workflow

- [`fit_survival_forest()`](https://dai540.github.io/heteff/reference/fit_survival_forest.md)
  : Fit a survival causal forest workflow

- [`fit_instrumental_forest()`](https://dai540.github.io/heteff/reference/fit_instrumental_forest.md)
  : Fit an instrumental forest workflow

- [`case_study_catalog()`](https://dai540.github.io/heteff/reference/case_study_catalog.md)
  :

  Case-study catalog for `heteff`

- [`available_case_studies()`](https://dai540.github.io/heteff/reference/available_case_studies.md)
  : List built-in case study names

- [`run_case_study()`](https://dai540.github.io/heteff/reference/run_case_study.md)
  : Run a built-in case study

- [`export_tables()`](https://dai540.github.io/heteff/reference/export_tables.md)
  : Export output tables to CSV files

- [`export_plots()`](https://dai540.github.io/heteff/reference/export_plots.md)
  :

  Write standard plots for a `heteff_fit`

## Main plots

- [`plot_observational_dag()`](https://dai540.github.io/heteff/reference/plot_observational_dag.md)
  : Plot the observational causal DAG
- [`plot_instrumental_dag()`](https://dai540.github.io/heteff/reference/plot_instrumental_dag.md)
  : Plot the instrumental DAG
- [`plot_treatment_outcome()`](https://dai540.github.io/heteff/reference/plot_treatment_outcome.md)
  : Plot the treatment-outcome relationship for an observational
  workflow
- [`plot_first_stage()`](https://dai540.github.io/heteff/reference/plot_first_stage.md)
  : Plot the first-stage treatment-instrument relationship
- [`plot_reduced_form()`](https://dai540.github.io/heteff/reference/plot_reduced_form.md)
  : Plot the reduced-form outcome-instrument relationship
- [`plot_subgroup_effects()`](https://dai540.github.io/heteff/reference/plot_subgroup_effects.md)
  : Plot subgroup mean effects
- [`plot_effect_tree()`](https://dai540.github.io/heteff/reference/plot_effect_tree.md)
  : Plot an explanation tree with a publication-style layout
- [`plot_variable_importance()`](https://dai540.github.io/heteff/reference/plot_variable_importance.md)
  : Plot ranked variable importance

## Example data

- [`simulate_observational_data()`](https://dai540.github.io/heteff/reference/simulate_observational_data.md)
  : Simulate data for an observational causal-forest workflow
- [`simulate_survival_data()`](https://dai540.github.io/heteff/reference/simulate_survival_data.md)
  : Simulate data for a survival-forest workflow
- [`simulate_instrumental_data()`](https://dai540.github.io/heteff/reference/simulate_instrumental_data.md)
  : Simulate data for an instrumental-forest workflow
- [`prepare_case_nhefs()`](https://dai540.github.io/heteff/reference/prepare_case_nhefs.md)
  : Prepare the NHEFS observational case study
- [`prepare_case_nsw()`](https://dai540.github.io/heteff/reference/prepare_case_nsw.md)
  : Prepare the NSW observational case study
- [`prepare_case_veteran()`](https://dai540.github.io/heteff/reference/prepare_case_veteran.md)
  : Prepare the veteran survival case study
- [`prepare_case_rotterdam()`](https://dai540.github.io/heteff/reference/prepare_case_rotterdam.md)
  : Prepare the Rotterdam survival case study
- [`prepare_case_card_data()`](https://dai540.github.io/heteff/reference/prepare_case_card_data.md)
  : Prepare the Card returns-to-schooling case study
- [`prepare_case_schooling_returns()`](https://dai540.github.io/heteff/reference/prepare_case_schooling_returns.md)
  : Prepare the SchoolingReturns case study

## Supplementary helpers

- [`print(`*`<heteff_fit>`*`)`](https://dai540.github.io/heteff/reference/print.heteff_fit.md)
  :

  Print a `heteff_fit` summary

- [`plot(`*`<heteff_fit>`*`)`](https://dai540.github.io/heteff/reference/plot.heteff_fit.md)
  :

  Plot a default subgroup-effect summary from a `heteff_fit`

- [`plot_effect_distribution()`](https://dai540.github.io/heteff/reference/plot_effect_distribution.md)
  : Plot the distribution of estimated sample-level effects

- [`build_instrument_score()`](https://dai540.github.io/heteff/reference/build_instrument_score.md)
  : Build a single instrument score from multiple columns

- [`explain_effect_shap()`](https://dai540.github.io/heteff/reference/explain_effect_shap.md)
  : Compute SHAP-style explanations for fitted local IV effects

- [`summarize_shap()`](https://dai540.github.io/heteff/reference/summarize_shap.md)
  : Summarize SHAP values into a ranked importance table

- [`plot_shap_importance()`](https://dai540.github.io/heteff/reference/plot_shap_importance.md)
  : Plot ranked SHAP importance

- [`fit_causal_tree_explorer()`](https://dai540.github.io/heteff/reference/fit_causal_tree_explorer.md)
  : Run a causalTree-style exploratory analysis

- [`plot_causal_tree_explorer()`](https://dai540.github.io/heteff/reference/plot_causal_tree_explorer.md)
  : Plot a causalTree explorer result
