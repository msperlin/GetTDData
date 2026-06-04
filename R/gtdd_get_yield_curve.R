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

  my_html <- read_html('https://www.anbima.com.br/informacoes/est-termo/CZ.asp')
  my_tab <-  my_html %>%
    html_nodes(xpath = '//*[@id="ETTJs"]/table') %>%
    html_table(fill = TRUE )

  df_yc <- my_tab[[1]]

  # get date
  my_xpath <- '//*[@id="Parametros"]/table/thead/tr/th[1]'
  date_now <- my_html %>%
    html_node(xpath = my_xpath) %>%
    html_text() %>%
    as.Date('%d/%m/%Y')

  # get yield curve data and organize it
  df_yc <- df_yc[2:nrow(df_yc), ]

  names(df_yc) <- c('n.biz.days', 'real_return', 'nominal_return', 'implicit_inflation')

  df_yc <- as.data.frame(lapply(df_yc, FUN = function(x) as.character(x)),
                      stringsAsFactors = F)

  n.biz.days <- NULL
  df_yc <- tidyr::pivot_longer(
    data = df_yc,
    cols = -n.biz.days,
    names_to = "type",
    values_to = "value"
  )

  df_yc <- df_yc[df_yc$value!='',]

  # fix cols
  my.fix.fct <- function(x) {
    x <- as.character(x)
    x <- stringr::str_replace(x, stringr::fixed('.'), '')
    x <- stringr::str_replace(x, stringr::fixed(','), '.')

    return(x)
  }

  df_yc <- as.data.frame(lapply(df_yc, FUN = my.fix.fct), stringsAsFactors = F)

  df_yc$n.biz.days <- as.numeric(df_yc$n.biz.days)
  df_yc$value <- as.numeric(df_yc$value)

  bizdays::load_builtin_calendars()
  my_holidays <- bizdays::calendars()[["Brazil/ANBIMA"]]$holidays

  cal <- bizdays::create.calendar("Brazil/ANBIMA",
                         holidays = my_holidays,
                         weekdays=c("saturday", "sunday"))

  df_yc$ref.date <- bizdays::add.bizdays(date_now, df_yc$n.biz.days,
                                         cal = cal)
  df_yc$current.date <- date_now

  return(df_yc)

}

#' @rdname get_yield_curve
#' @export
get.yield.curve <- function() {
  .Deprecated("get_yield_curve")
  return(get_yield_curve())
}

