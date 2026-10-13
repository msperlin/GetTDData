test_that("mcp_tools() returns the expected tool set", {
  skip_if_not_installed("ellmer")
  skip_if_not_installed("jsonlite")

  tools <- GetTDData::mcp_tools()

  expect_type(tools, "list")
  expect_setequal(
    names(tools),
    c("get_td_data", "get_td_current", "get_yield_curve", "list_asset_info", "list_asset_names")
  )
})

test_that("list_asset_info tool returns valid JSON without network access", {
  skip_if_not_installed("ellmer")
  skip_if_not_installed("jsonlite")

  tools <- GetTDData::mcp_tools()
  out <- tools$list_asset_info(asset_codes = "LTN")

  expect_type(out, "character")
  expect_true(jsonlite::validate(out))

  parsed <- jsonlite::fromJSON(out)
  expect_true("LTN" %in% parsed$asset_code)
})

test_that("mcp_server() is exported and accepts the documented arguments", {
  expect_true(is.function(GetTDData::mcp_server))
  expect_true(all(c("tools", "type", "...") %in% names(formals(GetTDData::mcp_server))))
})
