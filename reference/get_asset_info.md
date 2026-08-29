# Returns metadata and information about Tesouro Direto bond types

Provides metadata for Brazilian government bond types, including their
official names, indexers (e.g., IPCA, SELIC, Fixed rate), payment
frequency, and description.

## Usage

``` r
get_asset_info(asset_codes = NULL)
```

## Arguments

- asset_codes:

  Optional character vector of asset codes (e.g. 'LTN', 'NTN-B'). If
  \`NULL\`, returns info for all assets.

## Value

A tibble with asset metadata.

## Examples

``` r
get_asset_info()
#> # A tibble: 9 × 5
#>   asset_code      name                                indexer coupon description
#>   <chr>           <chr>                               <chr>   <chr>  <chr>      
#> 1 LTN             Tesouro Prefixado                   Prefix… Zero … Fixed-rate…
#> 2 LFT             Tesouro Selic                       SELIC   Zero … Floating-r…
#> 3 NTN-B           Tesouro IPCA+ com Juros Semestrais  IPCA    Semi-… Inflation-…
#> 4 NTN-B Principal Tesouro IPCA+                       IPCA    Zero … Inflation-…
#> 5 NTN-F           Tesouro Prefixado com Juros Semest… Prefix… Semi-… Fixed-rate…
#> 6 NTN-C           Tesouro IGP-M com Juros Semestrais  IGP-M   Semi-… Inflation-…
#> 7 NTN-B1          Tesouro RendA+ / Educa+             IPCA    Month… Inflation-…
#> 8 RendA+          Tesouro RendA+                      IPCA    Month… Inflation-…
#> 9 Educa+          Tesouro Educa+                      IPCA    Month… Inflation-…
get_asset_info("LTN")
#> # A tibble: 1 × 5
#>   asset_code name              indexer   coupon      description                
#>   <chr>      <chr>             <chr>     <chr>       <chr>                      
#> 1 LTN        Tesouro Prefixado Prefixado Zero Coupon Fixed-rate bond paying R$ …
```
