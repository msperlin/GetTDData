test_that("get_asset_info works correctly", {
  info <- get_asset_info()
  expect_s3_class(info, "tbl_df")
  expect_true(nrow(info) > 0)
  expect_true(all(c("asset_code", "name", "indexer", "coupon", "description") %in% names(info)))

  info_ltn <- get_asset_info("LTN")
  expect_equal(nrow(info_ltn), 1)
  expect_equal(info_ltn$indexer, "Prefixado")
})

test_that("get_cache_folder options work", {
  cache_temp <- get_cache_folder(persistent = FALSE)
  expect_true(fs::is_dir(cache_temp))

  cache_pers <- get_cache_folder(persistent = TRUE)
  expect_true(fs::is_dir(cache_pers))
})

test_that("plot functions create ggplot objects", {
  mock_yc <- tibble::tibble(
    n_biz_days = c(252, 252, 252),
    type = c("real_return", "nominal_return", "implicit_inflation"),
    value = c(6.5, 12.0, 5.5),
    ref_date = as.Date(c("2025-01-01", "2025-01-01", "2025-01-01")),
    current_date = as.Date("2024-01-01")
  )

  p_yc <- plot_yield_curve(mock_yc)
  expect_s3_class(p_yc, "ggplot")

  mock_td <- tibble::tibble(
    ref_date = as.Date("2024-01-01") + 0:4,
    yield_bid = c(0.1, 0.11, 0.105, 0.12, 0.115),
    price_bid = c(800, 805, 802, 810, 808),
    asset_code = "LTN 010126",
    matur_date = as.Date("2026-01-01")
  )

  p_price <- plot_td_series(mock_td, type = "price")
  expect_s3_class(p_price, "ggplot")

  p_yield <- plot_td_series(mock_td, type = "yield")
  expect_s3_class(p_yield, "ggplot")
})
