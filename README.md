
<!-- README.md is generated from README.Rmd. Please edit that file -->

<!-- badges: start -->

[![Codecov test
coverage](https://codecov.io/gh/msperlin/GetTDData/branch/master/graph/badge.svg)](https://app.codecov.io/gh/msperlin/GetTDData?branch=master)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

# Package `GetTDData`

Information regarding prices and yields of bonds issued by the Brazilian
government can be downloaded manually as excel files from the [Tesouro
Direto website](https://www.tesourodireto.com.br/). However, it is
painful to aggregate all of this data into something useful as the
several files don’t have an uniform format.

Package `GetTDData` makes the process of importing data from Tesouro
direto much easier. All that you need in order to download the data is
the name of the assets (LFT, LTN, NTN-C, NTN-B, NTN-B Principal, NTN-F).

## Installation

    # from CRAN (stable version)
    install.package('GetTDData')

    # from github (development version)
    devtools::install_github('msperlin/GetTDData')

## How to use GetTDData

Suppose you need financial data (prices and yields) for a bond of type
LTN with a maturity (end of contract) at 2023-01-01. This bullet bond is
the most basic debt contract the Brazilian government issues. It does
not pay any value (coupon) during its lifetime and will pay 1000 R\$ at
maturity.

In order to get the data, all you need to do is to run the following
code in R:

``` r
library(GetTDData)

assets <- 'LTN'   # Identifier of assets 
first_year <- 2020
last_year <- 2022

df_td <- td_get(assets,
                first_year,
                last_year)
#> 
#> ── Downloading TD files
#> ℹ Downloading 3 files in parallel...
#> ✔ All downloads completed successfully.
#> 
#> ── Checking files
#> ✔ Found 3 files
#> 
#> ── Reading files
```

Let’s plot the prices to check if the code worked:

``` r
library(ggplot2)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

# filter  LTN 
my_asset_code <- "LTN 010123"

LTN <- df_td %>%
  filter(asset_code  ==  my_asset_code)

p <- ggplot(data = LTN, 
            aes(x = as.Date(ref_date), 
                y = price_bid, 
                color = asset_code)) + 
  geom_line(linewidth = 1) + scale_x_date() + labs(title = '', x = 'Dates')

print(p)
```

<img src="man/figures/README-plot.prices-1.png" alt="" width="100%" />

## Downloading the Brazilian Yield Curve

The latest version of `GetTDData` offers function `get_yield_curve` to
download the current Brazilian yield curve directly from Anbima. The
yield curve is a tool of financial analysts that show, based on current
prices of fixed income instruments, how the market perceives the future
real, nominal and inflation returns. You can find more details regarding
the use and definition of a yield curve in
\[Investopedia\]\[<https://www.investopedia.com/terms/y/yieldcurve.asp>\].

``` r
df_yield <- get_yield_curve()  
str(df_yield)
#> tibble [104 × 5] (S3: tbl_df/tbl/data.frame)
#>  $ n_biz_days  : num [1:104] 252 252 252 378 378 378 504 504 504 630 ...
#>  $ type        : chr [1:104] "real_return" "nominal_return" "implicit_inflation" "real_return" ...
#>  $ value       : num [1:104] 7.09 13.57 6.05 7.56 13.83 ...
#>  $ ref_date    : Date[1:104], format: "2027-09-01" "2027-09-01" ...
#>  $ current_date: Date[1:104], format: "2026-08-28" "2026-08-28" ...
```

And we can plot it for the desired result:

``` r
library(ggplot2)

p <- ggplot(df_yield, aes(x=ref_date, y = value) ) +
  geom_line(size=1) + geom_point() + facet_grid(~type, scales = 'free') + 
  labs(title = paste0('The current Brazilian Yield Curve '),
       subtitle = paste0('Date: ', df_yield$current_date[1]))     
#> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
#> ℹ Please use `linewidth` instead.
#> This warning is displayed once per session.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.

print(p)
```

<img src="man/figures/README-unnamed-chunk-3-1.png" alt="" width="100%" />
