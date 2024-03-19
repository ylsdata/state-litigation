/*******************************************************************************
// File:			regressions.do
// Author:			Alex Jakubow

// Description:		Compute descriptive statistics, main regressions, and 
					visualizations for interaction terms.
					
// Usage notes:		1.	All global macros (e.g., $MACRO_NAME) are defined in 
						../1-analyze-all.do
					2.	Marginal effects computations can take a while, so you
						may want to consider selecting a smaller value for
						$mfx_grid_size in ../1-analyze-all.do
*******************************************************************************/


*************
*** SETUP ***
*************

// Load data
import delimited using $dataset

// Compute interactions for regression tables
gen dem_presXnominate = dem_pres*nominate_p50_cngr
gen circXnominate = circ_rep_share*nominate_p50_cngr

// Define sample (complete cases only)
foreach v of varlist $depvars $indvars5 $controls {
	drop if `v' == .
}

// Set for tscs analysis
xtset state_code year


****************************** 
*** DESCRIPTIVE STATISTICS ***
******************************

outreg2 using "$outreg_path/descriptives", excel sum(log) replace ///
	keep($depvars $indvars1 dem_pres circ_rep_share $indvars3 $indvars4) ///
	eqdrop(N_clust)

	
*******************	
*** REGRESSIONS ***
*******************

foreach y in $depvars {
	foreach m in $models {		
		`m' `y' $indvars1 $controls i.year || state_code:, vce(robust)
		outreg2 using "$outreg_path/`y'_`m'", $outreg_opts ///
			title("Mixed-Effects `m' Regressions of Litigation Counts (`y')") ///
			ctitle("Resources") replace
		
		`m' `y' $indvars2 $controls i.year || state_code:, vce(robust) 
		outreg2 using "$outreg_path/`y'_`m'", $outreg_opts ///		
			ctitle("Partisanship") append
		
		`m' `y' $indvars3 $controls i.year || state_code:, vce(robust)
		outreg2 using "$outreg_path/`y'_`m'", $outreg_opts ///
			ctitle("Attorney General") append
		
		`m' `y' $indvars4 $controls i.year || state_code:, vce(robust)
		outreg2 using "$outreg_path/`y'_`m'", $outreg_opts ///
			ctitle("Solicitor General") append
		
		`m' `y' $indvars5 $controls i.year || state_code:, vce(robust) 
		outreg2 using "$outreg_path/`y'_`m'", $outreg_opts ///
			ctitle("Full Model") append
	}
}


************************
*** MARGINAL EFFECTS ***
************************

// Determine range values for plots
qui sum nominate_p50_cngr
local min_cngr = r(min)
local max_cngr = r(max)
local grid_cngr = (`max_cngr'-`min_cngr')/$mfx_grid_size

// Model loops
foreach y in $depvars {
	foreach m in $models {
		`m' `y' c.nominate_p50_cngr##i.dem_pres c.nominate_p50_cngr##c.circ_rep_share ///
			$indvars1 $indvars3 $indvars4 $controls i.year || state_code:, irr vce(robust)			
	
	
		// Presidential party and congressional NOMINATE interaction
		* compute predictive margins
		qui margins dem_pres, noestimcheck ///
			at(nominate_p50_cngr = (`min_cngr' (`grid_cngr') `max_cngr')) 
		marginsplot, recast(line) recastci(rarea) ciopt(color(%50)) ///
			title("Predictive Margins of Presidential Party") ///
			xtitle("Congressional NOMINATE Score") ///
			ytitle("Predicted Mean Litigation") ///
			xlabel(20 (10) 90) ///
			legend(order (1 "Republican" 2 "Democrat")) name(main, replace)

		* compute avg. marginal effect
		qui margins, dydx(dem_pres) noestimcheck ///
			at(nominate_p50_cngr = (`min_cngr' (`grid_cngr') `max_cngr')) 
		marginsplot, recast(line) recastci(rarea) yline(0) /// 
			ciopt(color(%50)) ///
			title("Average Marginal Effects of Democratic Presidency") ///
			xtitle("Congressional NOMINATE Score") ///
			ytitle("Change in Predicted Mean Litigation") ///
			xlabel(20 (10) 90) ///
			legend(order (1 "Republican" 2 "Democrat")) name(diff, replace)
			
		* combine and save graph
		graph combine main diff, xsize(6.5) ysize(2.7) iscale(.8) name(comb, replace)
		graph close main diff
		graph export "${outreg_path}/partisan-presidency_`y'_`m'.png", width(6000) replace
		
		// Circuit partisanship and congressional nominate interaction
		* predictive margins
		qui margins, noestimcheck ///
			at(circ_rep_share = (10 50 90) ///
			nominate_p50_cngr = (`min_cngr' (`grid_cngr') `max_cngr')) 
		marginsplot, x(nominate_p50_cngr) recast(line) noci ///
			title("Predictive Margins of Circuit Court Partisanship") ///
			xtitle("Congressional NOMINATE Score") ///
			ytitle("Predicted Mean Litigation") ///
			xlabel(20 (10) 90) ///
			legend(order (1 "10% R-Appointed" 2 "50% R-Appointed" 3 "90% R-Appointed")) ///
			name(main, replace)
		
		* avg. marginal effect
		qui margins, dydx(circ_rep_share) noestimcheck ///
			at(nominate_p50_cngr = (`min_cngr' (`grid_cngr') `max_cngr')) 
		marginsplot, recast(line) recastci(rarea) yline(0) /// 
			ciopt(color(%50)) ///
			title("Average Marginal Effects of Republican Circuit Court") ///
			xtitle("Congressional NOMINATE Score") ///
			ytitle("Change in Predicted Mean Litigation") ///
			xlabel(20 (10) 90) ///
			name(diff, replace)
			
		* combine and save graph
		graph combine main diff, xsize(6.5) ysize(2.7) iscale(.8) name(comb, replace)
		graph close main diff
		graph export "${outreg_path}/partisan-circuit_`y'_`m'.png", width(6000) replace
	}
}	
