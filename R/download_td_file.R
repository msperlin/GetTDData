#' Downloads a single file from the Tesouro Direto (TD) server
#'
#' @param asset_code The code of the asset (e.g., 'LTN').
#' @param year The year of the data (numeric).
#' @param dl_folder The path to the download folder.
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

#' Downloads multiple files from Tesouro Direto (TD) in parallel using curl
#'
#' @param asset_codes A character vector of asset codes.
#' @param years A numeric vector of years.
#' @param dl_folder The path to the download folder.
#'
#' @noRd
download_td_files_parallel <- function(asset_codes, years, dl_folder) {
  unique_codes <- unique(asset_codes)
  for (code in unique_codes) {
    asset_folder <- fs::path(dl_folder, code)
    if (!dir.exists(asset_folder)) {
      fs::dir_create(asset_folder, recurse = TRUE)
    }
  }

  urls <- stringr::str_glue(
    "https://cdn.tesouro.gov.br/sistemas-internos/apex/producao/sistemas/sistd/{years}/{asset_codes}_{years}.xls"
  )
  file_basenames <- basename(urls)
  dest_paths <- fs::path(dl_folder, asset_codes, file_basenames)

  current_year_str <- format(Sys.Date(), '%Y')
  flag_current_year <- stringr::str_detect(file_basenames, current_year_str)

  needs_download <- !fs::file_exists(dest_paths) | flag_current_year

  if (any(!needs_download)) {
    skipped_count <- sum(!needs_download)
    cli::cli_alert_success('Found {skipped_count} files in cache, skipping them.')
  }

  urls_to_dl <- urls[needs_download]
  dests_to_dl <- dest_paths[needs_download]

  if (length(urls_to_dl) > 0) {
    cli::cli_alert_info('Downloading {length(urls_to_dl)} files in parallel...')

    dl_status <- curl::multi_download(
      urls = urls_to_dl,
      destfiles = dests_to_dl,
      resume = TRUE,
      progress = TRUE
    )

    failed_idx <- dl_status$status_code != 200
    if (any(failed_idx)) {
      failed_urls <- urls_to_dl[failed_idx]
      failed_dests <- dests_to_dl[failed_idx]
      cli::cli_alert_danger("Failed to download {sum(failed_idx)} files:")
      for (f_url in failed_urls) {
        cli::cli_alert_danger("  - {f_url}")
      }
      for (f_dest in failed_dests) {
        if (fs::file_exists(f_dest)) fs::file_delete(f_dest)
      }
    } else {
      cli::cli_alert_success("All downloads completed successfully.")
    }
  }

  return(TRUE)
}
