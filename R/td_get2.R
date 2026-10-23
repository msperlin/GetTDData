#' Downloads data for Brazilian government bonds from Tesouro Transparente (CKAN)
#'
#' This function downloads historical prices and yields of Brazilian government bonds
#' directly from the Tesouro Transparente CKAN open data portal
#' (<https://www.tesourotransparente.gov.br/ckan/dataset/taxas-dos-titulos-ofertados-pelo-tesouro-direto/>).
#' It serves as the modern replacement for \code{\link{td_get}}, which relied on the
#' legacy Tesouro Direto application shut down in August 2026.
#'
#' @details
#' The downloaded file is validated before it replaces any cached copy: error
#' pages and incomplete downloads are rejected instead of being silently parsed
#' as an empty data set. Parsed data is cached in \code{dl_folder} as an RDS
#' file for the rest of the day. The cache is only reused when it was produced
#' from the same \code{dataset_url}.
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
#'   a cached version from today is present. If the download fails, the existing
#'   cache is used as a fallback. Defaults to `FALSE`.
#' @param dataset_url The URL to the CKAN dataset page, a direct CSV file link, or
#'   the path to a local CSV file with the same layout. Defaults to
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
  first_year <- check_year_input(first_year, "first_year")
  last_year <- check_year_input(last_year, "last_year")

  if (first_year < 2005) {
    warning("First year of TD data is 2005. Fixing input first_year to 2005.")
    first_year <- 2005
  }

  if (first_year > last_year) {
    cli::cli_abort("Input `first_year` ({first_year}) cannot be greater than `last_year` ({last_year}).")
  }

  # validate asset codes
  code_map <- td_code_to_group()

  if (!is.null(asset_codes)) {
    invalid_codes <- setdiff(asset_codes, names(code_map))
    if (length(invalid_codes) > 0) {
      cli::cli_abort(
        "Input asset_codes not valid: {.val {invalid_codes}}. Valid codes include: {.val {names(code_map)}}."
      )
    }
  }

  # ensure dl_folder exists
  if (!dir.exists(dl_folder)) {
    fs::dir_create(dl_folder, recurse = TRUE)
  }

  local_csv <- fs::path(dl_folder, "precotaxatesourodireto.csv")
  local_rds <- fs::path(dl_folder, "precotaxatesourodireto.rds")

  # identify the data source so that a cache built from a different source is
  # never reused silently
  source_id <- normalize_td_source(dataset_url)

  cache <- read_td_cache(local_rds)
  cache_is_usable <- !is.null(cache) &&
    identical(cache$meta$version, .td_cache_version) &&
    identical(cache$meta$source, source_id) &&
    cache$mtime >= Sys.Date()

  df_full <- NULL

  if (!force_download && cache_is_usable) {
    cli::cli_h3("Reading TD data")
    df_full <- cache$data
  }

  if (is.null(df_full)) {
    # reuse an already validated CSV from today instead of downloading it again
    csv_is_usable <- FALSE
    if (!force_download && fs::file_exists(local_csv)) {
      csv_mtime <- as.Date(fs::file_info(local_csv)$modification_time)
      same_source <- is.null(cache) || is.null(cache$meta) ||
        identical(cache$meta$source, source_id)
      csv_is_usable <- csv_mtime >= Sys.Date() && same_source && is_valid_td_csv(local_csv)
    }

    if (!csv_is_usable) {
      fetched <- fetch_td_csv(dataset_url, local_csv)

      if (!fetched) {
        # if the refresh failed, fall back to any previously parsed data
        if (!is.null(cache)) {
          cli::cli_alert_warning("Using previously cached TD data (could not refresh it).")
          df_full <- cache$data
        } else {
          cli::cli_abort("Failed to download data and no cached file was found.")
        }
      }
    }
  }

  if (is.null(df_full)) {
    cli::cli_h3("Reading TD data")
    df_full <- parse_td_csv(local_csv, source_id = source_id)

    # cache as RDS (keeps the source/version metadata used for validation)
    save_ok <- tryCatch({
      saveRDS(df_full, local_rds)
      TRUE
    }, error = function(e) FALSE)

    if (!save_ok) {
      cli::cli_alert_warning("Could not write the cache file at {.file {local_rds}}.")
    }
  }

  # filter by asset_codes
  if (!is.null(asset_codes)) {
    title_groups <- td_title_groups()
    keep <- rep(FALSE, nrow(df_full))

    for (code in asset_codes) {
      titles <- title_groups[[code_map[[code]]]]
      keep <- keep | (df_full$tipo_titulo %in% titles)
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

  # drop cache metadata and row names from the returned object
  attr(df_out, ".GetTDData_meta") <- NULL
  rownames(df_out) <- NULL

  if (nrow(df_out) == 0) {
    cli::cli_alert_warning("No TD data found for the requested assets and years.")
  } else {
    cli::cli_alert_success("Retrieved {nrow(df_out)} rows of TD data.")
  }

  return(tibble::as_tibble(df_out))
}

# Internal constants and helpers -------------------------------------------------

# version tag stored with the parsed cache; bump it whenever the layout or the
# parsing rules change so that older caches are rebuilt
.td_cache_version <- 3L

#' Returns the internal group name of each accepted asset code
#'
#' Every accepted `asset_codes` value (short code or official name) is mapped to
#' a group of `tipo_titulo` values in the raw data. Defining the accepted codes
#' and the filtering rules in a single place avoids the two lists drifting apart.
#'
#' @return A named character vector (code -> group).
#' @noRd
td_code_to_group <- function() {
  c(
    "LTN" = "prefixado",
    "Tesouro Prefixado" = "prefixado",
    "LFT" = "selic",
    "Tesouro Selic" = "selic",
    "NTN-B" = "ipca_coupon",
    "Tesouro IPCA+ com Juros Semestrais" = "ipca_coupon",
    "NTN-B Principal" = "ipca_principal",
    "NTN-B Princip" = "ipca_principal",
    "NTNBP" = "ipca_principal",
    "Tesouro IPCA+" = "ipca_principal",
    "NTN-F" = "prefixado_coupon",
    "NTNF" = "prefixado_coupon",
    "Tesouro Prefixado com Juros Semestrais" = "prefixado_coupon",
    "NTN-C" = "igpm_coupon",
    "NTNC" = "igpm_coupon",
    "Tesouro IGPM+ com Juros Semestrais" = "igpm_coupon",
    "Tesouro IGP-M com Juros Semestrais" = "igpm_coupon",
    "NTN-B1" = "renda_educa",
    "Tesouro RendA+ / Educa+" = "renda_educa",
    "Educa+" = "educa",
    "Tesouro Educa+" = "educa",
    "RendA+" = "renda",
    "Renda+" = "renda",
    "Tesouro Renda+ Aposentadoria Extra" = "renda",
    "Tesouro RendA+" = "renda"
  )
}

#' Returns the `tipo_titulo` values of each asset group
#'
#' @return A named list of character vectors.
#' @noRd
td_title_groups <- function() {
  list(
    prefixado = "Tesouro Prefixado",
    selic = "Tesouro Selic",
    ipca_coupon = "Tesouro IPCA+ com Juros Semestrais",
    ipca_principal = "Tesouro IPCA+",
    prefixado_coupon = "Tesouro Prefixado com Juros Semestrais",
    igpm_coupon = c("Tesouro IGPM+ com Juros Semestrais", "Tesouro IGP-M com Juros Semestrais"),
    renda_educa = c("Tesouro Educa+", "Tesouro Renda+ Aposentadoria Extra"),
    educa = "Tesouro Educa+",
    renda = "Tesouro Renda+ Aposentadoria Extra"
  )
}

#' Validates a year input
#'
#' @param x The value to validate.
#' @param arg The argument name, used in the error message.
#'
#' @return A single integer.
#' @noRd
check_year_input <- function(x, arg) {
  if (length(x) != 1 || is.na(x)) {
    cli::cli_abort("Input `{arg}` must be a single whole number (year).")
  }

  x_num <- suppressWarnings(as.numeric(x))

  if (is.na(x_num) || x_num != round(x_num)) {
    cli::cli_abort("Input `{arg}` must be a single whole number (year).")
  }

  as.integer(x_num)
}

#' Normalizes the data source identifier used in the cache metadata
#'
#' @param x A URL or a local file path.
#'
#' @return A character string.
#' @noRd
normalize_td_source <- function(x) {
  x <- trimws(x)

  if (stringr::str_detect(tolower(x), "^https?://")) {
    return(x)
  }

  as.character(fs::path_abs(x))
}

#' Checks whether a file looks like a Tesouro Transparente CSV
#'
#' This guards against HTML error pages, rate-limit responses and truncated
#' downloads being treated as valid data.
#'
#' @param path Path to the CSV file.
#'
#' @return A single logical.
#' @noRd
is_valid_td_csv <- function(path) {
  if (!fs::file_exists(path)) return(FALSE)
  if (is.na(fs::file_size(path)) || fs::file_size(path) < 100) return(FALSE)

  header <- tryCatch(
    readLines(path, n = 1, warn = FALSE),
    error = function(e) character()
  )

  if (length(header) == 0) return(FALSE)

  header <- sub("^\ufeff", "", header)
  cols <- tolower(gsub("[ ._]+", "_", trimws(strsplit(header, ";", fixed = TRUE)[[1]])))

  required <- c(
    "tipo_titulo", "data_base", "data_vencimento",
    "taxa_compra_manha", "pu_compra_manha"
  )

  all(required %in% cols)
}

#' Checks whether the package can reach the internet
#'
#' A thin wrapper so that tests can mock network availability.
#'
#' @return A single logical.
#' @noRd
td_has_internet <- function() {
  curl::has_internet()
}

#' Reads the parsed data cache
#'
#' @param path Path to the RDS cache file.
#'
#' @return `NULL` if the file is missing/unreadable/empty, otherwise a list with
#'   elements `data` (the cached data frame), `meta` (the source/version
#'   metadata) and `mtime` (the cache date).
#' @noRd
read_td_cache <- function(path) {
  if (!fs::file_exists(path)) return(NULL)

  cache_data <- tryCatch(readRDS(path), error = function(e) NULL)

  if (!is.data.frame(cache_data) || nrow(cache_data) == 0) return(NULL)

  meta <- attr(cache_data, ".GetTDData_meta")
  attr(cache_data, ".GetTDData_meta") <- NULL

  list(
    data = cache_data,
    meta = meta,
    mtime = as.Date(fs::file_info(path)$modification_time)
  )
}

#' Obtains a validated TD CSV file
#'
#' Downloads (or copies, for local sources) the raw CSV file, validating it
#' before it replaces any previously cached copy. Network downloads are retried
#' a few times before giving up.
#'
#' @param dataset_url The data source (CKAN page, direct CSV URL or local file).
#' @param local_csv Destination path of the CSV file.
#'
#' @return `TRUE` (invisibly) on success, `FALSE` if the data could not be
#'   obtained (for example, when there is no internet connection).
#' @noRd
fetch_td_csv <- function(dataset_url, local_csv) {
  # local file: validate before copying
  if (fs::file_exists(dataset_url)) {
    if (!is_valid_td_csv(dataset_url)) {
      cli::cli_abort(c(
        "Local file {.file {dataset_url}} is not a valid Tesouro Direto data file.",
        "i" = "Expected a semicolon-separated CSV with columns such as 'Tipo Titulo', 'Data Base', 'Taxa Compra Manha' and 'PU Compra Manha'."
      ))
    }

    if (!identical(fs::path_abs(dataset_url), fs::path_abs(local_csv))) {
      fs::file_copy(dataset_url, local_csv, overwrite = TRUE)
    }

    return(invisible(TRUE))
  }

  if (!td_has_internet()) {
    cli::cli_alert_warning("No internet connection found.")
    return(invisible(FALSE))
  }

  csv_url <- get_ckan_csv_url(dataset_url)

  cli::cli_h3("Downloading TD data from Tesouro Transparente CKAN")

  # download to a temporary file so a failed transfer never corrupts the cache
  tmp_file <- paste0(local_csv, ".download")
  on.exit(unlink(tmp_file), add = TRUE)

  max_tries <- 3L
  download_error <- NULL

  for (i_try in seq_len(max_tries)) {
    ok <- tryCatch({
      curl::curl_download(
        url = csv_url,
        destfile = tmp_file,
        quiet = TRUE,
        handle = curl::new_handle(
          useragent = "GetTDData R package (https://github.com/msperlin/GetTDData)"
        )
      )
      TRUE
    }, error = function(e) {
      download_error <<- conditionMessage(e)
      FALSE
    })

    if (ok && is_valid_td_csv(tmp_file)) {
      fs::file_copy(tmp_file, local_csv, overwrite = TRUE)
      return(invisible(TRUE))
    }

    if (ok) {
      cli::cli_alert_warning(
        "The downloaded file is not a valid TD data file (attempt {i_try}/{max_tries})."
      )
    } else {
      cli::cli_alert_warning(
        "Failed to download TD data (attempt {i_try}/{max_tries}): {download_error}"
      )
    }

    if (i_try < max_tries) Sys.sleep(i_try)
  }

  cli::cli_alert_warning("Failed to download TD data from {.url {csv_url}}.")

  invisible(FALSE)
}

#' Parses the Tesouro Transparente CSV file
#'
#' @param csv_path Path to the raw CSV file.
#' @param source_id The data source identifier, stored in the cache metadata.
#'
#' @return A tibble with the parsed data and the cache metadata attribute.
#' @noRd
parse_td_csv <- function(csv_path, source_id) {
  if (!is_valid_td_csv(csv_path)) {
    cli::cli_abort(c(
      "The TD data file at {.file {csv_path}} is not a valid Tesouro Direto data file.",
      "i" = "It may be an HTML error page or an incomplete download. Try `force_download = TRUE` or delete the file."
    ))
  }

  df_raw <- utils::read.csv2(csv_path, stringsAsFactors = FALSE, check.names = FALSE)
  names(df_raw)[1] <- sub("^\ufeff", "", names(df_raw)[1])
  names(df_raw) <- tolower(gsub("[ ._]+", "_", names(df_raw)))

  required_cols <- c(
    "tipo_titulo", "data_base", "data_vencimento",
    "taxa_compra_manha", "pu_compra_manha"
  )
  missing_cols <- setdiff(required_cols, names(df_raw))

  if (length(missing_cols) > 0) {
    cli::cli_abort("Missing required columns in {.file {csv_path}}: {.val {missing_cols}}.")
  }

  ref_date <- as.Date(df_raw$data_base, format = "%d/%m/%Y")
  matur_date <- as.Date(df_raw$data_vencimento, format = "%d/%m/%Y")
  yield_bid <- suppressWarnings(as.numeric(df_raw$taxa_compra_manha)) / 100
  price_bid <- suppressWarnings(as.numeric(df_raw$pu_compra_manha))
  tipo_titulo <- trimws(df_raw$tipo_titulo)

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

  bond_symbol <- unname(bond_map[tipo_titulo])
  bond_symbol[is.na(bond_symbol)] <- tipo_titulo[is.na(bond_symbol)]
  asset_code <- paste0(bond_symbol, " ", format(matur_date, "%d%m%y"))

  df_full <- tibble::tibble(
    ref_date = ref_date,
    yield_bid = yield_bid,
    price_bid = price_bid,
    asset_code = asset_code,
    matur_date = matur_date,
    tipo_titulo = tipo_titulo
  )

  # filter invalid rows (unparseable dates/numbers and zero prices)
  keep <- stats::complete.cases(
    df_full$ref_date,
    df_full$yield_bid,
    df_full$price_bid,
    df_full$matur_date
  ) &
    nzchar(df_full$tipo_titulo) &
    df_full$price_bid > 0

  df_full <- df_full[keep, ]

  if (nrow(df_full) == 0) {
    cli::cli_abort(c(
      "No valid rows found in {.file {csv_path}}.",
      "i" = "The file may be corrupted or in an unexpected format."
    ))
  }

  attr(df_full, ".GetTDData_meta") <- list(
    version = .td_cache_version,
    source = source_id,
    created_at = Sys.time()
  )

  df_full
}

#' Resolves the CSV download URL from a Tesouro Transparente CKAN page
#'
#' @param dataset_url A URL to the CKAN dataset page or a direct CSV link.
#'
#' @return A character string containing the CSV download URL.
#' @noRd
get_ckan_csv_url <- function(dataset_url) {
  dataset_url <- trimws(dataset_url)

  if (fs::file_exists(dataset_url)) {
    return(dataset_url)
  }

  if (stringr::str_detect(tolower(dataset_url), "\\.csv($|[?#])")) {
    return(dataset_url)
  }

  is_url <- stringr::str_detect(tolower(dataset_url), "^https?://")
  is_ckan <- stringr::str_detect(tolower(dataset_url), "tesourotransparente\\.gov\\.br")

  if (!is_url) {
    cli::cli_abort(c(
      "Cannot use {.val {dataset_url}} as a data source.",
      "i" = "It is neither an existing local file nor an HTTP(S) URL."
    ))
  }

  csv_url <- NULL

  # 1. Scrape HTML page with rvest
  tryCatch({
    page <- rvest::read_html(dataset_url)
    links <- rvest::html_attr(rvest::html_elements(page, "a"), "href")
    csv_links <- links[!is.na(links) & grepl("\\.csv($|[?#])", links, ignore.case = TRUE)]

    if (length(csv_links) > 0) {
      # prefer the official price file when the page offers several resources
      idx <- grep("precotaxatesourodireto\\.csv", csv_links, ignore.case = TRUE)
      picked <- if (length(idx) > 0) csv_links[idx[1]] else csv_links[1]
      csv_url <- xml2::url_absolute(picked, dataset_url)
    }
  }, error = function(e) NULL)

  if (!is.null(csv_url)) return(csv_url)

  # 2. Try CKAN API (only for the Tesouro Transparente portal)
  if (is_ckan) {
    tryCatch({
      pkg_name <- basename(sub("/+$", "", dataset_url))
      api_url <- paste0(
        "https://www.tesourotransparente.gov.br/ckan/api/3/action/package_show?id=",
        pkg_name
      )
      res <- curl::curl_fetch_memory(api_url)

      if (res$status_code == 200) {
        matches <- stringr::str_match_all(
          rawToChar(res$content),
          "\"url\"\\s*:\\s*\"([^\"]+\\.csv)\""
        )[[1]]

        if (nrow(matches) > 0) {
          urls <- matches[, 2]
          idx <- grep("precotaxatesourodireto\\.csv", urls, ignore.case = TRUE)
          csv_url <- if (length(idx) > 0) urls[idx[1]] else urls[1]
        }
      }
    }, error = function(e) NULL)
  }

  if (!is.null(csv_url)) return(csv_url)

  # 3. Known fallback URL (only makes sense for the Tesouro Transparente portal)
  if (is_ckan) {
    cli::cli_alert_warning(
      "Could not resolve the CSV link from {.url {dataset_url}}. Falling back to the default Tesouro Transparente URL."
    )
    return(get_default_ckan_csv_url())
  }

  cli::cli_abort(
    "Could not resolve a CSV download link from {.val {dataset_url}}. Please provide a direct CSV URL or the CKAN dataset page."
  )
}

#' Returns the default CKAN dataset URL
#'
#' @return A character string URL.
#' @noRd
get_default_ckan_url <- function() {
  "https://www.tesourotransparente.gov.br/ckan/dataset/taxas-dos-titulos-ofertados-pelo-tesouro-direto/"
}

#' Returns the default CKAN CSV URL
#'
#' @return A character string URL.
#' @noRd
get_default_ckan_csv_url <- function() {
  "https://www.tesourotransparente.gov.br/ckan/dataset/df56aa42-484a-4a59-8184-7676580c81e3/resource/796d2059-14e9-44e3-80c9-2d9e30b405c1/download/precotaxatesourodireto.csv"
}
