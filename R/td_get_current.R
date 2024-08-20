#' Returns current TD prices
#'
#' Fetches current prices of TD assets from website's json api at <https://www.tesourodireto.com.br/titulos/precos-e-taxas.htm>
#'
#' @return a dataframe with prices
#' @export
#'
#' @examples
#' \dontrun{
#' td_get_current()
#' }
td_get_current <- function() {

  cli::cli_alert_info("fetching current TD prices")

  # 20240820: error on call: HTTP status was '403 Forbidden
  cli::cli_alert_danger("20240820: The json endpoint for current TD prices is now forbidden. Returning empty dataframe. ")
  return(dplyr::tibble())

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

  cli::cli_alert_success("got dataframe with {nrow(df_current)} rows and {ncol(df_current)} columns")

  return(df_current)
}
