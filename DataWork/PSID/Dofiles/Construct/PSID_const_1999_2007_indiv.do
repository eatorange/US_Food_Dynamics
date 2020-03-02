
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_const_1999_2017_ind
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Mar 01, 2020, by Seungmin Lee (slee31@worldbank.org)
	
	IDS VAR:    	x11101ll // Personal Identification Number

	DESCRIPTION: 	Construct PSID individual panel data from 1999 to 2017
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Data construction
						1.1	-	Construct descriptive variables
					2 - 
					X - Save and Exit
					
	INPUTS: 		* PSID 1999-2017 panel data (indiv)
					${PSID_dtInt}/PSID_clean_1999_2017_ind.dta

					
	OUTPUTS: 		* 
					
					
					* 
						

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
	loc	name_do	PSID_const_1999_2017_ind
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doCon}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
		
	/****************************************************************
		SECTION 1: Construct descriptive variables		 									
	****************************************************************/
	
	use	"${PSID_dtInt}/PSID_clean_1999_2017_ind.dta", clear
	
		
	*	Construct
		
		local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
		
		*	Relation to "current" reference person (head)
			foreach	year of local years	{
				
				*	Relation to current head
				generate	relat_to_current_head`year'	=.
				
				replace	relat_to_current_head`year'	=	1	if	xsqnr_`year'==1	&	relat_to_head`year'==10
				replace	relat_to_current_head`year'	=	2	if	xsqnr_`year'==2	&	inlist(relat_to_head`year',20,22)
				replace	relat_to_current_head`year'	=	3	if	inrange(xsqnr_`year',2,20)	&	inrange(relat_to_head`year',30,38)
				replace	relat_to_current_head`year'	=	4	if	!inrange(xsqnr_`year',1,20)	|	!inrange(relat_to_head`year',1,38)
				replace	relat_to_current_head`year'	=	.n	if	inlist(0,xsqnr_`year',relat_to_head`year')
				
				label	variable	relat_to_current_head`year'	"Relation to current head, `year'"
				
				note	relat_to_current_head`year': son/daughter includes stepson/daughter, son-in-law/daughter-in-law
								
			}
						
			label	define	relat_to_current_head	1	"Reference Person (Head)"	///
													2	"Spouse or partner"	///
													3	"Son/Daughter"	///
													4	"Other"
													
			label values	relat_to_current_head*	relat_to_current_head
			
		*	Sample source
		gen		sample_source=.
		replace	sample_source=1	if	inrange(x11101ll,1000,2930999)	//	SRC
		replace	sample_source=2	if	inrange(x11101ll,5001000,6872999)	//	SEO
		replace	sample_source=3	if	inrange(x11101ll,3001000,3511999)	//	Immgrant Regresher (1997,1999)
		replace	sample_source=4	if	inrange(x11101ll,4001000,4462999)	//	Immigrant Refresher (2017)
		replace	sample_source=5	if	inrange(x11101ll,7001000,9308999)	//	Latino Sample (1990-1992)
		
		label	define	sample_source		1	"SRC(Survey Research Center)"	///
											2	"SEO(Survey of Economic Opportunity)"	///
											3	"Immigrant Refresher (1997,1999)"	///
											4	"Immigrant Refresher (2017)"	///
											5	"Latino Sample (1990-1992)"
		label	values	sample_source		sample_source
		label	variable	sample_source	"Source of Sample"	
			
		
		*	Family Spllit-off (1999-2003)
		
			*	1999 Family ID (base-year)
			assert !mi( splitoff_indicator1999) if !mi( x11102_1999)
			generate	fam_ID_1999	=	x11102_1999	if	!mi(x11102_1999)
			lab	var	fam_ID_1999	"Family ID in 1999"
			
			*	Split-off indicator (binary, family_level)
			foreach year of local years	{
				
				local	var	splitoff_dummy`year'
				generate	`var'=.
				label	var	`var'	"Split-off dummy indicator"
				
				if	(`year'==1999)	{
					replace		`var'=0	if	inlist(splitoff_indicator`year',1,3,4)	// In 1999, "split-off from recontract family" is NOT actually split-off, but 70 immigrant refresher households.
					replace		`var'=1	if	splitoff_indicator`year'==2	
				}
				else	if	(`year'==2017)	{
					replace		`var'=0	if	inlist(splitoff_indicator`year',1,3,5)	// In 2017, "2017 New immigrant has value 5
					replace		`var'=1	if	inlist(splitoff_indicator`year',2,4)	
				}
				else	{
					replace		`var'=0	if	inlist(splitoff_indicator`year',1,3)	
					replace		`var'=1	if	inlist(splitoff_indicator`year',2,4)	
				}
		
			}
			label	values	splitoff_dummy*	yesno
			
			*	Number of split-off since 1999 (1999 is base-year, thus families splitted of in 1999 is not counted as split-off)
				local	years	2001 2003 2005 2007 2009 2011 2013 2015 2017
				foreach	year	of	local	years	{
				    egen	accum_splitoff`year'	=	rowtotal(splitoff_dummy2001-splitoff_dummy`year')
					replace	accum_splitoff`year'=.	if	x11102_`year'==.
					label	variable	accum_splitoff`year' "# of split-offs since 1999"
				}
				
			
				
		

			*	Respondent Consistency Indicator (family-level)
				
				*	1999-2001
				local	surveyed	!mi(x11102_1999)	&	!mi(x11102_2001)
				local	reinterview	splitoff_indicator2001==1
				gen 	resp_consist_99_01_tmp	=.
				replace	resp_consist_99_01_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent1999==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_99_01_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent1999==1	&	respondent2001==1	//	Numerator: same respondents out of sample
				bys	x11102_2001: egen resp_consist_99_01=max(resp_consist_99_01_tmp)
				drop	resp_consist_99_01_tmp
				label	var	resp_consist_99_01	"Respondent is consistent"
				
				*	1999-2003
				local	surveyed	!mi(x11102_1999)	&	!mi(x11102_2001)	&	!mi(x11102_2003)
				local	reinterview	splitoff_indicator2001==1	&	splitoff_indicator2003==1
				gen 	resp_consist_99_03_tmp	=.
				replace	resp_consist_99_03_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent1999==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_99_03_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent1999==1	&	respondent2001==1	&	respondent2003==1	//	Numerator: same respondents out of sample
				bys	x11102_2003: egen resp_consist_99_03=max(resp_consist_99_03_tmp)
				drop	resp_consist_99_03_tmp
				label	var	resp_consist_99_03	"Respondent is consistent"
				
				*	1999-2015
				local	surveyed	!mi(x11102_1999)	&	!mi(x11102_2001)	&	!mi(x11102_2003)	&	!mi(x11102_2005)	&	!mi(x11102_2007)	&	!mi(x11102_2009)	&	!mi(x11102_2011)	&	!mi(x11102_2013)	&	!mi(x11102_2015)
				local	reinterview	splitoff_indicator2001==1	&	splitoff_indicator2003==1	&	splitoff_indicator2005==1	&	splitoff_indicator2007==1	&	splitoff_indicator2009==1	&	splitoff_indicator2011==1	&	splitoff_indicator2013==1	&	splitoff_indicator2015==1
				local	respondent_same	respondent2001==1	&	respondent2003==1	&	respondent2005==1	&	respondent2007==1	&	respondent2009==1	&	respondent2011==1	&	respondent2013==1	&	respondent2015==1				
				gen 	resp_consist_99_15_tmp	=.
				replace	resp_consist_99_15_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent1999==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_99_15_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent1999==1	&	`respondent_same'	//	Numerator: same respondents out of sample
				bys	x11102_2015: egen resp_consist_99_15=max(resp_consist_99_15_tmp)
				drop	resp_consist_99_15_tmp
				label	var	resp_consist_99_15	"Respondent is consistent"
				
				*	1999-2017
				local	surveyed	!mi(x11102_1999)	&	!mi(x11102_2001)	&	!mi(x11102_2003)	&	!mi(x11102_2005)	&	!mi(x11102_2007)	&	!mi(x11102_2009)	&	!mi(x11102_2011)	&	!mi(x11102_2013)	&	!mi(x11102_2015)	&	!mi(x11102_2017)
				local	reinterview	splitoff_indicator2001==1	&	splitoff_indicator2003==1	&	splitoff_indicator2005==1	&	splitoff_indicator2007==1	&	splitoff_indicator2009==1	&	splitoff_indicator2011==1	&	splitoff_indicator2013==1	&	splitoff_indicator2015==1	&	splitoff_indicator2017==1
				local	respondent_same	respondent2001==1	&	respondent2003==1	&	respondent2005==1	&	respondent2007==1	&	respondent2009==1	&	respondent2011==1	&	respondent2013==1	&	respondent2015==1	&	respondent2017==1			
				gen 	resp_consist_99_17_tmp	=.
				replace	resp_consist_99_17_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent1999==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_99_17_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent1999==1	&	`respondent_same'	//	Numerator: same respondents out of sample
				bys	x11102_2017: egen resp_consist_99_17=max(resp_consist_99_17_tmp)
				drop	resp_consist_99_17_tmp
				label	var	resp_consist_99_17	"Respondent is consistent"
				
				*	2001-2003
				local	surveyed	!mi(x11102_2001)	&	!mi(x11102_2003)
				local	reinterview	splitoff_indicator2003==1
				gen 	resp_consist_01_03_tmp	=.
				replace	resp_consist_01_03_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent2001==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_01_03_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent2001==1	&	respondent2003==1	//	Numerator: same respondents out of sample
				bys	x11102_2003: egen resp_consist_01_03=max(resp_consist_01_03_tmp)
				drop	resp_consist_01_03_tmp
				label	var	resp_consist_01_03	"Respondent is consistent"
			
				
				*	2001-2015
				local	surveyed	!mi(x11102_2001)	&	!mi(x11102_2003)	&	!mi(x11102_2005)	&	!mi(x11102_2007)	&	!mi(x11102_2009)	&	!mi(x11102_2011)	&	!mi(x11102_2013)	&	!mi(x11102_2015)
				local	reinterview	splitoff_indicator2003==1	&	splitoff_indicator2005==1	&	splitoff_indicator2007==1	&	splitoff_indicator2009==1	&	splitoff_indicator2011==1	&	splitoff_indicator2013==1	&	splitoff_indicator2015==1
				local	respondent_same	respondent2003==1	&	respondent2005==1	&	respondent2007==1	&	respondent2009==1	&	respondent2011==1	&	respondent2013==1	&	respondent2015==1				
				gen 	resp_consist_01_15_tmp	=.
				replace	resp_consist_01_15_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent2001==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_01_15_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent2001==1	&	`respondent_same'	//	Numerator: same respondents out of sample
				bys	x11102_2015: egen resp_consist_01_15=max(resp_consist_01_15_tmp)
				drop	resp_consist_01_15_tmp
				label	var	resp_consist_01_15	"Respondent is consistent"
				
				*	2001-2017
				local	surveyed	!mi(x11102_2001)	&	!mi(x11102_2003)	&	!mi(x11102_2005)	&	!mi(x11102_2007)	&	!mi(x11102_2009)	&	!mi(x11102_2011)	&	!mi(x11102_2013)	&	!mi(x11102_2015)	&	!mi(x11102_2017)
				local	reinterview	splitoff_indicator2003==1	&	splitoff_indicator2005==1	&	splitoff_indicator2007==1	&	splitoff_indicator2009==1	&	splitoff_indicator2011==1	&	splitoff_indicator2013==1	&	splitoff_indicator2015==1	&	splitoff_indicator2017==1
				local	respondent_same	respondent2003==1	&	respondent2005==1	&	respondent2007==1	&	respondent2009==1	&	respondent2011==1	&	respondent2013==1	&	respondent2015==1	&	respondent2017==1			
				gen 	resp_consist_01_17_tmp	=.
				replace	resp_consist_01_17_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent2001==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_01_17_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent2001==1	&	`respondent_same'	//	Numerator: same respondents out of sample
				bys	x11102_2017: egen resp_consist_01_17=max(resp_consist_01_17_tmp)
				drop	resp_consist_01_17_tmp
				label	var	resp_consist_01_17	"Respondent is consistent"
				
				*	2003-2015
				local	surveyed	!mi(x11102_2003)	&	!mi(x11102_2005)	&	!mi(x11102_2007)	&	!mi(x11102_2009)	&	!mi(x11102_2011)	&	!mi(x11102_2013)	&	!mi(x11102_2015)
				local	reinterview	splitoff_indicator2005==1	&	splitoff_indicator2007==1	&	splitoff_indicator2009==1	&	splitoff_indicator2011==1	&	splitoff_indicator2013==1	&	splitoff_indicator2015==1
				local	respondent_same	respondent2005==1	&	respondent2007==1	&	respondent2009==1	&	respondent2011==1	&	respondent2013==1	&	respondent2015==1				
				gen 	resp_consist_03_15_tmp	=.
				replace	resp_consist_03_15_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent2003==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_03_15_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent2003==1	&	`respondent_same'	//	Numerator: same respondents out of sample
				bys	x11102_2015: egen resp_consist_03_15=max(resp_consist_03_15_tmp)
				drop	resp_consist_03_15_tmp
				label	var	resp_consist_03_15	"Respondent is consistent"
				
				*	2003-2017
				local	surveyed	!mi(x11102_2003)	&	!mi(x11102_2005)	&	!mi(x11102_2007)	&	!mi(x11102_2009)	&	!mi(x11102_2011)	&	!mi(x11102_2013)	&	!mi(x11102_2015)	&	!mi(x11102_2017)
				local	reinterview	splitoff_indicator2005==1	&	splitoff_indicator2007==1	&	splitoff_indicator2009==1	&	splitoff_indicator2011==1	&	splitoff_indicator2013==1	&	splitoff_indicator2015==1	&	splitoff_indicator2017==1
				local	respondent_same	respondent2005==1	&	respondent2007==1	&	respondent2009==1	&	respondent2011==1	&	respondent2013==1	&	respondent2015==1	&	respondent2017==1			
				gen 	resp_consist_03_17_tmp	=.
				replace	resp_consist_03_17_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent2003==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_03_17_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent2003==1	&	`respondent_same'	//	Numerator: same respondents out of sample
				bys	x11102_2017: egen resp_consist_03_17=max(resp_consist_03_17_tmp)
				drop	resp_consist_03_17_tmp
				label	var	resp_consist_03_17	"Respondent is consistent"
				
				*	2015-2017
				local	surveyed	!mi(x11102_2015)	&	!mi(x11102_2017)
				local	reinterview	splitoff_indicator2017==1
				gen 	resp_consist_15_17_tmp	=.
				replace	resp_consist_15_17_tmp	=0	if	`surveyed'	&	`reinterview'	&	respondent2001==1	//	Denominator (sample): surveyed in all years as reinterview family
				replace	resp_consist_15_17_tmp	=1	if	`surveyed'	&	`reinterview'	&	respondent2001==1	&	respondent2003==1	//	Numerator: same respondents out of sample
				bys	x11102_2017: egen resp_consist_15_17=max(resp_consist_15_17_tmp)
				drop	resp_consist_15_17_tmp
				label	var	resp_consist_15_17	"Respondent is consistent"
				
				label	values	resp_consist*	yesno


	/****************************************************************
		SECTION X: Save and Exit
	****************************************************************/
	
	
	* Make dta
		
		*	Individual data
		notes	drop _dta
		notes:	PSID_const_1999_2017_ind / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID individual panel data from 1999 to 2017,
		*notes:	Only individuals appear in all waves are included.
		

		* Git branch info
		stgit9 
		notes : PSID_const_1999_2017_ind / Git branch `r(branch)'; commit `r(sha)'.
	
	
		* Sort, order and save dataset
		/*
		loc	IDvars		HHID_survey HHID_old_Feb22
		loc	Geovars		District Village CDCID Masjid
		loc	HHvars		hhhead_gender hhhead_name father_spouse_name relationship_hhhead
		loc	PRAvars		SNo-PRA_remarks PRA_multiple_results
		loc	eligvars	TUP_eligible_initial TUP_eligible_Feb22 TUP_eligible_Mar10
		loc	surveyvars	survey_done_Mar10 survey_sample
		
		sort	`IDvars'	`Geovars'	`HHvars'	`PRAvars'	`eligvars'	`surveyvars'
		order	`IDvars'	`Geovars'	`HHvars'	`PRAvars'	`eligvars'	`surveyvars'
	*/
	
		qui		compress
		save	"${PSID_dtFin}/PSID_const_1999_2017_ind.dta", replace
	
	/*
		* Save log
		cap file		close _all
		cap log			close
		copy			"${bl_do_cleaning}/logs/`name_do'.smcl" ///
						"${bl_do_cleaning}/logs/archive/`name_do' - `c(current_date)' - `c(username)'.smcl", replace
		*/
	
	* Exit	
	exit
			