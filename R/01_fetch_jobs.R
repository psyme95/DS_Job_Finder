# R/01_fetch_jobs.R - Fetch jobs from Adzuna and Reed APIs

library(httr)
library(jsonlite)
library(dplyr)
library(dotenv)

source("R/config.R")
source("R/utils.R")

# Load API keys
load_dot_env()
adzuna_id  <- Sys.getenv("ADZUNA_APP_ID")
adzuna_key <- Sys.getenv("ADZUNA_APP_KEY")
reed_key   <- Sys.getenv("REED_API_KEY")

# ---- Adzuna API ----
fetch_adzuna <- function(search_term, location, salary_min, max_results = 20) {
  
  log_info(paste("Fetching Adzuna jobs for:", search_term))
  
  url <- paste0(
    "https://api.adzuna.com/v1/api/jobs/gb/search/1",
    "?app_id=", adzuna_id,
    "&app_key=", adzuna_key,
    "&results_per_page=", max_results,
    "&what=", URLencode(search_term),
    "&where=", URLencode(location),
    "&salary_min=", salary_min,
    "&max_days_old=", search_terms$posted_within_days
  )
  
  response <- tryCatch(
    GET(url, timeout(30)),
    error = function(e) {
      log_error(paste("Adzuna API error:", e$message))
      return(NULL)
    }
  )
  
  if (is.null(response) || status_code(response) != 200) {
    log_warning(paste("Adzuna returned status:", status_code(response)))
    return(tibble())
  }
  
  data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  
  if (length(data$results) == 0) {
    log_info("No Adzuna results for this query")
    return(tibble())
  }
  
  # Standardise to common schema
  results <- tibble(
    source         = "adzuna",
    job_id         = as.character(data$results$id),
    title          = data$results$title,
    company        = data$results$company$display_name,
    location       = data$results$location$display_name,
    description    = data$results$description,
    salary_min     = data$results$salary_min %||% NA_real_,
    salary_max     = data$results$salary_max %||% NA_real_,
    url            = data$results$redirect_url,
    date_posted    = as.Date(data$results$created),
    date_fetched   = Sys.Date()
  )
  
  log_info(paste("Fetched", nrow(results), "Adzuna results"))
  return(results)
}


# ---- Reed API ----
fetch_reed <- function(search_term, location, salary_min, max_results = 20) {
  
  log_info(paste("Fetching Reed jobs for:", search_term))
  
  url <- paste0(
    "https://www.reed.co.uk/api/1.0/search",
    "?keywords=", URLencode(search_term),
    "&locationName=", URLencode(location),
    "&minimumSalary=", salary_min,
    "&resultsToTake=", max_results
  )
  
  response <- tryCatch(
    GET(url, authenticate(reed_key, ""), timeout(30)),
    error = function(e) {
      log_error(paste("Reed API error:", e$message))
      return(NULL)
    }
  )
  
  if (is.null(response) || status_code(response) != 200) {
    log_warning(paste("Reed returned status:", status_code(response)))
    return(tibble())
  }
  
  data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  
  if (length(data$results) == 0) {
    log_info("No Reed results for this query")
    return(tibble())
  }
  
  results <- tibble(
    source         = "reed",
    job_id         = as.character(data$results$jobId),
    title          = data$results$jobTitle,
    company        = data$results$employerName,
    location       = data$results$locationName,
    description    = data$results$jobDescription,
    salary_min     = data$results$minimumSalary %||% NA_real_,
    salary_max     = data$results$maximumSalary %||% NA_real_,
    url            = data$results$jobUrl,
    date_posted    = as.Date(data$results$date, format = "%d/%m/%Y"),
    date_fetched   = Sys.Date()
  )
  
  log_info(paste("Fetched", nrow(results), "Reed results"))
  return(results)
}

# ---- Main fetch function ----
fetch_all_jobs <- function() {
  
  all_jobs <- tibble()
  
  for (term in search_terms$titles) {
    adzuna_results <- fetch_adzuna(
      term,
      search_terms$location,
      search_terms$salary_min,
      search_terms$max_results_per_query
    )
    
    reed_results <- fetch_reed(
      term,
      search_terms$location,
      search_terms$salary_min,
      search_terms$max_results_per_query
    )
    
    all_jobs <- bind_rows(all_jobs, adzuna_results, reed_results)
    
    # Be polite to APIs
    Sys.sleep(1)
  }
  
  log_info(paste("Total raw jobs fetched:", nrow(all_jobs)))
  
  # Validate
  if (nrow(all_jobs) > 0) {
    validate_fetched_data(all_jobs)
  }
  
  return(all_jobs)
}
