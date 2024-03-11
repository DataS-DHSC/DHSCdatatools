
#' Helper function to save DAC Databrick tokens to keyring
#'
#' @param env development environment of token. One of "prod" (default), "qa", 
#' "test", or "dev".
#' @param username username, a character scalar, or NULL if the key is not 
#' associated with a username passed to \code{\link[keyring]{key_set}}.
#' @param keyring for systems that support multiple keyrings, specify the name 
#' of the keyring to use here. If NULL, then the default keyring is used. 
#' Passed to \code{\link[keyring]{key_set}}.
#'
#' @export
#'
set_token <- function(env = c("prod", "qa", "test", "dev"), 
                      username = NULL,
                      keyring = NULL) {
  env <- match.arg(env)

  keyring::key_set(
    sprintf(.token_servicename, env),
    username = username,
    keyring = keyring,
    prompt = sprintf("DAC %s token: ", env)
  )

}


#' Helper function to retrieve DAC Databricks tokens from keyring
#'
#' @param env development environment of token. One of "prod" (default), "qa", 
#' "test", or "dev".
#' @param username username, a character scalar, or NULL if the key is not 
#' associated with a username passed to \code{\link[keyring]{key_get}}.
#' @param keyring for systems that support multiple keyrings, specify the name 
#' of the keyring to use here. If NULL, then the default keyring is used. 
#' Passed to \code{\link[keyring]{key_get}}.
#'
#' @return a character scalar, the password or other confidential information 
#' that was stored in the key.
#' @export
#'
get_token <- function(env = c("prod", "qa", "test", "dev"), 
                      username = NULL,
                      keyring = NULL) {
  env <- match.arg(env)
  
  # read in token from keyring
  service_name <- sprintf(.token_servicename, env)
  
  if (!(service_name %in% keyring::key_list(keyring = keyring)$service)) {
    stop(
      sprintf(
        paste(
          "Unable to find Databricks token for '%s' environment in",
          "system credenial store. Please see",
          "https://github.com/DataS-DHSC/DHSCdatatools for",
          "guidance on creating and setting token."
        ),
        env
      )
    )
  }
  
  keyring::key_get(
    service_name,
    username = username,
    keyring = keyring
  )
}