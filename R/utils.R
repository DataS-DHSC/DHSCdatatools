
#'@keywords internal
get_env <- function(x) {
  error_string <- paste(
    "Could not find value for `%s` in .Renviron, please",
    "make sure key=value pair exists and that .Renviron file is loaded."
  )
  
  val <- Sys.getenv(x)
  if (val == "") stop(sprintf(error_string, x))
  
  return(val)
}


#'@keywords internal
set_env_list <- function(x) {
  vals <- as.list(Sys.getenv(names(x)))
  do.call(Sys.setenv, x)
  invisible(vals)
}


#'@keywords internal
read_secret <- function(kv, secret_name) {
  kv$secrets$get(secret_name)$value |> as.character()
}


#'@keywords internal
get_conda_path <- function(conda_env) {
  if (is.null(conda_env)) return(NULL)
  
  conda_environments <- reticulate::conda_list()
  idx <- conda_environments$name == conda_env
  
  if (!any(idx)) return(NULL)
  return(conda_environments$python[idx])
}


#'@keywords internal
get_cfg <- function(cfg, env, val_name, default) {
  error_string <- paste(
    "Could not find configuration value `%s` for '%s' environment in file '%s'."
  )
  
  val <- cfg[[env]][[val_name]]
  if (is.null(val)) {
    if (missing(default)) {
      stop(
        sprintf(error_string, val_name, env, cfg[["filename"]])
      )  
    }
    
    val <- default
  }
  
  return(val)
}