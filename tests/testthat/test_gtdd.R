library(testthat)
library(GetTDData)

# no longer testing download and read functions (keeping all files local to avoid problems with TD website)

dl.folder <- file.path(tempdir(), "TESTING_TD")
dir.create(dl.folder)

test_that(desc = 'Test of download function',{

  testthat::skip_if_offline()
  testthat::skip_on_cran()

  my.flag <- download.TD.data(asset.codes = 'LTN', dl.folder = dl.folder, n.dl = 1)

  expect_equal(my.flag , TRUE)
  }
)


test_that(desc = 'Test of read function',{

  testthat::skip_if_offline()
  testthat::skip_on_cran()

  returned.rows <- nrow(read.TD.files(maturity = NULL,
                                      dl.folder = dl.folder ))

  expect_equal(returned.rows > 0, TRUE)
} )

cat('\nDeleting test folder')
unlink(dl.folder, recursive = T)

