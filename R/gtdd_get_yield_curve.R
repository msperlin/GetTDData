#' Gets the current yield curve
#'
#' Downloads and parses information about the current Brazilian yield curve.
#'
#' @return A dataframe with information about the yield curve
#' @export
#'
#' @examples
#' df.yield <- get.yield.curve()
#' str(df.yield)
get.yield.curve <- function(){

  # message and return empty df
  my.msg <- paste0('The previous Anbima site is no longer available. Data about ',
                   'the yield curve cannot be scrapped from the site, meaning that ',
                   'this function is no longer working. An alternative (and free) source of brazilian yield data is ',
                   'being searched. If you know one, please drop an email at marceloperlin@gmail.com. \n\n',
                   'Returning an empty dataframe.')
  message(my.msg)

  return(data.frame())

  # rest of code (keep it for reference)
  my.l <- XML::readHTMLTable('http://www.anbima.com.br/est_termo/CZ.asp')

  # get date
  temp <- my.l[[6]]
  date.now <- as.Date(names(temp)[1], '%d/%m/%Y')

  # get yield curve data and organizes it
  df <- my.l[[7]]
  df <- df[3:nrow(df), ]

  names(df) <- c('n.biz.days', 'real_return', 'nominal_return', 'implicit_inflation')

  df <- as.data.frame(lapply(df, FUN = function(x) as.character(x)),
                      stringsAsFactors = F)

  n.biz.days <- NULL
  df <- tidyr::gather(data = df, 'type', value = 'value', -n.biz.days )

  df <- df[df$value!='',]

  # also get additional, short term, data for expected nominal returns
  temp <- my.l[[11-3]]
  temp.nrow <- nrow(temp)

  df <- rbind(df, data.frame(n.biz.days = c(as.character(temp[[1]][3:temp.nrow]),
                                        as.character(temp[[3]][3:temp.nrow])),
                             type = rep ('nominal_return', temp.nrow*2-4),
                             value = c(as.character(temp[[2]][3:temp.nrow]),
                                       as.character(temp[[4]][3:temp.nrow]))) )

  # fix cols
  my.fix.fct <- function(x) {
    x <- as.character(x)
    x <- stringr::str_replace(x, stringr::fixed('.'), '')
    x <- stringr::str_replace(x, stringr::fixed(','), '.')

    return(x)
  }
  my.fix.fct(df$value)
  df <- as.data.frame(lapply(df, FUN = my.fix.fct), stringsAsFactors = F)

  df$n.biz.days <- as.numeric(df$n.biz.days)
  df$value <- as.numeric(df$value)
  df$ref.date <- bizdays::add.bizdays(date.now, df$n.biz.days)
  df$current.date <- date.now

  return(df)

}

