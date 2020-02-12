
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
	
	
	*	Create variables for descriptive stats
	
		*	Quantile (income per capita)
		loc	qtile_var	fam_income_pc
		xtile	`qtile_var'_99_qt	=	`qtile_var'	if	(wave==1999),	n(10)	//	'99 per capita income
		xtile	`qtile_var'_15_qt	=	`qtile_var'	if	(wave==2015),	n(10)	//	'15 per capita income
		xtile	`qtile_var'_17_qt	=	`qtile_var'	if	(wave==2017),	n(10)	//	'17 per capita income
		sort x11101ll wave
		bys x11101ll: replace `qtile_var'_99_qt = L.`qtile_var'_99_qt if mi(`qtile_var'_99_qt)	//	'99
		bys x11101ll: replace `qtile_var'_15_qt = L.`qtile_var'_15_qt if mi(`qtile_var'_15_qt)	//	'15
		
		*	Quantile (food security scale, household)
		loc	qtile_var	fs_hh_scale
		xtile	`qtile_var'_99_qt	=	`qtile_var'	if	(wave==1999),	n(10)	//	'99 per capita income
		xtile	`qtile_var'_15_qt	=	`qtile_var'	if	(wave==2015),	n(10)	//	'15 per capita income
		xtile	`qtile_var'_17_qt	=	`qtile_var'	if	(wave==2017),	n(10)	//	'17 per capita income
		sort x11101ll wave
		bys x11101ll: replace `qtile_var'_99_qt = L.`qtile_var'_99_qt if mi(`qtile_var'_99_qt)	//	'99
		bys x11101ll: replace `qtile_var'_15_qt = L.`qtile_var'_15_qt if mi(`qtile_var'_15_qt)	//	'15
		
		*	Quantile (food expenditure per capita)
		loc	qtile_var	food_exp_pc
		xtile	`qtile_var'_99_qt	=	`qtile_var'	if	(wave==1999),	n(10)	//	'99 per capita income
		xtile	`qtile_var'_15_qt	=	`qtile_var'	if	(wave==2015),	n(10)	//	'15 per capita income
		xtile	`qtile_var'_17_qt	=	`qtile_var'	if	(wave==2017),	n(10)	//	'17' per capita income
		sort x11101ll wave
		bys x11101ll: replace `qtile_var'_99_qt = L.`qtile_var'_99_qt if mi(`qtile_var'_99_qt)	//	'99
		bys x11101ll: replace `qtile_var'_15_qt = L.`qtile_var'_15_qt if mi(`qtile_var'_15_qt)	//	'15
	
	*	Descriptive stats
	xtset
	
		*	Overview (variables that appear all the time between 1999 and 2017)
		xtsum fam_income_pc food_exp_pc food_school_any food_stamp_1yr food_stamp_2yr food_elderly_meal food_WIC_received
		xtsum fam_income_pc food_exp_pc food_school_any food_stamp_1yr food_stamp_2yr food_elderly_meal food_WIC_received	if	fam_income_pc_99_qt==1
		
		*	Food security (variables that don't appear in every period)
		xtsum fs_hh_scale fs_child_scale fs_hh_cat fs_child_cat if inrange(wave,1999,2003)	//	1999-2003
		xtsum fs_hh_scale fs_child_scale fs_hh_cat fs_child_cat if inrange(wave,2015,2017)	//	2015-2017
		
		xtsum fs_hh_scale fs_child_scale fs_hh_cat fs_child_cat if inrange(wave,1999,2003)	&	fam_income_pc_99_qt==1	//	1999-2003, '99 income per capita botoom 10%
		xtsum fs_hh_scale fs_child_scale fs_hh_cat fs_child_cat if inrange(wave,2015,2017)	&	fam_income_pc_99_qt==1	//	2015-2017,	'99 income per capita botoom 10%
		
	*	Correlation
		
		*	Cross-sectional correlation
		corr	fam_income_pc food_exp_pc food_school_any food_stamp_1yr food_stamp_2yr food_elderly_meal food_WIC_received
		
		*	Autocorrelation
		foreach	var	in fam_income_pc food_exp_pc food_school_any food_stamp_1yr food_stamp_2yr food_elderly_meal food_WIC_received	{
			di	"Autocorrelatoin of `var'"
			corr	`var'	l.`var'	l2.`var'	l3.`var'	l4.`var'	l5.`var'	l6.`var'	l7.`var'	l8.`var'	l9.`var'
		}

		corr	fs_hh_scale	l.fs_hh_scale	l2.fs_hh_scale

		*	Correlation between income per capita and lagged values of other variables
		foreach	var	in food_exp_pc food_school_any food_stamp_1yr food_stamp_2yr food_elderly_meal food_WIC_received	{
			di	"Correlation between income per capita and lagged values of `var'"
			corr	fam_income_pc	l.`var'	l2.`var'	l3.`var'	l4.`var'	l5.`var'	l6.`var'	l7.`var'	l8.`var'	l9.`var'
		}

		corr	fam_income_pc	l.fs_hh_scale	l2.fs_hh_scale
		
	*	Transition probability (of food security)
	
		xttrans fs_hh_cat	if	inrange(wave,1999,2003)	//	'99-'03
		xttrans fs_hh_cat	if	inrange(wave,2015,2017)	//	'15-'17
		
		xttrans	fs_hh_cat	if	inrange(wave,1999,2003)	&	food_exp_pc_99_qt==1	//	'99-'03, income bottom 10% quantile
		xttrans	fs_hh_cat	if	inrange(wave,2015,2017)	&	food_exp_pc_15_qt==1	//	'15-'17, income bottom 10% quantile

	*	Quantile plots
	
		quantile fs_hh_scale
		
		qplot fs_hh_scale if (wave==2017), over(fam_income_pc_99_qt) legend(rows(1))
		graph	close
		
	*	Dynamics (change over time)
	
			
		*	Collapse variables using median
		collapse (mean) food* fs*, by(wave fam_income_pc_99_qt)	//	use '99 income per capita as distribution
		
		*	Food Security (household)
		graph twoway	(connected fs_hh_scale wave if fam_income_pc_99_qt==1)	///
						(connected fs_hh_scale wave if fam_income_pc_99_qt==2)	///
						(connected fs_hh_scale wave if fam_income_pc_99_qt==5)	///
						(connected fs_hh_scale wave if fam_income_pc_99_qt==9)	///
						(connected fs_hh_scale wave if fam_income_pc_99_qt==10),	///
						ytitle(Food Security Scale) title(Food Security (Household))	///
						note(note: Quantile is based on '99 income per capita & no data between '05-'13) legend(lab (1 "10%") lab(2 "20%") lab(3 "50%") lab(4 "90%") lab(5 "100%") rows(1))	///
						name(fs_hh_scale, replace)
		
		graph	export	"${PSID_outRaw}/fs_hh_scale.png", replace
		graph	close
		
		*	Food Security (children)
		graph twoway	(connected fs_child_scale wave if fam_income_pc_99_qt==1)	///
						(connected fs_child_scale wave if fam_income_pc_99_qt==2)	///
						(connected fs_child_scale wave if fam_income_pc_99_qt==5)	///
						(connected fs_child_scale wave if fam_income_pc_99_qt==9)	///
						(connected fs_child_scale wave if fam_income_pc_99_qt==10),	///
						ytitle(Food Security Scale) title(Food Security (Children))	///
						note(note: Quantile is based on '99 income per capita & no data between '05-'13) legend(lab (1 "10%") lab(2 "20%") lab(3 "50%") lab(4 "90%") lab(5 "100%") rows(1))	///
						name(fs_child_scale, replace)
		
		graph	export	"${PSID_outRaw}/fs_hh_child.png", replace
		graph	close
		
		graph	combine	fs_hh_scale	fs_child_scale
		
		*	Food Stamp (Last year)
		graph twoway	(connected food_stamp_1yr wave if fam_income_pc_99_qt==1)	///
						(connected food_stamp_1yr wave if fam_income_pc_99_qt==2)	///
						(connected food_stamp_1yr wave if fam_income_pc_99_qt==5)	///
						(connected food_stamp_1yr wave if fam_income_pc_99_qt==9)	///
						(connected food_stamp_1yr wave if fam_income_pc_99_qt==10),	///
						ytitle(=1 "Received") title(Food Stamp last year)	///
						note(note: Quantile is based on '99 income per capita)	legend(lab (1 "10%") lab(2 "20%") lab(3 "50%") lab(4 "90%") lab(5 "100%") rows(1))	///
						name(food_stamp_1yr, replace)
		
		graph	export	"${PSID_outRaw}/food_stamp_1yr.png", replace
		graph	close
		
		*	Food Stamp (2 years ago)
		graph twoway	(connected food_stamp_2yr wave if fam_income_pc_99_qt==1)	///
						(connected food_stamp_2yr wave if fam_income_pc_99_qt==2)	///
						(connected food_stamp_2yr wave if fam_income_pc_99_qt==5)	///
						(connected food_stamp_2yr wave if fam_income_pc_99_qt==9)	///
						(connected food_stamp_2yr wave if fam_income_pc_99_qt==10),	///
						ytitle(=1 "Received") title(Food Stamp 2 years ago)	///
						note(note: Quantile is based on '99 income per capita)	legend(lab (1 "10%") lab(2 "20%") lab(3 "50%") lab(4 "90%") lab(5 "100%") rows(1))	///
						name(food_stamp_2yr, replace)
						
		graph	export	"${PSID_outRaw}/food_stamp_2yr.png", replace
		graph	close
						
		*	Child received free meal
		graph twoway	(connected food_school_any wave if fam_income_pc_99_qt==1)	///
						(connected food_school_any wave if fam_income_pc_99_qt==2)	///
						(connected food_school_any wave if fam_income_pc_99_qt==5)	///
						(connected food_school_any wave if fam_income_pc_99_qt==9)	///
						(connected food_stamp_2yr wave if fam_income_pc_99_qt==10),	///
						ytitle(=1 "Received") title(School meal)	///
						note(note: Quantile is based on '99 income per capita)	legend(lab (1 "10%") lab(2 "20%") lab(3 "50%") lab(4 "90%") lab(5 "100%") rows(1))	///
						name(school_meal, replace)
		
		graph	export	"${PSID_outRaw}/school_meal.png", replace
		graph	close
		
		*	WIC meal
		graph twoway	(connected food_WIC_received wave if fam_income_pc_99_qt==1)	///
						(connected food_WIC_received wave if fam_income_pc_99_qt==2)	///
						(connected food_WIC_received wave if fam_income_pc_99_qt==5)	///
						(connected food_WIC_received wave if fam_income_pc_99_qt==9)	///
						(connected food_WIC_received wave if fam_income_pc_99_qt==10),	///
						ytitle(=1 "Received") title(WIC meal)	///
						note(note: Quantile is based on '99 income per capita)	legend(lab (1 "10%") lab(2 "20%") lab(3 "50%") lab(4 "90%") lab(5 "100%") rows(1))	///
						name(WIC_meal, replace)
						
		graph	export	"${PSID_outRaw}/WIC_meal.png", replace
		graph	close
						
		*	Elderly meal
		graph twoway	(connected food_elderly_meal wave if fam_income_pc_99_qt==1)	///
						(connected food_elderly_meal wave if fam_income_pc_99_qt==2)	///
						(connected food_elderly_meal wave if fam_income_pc_99_qt==5)	///
						(connected food_elderly_meal wave if fam_income_pc_99_qt==9)	///
						(connected food_elderly_meal wave if fam_income_pc_99_qt==10),	///
						ytitle(=1 "Received") title(Elderly meal status)	///
						note(note: Quantile is based on '99 income per capita)	legend(lab (1 "10%") lab(2 "20%") lab(3 "50%") lab(4 "90%") lab(5 "100%") rows(1))	///
						name(Elderly_meal, replace)
		
		graph	export	"${PSID_outRaw}/Elderly_meal.png", replace
		graph	close
		
	*	Combine graphs
		cd	"${PSID_outRaw}"
		graph	combine		fs_hh_scale	food_stamp_1yr	school_meal	fs_child_scale	food_stamp_2yr	WIC_meal
		
		graph	export	"${PSID_outRaw}/Food_over_time.png", replace
		graph	close
		

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