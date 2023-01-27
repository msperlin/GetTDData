#' Downloads data of Brazilian government bonds directly from the website
#'
#' This function looks into the tesouro direto website
#' (https://www.tesourodireto.com.br/) and
#' downloads all of the files containing prices and yields of government bonds.
#' You can use input asset_codes to restrict the downloads to specific bonds
#'
#' @param asset_codes Strings that identify the assets (1 or more assets) in the
#'   names of the excel files. E.g. asset_codes = 'LTN'. When set to NULL, it
#'   will download all available assets
#' @param first_year first year of data (minimum of 2015)
#' @param last_year first year of data
#' @param dl_folder Name of folder to save excel files from tesouro direto (will
#'   create if it does not exists)
#'
#' @return TRUE if successful
#' @export
#'
#' @examples
#' \dontrun{
#' td_get("LTN", 2020, 2022)
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
  purrr::walk2(dl_grid$asset_codes, dl_grid$vec_years,
               .f = download_td_file,
               dl_folder = dl_folder)

  cli::cli_h3('Checking files')
  asset_folder <- stringr::str_glue(
    "{dl_folder}/{asset_codes}"
  )

  local_files <- fs::dir_ls(asset_folder)

  n_files <- length(local_files)
  cli::cli_alert_success("Found {n_files} files")

  if (n_files == 0){
    cli::cli_abort('Cant find any files at {asset_folder}')
  }

  cli::cli_h3('Reading files')

  df_td <- purrr::map_dfr(local_files,
                          read_td_file)

  df_td <- df_td[stats::complete.cases(df_td), ]

  df_td$asset_code <- fix_td_names(df_td$asset_code)

  df_td$matur_date <- as.Date(sapply(df_td$asset_code, get_matur),
                              origin = '1970-01-01' )

  # clean up zero value prices
  col_classes <- sapply(df_td, class)
  col_classes <- col_classes[col_classes == 'numeric']
  cols_to_change <- names(col_classes)

  # remove yield columns
  cols_to_change <- cols_to_change[!stringr::str_detect(cols_to_change, "yield")]
  idx <- apply((as.matrix(df_td[, cols_to_change]) == 0 ),
               MARGIN = 1, any)

  df_td <- df_td[!idx, ]

  return(df_td)

  return(TRUE)

}
