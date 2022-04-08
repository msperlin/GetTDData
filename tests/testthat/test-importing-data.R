library(testthat)
library(GetTDData)

# no longer testing download and read functions (keeping all files local to avoid problems with TD website)

dl.folder <- file.path(tempdir(), "TESTING_TD")
dir.create(dl.folder)

test_that(desc = 'Test of download function #1',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }


  my.flag <- download.TD.data(asset.codes = 'LTN',
                              dl.folder = dl.folder,
                              n.dl = 5  # keep it short
                              )

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
                              n.dl = 5  # keep it short
  )

  expect_equal(my.flag , TRUE)
}
)


test_that(desc = 'Test of read function #01',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  returned.rows <- nrow(read.TD.files(maturity = NULL,
                                      dl.folder = dl.folder ))

  expect_equal(returned.rows > 0, TRUE)
} )

test_that(desc = 'Test of read function #02',{

  if (!covr::in_covr()) {
    testthat::skip_if_offline()
    testthat::skip_on_cran()
  }

  returned.rows <- nrow(read.TD.files(asset.codes = "LTN",
                                      maturity = NULL,
                                      dl.folder = dl.folder ))

  expect_true(returned.rows > 0)
} )

cat('\nDeleting test folder')
unlink(dl.folder, recursive = T)

