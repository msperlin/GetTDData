# MCP tool definitions for GetTDData
#
# This file is sourced by `GetTDData::mcp_tools()` and by the test suite. It
# must evaluate to a named list of `ellmer::tool()` objects.
#
# Results are serialized to JSON because `ellmer::tool()` requires tool results
# to be character or JSON (returning raw data frames is deprecated), and JSON
# keeps the records lossless for the calling model.

local({
  to_json <- function(x) {
    jsonlite::toJSON(
      x,
      dataframe = "rows",
      auto_unbox = TRUE,
      digits = NA,
      na = "null"
    )
  }

  # All GetTDData tools only read remote data; they never modify their
  # environment.
  read_only <- ellmer::tool_annotations(
    read_only_hint = TRUE,
    open_world_hint = TRUE
  )

  # `"all"` is a friendlier way for a model to ask for every asset than an
  # empty array.
  normalize_codes <- function(asset_codes) {
    if (is.null(asset_codes)) {
      return(NULL)
    }
    if (length(asset_codes) == 1L && identical(asset_codes, "all")) {
      return(NULL)
    }
    as.character(asset_codes)
  }

  tool_get_td_data <- ellmer::tool(
    function(asset_codes = "LTN", first_year = 2005, last_year = NULL) {
      if (is.null(last_year)) {
        last_year <- as.numeric(format(Sys.Date(), "%Y"))
      }
      df <- GetTDData::td_get2(
        asset_codes = normalize_codes(asset_codes),
        first_year = as.integer(first_year),
        last_year = as.integer(last_year)
      )
      to_json(df)
    },
    name = "get_td_data",
    description = paste(
      "Download historical prices and yields of Brazilian government bonds",
      "(Tesouro Direto) from the official Tesouro Transparente open data portal.",
      "Returns a JSON array of records with fields: ref_date, yield_bid (annual",
      "rate as a decimal, e.g. 0.1183 means 11.83%), price_bid (unit price in BRL),",
      "asset_code, and matur_date. Restrict first_year/last_year to keep the",
      "response small. Use list_asset_info to discover valid asset codes."
    ),
    arguments = list(
      asset_codes = ellmer::type_array(
        ellmer::type_string(),
        paste0(
          "Bond identifiers, e.g. 'LTN', 'NTN-B', 'LFT', 'NTN-F', ",
          "'NTN-B Principal', 'NTN-C', 'RendA+', 'Educa+'. Use 'all' for every ",
          "asset. Defaults to 'LTN'."
        ),
        required = FALSE
      ),
      first_year = ellmer::type_integer(
        "First year of data (minimum 2005). Defaults to 2005.",
        required = FALSE
      ),
      last_year = ellmer::type_integer(
        "Last year of data. Defaults to the current year.",
        required = FALSE
      )
    ),
    annotations = read_only
  )

  tool_get_td_current <- ellmer::tool(
    function(asset_codes = NULL) {
      df <- GetTDData::td_get_current(
        asset_codes = normalize_codes(asset_codes)
      )
      to_json(df)
    },
    name = "get_td_current",
    description = paste(
      "Get current prices and yields of Brazilian government bonds (Tesouro",
      "Direto). Returns the latest available daily records as a JSON array with",
      "the same fields as get_td_data. Omit asset_codes to return every asset."
    ),
    arguments = list(
      asset_codes = ellmer::type_array(
        ellmer::type_string(),
        paste0(
          "Bond identifiers, e.g. 'LTN', 'NTN-B', 'LFT'. Use 'all' or omit to ",
          "return every asset."
        ),
        required = FALSE
      )
    ),
    annotations = read_only
  )

  tool_get_yield_curve <- ellmer::tool(
    function() {
      to_json(GetTDData::get_yield_curve())
    },
    name = "get_yield_curve",
    description = paste(
      "Download the current Brazilian (Anbima) yield curve. Returns a JSON array",
      "of records with fields ref_date, value, type, and current_date. The yield",
      "curve summarizes how the market perceives future real, nominal, and",
      "inflation returns."
    ),
    arguments = list(),
    annotations = read_only
  )

  tool_list_asset_info <- ellmer::tool(
    function(asset_codes = NULL) {
      to_json(GetTDData::get_asset_info(asset_codes = normalize_codes(asset_codes)))
    },
    name = "list_asset_info",
    description = paste(
      "Return metadata for Brazilian government bond types: official name,",
      "indexer (e.g. IPCA, SELIC, Prefixado), coupon type, and description.",
      "Returns a JSON array. Omit asset_codes for every bond type."
    ),
    arguments = list(
      asset_codes = ellmer::type_array(
        ellmer::type_string(),
        "Optional bond identifiers to filter, e.g. 'LTN', 'NTN-B'. Omit for all.",
        required = FALSE
      )
    ),
    annotations = read_only
  )

  tool_list_asset_names <- ellmer::tool(
    function(online = FALSE) {
      to_json(GetTDData::get_td_names(online = online))
    },
    name = "list_asset_names",
    description = paste(
      "Return the available Tesouro Direto asset names as a JSON array of strings.",
      "Set online = TRUE to query the live CDN server (slower, needs internet)."
    ),
    arguments = list(
      online = ellmer::type_boolean(
        "If TRUE, query the live Tesouro Direto server for the currently available names. Defaults to FALSE.",
        required = FALSE
      )
    ),
    annotations = read_only
  )

  list(
    get_td_data = tool_get_td_data,
    get_td_current = tool_get_td_current,
    get_yield_curve = tool_get_yield_curve,
    list_asset_info = tool_list_asset_info,
    list_asset_names = tool_list_asset_names
  )
})
