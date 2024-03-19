# Return years corresponding to a given congress
us_congress_years <- function(congress, out = c("vector", "df")) {
  if (congress < 74) { #| year < 1935) {
    return("Conversion not possible.  Please select a congress/year >= 74/1935")
  }
  
  y1 <- 74 + (congress - 74)*2 + 1861
  y2 <- y1 + 1
  years <- c(y1, y2)
  
  if (out == "df") {
    data.frame(
      congress = congress,
      year = years
    )
  }
}


add_state_fips <- function(df, 
                           key_var, 
                           key_type = c("name", "postal"),
                           drop_key = FALSE) {
  
  # Leave state data only
  df_fips <- tidycensus::fips_codes |>
    select(-starts_with("county")) |>
    mutate(
      state_name = tolower(state_name),
      state = tolower(state)
      ) |>
    distinct()
  
  # Rename key to match `df` key name
  if (key_type == "name") {
    df_fips$state <- NULL
    names(df_fips)[names(df_fips)=="state_name"] <- key_var
    # df_fips <- df_fips |>
    #   rename(key_var = state_name)
  } else if (key_type == "postal") {
    df_fips$state_name <- NULL
    names(df_fips)[names(df_fips)=="state"] <- key_var
    # df_fips <- df_fips |>
    #   rename(key_var = state)
  }
  
  # Join
  df_out <- left_join(df, df_fips) 
  
  # Optional drop
  if (drop_key == TRUE) {
    df_out[[key_var]] <- NULL
  }
  
  return(df_out)
}


download_pop <- function(decade, data_dir, docs_dir) {
  # Determine endpoint
  file_ext <- ".csv"
  data_stub <- "https://www2.census.gov/programs-surveys/popest/datasets/"
  layout_stub <- "https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/"
  
  if (decade == 2000) {
    doc_url <- paste0(layout_stub, "2000-2010/intercensal/state/st-est00int-hisp.pdf")
    data_url <- paste0(data_stub, "2000-2010/intercensal/state/st-est00int-hisp.csv")
  } else if (decade == 2010) {
    doc_url <- paste0(layout_stub, "2010-2020/nst-est2020.pdf")
    data_url <- paste0(data_stub, "2010-2020/state/totals/nst-est2020.csv")
  } else if (decade == 2020) {
    doc_url <- paste0(layout_stub, "2020-2023/NST-EST2023-ALLDATA.pdf")
    data_url <- paste0(data_stub, "2020-2023/state/totals/NST-EST2023-ALLDATA.csv")
  }
  
  # Download
  purrr::safely(download.file(url = data_url,
                              destfile = paste0(data_dir, "/pop", decade, file_ext),
                              extra="--random-wait --retry-on-http-error=503"))
  purrr::safely(download.file(url = doc_url,
                              destfile = paste0(docs_dir, "/pop", decade, ".pdf"),
                              extra="--random-wait --retry-on-http-error=503"))
}


download_aspep <- function(year, data_dir) {
  
  # Determine endpoint
  file_ext <- ifelse(year > 2019, ".xlsx", ".xls")
  data_url <- paste0("https://www2.census.gov/programs-surveys/apes/datasets/",
                     year, "/", year, "_state", file_ext)
  if (year < 2017) {
    data_url <- paste0("https://www2.census.gov/programs-surveys/apes/datasets/",
                       year, "/annual-apes/", year, "_state", file_ext)
  }
  if (year >= 2000 & year < 2012) {
    yr <- substr(as.character(year), 3, 4)
    data_url <- paste0("https://www2.census.gov/programs-surveys/apes/tables/",
                       year, "/annual-apes/", yr, "stall", file_ext)
  }
  
  # Download
  purrr::safely(download.file(url = data_url,
                              destfile = paste0(data_dir, "/aspep_", year, file_ext),
                              extra="--random-wait --retry-on-http-error=503"))
}


