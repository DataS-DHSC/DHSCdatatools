
#' Automatically get proxy config 
#'
#' @param target_url url with host for which to lookup the proxy server
#'
#' @return curl config parameters
#' @export
#' 
get_proxy_config <- function(target_url = "https://www.google.com") {
  config <- httr::use_proxy(
    url = unlist(
      strsplit(curl::ie_get_proxy_for_url(target_url), ";")
    )[[1]],
    auth = "ntlm"
  )
  
  return(config)
}