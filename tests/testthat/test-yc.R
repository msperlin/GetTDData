test_that('Test of get.yield.curve()',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  df_yc <- get.yield.curve()

  expect_true(nrow(df_yc) > 0)
})
