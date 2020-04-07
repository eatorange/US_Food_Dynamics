
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
				
	*	Federal Poverty Line
	
		*	1998 HHS Poverty Guideline (https://aspe.hhs.gov/1998-hhs-poverty-guidelines)
		scalar	FPL_base_48_1999	=	8050
		scalar	FPL_base_AL_1999	=	10070
		scalar	FPL_base_HA_1999	=	9260
		scalar	FPL_mult_48_1999	=	2800
		scalar	FPL_mult_AL_1999	=	3500
		scalar	FPL_mult_HA_1999	=	3200
		
		*	2000 HHS Poverty Guideline (https://aspe.hhs.gov/2000-hhs-poverty-guidelines)
		scalar	FPL_base_48_2001	=	8350
		scalar	FPL_base_AL_2001	=	10430
		scalar	FPL_base_HA_2001	=	9590
		scalar	FPL_mult_48_2001	=	2900
		scalar	FPL_mult_AL_2001	=	3630
		scalar	FPL_mult_HA_2001	=	3340
		
		*	2002 HHS Poverty Guideline (https://aspe.hhs.gov/2002-hhs-poverty-guidelines)
		scalar	FPL_base_48_2003	=	8860
		scalar	FPL_base_AL_2003	=	11080
		scalar	FPL_base_HA_2003	=	10200
		scalar	FPL_mult_48_2003	=	3080
		scalar	FPL_mult_AL_2003	=	3850
		scalar	FPL_mult_HA_2003	=	3540
		
		*	2014 HHS Poverty Guideline (https://aspe.hhs.gov/2014-hhs-poverty-guidelines)
		scalar	FPL_base_48_2015	=	11670
		scalar	FPL_base_AL_2015	=	14580
		scalar	FPL_base_HA_2015	=	13420
		scalar	FPL_mult_48_2015	=	4060
		scalar	FPL_mult_AL_2015	=	5080
		scalar	FPL_mult_HA_2015	=	4670
		
		*	2016 HHS Poverty Guideline (https://aspe.hhs.gov/2014-hhs-poverty-guidelines)
		*	2016 Line has complicated design
		scalar	FPL_base_48_2017	=	11880
		scalar	FPL_base_AL_2017	=	14850	//	11,880 * 1.25 (AL scaling factor)
		scalar	FPL_base_HA_2017	=	13660	//	11,880 * 1.25 (HA scaling factor)
		scalar	FPL_mult_48_2017	=	4140	
		scalar	FPL_mult_AL_2017	=	5180	//	4,140 * 1.25 (AL scaling factor)
		scalar	FPL_mult_HA_2017	=	4670	//	4,760 * 1.15 (HA scaling factor)
		
		scalar	FPL_line_48_7_2017	=	36730	//	(6 members + 4,150)
		scalar	FPL_line_AL_7_2017	=	45920
		scalar	FPL_line_HA_7_2017	=	42230
		
		scalar	FPL_mult_48_over7_2017	=	4160	
		scalar	FPL_mult_AL_over7_2017	=	5200	//	4,160 * 1.25 (AL scaling factor)
		scalar	FPL_mult_HA_over7_2017	=	4780	//	4,160 * 1.15 (HA scaling factor)
		

		*	Calculate FPL

			*	1999-2003, 2015
			foreach	year	in	1999	2001	2003	2015	{
				gen 	FPL_`year'	=	FPL_base_48_`year'	+	(num_FU_fam`year'-1)*FPL_mult_48_`year'	if	inrange(state_resid_fam`year',1,49)
				replace	FPL_`year'	=	FPL_base_AL_`year'	+	(num_FU_fam`year'-1)*FPL_mult_AL_`year'	if	state_resid_fam`year'==50
				replace	FPL_`year'	=	FPL_base_HA_`year'	+	(num_FU_fam`year'-1)*FPL_mult_HA_`year'	if	state_resid_fam`year'==51
				*replace	FPL_`year'	=.	if	inrange(xsqnr_`year',1,89)	&	state_resid_fam`year'==0	//	Inappropriate state
				*replace	FPL_`year'	=.n	if	!inrange(xsqnr_`year',1,89)		//	Outside wave
				label	var	FPL_`year'	"Federal Poverty Line, `year'"
			}
			
			*	2017 (2016 FPL) has different design as below.
				
				*	Families with member 6 or below.
				gen 	FPL_2017	=	FPL_base_48_2017	+	(num_FU_fam2017-1)*FPL_mult_48_2017	if	num_FU_fam2017<=6	&	inrange(state_resid_fam2017,1,49)
				replace	FPL_2017	=	FPL_base_AL_2017	+	(num_FU_fam2017-1)*FPL_mult_AL_2017	if	num_FU_fam2017<=6	&	state_resid_fam2017==50
				replace	FPL_2017	=	FPL_base_HA_2017	+	(num_FU_fam2017-1)*FPL_mult_HA_2017	if	num_FU_fam2017<=6	&	state_resid_fam2017==51
				
				*	Families with 7 members
				replace	FPL_2017	=	FPL_line_48_7_2017	if	num_FU_fam2017==7	&	inrange(state_resid_fam2017,1,49)
				replace	FPL_2017	=	FPL_line_AL_7_2017	if	num_FU_fam2017==7	&	state_resid_fam2017==50
				replace	FPL_2017	=	FPL_line_HA_7_2017	if	num_FU_fam2017==7	&	state_resid_fam2017==51
				
				*	Families with 8 or more members
				replace	FPL_2017	=	FPL_line_48_7_2017	+	(num_FU_fam2017-7)*FPL_mult_48_over7_2017	if	num_FU_fam2017>=8	&	inrange(state_resid_fam2017,1,49)
				replace	FPL_2017	=	FPL_line_AL_7_2017	+	(num_FU_fam2017-7)*FPL_mult_AL_over7_2017	if	num_FU_fam2017>=8	&	state_resid_fam2017==50
				replace	FPL_2017	=	FPL_line_HA_7_2017	+	(num_FU_fam2017-7)*FPL_mult_HA_over7_2017	if	num_FU_fam2017>=8	&	state_resid_fam2017==51
				
				*	Missing values
				replace	FPL_2017	=.	if	inrange(xsqnr_2017,1,89)	&	state_resid_fam2017==0	//	Inappropriate state
				replace	FPL_2017	=.n	if	!inrange(xsqnr_2017,1,89)		//	Outside wave
				
				label	var	FPL_2017	"Federal Poverty Line, 2017"
				
			*	FPL Category
			foreach	year	in	1999	2001	2003	2015	2017	{
				*gen		FPL_cat`year'=.
				*replace	FPL_cat`year'=1	if	total_income_fam`year'<FPL_`year'
				generate	FPL_cat`year'=1	if	total_income_fam`year'<FPL_`year'
				replace		FPL_cat`year'=2	if	inrange(total_income_fam`year',FPL_`year',2*FPL_`year')
				replace		FPL_cat`year'=3	if	total_income_fam`year'>=2*FPL_`year'
				replace		FPL_cat`year'=.	if	mi(FPL_`year')
				label	var	FPL_cat`year'	"Income Category(FPL), `year'"
			}
			
			label	define	income_cat_FPL	1	"<100% FPL"	2	"100%~200% FPL"	3	">200% FPL"	0	"Inappropriate"
			label	values	FPL_cat*	income_cat_FPL
		
		
		*	Education	(category)
			foreach	year	in	1999	2001	2003	2015	2017	{
				gen		grade_comp_cat`year'	=1	if	inrange(edu_years_head_fam`year',0,11)
				replace	grade_comp_cat`year'	=2	if	inrange(edu_years_head_fam`year',12,12)
				replace	grade_comp_cat`year'	=3	if	inrange(edu_years_head_fam`year',13,15)
				replace	grade_comp_cat`year'	=4	if	edu_years_head_fam`year'>=16 & !mi(edu_years_head_fam`year')
				replace	grade_comp_cat`year'	=.n	if	mi(edu_years_head_fam`year')
				label	var	grade_comp_cat`year'	"Grade Household Head Completed, `year'"
			}
			
			label	define	grade_comp_cat	1	"Less than HS"	2	"HS"	3	"Some College"	4	"College Degree"
			label 	values	grade_comp_cat*	grade_comp_cat
			
			
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
			