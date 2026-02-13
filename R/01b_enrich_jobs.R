# R/01b_enrich_jobs.R - Enrich jobs with full descriptions from web pages

library(rvest)
library(httr)
library(dplyr)
library(stringr)

source("R/utils.R")

# ---- Extract full description from Adzuna ----
fetch_full_adzuna_description <- function(url) {
  tryCatch({
    Sys.sleep(1)  # Be polite
    
    page <- read_html(url)
    
    # Extract from ui-adp-content div
    description <- page %>%
      html_element(".ui-adp-content") %>%
      html_text(trim = TRUE)
    
    if (is.na(description) || nchar(description) < 100) {
      return(NA)
    }
    
    # Clean up navigation text
    description <- str_replace(description, ".*back to last search", "")
    
    return(description)
    
  }, error = function(e) {
    log_warning(paste("Failed to fetch Adzuna page:", e$message))
    return(NA)
  })
}

# ---- Extract full description from Reed ----
fetch_full_reed_description <- function(url) {
  tryCatch({
    Sys.sleep(1)  # Be polite
    
    page <- read_html(url)
    
    # Try the specific class we found
    description <- page %>%
      html_element(".job-details-container_container__3DSQL") %>%
      html_text(trim = TRUE)
    
    # If that didn't work, try a fallback
    if (is.na(description)) {
      description <- page %>%
        html_element("[class*='job-details']") %>%
        html_text(trim = TRUE)
    }
    
    if (is.na(description) || nchar(description) < 100) {
      return(NA)
    }
    
    # Clean up navigation text
    description <- str_replace(description, ".*Job details", "")
    
    return(description)
    
  }, error = function(e) {
    log_warning(paste("Failed to fetch Reed page:", e$message))
    return(NA)
  })
}

# ---- Main enrichment function ----
enrich_job_descriptions <- function(jobs, top_n = 50) {
  
  log_info(paste("Enriching top", top_n, "jobs with full descriptions..."))
  log_info("This will take a few minutes (being polite to websites)")
  
  # Only enrich the top N jobs by score
  jobs_to_enrich <- jobs %>%
    arrange(desc(score)) %>%
    head(top_n)
  
  enriched_count <- 0
  failed_count <- 0
  
  for (i in 1:nrow(jobs_to_enrich)) {
    job_id <- jobs_to_enrich$job_id[i]
    source <- jobs_to_enrich$source[i]
    url <- jobs_to_enrich$url[i]
    
    log_info(paste("Enriching", i, "of", top_n, "-", jobs_to_enrich$title[i]))
    
    full_description <- NA
    
    if (source == "adzuna") {
      full_description <- fetch_full_adzuna_description(url)
    } else if (source == "reed") {
      full_description <- fetch_full_reed_description(url)
    }
    
    if (!is.na(full_description)) {
      # Update the description in the main dataframe
      jobs$description[jobs$job_id == job_id] <- full_description
      enriched_count <- enriched_count + 1
    } else {
      failed_count <- failed_count + 1
    }
  }
  
  log_info(paste("Enrichment complete:", enriched_count, "succeeded,", failed_count, "failed"))
  
  return(jobs)
}