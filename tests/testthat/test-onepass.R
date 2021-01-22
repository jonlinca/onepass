check_api <- function(){
  key <- Sys.getenv('onepass_secretkey')
  if (!nzchar(key)){
    skip('API not available')
  }
}

test_that("Initial 1Password, no sessions or incorrect passwords", {
  check_api()

  op_domain <- Sys.getenv('onepass_domain')
  op_email <- Sys.getenv('onepass_email')
  op_secretkey <- Sys.getenv('onepass_secretkey')
  op_masterpassword <- Sys.getenv('onepass_password')

  expect_error(unlock_op(op_domain, op_email), 'new|Unauthorized') # Needs to handle testing for devices that don't have the sys environ set
  expect_error(setup_op(op_domain, op_email, op_masterpassword, "A1-B12345-C12345-D1234-E1234-F1234-12345"), 'invalid account')
})

test_that("Authentication 1Password",{
  check_api()

  op_domain <- Sys.getenv('onepass_domain')
  op_email <- Sys.getenv('onepass_email')
  op_secretkey <- Sys.getenv('onepass_secretkey')
  op_masterpassword <- Sys.getenv('onepass_password')

  # Initial setup
  ops1 <- setup_op(op_domain, op_email, op_masterpassword, op_secretkey) # Pass
  device <- Sys.getenv('OP_DEVICE')
  expect_true(device != '')
  expect_named(ops1, c('token', 'domain', 'created'))
  expect_s3_class(ops1, 'ops')

  # Subsequent login
  expect_error(unlock_op(op_domain, op_email), 'Incorrect Master Password')

  ops2 <- unlock_op(op_domain, op_masterpassword) # Pass
  expect_named(ops2, c('token', 'domain', 'created'))
  expect_s3_class(ops2, 'ops')

  expect_false(ops1$token == ops2$token)
})

test_that("List items",{
  op_domain <- Sys.getenv('onepass_domain')
  op_email <- Sys.getenv('onepass_email')
  op_secretkey <- Sys.getenv('onepass_secretkey')
  op_masterpassword <- Sys.getenv('onepass_password')

  ops <- setup_op(op_domain, op_email, op_masterpassword, op_secretkey) # Pass

  expect_true(nrow(op_list_items(ops, 'Shared (Everyone)')) > 0)
  expect_true(nrow(op_list_items(ops, 'Private')) > 0)
})

test_that("Retrieve item",{
  check_api()

  op_domain <- Sys.getenv('onepass_domain')
  op_email <- Sys.getenv('onepass_email')
  op_secretkey <- Sys.getenv('onepass_secretkey')
  op_masterpassword <- Sys.getenv('onepass_password')

  # Initial setup
  ops <- setup_op(op_domain, op_email, op_masterpassword, op_secretkey) # Pass

  # Retrieve an item
  creds <- op_get_item(ops, 'Westjet')
  expect_equal(creds$username, 'superuser')
  expect_equal(creds$password, 'westjetter')

  creds <- op_get_item(ops, 'Super Duper')
  expect_equal(creds$username, 'awesome')
  expect_equal(creds$password, 'sauce')
})
