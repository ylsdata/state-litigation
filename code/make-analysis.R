library(tidyverse)
library(tidycensus)
library(zoo)

source("code/macros.R")

# Load files
dv <- read_csv(DV_FILE)
rhs <- read_csv(ALL_RHS_FILE)
state_xwalk <- fips_codes |>
  select(state_code, state_name, state) |>
  distinct(.keep_all = TRUE)

# Combine
df <- dv |>
  select(-state) |>
  left_join(rhs)

# Tidy
df <- df |>
  select(-ends_with("fte_emp"), -ends_with("tot_pay"), -starts_with("jud2"),
         -state) |>
  rename(
    judicial_fte_share = jud_emp_share,
    judicial_pay_share = jud_pay_share,
    circ_dem_share = avg_dem_share,
    circ_rep_share = avg_rep_share
  ) |> 
  left_join(state_xwalk) |>
  select(state_code, state_name, state, year, circuit, starts_with("n_"), 
         starts_with("judicial"), starts_with("nominate"), everything()) |>
  select(-circ_dem_share)


# Variable transformations and missing value imputations
df_out <- df |>
  mutate(
    across(
      c(judicial_fte_share, judicial_pay_share, circ_rep_share,
        sg_t14_grad, sg_clerk_scotus, sg_clerk_dc, ag_higher_office),
      ~.x * 100),
    sg_clerk = sg_clerk_scotus + sg_clerk_dc,
    across(
      c(pop_total, sg_experience, ag_tenure),
      log,
      .names = "ln_{.col}"
    ),
    across(
      starts_with("nominate"),
      ~(.x + 1)/2 * 100
    ),
    admin = case_when(
      year %in% 2001:2008 ~ "Bush, Jr.",
      year %in% 2009:2016 ~ "Obama",
      year %in% 2017:2020 ~ "Trump",
      year >= 2021 ~ "Biden"
    ),
    dem_pres = ifelse(admin %in% c("Biden", "Obama"), 1, 0),
    trumpian = ifelse(year > 2016, 1, 0)
  ) |>
  arrange(state_code, year) |>
  mutate(
    nominate_p50_pres2 = nominate_p50_pres,
    nominate_avg_pres2 = nominate_avg_pres
  ) |>
  fill(nominate_p50_pres2, nominate_avg_pres2) 


df_out <- df_out |>
  mutate(
    nominate_p50_cngr2 = nominate_p50_cngr,
    nominate_avg_cngr2 = nominate_avg_cngr,
    judicial_fte_share2 = judicial_fte_share,
    judicial_pay_share2 = judicial_pay_share
  ) 

df_out <- df_out |>
  filter(state_code != "11") |>
  bind_rows(df_out |>
              filter(state_code == "11") |>
              fill(nominate_p50_cngr2, nominate_avg_cngr2,
                   .direction = "downup")) |>
  group_by(state_code) |>
  mutate(
    across(c(judicial_fte_share2, judicial_pay_share2), 
           ~ifelse(state_code != "11", na.spline(.x), .x)
    )
  ) |>
  ungroup()
  

# Missingness check
df_m <- df_out |>
  select(-state_code, -state) |>
  group_by(state_name) |>
  miss_var_summary()
  
# Save
df_out |>
  distinct() |>
  write_csv(ANALYSIS_FILE, na = "")
