#' Downloads data of Brazilian government bonds directly from the website
#'
#' This function looks into the tesouro direto website
#' (http://www.tesouro.fazenda.gov.br/tesouro-direto-balanco-e-estatisticas) and
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

  base.url <- "http://sisweb.tesouro.gov.br/apex/f?p=2031:2::::::"

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
    html.code <- RCurl::getURL(base.url,
                               .opts = RCurl::curlOptions(cookiejar="",
                                                          followlocation = TRUE ))

    # making sure the enconding is correct

    html.code <- stringi::stri_enc_toutf8(html.code)

    # check if html.code makes sense. If not, download it again

    if ( (!is.character(html.code))|(stringr::str_length(html.code)<10) ){
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

  # fixing links strings

  my.links <-
    stringr::str_extract_all(html.code,pattern = 'href=\"(.*?)\" download')[[1]]
  my.links <-
    stringr::str_replace_all(my.links,'href=\"',replacement = '')
  my.links <-
    stringr::str_replace_all(my.links,'\" download',replacement = '')

  # find names in links

  my.names <-
    stringr::str_extract_all(html.code,pattern = 'download>(.*?)</a>')[[1]]
  my.names <-
    stringr::str_replace_all(my.names ,'download>',replacement = '')
  my.names <-
    stringr::str_replace_all(my.names ,'</a>',replacement = '')

  # finding years from website

  first.year <- 2002
  year.now <- as.numeric(format(Sys.Date(),'%Y'))
  seq.years <- seq(from =   year.now, to = first.year)

  str.now <- sprintf('<span>%i - </span>',seq.years)

  idx <- stringr::str_locate(string = html.code,str.now)
  idx <- idx[,1]

  idx <- c(as.numeric(idx), nchar(html.code))

  sub.strings <- stringr::str_sub(html.code,start=idx[1:(length(idx)-1)],end = idx[2:(length(idx))])

  my.fct <- function(x,sub.strings){
    idx <- which(stringr::str_detect(sub.strings, stringr::fixed(x) ))
    return(idx)
  }

  idx.years <- sapply(X = my.links, FUN = my.fct, sub.strings=sub.strings)

  my.years <- seq.years[idx.years]

  # find asset code in names

  if (!is.null(asset.codes)) {

    idx <- my.names %in% asset.codes

    my.links <- my.links[idx]
    my.names <- my.names[idx]
    my.years <- my.years[idx]

  }

  # proceed with download loop

  n.links <- length(my.links)

  if (!is.null(n.dl)){
    my.links <-my.links[1:n.dl]
  }

  my.c <- 1
  for (i.link in my.links) {

    out.file <-
      paste0(dl.folder,'/',paste0(my.names[my.c],'_',my.years[my.c], '.xls'))

    i.link <- paste0('http://sisweb.tesouro.gov.br/apex/', i.link)

    cat(paste0('\nDownloading file ', out.file, ' (',my.c, '-', n.links, ')'))

    # check if file exists and if it does not contain the current year
    # in its name (thats how tesouro direto stores new data)

    test.current.year <- stringr::str_detect(out.file,format(Sys.Date(),'%Y'))

    if (file.exists(out.file)&(!test.current.year)&(!do.overwrite)){

      cat(' Found file in folder, skipping it.')
      my.c <- my.c + 1
      next()
    }

    #browser()

    cat(' Downloading...')
    utils::download.file(
      url = i.link,
      method = 'internal',
      mode = 'wb',
      destfile = out.file,
      quiet = T )

    my.c <- my.c + 1

  }

  return(T)

}
