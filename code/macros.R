# Directories
RAW_DATA_DIR = "data/raw"
MUNGED_DATA_DIR = "data/munged"
CLEAN_DATA_DIR = "data/clean"
DOC_DIR = "docs"

# Files
#source
WIRZ_RAW = paste0(RAW_DATA_DIR, "/Master Dataset-20240227.xlsx")
NOMINATE_RAW = paste0(RAW_DATA_DIR, "/HSall_members.csv")
#munged
NOMINATE_MUNGED = paste0(MUNGED_DATA_DIR, "/nominate.csv")
ASPEP_FILE = paste0(MUNGED_DATA_DIR, "/aspep.csv")
FJC_FILE = paste0(MUNGED_DATA_DIR, "/usca_partisanship_yearly.csv")
POP_FILE = paste0(MUNGED_DATA_DIR, "/pop.csv")
DV_FILE = paste0(MUNGED_DATA_DIR, "/litigation.csv")
AGSG_FILE = paste0(MUNGED_DATA_DIR, "/agsg.csv")
ALL_RHS_FILE <- paste0(MUNGED_DATA_DIR, "/rhs.csv")
#clean
ANALYSIS_FILE <- paste0(CLEAN_DATA_DIR, "/analysis.csv")

# Parameters
YEARS = 2000:2022
POP_YEARS = c(2000, 2010, 2020)
CONGRESS_START = 106
CONGRESS_STOP = 118