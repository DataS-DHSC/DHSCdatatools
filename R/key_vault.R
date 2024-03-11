
#' Get DAC Azure Key Vault client
#' 
#' Note that retrieving client and any secrets will only work
#' it the correct proxy is set - see \code{\link{set_proxy_config}}
#' for setting the correct proxy configuration.
#' 
#' By default this function uses the "DAC_TENANT" and "KEY_VAULT_NAME"
#' environment variables set in the .Renviron file to access the Key Vault.
#' **Import: Never commit your .Renviron file to git or GitHub**
#'
#' @param .env development environment to use. One of "prod" (default), "qa", 
#' "test", or "dev". This value is ignored if \code{url} argument is specified 
#' for the Key Vault.
#' @param ... further arguments passed to \code{\link[AzureKeyVault]{key_vault}}
#'
#' @return Key Vault client
#' @export
#'
key_vault <- function(.env = c("prod", "qa", "test", "dev"), ...) {
  .env <- match.arg(.env)
  
  # check passed arguments
  params <- list(...)

  if (is.null(params[["tenant"]])) params[["tenant"]] <- get_env("DAC_TENANT")
  if (is.null(params[["url"]])) {
    params[["url"]] <- gsub(
      "{env}",
      .env,
      get_env("KEY_VAULT_NAME"),
      fixed = TRUE
    )
  }
  
  kv <- do.call(AzureKeyVault::key_vault, params)
  
  return(kv)
}

