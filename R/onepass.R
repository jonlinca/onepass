save_domain <- function(domain){
  # Instead of calling the domain a bunch of times
  # Save it as an environment variable for the session

  Sys.setenv(OP_DOMAIN = domain)
}

save_token <- function(token, domain){
  # Will save a session token as an environment variable
  # Set system environment variable based on dynamic subdomain name, generated from domain
  # This is only valid for 30 minutes
  # Can be considered to put into a ops object so it can be passed forward, as right now domains are called/saved as environment variables

  args <- list(token)
  names(args) <- paste0('OP_SESSION_', get_subdomain(domain))
  do.call(Sys.setenv, args)
}

save_device <- function(response){
  # Save the device as an environment variable

  if (grepl('OP_DEVICE', response)){
    device_id <- sub('.*OP_DEVICE=', '', response[1])
    device_id <- sub('`', '', device_id)
    Sys.setenv(OP_DEVICE = device_id)
  }

  message(paste0("To reduce notifications of new devices, insert the following line into the REnviron file (usethis::edit_r_environ() or edit .Renviron):\n  OP_DEVICE = ", Sys.getenv('OP_DEVICE')))

  return(device_id)
}

get_subdomain <- function(domain){
  strsplit(domain, '.', fixed=TRUE)[[1]][1]
}

current_token <- function(domain){
  Sys.getenv(paste0('OP_SESSION_', get_subdomain(domain)))
}

current_domain <- function(){
  Sys.getenv('OP_DOMAIN')
}


get_token <- function(domain, email = NULL, masterpassword, secretkey = NULL){
  subdomain <- get_subdomain(domain)

  # Injection prevention
  validateSecret(secretkey)
  email <- shQuote(email)
  subdomain <- shQuote(subdomain)
  domain <- shQuote(domain)

  if (is.null(secretkey)){
    ## Future - consider --account to work with multiple accounts
    response <- suppressWarnings(system2('op', args = c('signin', subdomain, '--raw'), input = masterpassword, stdout = TRUE, stderr = TRUE))[1]

    # Unique errors if secret key is not provided
    if(grepl('401: Unauthorized', response)){
      stop(paste0("Incorrect Master Password - ",response))
    }
  } else {
    response <- suppressWarnings(system2('op', args = c('signin', domain, email, secretkey, '--raw'), input = masterpassword, stdout = TRUE, stderr = TRUE))[1]

    # Unique errors if secret key is provided
    if(grepl('401: Unauthorized', response)){
      stop(paste0("Incorrect Secret Key or Master Password - ",response))
    }
  }

  # Exception if Op device comes up - kick it back out
  if (grepl('OP_DEVICE', response)){
    return(response)
  }

  check_response(response) # Check for more errors

  return(response)
}

check_response <- function(response){
  if (length(response) == 0){
    stop("Zero length response")
  }

  if (grepl('Account not found', response)) {
    stop("This appears to be a new device. Please run setup_op() first.")
  } else if (grepl('session expired', response)) {
    stop(paste0("Session expired. Reauthenticate with unlock_op()",response))
  } else if (grepl('ERROR', response)) {
    stop(paste0("Other error - ",response))
  }
}

new_ops <- function(token, domain, current_time = Sys.time()){
  # Create stable class of ops token

  structure(
    list(token = token,
         domain = domain,
         created = Sys.time()),
    class = 'ops')
}

#' Initialize vault and device
#'
#' If the device does not have an environment variable, creates one for the
#' session. This can be saved within the .Renviron file to reduce new device
#' alerts.
#'
#' Saves a token as an environment variable for the session as OP_SESSION_(subdomain)
#'
#' @param domain Full domain URL of your vault
#' @param email Email address used on 1Password
#' @param masterpassword Used to unlock the vault
#' @param secretkey Used for enabling 1Password on new devices
#'
#' @return 1Password session object, to be used for interacting with vault
#' @export
setup_op <- function(domain, email, masterpassword = rstudioapi::askForPassword("Please enter your Master Password"), secretkey = rstudioapi::askForPassword("Please enter your Secret Key")){
  response <- get_token(domain, email, masterpassword, secretkey)

  # If a device ID hasn't been set up, parse it out and regenerate a token
  # Setting a OP_DEVICE environment variable will reduce the notifications of a new device
  if (grepl('OP_DEVICE', response)){
    save_device(response) # Save the device id as an environment variable
    response <- get_token(domain, email, masterpassword, secretkey)
  }

  # save_token(response, get_subdomain(domain))
  # save_domain(domain)

  ops <- new_ops(response, domain)

  return(ops)
}

