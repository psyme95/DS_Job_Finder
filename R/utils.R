# R/utils.R - Helper functions for logging and validation

library(glue)

# ---- Simple logging ----
log_info    <- function(msg) message(glue("[{Sys.time()}] INFO: {msg}"))
log_warning <- function(msg) message(glue("[{Sys.time()}] WARNING: {msg}"))
log_error   <- function(msg) message(glue("[{Sys.time()}] ERROR: {msg}"))

# ---- Null coalescing operator ----
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# ---- Data validation ----
validate_fetched_data <- function(df) {
  expected_cols <- c("source", "job_id", "title", "company",
                     "location", "description", "salary_min",
                     "salary_max", "url", "date_posted", "date_fetched")
  
  missing_cols <- setdiff(expected_cols, names(df))
  if (length(missing_cols) > 0) {
    log_error(paste("Missing columns:", paste(missing_cols, collapse = ", ")))
    stop("Data validation failed: missing columns")
  }
  
  # Check critical fields
  null_titles <- sum(is.na(df$title))
  if (null_titles > 0) {
    log_warning(paste(null_titles, "jobs have missing titles"))
  }
  
  log_info("Data validation passed")
  return(invisible(TRUE))
}
