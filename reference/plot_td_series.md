# Plot Tesouro Direto Time Series Data

Plots price or yield time series trajectories for Tesouro Direto assets
downloaded using
[`td_get`](https://msperlin.github.io/GetTDData/reference/td_get.md).

## Usage

``` r
plot_td_series(df_td, type = c("price", "yield"))
```

## Arguments

- df_td:

  A data frame or tibble returned by
  [`td_get`](https://msperlin.github.io/GetTDData/reference/td_get.md).

- type:

  Character string indicating what to plot: `"price"` (price_bid) or
  `"yield"` (yield_bid). Defaults to `"price"`.

## Value

A `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
df_td <- td_get("LTN", 2020, 2022)
plot_td_series(df_td, type = "price")
} # }
```
