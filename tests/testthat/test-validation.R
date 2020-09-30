test_that("Secret Key Validation", {
  goodkey <- 'A1-B12345-C12345-D1234-E1234-F1234-12345'
  badkey <-'A1-B12345-C12345-D1234-E1234-F1234-1234'
  injection <- "foo&touch fooooooooooooooooooooooooo"

  expect_silent(validateSecret(testkey))
  expect_error(validateSecret(badkey), '34')
  expect_error(validateSecret(injection), 'numbers, letters and dashes')
})
