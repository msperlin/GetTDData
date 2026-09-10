#' Gets the current yield curve
#'
#' Downloads and parses information about the current Brazilian yield curve from Anbima.
#'
#' @return A data frame with information about the yield curve.
#' @export
#' @import rvest xml2
#'
#' @examples
#' \dontrun{
#' df_yield <- get_yield_curve()
#' str(df_yield)
#' }
get_yield_curve <- function(){

  if (!curl::has_internet()) {
    stop("No internet connection found...")
  }

  my_url <- 'https://www.anbima.com.br/informacoes/est-termo/CZ.asp'
  h <- curl::new_handle()
  curl::handle_setheaders(h,
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language" = "pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7"
  )

  req <- tryCatch({
    curl::curl_fetch_memory(my_url, handle = h)
  }, error = function(e) {
    # Fallback for Windows machines with outdated root certificate stores
    curl::handle_setopt(h, ssl_verifypeer = FALSE)
    curl::curl_fetch_memory(my_url, handle = h)
  })

  my_html <- rvest::read_html(req$content)
  my_tab <-  my_html %>%
    html_nodes(xpath = '//*[@id="ETTJs"]/table') %>%
    html_table(fill = TRUE )

  if (length(my_tab) == 0) {
    cli::cli_abort("Could not find yield curve table on Anbima website.")
  }

  df_yc <- my_tab[[1]]

  # get date
  my_xpath <- '//*[@id="Parametros"]/table/thead/tr/th[1]'
  raw_date <- my_html %>%
    html_node(xpath = my_xpath) %>%
    html_text(trim = TRUE)

  date_str <- stringr::str_extract(raw_date, "\\d{2}/\\d{2}/\\d{4}")
  date_now <- as.Date(date_str, format = '%d/%m/%Y')

  if (is.na(date_now)) {
    cli::cli_abort("Could not parse reference date from Anbima webpage: '{raw_date}'")
  }

  # get yield curve data and organize it
  df_yc <- df_yc[2:nrow(df_yc), ]

  names(df_yc) <- c('n_biz_days', 'real_return', 'nominal_return', 'implicit_inflation')

  df_yc <- as.data.frame(lapply(df_yc, FUN = function(x) as.character(x)),
                      stringsAsFactors = F)

  n_biz_days <- NULL
  df_yc <- tidyr::pivot_longer(
    data = df_yc,
    cols = -n_biz_days,
    names_to = "type",
    values_to = "value"
  )

  df_yc <- df_yc[df_yc$value!='',]

  # fix cols
  my_fix_fct <- function(x) {
    x <- as.character(x)
    x <- stringr::str_replace(x, stringr::fixed('.'), '')
    x <- stringr::str_replace(x, stringr::fixed(','), '.')

    return(x)
  }

  df_yc <- as.data.frame(lapply(df_yc, FUN = my_fix_fct), stringsAsFactors = F)

  df_yc$n_biz_days <- as.numeric(df_yc$n_biz_days)
  df_yc$value <- as.numeric(df_yc$value)

  bizdays::load_builtin_calendars()
  my_holidays <- bizdays::calendars()[["Brazil/ANBIMA"]]$holidays

  cal <- bizdays::create.calendar("Brazil/ANBIMA",
                         holidays = my_holidays,
                         weekdays=c("saturday", "sunday"))

  df_yc$ref_date <- bizdays::add.bizdays(date_now, df_yc$n_biz_days,
                                         cal = cal)
  df_yc$current_date <- date_now

  return(tibble::as_tibble(df_yc))
}

#' @rdname get_yield_curve
#' @export
get.yield.curve <- function() {
  .Deprecated("get_yield_curve")
  return(get_yield_curve())
}

