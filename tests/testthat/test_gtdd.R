library(testthat)
library(GetTDData)

# no longer testing download and read functions (keeping all files local to avoid problems with TD website)

# dl.folder <- 'TD Data'
#
# my.flag <- download.TD.data(asset.codes = 'LTN', dl.folder = dl.folder, n.dl = 1)
# test_that(desc = 'Test of download function',{
#           expect_equal(my.flag , TRUE) } )
#
#
# returned.rows <- nrow(read.TD.files(maturity = '010117', dl.folder = dl.folder ))
#
# test_that(desc = 'Test of read function',{
#   expect_equal(returned.rows>0, TRUE)
#   } )
#
# cat('\nDeleting test folder')
# unlink(dl.folder, recursive = T)

