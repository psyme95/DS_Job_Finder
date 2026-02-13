# test_process.R - Test fetching + processing

source("R/01_fetch_jobs.R")
source("R/02_process_jobs.R")

# Fetch
log_info("=== FETCHING ===")
raw_jobs <- fetch_all_jobs()

# Process
log_info("\n=== PROCESSING ===")
processed_jobs <- process_jobs(raw_jobs)

# Show results
cat("\n=== RESULTS ===\n")
cat("Total jobs:", nrow(processed_jobs), "\n")
cat("R-acceptable:", sum(processed_jobs$r_acceptable), "\n")
cat("Score range:", min(processed_jobs$score), "-", max(processed_jobs$score), "\n")

cat("\n=== TOP 5 R-ACCEPTABLE JOBS ===\n")
top_r_jobs <- processed_jobs %>%
  filter(r_acceptable == TRUE) %>%
  select(score, title, company, location, salary_min, salary_max, url) %>%
  head(5)

print(top_r_jobs)

cat("\n=== TOP 5 ALL JOBS ===\n")
top_all <- processed_jobs %>%
  select(score, title, company, r_acceptable, salary_min) %>%
  head(5)

print(top_all)

# Add at the end of test_process.R

cat("\n=== MANUAL INSPECTION ===\n")

# Let's look at 5 random jobs and see why they weren't flagged as R
set.seed(123)
sample_jobs <- processed_jobs %>%
  filter(r_acceptable == FALSE) %>%
  sample_n(min(5, n())) %>%
  select(title, company, description)

for (i in 1:nrow(sample_jobs)) {
  cat("\n--- JOB", i, "---\n")
  cat("Title:", sample_jobs$title[i], "\n")
  cat("Company:", sample_jobs$company[i], "\n")
  cat("Description:", substr(sample_jobs$description[i], 1, 500), "...\n")
  cat("Contains 'R'?:", str_detect(str_to_lower(sample_jobs$description[i]), "\\br\\b"), "\n")
  cat("Contains 'Python'?:", str_detect(str_to_lower(sample_jobs$description[i]), "python"), "\n")
}

# Also check the 2 that WERE flagged
cat("\n=== THE 2 R-ACCEPTABLE JOBS ===\n")
r_jobs <- processed_jobs %>%
  filter(r_acceptable == TRUE) %>%
  select(title, company, description)

for (i in 1:nrow(r_jobs)) {
  cat("\n--- R JOB", i, "---\n")
  cat("Title:", r_jobs$title[i], "\n")
  cat("Company:", r_jobs$company[i], "\n")
  cat("Description:", substr(r_jobs$description[i], 1, 500), "...\n")
}
