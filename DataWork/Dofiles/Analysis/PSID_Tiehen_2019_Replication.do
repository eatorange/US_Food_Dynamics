
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_Tiehen_2009_Replication
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Mar 15, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	        // Uniquely identifies family (update for your project)

	DESCRIPTION: 	Replicates Tiehen(2019) Tables
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Tables & Figures
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID 1999-2017 Panel Constructed (ind & family)
					${PSID_dtFin}/PSID_const_1999_2017_ind.dta
					
			
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
	loc	name_do	PSID_Tiehen_2009_Replication
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doAnl}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1: Construct Additional Variables 
	****************************************************************/		
	
	use	"${PSID_dtFin}/PSID_const_1999_2017_ind.dta",	clear
	
	*	Racial category
	foreach	year	in	1999 2001 2003 2015 2017	{
	    gen		race_head_cat`year'=.
		*replace	race_head_cat`year'=1	if	race_head_fam`year'==1
		replace	race_head_cat`year'=1	if	inlist(race_head_fam`year',1,5)
		replace	race_head_cat`year'=2	if	race_head_fam`year'==2
		*replace	race_head_cat`year'=3	if	inrange(race_head_fam`year',3,7)
		replace	race_head_cat`year'=3	if	inlist(race_head_fam`year',3,4,6,7)
		replace	race_head_cat`year'=.n	if	inrange(race_head_fam`year',8,9)
		
		label variable	race_head_cat`year'	"Racial Category of Head, `year'"
	}
	label	define	race_cat	1	"White"	2	"Black"	3	"Others"
	label	values	race_head_cat*	race_cat
	
	tab race_head_cat1999
	
	*	Marital Status (Binary)
	foreach	year	in	1999	2001	2003	2015	2017	{
		gen		marital_status_cat`year'=.
		replace	marital_status_cat`year'=1	if	marital_status_fam`year'==1
		replace	marital_status_cat`year'=2	if	inrange(marital_status_fam`year',2,5)
		replace	marital_status_cat`year'=.n	if	inrange(marital_status_fam`year',8,9)
		
		label variable	marital_status_cat`year'	"Marital Status of Head, `year'"
	}
	label	define	marital_status_cat	1	"Married"	2	"Not Married"
	label	values	marital_status_cat*	marital_status_cat
	
	*	Children in Household (Binary)
	foreach	year	in	1999	2001	2003	2015	2017	{
		gen		child_in_FU_cat`year'=.
		replace	child_in_FU_cat`year'=1		if	num_child_fam`year'>=1	&	!mi(num_child_fam`year')
		replace	child_in_FU_cat`year'=2		if	num_child_fam`year'==0
		*replace	child_in_FU_cat`year'=.n	if	!inrange(xsqnr_`year',1,89)
		
		label variable	child_in_FU_cat`year'	"Marital Status of Head, `year'"
	}
	label	define	child_in_FU_cat	1	"Children in Household"	2	"No Children in Household"
	label	values	child_in_FU_cat*	child_in_FU_cat
	
	*	Age of Head (Category)
	foreach	year	in	1999	2001	2003	2015	2017	{
		gen		age_head_cat`year'=1	if	inrange(age_head_fam`year',16,24)
		replace	age_head_cat`year'=2	if	inrange(age_head_fam`year',25,34)
		replace	age_head_cat`year'=3	if	inrange(age_head_fam`year',35,44)
		replace	age_head_cat`year'=4	if	inrange(age_head_fam`year',45,54)
		replace	age_head_cat`year'=5	if	inrange(age_head_fam`year',55,64)
		replace	age_head_cat`year'=6	if	age_head_fam`year'>=65	&	!mi(age_head_fam`year'>=65)
		replace	age_head_cat`year'=.	if	mi(age_head_fam`year')
		
		label	var	age_head_cat`year'	"Age of Household Head (category), `year'"
	}
	label	define	age_head_cat	1	"16-24"	2	"25-34"	3	"35-44"	///
									4	"45-54"	5	"55-64"	6	"65 and older"
	label	values	age_head_cat*	age_head_cat
	
	*	Recode gender
	foreach	year	in	1999	2001	2003	2015	2017	{
		replace	gender_head_fam`year'	=	0	if	gender_head_fam`year'==2
		
		label	var	gender_head_fam`year'	"Gender Household Head (category), `year'"
	}
	label	define	gender_head_cat	0	"Female"	1	"Male"
	label	values	gender_head_fam*	gender_head_cat
	
	*	Create dummy variables for food security status, compatible with literature
	foreach	year	in	1999	2001	2003	2015	2017	{
		
		generate	fs_cat_MS`year'		=	0	if	!mi(fs_cat_fam`year')
		generate	fs_cat_IS`year'		=	0	if	!mi(fs_cat_fam`year')
		generate	fs_cat_VLS`year'	=	0	if	!mi(fs_cat_fam`year')
				
		replace		fs_cat_MS`year'	=	1	if	inrange(fs_cat_fam`year',2,4)
		replace		fs_cat_IS`year'	=	1	if	inrange(fs_cat_fam`year',3,4)
		replace		fs_cat_VLS`year'	=	1	if	fs_cat_fam`year'==4
		
		label	var	fs_cat_VLS`year'	"Very Low Food Secure (cum) - `year'"
		label	var	fs_cat_IS`year'		"Food Insecure (cum) - `year'"
		label	var	fs_cat_MS`year'		"Marginally Food Insecure (cum) - `year'"
	}
	
	*	Save
	*clonevar	ER13002=x11102_1999
	tempfile	dta_constructed
	save		`dta_constructed'
	
	/****************************************************************
		SECTION 2: Replication
	****************************************************************/		
	
	loc	rep_table_2		0
	loc	rep_table_3		0
	loc	rep_table_4_8	0
	loc	rep_table_9_13	0
	loc	rep_table_14_18	1
		
	*	Before replicating, import variables for sampling error estimation
		use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
		*	Generate a single ID variable
		generate	x11101ll=(ER30001*1000)+ER30002
		
		tempfile	Ind
		save		`Ind'
	
	*	Import variables
	use	`dta_constructed', clear
	merge	m:1	x11101ll	using	`Ind', assert(2 3) keep(3) keepusing(ER31996 ER31997) nogen
	
	save	`dta_constructed', replace
	
	* Since the data is individual level but paper uses family-level data, we need to either (1) keep family variables only or (2) use only one observation per family.
	*	We will do (1)
	
	*	Create	yearly data
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			use	`dta_constructed', clear
			keep	x11102_`year'	weight_long_fam`year'	age_head_fam`year'	race_head_fam`year'	total_income_fam`year'	///	
					marital_status_fam`year'	num_FU_fam`year'	num_child_fam`year'	gender_head_fam`year'	edu_years_head_fam`year'	///
					state_resid_fam`year'	sample_source FPL_`year' FPL_cat`year' grade_comp_cat`year' race_head_cat`year'	///
					marital_status_cat`year' child_in_FU_cat`year' age_head_cat`year'	fs_cat*`year' ER31996 ER31997	/*ER16519*/
			drop	if	mi(x11102_`year')
			duplicates drop
			svyset	ER31997 [pweight=weight_long_fam`year'], strata(ER31996)
			
			tempfile	dta_fam_`year'
			save		`dta_fam_`year''
		}
		
		use	`dta_fam_1999', clear
	
	* Table 2
	if	`rep_table_2'==1	{

		mat drop _all
		
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			use	`dta_fam_`year'', clear			
			
			*	Income categories
			svy: proportion FPL_cat`year'
			mat	FPL_cat`year'	=	e(b)'
			
			*	Racial categories
			svy: proportion	race_head_cat`year'
			mat	race_head_cat`year'	=	e(b)'
			
			*	Marital status
			svy: proportion	marital_status_cat`year'
			mat	marital_status_cat`year'	=	e(b)'
			
			*	Children
			svy: proportion	child_in_FU_cat`year'
			mat	child_in_FU_cat`year'	=	e(b)'
			
			*	Age
			svy: proportion	age_head_cat`year'
			mat	age_head_cat`year'	=	e(b)'
			
			*	Education (Grades Completed)
			svy: proportion	grade_comp_cat`year'
			mat	grade_comp_cat`year'	=	e(b)'
			
			*	Gender
			svy: proportion	gender_head_fam`year'
			mat	gender_head_fam`year'	=	e(b)'
			
			*	Append matrices
			mat	empty_row	=	J(1,1,.)
		
		mat	summary_`year'	=	nullmat(summary_`year')	\	FPL_cat`year'	\	empty_row	\	race_head_cat`year'	\	empty_row	\	///
								marital_status_cat`year'	\	empty_row	\	child_in_FU_cat`year'	\	empty_row	\	age_head_cat`year'	\	///
								empty_row	\	grade_comp_cat`year'	\	empty_row	\	gender_head_fam`year'
		}
		mat	table_2	=	nullmat(table_2),	summary_1999,	summary_2001,	summary_2003,	summary_2015,	summary_2017
		
		*	Output
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table2) modify
		*putexcel	A2 = "CPS-PSID Summary Statistics"
		putexcel	A3	=	matrix(table_2), names overwritefmt nformat(number_d1)
	
	}
	
	*	Table 3
	if	`rep_table_3'==1	{
	
	mat drop _all
		
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			use	`dta_fam_`year'', clear			
			
			*	Food Security
			//	svy: proportion fs_cat_fam`year'
			//	mat	FS_PSID_`year'=(e(b)[1,2..4])'
			svy: mean fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
			mat FS_PSID_`year'=(e(b))'
		}
		
		*	Append matrices
		mat	empty_row	=	J(1,1,.)
		
		mat	table_3	=	nullmat(table_3)	\	FS_PSID_1999	\	empty_row	\	FS_PSID_2001	\	empty_row	\	///
						FS_PSID_2003	\	empty_row	\	FS_PSID_2015	\	empty_row	\	FS_PSID_2017
						
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table3) modify
		*putexcel	A2 = "CPS-PSID Summary Statistics"
		putexcel	A3	=	matrix(table_3), names overwritefmt nformat(number_d1)	
	}
	
	*	Table 4 - Table 8
	if	`rep_table_4_8'==1	{
	
		mat	drop	_all
		
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			use	`dta_fam_`year'', clear
					
			*	Full Sample
			svy: mean	fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
			mat	full_dem_`year'	=	nullmat(full_dem_`year')	\	(e(b))
			
			*	Income Category
			forval	i=1/3	{
				svy, subpop	(if	FPL_cat`year'==`i'): mean	fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
				mat	FPL_dem_`year'	=	nullmat(FPL_dem_`year')	\	(e(b))
			}
			
			*	Racial Category
			forval	i=1/3	{
				svy, subpop	(if	race_head_cat`year'==`i'): mean	fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
				mat	race_dem_`year'	=	nullmat(race_dem_`year')	\	(e(b))
			}
			
			*	Marital Status
			forval	i=1/2	{
				svy, subpop	(if	marital_status_cat`year'==`i'): mean	fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
				mat	marital_dem_`year'	=	nullmat(marital_dem_`year')	\	(e(b))
			}
			
			*	Children
			forval	i=1/2	{
				svy, subpop	(if	child_in_FU_cat`year'==`i'): mean	fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
				mat	child_dem_`year'	=	nullmat(child_dem_`year')	\	(e(b))
			}
			
			*	Age
			forval	i=1/6	{
				svy, subpop	(if	age_head_cat`year'==`i'): mean	fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
				mat	age_dem_`year'	=	nullmat(age_dem_`year')	\	(e(b))
			}
			
			*	Gender
			foreach	i	in	0	1	{
				svy, subpop	(if	gender_head_fam`year'==`i'): mean	fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
				mat	gender_dem_`year'	=	nullmat(gender_dem_`year')	\	(e(b))
			}
			
			*	Grade Completed
			forval	i=1/4	{
				svy, subpop	(if	grade_comp_cat`year'==`i'): mean	fs_cat_MS`year' fs_cat_IS`year' fs_cat_VLS`year'
				mat	grade_dem_`year'	=	nullmat(grade_dem_`year')	\	(e(b))
			}
			
			*	Append
			mat	empty_row	=	J(1,3,.)
			
			mat	table_dem_`year'	=	full_dem_`year'	\	empty_row	\	FPL_dem_`year'	\	empty_row	\	race_dem_`year'	\	empty_row	\	///
									marital_dem_`year'	\	empty_row	\	child_dem_`year'	\	empty_row	\	///
									age_dem_`year'	\	empty_row	\	gender_dem_`year'	\	empty_row	\	grade_dem_`year'
		}	//	Year
			
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table4) modify
		putexcel	A2 = "Food Insecurity Rates by Demographic Group – 1998"
		putexcel	A3	=	matrix(table_dem_1999), names overwritefmt nformat(number_d1)	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table5) modify
		putexcel	A2 = "Food Insecurity Rates by Demographic Group – 2000"
		putexcel	A3	=	matrix(table_dem_2001), names overwritefmt nformat(number_d1)	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table6) modify
		putexcel	A2 = "Food Insecurity Rates by Demographic Group – 2002"
		putexcel	A3	=	matrix(table_dem_2003), names overwritefmt nformat(number_d1)	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table7) modify
		putexcel	A2 = "Food Insecurity Rates by Demographic Group – 2014"
		putexcel	A3	=	matrix(table_dem_2015), names overwritefmt nformat(number_d1)	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table8) modify
		putexcel	A2 = "Food Insecurity Rates by Demographic Group – 2016"
		putexcel	A3	=	matrix(table_dem_2017), names overwritefmt nformat(number_d1)	
	}	//	Table 4 ~ Table 8

	
	* Table 9-13
	if	`rep_table_9_13'==1	{
	
		mat	drop	_all
		mat	empty_row	=	J(1,1,.)
		
		foreach	year	in	1999	2001	2003	2015	2017	{	
			
			use	`dta_fam_`year'', clear
			
			foreach	fscat	in	MS	IS	VLS	{	//	Food security category
				
				*	Income categories
				svy, subpop(if	fs_cat_`fscat'`year'==1): proportion FPL_cat`year'
				mat	summary_FScat_`year'_`fscat'	=	nullmat(FPL_FScat_`year')	\	e(b)'	\	empty_row
				
				*	Racial categories
				svy, subpop(if	fs_cat_`fscat'`year'==1): proportion race_head_cat`year'
				mat	summary_FScat_`year'_`fscat'	=	summary_FScat_`year'_`fscat'	\	e(b)'	\	empty_row
				
				*	Marital status
				svy, subpop(if	fs_cat_`fscat'`year'==1): proportion marital_status_cat`year'
				mat	summary_FScat_`year'_`fscat'	=	summary_FScat_`year'_`fscat'	\	e(b)'	\	empty_row
				
				*	Children
				svy, subpop(if	fs_cat_`fscat'`year'==1): proportion child_in_FU_cat`year'
				mat	summary_FScat_`year'_`fscat'	=	summary_FScat_`year'_`fscat'	\	e(b)'	\	empty_row
				
				*	Age
				svy, subpop(if	fs_cat_`fscat'`year'==1): proportion age_head_cat`year'
				mat	summary_FScat_`year'_`fscat'	=	summary_FScat_`year'_`fscat'	\	e(b)'	\	empty_row
				
				*	Education (Grades Completed)
				svy, subpop(if	fs_cat_`fscat'`year'==1): proportion grade_comp_cat`year'
				mat	summary_FScat_`year'_`fscat'	=	summary_FScat_`year'_`fscat'	\	e(b)'	\	empty_row
				
				*	Gender
				svy, subpop(if	fs_cat_`fscat'`year'==1): proportion gender_head_fam`year'
				mat	summary_FScat_`year'_`fscat'	=	summary_FScat_`year'_`fscat'	\	e(b)'
					
				}
				
			*	Append
			mat	summary_FScat_`year'	=	summary_FScat_`year'_MS,	summary_FScat_`year'_IS,	summary_FScat_`year'_VLS
		}	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table9) modify
		putexcel	A2 = "Summary Statistics by Food Insecurity Category – 1998"
		putexcel	A3	=	matrix(summary_FScat_1999), names overwritefmt nformat(number_d1)	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table10) modify
		putexcel	A2 = "Summary Statistics by Food Insecurity Category – 2000"
		putexcel	A3	=	matrix(summary_FScat_2001), names overwritefmt nformat(number_d1)	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table11) modify
		putexcel	A2 = "Summary Statistics by Food Insecurity Category – 2002"
		putexcel	A3	=	matrix(summary_FScat_2003), names overwritefmt nformat(number_d1)	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table12) modify
		putexcel	A2 = "Summary Statistics by Food Insecurity Category – 2014"
		putexcel	A3	=	matrix(summary_FScat_2015), names overwritefmt nformat(number_d1)	
		
		putexcel	set "${PSID_outRaw}/Tiehen_2019_replication_raw", sheet(table13) modify
		putexcel	A2 = "Summary Statistics by Food Insecurity Category – 2016"
		putexcel	A3	=	matrix(summary_FScat_2017), names overwritefmt nformat(number_d1)	

	}
	
	* Table 14-18
	if	`rep_table_14_18'==1	{
	
		mat	drop	_all
		eststo	clear
		
		foreach	year	in	1999	2001	2003	2015	2017	{	
			
			use	`dta_fam_`year'', clear	
			
			/*
			tab fs_cat_fam`year', generate(fs_cat_`year'_)
			label	var	fs_cat_`year'_2	"PSID Marginal"
			label	var	fs_cat_`year'_3	"PSID Food Insecure"
			label	var	fs_cat_`year'_4	"PSID Very Low"
			*/
			
			eststo clear
			
			svy: reg	/*fs_cat_`year'_2*/	fs_cat_MS`year'	ib1.FPL_cat`year'	ib1.race_head_cat`year'	ib2.marital_status_cat`year'	///
								ib2.child_in_FU_cat`year'	ib1.age_head_cat`year'	ib1.grade_comp_cat`year'	///
								ib1.gender_head_fam`year'
			est	store	PSID_Marginal_`year'
			
			svy: reg	/*fs_cat_`year'_3*/	fs_cat_IS`year'	ib1.FPL_cat`year'	ib1.race_head_cat`year'	ib2.marital_status_cat`year'	///
								ib2.child_in_FU_cat`year'	ib1.age_head_cat`year'	ib1.grade_comp_cat`year'	///
								ib1.gender_head_fam`year'
			est	store	PSID_FoodInsecure_`year'
			
			svy: reg	/*fs_cat_`year'_4*/	fs_cat_VLS`year'	ib1.FPL_cat`year'	ib1.race_head_cat`year'	ib2.marital_status_cat`year'	///
								ib2.child_in_FU_cat`year'	ib1.age_head_cat`year'	ib1.grade_comp_cat`year'	///
								ib1.gender_head_fam`year'
			est	store	PSID_VeryLow_`year'
			
			esttab	PSID_Marginal_`year'	PSID_FoodInsecure_`year'	PSID_VeryLow_`year' using "${PSID_outRaw}/Tiehen_Reg_`year'.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Food Insecurity Estimates_`year') replace
		}
	*estout	PSID_Marginal_`year'	PSID_FoodInsecure_`year'	PSID_VeryLow_`year' using "${PSID_outRaw}/Table14.csv", cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Table 14. Food Insecurity Estimates – 1998) replace
	}
	
	
	/*
	
	Each table presents six sets of results that compare estimates of each of the three food insecurity measures between the two datasets, where the independent variables are the groups of demographic variables in the previous tables. The omitted categories are income less than 100%FPL, white, non-married, age 16-24, less than high school education, and male. Standard errors are corrected using Huber-White robust standard errors and survey weights are used
	
	
	
	mat	drop	_all
	
	use	`dta_fam_1999', clear
	svy: proportion fs_cat_fam1999
	clonevar	ER13002=x11102_1999
	merge	m:1	ER13002		using	"${PSID_dtRaw}/Main/fam1999er.dta", assert(1 3) keep(3) keepusing(ER16519) nogen
	svyset	ER31997 [pweight=weight_long_fam1999], strata(ER31996)

	
