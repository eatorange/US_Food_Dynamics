
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
			
		
		*	Family Composition Change
		
			*	As the first step, we construct the maximum sequence number per each family unit per each wave
			*	This maximum sequence number will be used to detect whether family unit has change in composition
			*	This step is needed as "family composition change" variable is not enough: there are families which recorded "no family change" but some family members actually moved out (either to institution or to form other FU)
			*	This could be the reason why PSID guide movie suggested to "keep individuals with a sequence number 1-20"
			
			foreach	year	in	1999	2001	2003	2015	2017	{			
				cap	drop	max_sequence_no`year'
				bys	x11102_`year':	egen	max_sequence_no`year'	=	max(xsqnr_`year')
				label	var	max_sequence_no`year'	"Maximum sequence number of FU in `year'"
			}
			

			*	No change (1999-2003, 1999 as base year)
			local	var	fam_comp_nochange_99_03
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0		if	inrange(xsqnr_1999,1,89)
			replace	`var'=1		if	inrange(xsqnr_1999,1,89)	///	/*	All individuals	as of 1999	*/
								&	family_comp_change2001==0	&	inrange(max_sequence_no2001,1,20)	///	/*	No member change in 2001	*/
								&	family_comp_change2003==0	&	inrange(max_sequence_no2003,1,20)	//	/*	No member change in 2003	*/
			label	var	`var'	"FU has no member change during 1999-2003"
			
			*	Same household head (1999-2003, 1999 as base year)
			local	var	fam_comp_samehead_99_03
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0		if	inrange(xsqnr_1999,1,89)
			replace	`var'=1		if	relat_to_head1999==10	&	xsqnr_1999==1	///	/*	Head in 1999	*/
								&	inrange(family_comp_change2001,0,2)	&	relat_to_head2001==10	&	xsqnr_2001==1	///	/*	Head in 2001	*/
								&	inrange(family_comp_change2003,0,2)	&	relat_to_head2003==10	&	xsqnr_2003==1	/*	Head in 2003	*/
			label	var	`var'	"FU has same household head during 1999-2003"
			
			*	Same household head (1999-2017, 1999 as base year)
				
				*	Condition macro
				local	nochange_hh	relat_to_head1999==10	&	xsqnr_1999==1
				foreach	year	in	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
					local	nochange_hh	`nochange_hh'	&	inrange(family_comp_change`year',0,2)	&	relat_to_head`year'==10	&	xsqnr_`year'==1
				}
				di "`nochange_hh'"
				
				local	var	fam_comp_samehead_99_17
				cap	drop	`var'
				gen		`var'=.
				replace	`var'=0		if	inrange(xsqnr_1999,1,89)
				replace	`var'=1		if	`nochange_hh'	//	No change in HH member other than head since 1999 to 2017
				label	var	`var'	"FU has same household head during 1999-2017"

			drop	max_sequence_no*			
		
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
		
		*	2004 HHS Poverty Guideline (https://aspe.hhs.gov/2004-hhs-poverty-guidelines)
		scalar	FPL_base_48_2005	=	9310
		scalar	FPL_base_AL_2005	=	11630
		scalar	FPL_base_HA_2005	=	10700
		scalar	FPL_mult_48_2005	=	3180
		scalar	FPL_mult_AL_2005	=	3980
		scalar	FPL_mult_HA_2005	=	3660
		
		*	2006 HHS Poverty Guideline (https://aspe.hhs.gov/2006-hhs-poverty-guidelines)
		scalar	FPL_base_48_2007	=	9800
		scalar	FPL_base_AL_2007	=	12250
		scalar	FPL_base_HA_2007	=	11270
		scalar	FPL_mult_48_2007	=	3400
		scalar	FPL_mult_AL_2007	=	4250
		scalar	FPL_mult_HA_2007	=	3910
		
		*	2008 HHS Poverty Guideline (https://aspe.hhs.gov/2008-hhs-poverty-guidelines)
		scalar	FPL_base_48_2009	=	10400
		scalar	FPL_base_AL_2009	=	13000
		scalar	FPL_base_HA_2009	=	11960
		scalar	FPL_mult_48_2009	=	3600
		scalar	FPL_mult_AL_2009	=	4500
		scalar	FPL_mult_HA_2009	=	4140
		
		*	2010 HHS Poverty Guideline (https://aspe.hhs.gov/2010-hhs-poverty-guidelines)
		scalar	FPL_base_48_2011	=	10830
		scalar	FPL_base_AL_2011	=	13530
		scalar	FPL_base_HA_2011	=	12460
		scalar	FPL_mult_48_2011	=	3740
		scalar	FPL_mult_AL_2011	=	4680
		scalar	FPL_mult_HA_2011	=	4300
		
		*	2012 HHS Poverty Guideline (https://aspe.hhs.gov/2012-hhs-poverty-guidelines)
		scalar	FPL_base_48_2013	=	11170
		scalar	FPL_base_AL_2013	=	13970
		scalar	FPL_base_HA_2013	=	12860
		scalar	FPL_mult_48_2013	=	3960
		scalar	FPL_mult_AL_2013	=	4950
		scalar	FPL_mult_HA_2013	=	4550
		
		*	2014 HHS Poverty Guideline (https://aspe.hhs.gov/2014-hhs-poverty-guidelines)
		scalar	FPL_base_48_2015	=	11670
		scalar	FPL_base_AL_2015	=	14580
		scalar	FPL_base_HA_2015	=	13420
		scalar	FPL_mult_48_2015	=	4060
		scalar	FPL_mult_AL_2015	=	5080
		scalar	FPL_mult_HA_2015	=	4670
		
		*	2016 HHS Poverty Guideline (https://aspe.hhs.gov/2016-hhs-poverty-guidelines)
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
			forval	year=1999(2)2015	{
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
				
			*	FPL variables
			forval	year=1999(2)2017	{
				
				*	Income to Poverty Ratio
				gen		income_to_poverty`year'	=	total_income_fam`year'/FPL_`year'
				lab	var	income_to_poverty`year'	"Income to Poverty Ratio, `year'"
				
				*	FPL category
				*gen		FPL_cat`year'=.
				*replace	FPL_cat`year'=1		if	total_income_fam`year'<FPL_`year'
				generate	income_to_poverty_cat`year'=1		if	income_to_poverty`year' <1
				replace		income_to_poverty_cat`year'=2		if	inrange(income_to_poverty`year',1,2)
				replace		income_to_poverty_cat`year'=3		if	inrange(income_to_poverty`year',2,3)
				replace		income_to_poverty_cat`year'=4		if	inrange(income_to_poverty`year',3,4)
				replace		income_to_poverty_cat`year'=5		if	inrange(income_to_poverty`year',4,5)
				replace		income_to_poverty_cat`year'=6		if	inrange(income_to_poverty`year',5,6)
				replace		income_to_poverty_cat`year'=7		if	inrange(income_to_poverty`year',6,7)
				replace		income_to_poverty_cat`year'=8		if	inrange(income_to_poverty`year',7,8)
				replace		income_to_poverty_cat`year'=9		if	inrange(income_to_poverty`year',8,9)
				replace		income_to_poverty_cat`year'=10	if	inrange(income_to_poverty`year',9,10)
				replace		income_to_poverty_cat`year'=11	if	income_to_poverty`year'>10
				replace		income_to_poverty_cat`year'=.	if	mi(FPL_`year')
				label	var	income_to_poverty_cat`year'	"Income to Poverty Category, `year'"
			}
			
			label	define	income_cat_FPL	1	"<1.0"		2	"1.0~2.0"	3	"2.0~3.0"	4	"3.0~4.0"	5	"4.0~5.0"	6	"5.0~6.0"	///
											7	"6.0~7.0"	8	"7.0~8.0"	9	"8.0~9.0"	10	"9.0~10.0"	11	"10.0"		0	"Inappropriate"
			label	values	income_to_poverty_cat*	income_cat_FPL
		
		
		*	Education	(category)
			foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
				gen		grade_comp_cat`year'	=1	if	inrange(grade_comp_head_fam`year',0,11)
				replace	grade_comp_cat`year'	=2	if	inrange(grade_comp_head_fam`year',12,12)
				replace	grade_comp_cat`year'	=3	if	inrange(grade_comp_head_fam`year',13,15)
				replace	grade_comp_cat`year'	=4	if	grade_comp_head_fam`year'>=16 & !mi(grade_comp_head_fam`year')
				replace	grade_comp_cat`year'	=.n	if	mi(grade_comp_head_fam`year')
				label	var	grade_comp_cat`year'	"Grade Household Head Completed, `year'"
			}
			
			label	define	grade_comp_cat	1	"Less than HS"	2	"HS"	3	"Some College"	4	"College Degree"
			label 	values	grade_comp_cat*	grade_comp_cat
			
		*	Child food assistance program 
		**	Let "N/A (no child)" as 0 for now.
	
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	{
			foreach	meal	in	bf	lunch	{
				*replace	child_`meal'_assist`year'	=.n	if	child_`meal'_assist`year'==0
				*replace	child_`meal'_assist`year'	=.d	if	child_`meal'_assist`year'==8
				*replace	child_`meal'_assist`year'	=.r	if	child_`meal'_assist`year'==9
				*replace	child_`meal'_assist`year'	=0	if	child_`meal'_assist`year'==5
			}
			generate	child_meal_assist`year'	=.
			
			*	Merge breakfast and lunch in to one variable, to be compatible with 2013-2017 data.
			*replace		child_meal_assist`year'	=.n	if	child_bf_assist`year'==.n	&	child_lunch_assist`year'==.n
			replace		child_meal_assist`year'	=8	if	child_bf_assist`year'==8	|	child_lunch_assist`year'==8	//	"Don't know" if either lunch or breakfast is "don't know'"
			replace		child_meal_assist`year'	=9	if	child_bf_assist`year'==9	|	child_lunch_assist`year'==9	//	"Refuse to answer" if either lunch or breakfast is "refuse to answer"
			replace		child_meal_assist`year'	=0	if	child_bf_assist`year'==0	&	child_lunch_assist`year'==0	//	"Inapp" if both breakfast and lunch are inapp.
			replace		child_meal_assist`year'	=5	if	child_bf_assist`year'==5	&	child_lunch_assist`year'==5	//	"No" if both breakfast and lunch are "No".
			replace		child_meal_assist`year'	=1	if	inlist(1,child_bf_assist`year',child_lunch_assist`year')	//	"Yes" if either breakfast or lunch is "Yes"
			label	variable	child_meal_assist`year'	"Child received free meal in `year'"
			label value	child_meal_assist`year'	YNDRI
		}
		order	child_meal_assist1999-child_meal_assist2011, before(child_meal_assist2013)
		
		foreach	year	in	2013	2015	2017	{
			replace	child_meal_assist`year'	=1	if	inrange(child_meal_assist`year',1,3)	//	Received either breakfast or lunch
		}
		label values	child_meal_assist*	YNDRI
		
		
		*	Retirement age
		forval	year=1999(2)2017	{
			cap	drop	retire_age`year'
			gen	retire_age`year'	=	age_head_fam`year'	-	(`year'-retire_year_head`year')	///
				if	emp_status_head`year'==4	&	inrange(retire_year_head`year',1910,`year')	&	inrange(age_head_fam`year',1,120)	&	`year'>=retire_year_head`year'
			lab	var	retire_age`year' "Retirement age in `year'"
		}
		
		*	Body Mass Index (BMI)
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			
			*	Convert units into metrics
				
				*	Height
				if	inrange(`year',1999,2009)	{
					gen		height_meter`year'	=		(height_feet`year'*30.48)	+	(height_inch`year'*2.54)
				}
				else	if	inrange(`year',2011,2017)	{
					replace	height_meter`year'	=		(height_feet`year'*30.48)	+	(height_inch`year'*2.54)	if	!mi(height_feet`year')	&	mi(height_meter`year')
				}
				
				*	Weight
				if	inrange(`year',1999,2009)	{
					gen		weight_kg`year'	=		(weight_lbs`year'*0.454)
				}
				else	if	inrange(`year',2011,2017)	{
					replace	weight_kg`year'	=		(weight_lbs`year'*0.454)	if	!mi(weight_lbs`year')	&	mi(weight_kg`year')
				}
				
				label	var	height_meter`year'	"Respondent's height (cm)"
				label	var	weight_kg`year'		"Respondent's weight (kg)"
				
			*	Calculate BMI
				gen	respondent_BMI`year'	=		weight_kg`year'	/	(height_meter`year'/100)^2
				label	variable	respondent_BMI`year'	"Respondent's BMI, `year'"
		}
		
		
		*	Income &  expenditure & wealth & tax per capita
			
			foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
					
					*	Income per capita
					gen	income_pc`year'	=	total_income_fam`year'/num_FU_fam`year'
					label	variable	income_pc`year'	"Family income per capita, `year'"
					
					*	Expenditures, tax, debt and wealth per capita
					
					gen	food_exp_pc`year'			=	food_exp_total`year'/num_FU_fam`year'
					gen	child_exp_pc`year'			=	child_exp_total`year'/num_FU_fam`year'
					gen	edu_exp_pc`year'			=	edu_exp_total`year'/num_FU_fam`year'
					gen	health_exp_pc`year'			=	health_exp_total`year'/num_FU_fam`year'
					gen	house_exp_pc`year'			=	house_exp_total`year'/num_FU_fam`year'
					gen	property_tax_pc`year'		=	property_tax`year'/num_FU_fam`year'
					gen	transport_exp_pc`year'		=	transport_exp`year'/num_FU_fam`year'
					*gen	other_debts_pc`year'		=	other_debts`year'/num_FU_fam`year'
					gen	wealth_pc`year'				=	wealth_total`year'/num_FU_fam`year'
					
					label	variable	food_exp_pc`year'	"Food expenditure per capita, `year'"
					label	variable	child_exp_pc`year'	"Child expenditure per capita, `year'"
					label	variable	edu_exp_pc`year'	"Education expenditure per capita, `year'"
					label	variable	health_exp_pc`year'	"Health expenditure per capita, `year'"
					label	variable	house_exp_pc`year'	"House expenditure per capita, `year'"
					label	variable	property_tax_pc`year'	"Property tax per capita, `year'"
					label	variable	transport_exp_pc`year'	"Transportation expenditure per capita, `year'"
					*label	variable	other_debts_pc`year'	"Other debts per capita, `year'"
					label	variable	wealth_pc`year'			"Wealth per capita, `year'"
					
					
					if	inrange(`year',2005,2017)	{	//	Cloth
						gen	cloth_exp_pc`year'	=	cloth_exp_total`year'/num_FU_fam`year'
						label	variable	cloth_exp_pc`year'	"Cloth expenditure per capita, `year'"
					}
					
					*	Average over the two years	(starting 2001, as we have data from 1999)
					if	inrange(`year',2001,2017)	{
						
						local	prevyear=`year'-2
						gen	avg_income_pc`year'		=	(income_pc`year'+income_pc`prevyear')/2	//	average income per capita
						gen	avg_foodexp_pc`year'	=	(food_exp_pc`year'+food_exp_pc`prevyear')/2
						gen	avg_childexp_pc`year'	=	(child_exp_pc`year'+child_exp_pc`prevyear')/2
						gen	avg_eduexp_pc`year'		=	(edu_exp_pc`year'+edu_exp_pc`prevyear')/2
						gen	avg_healthexp_pc`year'	=	(health_exp_pc`year'+health_exp_pc`prevyear')/2
						gen	avg_houseexp_pc`year'	=	(house_exp_pc`year'+house_exp_pc`prevyear')/2
						gen	avg_proptax_pc`year'	=	(property_tax_pc`year'+property_tax_pc`prevyear')/2
						gen	avg_transexp_pc`year'	=	(transport_exp_pc`year'+transport_exp_pc`prevyear')/2
						*gen	avg_othdebts_pc`year'	=	(other_debts_pc`year'+other_debts_pc`prevyear')/2
						gen	avg_wealth_pc`year'		=	(wealth_pc`year'+wealth_pc`prevyear')/2
						
						
						label	variable	avg_income_pc`year'		"Averge income per capita income, `year'-`prevyear'"
						label	variable	avg_foodexp_pc`year'	"Averge food expenditure per capita income, `year'-`prevyear'"
						
						if	inrange(`year',2007,2017)	{	//	cloths							
							gen	avg_clothexp_pc`year'	=	(cloth_exp_pc`year'+cloth_exp_pc`prevyear')/2
						}
					}
			}
		
	
		*	Winsorize family income and expenditures per capita at top 1%, and scale it to thousand-dollars via division
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			
			foreach	var	in	income_pc	food_exp_pc	child_exp_pc	edu_exp_pc	health_exp_pc	house_exp_pc	property_tax_pc	transport_exp_pc	/*other_debts*/	wealth_pc	{
				
				*	Winsorize top 1% 
				winsor `var'`year' 			if xsqnr_`year'!=0 & inrange(sample_source,1,3), gen(`var'_wins`year') p(0.01) highonly
				
				*	Keep winsorized variables only
				drop	`var'`year'
				rename	`var'_wins`year'		`var'`year'
				
				*	Scale to thousand-dollars
				replace	`var'`year'	=	`var'`year'/1000
			}	//	var	
		}	//	year
		
		
		*	Employed status (simplified)
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			gen		emp_HH_simple`year'	=.
			replace	emp_HH_simple`year'	=1	if	inrange(emp_status_head`year',1,2)	//	Employed
			replace	emp_HH_simple`year'	=5	if	inrange(emp_status_head`year',3,99)	//	Unemployed (including retired, disabled, keeping house, inapp, ...)
			*replace	emp_HH_simple`year'	=5	if	inrange(emp_status_head`year',3,3)	//	Unemployed
			*replace	emp_HH_simple`year'	=0	if	inrange(emp_status_head`year',4,99)	//	Others (retired, disabled, keeping house, inapp, DK, NA,...)
			
			gen		emp_spouse_simple`year'	=.
			replace	emp_spouse_simple`year'	=1	if	inrange(emp_status_spouse`year',1,2)	//	Employed
			replace	emp_spouse_simple`year'	=5	if	inrange(emp_status_spouse`year',3,99)	|	emp_status_spouse`year'==0	//	Unemployed (including retired, disabled, keeping house, inapp, DK, NA,...)	
			*replace	emp_spouse_simple`year'	=5	if	inrange(emp_status_spouse`year',3,3)	//	Unemployed
			*replace	emp_spouse_simple`year'	=0	if	inrange(emp_status_spouse`year',4,99)	|	emp_status_spouse`year'==0	//	Others (retired, disabled, keeping house, inapp, DK, NA,...)	
		}
		
		
		
		*	Food expenditure
		tempfile temp
		save	`temp'

		*	clean food price data
		import excel "E:\Box\US Food Security Dynamics\DataWork\USDA\Food Plans_Cost of Food Reports.xlsx", sheet("food_cost_month") firstrow clear
		replace	year=year+1
		
		*	calculate adult expenditure by average male and female
			foreach	plan	in	thrifty low moderate liberal	{
				egen	adult_`plan'	=	rowmean(male_`plan' female_`plan')
			}
			
		*	Reshape to me merged
		gen	temptag=1
		reshape	wide	child_thrifty-adult_liberal,	i(temptag)	j(year)
				
		tempfile monthly_foodprice
		save 	`monthly_foodprice'

		*	Merge food price data into the main data
		use	`temp', clear
		gen	temptag=1
		merge m:1 temptag using `monthly_foodprice', assert(1	3) nogen
		drop	temptag

		*	Calculate annual household food expenditure per each 
			
			*	Yearly food expenditure = monthly food expenditure * 12
			*	Monthly food expenditure is calculated by the (# of children * children cost) + (# of adult * adult cost)
			foreach	plan	in	thrifty low moderate liberal	{
				
				foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
				
					*	Unadjusted
					gen	double	foodexp_W_`plan'`year'	=	((num_child_fam`year'*child_`plan'`year')	+	((num_FU_fam`year'-num_child_fam`year')*adult_`plan'`year'))*12
					
					*	Adjust by the number of families
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*1.2	if	num_FU_fam`year'==1	//	1 person family
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*1.1	if	num_FU_fam`year'==2	//	2 people family
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*1.05	if	num_FU_fam`year'==3	//	3 people family
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*0.95	if	inlist(num_FU_fam`year',5,6)	//	5-6 people family
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*0.90	if	num_FU_fam`year'>=7	//	7+ people family
					
					*	Divide by the number of families to get the threshold value(W) per capita
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'/num_FU_fam`year'
					
					*	Scale it to thousand-dollars
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'/1000
					
					*	Get the average value per capita (SL: This variable would no longer needed as of June 14, 2020)
					sort	fam_ID_1999
					if	!inlist(`year',1999)	{
						local	prevyear=`year'-2
						gen	avg_foodexp_W_`plan'`year'	=	(foodexp_W_`plan'`year'+foodexp_W_`plan'`prevyear')/2
					}
					
				}
			}
		
		*	Drop variables no longer needed
		drop child_thrifty2013-adult_liberal2017
		
		*	Food security category (simplified)
		*	This simplified category is based on Tiehen(2019)
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			clonevar	fs_cat_fam_simp`year'	=	fs_cat_fam`year'
			*recode		fs_cat_fam_simp	(3,4=1) (1,2=1)
			*label	define	fs_cat_simp	1	"High Secure"	2	"Marginal Secure"	3	"Insecure"
			recode		fs_cat_fam_simp`year'	(2 3 4=0) (1=1)

		}
		label	define	fs_cat_simp	0	"Food Insecure (any)"	1	"Food Secure"
		label values	fs_cat_fam_simp*	fs_cat_simp
		
		*	Food security score (Rescaled)
		*	Rescaled to be comparable to C&B resilience scores
		foreach	year	in	1999	2001	2003	2015	2017	{

			gen	double	fs_scale_fam_rescale`year'	=	(9.3-fs_scale_fam`year')/9.3
			lab	var	fs_scale_fam_rescale`year'	"Food Securiy Score (Scale), rescaled"
			
		}
		
		
		/*
		*	School Completion (Disabled - no longer recodees nonresponses as missing)
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			
			*	High School (head)
			recode	hs_completed_head`year'	(1 2=1)	(3=0)	(8=.d)	(9=.r)	//	Treat "inappropriate (no education ,outside the U.S.) as "no high school"
			label	variable	hs_completed_head`year'	"HH has high school diploma or GED, `year'"
			
			*	High School (spouse)
			recode	hs_completed_spouse`year'	(1 2=1)	(3=0)	(8=.d)	(9=.r)	//	Treat "inappropriate (no education ,outside the U.S.) as "no high school"
			label	variable	hs_completed_spouse`year'	"Spouse has high school diploma or GED, `year'"

			*	College (HH)
			recode	college_completed`year'	(5=0)	(8=.d)	(9=.r)	//	Treat "inappropriate (no education ,outside the U.S.) as "no college"
			label	variable	college_completed`year'	"HH Has college degree, `year'"
			
			*	College (Spouse)
			recode	college_comp_spouse`year'	(5=0)	(8=.d)	(9=.r)	//	Treat "inappropriate (no education ,outside the U.S.) as "no college"
		}
		*/
			
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
			