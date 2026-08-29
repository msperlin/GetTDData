#' Downloads data for Brazilian government bonds directly from the website
#'
#' This function looks into the Tesouro Direto website
#' (<https://www.tesourodireto.com.br/>) and
#' downloads all files containing prices and yields of government bonds.
#' You can use the input `asset_codes` to restrict the downloads to specific bonds.
#'
#' @param asset_codes A character vector identifying the assets (one or more) in the
#'   names of the Excel files (e.g., 'LTN'). If `NULL`, downloads all available assets.
#' @param first_year The first year of data (minimum of 2005).
#' @param last_year The last year of data.
#' @param dl_folder Path of the folder to save Excel files from Tesouro Direto (will
#'   create if it does not exist). Defaults to a session-temporary directory.
#'   To avoid redownloading files across different R sessions, you can pass a
#'   persistent path (e.g., a local folder path, or using tools::R_user_dir("GetTDData", which = "cache")).
#'
#' @return A data frame containing the asset data (prices and yields).
#' @export
#'
#' @examples
#' \dontrun{
#' df_td <- td_get("LTN", 2020, 2022)
#' }
td_get <- function(asset_codes = 'LTN',
                   first_year = 2005,
                   last_year = as.numeric(format(Sys.Date(), "%Y")),
                   dl_folder = get_cache_folder()) {

  # check years
  if (first_year < 2005) {
    warning('First year of TD data is 2005. Fixing input first_year to 2005.')
    first_year <- 2005
  }

  # check if user has internet
  if (!curl::has_internet()){
    stop('No internet connection found...')
  }

  # check if names names sense
  possible_names <- get_td_names()
  if (!is.null(asset_codes)){

    idx <- !(asset_codes %in% possible_names)

    if (any(idx)){
      cli::cli_abort(
        paste0('Input asset_codes not valid. ',
        'It should be one or many of the following: {possible_names}'
        ))
    }

  } else {
    asset_codes <- possible_names
  }

  # replace space by _
  asset_codes <- stringr::str_replace_all(asset_codes, " ", "_")

  vec_years = first_year:last_year

  dl_grid <- tidyr::expand_grid(asset_codes, vec_years)

  cli::cli_h3('Downloading TD files')
  download_td_files_parallel(dl_grid$asset_codes, dl_grid$vec_years, dl_folder = dl_folder)

  cli::cli_h3('Checking files')
  asset_folder <- stringr::str_glue(
    "{dl_folder}/{asset_codes}"
  )

  local_files <- fs::dir_ls(asset_folder, regexp = "\\.xls$")

  n_files <- length(local_files)
  cli::cli_alert_success("Found {n_files} files")

  if (n_files == 0){
    cli::cli_abort('Cant find any files at {asset_folder}')
  }

  cli::cli_h3('Reading files')

  # Set up parallel execution if multiple cores are available
  n_cores <- parallel::detectCores() - 1
  if (is.na(n_cores) || n_cores < 1) n_cores <- 1
  n_cores <- min(n_cores, 2) # Limit to 2 to comply with CRAN checks

  if (n_cores > 1) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterExport(cl, c("read_td_file", "clean_td_data", "get_matur", "fix_td_names"), envir = asNamespace("GetTDData"))
    parallel::clusterEvalQ(cl, {
      library(readxl)
      library(dplyr)
      library(tibble)
      library(stringr)
    })
    res_list <- parallel::parLapply(cl, local_files, read_td_file)
  } else {
    res_list <- lapply(local_files, read_td_file)
  }

  df_td <- dplyr::bind_rows(res_list)

  df_td <- df_td[stats::complete.cases(df_td), ]

  df_td$asset_code <- fix_td_names(df_td$asset_code)

  df_td$matur_date <- get_matur(df_td$asset_code)

  # clean up zero value prices
  col_classes <- sapply(df_td, class)
  col_classes <- col_classes[col_classes == 'numeric']
  cols_to_change <- names(col_classes)

  # remove yield columns
  cols_to_change <- cols_to_change[!stringr::str_detect(cols_to_change, "yield")]
  idx <- apply((as.matrix(df_td[, cols_to_change]) == 0 ),
               MARGIN = 1, any)

  df_td <- df_td[!idx, ]

  return(tibble::as_tibble(df_td))
}
