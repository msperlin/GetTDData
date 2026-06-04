# Returns current TD prices

Fetches current prices of Tesouro Direto (TD) assets from the website's
JSON API at
\<https://www.tesourodireto.com.br/titulos/precos-e-taxas.htm\>.

## Usage

``` r
td_get_current()
```

## Value

A data frame with prices.

## Examples

``` r
if (FALSE) { # \dontrun{
df_current <- td_get_current()
} # }
```