# Determine remaining years to grab by looking at files already downloaded
to_download <- function(dir, all_years, pattern = "aspep") {
  f <- list.files(dir, pattern = pattern)
  years <- as.numeric(stringr::str_extract_all(f, "[0-9]{4}", simplify = TRUE))
  setdiff(all_years, years)
}


ingest_aspep <- function(raw_excel_file, preview = FALSE) {
  # Get year from file name
  year <- as.numeric(
    stringr::str_extract_all(raw_excel_file, "[0-9]{4}", simplify = TRUE)
  )
  
  # Modify rows to skip
  if (year > 2017 | year %in% c(2012)) {
    rowskip <- 15
  } else if (year %in% c(2009:2011, 2013, 2017)) {
    rowskip <- 14
  } else if (year %in% c(2007:2008)) {
    rowskip <- 13
  } else if (year %in% c(2014:2016)) {
    rowskip <- 12
  } else if (year %in% 2001) {
    rowskip <- 7
  } else if (year %in% c(2000, 2002:2006)) {
    rowskip <- 5
  }
  
  # Modify variable names
  if (year > 2018) {
    vars <- c("state", "govt_function", "ft_emp", "ft_pay", "pt_emp", 
              "pt_pay", "fte_emp", "tot_emp", "tot_pay")
    
  } else if (year %in% 2012:2018) {
    vars <- c("state", "govt_function", "ft_emp", "ft_pay", "pt_emp", 
              "pt_pay", "pt_hours", "fte_emp", "tot_emp", "tot_pay")
  } else if (year %in% 2007:2011) {
    vars <- c("state", "govt_function", "ft_emp", "ft_pay", "pt_emp", 
              "pt_pay", "pt_hours", "fte_emp", "tot_emp", "tot_pay", "state_seq")
  } else if (year %in% 2002:2006) {
    vars <- c("state", "govt_function", "ft_emp", "ft_pay", "pt_emp", 
              "pt_pay", "pt_hours", "fte_emp", "tot_pay", "state_seq")
  } else if (year %in% 2000:2001) {
    vars <- c("state", "govt_function", "ft_emp", "ft_pay", "pt_emp", 
              "pt_pay", "pt_hours", "fte_emp", "tot_pay")
  }
  
  # Load
  df <- readxl::read_excel(path = raw_excel_file, 
                           col_names = FALSE, 
                           skip = rowskip)
  
  # Rename and munge
  names(df) <- vars
  df <- df |>
    mutate(
      year = year,
      state = str_trim(tolower(state)),
      govt_function = str_trim(tolower(govt_function))
    )
  
  # Harmonize fips
  if (max(nchar(df$state)) == 2) {
    df <- add_state_fips(df, key_var = 'state', key_type = 'postal')
  } else {
    df <- add_state_fips(df, key_var = 'state', key_type = 'name')
  }
  # Output
  if (preview == TRUE) {
    return(head(df))
  }
  return(df)
}


munge_pop <- function(csv_file) {
  fips_exclude <- c("0", "00", "72") #drop Nationwide, PR and regions
  decade <- as.numeric(gsub("[^0-9]", "", csv_file))
  
  df <- read_csv(csv_file)
  
  # Munge
  if (decade == 2000) {
    df <- df |>
      filter(ORIGIN == 0)
  }
  df <- df |>
    select(STATE, NAME, matches("POPESTIMATE[0-9]{4}$")) |>
    filter(!STATE %in% fips_exclude)
  
  # Reshape
  df <- df |>
    pivot_longer(
      cols = starts_with("POPESTIMATE"),
      names_to = "year",
      values_to = "pop_total"
    ) |>
    mutate(year = gsub('[^0-9]', '', year)) |>
    rename(
      "state_code" = STATE,
      "state" = NAME
    )
  
  # Filter out last year of each file, so that it is picked up by next decade
  drop_year = as.character(decade + 10)
  df <- filter(df, year != drop_year)
  return(df)
}
