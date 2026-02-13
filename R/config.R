# R/config.R - User-defined search parameters

# ---- Search parameters ----
search_terms <- list(
  titles = c(
    "data scientist",
    "machine learning engineer",
    "statistician",
    "data science"  # Sometimes better than "data scientist"
  ),
  location = "England",
  salary_min = 40000,
  max_results_per_query = 100,
  posted_within_days = 1
)

# ---- Title filtering ----
# Exclude jobs with these words in the title (applied AFTER fetching)
excluded_title_keywords <- c(
  "quantity surveyor", "surveyor",
  "project manager", "project lead",
  "mechanical", "civil", "structural",
  "architect" # Power BI Architect, AI Architect without DS context
)

# Only include jobs with at least ONE of these in the title
required_title_keywords <- c(
  "data", "scientist", "analyst", "machine learning",
  "statistician", "ml engineer", "analytics"
)

# ---- Scoring weights ----
scoring_weights <- list(
  r_mentioned        = 0.30,
  salary_score       = 0.20,
  remote_mentioned   = 0.20,
  seniority_match    = 0.15,
  sector_match       = 0.10,
  location_match     = 0.05
)

# Rest stays the same...
r_positive_patterns <- c(
  "\\bR\\b.*\\bPython\\b",
  "\\bPython\\b.*\\bR\\b",
  "\\bRStudio\\b",
  "\\btidyverse\\b",
  "\\bggplot\\b",
  "\\bshiny\\b",
  "\\bdplyr\\b",
  "R/Python",
  "R or Python",
  "R and Python"
)

r_false_positive_patterns <- c(
  "\\bR&D\\b",
  "\\bR & D\\b",
  "\\bR&I\\b"
)

preferred_sectors <- c(
  "environment", "conservation", "ecology", "climate",
  "health", "pharma", "medical", "clinical",
  "consulting", "analytics"
)