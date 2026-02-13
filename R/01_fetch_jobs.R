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

# ---- Adzuna API with pagination ----
fetch_adzuna <- function(search_term, location, salary_min, max_results = 100) {
  
  log_info(paste("Fetching Adzuna jobs for:", search_term))
  
  all_results <- tibble()
  results_per_page <- 50  # API max
  pages_needed <- ceiling(max_results / results_per_page)
  
  for (page in 1:pages_needed) {
    
    url <- paste0(
      "https://api.adzuna.com/v1/api/jobs/gb/search/", page,  # page number in URL
      "?app_id=", adzuna_id,
      "&app_key=", adzuna_key,
      "&results_per_page=", results_per_page,
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
      log_warning(paste("Adzuna page", page, "returned status:", status_code(response)))
      break
    }
    
    data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
    
    if (length(data$results) == 0) {
      log_info(paste("No more Adzuna results at page", page))
      break
    }
    
    page_results <- tibble(
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
    
    all_results <- bind_rows(all_results, page_results)
    
    # Be polite - wait between pages
    if (page < pages_needed) Sys.sleep(1)
  }
  
  log_info(paste("Fetched", nrow(all_results), "Adzuna results across", page, "pages"))
  return(all_results)
}

# ---- Reed API with pagination ----
fetch_reed <- function(search_term, location, salary_min, max_results = 100) {
  
  log_info(paste("Fetching Reed jobs for:", search_term))
  
  all_results <- tibble()
  results_per_page <- 100  # Reed allows up to 100
  pages_needed <- ceiling(max_results / results_per_page)
  
  for (page in 0:(pages_needed - 1)) {  # Reed uses 0-indexed pages
    
    skip <- page * results_per_page
    
    url <- paste0(
      "https://www.reed.co.uk/api/1.0/search",
      "?keywords=", URLencode(search_term),
      "&locationName=", URLencode(location),
      "&minimumSalary=", salary_min,
      "&resultsToSkip=", skip,
      "&resultsToTake=", results_per_page
    )
    
    response <- tryCatch(
      GET(url, authenticate(reed_key, ""), timeout(30)),
      error = function(e) {
        log_error(paste("Reed API error:", e$message))
        return(NULL)
      }
    )
    
    if (is.null(response) || status_code(response) != 200) {
      log_warning(paste("Reed page", page + 1, "returned status:", status_code(response)))
      break
    }
    
    data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
    
    if (length(data$results) == 0) {
      log_info(paste("No more Reed results at page", page + 1))
      break
    }
    
    page_results <- tibble(
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
    
    all_results <- bind_rows(all_results, page_results)
    
    # Be polite
    if (page < pages_needed - 1) Sys.sleep(1)
  }
  
  log_info(paste("Fetched", nrow(all_results), "Reed results"))
  return(all_results)
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
