% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/keyring.R
\name{get_token}
\alias{get_token}
\title{Helper function to retrieve DAC Databricks tokens from keyring}
\usage{
get_token(
  env = c("prod", "qa", "test", "dev"),
  username = NULL,
  keyring = NULL
)
}
\arguments{
\item{env}{development environment of token. One of "prod" (default), "qa",
"test", or "dev".}

\item{username}{username, a character scalar, or NULL if the key is not
associated with a username passed to \code{\link[keyring]{key_get}}.}

\item{keyring}{for systems that support multiple keyrings, specify the name
of the keyring to use here. If NULL, then the default keyring is used.
Passed to \code{\link[keyring]{key_get}}.}
}
\value{
a character scalar, the password or other confidential information
that was stored in the key.
}
\description{
Helper function to retrieve DAC Databricks tokens from keyring
}
