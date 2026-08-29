# Returns current TD prices and yields

Fetches current prices and yields of Tesouro Direto (TD) assets by
downloading the latest daily data available from the website.

## Usage

``` r
td_get_current(asset_codes = NULL, dl_folder = get_cache_folder())
```

## Arguments

- asset_codes:

  A character vector identifying the assets (e.g., 'LTN', 'NTN-B'). If
  \`NULL\`, returns all available assets.

- dl_folder:

  Path of the folder to save Excel files from Tesouro Direto. Defaults
  to a session-temporary directory.

## Value

A tibble with current asset prices, yields, and maturity dates.

## Examples

``` r
if (FALSE) { # \dontrun{
df_current <- td_get_current()
head(df_current)
} # }
```
