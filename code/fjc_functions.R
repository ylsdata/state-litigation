## Helper Functions
fjc_none_to_na <- function(x) {
  ifelse(grepl("^None ", x), NA, x)
}


dlyear <- function(year, inclusive = TRUE) {
  # Return appropriate duration (in days) depending on whether year is a leap year;
  # If inclusive is set to true, max days reduced by 1 (useful for computing service days as
  # the share of total possible service days in a year where we want to include start
  # and end dates in the calculation)
  
  if (inclusive == TRUE) {
    n = 364
  } else {
    n = 365
  }
  
  if (lubridate::leap_year(as.numeric(year))) {
    lubridate::ddays(n + 1)
  } else {
    lubridate::ddays(n)
  }
}


fjc_circuit_nums <- function(x, pad = FALSE) {
  y <- tolower(x)
  z <- dplyr::case_when(
    grepl("first", y) ~ "1",
    grepl("second", y) ~ "2",
    grepl("third", y) ~ "3",
    grepl("fourth", y) ~ "4",
    grepl("fifth", y) ~ "5",
    grepl("sixth", y) ~ "6",
    grepl("seventh", y) ~ "7",
    grepl("eighth", y) ~ "8",
    grepl("ninth", y) ~ "9",
    grepl("tenth", y) ~ "10",
    grepl("eleventh", y) ~ "11",
    grepl("district of columbia|^dc$|district-columbia", y) ~ "DC",
    grepl("federal|^fc$", y) ~ "FC"
  )
  
  if (pad == TRUE) {
    z <- stringr::str_pad(z, 2, pad = "0")
  }
  
  return(z)
}


fjc_parse_seatid <- function(df, court_num, seatid) {
  df |>
    dplyr::mutate(
      seat_order = str_sub({{ seatid }}, start= -2),
      seat_num = str_replace({{ seatid }}, paste0("CA", {{ court_num }}), ""),
      seat_num = str_replace(seat_num, paste0(seat_order, "$"), ""),
      seat_new = ifelse(is.na(`Statute Authorizing New Seat`), 0, 1)
    )
}


fjc_tidy_party <- function(x) {
  y <- tolower(x)
  dplyr::case_when(
    y == "republican" ~ "rep",
    y == "democratic" ~ "dem"
  )
}


fjc_num_to_rank <- function(x, full = TRUE) {
  y <- str_trim(ifelse(is.numeric(x), as.character(x), x))
  
  if (full == TRUE) {
    z <- dplyr::case_when(
      str_detect(y, "^0?1$") ~ "first",
      str_detect(y, "^0?2$") ~ "second",
      str_detect(y, "^0?3$") ~ "third",
      str_detect(y, "^0?4$") ~ "fourth",
      str_detect(y, "^0?5$") ~ "fifth",
      str_detect(y, "^0?6$") ~ "sixth",
      str_detect(y, "^0?7$") ~ "seventh",
      str_detect(y, "^0?8$") ~ "eighth",
      str_detect(y, "^0?9$") ~ "ninth",
      str_detect(y, "^10$") ~ "tenth",
      str_detect(y, "^11$") ~ "eleventh",
      str_detect(y, "^dc$") ~ "district-columbia",
      str_detect(y, "^fc$") ~ "federal"
    )
  }
  return(z)
}


fjc_judgeships <- function(court) {
  # Make url
  pfx <- "https://www.fjc.gov/history/courts/u.s.-court-appeals-"
  sfx <- "-circuit-legislative-history"
  url <- paste0(pfx, court, sfx)
  
  
  page <- rvest::read_html(url) 
  
  tables <- page |>
    rvest::html_table()
  
  tables[[2]] |>
    filter(!grepl("Judge", X1)) |>
    mutate(
      across(everything(), as.numeric),
      court_num = fjc_circuit_nums(court)
    ) |>
    rename(
      year = X1,
      judges = X2
    ) |>
    select(court_num, everything())
}


fjc_service_dates <- function(df,  current_judges_as = c("missing", "today")) {
  
  # Return a dataframe of start and end dates for each judge
  df_out <- df |>
    mutate(
      start_date = case_when(
        !is.na(`Recess Appointment Date`) ~ `Recess Appointment Date`,
        TRUE ~ `Commission Date`
      ),
      end_date = 
        case_when(
          !is.na(`Senior Status Date`) ~ `Senior Status Date`,
          !is.na(`Termination Date`) ~ `Termination Date`
        )
    )
  
  if (current_judges_as == "today") {
    df_out <- df_out |>
      mutate(end_date = 
               format.Date(as.Date(ifelse(is.na(end_date), Sys.Date(), end_date)))
      )
  }
  
  return(df_out)
}


fjc_service_frac <- function(df) {
  df |>
    mutate(
      start_year = lubridate::year(start_date),
      start_year_int = lubridate::interval(start_date, ymd(paste0(start_year, "-12-31"))),
      start_year_frac = purrr::map2_dbl(start_year_int, start_year, ~.x/dlyear(.y)),
      end_year = lubridate::year(end_date),
      end_year_int = lubridate::interval(ymd(paste0(end_year, "-01-01")), end_date),
      end_year_frac = purrr::map2_dbl(end_year_int, end_year, 
                                      ~ifelse(!is.na(.y), .x/dlyear(.y), NA))
    )
}


fjc_judge_party_infer <- function(df) {
  # Carry forward inference of party based on most recent president to nominate; in case of re-appointment TBD
  df |>
    arrange(nid, Sequence) |>
    mutate(
      president = fjc_none_to_na(`Appointing President`),
      party = fjc_none_to_na(`Party of Appointing President`)
    ) |>
    group_by(nid) |>
    tidyr::fill(c(president, party)) |>
    ungroup()
}


fjc_partisan_churn <- function(df) {
  # Filter and arrange data set
  x <- df |>
    arrange(court_num, date, event) |>
    filter(!is.na(date))
  
  # Create empty vectors to hold counts
  dems <- reps <- oth <- vector('numeric', nrow(x))
  
  # Iterate through churn events and update counts
  for (i in 1:nrow(x)) {
    y <- x[1:i,]
    #ct_size[i] = sum(y[y$event == "enter", ]$seat_new)
    oth[i] = nrow(y[which(y$event == "enter" & is.na(y$party)), ]) - nrow(y[which(y$event == "exit" & is.na(y$party)), ])
    dems[i] = nrow(y[which(y$event == "enter" & y$party == "dem"), ]) - nrow(y[which(y$event == "exit" & y$party == "dem"), ])
    reps[i] = nrow(y[which(y$event == "enter" & y$party == "rep"), ]) - nrow(y[which(y$event == "exit" & y$party == "rep"), ])
  }
  
  # Return dataframe
  x |>
    mutate(
      num_other = oth,
      num_dem = dems,
      num_rep = reps,
      #ct_size = ct_size,
      seats_filled = num_other + num_dem + num_rep,
      frac_dem = num_dem/seats_filled,
      frac_rep = num_rep/seats_filled 
    )
}

 