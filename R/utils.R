#' Returns the available asset names at the Tesouro Direto (TD) website
#'
#' @param online Logical. If `TRUE`, attempts to query the Tesouro Direto CDN server for live asset names. Defaults to `FALSE`.
#' @return A character vector of names.
#' @export
#'
#' @examples
#' get_td_names()
get_td_names <- function(online = FALSE) {
  possible_names <- c("LFT", "LTN", "NTN-C", "NTN-B", "NTN-B Principal", "NTN-F", "NTN-B1")

  if (online) {
    if (curl::has_internet()) {
      current_year <- format(Sys.Date(), "%Y")
      valid_codes <- c()
      for (code in possible_names) {
        code_str <- stringr::str_replace_all(code, " ", "_")
        test_url <- stringr::str_glue(
          "https://cdn.tesouro.gov.br/sistemas-internos/apex/producao/sistemas/sistd/{current_year}/{code_str}_{current_year}.xls"
        )
        h <- curl::new_handle(nobody = TRUE)
        res <- tryCatch(curl::curl_fetch_memory(test_url, handle = h), error = function(e) NULL)
        if (!is.null(res) && res$status_code == 200) {
          valid_codes <- c(valid_codes, code)
        }
      }
      if (length(valid_codes) > 0) {
        return(valid_codes)
      }
    }
  }

  return(possible_names)
}

#' Returns the cache directory path
#'
#' @param persistent Logical. If `TRUE`, uses a user-persistent directory via `tools::R_user_dir`. If `FALSE`, defaults to session temporary directory. Can also be set globally via `options(GetTDData.persistent_cache = TRUE)`. Defaults to `FALSE`.
#' @return A character string representing the folder path.
#'
#' @export
#'
#' @examples
#' get_cache_folder()
get_cache_folder <- function(persistent = getOption("GetTDData.persistent_cache", FALSE)) {
  if (persistent) {
    cache_dir <- tools::R_user_dir("GetTDData", which = "cache")
  } else {
    cache_dir <- fs::path_temp("td-files")
  }

  if (!dir.exists(cache_dir)) {
    fs::dir_create(cache_dir, recurse = TRUE)
  }

  return(cache_dir)
}

#' Returns metadata and information about Tesouro Direto bond types
#'
#' Provides metadata for Brazilian government bond types, including their official names,
#' indexers (e.g., IPCA, SELIC, Fixed rate), payment frequency, and description.
#'
#' @param asset_codes Optional character vector of asset codes (e.g. 'LTN', 'NTN-B'). If `NULL`, returns info for all assets.
#'
#' @return A tibble with asset metadata.
#' @export
#'
#' @examples
#' get_asset_info()
#' get_asset_info("LTN")
get_asset_info <- function(asset_codes = NULL) {
  df_info <- tibble::tribble(
    ~asset_code, ~name, ~indexer, ~coupon, ~description,
    "LTN", "Tesouro Prefixado", "Prefixado", "Zero Coupon", "Fixed-rate bond paying R$ 1,000 at maturity.",
    "LFT", "Tesouro Selic", "SELIC", "Zero Coupon", "Floating-rate bond indexed to the SELIC overnight interest rate.",
    "NTN-B", "Tesouro IPCA+ com Juros Semestrais", "IPCA", "Semi-annual Coupons", "Inflation-linked bond paying semi-annual coupon interest.",
    "NTN-B Principal", "Tesouro IPCA+", "IPCA", "Zero Coupon", "Inflation-linked bond with principal and inflation adjustment paid at maturity.",
    "NTN-F", "Tesouro Prefixado com Juros Semestrais", "Prefixado", "Semi-annual Coupons", "Fixed-rate bond paying semi-annual coupon interest.",
    "NTN-C", "Tesouro IGP-M com Juros Semestrais", "IGP-M", "Semi-annual Coupons", "Inflation-linked bond indexed to IGP-M (legacy).",
    "NTN-B1", "Tesouro RendA+ / Educa+", "IPCA", "Monthly Amortization", "Inflation-linked retirement or education bond paying monthly income during accumulation/payout.",
    "RendA+", "Tesouro RendA+", "IPCA", "Monthly Amortization", "Inflation-linked retirement bond with monthly payout.",
    "Educa+", "Tesouro Educa+", "IPCA", "Monthly Amortization", "Inflation-linked education bond for tuition funding."
  )

  if (!is.null(asset_codes)) {
    df_info <- df_info |>
      dplyr::filter(.data$asset_code %in% asset_codes)
  }

  return(df_info)
}

#' Cleans raw data from TD
#'
#' @noRd
clean_td_data <- function(temp_df) {

  col_names <-  c('ref_date','yield_bid','price_bid')
  cols_to_import <- c(1, 2, 4)

  temp_df <- temp_df[, cols_to_import]
  n_col <- ncol(temp_df)

  # fix for different format of xls files

  colnames(temp_df) <- col_names
  temp_df[, c(2:n_col)] <- suppressWarnings(
    data.frame(lapply(X = temp_df[, c(2:n_col)], as.numeric))
  )

  temp_df <- temp_df[stats::complete.cases(temp_df), ]


  # fix for data in xls (for some files, dates comes in a numeric format and for others as strings)

  if (stringr::str_detect(as.character(temp_df$ref_date[1]),'/')){

    dateVec <- as.Date(as.character(temp_df[ , 1]), format = '%d/%m/%Y')

  } else {

    if (is.numeric(temp_df$ref_date)) {

      dateVec <- as.Date(as.numeric(temp_df$ref_date)-2,  origin="1900-01-01")

    } else {
      dateVec <- as.Date(temp_df$ref_date)
    }

  }

  temp_df$ref_date <- dateVec

  return(temp_df)

}


#' Returns maturity dates from asset code
#'
#' @noRd
get_matur <- function(x){
  x <- substr(x, nchar(x)-5, nchar(x))
  return(as.Date(x,'%d%m%y'))
}

#' Fixes TD names
#'
#' @noRd
fix_td_names <- function(str_in) {
  # fix names (TD website is a mess!!)
  str_in <- stringr::str_replace_all(str_in,
                                     stringr::fixed('NTNBP'),
                                     'NTN-B Principal')

  str_in <- stringr::str_replace_all(str_in,
                                     stringr::fixed('NTNF'),
                                     'NTN-F')

  str_in <- stringr::str_replace_all(str_in,
                                     stringr::fixed('NTNB'),
                                     'NTN-B')

  str_in <- stringr::str_replace_all(str_in,
                                     stringr::fixed('NTNC'),
                                     'NTN-C')


  # fix names for NTN-B Principal
  str_in <- stringr::str_replace_all(str_in,
                                     'NTN-B Princ ',
                                     'NTN-B Principal '  )

  return(str_in)
}
