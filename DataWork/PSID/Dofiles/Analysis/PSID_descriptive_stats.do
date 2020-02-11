
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_descriptive_stats
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Feb 10, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	x11101ll         // Uniquely identifies households (update for your project)

	DESCRIPTION: 	Generate descriptives stats(tables, plots)
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Descriptive Stats
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID Data
			
	OUTPUTS: 		* Graphs & Tables

	NOTE:			*
	******************************************************************/

	/****************************************************************
		SECTION 0: Preamble			 									
	****************************************************************/		 
		
	/* 0.1 - Environment setup */
	
	* Clear all stored values in memory from previous projects
	clear			all
	cap	log			close

	* Set version number
	version			14

	* Set basic memory limits
	set maxvar 		32767
	set matsize		11000

	* Set default options
	set more		off
	pause			on
	set varabbrev	off
	
	* Filename and log
	loc	name_do	PSID_descriptive_stats
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doAnl}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1.1: Descriptive Stats
	****************************************************************/	
	
	use	"${PSID_dtInt}/PSID_interm", clear
	
	*	Descriptive stats
	xtset
	
		*	Overview (variables that appear all the time between 1999 and 2017)
		xtsum fam_income_pc food_exp_pc food_school_any food_stamp_1yr food_stamp_2yr food_elderly_meal food_WIC_received
		
		*	Food security (variables that don't appear in every period)
		xtsum fs_hh_scale fs_child_scale fs_hh_cat fs_child_cat if inrange(wave,1999,2003)	//	1999-2003
		xtsum fs_hh_scale fs_child_scale fs_hh_cat fs_child_cat if inrange(wave,2015,2017)	//	2015-2017
		
	*	Transition probability (of food security)
	
		xttrans fs_hh_cat if inrange(wave,1999,2003), freq	//	'99-'03
		xttrans fs_hh_cat if inrange(wave,2015,2017), freq	//	'15-'17
		
	*	Quantile plots
	
		quantile fs_hh_scale
		qplot fs_hh_scale, over(wave)

	*	Survey data analyses
	** (This part is temporarily disabled, as STATA doesn't allow panel data setting and survey design setting at the same time)

	/*

	svyset ER31997 [pweight=ind_weight_long], strata(ER31996) singleunit(certainty)

	svy: xtsum food_exp_tot

	svy: mean food_exp_tot
	svy: tab fs_hh_scale



	xtsum x11101ll wave food_exp_tot fs_hh_scale

	sepscatter fs_hh_scale fam_income_tot if (inlist(wave,1999,2001) & fs_hh_scale!=0), sep(wave) 

	/*
	sepscatter fam_income_tot fs_hh_scale if inlist(wave,1999,2001,2003,2015,2017), sep(wave) ysc(log) xsc(log) ///
	legend(pos(3) col(1)) xla(50 100 200 500 1000 2000 5000) ///
	yla(1000 500 200 100 50 20 10 5 2, ang(h))
	*/

	** for family level analysis

	*drop	individual level variables
	drop	x11101ll xsqnr ind_weight_long ind_weight_cross
	duplicates drop

	svyset ER31997 [pweight=fam_weight_long], strata(ER31996) singleunit(certainty)
	svy, vce(linearized): mean food_exp_tot

	*/
	
	
	/* Archive (old codes)
	*	Food expenditure
	use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Customized\Food_variables\food_variables.dta", clear
	
	*	Distribution of food expenditure
		graph twoway	(kdensity ER16515A1) (kdensity ER24138A1) (kdensity ER41027A1) (kdensity ER52395A1) (kdensity ER71487) if !mi(ER66002),	///
		title(Distribution of Annual Food Expenditure)	legend(lab (1 "1999") lab(2 "2003") lab(3 "2007") lab(4 "2011") lab(5 "2017"))
		
	*	Distribution of food security (scaled score)
		graph twoway	(kdensity ER14331T) (kdensity ER18470T) (kdensity ER21735T) (kdensity ER60798) (kdensity ER66846) if !mi(ER66002),	///
		title(Distribution of Food Security Score(scaled))	legend(lab (1 "1999") lab(2 "2001") lab(3 "2003") lab(4 "2015") lab(5 "2017"))
		
	*	Distribution of food security (category)
		graph twoway	(bar ER14331U) (bar ER18470U) (bar ER21735U) (bar ER60799) (bar ER66847) if !mi(ER66002),	///
		title(Distribution of Food Security Score(scaled))	legend(lab (1 "1999") lab(2 "2001") lab(3 "2003") lab(4 "2015") lab(5 "2017"))
		
	*/