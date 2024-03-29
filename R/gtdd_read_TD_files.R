#' Reading excel files from Tesouro Direto
#'
#' Reads files downloaded by \code{\link{download.TD.data}}
#'
#' @param dl.folder Folder with excel files from tesouro direto
#' @param cols.to.import Columns (numeric) to import from excel files (open and
#'   check the columns of the excel file from tesouro direto for details)
#' @param col.names Names of columns in final data.frame (same size as
#'   cols.to.import)
#'
#' @return A dataframe with the data
#' @export
#'
#' @examples
#' # Downloads data from tesouro direto (only 1 file for simplicity)
#'
#' dl.folder ='TD Files'
#'
#' \dontrun{
#' download.TD.data(dl.folder = dl.folder, n.dl = 1)
#'
#' my.df <- read.TD.files(dl.folder = dl.folder)
#' }
read.TD.files <- function(dl.folder = 'TD Files',
                          cols.to.import = c(1,2,4),
                          col.names =  c('ref.date','yield.bid','price.bid')){

  # 20230124 DEPRECATION
  my_message <- stringr::str_glue(
    "This function is deprecated and will be removed soon.",
    " Please use the new function, td_get()."
  )
  lifecycle::deprecate_soft(when = "v1.5.3 (2023-01-24)",
                            what = "GetTDData::read.TD.files()",
                            details = c(i = my_message) )

  # Error checking
  if (!is.character(dl.folder)) stop('Argument dl.folder should be a character')
  if (!is.numeric(cols.to.import)) stop('Argument cols.to.import should be numeric ')

  if(!any(cols.to.import == 1)) {
    stop('The first column represents the dates in the excel files. You should include it in cols.to.import')
  }

  if(length(cols.to.import)!=length(col.names)){
    stop('The lenghts of cols.cols.to.import and col.names should be equal')
  }

  if(any(cols.to.import>6)){
    stop('The maximum possible value in cols.to.import is 6. Thats the number of columns in the excel files.')
  }

  if (!dir.exists(dl.folder)){
    stop(paste('Cant find folder', dl.folder))
  }

  cat('\nReading xls data and saving to data.frame')

  my.f <- list.files(dl.folder, full.names = T)

  if (length(my.f)==0){
    stop(paste('Cant file xlsx files at',dl.folder))
  }


  my.df <- data.frame()
  for (i.f in my.f){

    cat(paste('\n Reading File = ', i.f, sep = ''))

    # Use capture.output so that no message "DEFINEDNAME" is shown
    # Details in: https://github.com/hadley/readxl/issues/82#issuecomment-166767220

    utils::capture.output({
      sheets <- readxl::excel_sheets(i.f)
    })

    for (i.sheet in sheets) {

      cat(paste('\n    Reading Sheet ', i.sheet, sep = ''))

      # Read it with readxl (use capture.output to avoid "DEFINEDNAME:"  issue)
      # see: https://github.com/hadley/readxl/issues/111/
      utils::capture.output({
        temp.df <- readxl::read_excel(path = i.f,
                                      sheet = i.sheet,
                                      skip = 1 )
      })

      # make sure it is a dataframe (readxl has a different format as output)
      temp.df <- as.data.frame(temp.df)

      # control for columns
      if (max(cols.to.import)>ncol(temp.df)){
        stop(paste0('In file ',i.f, ' the number of columns is lower than ',max(cols.to.import),
                    '. Please supply values of cols.to.import that make sense.'))
      }

      # filter columns to import
      temp.df <- temp.df[,cols.to.import]
      n.col <- ncol(temp.df)

      # fix for different format of xls files

      colnames(temp.df) <- col.names
      temp.df[, c(2:n.col)] <- suppressWarnings(data.frame(lapply(X = temp.df[, c(2:n.col)], as.numeric)))

      temp.df <- temp.df[stats::complete.cases(temp.df), ]


      # fix for data in xls (for some files, dates comes in a numeric format and for others as strings)

      if (stringr::str_detect(as.character(temp.df$ref.date[1]),'/')){

        dateVec <- as.Date(as.character(temp.df[ , 1]), format = '%d/%m/%Y')

      } else {

        if (is.numeric(temp.df$ref.date)) {

          dateVec <- as.Date(as.numeric(temp.df$ref.date)-2,  origin="1900-01-01")

        } else {
          dateVec <- as.Date(temp.df$ref.date)
        }

      }

      temp.df$ref.date <- dateVec
      temp.df$asset.code <- i.sheet

      my.df <- rbind(my.df, temp.df)
    }

  }

  my.df <- my.df[stats::complete.cases(my.df), ]

  # fix names (TD website is a mess!!)
  my.df$asset.code <- stringr::str_replace_all(my.df$asset.code,
                                               stringr::fixed('NTNBP'),
                                               'NTN-B Principal')

  my.df$asset.code <- stringr::str_replace_all(my.df$asset.code,
                                               stringr::fixed('NTNF'),
                                               'NTN-F')

  my.df$asset.code <- stringr::str_replace_all(my.df$asset.code,
                                               stringr::fixed('NTNB'),
                                               'NTN-B')

  my.df$asset.code <- stringr::str_replace_all(my.df$asset.code,
                                               stringr::fixed('NTNC'),
                                               'NTN-C')


  # add maturity dates
  my.fct <- function(x){
    x <- substr(x, nchar(x)-5, nchar(x))
    return(as.Date(x,'%d%m%y'))
  }

  # fix names for NTN-B Principal
  my.df$asset.code <- stringr::str_replace_all(my.df$asset.code,
                                               'NTN-B Princ ',
                                               'NTN-B Principal '  )

  my.df$matur.date <- as.Date(sapply(my.df$asset.code, my.fct),
                              origin = '1970-01-01' )

  # clean up zero value prices
  col.classes <- sapply(my.df, class)
  col.classes <- col.classes[col.classes == 'numeric']
  col.to.change <- names(col.classes)

  # remove yield columns
  col.to.change <- col.to.change[!stringr::str_detect(col.to.change, "yield")]
  idx <- apply((as.matrix(my.df[, col.to.change]) == 0 ),
               MARGIN = 1, any)

  my.df <- my.df[!idx, ]

  return(my.df)
}

