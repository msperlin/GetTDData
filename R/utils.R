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


get_matur <- function(x){
  x <- substr(x, nchar(x)-5, nchar(x))
  return(as.Date(x,'%d%m%y'))
}
