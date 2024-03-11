

#' Connect to the DHSC analytical cloud data store via ODBC driver
#'
#' Connects to the Databricks SQL endpoint on the DHSC analytical
#' cloud (DAC). Connections are authenticated using Azure Entra ID.
#' 
#' This function uses the "DAC_TENANT" and "KEY_VAULT_NAME"
#' environment variables set in the .Renviron file to access the DAC.
#' **Import: Never commit your .Renviron file to git or GitHub**
#'
#' @param env development environment to use. One of "prod" (default), "qa", 
#' "test", or "dev".
#' @param use_cache should any existing cached tokens be used for
#' authentication.
#' @param connections_pane whether to add the connection to RStudio's
#' interactive connection pane (adds additional loading time).
#'
#' @return a \code{DBIConnection} object equivalent to that returned by 
#' \code{\link[DBI]{dbConnect}}
#' @export
#'
dac_connect <- function(env = c("prod", "qa", "test", "dev"), 
                        use_cache = TRUE, 
                        connections_pane = FALSE) {
  env <- match.arg(env)
  
  dac_tenant <- get_env("DAC_TENANT")

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
  
  kv <- key_vault(.env = env)
  dac_sql_host <- kv |> read_secret("dac-db-host")
  dac_sql_path <- kv |> read_secret("dac-sql-endpoint-http-path")
    as.character()
  
  con <- DBI::dbConnect(
    odbc::odbc(),
    Driver = "Simba Spark ODBC Driver",
    Host = dac_sql_host,
    Port = 443,
    HTTPPath = dac_sql_path,
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