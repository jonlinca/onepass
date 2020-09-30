validatePassword <- function(text){
  stopifnot(is.character(text))
}

validateSecret <- function(text){
  stopifnot(is.character(text))

  if (!grepl("^[A-Z0-9-]*$", text)){
    stop('Secret key appears invalid - only numbers, letters and dashes should included')
  }

  if (nchar(gsub("[^[:alnum:]]","",text)) != 34){
    stop('Secret key appears invalid - is it 34 numbers or characters long?')
  }
}

validateEmail <- function(text){
  stopifnot(is.character(text))
}

validateDomain <- function(text){
  stopifnot(is.character(text))
}

