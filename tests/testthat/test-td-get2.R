library(testthat)
library(GetTDData)

# helper: writes a minimal, valid Tesouro Transparente CSV file
make_td_csv <- function(rows) {
  path <- tempfile(fileext = ".csv")
  writeLines(
    c(
      "Tipo Titulo;Data Vencimento;Data Base;Taxa Compra Manha;Taxa Venda Manha;PU Compra Manha;PU Venda Manha;PU Base Manha",
      rows
    ),
    path
  )
  path
}

make_one_bond_csv <- function(yield) {
  make_td_csv(sprintf(
    "Tesouro Prefixado;01/01/2027;09/09/2026;%s;13,67;961,91;961,11;961,11",
    yield
  ))
}

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

test_that("td_get2() rejects corrupt and empty data files instead of caching them", {
  tmp_dl <- tempfile(pattern = "cache_")
  on.exit(unlink(tmp_dl, recursive = TRUE), add = TRUE)

  # HTML error page (e.g. a 429 response saved as CSV)
  bad_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(bad_csv), add = TRUE)
  writeLines(c(
    "<!DOCTYPE html>",
    "<html><body>429 Too Many Requests</body></html>"
  ), bad_csv)

  expect_error(
    td_get2("LTN", 2026, 2026, dl_folder = tmp_dl, dataset_url = bad_csv),
    "not a valid"
  )
  expect_false(file.exists(file.path(tmp_dl, "precotaxatesourodireto.rds")))

  # header-only file: valid header, no data
  empty_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(empty_csv), add = TRUE)
  writeLines(
    "Tipo Titulo;Data Vencimento;Data Base;Taxa Compra Manha;Taxa Venda Manha;PU Compra Manha;PU Venda Manha;PU Base Manha",
    empty_csv
  )

  expect_error(
    td_get2("LTN", 2026, 2026, dl_folder = tmp_dl, dataset_url = empty_csv),
    "No valid rows found"
  )
  expect_false(file.exists(file.path(tmp_dl, "precotaxatesourodireto.rds")))
})

test_that("td_get2() does not reuse a cache built from a different source", {
  tmp_dl <- tempfile(pattern = "cache_")
  on.exit(unlink(tmp_dl, recursive = TRUE), add = TRUE)

  src_1 <- make_one_bond_csv("10,00")
  src_2 <- make_one_bond_csv("20,00")
  on.exit(unlink(c(src_1, src_2)), add = TRUE)

  df_1 <- td_get2(NULL, 2026, 2026, dl_folder = tmp_dl, dataset_url = src_1)
  expect_equal(df_1$yield_bid, 0.10)

  # same folder, different source: must not return the old data
  df_2 <- td_get2(NULL, 2026, 2026, dl_folder = tmp_dl, dataset_url = src_2)
  expect_equal(df_2$yield_bid, 0.20)
})

test_that("td_get2() rebuilds from an already validated CSV without fetching it again", {
  tmp_dl <- tempfile(pattern = "cache_")
  on.exit(unlink(tmp_dl, recursive = TRUE), add = TRUE)

  src <- make_one_bond_csv("10,00")
  on.exit(unlink(src), add = TRUE)

  df_1 <- td_get2(NULL, 2026, 2026, dl_folder = tmp_dl, dataset_url = src)
  expect_equal(nrow(df_1), 1)

  # drop the parsed cache and the source file: the same-day CSV must be reused
  unlink(file.path(tmp_dl, "precotaxatesourodireto.rds"))
  unlink(src)

  df_2 <- td_get2(NULL, 2026, 2026, dl_folder = tmp_dl, dataset_url = src)
  expect_equal(nrow(df_2), 1)
  expect_equal(df_2$yield_bid, 0.10)
})

test_that("td_get2() falls back to cached data when a forced refresh fails", {
  skip_if_not_installed("testthat", "3.1.5")

  tmp_dl <- tempfile(pattern = "cache_")
  on.exit(unlink(tmp_dl, recursive = TRUE), add = TRUE)

  src <- make_one_bond_csv("10,00")
  on.exit(unlink(src), add = TRUE)

  df_1 <- td_get2(NULL, 2026, 2026, dl_folder = tmp_dl, dataset_url = src)
  expect_equal(nrow(df_1), 1)

  # simulate a refresh with no internet connection
  testthat::local_mocked_bindings(td_has_internet = function() FALSE, .package = "GetTDData")

  expect_message(
    df_2 <- td_get2(
      NULL, 2026, 2026,
      dl_folder = tmp_dl,
      force_download = TRUE,
      dataset_url = "https://www.tesourotransparente.gov.br/ckan/dataset/taxas-dos-titulos-ofertados-pelo-tesouro-direto/"
    ),
    "Using previously cached TD data"
  )
  expect_equal(nrow(df_2), 1)
  expect_equal(df_2$yield_bid, 0.10)
})

