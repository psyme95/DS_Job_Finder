# test_with_enrichment.R - Full pipeline with description enrichment

source("R/01_fetch_jobs.R")
source("R/02_process_jobs.R")
source("R/01b_enrich_jobs.R")

log_info("=== STAGE 1: FETCH ===")
raw_jobs <- fetch_all_jobs()

log_info("\n=== STAGE 2: INITIAL PROCESSING ===")
processed_jobs <- process_jobs(raw_jobs)

log_info("\n=== STAGE 3: ENRICH TOP JOBS ===")
# Enrich top 30 jobs (adjust this number based on patience)
enriched_jobs <- enrich_job_descriptions(processed_jobs, top_n = 30)

log_info("\n=== STAGE 4: RE-SCORE WITH FULL DESCRIPTIONS ===")
# Re-score the enriched jobs
enriched_jobs$score <- sapply(1:nrow(enriched_jobs), function(i) score_job(enriched_jobs[i, ]))
enriched_jobs$r_acceptable <- sapply(enriched_jobs$description, detect_r_language)

# Re-sort by new scores
enriched_jobs <- enriched_jobs %>%
  arrange(desc(score))

# Show results
cat("\n=== RESULTS AFTER ENRICHMENT ===\n")
cat("Total jobs:", nrow(enriched_jobs), "\n")
cat("R-acceptable:", sum(enriched_jobs$r_acceptable), "\n")
cat("Score range:", min(enriched_jobs$score), "-", max(enriched_jobs$score), "\n")

cat("\n=== TOP 10 R-ACCEPTABLE JOBS ===\n")
top_r_jobs <- enriched_jobs %>%
  filter(r_acceptable == TRUE) %>%
  select(score, title, company, location, salary_min, salary_max, url) %>%
  head(10)

print(top_r_jobs, n = 10)

cat("\n=== TOP 10 ALL JOBS ===\n")
top_all <- enriched_jobs %>%
  select(score, title, company, r_acceptable, salary_min, url) %>%
  head(10)

print(top_all, n = 10)