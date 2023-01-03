#' Returns available instruments
#'
#' @return string vector
#'
#' @noRd
get_td_names <- function() {
  possible.names <- c("LFT","LTN","NTN-C","NTN-B","NTN-B Principal","NTN-F")

  return(possible.names)
}

#' Returns cache directory
#'
#' @return a path
#'
#' @noRd
get_cache_folder <- function() {

  cache_dir <- fs::path_temp("TD_temp")

  return(cache_dir)
}
