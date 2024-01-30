# state-lawsuits

## Getting started

### Initial Setup

1. Clone this repo onto your a local machine
2. Open`state-lawsuits.Rproj` using RStudio and the project dependencies should install automatically
3. If step 2 doesn't work, you can run `renv::restore()` in the console window

### Add your Census API Key

1. Request an API Key from the Census Bureau from [this website](https://api.census.gov/data/key_signup.html)
2. In the console, create a project level `.Renviron` file to safely store your API key (`usethis::edit_r_environ(scope = "project")`). See this [code snippet](https://www.hrecht.com/censusapi/articles/getting-started.html#api-key-setup) for more info on how to set and store the key.

## Data Harvesting using the API

### Total population

We need to obtain state-level data for each of the 50 states from 2000- using the following API endpoints:

- Total state population from the [Population Estimates and Projections API](https://www.census.gov/data/developers/data-sets/popest-popproj.html)

### State expenditure and employment data

Option 1: API

- Grab all highlighted fields from the AGG_DESC tab of ['Public Sector -Annual - CoG API Documentation.xlsx'](https://yaleedu.sharepoint.com/:x:/r/sites/YLSData/Shared%20Documents/Efforts/state-lawsuits/Public%20Sector%20-Annual%20-%20CoG%20API%20Documentation.xlsx?d=w13ed7e948ec74b64bbe5c859e6355694&csf=1&web=1&e=EHfcJp) using the [Public Sector Statistics API](https://www.census.gov/data/developers/data-sets/annual-public-sector-stats.html) for all states and years 2000-

- Employment data should come from SVY-CMP 01, Expenditure data should come from SVY-CMP 04
- For GOV_TYPE, try 001 (State and Local) or 002 (State)

Option 2: Download manually (not sure if we need this just yet....)

- Download and extract public use files for all states and years 2000- from the [datasets here](https://www.census.gov/programs-surveys/gov-finances/data/datasets.All.List_1883146942.html#list-tab-List_1883146942)
- Extract data for all fields with any of the following item codes:
  - E25 - Judicial-Current Operation
  - E29 - Central Staff-Current Operation
  - F25 - Judicial-Construction
  - F29 - Central Staff-Construction
  - G25 - Judicial-Other Capital Outlay
  - G29 - Central Staff-Other Capital Outlay


## Guides
- [`censusapi`](https://www.hrecht.com/censusapi/articles/getting-started.html)
