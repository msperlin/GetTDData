#' Downloads data of Brazilian government bonds directly from the website
#'
#' This function looks into the tesouro direto website
#' (https://www.tesourodireto.com.br/) and
#' downloads all of the files containing prices and yields of government bonds.
#' You can use input asset.codes to restrict the downloads to specific bonds
#'
#' @param asset.codes Strings that identify the assets (1 or more assets) in the
#'   names of the excel files. E.g. asset.codes = 'LTN'. When set to NULL, it
#'   will download all available assets
#' @param dl.folder Name of folder to save excel files from tesouro direto (will
#'   create if it does not exists)
#' @param do.clean.up Clean up folder before downloading? (TRUE or FALSE)
#' @param do.overwrite Overwrite excel files? (TRUE or FALSE). If FALSE, will
#'   only download the new data for the current year
#' @param n.dl Sets how many files to download from the website. Used only to
#'   decrease CRAN CHECK time. The default value is NULL (downloads all files)
#'
#' @return TRUE if successful
#' @export
#'
#' @examples
#' # only download file where string LTN is found
#' # (only 1 file for simplicity)
#' \dontrun{
#' download.TD.data(asset.codes = 'LTN', n.dl = 1)
#' }
#' # The excel file should be available in folder 'TD Files' (default name)
#'
download.TD.data <- function(asset.codes = 'LTN',
                             dl.folder = 'TD Files',
                             do.clean.up = F,
                             do.overwrite = F,
                             n.dl = NULL) {
  # check folder

  if (!dir.exists(dl.folder)) {
    warning(paste('Folder ', dl.folder, 'was not found. Creating a it..'))
    dir.create(dl.folder)
  }

  # clean up folders
  if (do.clean.up) {
    list.f <- dir(dl.folder, pattern = '*.xls', full.names = T)
    file.remove(list.f)
  }

  # check if user has internet
  test.internet <- curl::has_internet()

  if (!test.internet){
    stop('No internet connection found...')
  }

  # check if names names sense

  possible.names <- get_td_names()
  if (!is.null(asset.codes)){

    idx <- asset.codes %in% possible.names

    if (!any(idx)){
      stop(paste(c('Input asset.codes not valid. It should be one or many of the following: ', possible.names), collapse = ', '))
    }

  } else {
    asset.codes <- possible.names
  }

  # replace space by _
  asset.codes <- stringr::str_replace_all(asset.codes, " ", "_")

  first_year = 2005L
  last_year = as.integer(format(Sys.Date(), "%Y"))
  vec_years = first_year:last_year

  base_url <- "https://cdn.tesouro.gov.br/sistemas-internos/apex/producao/sistemas/sistd/{vec_years}/{asset.codes}_{vec_years}.xls"
  file_grid <- tidyr::expand_grid(asset.codes, vec_years) %>%
    dplyr::mutate(url = stringr::str_glue(base_url))

  # proceed with download loop
  my.links <- file_grid$url
  n.links <- length(my.links)

  if (!is.null(n.dl)) {
    file_grid <- file_grid[1:n.dl, ]
  }

  my.c <- 1
  for (i in 1:nrow(file_grid)) {

    i.link <- file_grid$url[i]
    my.name <- file_grid$asset.codes[i]
    my.year <- file_grid$vec_years[i]

    .fname <- paste0(my.name, '_', my.year, '.xls')
    out.file <- file.path(dl.folder, .fname)

    cat(paste0('\nDownloading file ', out.file, ' (',my.c, '-', n.links, ')'))

    # check if file exists and if it does not contain the current year
    # in its name (thats how tesouro direto stores new data)

    test.current.year <- stringr::str_detect(out.file, format(Sys.Date(),'%Y'))

    if (file.exists(out.file)&(!test.current.year)&(!do.overwrite)){

      cat(' Found file in folder, skipping it.')
      my.c <- my.c + 1
      next()
    }

    #browser()

    cat(' Downloading...')
    utils::download.file(
      url = i.link,
      method = "auto",
      mode = "wb",
      destfile = out.file,
      quiet = T)

    my.c <- my.c + 1

  }

  return(T)

}
