
#' Initialise sparklyr and open connection
#' 
#' Function will download relevant configuration from the DAC Key Vault and use
#' this to create a Python conda environment in which to run the Databricks
#' connection.  
#'
#' @param env development environment to use. One of "prod" (default), "qa", 
#' "test", or "dev".
#' @param token Databricks developer token. If not provided windows
#' credential manager (keyring) is used see \link{set_token} for setting tokens.
#' @param use_cache should any existing cached Azure tokens be used for
#' authentication when retrieving config data from Key Vault.
#' @param install_ml installs ML related Python libraries.
#' @param reset_conda should existing conda environment be deleted first.
#'
#' @return a \pkg{sparklyr} connection object.
#' @export
#'
sparklyr_connect <- function(env = c("prod", "qa", "test", "dev"), 
                             token = NULL,
                             use_cache = TRUE,
                             reset_conda = FALSE,
                             install_ml = FALSE) {
  env <- match.arg(env)
  
  if (is.null(db_token)) db_token <- get_token(env)

  # url used for loading the correct proxy
  dac_url <- sprintf("https://login.microsoftonline.com/%s", get_env("DAC_TENANT"))
  old_config <- httr::set_config(get_proxy_config(dac_url))
  on.exit(httr::set_config(old_config, override = TRUE))
  
  # get configurations
  kv <- key_vault(.env = env, use_cache = use_cache)
  dac_db_host <- kv |> read_secret("dac-db-host")
  dac_db_version <- kv |> read_secret("dac-sparklyr-version")
  dac_cluster_id <- kv |> read_secret("dac-sparklyr-cluster-id")
  
  sc <- .spark_connect(
    db_token, 
    dac_db_host, 
    dac_cluster_id,
    dac_db_version,
    install_ml,
    reset_conda
  )
  
  return(sc)
}


#' Initialise sparklyr and open connection using a config yaml file
#'
#' @param config_yml yaml file with configuration settings.
#' @param env development environment to use from file. One of "prod" (default), 
#' "qa", "test", or "dev".
#' @param use_cache should any existing cached Azure tokens be used for
#' authentication when retrieving config data from Key Vault.
#'
#' @return a \pkg{sparklyr} connection object.
#' @export
#'
sparklyr_cfg_connect <- function(config_yml, 
                                 env = c("prod", "qa", "test", "dev"),
                                 use_cache = TRUE) {
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
  db_token <- cfg |> get_cfg(env, "token", default = NULL)
  if (is.null(db_token)) db_token <- get_token(env)
  
  # url used for loading the correct proxy
  dac_url <- sprintf("https://login.microsoftonline.com/%s", get_env("DAC_TENANT"))
  old_config <- httr::set_config(get_proxy_config(dac_url))
  on.exit(httr::set_config(old_config, override = TRUE))
  
  # get configurations
  kv <- key_vault(.env = env, use_cache = use_cache)
  dac_db_host <- kv |> read_secret("dac-db-host")
  
  sc <- .spark_connect(
    db_token, 
    dac_db_host, 
    cfg |> get_cfg(env, "dac_cluster_id"),
    cfg |> get_cfg(env, "dac_db_version"),
    cfg |> get_cfg(env, "install_ml", default = FALSE),
    cfg |> get_cfg(env, "reset_conda", default = FALSE)
  )
  
  return(sc)
}


#'@keywords internal
.spark_connect <- function(token, 
                           dac_db_host, 
                           dac_cluster_id,
                           dac_db_version,
                           install_ml,
                           reset_conda) {
  
  conda_env <- sprintf("r-sparklyr-databricks-%s", dac_db_version)
  conda_python_path <- get_conda_path(conda_env)
  
  if (is.null(conda_python_path) || reset_conda) {
    # install python environment if needed
    pysparklyr::install_databricks(
      version = dac_db_version,
      envname = conda_env,
      method = "conda",
      install_ml = install_ml,
      new_env = reset_conda,
      as_job = FALSE
    )
    
    conda_python_path <- get_conda_path(conda_env)
  }
  
  # need to set the token and host
  old_env <- set_env_list(
    list(
      DATABRICKS_TOKEN = token,
      DATABRICKS_HOST = sprintf("https://%s", dac_db_host),
      RETICULATE_PYTHON=conda_python_path
    )
  )
  on.exit(set_env_list(old_env))
  
  # should we pass silent = TRUE argument?
  # for some reason need to make the key vault cluster_id into character
  sc <- sparklyr::spark_connect(
    cluster_id = dac_cluster_id,
    method = "databricks_connect",
    envname = dirname(conda_python_path)
  )
  
  return(sc)
}