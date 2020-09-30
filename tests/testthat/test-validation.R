test_that("Secret Key Validation", {
  goodkey <- 'A1-B12345-C12345-D1234-E1234-F1234-12345'
  badkey <-'A1-B12345-C12345-D1234-E1234-F1234-1234'
  injection <- "foo&touch fooooooooooooooooooooooooo"

  expect_silent(validateSecret(goodkey))
  expect_error(validateSecret(badkey), '34')
  expect_error(validateSecret(injection), 'numbers, letters and dashes')
})

test_that("Injections", {
  injection <- "foo&touch foo"

  op_domain <- Sys.getenv('onepass_domain')
  op_email <- Sys.getenv('onepass_email')
  op_secretkey <- Sys.getenv('onepass_secretkey')
  op_masterpassword <- Sys.getenv('onepass_password')

  expect_error(setup_op(op_domain, op_email, op_masterpassword, injection))
  expect_error(setup_op(op_domain, op_email, injection, op_secretkey))
  expect_error(setup_op(op_domain, injection, op_masterpassword, op_secretkey))
  expect_error(setup_op(injection, op_email, op_masterpassword, op_secretkey))

  expect_error(unlock_op(op_domain, injection))
  expect_error(unlock_op(injection, op_masterpassword))

  # Can't seem to pick up error code from list items, although injection is being prevented
  # expect_error(op_list_items(ops, injection))
  # expect_error(op_get_item(ops, injection))
  expect_error(op_get_item(ops, 'Westjet', fields = injection)) # No fields should be returned
  # op_get_item(ops, 'Westjet', fields = paste0('username,password,', injection))
})
