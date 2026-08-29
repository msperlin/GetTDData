#' Reads and cleans data from a Tesouro Direto Excel file
#'
#' @param local_file The path to the local Excel file to read.
#'
#' @return A data frame containing the cleaned data.
#'
#' @noRd
read_td_file <- function(local_file) {

  if (stringr::str_ends(local_file, "\\.rds")) {
    return(NULL)
  }

  rds_file <- paste0(local_file, ".rds")
  if (fs::file_exists(rds_file) && fs::file_info(rds_file)$modification_time >= fs::file_info(local_file)$modification_time) {
    cli::cli_alert_success('Reading cached RDS for {basename(local_file)}')
    return(readRDS(rds_file))
  }

  cli::cli_alert_info('Reading {local_file}')

  sheets <- tryCatch(readxl::excel_sheets(local_file), error = function(e) {
    cli::cli_alert_warning("Could not read sheets from {local_file}: {e$message}")
    return(NULL)
  })

  if (is.null(sheets)) return(NULL)

  df_list <- list()
  for (i_sheet in sheets) {

    cli::cli_alert_success('\tReading Sheet {i_sheet}')

    # Read it with readxl (use capture.output to avoid "DEFINEDNAME:" issue)
    temp_df <- tryCatch({
      utils::capture.output({
        res <- readxl::read_excel(path = local_file,
                                  sheet = i_sheet,
                                  skip = 1)
      })
      res
    }, error = function(e) {
      cli::cli_alert_warning("Could not read sheet {i_sheet} from {local_file}")
      return(NULL)
    })

    if (is.null(temp_df)) next

    temp_df <- temp_df |>
      as.data.frame() |>
      clean_td_data()

    temp_df$asset_code <- i_sheet
    df_list[[i_sheet]] <- temp_df
  }

  if (length(df_list) == 0) return(NULL)

  this_df <- dplyr::bind_rows(df_list)
  try(saveRDS(this_df, rds_file), silent = TRUE)
  return(this_df)
}
