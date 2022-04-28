library(testthat)
library(GetTDData)

# no longer testing download and read functions (keeping all files local to avoid problems with TD website)

dl.folder <- file.path(tempdir(), "TESTING_TD")
dir.create(dl.folder)
n_dl <- 3

test_that(desc = 'Test of download function #1',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }


  my.flag <- download.TD.data(asset.codes = 'LTN',
                              dl.folder = dl.folder,
                              n.dl = n_dl)

  # run it again to check existing files
  my.flag <- download.TD.data(asset.codes = 'LTN',
                              dl.folder = dl.folder,
                              n.dl = n_dl)

  expect_equal(my.flag , TRUE)
  }
)

test_that(desc = 'Test of download function #2',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }


  my.flag <- download.TD.data(asset.codes = NULL,
                              dl.folder = dl.folder,
                              n.dl = n_dl  # keep it short
  )

  expect_equal(my.flag , TRUE)
}
)


test_that(desc = 'Test of read function #01',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  returned.rows <- nrow(read.TD.files(dl.folder = dl.folder ))

  expect_equal(returned.rows > 0, TRUE)
} )

test_that(desc = 'Test of read function #02',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  available_assets <- get_td_names()

  for (i_asset in available_assets) {
    download.TD.data(asset.codes = i_asset,
                     dl.folder = dl.folder,
                     n.dl = n_dl)

    df_temp <- read.TD.files(dl.folder = dl.folder)

    expect_true(nrow(df_temp) > 0)
  }


} )

cat('\nDeleting test folder')
unlink(dl.folder, recursive = T)

