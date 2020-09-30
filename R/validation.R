validatePassword <- function(text){
  stopifnot(is.character(text))
}

validateSecret <- function(text){
  if (is.null(text)){return(TRUE)}

  stopifnot(is.character(text))

  if (!grepl("^[A-Z0-9-]*$", text)){
    stop('Secret key appears invalid - only numbers, letters and dashes should included')
  }

  if (nchar(gsub("[^[:alnum:]]","",text)) != 34){
    stop('Secret key appears invalid - is it 34 numbers or characters long?')
  }

  return(TRUE)
}

validateEmail <- function(text){
  stopifnot(is.character(text))

  # Credit: http://emailregex.com
  if(!grepl('[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}', text, ignore.case=TRUE, perl = TRUE)){
    stop('Invalid email detected')
  }

  return(TRUE)
}

validateDomain <- function(text){
  stopifnot(is.character(text))
}

