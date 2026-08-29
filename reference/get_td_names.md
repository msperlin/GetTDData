# Returns the available asset names at the Tesouro Direto (TD) website

Returns the available asset names at the Tesouro Direto (TD) website

## Usage

``` r
get_td_names(online = FALSE)
```

## Arguments

- online:

  Logical. If \`TRUE\`, attempts to query the Tesouro Direto CDN server
  for live asset names. Defaults to \`FALSE\`.

## Value

A character vector of names.

## Examples

``` r
get_td_names()
#> [1] "LFT"             "LTN"             "NTN-C"           "NTN-B"          
#> [5] "NTN-B Principal" "NTN-F"           "NTN-B1"         
```
