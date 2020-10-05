test_that("Secret Key Validation", {
  goodkey <- 'A1-B12345-C12345-D1234-E1234-F1234-12345'
  badkey <-'A1-B12345-C12345-D1234-E1234-F1234-1234'
  injection <- "foo&touch fooooooooooooooooooooooooo"

  expect_silent(validateSecret(goodkey))
  expect_error(validateSecret(badkey), '34')
  expect_error(validateSecret(injection), 'numbers, letters and dashes')
})

test_that("Injection 1", {
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

  ops <- setup_op(op_domain, op_email, op_masterpassword, op_secretkey)

  # List
  expect_error(expect_warning(op_list_items(injection), "status 1"), "ops")
  expect_error(expect_warning(op_list_items(ops, injection), "status 1"), "doesn't seem to be a vault")

  # Get Item
  expect_error(op_get_item(ops, 'Westjet', fields = injection), "Zero") # No fields should be returned, caught in response
  expect_error(expect_warning(op_get_item(ops, injection), "status 1"), "Zero|item") # Expect both error and warning

  # This will return the injection as a named vector
  creds <- op_get_item(ops, 'Westjet', fields = paste0('username,password,', injection))
  expect_equal(length(creds), 3)
  expect_true(creds[1] == "")
})

test_that("Injection 2", {
  injection <- "$(touch ~/foo)1234567890"

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

  ops <- setup_op(op_domain, op_email, op_masterpassword, op_secretkey)

  # List
  expect_error(expect_warning(op_list_items(injection), "status 1"), "ops")
  expect_error(expect_warning(op_list_items(ops, injection), "status 1"), "doesn't seem to be a vault")

  # Get Item
  expect_error(op_get_item(ops, 'Westjet', fields = injection), "Zero") # No fields should be returned, caught in response
  expect_error(expect_warning(op_get_item(ops, injection), "status 1"), "Zero|item") # Expect both error and warning

  # This will return the injection as a named list
  creds <- op_get_item(ops, 'Westjet', fields = paste0('username,password,', injection))
  expect_equal(length(creds), 3)
  expect_true(creds[1] == "")
})
