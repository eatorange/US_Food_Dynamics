
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
	
	use	"${PSID_dtInt}/PSID_clean_1999_2017_ind.dta",	clear
	
	*	Racial category
	foreach	year	in	1999 2001 2003 2015 2017	{
	    gen		race_head_cat`year'=.
		replace	race_head_cat`year'=1	if	race_head_fam`year'==1
		replace	race_head_cat`year'=2	if	race_head_fam`year'==2
		replace	race_head_cat`year'=3	if	inrange(race_head_fam`year',3,7)
		replace	race_head_cat`year'=.n	if	inrange(race_head_fam`year',8,9)
		
		label variable	race_head_cat`year'	"Racial Category of Head, `year'"
	}
	label	define	race_cat	1	"White"	2	"Black"	3	"Others"
	label	values	race_head_cat*	race_cat
	
	
	* Since the data is individual level but paper uses family-level data, we need to either (1) keep family variables only or (2) use only one observation per family.
	*	We will do (1)
	
	/*
	*	Keep variables on interest only in 1999
	keep x11102_1999 weight_long_fam1999 age_head_fam1999 race_head_fam1999 total_income_fam1999 marital_status_fam1999 num_FU_fam1999 num_child_fam1999 gender_head_fam1999 edu_years_head_fam1999 state_resid_fam1999
	duplicates drop
	drop	if	mi(x11102_1999)
	
	