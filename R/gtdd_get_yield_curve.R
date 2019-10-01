#' Gets the current yield curve
#'
#' Downloads and parses information about the current Brazilian yield curve.
#'
#' @return A dataframe with information about the yield curve
#' @export
#' @import rvest xml2
#'
#' @examples
#' \dontrun{
#' df.yield <- get.yield.curve()
#' str(df.yield)
#' }
get.yield.curve <- function(){

  # message and return empty df (FIXED)
  # my.msg <- paste0('The previous Anbima site is no longer available. Data about ',
  #                  'the yield curve cannot be scrapped from the site, meaning that ',
  #                  'this function is no longer working. An alternative (and free) source of brazilian yield data is ',
  #                  'being searched. If you know one, please drop an email at marceloperlin@gmail.com. \n\n',
  #                  'Returning an empty dataframe.')
  # message(my.msg)
  #return(data.frame())

  # OLD code (keep it for reference)
  #my.l <- XML::readHTMLTable('http://www.anbima.com.br/est_termo/CZ.asp')

  # NEW CODE
  my_html <- read_html('https://www.anbima.com.br/informacoes/est-termo/CZ.asp')
  my_tab <-  my_html %>%
    rvest::html_nodes(xpath = '//*[@id="ETTJs"]/table') %>%
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
  df_yc <- tidyr::gather(data = df_yc, 'type', value = 'value', -n.biz.days )

  df_yc <- df_yc[df_yc$value!='',]

  # also get additional, short term, data for expected nominal returns
  # temp <- my.l[[11-3]]
  # temp.nrow <- nrow(temp)
  #
  # df <- rbind(df, data.frame(n.biz.days = c(as.character(temp[[1]][3:temp.nrow]),
  #                                       as.character(temp[[3]][3:temp.nrow])),
  #                            type = rep ('nominal_return', temp.nrow*2-4),
  #                            value = c(as.character(temp[[2]][3:temp.nrow]),
  #                                      as.character(temp[[4]][3:temp.nrow]))) )

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
  df_yc$ref.date <- bizdays::add.bizdays(date_now, df_yc$n.biz.days)
  df_yc$current.date <- date_now

  return(df_yc)

}

