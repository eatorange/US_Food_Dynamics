
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_tracking_fam_resp
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Feb 24, 2020, by Seungmin Lee (slee31@worldbank.org)
	
	IDS VAR:    	ER13002         // 1999 Family ID

	DESCRIPTION: 	Track families and respondent between 1999-2003, 2015-2017
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Data construction
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID 1999 cleaned (family)
					${PSID_dtInt}/PSID_clean_1999_fam.dta
					
					* PSID 1999 cleaned (individual)
					${PSID_dtInt}/PSID_clean_1999_ind.dta
					
	OUTPUTS: 		* PSID 1999 Constructed (family)
					${PSID_dtInt}/PSID_const_1999_fam.dta
					
					* PSID 1999 Constructed (individual)
					${PSID_dtInt}/PSID_const_1999_ind.dta
					

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
	version			16

	* Set basic memory limits
	set maxvar 		32767
	set matsize		11000

	* Set default options
	set more		off
	pause			on
	set varabbrev	off
	
	* Filename and log
	loc	name_do	PSID_construct
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doCon}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1: Prepare data
	****************************************************************/	
	
	*	Individual file
	use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
		*	Define variable label for multiple variables
		label define	yesno	1	"Yes"	0	"No"
		
		*	1999 Survey respondent
		local	var	respondent_1999
		generate	`var'	=	1	if	ER33511==1
		replace		`var'	=	0	if	ER33511==5
		replace		`var'	=	.n	if	ER33511==0
		
		*	2001 Survey respondent
		local	var	respondent_2001
		generate	`var'	=	1	if	ER33611==1
		replace		`var'	=	0	if	ER33611==5
		replace		`var'	=	.n	if	ER33611==0
		
		*	2001 Survey respondent
		local	var	respondent_2003
		generate	`var'	=	1	if	ER33711==1
		replace		`var'	=	0	if	ER33711==5
		replace		`var'	=	.n	if	ER33711==0
		
		label values	respondent_*	yesno
		
		*	Relation to "current" head
		gen	relation_to_head_1999=.
		gen	relation_to_head_2001=.
		gen	relation_to_head_2003=.
		gen	relation_to_head_2015=.
		gen	relation_to_head_2017=.
		
			*	As PSID stated, we will use the combination of "relation to head" and "sequnce number"
			
				*	Define variable label to be applied
				label	define	relat_to_current_head	1	"Reference Person"	///
														2	"Spouse"	///
														3	"Son/Daughter"	///
														4	"Other"
														
				
				*	Head (sequence==1 & relation to head==1)
				replace	relation_to_head_1999	=	1	if	ER33502==1	&	ER33503==10
				
				
	
	