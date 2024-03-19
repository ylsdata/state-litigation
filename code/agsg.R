library(tidyverse)
library(tidycensus)
library(readxl)

source("code/macros.R")
source("code/functions.R")

# Load
raw <- read_xlsx(WIRZ_RAW, 
                 sheet = "State Analysis",
                 skip = 1,
                 na = c("", "N/A")) |>
  filter(!is.na(Abbreviation))

# Tidy and Munge
df_sgag <- raw |>
  rename(
    sg_experience = `Years Experience (when entering SG role)`,
    sg_t14_grad = `Top Law School`,
    sg_clerk_scotus = `SCOTUS Clerk`,
    sg_clerk_dc = `D.C. Cir. Clerk`,
    ag_num = `# AGs since 2000`,
    ag_higher_office = `% former AGs seek higher office`
  ) |>
  mutate(
    ag_tenure = 23/ag_num,
    ag_higher_office = ifelse(ag_higher_office > 1, 1, ag_higher_office)
  ) |>
  select(Abbreviation, starts_with("sg_"), starts_with("ag_"))


# Combine, Add State Code, and Save --------------------------------------------
df_out <- df_sgag |>
  mutate(Abbreviation = tolower(Abbreviation)) |>
  add_state_fips(key_var = "Abbreviation",
                 key_type = "postal",
                 drop_key = TRUE) |>
  select(state_code, everything())

write_csv(df_out, AGSG_FILE)
