# Downloads data for Brazilian government bonds directly from the website

This function looks into the Tesouro Direto website
(\<https://www.tesourodireto.com.br/\>) and downloads all files
containing prices and yields of government bonds. You can use the input
\`asset_codes\` to restrict the downloads to specific bonds.

## Usage

``` r
td_get(
  asset_codes = "LTN",
  first_year = 2005,
  last_year = as.numeric(format(Sys.Date(), "%Y")),
  dl_folder = get_cache_folder()
)
```

## Arguments

- asset_codes:

  A character vector identifying the assets (one or more) in the names
  of the Excel files (e.g., 'LTN'). If \`NULL\`, downloads all available
  assets.

- first_year:

  The first year of data (minimum of 2005).

- last_year:

  The last year of data.

- dl_folder:

  Path of the folder to save Excel files from Tesouro Direto (will
  create if it does not exist). Defaults to a session-temporary
  directory. To avoid redownloading files across different R sessions,
  you can pass a persistent path (e.g., a local folder path, or using
  tools::R_user_dir("GetTDData", which = "cache")).

## Value

A data frame containing the asset data (prices and yields).

## Examples

``` r
if (FALSE) { # \dontrun{
df_td <- td_get("LTN", 2020, 2022)
} # }
```
