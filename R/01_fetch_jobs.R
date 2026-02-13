# test_api.R - Now with secure key loading

library(httr)
library(jsonlite)
library(dotenv)

# Load environment variables from .env
load_dot_env()

# Get keys from environment
ADZUNA_ID <- Sys.getenv("ADZUNA_APP_ID")
ADZUNA_KEY <- Sys.getenv("ADZUNA_APP_KEY")

# Rest stays the same...
url <- paste0(
  "https://api.adzuna.com/v1/api/jobs/gb/search/1",
  "?app_id=", ADZUNA_ID,
  "&app_key=", ADZUNA_KEY,
  "&results_per_page=5",
  "&what=data%20scientist",
  "&where=England"
)

response <- GET(url)

if (status_code(response) == 200) {
  data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  
  cat("Success! Found", data$count, "jobs\n\n")
  
  if (length(data$results) > 0) {
    cat("First job:\n")
    cat("Title:", data$results$title[1], "\n")
    cat("Company:", data$results$company$display_name[1], "\n")
    cat("Location:", data$results$location$display_name[1], "\n")
    cat("URL:", data$results$redirect_url[1], "\n")
  }
} else {
  cat("Error:", status_code(response), "\n")
}