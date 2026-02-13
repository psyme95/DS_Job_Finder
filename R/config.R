# R/config.R - User-defined search parameters

# ---- Search parameters ----
search_terms <- list(
  titles = c("data scientist", "data analyst"),
  location = "England",
  salary_min = 40000,
  max_results_per_query = 20,
  posted_within_days = 7
)

# ---- Scoring weights ----
scoring_weights <- list(
  r_mentioned        = 0.70,
  salary_score       = 0.20,
  remote_mentioned   = 0.10,
  seniority_match    = 0.00,
  sector_match       = 0.00,
  location_match     = 0.00
)

# ---- R detection patterns ----
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
  "R and Python",
  "Python or R",
  "Python and R"
)

r_false_positive_patterns <- c(
  "\\bR&D\\b",
  "\\bR & D\\b"
)

# ---- Preferred sectors ----
preferred_sectors <- c(
  "environment", "conservation", "ecology", "climate",
  "health", "pharma", "medical", "clinical",
  "consulting", "analytics"
)
