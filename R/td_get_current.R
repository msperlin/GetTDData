#' Returns current TD prices
#'
#' Fetches current prices of TD assets from website's json api
#'
#' @return a dataframe with prices
#' @export
#'
#' @examples
#' td_get_current()
td_get_current <- function() {
  url <- "https://www.tesourodireto.com.br/json/br/com/b3/tesourodireto/service/api/treasurybondsinfo.json"
  l_out <- jsonlite::fromJSON(url)

  df_current <- l_out$response$TrsrBdTradgList$TrsrBd |>
    dplyr::mutate(maturity = as.Date(mtrtyDt),
                  name = nm,
                  min_qtd = minRedQty,
                  min_value = minRedVal,
                  price = untrRedVal,
                  annual_ret = anulRedRate/100) |>
    dplyr::select(name, maturity, min_qtd, min_value,
                  price, annual_ret)

  return(df_current)
}
