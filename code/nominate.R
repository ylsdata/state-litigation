library(tidyverse)

source("code/macros.R")
source("code/functions.R")


# Load datasets
df_xwalk <- map(CONGRESS_START:CONGRESS_STOP, ~us_congress_years(.x, "df")) |>
  list_rbind()
raw <- read_csv(NOMINATE_RAW) 

# Munge
df <- raw |>
  filter(congress >= 106) |>
  mutate( #drop ~1st 2 weeks of trump pres from 117 Congress
    drop_trump_117 = 
      case_when(
        congress == 117 & grepl("TRUMP", bioname) ~ 1,
        .default = 0
      )
  ) |>
  filter(drop_trump_117 == 0) |>
  mutate(
    state_abbrev = tolower(state_abbrev),
    chamber = case_when(
      chamber %in% c('House', 'Senate') ~ "cngr",
      chamber == 'President' ~ 'pres'
    )
  ) |>
  group_by(chamber, congress, state_abbrev) |>
  summarize(nominate_p50 = median(nominate_dim1, na.rm = TRUE),
            nominate_avg = mean(nominate_dim1, na.rm = TRUE)) |>
  pivot_wider(id_cols = c(congress, state_abbrev),
              names_from = 'chamber',
              names_glue = "{.value}_{chamber}",
              values_from = starts_with("nominate"))

# Split by chamber and then recombine to get pres nominate for all congresses 
df_cong <- df |>
  filter(state_abbrev != 'usa') |>
  select(-ends_with('pres'))
df_pres <- df |>
  filter(!is.na(nominate_p50_pres)) |>
  select(-state_abbrev, -ends_with('cngr'))
df2 <- left_join(df_cong, df_pres)

# Convert from state-congresses to state-years and add fips code
df_yearly <- left_join(df2, df_xwalk, relationship = 'many-to-many') |>
  add_state_fips(key_var = 'state_abbrev', key_type = "postal")

# Tidy output
df_out <- df_yearly |>
  ungroup() |>
  select(state_code, congress, year, nominate_p50_pres, nominate_p50_cngr,
         nominate_avg_pres, nominate_avg_cngr) 

# Save
write_csv(df_out, NOMINATE_MUNGED)