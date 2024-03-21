library(tidyverse)

source("code/macros.R")
source("code/functions.R")


# Download data files
years_remaining <- to_download(RAW_DATA_DIR, POP_YEARS, pattern = "pop")
if (!length(years_remaining) == 0) {
  years_remaining |>
    map(~download_pop(decade = .x, data_dir = RAW_DATA_DIR, docs_dir = DOC_DIR))
}

# Munge
raw_files <- list.files(RAW_DATA_DIR, pattern = "pop", full.names = TRUE)
df <- raw_files |>
  map(munge_pop) |>
  list_rbind()

# Save
write_csv(df, POP_FILE)
