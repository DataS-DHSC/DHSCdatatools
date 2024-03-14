

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
  
  cli::cli_alert_info("Getting Azure token.")

  # run this first so can invalidate cache if needed  
  token <- AzureAuth::get_azure_token(
    resource = .databricks_resource_id, 
    tenant = dac_tenant, 
    app = .az_cli_app_id,
    use_cache = use_cache
  )
  
  cli::cli_alert_info("Reading from \"{env}\" DAC Key Vault.")
  
  kv <- key_vault(.env = env)
  dac_sql_host <- kv |> read_secret("dac-db-host")
  dac_sql_path <- kv |> read_secret("dac-sql-endpoint-http-path")

  connection_code <- sprintf(
    paste(
      "con <- dac_connect(",
      "env = \"%s\", use_cache = TRUE, connections_pane = TRUE",
      ")"
    ),
    env
  )
  
  con <- .dac_connect(
    token$credentials$access_token, 
    dac_sql_host, 
    dac_sql_path,
    connections_pane,
    connection_code
  )
    
  return(con)
}


#' Connect to the DHSC analytical cloud data store via ODBC driver using a config yaml file
#'
#' @param config_yml yaml file with configuration settings.
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
dac_cfg_connect <- function(config_yml, 
                            env = c("prod", "qa", "test", "dev"),
                            use_cache = TRUE, 
                            connections_pane = FALSE) {
  env <- match.arg(env)
  
  cfg <- yaml::read_yaml(config_yml)
  if (!(env %in% names(cfg))) {
    stop(
      sprintf(
        "Unable to find config for '%s' environment in '%s' file.",
        env,
        config_yml
      )
    )
  }
  
  cfg[["filename"]] <- config_yml
  
  # if no token set get from keyring
  token <- cfg |> get_cfg(env, "token", default = NULL)
  if (is.null(token)) token <- get_token(env)
  
  dac_tenant <- get_env("DAC_TENANT")
  
  # url used for loading the correct proxy
  dac_url <- sprintf("https://login.microsoftonline.com/%s", dac_tenant)
  old_config <- httr::set_config(get_proxy_config(dac_url))
  on.exit(httr::set_config(old_config, override = TRUE))
  
  # get configurations
  kv <- key_vault(.env = env, use_cache = use_cache)
  dac_sql_host <- kv |> read_secret("dac-db-host")
  
  connection_code <- sprintf(
    paste(
      "con <- dac_cfg_connect(",
      "\"%s\", env = \"%s\", use_cache = TRUE, connections_pane = TRUE",
      ")"
    ),
    config_yml,
    env
  )
  
  con <- .dac_connect(
    token, 
    dac_sql_host, 
    cfg |> get_cfg(env, "dac_sql_path"),
    connections_pane,
    connection_code
  )
  
  return(con)
}


#'@keywords internal
.dac_connect <- function(token, 
                         dac_sql_host, 
                         dac_sql_path,
                         connections_pane,
                         connection_code) {
  
  cli::cli_alert_info(
    "Creating connection, this may take some time if cluster needs starting."
  )
  
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
    Auth_AccessToken = token
  )
  
  if (!odbc::dbIsValid(con)) {
    cli::cli_alert_danger("Failed to connect, please try connecting again.")
    return(NULL)
  } else {
    cli::cli_alert_info("Connection complete.")
  }

  # call odbc connection contract
  # NOTE uses non-exported function
  if (connections_pane) {
    odbc:::on_connection_opened(
      connection = con,
      code = paste(
        c(
          "library(DHSCdatatools)", 
          connection_code
        ),
        collapse = "\n"
      )
    )
  }
  
  return(con)
}
