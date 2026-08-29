# Plot the ANBIMA Yield Curve

Plots the yield curve data frame downloaded using
[`get_yield_curve`](https://msperlin.github.io/GetTDData/reference/get_yield_curve.md).

## Usage

``` r
plot_yield_curve(df_yc)
```

## Arguments

- df_yc:

  A data frame or tibble returned by
  [`get_yield_curve`](https://msperlin.github.io/GetTDData/reference/get_yield_curve.md).

## Value

A `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
df_yc <- get_yield_curve()
plot_yield_curve(df_yc)
} # }
```
