library(tidyverse)
library(tidycensus)

source("macros.R")
source("functions.R")


# Download
years_remaining <- to_download(RAW_DATA_DIR, YEARS)
if (length(years_remaining) > 0) {
  years_remaining |>
    map(~download_aspep(year = .x, data_dir = RAW_DATA_DIR))
}
  
# Combine
raw_files <- list.files(RAW_DATA_DIR, pattern = "aspep", full.names = TRUE)
df <- raw_files |>
  map(ingest_aspep) |>
  list_rbind()


# Tidy
df_tidy <- df |>
  select(state_code, year, govt_function, fte_emp, tot_pay) |>
  filter(
    !is.na(state_code) & grepl("^total|^other gov|^judicial|^central gov|^central adm", 
                               govt_function)
  ) |>
  mutate(
    govt_function =
      case_when(
        grepl("total", govt_function) ~ "total",
        grepl("other|central", govt_function) ~ "other",
        grepl("judicial", govt_function) ~ "judicial"
      )
  ) |>
  pivot_wider(
    id_cols = c(state_code, year),
              names_from = govt_function,
              names_glue = "{govt_function}_{.value}",
              values_from = c(fte_emp, tot_pay)
  ) |>
  mutate(
    jud_emp_share = judicial_fte_emp/total_fte_emp,
    jud2_emp_share = (judicial_fte_emp + other_fte_emp)/total_fte_emp,
    jud_pay_share = judicial_tot_pay/total_tot_pay,
    jud2_pay_share = (judicial_tot_pay + other_tot_pay)/total_tot_pay,
  )

write_csv(df_tidy, ASPEP_FILE)
