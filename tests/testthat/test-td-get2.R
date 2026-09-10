library(testthat)
library(GetTDData)

test_that("td_get2() works with local CSV file and has matching columns", {
  tmp_csv <- tempfile(fileext = ".csv")
  cat(
    "Tipo Titulo;Data Vencimento;Data Base;Taxa Compra Manha;Taxa Venda Manha;PU Compra Manha;PU Venda Manha;PU Base Manha\n",
    "Tesouro Prefixado;01/01/2027;09/09/2026;13,55;13,67;961,91;961,11;961,11\n",
    "Tesouro Selic;01/03/2027;09/09/2026;0,00;0,01;19844,22;19833,00;19833,00\n",
    "Tesouro IPCA+ com Juros Semestrais;15/08/2030;09/09/2026;7,78;7,90;4489,89;4471,47;4471,47\n",
    file = tmp_csv, sep = ""
  )
  on.exit(unlink(tmp_csv), add = TRUE)

  tmp_dl <- tempfile(pattern = "cache_")
  on.exit(unlink(tmp_dl, recursive = TRUE), add = TRUE)

  # Check all assets
  df_all <- td_get2(
    asset_codes = NULL,
    first_year = 2026,
    last_year = 2026,
    dl_folder = tmp_dl,
    dataset_url = tmp_csv
  )

  expect_s3_class(df_all, "tbl_df")
  expect_equal(colnames(df_all), c("ref_date", "yield_bid", "price_bid", "asset_code", "matur_date"))
  expect_equal(nrow(df_all), 3)
  expect_equal(df_all$asset_code, c("LFT 010327", "LTN 010127", "NTN-B 150830"))
  expect_equal(df_all$yield_bid[df_all$asset_code == "LTN 010127"], 0.1355)
  expect_equal(df_all$price_bid[df_all$asset_code == "LTN 010127"], 961.91)
  expect_equal(df_all$ref_date[1], as.Date("2026-09-09"))
  expect_equal(df_all$matur_date[df_all$asset_code == "LTN 010127"], as.Date("2027-01-01"))

  # Check filtering single asset
  df_ltn <- td_get2(
    asset_codes = "LTN",
    first_year = 2026,
    last_year = 2026,
    dl_folder = tmp_dl,
    dataset_url = tmp_csv
  )
  expect_equal(nrow(df_ltn), 1)
  expect_equal(df_ltn$asset_code, "LTN 010127")

  # Check caching works on second call
  df_cached <- td_get2(
    asset_codes = "LFT",
    first_year = 2026,
    last_year = 2026,
    dl_folder = tmp_dl,
    dataset_url = tmp_csv
  )
  expect_equal(nrow(df_cached), 1)
  expect_equal(df_cached$asset_code, "LFT 010327")
})

test_that("td_get2() validates input arguments", {
  # Invalid asset code
  expect_error(td_get2("NOT_A_BOND"), "Input asset_codes not valid")

  # Invalid year range
  expect_error(td_get2("LTN", first_year = 2025, last_year = 2020), "cannot be greater")

  # Year < 2005 fixes with warning
  tmp_csv <- tempfile(fileext = ".csv")
  cat(
    "Tipo Titulo;Data Vencimento;Data Base;Taxa Compra Manha;Taxa Venda Manha;PU Compra Manha;PU Venda Manha;PU Base Manha\n",
    "Tesouro Prefixado;01/01/2027;09/09/2026;13,55;13,67;961,91;961,11;961,11\n",
    file = tmp_csv, sep = ""
  )
  on.exit(unlink(tmp_csv), add = TRUE)
  tmp_dl <- tempfile(pattern = "cache_")
  on.exit(unlink(tmp_dl, recursive = TRUE), add = TRUE)

  expect_warning(
    td_get2("LTN", first_year = 2000, last_year = 2026, dl_folder = tmp_dl, dataset_url = tmp_csv),
    "First year of TD data is 2005"
  )
})

test_that("td_get2() column names match td_get() output", {
  if (!(requireNamespace("covr", quietly = TRUE) && covr::in_covr())) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  isolated_dl <- tempfile()
  suppressWarnings(df_old <- td_get("LTN", 2022, 2022, dl_folder = isolated_dl))
  df_new <- td_get2("LTN", 2022, 2022, dl_folder = isolated_dl)

  expect_equal(colnames(df_new), colnames(df_old))
  expect_equal(sapply(df_new, class), sapply(df_old, class))
  expect_equal(nrow(df_new), nrow(df_old))
  expect_s3_class(df_new, "tbl_df")
})

test_that("td_get2() retrieves multiple assets", {
  if (!(requireNamespace("covr", quietly = TRUE) && covr::in_covr())) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  df_multi <- td_get2(c("LTN", "NTN-B"), 2022, 2022)
  bonds <- unique(sub(" \\d{6}$", "", df_multi$asset_code))
  expect_true("LTN" %in% bonds)
  expect_true("NTN-B" %in% bonds)
  expect_equal(colnames(df_multi), c("ref_date", "yield_bid", "price_bid", "asset_code", "matur_date"))
})
