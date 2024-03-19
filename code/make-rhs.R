library(tidyverse)
library(tidycensus)
library(readxl)
library(naniar)

source("code/functions.R")
source("code/macros.R")

# Set common dimensions for database
yrange <- 2001:2024
includes <- c("year", "state_code", "jud_emp_share", "jud_pay_share",
              "pop_total", "nominate_p50_pres", "nominate_p50_cngr",
              "avg_rep_share")

# Compile state-year datasets
df_list <- map(c(ASPEP_FILE, POP_FILE, NOMINATE_MUNGED), read_csv)
df <- full_join(df_list[[1]], df_list[[2]]) |>
  full_join(df_list[[3]]) |>
  filter(year %in% yrange & state_code < 60) |>
  arrange(state_code, year) 

df_m <- df |>
  select(any_of(includes)) |>
  group_by(state_code) |>
  miss_var_summary()


# Add circuits, fjc data
df_state_circs <- read_xlsx(WIRZ_RAW, sheet = "State Analysis", skip = 1) |>
  select(Abbreviation, `Federal Circuit #`) |>
  mutate(
    key = tolower(Abbreviation),
    circuit = str_pad(`Federal Circuit #`, 2, pad = "0")
  ) |>
  select(key, circuit) |>
  add_state_fips(key_var = "key",
                 key_type = "postal",
                 drop_key = TRUE)
fjc <- read_csv(FJC_FILE) |>
  left_join(df_state_circs)

df_m <- fjc |>
  select(any_of(includes)) |>
  filter(year %in% yrange) |>
  group_by(state_code) |>
  miss_var_summary()

df <- df |>
  left_join(fjc)

# Add AG/SG Data
df_agsg <- read_csv(AGSG_FILE) 
df_m <- df_agsg |>
  select(state_code, starts_with("ag_"), starts_with("sg_")) |>
  group_by(state_code) |>
  miss_var_summary()

df <- left_join(df, df_agsg)

# Save
write_csv(df, ALL_RHS_FILE)
