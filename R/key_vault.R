
#' Get DAC Azure Key Vault client
#' 
#' Note that retrieving client and any secrets will only work
#' it the correct proxy is set - see `DHSCdatatools::get_proxy_config` 
#' for getting the correct proxy configuration.
#'
#' @param ... Further arguments passed to `AzureKeyVault::key_vault`
#'
#' @return Key Vault client
#' @export
#'
key_vault <- function(...) {
  # check passed arguments
  params <- list(...)

  error_string <- paste(
    "Could not find value for `%s` in .Renviron, please",
    "make sure key=value pair exists and that .Renviron file is loaded."
  )
    
  if (is.null(params[["url"]])) {
    params[["url"]] <- Sys.getenv("KEY_VAULT_NAME")
    if (params[["url"]] == "") stop(sprintf(error_string, "KEY_VAULT_NAME"))
  }
  
  if (is.null(params[["tenant"]])) {
    params[["tenant"]] <- Sys.getenv("DAC_TENANT")
    if (params[["tenant"]] == "") stop(sprintf(error_string, "DAC_TENANT"))
  }
  
  kv <- do.call(AzureKeyVault::key_vault, params)
  
  return(kv)
}