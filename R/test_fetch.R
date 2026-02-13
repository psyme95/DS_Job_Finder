# test_fetch.R - Test the new structured code

source("R/01_fetch_jobs.R")

# Fetch jobs
jobs <- fetch_all_jobs()

# Show first 3 jobs
print(jobs[1:min(3, nrow(jobs)), c("title", "company", "location", "salary_min")])


