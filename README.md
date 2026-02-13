# DS_Job_Finder
Use Reed &amp; Adzuna APIs to pull data science jobs, then use SQL to filter jobs based on criteria and information in the job description. Later deployed on AWS for batch processing and emailing results each week.


job-hunter/
├── .gitignore
├── .env
├── R/
│   ├── config.R
│   ├── utils.R
│   └── 01_fetch_jobs.R
└── test_api.R  # <- we'll start here
