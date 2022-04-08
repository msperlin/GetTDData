#' Returns available instruments
#'
#' @return string vector
#'
#' @noRd
get_td_names <- function() {
  possible.names <- c("LFT","LTN","NTN-C","NTN-B","NTN-B Principal","NTN-F")

  return(possible.names)
}
