# state-lawsuits

This repo contains replication code for the state litigation analysis project.


## Getting started

Clone this repository on your local machine.  If you would like to focus on the analysis, skip the following subsection.  Otherwise, continue to read on!


## Data Preparation

### Initial R Setup

1. Please ensure that you have [R](https://www.r-project.org/) installed on your local machine.  [RStudio](https://posit.co/download/rstudio-desktop/) is nice, too, but technically not necessary to reproduce the contents of this repository.
2. Open`state-lawsuits.Rproj` using RStudio and the project dependencies should install automatically
3. If step 2 doesn't work (or if you aren't using RStudio), you can run `renv::restore()` in the console window/terminal.

### Data Prep Pipeline

> Executing `0-prep-all.R` will sequentially execute the relevant .R scripts in `./code` to produce the final data set used in the analysis, saved at `./data/clean/analysis.csv`

There are three helper scripts located within `./code`:

- `functions.R` - Custom functions used by 1+ of the preparatory files
- `functions_fjc.R` - A subset of custom functions that apply only to `fjc.R`
- `macros.R` - Globally-defined objects (e.g., file paths, common parameters) that are referenced across many of the preparatory files.

### Web Scraping

`./code/aspep.R` and `./code/population.R` programmatically-harvest data from the US Census Bureau website.  By default, this repo already contains those downloaded files within `./data/raw`.

If you want to reproduce the process of harvesting these files from source, you will need to delete all of the following files within `./data/raw`:

- `pop[YYYY].csv` - Population estimates files
- `aspep_[YYYY].csv` - State government employment data files

*Please note that if you decide to delete these files, the versions you obtain from the US Census Bureau website may be different*

## Data Analysis

### Stata Setup

1. Please ensure that you have [Stata](https://www.stata.com/) installed on your local machine.  If you are a member of the Yale University community, you can go to this link to procure your own copy (free of charge!) as part of Yale's site licensing agreement.
2. Open Stata and type `ssc install outreg2` in the command window to install the [`outreg2`](http://repec.org/bocode/o/outreg2.html) program for rendering result tables.

### Data Analysis Pipeline

> Executing `1-analyze-all.do` will sequentially execute the relevant do-files (.do) within `./code` to produce the tables and figures used in the analysis.  These files will be saved within `./results` 

### Working with Tables

For convenience, the regression tables in `./results` have already been converted from .xml format into .xlsx.  Re-running `./code/regressions.do` will generate the results in .xml format.  You can easily open and edit these files in Excel, although you might have to right-click on the file name and select Excel from the drop-down menu.