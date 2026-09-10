#' Downloads data for Brazilian government bonds from Tesouro Transparente (CKAN)
#'
#' This function downloads historical prices and yields of Brazilian government bonds
#' directly from the Tesouro Transparente CKAN open data portal
#' (<https://www.tesourotransparente.gov.br/ckan/dataset/taxas-dos-titulos-ofertados-pelo-tesouro-direto/>).
#' It serves as the modern replacement for \code{\link{td_get}}, which relied on the
#' legacy Tesouro Direto application shut down in August 2026.
#'
#' @param asset_codes A character vector identifying the assets to download (e.g., 'LTN',
#'   'NTN-B', 'LFT', 'NTN-B Principal', 'NTN-F', 'NTN-C', 'NTN-B1', 'Educa+', 'RendA+').
#'   You can also pass official names such as 'Tesouro Prefixado', 'Tesouro Selic', etc.
#'   If `NULL`, downloads all available assets. Defaults to 'LTN'.
#' @param first_year The first year of data (minimum of 2005). Defaults to 2005.
#' @param last_year The last year of data. Defaults to the current year.
#' @param dl_folder Path of the folder to save data files from Tesouro Transparente.
#'   Defaults to \code{\link{get_cache_folder}()}.
#' @param force_download Logical. If `TRUE`, forces redownloading the data even if
#'   a cached version from today is present. Defaults to `FALSE`.
#' @param dataset_url The URL to the CKAN dataset page or direct CSV file. Defaults to
#'   "https://www.tesourotransparente.gov.br/ckan/dataset/taxas-dos-titulos-ofertados-pelo-tesouro-direto/".
#'
#' @return A \code{tibble} (data frame) containing the asset data:
#' \describe{
#'   \item{ref_date}{Reference date (Date)}
#'   \item{yield_bid}{Annual purchase yield / rate in decimal format (numeric, e.g. 0.1183 for 11.83\%)}
#'   \item{price_bid}{Unit purchase price in BRL (numeric)}
#'   \item{asset_code}{Standard bond identifier (character, e.g. 'LTN 010123')}
#'   \item{matur_date}{Maturity date of the bond (Date)}
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' df_td <- td_get2("LTN", 2020, 2022)
#' head(df_td)
#' }
td_get2 <- function(asset_codes = "LTN",
                    first_year = 2005,
                    last_year = as.numeric(format(Sys.Date(), "%Y")),
                    dl_folder = get_cache_folder(),
                    force_download = FALSE,
                    dataset_url = get_default_ckan_url()) {

  # check years
  if (first_year < 2005) {
    warning("First year of TD data is 2005. Fixing input first_year to 2005.")
    first_year <- 2005
  }

  if (first_year > last_year) {
    cli::cli_abort("Input `first_year` ({first_year}) cannot be greater than `last_year` ({last_year}).")
  }

  # validate asset codes
  valid_codes <- c(
    "LTN", "LFT", "NTN-B", "NTN-B Principal", "NTN-B Princip", "NTNBP",
    "NTN-F", "NTNF", "NTN-C", "NTNC", "NTN-B1", "Educa+", "RendA+", "Renda+",
    "Tesouro Prefixado", "Tesouro Selic", "Tesouro IPCA+",
    "Tesouro IPCA+ com Juros Semestrais", "Tesouro Prefixado com Juros Semestrais",
    "Tesouro IGPM+ com Juros Semestrais", "Tesouro IGP-M com Juros Semestrais",
    "Tesouro Renda+ Aposentadoria Extra", "Tesouro RendA+",
    "Tesouro Educa+", "Tesouro RendA+ / Educa+"
  )

  if (!is.null(asset_codes)) {
    invalid_codes <- asset_codes[!asset_codes %in% valid_codes]
    if (length(invalid_codes) > 0) {
      cli::cli_abort(paste0(
        "Input asset_codes not valid: {paste(invalid_codes, collapse = ', ')}. ",
        "Valid codes include: {paste(get_td_names(), collapse = ', ')}"
      ))
    }
  }

  # ensure dl_folder exists
  if (!dir.exists(dl_folder)) {
    fs::dir_create(dl_folder, recurse = TRUE)
  }

  local_csv <- fs::path(dl_folder, "precotaxatesourodireto.csv")
  local_rds <- fs::path(dl_folder, "precotaxatesourodireto.rds")

  # check if we can read from today's cache
  can_use_cache <- FALSE
  if (!force_download) {
    if (fs::file_exists(local_rds)) {
      rds_mtime <- as.Date(fs::file_info(local_rds)$modification_time)
      if (rds_mtime >= Sys.Date()) {
        can_use_cache <- TRUE
      }
    } else if (fs::file_exists(local_csv)) {
      csv_mtime <- as.Date(fs::file_info(local_csv)$modification_time)
      if (csv_mtime >= Sys.Date()) {
        can_use_cache <- TRUE
      }
    }
  }

  # if cannot use cache, download or update
  if (!can_use_cache) {
    # Check if dataset_url is a local file
    if (fs::file_exists(dataset_url)) {
      if (!identical(fs::path_abs(dataset_url), fs::path_abs(local_csv))) {
        fs::file_copy(dataset_url, local_csv, overwrite = TRUE)
      }
      if (fs::file_exists(local_rds)) {
        try(fs::file_delete(local_rds), silent = TRUE)
      }
    } else {
      has_net <- curl::has_internet()

      # if no internet but cached file exists, fall back to cache
      if (!has_net) {
        if (fs::file_exists(local_rds) || fs::file_exists(local_csv)) {
          cli::cli_alert_warning("No internet connection found. Using existing cached TD data.")
        } else {
          stop("No internet connection found...")
        }
      } else {
        # resolve CSV URL from CKAN dataset page
        csv_url <- get_ckan_csv_url(dataset_url)

        cli::cli_h3("Downloading TD data from Tesouro Transparente CKAN")
        dl_success <- tryCatch({
          curl::curl_download(csv_url, destfile = local_csv, quiet = TRUE)
          TRUE
        }, error = function(e) {
          cli::cli_alert_warning("Failed to download TD file from {csv_url}: {e$message}")
          FALSE
        })

        if (!dl_success) {
          if (fs::file_exists(local_rds) || fs::file_exists(local_csv)) {
            cli::cli_alert_warning("Using previously cached TD data.")
          } else {
            cli::cli_abort("Failed to download data and no cached file was found.")
          }
        } else {
          # remove old rds cache so it gets regenerated
          if (fs::file_exists(local_rds)) {
            try(fs::file_delete(local_rds), silent = TRUE)
          }
        }
      }
    }
  }

  # read data
  cli::cli_h3("Reading TD data")
  df_full <- NULL

  if (fs::file_exists(local_rds) && !force_download) {
    df_full <- tryCatch(readRDS(local_rds), error = function(e) NULL)
  }

  if (is.null(df_full) || !is.data.frame(df_full)) {
    if (!fs::file_exists(local_csv)) {
      cli::cli_abort("Cannot find data file at {local_csv}")
    }

    df_raw <- utils::read.csv2(local_csv, stringsAsFactors = FALSE, check.names = FALSE)
    names(df_raw) <- tolower(gsub("[ ._]+", "_", names(df_raw)))

    ref_date <- as.Date(df_raw$data_base, format = "%d/%m/%Y")
    matur_date <- as.Date(df_raw$data_vencimento, format = "%d/%m/%Y")
    yield_bid <- suppressWarnings(as.numeric(df_raw$taxa_compra_manha)) / 100
    price_bid <- suppressWarnings(as.numeric(df_raw$pu_compra_manha))

    bond_map <- c(
      "Tesouro Prefixado" = "LTN",
      "Tesouro Selic" = "LFT",
      "Tesouro IPCA+ com Juros Semestrais" = "NTN-B",
      "Tesouro IPCA+" = "NTN-B Principal",
      "Tesouro Prefixado com Juros Semestrais" = "NTN-F",
      "Tesouro IGPM+ com Juros Semestrais" = "NTN-C",
      "Tesouro IGP-M com Juros Semestrais" = "NTN-C",
      "Tesouro Educa+" = "NTN-B1",
      "Tesouro Renda+ Aposentadoria Extra" = "NTN-B1"
    )

    bond_symbol <- unname(bond_map[df_raw$tipo_titulo])
    bond_symbol[is.na(bond_symbol)] <- df_raw$tipo_titulo[is.na(bond_symbol)]
    asset_code <- paste0(bond_symbol, " ", format(matur_date, "%d%m%y"))

    df_full <- tibble::tibble(
      ref_date = ref_date,
      yield_bid = yield_bid,
      price_bid = price_bid,
      asset_code = asset_code,
      matur_date = matur_date,
      tipo_titulo = df_raw$tipo_titulo
    )

    # filter complete cases and positive prices
    df_full <- df_full[stats::complete.cases(
      df_full$ref_date,
      df_full$yield_bid,
      df_full$price_bid,
      df_full$asset_code,
      df_full$matur_date
    ), ]
    df_full <- df_full[df_full$price_bid > 0, ]

    # cache as RDS
    try(saveRDS(df_full, local_rds), silent = TRUE)
  }

  # filter by asset_codes
  if (!is.null(asset_codes)) {
    keep <- rep(FALSE, nrow(df_full))
    for (code in asset_codes) {
      if (code %in% c("LTN", "Tesouro Prefixado")) {
        keep <- keep | (df_full$tipo_titulo == "Tesouro Prefixado")
      } else if (code %in% c("LFT", "Tesouro Selic")) {
        keep <- keep | (df_full$tipo_titulo == "Tesouro Selic")
      } else if (code %in% c("NTN-B", "Tesouro IPCA+ com Juros Semestrais")) {
        keep <- keep | (df_full$tipo_titulo == "Tesouro IPCA+ com Juros Semestrais")
      } else if (code %in% c("NTN-B Principal", "NTN-B Princip", "NTNBP", "Tesouro IPCA+")) {
        keep <- keep | (df_full$tipo_titulo == "Tesouro IPCA+")
      } else if (code %in% c("NTN-F", "NTNF", "Tesouro Prefixado com Juros Semestrais")) {
        keep <- keep | (df_full$tipo_titulo == "Tesouro Prefixado com Juros Semestrais")
      } else if (code %in% c("NTN-C", "NTNC", "Tesouro IGPM+ com Juros Semestrais", "Tesouro IGP-M com Juros Semestrais")) {
        keep <- keep | (df_full$tipo_titulo %in% c("Tesouro IGPM+ com Juros Semestrais", "Tesouro IGP-M com Juros Semestrais"))
      } else if (code %in% c("NTN-B1", "Tesouro RendA+ / Educa+")) {
        keep <- keep | (df_full$tipo_titulo %in% c("Tesouro Educa+", "Tesouro Renda+ Aposentadoria Extra"))
      } else if (code %in% c("Educa+", "Tesouro Educa+")) {
        keep <- keep | (df_full$tipo_titulo == "Tesouro Educa+")
      } else if (code %in% c("RendA+", "Renda+", "Tesouro Renda+ Aposentadoria Extra", "Tesouro RendA+")) {
        keep <- keep | (df_full$tipo_titulo == "Tesouro Renda+ Aposentadoria Extra")
      } else {
        keep <- keep | stringr::str_starts(df_full$asset_code, stringr::fixed(paste0(code, " ")))
      }
    }
    df_full <- df_full[keep, ]
  }

  # filter by date range
  start_date <- as.Date(paste0(first_year, "-01-01"))
  end_date <- as.Date(paste0(last_year, "-12-31"))

  df_filtered <- df_full[df_full$ref_date >= start_date & df_full$ref_date <= end_date, ]

  # sort by asset_code and ref_date
  df_filtered <- df_filtered[order(df_filtered$asset_code, df_filtered$ref_date), ]

  # select final columns matching td_get() exactly
  df_out <- df_filtered[, c("ref_date", "yield_bid", "price_bid", "asset_code", "matur_date")]

  cli::cli_alert_success("Retrieved {nrow(df_out)} rows of TD data.")

  return(tibble::as_tibble(df_out))
}

