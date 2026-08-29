#' Returns current TD prices and yields
#'
#' Fetches current prices and yields of Tesouro Direto (TD) assets by downloading the latest daily data available from the website.
#'
#' @param asset_codes A character vector identifying the assets (e.g., 'LTN', 'NTN-B'). If `NULL`, returns all available assets.
#' @param dl_folder Path of the folder to save Excel files from Tesouro Direto. Defaults to a session-temporary directory.
#'
#' @return A tibble with current asset prices, yields, and maturity dates.
#' @export
#'
#' @examples
#' \dontrun{
#' df_current <- td_get_current()
#' head(df_current)
#' }
td_get_current <- function(asset_codes = NULL, dl_folder = get_cache_folder()) {

  cli::cli_alert_info("Fetching current TD prices and yields...")

  current_year <- as.numeric(format(Sys.Date(), "%Y"))

  df_td <- td_get(
    asset_codes = asset_codes,
    first_year = current_year,
    last_year = current_year,
    dl_folder = dl_folder
  )

  if (nrow(df_td) == 0) {
    cli::cli_alert_warning("No data found for the current year.")
    return(tibble::tibble())
  }

  latest_date <- max(df_td$ref_date, na.rm = TRUE)
  df_current <- df_td |>
    dplyr::filter(.data$ref_date == latest_date)

  cli::cli_alert_success(
    "Got {nrow(df_current)} current asset prices for reference date {latest_date}"
  )

  return(tibble::as_tibble(df_current))
}
