
#' Automatically get proxy config 
#' 
#' Get proxy settings for functions based on curl using Windows settings.
#'
#' While R uses the \code{wininet} download method that correctly obtains
#' proxy details from Windows via the WinINet functions, other packages
#' such as \pkg{httr} are based on \pkg{curl} and so need the proxy settings
#' configured to use the corporate proxy and firewall. This function uses 
#' \code{\link[curl]{ie_get_proxy_for_url}} to read these settings.
#'
#' @param target_url url with host for which to lookup the proxy server
#'
#' @return curl config parameters
#' @export
#' 
get_proxy_config <- function(target_url = "https://www.google.com") {
  proxy_list <- curl::ie_get_proxy_for_url(target_url)
  
  config <- httr::use_proxy(
    url = regmatches(proxy_list, regexpr("[^;]+", proxy_list)),
    auth = "ntlm"
  )
  
  return(config)
}


#' Correctly set the DHSC proxy for base R methods
#' 
#' Configure proxy settings for functions based on curl using Windows settings.
#'
#' While R uses the \code{wininet} download method that correctly obtains
#' proxy details from Windows via the WinINet functions, other packages
#' such as \pkg{httr} are based on \pkg{curl} and so need the proxy settings
#' configured to use the corporate proxy and firewall. This function uses 
#' \code{\link[curl]{ie_get_proxy_for_url}} to read these settings and then applies 
#' them using \code{\link[httr]{set_config}}.
#'
#' @param target_url url with host for which to lookup the proxy server
#'
#' @return invisibility, the old global config.
#' @export
#'
set_proxy_config <- function(target_url = "https://www.google.com") {
  httr::set_config(get_proxy_config(target_url))
}