#' Unlock vault
#'
#' Saves a token as an environment variable for the session as OP_SESSION_(subdomain)
#'
#' @inheritParams setup_op
#'
#' @return 1Password session object, to be used for interacting with vault
#' @export
unlock_op <- function(domain, masterpassword = rstudioapi::askForPassword("Please enter your Master Password")){
  response <- get_token(domain, masterpassword = masterpassword)

  # If a device ID hasn't been set up, force an error and ask user to run setup
  if (grepl('OP_DEVICE', response)){
    stop("This appears to be a new device. Please run setup_op() first.")
  }

  # save_token(response, get_subdomain(domain))
  # save_domain(domain)

  ops <- new_ops(response, domain)

  return(ops)
}

#' List vaults
#'
#' @param ops 1Password Session object, created from setup_op() or unlock_op()
#'
#' @return A data frame containing the vaults available in the session
#' @export
op_list_vaults <- function(ops){
  stopifnot(class(ops) == 'ops')
  arg_session <- paste0('--session ', ops$token)

  response <- system2('op', args = c('list', 'vaults', arg_session), stdout = TRUE, stderr = TRUE)
  response <- paste0(response, collapse = '')
  check_response(response)

  parsed <- jsonlite::fromJSON(response, simplifyVector = TRUE)
  return(parsed)
}

#' List items
#'
#' @param vault Optional. Can specify a vault by name or uuid to see passwords
#'   within a specific vault
#' @param name Optional. A word or regex expression to search for items in vault(s).
#'
#' @inheritParams op_list_vaults
#'
#' @return A data frame of password items with titles, usernames and uuids
#' @export
op_list_items <- function(ops, vault = NULL, name = NULL){
  stopifnot(class(ops) == 'ops')

  if (!is.null(name) & !is.character(name)){
    stop("name is not a searchable text")
  }

  arg_session <- paste0('--session ', ops$token)
  arg_vault <- ''

  if (!is.null(vault)){
    arg_vault <- paste0('--vault ', shQuote(vault)) # Injection prevention
  }

  response <- system2('op', args = c('list', 'items', arg_session, arg_vault), stdout = TRUE, stderr = TRUE) #attr(response, 'status')
  response <- paste0(response, collapse = '') # Collapse because the response comes over as multiple character vectors
  check_response(response)

  parsed <- jsonlite::fromJSON(response, simplifyVector = TRUE)
  parsed <- data.frame(title = parsed$overview$title, username = parsed$overview$ainfo, uuid = parsed$uuid)

  # Search for a single term if available
  if (!is.null(name)) {
    parsed <- parsed[grepl(name, parsed$title, ignore.case = TRUE),]
  }

  return(parsed)
}

#' Retrieve a username and password
#'
#' @param name Specify an item by name or uuid. UUID is preferred for consistency.
#' @param fields Optional. List of fields desired. NULLable to get all contents.
#'
#' @inheritParams op_list_vaults
#'
#' @return A character vector
#' @export
op_get_item <- function(ops, name, fields = 'username,password'){
  stopifnot(class(ops) == 'ops')

  # Injection prevention
  name <- shQuote(name)
  fields <- shQuote(fields)

  arg_session <- paste0('--session ', ops$token)

  if (is.null(fields)){
    arg_fields <- ''
  } else {
    arg_fields <- paste0('--fields ', fields)
  }

  response <- system2('op', args = c('get', 'item', name, arg_session, arg_fields), stdout = TRUE, stderr = TRUE)
  check_response(response)

  parsed <- jsonlite::fromJSON(response, simplifyVector = TRUE)
  return(parsed)
}
