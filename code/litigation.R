library(tidyverse)
library(tidycensus)
library(readxl)

source("code/macros.R")
source("code/functions.R")


# Load
raw <- read_xlsx(WIRZ_RAW, 
                 sheet = "State Analysis (Annual Data)",
                 skip = 1,
                 na = c("", "N/A")) |>
  filter(!is.na(Abbreviation)) |>
  select(-Party, -State)

# As Lead  
df1 <- raw[, 1:24] 
names(df1) <- gsub("\\..+$", "", names(df1))
df1 <- df1 |>
  pivot_longer(-Abbreviation,
               values_to = "n_litigate",
               names_to = "year")

# As Lead, Initial, and/or Intervening
df2 <- raw[, c(1, 25:ncol(raw))] 
names(df2) <- gsub("\\..+$", "", names(df2))
df2 <- df2 |>
  pivot_longer(-Abbreviation,
               values_to = "n_litigate2",
               names_to = "year")

# Combine, Add State Code, Save
df_litigation <- left_join(df1, df2) |>
  mutate(key = tolower(Abbreviation)) |>
  add_state_fips(key_var = "key",
                 key_type = "postal",
                 drop_key = TRUE) |>
  rename(state = Abbreviation) |>
  select(state_code, state, year, everything())

write_csv(df_litigation, DV_FILE)
