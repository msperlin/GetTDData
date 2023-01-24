read_td_file <- function(local_file) {

  cli::cli_alert_info('Reading {local_file}')

  # Use capture.output so that no message "DEFINEDNAME" is shown
  # Details in: https://github.com/hadley/readxl/issues/82#issuecomment-166767220

  #utils::capture.output({
  sheets <- readxl::excel_sheets(local_file)
  #})

  this_df <- tibble::tibble()
  for (i_sheet in sheets) {

    cli::cli_alert_success('\tReading Sheet {i_sheet}')

    # Read it with readxl (use capture.output to avoid "DEFINEDNAME:"  issue)
    # see: https://github.com/hadley/readxl/issues/111/
    utils::capture.output({
      temp_df <- readxl::read_excel(path =local_file,
                                    sheet = i_sheet,
                                    skip = 1 )
    })

    # make sure it is a dataframe (readxl has a different format as output)
    temp_df <- temp_df |>
      as.data.frame() |>
      clean_td_data()

    temp_df$asset_code <- i_sheet

    # filter columns to import


    this_df <- dplyr::bind_rows(this_df, temp_df)
  }

  return(this_df)

}
