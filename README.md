
<!-- README.md is generated from README.Rmd. Please edit that file -->

# onepass

<!-- badges: start -->

<!-- badges: end -->

The **onepass** package enables you to use R to interact with your
1Password vault. **onepass** provides an interface to the 1Password
Command Line Interface (CLI), allowing you to query the list of
credentials in your vault, and retrieve account usernames and passwords.

## Installation

First off, ensure the [1Password
CLI](https://1password.com/downloads/command-line/) installed on your
computer. You should test that it works from the command line as well.

You can install the released version of onepass from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("onepass")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("jonlinca/onepass")
```

## Set up

Once the 1Password CLI is installed, you will need your domain
(\*.1password.com), the email account, your master password, as well as
your secret key.

To setup 1Password CLI with R on a new machine, `setup_op()` will
require both the master password and secret key:

``` r
library('onepass')

ops <- setup_op(op_domain, op_email, op_masterpassword, op_secretkey) 
```

Typically on a new machine, you may also receive the following as well:

    #> To reduce notifications of new devices, insert the following line into the 
    #> Renviron file (usethis::edit_r_environ() or edit .Renviron):
    #>           OP_DEVICE = 1234567890abcdefghijklmnopqrstuvwxyz

It is highly recommended that you insert the unique `OP_DEVICE` into
your .Renviron file - otherwise, you will receive constant messages
about logins from a new device.

## Usage

Once you have set up 1Password and connected to the vault, you can
connect to 1Password by unlocking the vault. You will also need to do
this if your session token expires after 30 minutes. The email account
isn’t required as it is implicit based upon your first setup.

``` r
ops <- unlock_op(op_domain, op_masterpassword)
```

This `ops` object will contain three elements, the most important being
the token. You can use this token and pass it through to see what vaults
you have access to:

``` r
op_list_vaults(ops)
```

Within these vaults, you can see the list of passwords you have
available:

``` r
op_list_items(ops) # All vaults
op_list_items(ops, 'Private') # Just the contents in the private vault
```

And most importantly, you can retrieve the username and password for any
singular item. You can either use the name, or more reliably, the UUID:

``` r
op_get_item(ops, 'Westjet')
#> $password
#> [1] "westjetter"
#> 
#> $username
#> [1] "superuser"
op_get_item(ops, 'c4mqmdxk4gyjgifj5s5tctk4ea')
#> $password
#> [1] "westjetter"
#> 
#> $username
#> [1] "superuser"
```
