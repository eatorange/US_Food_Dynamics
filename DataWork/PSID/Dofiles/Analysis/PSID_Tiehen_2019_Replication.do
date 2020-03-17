
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
		gen		age_head_cat`year'=.
		replace	age_head_cat`year'=1		if	inrange(age_head_fam`year',16,24)
		replace	age_head_cat`year'=2		if	inrange(age_head_fam`year',25,34)
		replace	age_head_cat`year'=3		if	inrange(age_head_fam`year',35,44)
		replace	age_head_cat`year'=4		if	inrange(age_head_fam`year',45,54)
		replace	age_head_cat`year'=5		if	inrange(age_head_fam`year',55,64)
		replace	age_head_cat`year'=6		if	age_head_fam`year'>=65	&	!mi(age_head_fam`year'>=65)
		
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
	
	*	Save
	*clonevar	ER13002=x11102_1999
	tempfile	dta_constructed
	save		`dta_constructed'
	
	/****************************************************************
		SECTION 2: Replication
	****************************************************************/		
		
	*	Before replicating, import variables for sampling error estimation
		use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
		*	Generate a single ID variable
		generate	x11101ll=(ER30001*1000)+ER30002
		
		tempfile	Ind
		save		`Ind'
	
	*	Import variables
	use	`dta_constructed', clear
	merge	m:1	x11101ll	using	`Ind', assert(2 3) keep(3) keepusing(ER31996 ER31997) nogen
	*merge	m:1	ER13002		using	"${PSID_dtRaw}/Main/fam1999er.dta", assert(1 3) keep(3) keepusing(ER16519) nogen
	
	save	`dta_constructed', replace
	
	* Since the data is individual level but paper uses family-level data, we need to either (1) keep family variables only or (2) use only one observation per family.
	*	We will do (1)
	
	*	Create	yearly data
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			use	`dta_constructed', clear
			keep	x11102_`year'	weight_long_fam`year'	age_head_fam`year'	race_head_fam`year'	total_income_fam`year'	///	
					marital_status_fam`year'	num_FU_fam`year'	num_child_fam`year'	gender_head_fam`year'	edu_years_head_fam`year'	///
					state_resid_fam`year'	sample_source FPL_`year' FPL_cat`year' grade_comp_cat`year' race_head_cat`year'	///
					marital_status_cat`year' child_in_FU_cat`year' age_head_cat`year'	fs_cat_fam`year' ER31996 ER31997	/*ER16519*/
			drop	if	mi(x11102_`year')
			duplicates drop
			svyset	ER31997 [pweight=weight_long_fam`year'], strata(ER31996)
			
			tempfile	dta_fam_`year'
			save		`dta_fam_`year''
		}
	
	/*
	* Table 2

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
	*/
	*	Table 3
	mat	drop	_all
	
	use	`dta_fam_2001', clear
	svy: proportion fs_cat_fam2001
	
	/*
	*	Keep variables on interest only in 1999
	keep x11102_1999 weight_long_fam1999 age_head_fam1999 race_head_fam1999 total_income_fam1999 marital_status_fam1999 num_FU_fam1999 num_child_fam1999 gender_head_fam1999 edu_years_head_fam1999 state_resid_fam1999
	duplicates drop
	drop	if	mi(x11102_1999)
	
	