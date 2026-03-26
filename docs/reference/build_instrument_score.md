# Build a single instrument score from multiple columns

Build a single instrument score from multiple columns

## Usage

``` r
build_instrument_score(
  data,
  instrument_cols,
  method = c("z_mean", "mean", "sum", "pca1"),
  weights = NULL,
  new_col = "instrument"
)
```

## Arguments

- data:

  A `data.frame`.

- instrument_cols:

  Character vector of raw instrument column names.

- method:

  One of `"z_mean"`, `"mean"`, `"sum"`, or `"pca1"`.

- weights:

  Optional numeric weights.

- new_col:

  Name of the generated instrument score column.

## Value

A list with `data` and `instrument_map`.
