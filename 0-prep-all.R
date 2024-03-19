################################################################################
# File:         0-prep-all.R
# Author:       Alex Jakubow
# 
# Description:  This master script sequentially executes various source-specific
#               scripts to generate the analysis data set.
#
# Usage Notes:  1.  R functions common to 1+ of these files are defined within
#                   code/fjc_functions.R and functions.R
#               2.  Object names used across these files are defined in 
#                   code/macros.R
################################################################################


### CREATE DEPENDENT VARIABLES DATA SET ----------------------------------------
source("code/litigation.R")


### CREATE INDEPENDENT VARIABLES DATA SET --------------------------------------
# State-year data sources
source("code/population.R")
source("code/aspep.R")
source("code/nominate.R")  #convert state-congresses (US) to state-years

# Circuit-year data sources
source("code/fjc.R")

# State data sources
source("code/agsg.R")

# Combine all to single RHS data set
source("code/make-rhs.R")


### CREATE ANALYSIS DATA SET ---------------------------------------------------
source("code/make-analysis.R")