#' Returns available nammes at TD site
#'
#' @return string vector
#'
#' @export
#'
#' @examples
#' get_td_names()
get_td_names <- function() {
  possible.names <- c("LFT","LTN","NTN-C","NTN-B","NTN-B Principal","NTN-F")

  return(possible.names)
}

#' Returns cache directory
#'
#' @return a path
#'
#' @export
#'
#' @examples
#' get_cache_folder()
get_cache_folder <- function() {

  cache_dir <- fs::path_temp("td-files")

  return(cache_dir)
}


#' Cleans raw data from TD
#'
#' @noRd
clean_td_data <- function(temp_df) {

  col_names <-  c('ref_date','yield_bid','price_bid')
  cols_to_import <- c(1, 2, 4)

  temp_df <- temp_df[, cols_to_import]
  n_col <- ncol(temp_df)

  # fix for different format of xls files

  colnames(temp_df) <- col_names
  temp_df[, c(2:n_col)] <- suppressWarnings(
    data.frame(lapply(X = temp_df[, c(2:n_col)], as.numeric))
  )

  temp_df <- temp_df[stats::complete.cases(temp_df), ]


  # fix for data in xls (for some files, dates comes in a numeric format and for others as strings)

  if (stringr::str_detect(as.character(temp_df$ref_date[1]),'/')){

    dateVec <- as.Date(as.character(temp_df[ , 1]), format = '%d/%m/%Y')

  } else {

    if (is.numeric(temp_df$ref_date)) {

      dateVec <- as.Date(as.numeric(temp_df$ref_date)-2,  origin="1900-01-01")

    } else {
      dateVec <- as.Date(temp_df$ref_date)
    }

  }

  temp_df$ref_date <- dateVec

  return(temp_df)

}


#' Returns maturity dates from asset code
#'
#' @noRd
get_matur <- function(x){
  x <- substr(x, nchar(x)-5, nchar(x))
  return(as.Date(x,'%d%m%y'))
}

#' Fixes TD names
#'
#' @noRd
fix_td_names <- function(str_in) {
  # fix names (TD website is a mess!!)
  str_in <- stringr::str_replace_all(str_in,
                                     stringr::fixed('NTNBP'),
                                     'NTN-B Principal')

  str_in <- stringr::str_replace_all(str_in,
                                     stringr::fixed('NTNF'),
                                     'NTN-F')

  str_in <- stringr::str_replace_all(str_in,
                                     stringr::fixed('NTNB'),
                                     'NTN-B')

  str_in <- stringr::str_replace_all(str_in,
                                     stringr::fixed('NTNC'),
                                     'NTN-C')


  # fix names for NTN-B Principal
  str_in <- stringr::str_replace_all(str_in,
                                     'NTN-B Princ ',
                                     'NTN-B Principal '  )

  return(str_in)
}
