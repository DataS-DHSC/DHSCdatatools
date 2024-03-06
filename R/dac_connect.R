

#' Connect to the DHSC analytical cloud data store via ODBC driver
#'
#' Connects to the Databricks SQL endpoint on the DHSC analytical
#' cloud (DAC). Connections are authenticated using Azure Entra ID.
#' 
#' Please ensure that you have the correct .Renviron variables 
#' set.IMPORTANT - NEVER COMMIT YOUR .Renviron FILE
#'
#' @param use_cache Should any existing cached tokens be used for
#' authentication.
#' @param connections_pane Whether to add the connection to RStudio's
#' interactive connection pane (adds additional loading time).
#'
#' @return a `DBIConnection` object equivalent to that returned by 
#' `DBI::dbConnect`
#' @export
#'
dac_connect <- function(use_cache = TRUE, connections_pane = FALSE) {
  error_string <- paste(
    "Could not find value for `%s` in .Renviron, please",
    "make sure key=value pair exists and that .Renviron file is loaded."
  )

  dac_tenant <- Sys.getenv("DAC_TENANT")
  if (dac_tenant == "") stop(sprintf(error_string, "DAC_TENANT"))
  
  # url used for loading the correct proxy
  dac_url <- sprintf("https://login.microsoftonline.com/%s", dac_tenant)
  old <- httr::set_config(get_proxy_config(dac_url))
  on.exit(httr::set_config(old, override = TRUE))

  # run this first so can invalidate cache if needed  
  token <- AzureAuth::get_azure_token(
    resource = .databricks_resource_id, 
    tenant = dac_tenant, 
    app = .az_cli_app_id,
    use_cache = use_cache
  )
  
  kv <- key_vault()
  dac_sql_host <- kv$secrets$get("dac-sql-endpoint-hostname")
  dac_sql_path <- kv$secrets$get("dac-sql-endpoint-http-path")
  
  con <- DBI::dbConnect(
    odbc::odbc(),
    Driver = "Simba Spark ODBC Driver",
    Host = dac_sql_host$value,
    Port = 443,
    HTTPPath = dac_sql_path$value,
    SSL = 1,
    ThriftTransport = 2,
    AuthMech = 11,
    Auth_Flow = 0,
    Auth_AccessToken = token$credentials$access_token
  )
  
  # call odbc connection contract
  # NOTE uses non-exported function
  if (connections_pane) {
    odbc:::on_connection_opened(
      connection = con,
      code = paste(
        c(
          "library(DHSCdatatools)", 
          "con <- dac_connect(use_cache = TRUE, connections_pane = TRUE)"
        ),
        collapse = "\n"
      )
    )
  }
  
  return(con)
}