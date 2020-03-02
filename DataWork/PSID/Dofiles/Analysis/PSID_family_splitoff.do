
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_family_splitoff
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Mar 01, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	Fx11101ll // Personal Identification Number

	DESCRIPTION: 	Generate family splitoff & respondent status
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Descriptive Stats
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID 1999 Constructed (family)
					${PSID_dtInt}/PSID_const_1999_fam.dta
					
					* PSID 1999 Constructed (individual)
					${PSID_dtInt}/PSID_const_1999_ind.dta
			
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
	loc	name_do	PSID_family_splitoff
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doAnl}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1: Summary stats 
	****************************************************************/		
	
	use	"${PSID_dtFin}/PSID_const_1999_2017_ind.dta", clear
	
	*	Descriptive Stats
	
		*	Individual level
		
			*	Member status of respodents
			foreach	year of local years	{
				tabulate relat_to_current_head`year'	if	respondent`year'==1			
			}
			
		*	Family-level
			
			*	Keep family-level variables only
			keep	x11102* splitoff* num_split* main_fam* sample_source splitoff_dummy*	resp_consist* accum_*
			duplicates drop
			tempfile	family_crosswave
			save		`family_crosswave'
		
			*	Respondent consistency (family-level)
			tab	resp_consist_99_01
			tab	resp_consist_99_03
			tab	resp_consist_99_15
			tab	resp_consist_99_17
			tab	resp_consist_01_03
			tab	resp_consist_01_15
			tab	resp_consist_01_17
			tab	resp_consist_03_15
			tab	resp_consist_03_17
			tab	resp_consist_15_17
			
			*	# of split-offs
			tab	accum_splitoff2001
			tab	accum_splitoff2003
			tab	accum_splitoff2005
			tab	accum_splitoff2007
			tab	accum_splitoff2009
			tab	accum_splitoff2011
			tab	accum_splitoff2013
			tab	accum_splitoff2015
			tab	accum_splitoff2017
			       
		
	
/*

		
		
		*	Individual file
		use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
		
			*	Survey respondents
			clonevar	respondent1999	=	ER33511
			clonevar	respondent2001	=	ER33611
			clonevar	respondent2003	=	ER33711
			clonevar	respondent2015	=	ER34312
			clonevar	respondent2017	=	ER34511
			
			
			
			*	Relation to head (reference person)
			clonevar	relat_to_head1999	=	ER33503
			clonevar	relat_to_head2001	=	ER33603
			clonevar	relat_to_head2003	=	ER33703
			clonevar	relat_to_head2015	=	ER34303
			clonevar	relat_to_head2017	=	ER34503
			
				
			
			label values	respondent_*	yesno
			
			*	Relation to "current" head
			gen	relation_to_head1999=.
			gen	relation_to_head2001=.
			gen	relation_to_head2003=.
			gen	relation_to_head2015=.
			gen	relation_to_head2017=.
		
	
		*	Clean
			
			
		/*
			local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
			foreach	year of local years	{
			    if	`year'==1999	{
					local	surveyed 1999
				}
				else	{
				    local	surveyed	`surveyed'	&	`year'
				}
				
			}
			di "surveyed is `surveyed'"
			*/
			