test_that("td_get2() maps every accepted asset code alias", {
  tmp_dl <- tempfile(pattern = "cache_")
  on.exit(unlink(tmp_dl, recursive = TRUE), add = TRUE)

  tmp_csv <- make_td_csv(c(
    "Tesouro Prefixado;01/01/2027;09/09/2026;13,55;13,67;961,91;961,11;961,11",
    "Tesouro Selic;01/03/2027;09/09/2026;0,01;0,02;19844,22;19833,00;19833,00",
    "Tesouro IPCA+ com Juros Semestrais;15/08/2030;09/09/2026;7,78;7,90;4489,89;4471,47;4471,47",
    "Tesouro IPCA+;15/08/2035;09/09/2026;6,50;6,60;2000,00;1990,00;1990,00",
    "Tesouro Prefixado com Juros Semestrais;01/01/2031;09/09/2026;13,00;13,10;1000,00;995,00;995,00",
    "Tesouro IGPM+ com Juros Semestrais;01/04/2031;09/09/2026;6,10;6,20;3000,00;2990,00;2990,00",
    "Tesouro Educa+;15/12/2030;09/09/2026;6,00;6,10;1500,00;1490,00;1490,00",
    "Tesouro Renda+ Aposentadoria Extra;15/12/2049;09/09/2026;6,20;6,30;1300,00;1290,00;1290,00"
  ))
  on.exit(unlink(tmp_csv), add = TRUE)

  expected <- c(
    "LTN" = "LTN 010127",
    "Tesouro Prefixado" = "LTN 010127",
    "LFT" = "LFT 010327",
    "Tesouro Selic" = "LFT 010327",
    "NTN-B" = "NTN-B 150830",
    "Tesouro IPCA+ com Juros Semestrais" = "NTN-B 150830",
    "NTN-B Principal" = "NTN-B Principal 150835",
    "NTN-B Princip" = "NTN-B Principal 150835",
    "NTNBP" = "NTN-B Principal 150835",
    "Tesouro IPCA+" = "NTN-B Principal 150835",
    "NTN-F" = "NTN-F 010131",
    "NTNF" = "NTN-F 010131",
    "Tesouro Prefixado com Juros Semestrais" = "NTN-F 010131",
    "NTN-C" = "NTN-C 010431",
    "NTNC" = "NTN-C 010431",
    "Tesouro IGPM+ com Juros Semestrais" = "NTN-C 010431",
    "Tesouro IGP-M com Juros Semestrais" = "NTN-C 010431",
    "Educa+" = "NTN-B1 151230",
    "Tesouro Educa+" = "NTN-B1 151230",
    "RendA+" = "NTN-B1 151249",
    "Renda+" = "NTN-B1 151249",
    "Tesouro RendA+" = "NTN-B1 151249",
    "Tesouro Renda+ Aposentadoria Extra" = "NTN-B1 151249"
  )

  for (code in names(expected)) {
    df <- td_get2(code, 2026, 2026, dl_folder = tmp_dl, dataset_url = tmp_csv)
    expect_equal(unique(df$asset_code), unname(expected[[code]]), info = code)
  }

  df_all <- td_get2(NULL, 2026, 2026, dl_folder = tmp_dl, dataset_url = tmp_csv)
  expect_equal(nrow(df_all), 8)

  df_group <- td_get2("NTN-B1", 2026, 2026, dl_folder = tmp_dl, dataset_url = tmp_csv)
  expect_equal(sort(unique(df_group$asset_code)), c("NTN-B1 151230", "NTN-B1 151249"))
})

test_that("td_get2() validates year inputs", {
  expect_error(td_get2("LTN", first_year = NA), "must be a single whole number")
  expect_error(td_get2("LTN", last_year = "not-a-year"), "must be a single whole number")
  expect_error(td_get2("LTN", first_year = c(2020, 2021)), "must be a single whole number")
})

test_that("get_ckan_csv_url() rejects sources that are neither files nor URLs", {
  expect_error(
    GetTDData:::get_ckan_csv_url("this-is-not-a-file"),
    "neither an existing local file"
  )
})
