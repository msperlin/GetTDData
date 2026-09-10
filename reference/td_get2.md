# Downloads data for Brazilian government bonds from Tesouro Transparente (CKAN)

This function downloads historical prices and yields of Brazilian
government bonds directly from the Tesouro Transparente CKAN open data
portal
(\<https://www.tesourotransparente.gov.br/ckan/dataset/taxas-dos-titulos-ofertados-pelo-tesouro-direto/\>).
It serves as the modern replacement for
[`td_get`](https://msperlin.github.io/GetTDData/reference/td_get.md),
which relied on the legacy Tesouro Direto application shut down in
August 2026.

## Usage

``` r
td_get2(
  asset_codes = "LTN",
  first_year = 2005,
  last_year = as.numeric(format(Sys.Date(), "%Y")),
  dl_folder = get_cache_folder(),
  force_download = FALSE,
  dataset_url = get_default_ckan_url()
)
```

## Arguments

- asset_codes:

  A character vector identifying the assets to download (e.g., 'LTN',
  'NTN-B', 'LFT', 'NTN-B Principal', 'NTN-F', 'NTN-C', 'NTN-B1',
  'Educa+', 'RendA+'). You can also pass official names such as 'Tesouro
  Prefixado', 'Tesouro Selic', etc. If \`NULL\`, downloads all available
  assets. Defaults to 'LTN'.

- first_year:

  The first year of data (minimum of 2005). Defaults to 2005.

- last_year:

  The last year of data. Defaults to the current year.

- dl_folder:

  Path of the folder to save data files from Tesouro Transparente.
  Defaults to
  [`get_cache_folder()`](https://msperlin.github.io/GetTDData/reference/get_cache_folder.md).

- force_download:

  Logical. If \`TRUE\`, forces redownloading the data even if a cached
  version from today is present. Defaults to \`FALSE\`.

- dataset_url:

  The URL to the CKAN dataset page or direct CSV file. Defaults to
  "https://www.tesourotransparente.gov.br/ckan/dataset/taxas-dos-titulos-ofertados-pelo-tesouro-direto/".

## Value

A `tibble` (data frame) containing the asset data:

- ref_date:

  Reference date (Date)

- yield_bid:

  Annual purchase yield / rate in decimal format (numeric, e.g. 0.1183
  for 11.83%)

- price_bid:

  Unit purchase price in BRL (numeric)

- asset_code:

  Standard bond identifier (character, e.g. 'LTN 010123')

- matur_date:

  Maturity date of the bond (Date)

## Examples

``` r
if (FALSE) { # \dontrun{
df_td <- td_get2("LTN", 2020, 2022)
head(df_td)
} # }
```