#' Resolves the CSV download URL from a Tesouro Transparente CKAN page
#'
#' @param dataset_url A URL to the CKAN dataset page or a direct CSV link.
#'
#' @return A character string containing the CSV download URL.
#' @noRd
get_ckan_csv_url <- function(dataset_url) {
  if (fs::file_exists(dataset_url)) {
    return(dataset_url)
  }

  if (stringr::str_ends(tolower(dataset_url), "\\.csv")) {
    return(dataset_url)
  }

  csv_url <- NULL

  # 1. Scrape HTML page with rvest
  tryCatch({
    page <- rvest::read_html(dataset_url)
    links <- rvest::html_attr(rvest::html_elements(page, "a"), "href")
    csv_links <- grep("\\.csv$", links, value = TRUE)
    if (length(csv_links) > 0) {
      csv_url <- xml2::url_absolute(csv_links[1], dataset_url)
    }
  }, error = function(e) NULL)

  if (!is.null(csv_url)) return(csv_url)

  # 2. Try CKAN API
  tryCatch({
    clean_url <- sub("/+$", "", dataset_url)
    pkg_name <- basename(clean_url)
    api_url <- paste0(
      "https://www.tesourotransparente.gov.br/ckan/api/3/action/package_show?id=",
      pkg_name
    )
    res <- curl::curl_fetch_memory(api_url)
    if (res$status_code == 200) {
      m <- stringr::str_match(rawToChar(res$content), "\"url\"\\s*:\\s*\"([^\"]+\\.csv)\"")
      if (!is.na(m[1, 2])) {
        csv_url <- m[1, 2]
      }
    }
  }, error = function(e) NULL)

  if (!is.null(csv_url)) return(csv_url)

  # 3. Known fallback URL
  fallback_url <- "https://www.tesourotransparente.gov.br/ckan/dataset/df56aa42-484a-4a59-8184-7676580c81e3/resource/796d2059-14e9-44e3-80c9-2d9e30b405c1/download/precotaxatesourodireto.csv"
  return(fallback_url)
}

#' Returns the default CKAN dataset URL
#'
#' @return A character string URL.
#' @noRd
get_default_ckan_url <- function() {
  "https://www.tesourotransparente.gov.br/ckan/dataset/taxas-dos-titulos-ofertados-pelo-tesouro-direto/"
}

