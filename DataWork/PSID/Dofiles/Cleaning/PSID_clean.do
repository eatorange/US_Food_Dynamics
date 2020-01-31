
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_clean
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Sep 13, 2016, by Seungmin Lee (slee31@worldbank.org)
	
	IDS VAR:    	list_ID_var_here         // Uniquely identifies households (update for your project)

	DESCRIPTION: 	Cleans PSID Data
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Data cleaning
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID Data
			
	OUTPUTS: 		* Cleaned Data

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
	loc	name_do	PSID_clean
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doCln}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1.1: Merge PSID data over the period of interest
	****************************************************************/	
	
	use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\Cross_year_individual\Cross_year_individual.dta", clear
	
	rename	ER33501	fam_interview_id_1999
	tempfile	cross_indiv
	save		`cross_indiv'
	
	*	Use 1999 data as a starting year
	use	"${PSID_dtRaw}/Main/fam1999/FAM1999.dta", clear
	
	*	Generate year variable
	gen	year=1999
	label variable	year	"Survey Year"
	
	*	Clone 1999 family interview ID to be used as merging ID
	clonevar	fam_interview_id_1999	=	ER13002
			
		*	Rename variables
	rename	(ER13002)	///
			(fam_interview_id)
	rename	(ER13008A)	///
			(family_composition)
	rename	(ER16515A1 ER16515A2 ER16515A3 ER16515A4)	///
			(food_exp_tot	food_exp_athome	food_exp_away	food_exp_delivered)
			
	*	Keep relevant variables only
	
		loc	ID_vars			fam_interview_id	fam_interview_id_1999 	//	ID variables
		loc	family_vars		family_composition	//	Family composition, etc.
		loc	food_exp_vars	food_exp_tot	food_exp_athome	food_exp_away	food_exp_delivered
		
		keep	`ID_vars'	`family_vars'	`food_exp_vars'	year
		
		tempfile	fam_1999
		save		`fam_1999'
		
	merge 1:m		fam_interview_id_1999	using	`cross_indiv',	nogen	assert(2 3)	keep(3)

