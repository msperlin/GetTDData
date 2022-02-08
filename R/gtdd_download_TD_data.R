#' Downloads data of Brazilian government bonds directly from the website
#'
#' This function looks into the tesouro direto website
#' (https://www.tesourodireto.com.br/titulos/historico-de-precos-e-taxas.htm) and
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

  if (!is.null(asset.codes)){
    possible.names <- c("LFT","LTN","NTN-C","NTN-B","NTN-B Principal","NTN-F")

    idx <- asset.codes %in% possible.names

    if (!any(idx)){
      stop(paste(c('Input asset.codes not valid. It should be one or many of the following: ', possible.names), collapse = ', '))
    }

  }

  base.url <- "https://www.tesourodireto.com.br/lumis/api/rest/documentos/lumgetdata/list.json?lumReturnFields=documentFile,title,description,tags&lumMaxRows=999"

  # # read html (OLD CODE, keep it for reference)
  #
  # html.code <- RCurl::getURL(base.url,
  #                             .opts = RCurl::curlOptions(cookiejar="",
  #                                                        useragent = "Mozilla/5.0",
  #                                                        followlocation = TRUE ))

  # read html code (trying max.tries)

  max.tries <- 10

  i.try <- 1
  while (TRUE){
    cat('\nDownloading html page (attempt = ', i.try,'|',max.tries,')',sep = '')

    json_code <- RCurl::getURL(
      base.url,
      httpheader = c(
        Accept = "application/json",
        Referer = "https://www.tesourodireto.com.br/titulos/historico-de-precos-e-taxas.htm"
      ),
      ssl.verifypeer = FALSE,
      .opts = RCurl::curlOptions(cookiejar = "", followlocation = TRUE)
    )


    # check if html.code makes sense. If not, download it again

    if ( (!is.character(json_code))|(stringr::str_length(json_code)<10) ){
      cat(' - Error in downloading html page. Trying again..')
    } else {
      break()
    }

    if (i.try==max.tries){
      stop('Reached maximum number of attempts to download html code. Exiting now...')
    }

    i.try <- i.try + 1

    Sys.sleep(1)
  }

  json <- jsonlite::fromJSON(json_code)

  # fixing links strings

  my.links <- json$rows$documentFile$downloadHref

  # find names in links

  my.names <- stringr::str_replace_all(json$rows$documentFile$name, "_", " ")
  my.names <- stringr::str_match(my.names, "[A-Za-z- ]+")
  my.names <- stringr::str_replace(my.names, "^historico", "")
  my.names <- stringr::str_replace(my.names, "^NTNB", "NTN-B")
  my.names <- stringr::str_replace(my.names, "^NTNC", "NTN-C")
  my.names <- stringr::str_replace(my.names, "^NTNF", "NTN-F")
  my.names <- stringr::str_replace(my.names, "^NTN-BPrincipal", "NTN-B Principal")
  my.names <- stringr::str_replace(my.names, "^NTN-CPrincipal", "NTN-C Principal")
  my.names <- stringr::str_trim(my.names)

  # finding years from website

  my.years <- stringr::str_match(json$rows$documentFile$name, "\\d{4}")

  # find asset code in names

  if (!is.null(asset.codes)) {

    idx <- my.names %in% asset.codes
    my.links <- my.links[idx]
    my.names <- my.names[idx]
    my.years <- my.years[idx]

    idx <- order(my.names, my.years)
    my.links <- my.links[idx]
    my.names <- my.names[idx]
    my.years <- my.years[idx]

  }

  # proceed with download loop

  n.links <- length(my.links)

  if (!is.null(n.dl)) {
    my.links <- my.links[1:n.dl]
  }

  my.c <- 1
  for (i.link in my.links) {

    .fname <- paste0(my.names[my.c], '_', my.years[my.c], '.xls')
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
