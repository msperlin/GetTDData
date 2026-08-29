library(testthat)
library(GetTDData)

first_year <- 2022

test_df <- function(df) {
  expect_true(nrow(df) > 1)
  expect_true(ncol(df) > 1)

  return(invisible(TRUE))
}

test_that(desc = 'td_get() -- single LTN',{

  if (!(requireNamespace("covr", quietly = TRUE) && covr::in_covr())) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  df_ltn <- td_get(asset_codes = 'LTN',
                   first_year = first_year)

  test_df(df_ltn)

})

test_that(desc = 'td_get() -- two assets',{

  if (!(requireNamespace("covr", quietly = TRUE) && covr::in_covr())) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  df_ltn <- td_get(asset_codes = c('LTN', "NTN-B"),
                   first_year = first_year)

  test_df(df_ltn)

})

test_that(desc = 'td_get_current()',{

  if (!(requireNamespace("covr", quietly = TRUE) && covr::in_covr())) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  df_current <- td_get_current()
  test_df(df_current)
})
