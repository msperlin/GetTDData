test_that('Test of get_yield_curve() and get.yield.curve()',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  df_yc <- get_yield_curve()
  expect_true(nrow(df_yc) > 0)

  # Check that get.yield.curve() warns and returns the same data
  expect_warning(df_yc_dep <- get.yield.curve(), "deprecated")
  expect_equal(df_yc, df_yc_dep)
})
