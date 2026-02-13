# test_fetch.R - Test the new structured code

source("R/01_fetch_jobs.R")

# Fetch jobs
jobs <- fetch_all_jobs()

# Show summary
cat("\n=== SUMMARY ===\n")
cat("Total jobs:", nrow(jobs), "\n")
cat("From Adzuna:", sum(jobs$source == "adzuna"), "\n")
cat("From Reed:", sum(jobs$source == "reed"), "\n")
cat("\n=== FIRST 3 JOBS ===\n")
print(jobs[1:min(3, nrow(jobs)), c("title", "company", "location", "salary_min")])


