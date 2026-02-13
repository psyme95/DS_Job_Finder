# R/02_process_jobs.R - Clean, deduplicate, score, and rank jobs

library(dplyr)
library(stringr)

source("R/config.R")
source("R/utils.R")

# ---- Deduplication ----
deduplicate_jobs <- function(df) {
  before <- nrow(df)
  
  # Same job appears on multiple boards
  df <- df %>%
    mutate(
      dedup_key = paste(
        str_to_lower(str_squish(title)),
        str_to_lower(str_squish(company))
      )
    ) %>%
    arrange(desc(!is.na(salary_min)), desc(date_posted)) %>%
    distinct(dedup_key, .keep_all = TRUE) %>%
    select(-dedup_key)
  
  log_info(paste("Deduplicated:", before, "->", nrow(df), "jobs"))
  return(df)
}

# ---- Title filtering ----
filter_by_title <- function(df) {
  before <- nrow(df)
  
  df <- df %>%
    mutate(title_lower = str_to_lower(title))
  
  # Exclude jobs with irrelevant keywords
  for (keyword in excluded_title_keywords) {
    df <- df %>%
      filter(!str_detect(title_lower, keyword))
  }
  
  # Require at least one relevant keyword
  df <- df %>%
    filter(str_detect(title_lower, paste(required_title_keywords, collapse = "|")))
  
  df <- df %>%
    select(-title_lower)
  
  log_info(paste("Title filtering:", before, "->", nrow(df), "jobs"))
  return(df)
}

# ---- R language detection ----
detect_r_language <- function(description) {
  if (is.na(description)) return(FALSE)
  
  desc_lower <- str_to_lower(description)
  
  # Remove common false positives
  desc_clean <- str_replace_all(desc_lower, "\\br&[di]\\b|\\br & [di]\\b|react|redux", "")
  
  # STRONG signals - if any of these, definitely R
  strong_signals <- c(
    "rstudio", "r studio",
    "tidyverse", "dplyr", "ggplot", "ggplot2",
    "shiny\\b", "r shiny",
    "\\bcran\\b",
    "tidymodels",
    "rmarkdown", "r markdown",
    "\\br packages\\b"
  )
  
  if (any(str_detect(desc_clean, strong_signals))) {
    return(TRUE)
  }
  
  # MEDIUM signals - R mentioned alongside Python or in statistical context
  # Be very specific here
  medium_signals <- c(
    "\\br/python\\b", "\\bpython/r\\b",
    "\\br or python\\b", "\\bpython or r\\b",
    "\\br and python\\b", "\\bpython and r\\b",
    "\\br, python\\b", "\\bpython, r\\b",
    "languages.{0,30}(r|python).{0,30}(python|r)",  # "languages: R, Python" etc
    "proficient.{0,30}\\br\\b.{0,30}python",
    "proficient.{0,30}python.{0,30}\\br\\b"
  )
  
  if (any(str_detect(desc_clean, medium_signals))) {
    return(TRUE)
  }
  
  # Check for standalone R in very specific contexts
  # Only match "R" when it's clearly about the language
  specific_r_contexts <- c(
    "experience.{0,20}\\br\\b",
    "\\br\\b.{0,20}programming",
    "programming.{0,20}\\br\\b",
    "statistical.{0,20}\\br\\b",
    "\\br\\b.{0,20}statistical",
    "using \\br\\b",
    "knowledge of \\br\\b",
    "proficiency in \\br\\b",
    "skills in \\br\\b"
  )
  
  # But NOT if it's clearly Python-only
  python_only_phrases <- c(
    "python required", "python essential", "python developer",
    "python engineer", "must.{0,20}python", "python.{0,20}must"
  )
  
  is_python_only <- any(str_detect(desc_clean, python_only_phrases))
  
  if (any(str_detect(desc_clean, specific_r_contexts)) && !is_python_only) {
    return(TRUE)
  }
  
  return(FALSE)
}

# ---- Scoring function ----
score_job <- function(row) {
  scores <- list()
  desc <- str_to_lower(row$description %||% "")
  title <- str_to_lower(row$title %||% "")
  location_text <- str_to_lower(row$location %||% "")
  
  # 1. R mentioned (0 or 1)
  scores$r_mentioned <- as.numeric(detect_r_language(row$description))
  
  # 2. Salary score (normalised 0-1)
  salary <- mean(c(row$salary_min, row$salary_max), na.rm = TRUE)
  if (is.na(salary)) {
    scores$salary_score <- 0.3  # neutral if unknown
  } else {
    # Scale: 40k = 0, 80k+ = 1
    scores$salary_score <- min(max((salary - 40000) / 40000, 0), 1)
  }
  
  # 3. Remote/hybrid mentioned (0 or 1)
  scores$remote_mentioned <- as.numeric(
    str_detect(desc, "remote|hybrid|work from home|flexible working")
  )
  
  # 4. Seniority match (0 or 1)
  scores$seniority_match <- as.numeric(
    str_detect(title, "senior|lead|principal|staff")
  )
  
  # 5. Sector match (0 or 1)
  scores$sector_match <- as.numeric(
    any(str_detect(desc, preferred_sectors))
  )
  
  # 6. Location match (0 or 1)
  scores$location_match <- as.numeric(
    str_detect(location_text, "remote|home|london|southampton|england")
  )
  
  # Weighted total
  total <- sum(
    scores$r_mentioned       * scoring_weights$r_mentioned,
    scores$salary_score      * scoring_weights$salary_score,
    scores$remote_mentioned  * scoring_weights$remote_mentioned,
    scores$seniority_match   * scoring_weights$seniority_match,
    scores$sector_match      * scoring_weights$sector_match,
    scores$location_match    * scoring_weights$location_match
  )
  
  return(round(total * 100))  # Score out of 100
}

# ---- Main processing function ----
process_jobs <- function(raw_jobs) {
  
  if (nrow(raw_jobs) == 0) {
    log_warning("No jobs to process")
    return(tibble())
  }
  
  # Clean
  jobs <- raw_jobs %>%
    filter(!is.na(title)) %>%
    mutate(
      title = str_squish(title),
      company = str_squish(company),
      description = str_squish(description)
    )
  
  log_info(paste("Cleaned", nrow(jobs), "jobs"))
  
  # Deduplicate
  jobs <- deduplicate_jobs(jobs)
  
  # Filter by title relevance
  jobs <- filter_by_title(jobs)
  
  # Score each job
  log_info("Scoring jobs...")
  jobs$score <- sapply(1:nrow(jobs), function(i) score_job(jobs[i, ]))
  
  # Flag R acceptability
  jobs$r_acceptable <- sapply(jobs$description, detect_r_language)
  
  # Rank
  jobs <- jobs %>%
    arrange(desc(score))
  
  log_info(paste("Processed", nrow(jobs), "jobs"))
  log_info(paste("Top score:", max(jobs$score, na.rm = TRUE)))
  log_info(paste("R-acceptable jobs:", sum(jobs$r_acceptable)))
  
  return(jobs)
}