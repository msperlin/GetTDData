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

  expect_warning(
    df_ltn <- td_get(asset_codes = 'LTN',
                     first_year = first_year),
    class = "lifecycle_warning_deprecated"
  )

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

test_that("td_get() deprecation warning conveys closure, August 2026, and td_get2()", {
  op <- options(lifecycle_verbosity = "warning")
  on.exit(options(op))

  warn_msg <- NULL
  withCallingHandlers(
    tryCatch(td_get(asset_codes = "INVALID_ASSET"), error = function(e) NULL),
    lifecycle_warning_deprecated = function(cnd) {
      warn_msg <<- conditionMessage(cnd)
      invokeRestart("muffleWarning")
    }
  )

  expect_false(is.null(warn_msg))
  expect_match(warn_msg, "deprecated")
  expect_match(warn_msg, "td_get2\\(\\)")
  expect_match(warn_msg, "August 2026")
  expect_match(warn_msg, "desativacao-do-aplicativo-a-partir-de-17-de-agosto")
})
