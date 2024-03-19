library(tidyverse)
source("macros.R")
source("fjc_functions.R")


# Ingest
raw <- read_csv("data/raw/federal-judicial-service.csv")

# Munge USCA data
df_usca <- raw |>
  fjc_judge_party_infer() |>
  filter(`Court Type` == 'U.S. Court of Appeals') |>
  fjc_service_dates(current_judges_as = "missing") |>
  fjc_service_frac() |>
  mutate(
    court_num = fjc_circuit_nums(`Court Name`),
    party = fjc_tidy_party(party)
  ) |>
  fjc_parse_seatid(court_num, `Seat ID`) 
  
# Create longer-form dataset of judge entrances and exits (churn)
df_judge_churn <- df_usca |>
  mutate(end_date = as.Date(end_date)) |>
  select(`Judge Name`, president, start_date, end_date, court_num, seat_num,
         seat_order, party, seat_new) |>
  pivot_longer(
    cols = c(start_date, end_date),
    names_to = "event",
    values_to = "date"
  ) |>
  mutate(
    event = case_when(
      event == "start_date" ~ 'enter',
      event == "end_date" ~ 'exit'
    )
  )

# Calculate partisan balance of power at each churn event for each circuit
df_bop <- map(
  unique(df_judge_churn$court_num),
  ~fjc_partisan_churn(
    filter(df_judge_churn, court_num == .x)
  ) 
) |>
  list_rbind()

# Expand and fill for each day
df_daily <- df_bop |>
  select(date, court_num, 
         starts_with("num"), seats_filled, starts_with("frac")) |>
  complete(nesting(court_num), date = seq(min(date), max(date), by = "day")) |>
  group_by(court_num) |>
  fill(starts_with("num"), seats_filled, starts_with("frac")) |>
  ungroup()

# Aggregate to circuit-year
df_yearly <- df_daily |>
  mutate(year  = year(date)) |>
  group_by(court_num, year) |>
  summarize(
    avg_dem_share = mean(frac_dem),
    avg_rep_share = mean(frac_rep)
  ) |>
  ungroup() |>
  rename(circuit = court_num) |>
  mutate(circuit = str_pad(circuit, 2, pad = "0"))

# Save
df_yearly |>
  write_csv(FJC_FILE)


# Judgeships over time
# circuits <- map_vec(c(as.character(1:11), "dc", "fc"), fjc_num_to_rank)
# df_list <- map(circuits, fjc_judgeships) 
# df_judges <- list_rbind(df_list)
