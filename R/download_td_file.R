#' Downloads single file from TD ftp
#'
#' @param asset_code code of asset
#' @param year year of data
#' @param dl_folder download folder
#'
#' @noRd
download_td_file <- function(asset_code, year, dl_folder) {

  # check folder
  asset_folder <- fs::path(
    dl_folder,
    asset_code)

  if (!dir.exists(asset_folder)) {
    fs::dir_create(asset_folder, recurse = TRUE)
  }

  base_url <- stringr::str_glue(
    "https://cdn.tesouro.gov.br/sistemas-internos/apex/producao/sistemas/sistd/{year}/{asset_code}_{year}.xls"
  )
  file_basename <- basename(base_url)

  local_file <- fs::path(asset_folder, file_basename)

  cli::cli_alert_info('Downloading {file_basename}')

  # check if file exists and if it does not contain the current year
  # in its name (thats how tesouro direto stores new data)
  flag_current_year <- stringr::str_detect(file_basename, format(Sys.Date(),'%Y'))


  if (fs::file_exists(local_file)&(!flag_current_year)){

    cli::cli_alert_success('\tFound file in folder, skipping it.')
    return(TRUE)

  }

  try({
    utils::download.file(
      url = base_url,
      method = "auto",
      mode = "wb",
      destfile = local_file,
      quiet = T)
  })

  # sleep for a bit..
  Sys.sleep(0.5)

  if (!fs::file_exists(local_file)) {

    cli::cli_alert_danger("Download error. Can't find file {local_file}..")
    return(FALSE)

  } else {
    # 20250519 removed due to humanize exit from cran
    #this_size <- humanize::natural_size(fs::file_size(local_file))
    #cli::cli_alert_success("\t{local_file} is found, with size {this_size}.")

    cli::cli_alert_success("\t{local_file} is found.")
  }

  return(TRUE)

}
