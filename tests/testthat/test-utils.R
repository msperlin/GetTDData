test_that('Test of get.yield.curve()',{

  available_td <- get_td_names()

  expect_true(class(available_td) == 'character')
  expect_true(length(available_td) > 0)
})


