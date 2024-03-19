/*******************************************************************************
// File:			1-analyze-all.do
// Author:			Alex Jakubow

// Description:		Main script to execute analyses.
					
// Usage notes:		1. 	See SETUP section below for more details
					2.	Marginal effects computations can take a while, so you
						may want to consider selecting a smaller value for
						$mfx_grid_size
					3. 	Regression tables default to reporting expontentiated
						coefficients.  If you would like change this, please 
						delete the word "eform" from the definition of 
						$outreg_opts.
*******************************************************************************/
clear

*************
*** SETUP ***
*************

// 1. Modify where the project folder lives on your machine
global root "~/yale/projects/state-lawsuits"

// 2. Install these packages if you don't have them
* ssc install outreg2


*******************
*** PREFERENCES ***
*******************

// Set graph scheme
set scheme s1mono


*********************
*** DEFINE MACROS ***
*********************

// Datasets
global dataset "$root/data/clean/analysis.csv"

// Model globals
global models mepoisson menbreg

// Regression globals
global depvars n_litigate n_litigate2
global indvars1 judicial_fte_share judicial_pay_share 
global indvars2 dem_presXnominate circXnominate dem_pres nominate_p50_cngr 
global indvars3 ag_higher_office ln_ag_tenure 
global indvars4 ln_sg_experience sg_t14_grad sg_clerk_scotus sg_clerk_dc
global indvars5 $indvars1 $indvars2 $indvars3 $indvars4
global controls ln_pop_total

// Marginal effect globals
global mfx_grid_size = 20  

// Output globals
global outreg_titles "Mixed-Effects `m' Regressions of Litigation Counts (`y')"
global outreg_path "$root/results"
global outreg_stats addstat("Wald Chi^2", e(chi2_c), "Prob > Chi^2", e(p_c), "Log-likelihood", e(ll), "N", e(N))
global outreg_opts word dec(3) eform nocons noobs noni keep($indvars5 $controls) sortvar($indvars5 $controls) $outreg_stats
global outreg_notes addtext(Year FE, Yes)



************************
*** EXECUTE DO-FILES ***
************************
cd $root
do "./code/regressions.do"

