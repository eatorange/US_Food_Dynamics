
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_const_1999_2017_ind
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	2020/9/23, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	x11101ll // Personal Identification Number

	DESCRIPTION: 	Construct PSID individual panel data from 1999 to 2017
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Data construction
						1.1	-	Construct descriptive variables
					2 - Additional cleaning for long data format
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
	
		
	*	Relation to "current" reference person (head)
	local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
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
		
		
		*	Race (category)
		forval	year=1999(2)2017	{
			gen		race_head_cat`year'=.
			replace	race_head_cat`year'=1	if	inlist(race_head_fam`year',1,5)
			replace	race_head_cat`year'=2	if	race_head_fam`year'==2
			replace	race_head_cat`year'=3	if	inlist(race_head_fam`year',3,4,6,7)
			replace	race_head_cat`year'=.n	if	inrange(race_head_fam`year',8,9)
			
			*	Dummy for each variable
			
			label variable	race_head_cat`year'	"Race (Head), `year'"
		}
		label	define	race_cat	1	"White"	2	"Black"	3	"Others"
		label	values	race_head_cat*	race_cat
		
		*	Marital Status (Binary)
		forval	year=1999(2)2017	{
			gen		marital_status_cat`year'=.
			replace	marital_status_cat`year'=1	if	marital_status_fam`year'==1
			replace	marital_status_cat`year'=0	if	inrange(marital_status_fam`year',2,5)
			replace	marital_status_cat`year'=.n	if	inrange(marital_status_fam`year',8,9)
			
			label variable	marital_status_cat`year'	"Head Married, `year'"
		}
		label	define	marital_status_cat	1	"Married"	0	"Not Married"
		label	values	marital_status_cat*	marital_status_cat
		
		*	Children in Household (Binary)
		forval	year=1999(2)2017	{
			gen		child_in_FU_cat`year'=.
			replace	child_in_FU_cat`year'=1		if	num_child_fam`year'>=1	&	!mi(num_child_fam`year')
			replace	child_in_FU_cat`year'=2		if	num_child_fam`year'==0
			*replace	child_in_FU_cat`year'=.n	if	!inrange(xsqnr_`year',1,89)
			
			label variable	child_in_FU_cat`year'	"Children in Household, `year'"
		}
		label	define	child_in_FU_cat	1	"Children in Household"	2	"No Children in Household"
		label	values	child_in_FU_cat*	child_in_FU_cat
		
		*	Age of Head (Category)
		forval	year=1999(2)2017	{
			gen		age_head_cat`year'=1	if	inrange(age_head_fam`year',16,24)
			replace	age_head_cat`year'=2	if	inrange(age_head_fam`year',25,34)
			replace	age_head_cat`year'=3	if	inrange(age_head_fam`year',35,44)
			replace	age_head_cat`year'=4	if	inrange(age_head_fam`year',45,54)
			replace	age_head_cat`year'=5	if	inrange(age_head_fam`year',55,64)
			replace	age_head_cat`year'=6	if	age_head_fam`year'>=65	&	!mi(age_head_fam`year'>=65)
			replace	age_head_cat`year'=.	if	mi(age_head_fam`year')
			
			label	var	age_head_cat`year'	"Age of Household Head (category), `year'"
			
			gen		retire_age`year'	=0	if	inrange(age_head_fam`year',1,64)
			replace	retire_age`year'	=1	if	!mi(age_head_fam`year')	&	!inrange(age_head_fam`year',1,64)
			label	var	retire_age`year'	"65 or older in `year'"
		}
		label	define	age_head_cat	1	"16-24"	2	"25-34"	3	"35-44"	///
										4	"45-54"	5	"55-64"	6	"65 and older"
		label	values	age_head_cat*	age_head_cat
		
		label	define	retire_age	0 "No"	1	"Yes"
		label	values	retire_age*	retire_age
		
		*	Education	(category)
			foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
				gen		grade_comp_cat`year'	=1	if	inrange(grade_comp_head_fam`year',0,11)
				replace	grade_comp_cat`year'	=2	if	inrange(grade_comp_head_fam`year',12,12)
				replace	grade_comp_cat`year'	=3	if	inrange(grade_comp_head_fam`year',13,15)
				replace	grade_comp_cat`year'	=4	if	grade_comp_head_fam`year'>=16 & !mi(grade_comp_head_fam`year')
				replace	grade_comp_cat`year'	=.n	if	mi(grade_comp_head_fam`year')
				label	var	grade_comp_cat`year'	"Grade Household Head Completed, `year'"
				
				gen		grade_comp_cat_spouse`year'	=1	if	inrange(grade_comp_spouse`year',0,11)
				replace	grade_comp_cat_spouse`year'	=2	if	inrange(grade_comp_spouse`year',12,12)
				replace	grade_comp_cat_spouse`year'	=3	if	inrange(grade_comp_spouse`year',13,15)
				replace	grade_comp_cat_spouse`year'	=4	if	grade_comp_spouse`year'>=16 & !mi(grade_comp_spouse`year')
				replace	grade_comp_cat_spouse`year'	=.n	if	mi(grade_comp_spouse`year')
				label	var	grade_comp_cat_spouse`year'	"Grade Household Spouse Completed, `year'"
			}
			
			label	define	grade_comp_cat	1	"Less than HS"	2	"HS"	3	"Some College"	4	"College Degree"
			label 	values	grade_comp_cat*	grade_comp_cat
			
			order	grade_comp_cat_spouse*, after(grade_comp_cat2017)
			
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
		
		*	% of children in the households
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			gen		ratio_child`year'	=	num_child_fam`year'/num_FU_fam`year'
			label	var	ratio_child`year'	"\% of children population in `year'"
		}
		
		
		
		*	Food expenditure
		tempfile temp
		save	`temp'
		
			*	Import monthly food plan cost data, which has cost per gender-age
			import excel "E:\Box\US Food Security Dynamics\DataWork\USDA\Food Plans_Cost of Food Reports.xlsx", sheet("thrifty") firstrow clear

			*	Make sure each gender-age uniquly identifies observation
			isid	gender	age

			rename	gender	indiv_gender

			tempfile	foodprice_raw
			save	`foodprice_raw'
		
			*	Save data for each year
			forvalues	year=1999(2)2017	{
				
				use	`foodprice_raw', clear
				
				rename	age	age_ind`year'
				keep	indiv_gender	age_ind`year'	foodcost_monthly_`year'
				
				tempfile	foodcost_`year'
				save	`foodcost_`year''
				
			}
			
			*	There are household members whose ages are missing in PSID. In that case, we apply average cost of male/female, from 19(20) to 50.
			*	I manually checked the observations, and very few numbers of household members in HH have missing ages (between 0.01~0.2%) in each year, and most of them are adults.

			scalar	foodcost_monthly_avgadult_1999	=	115.25
			scalar	foodcost_monthly_avgadult_2001	=	122.45
			scalar	foodcost_monthly_avgadult_2003	=	127.8
			scalar	foodcost_monthly_avgadult_2005	=	137.4
			scalar	foodcost_monthly_avgadult_2007	=	147.45
			scalar	foodcost_monthly_avgadult_2009	=	159
			scalar	foodcost_monthly_avgadult_2011	=	166.35
			scalar	foodcost_monthly_avgadult_2013	=	172.2
			scalar	foodcost_monthly_avgadult_2015	=	176
			scalar	foodcost_monthly_avgadult_2017	=	174.3

			*	Merge PSID data with cost dataset
			
			use	`temp', clear 
			*use	"${PSID_dtInt}/PSID_clean_1999_2017_ind.dta", clear
			
			forvalues	year=1999(2)2017	{
				
				merge m:1 indiv_gender age_ind`year' using `foodcost_`year'', keepusing(foodcost_monthly_`year')	nogen keep(1 3)
				replace	foodcost_monthly_`year' = foodcost_monthly_avgadult_`year'	if	mi(age_ind`year')
				
				foreach	plan	in	thrifty	/*low	moderate	liberal*/	{
				
					*	Sum all individual costs to calculate total monthly clost 
					bys x11102_`year': egen foodexp_W_`plan'`year' = total(foodcost_monthly_`year') if !mi(x11102_`year')	&	inrange(xsqnr_`year',1,20) //	Total household monthly cost
					
					*	Adjust by the number of families
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*1.2	if	num_FU_fam`year'==1	//	1 person family
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*1.1	if	num_FU_fam`year'==2	//	2 people family
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*1.05	if	num_FU_fam`year'==3	//	3 people family
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*0.95	if	inlist(num_FU_fam`year',5,6)	//	5-6 people family
					replace	foodexp_W_`plan'`year'	=	foodexp_W_`plan'`year'*0.90	if	num_FU_fam`year'>=7	//	7+ people family
						
					
					*	Calulate total annual cost per capita, in thousand sollars			
					replace foodexp_W_`plan'`year'	=	((foodexp_W_`plan'`year'*12) / num_FU_fam`year' ) /	1000	//	Total household annual cost per capita in thousands
					
					*	Make the food plan cost non-missing for household member NOT in the household (i.e. sequence number is outside 1 to 20)
					*	This step makes all members in a household have the same non-missing value, so they can be treated as duplicates and be dropped when constructing household-level data
					bys	x11102_`year': egen foodexp_W_`plan'`year'_temp = mean(foodexp_W_`plan'`year')
					drop	foodexp_W_`plan'`year'
					rename	foodexp_W_`plan'`year'_temp	foodexp_W_`plan'`year'
					
					label	var	foodexp_W_`plan'`year'	"`plan' Food Plan (annual per capita) in `year'"
				
				}
	
				
			}
			
			*	Drop variables no longer needed
			drop	foodcost_monthly_????
		

		*	The code below using "simplified" food price data is no longer used as of Sep 26, 2017
		{
		/*
		use	"${PSID_dtInt}/PSID_clean_1999_2017_ind.dta", clear
		tempfile temp2
		save `temp2'
		
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
		use	`temp2', clear
		gen	temptag=1
		merge m:1 temptag using `monthly_foodprice', assert(1	3) nogen
		drop	temptag

		*	Calculate annual household food expenditure per each 
			
			*	Yearly food expenditure = monthly food expenditure * 12
			*	Monthly food expenditure is calculated by the (# of children * children cost) + (# of adult * adult cost)
			foreach	plan	in	thrifty /*low moderate liberal*/	{
				
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
					
					/*
					*	Get the average value per capita (SL: This variable would no longer needed as of June 14, 2020)
					sort	fam_ID_1999
					if	!inlist(`year',1999)	{
						local	prevyear=`year'-2
						gen	avg_foodexp_W_`plan'`year'	=	(foodexp_W_`plan'`year'+foodexp_W_`plan'`prevyear')/2
					}
					*/
					
				}
			}
	
		
		*	Drop variables no longer needed
		drop child_thrifty2013-adult_liberal2017
		*/
		}
		
		
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
		
				
		*	Recode gender
		forval	year=1999(2)2017	{
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
			label	var	fs_cat_MS`year'		"Any Insecure (cum) - `year'"
		}
		
		
		/*
		*	Recode child-related variables from missing to zero, to be included in the regression model
		forval	year=1999(2)2017	{
				replace	WIC_received_last`year'=0	if	child_meal_assist`year'==2
				replace	child_meal_assist`year'=0	if	child_meal_assist`year'==2
		}
		*/
		tempfile	dta_constructed
		save		`dta_constructed'
		
		
		
		*	Import variables for sampling error estimation
		use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
		*	Generate a single ID variable
		generate	x11101ll=(ER30001*1000)+ER30002
		
		tempfile	Ind
		save		`Ind'
	
		*	Import variables
		use	`dta_constructed', clear
		merge	m:1	x11101ll	using	`Ind', assert(2 3) keep(3) keepusing(ER31996 ER31997) nogen
		
	*	Keep relevant variables and observations
				
		*	Drop outliers with strange pattern
		drop	if	x11102_1999==10015	//	This Family has outliers (food expenditure in 2009) as well as strange flutation in health expenditure (2007), thus needs to be dropped (* It attrits in 2011 anway)
		
		
		*	Keep	relevant sample
		*	We need to decide what families to track (so we have only 1 obs per family in baseyear)
		keep	if	fam_comp_samehead_99_17==1	//	Families with same household during 1999-2017
		*keep	if	fam_comp_nochange_99_03==1	//	Families with no member change during 1999-2003
		*keep	if	fam_comp_samehead_99_03==1	//	Families with same household during 1999-2003
		*keep	if	fam_comp_samehead_99_03==1	//	Families with same household during 1999-2003

		
		*	Drop individual level variables
		drop	x11101ll weight_long_ind* weight_cross_ind* respondent???? relat_to_head* age_ind* edu_years????	relat_to_current_head*	indiv_gender
		*	Keep	relevant years
		keep	*1999	*2001	*2003	*2005	*2007	*2009	*2011	*2013	*2015	*2017	/*fam_comp**/	sample_source	ER31996 ER31997		
		
		duplicates drop	
		
		
		*	Save it as wide format
		tempfile	fs_const_wide
		save		`fs_const_wide'
		
		
	/****************************************************************
		SECTION X: Construct a long format data
	****************************************************************/
		
	
	*	Re-shape dataset

		*	Retrieve the list of time-series variables
		qui	ds	*	//	All variables
		local	allvar	`r(varlist)'

		ds	sample_source	fam_ID_1999	ER31996 ER31997
		local	uniqvars	`r(varlist)'	//	Variables that are not time-series (not to be reshaped)
		
		local	allrelevars:	list	allvar	-	uniqvars	//	Keep time-series variables only
		
		foreach var of	local	allrelevars	{
			
			loc	pos=strlen("`var'")
			loc	newvar=substr("`var'",1,`pos'-4)	//	Trim the last 4 characters (years in this case)
				
			local	newvarlist	`newvarlist'	`newvar'
		}
		local	allrelevars_uniq:	list	uniq	newvarlist	//	Drop duplicates

		
		reshape	long	`allrelevars_uniq',	i(fam_ID_1999)	j(year)
		
						
		*	Label variables after reshape
		label	var	year				"Year"
		label	var	x11102_				"Interview No."	
		label	var	weight_long_fam		"Longitudinal Family Weight"
		label	var	age_head_fam		"Age"
		label	var	race_head_fam		"Race"
		label	var	total_income_fam	"Total Household Income"
		label	var	marital_status_fam	"Marital status"
		label	var	num_FU_fam			"Number of family members"
		label	var	num_child_fam		"Number of children"
		label	var	gender_head_fam		"Gender"
		label	var	grade_comp_head_fam	"Grades completed="
		label	var	state_resid_fam		"State of Residence"
		label 	var	fs_raw_fam 			"USDA food security raw score"
		label 	var	fs_scale_fam 		"USDA food security scale score"
		label	var	fs_scale_fam_rescale	"USDA food security scale score-rescaled"
		label	var	fs_cat_fam 			"USDA food security category"
		label	var	food_stamp_used_2yr	"Received food Stamp (2 years ago)"
		label	var	food_stamp_used_1yr "Received food stamp"
		label	var	child_meal_assist	"Received child free meal at school"
		label	var	WIC_received_last	"Received foods through WIC"
		label	var	family_comp_change	"Change in family composition"
		label	var	grade_comp_cat		"Highest Grade Completed"
		label	var	race_head_cat		"Racial category"
		label	var	marital_status_cat	"Married"
		label	var	child_in_FU_cat		"Household has a child"
		label	var	age_head_cat 		"Age category"
		label	var	total_income_fam	"Total household income"
		label	var	hs_completed_head	"HH completed high school/GED"
		label	var	college_completed	"HH has college degree"
		label	var	respondent_BMI		"Respondent's Body Mass Index"
		label	var	income_pc			"Family income per capita (thousands)"
		label	var	food_exp_pc			"Food expenditure per capita (thousands)"
		label	var	avg_income_pc		"Average income over two years per capita"
		label	var	avg_foodexp_pc		"Average food expenditure over two years per capita"
		label	var	splitoff_indicator	"Splitoff indicator"
		label	var	num_split_fam		"# of splits"
		label	var	main_fam_ID		"Family ID"
		label	var	food_exp_total		"Total food expenditure"
		label	var	height_feet		"Respondent height (feet)"
		label	var	height_inch		"Respondent height (inch)"
		label	var	height_meter		"Respondent height (meters)"
		label	var	weight_lbs		"Respondent weight (lbs)"
		label	var	weight_kg		"Respondent weight (Kg)"
		label	var	meal_together		"Meal together/wk"
		label	var	child_daycare_any		"Child in daycare"
		label	var	child_daycare_FSP		"Child daycare in FSP"
		label	var	child_daycare_snack		"Child daycare offers snack"
		label	var	age_spouse		"Age (spouse)"
		label	var	ethnicity_head		"Ethnicity (head)"
		label	var	ethnicity_spouse	"Ethnicity (spouse)"
		label	var	race_spouse		"Race(spouse)"
		label	var	other_degree_head		"Other degree (head)"
		label	var	other_degree_spouse		"Other degree (spouse)"
		label	var	attend_college_head		"Attend college (head)"
		label	var	attend_college_spouse		"Attend college (spouse)"
		label	var	college_comp_spouse		"College degree (spouse)"
		label	var	edu_in_US_head		"Education in the U.S. (head)"
		label	var	edu_in_US_spouse		"Education in the U.S. (spouse)"
		label	var	college_yrs_head		"Yrs in collge (head)"
		label	var	college_yrs_spouse		"Yrs in collge (spouse)"
		label	var	grade_comp_spouse		"Grades completed (spouse)"
		label	var	hs_completed_spouse		"HS degree (spouse)"
		label	var	child_exp_total		"Annual child expenditure"
		*label	var	cloth_exp_total		"Annual cloth expenditure"
		label	var	sup_outside_FU		"Support from outside family"
		label	var	edu_exp_total		"Annual education expenditure"
		label	var	health_exp_total	"Annual health expenditure"
		label	var	house_exp_total		"Annual housing expenditure"
		label	var	tax_item_deduct		"Itemized tax deduction"

		label	var	property_tax		"Property tax ($)"
		label	var	transport_exp		"Annual transport expenditure"

		label	var	couple_status		"Coupling status"
		label	var	head_status		"New head"
		label	var	spouse_new		"New spouse"
		label	var	alcohol_head	"Drink alcohol (head)"
		label	var	num_drink_head		"# of drink (head)"
		label	var	num_drink_spouse	"# of drink (spouse)"
		label	var	smoke_head		"Smoking (head)"
		label	var	smoke_spouse	"Smoking (spouse)"
		label	var	num_smoke_head		"# of smoking (head)"
		label	var	num_smoke_spouse	"# of smoking (spouse)"
		label	var	phys_disab_head		"Disabled"
		label	var	phys_disab_spouse	"Disabled (spouse)"
		label	var	housing_status		"Housing status"
		label	var	elderly_meal	"Received free/reduced cost elderly meal"
		label	var	retire_plan_head		"Retirement plan (head)"
		label	var	retire_plan_spouse	"Retirement plan (spouse)"
		label	var	annuities_IRA		"Annuities_IRA"
		label	var	veteran_head	"Veteran (head)"
		label	var	veteran_spouse	"Veteran (spouse)"
		label	var	wealth_total	"Total wealth"
		label	var	emp_status_head	"Employement status (head)"
		label	var	emp_status_spouse	"Employement status(spouse)"
		label	var	alcohol_spouse	"Drink alcohol (spouse)"
		*label	var	relat_to_current_head	"Veteran (head)"
		label	var	child_exp_pc		"Annual child expenditure (pc) (thousands)"
		label	var	edu_exp_pc		"Annual education expenditure (pc) (thousands)"
		label	var	health_exp_pc		"Annual health expenditure (pc) (thousands)"
		label	var	house_exp_pc		"Annual house expenditure (pc) (thousands)"
		label	var	property_tax_pc		"Property tax (pc) (thousands)"
		label	var	transport_exp_pc	"Annual transportation expenditure (pc) (thousands)"
		label	var	wealth_pc		"Wealth (pc) (thousands)"
		*label	var	cloth_exp_pc		"Annual cloth expenditure (pc)"
		label	var	avg_childexp_pc		"Avg child expenditure (pc)"
		label	var	avg_eduexp_pc		"Avg education expenditure (pc)"
		label	var	avg_healthexp_pc		"Avg health expenditure (pc)"
		label	var	avg_houseexp_pc		"Avg house expenditure (pc)"
		label	var	avg_proptax_pc		"Avg property expenditure (pc)"
		label	var	avg_transexp_pc		"Avg transportation expenditure (pc)"
		label	var	avg_wealth_pc		"Avg wealth (pc)"
		label	var	emp_HH_simple		"Employed"
		label	var	emp_spouse_simple		"Employed (spouse)"
		label	var	fs_cat_MS		"Marginal food secure"
		label	var	fs_cat_IS		"Food insecure"
		label	var	fs_cat_VLS		"Very Low food secure"
		label	var	child_bf_assist		"Free/reduced breakfast from school"
		label	var	child_lunch_assist		"Free/reduced lunch from school"
		label	var	splitoff_dummy		"Splitoff ummy"
		label	var	accum_splitoff		"Accumulated splitoff"
		label	var	other_debts			"Other debts"
		label	var	fs_cat_fam_simp		"Food Security Category (binary)"
		label	var	retire_age		"65 or older"
		label	var	retire_year_head	"Year of retirement"
		label	var	retire_year_head	"Age when retired"
		label	var	ratio_child			"\% of children population"
		label	var	grade_comp_cat_spouse	"Highest Grade Completed (Spouse)"
		label	var	foodexp_W_thrifty	"Thrifty Food Plan (TFP) cost (annual per capita)"

		*label	var	cloth_exp_total		"Total cloth expenditure"
		
		label	var	FPL_		"Federal Poverty Line"
		label	var	income_to_poverty		"Income to Poverty Ratio"
		label	var	income_to_poverty_cat		"Income to Poverty Ratio (category)"
			      
		drop	height_feet		height_inch	  weight_lbs	child_bf_assist	child_lunch_assist	food_exp_total	child_exp_total	edu_exp_total	health_exp_total	///
				house_exp_total	property_tax	transport_exp	wealth_total	/*cloth_exp_total*/
		
		
	*	Recode N/A & nonrespones reponses of "some" variables
	***	Recoding nonresponses & N/As should be done carefully, as there could be statistical difference between responses and non-responses. Judgements must be done by variable-level
	***	Among the variables with nonresponeses (ex. DK, Refusal), some of them have very small fraction of nonrespones (ex.less than 0.1%) This implies that they can be relatively recoded as missing safely.

		*	Recode variables which have a very small fraction of non-responses & N/As
		qui	ds	food_stamp_used_2yr	food_stamp_used_1yr	child_meal_assist	WIC_received_last	college_completed	child_daycare_any	college_comp_spouse	sup_outside_FU	///
				alcohol_head	smoke_spouse	phys_disab_head  phys_disab_spouse	elderly_meal	retire_plan_head retire_plan_spouse	annuities_IRA	alcohol_spouse	///
				
	    recode	`r(varlist)'	(8=.d)	(9=.r)
		
		replace	alcohol_head=.n	if	alcohol_head==0	// only 1 obs
		replace	smoke_head=.n	if	smoke_head==0	// only 1 obs
                                               
	*	Recode time variables, to start from 1 and increase by 1 in every wave
	replace	year	=	(year-1997)/2
	
	*	Generate in-sample and out-of-sample for performance check
	*	We use the data up to 2015 as "in-sample", and the data in 2018 as "out-of-sample"
	gen		in_sample	=	0
	replace	in_sample	=	1	if	inrange(year,1,9)
	label	var	in_sample	"In-sample (1999~2015)"
	
	gen		out_of_sample	=	0
	replace	out_of_sample	=	1	if	year==10
	label	var	out_of_sample	"Out of sample (2017)"
	
	*	Define the data as survey data and time-series data
	svyset	ER31997 [pweight=weight_long_fam], strata(ER31996)	singleunit(scaled)
	xtset fam_ID_1999 year,	delta(1)
	
	cap	drop	year2
	gen year2 = (year*2)+1997	//	actual year
	
	*	Recode nonresponses (dk, refuse, inappropriate) as "negative"
	label	define	yes1no0	0	"No"	1	"Yes"
	local	recode_vars	1
	if	`recode_vars'==1	{
		qui	ds	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse	veteran_head	veteran_spouse	tax_item_deduct	///
				retire_plan_head	retire_plan_spouse	annuities_IRA	attend_college_head	attend_college_spouse	hs_completed_head	hs_completed_spouse	///
				college_completed	college_comp_spouse	other_degree_head	other_degree_spouse	food_stamp_used_1yr	child_meal_assist	WIC_received_last	elderly_meal	///
				child_daycare_any	child_daycare_FSP	child_daycare_snack	emp_HH_simple emp_spouse_simple
		label values	`r(varlist)'	yes1no0
		recode	`r(varlist)'	(0	5	8	9	.d	.r=0)
	}
	
	*	Create a lagged variable of the outcome variable and its higher polynomial terms (needed for Shapley decomposition)	
	forval	i=1/5	{
		
		gen	lag_food_exp_pc_`i'	=	(cl.food_exp_pc)^`i'
		label	var	lag_food_exp_pc_`i'	"Lagged food exp (pc) - `i'th polynimial	order"
		
		*gen	lag_avg_foodexp_pc_`i'	=	(cl.avg_foodexp_pc)^`i'
		*label	var	lag_avg_foodexp_pc_`i'	"Lagged avg. food exp (pc) `i'th polynimial	order"
		
	}
	label	var	lag_food_exp_pc_1	"Lagged food expenditure per capita"
	order	lag_food_exp_pc_1-lag_food_exp_pc_5,	after(food_exp_pc)
	*order	lag_avg_foodexp_pc_1-lag_avg_foodexp_pc_5,	after(avg_foodexp_pc)
	 
	*	Create variables of status change (employment, marital status, ....) which could affect food expenditure
		
		*	No longer employed (employed in the previous period, but not employed in the current period)
		local	var	no_longer_employed
		gen		`var'=0
		replace	`var'=1	if	emp_HH_simple==0	&	l.emp_HH_simple==1
		label	var	`var'	"No longer employed"
		
		*	No longer married (married in the previous period, but no longer married (widowed, divorced, separated) in the current period)
		local	var	no_longer_married
		gen		`var'=0
		replace	`var'=1	if	inrange(marital_status_fam,3,5)	&	l.marital_status_fam==1	//	
		label	var	`var'	"No longer married"
		
		*	No longer owns house (Owned a house in the previous period, but no longer own (rent or else) in the current period)
		local	var	no_longer_own_house
		gen		`var'=0
		replace	`var'=1	if	inlist(housing_status,5,8)	&	l.housing_status==1	//	
		label	var	`var'	"No longer owns house"
		
		*	Household head became physically disabled
		local	var	became_disabled
		gen		`var'=0
		replace	`var'=1	if	phys_disab_head==1	&	l.phys_disab_head==0	//	
		label	var	`var'	"Became disabled"	
		
	
	*	Create additional variables, as "rforest" does accept none of the interaction, factor variable and time series variable

		*	Non-linear terms of income & wealth	&	age
		gen	income_pc_sq	=	(income_pc)^2
		label	var	income_pc_sq	"(Income per capita)$^2$ (thousands)"
		gen	wealth_pc_sq	=	(wealth_pc)^2
		label	var	wealth_pc_sq	"(Wealth per capita)$^2$ (thousands)"
		gen	age_head_fam_sq		=	(age_head_fam)^2
		label	var	age_head_fam_sq	"Age$^2$"
		gen	age_spouse_sq		=	(age_spouse)^2
		label	var	age_head_fam_sq	"Age$^2$ (spouse)"
		gen	income_pc_orig	=	income_pc*1000	//	Non-scaled, unit is dollars
		gen	invhyp_age	=	asinh(age_head_fam)	//	Inverse hyperbolic transformation of age
		gen	asinh_income	=	asinh(income_pc*1000)	//	Inverse hyperbolic transformation of income
		gen	ln_income_pc	=	ln(income_pc*1000)	//	Log of income
		lab	var	ln_income_pc	"ln(income per capita)"
		gen	ln_wealth_pc	=	ln(wealth_pc*1000)	//	Log of income
		lab	var	ln_wealth_pc	"ln(wealth per capita)"
		gen	income_cubic	=	(income_pc)^3	//	Cubic of income
		label	var	income_pc_sq	"(Income per capita)$^3$"
		
		*	Decompose unordered categorical variables
		local	catvars	race_head_cat	marital_status_fam	gender_head_fam	state_resid_fam	housing_status	family_comp_change	couple_status	grade_comp_cat	grade_comp_cat_spouse	year	sample_source
		foreach	var	of	local	catvars	{
			tab	`var',	gen(`var'_enum)
		}
		rename	gender_head_fam_enum1	HH_female
		label	variable	HH_female	"Female"
		
		rename	(race_head_cat_enum1 race_head_cat_enum2 race_head_cat_enum3)	(HH_race_white	HH_race_black	HH_race_other)
		label	variable	HH_race_white	"Race: White"
		label	variable	HH_race_black	"Race: Black"
		label	variable	HH_race_other	"Race: Other"
		
		rename	(grade_comp_cat_enum1	grade_comp_cat_enum2	grade_comp_cat_enum3	grade_comp_cat_enum4)	///
				(highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col)
				
		label	variable	highdegree_NoHS		"Highest degree: less than high school"
		label	variable	highdegree_HS		"Highest degree: high school"
		label	variable	highdegree_somecol	"Highest degree: some college"
		label	variable	highdegree_col		"Highest degree: college"
		
		rename	(grade_comp_cat_spouse_enum1	grade_comp_cat_spouse_enum2	grade_comp_cat_spouse_enum3	grade_comp_cat_spouse_enum4)	///
				(highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse)
				
		label	variable	highdegree_NoHS_spouse		"Highest degree: less than high school (spouse)"
		label	variable	highdegree_HS_spouse		"Highest degree: high school (spouse)"
		label	variable	highdegree_somecol_spouse	"Highest degree: some college (spouse)"
		label	variable	highdegree_col_spouse		"Highest degree: college (spouse)"
		
		rename	(sample_source_enum1	sample_source_enum2	sample_source_enum3)	///
				(sample_source_SRC	sample_source_SEO	sample_source_IMM)
				
		label	variable	sample_source_SRC	"Sample: SRC"
		label	variable	sample_source_SEO	"Sample: SEO"
		label	variable	sample_source_IMM	"Sample: Immigrants"
		
		*	Interaction variables
			
			*	Male education
			foreach	var	in	hs_completed_head	college_completed	other_degree_head	{
				gen	`var'_interact	=	`var'*grade_comp_head_fam
			}
		
			*	Female education
			foreach	var	in	hs_completed_spouse	college_comp_spouse	other_degree_spouse	{
				gen	`var'_interact	=	`var'*grade_comp_spouse
			}	
	
	sort	fam_ID_1999 year,	stable
	
	*	Codebook (To share with John, Chris and Liz)
	local	codebook	0
	if	`codebook'==1	{
		codebook	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse			///
					age_head_fam	age_spouse	race_head_cat	marital_status_fam		gender_head_fam		state_resid_fam	housing_status	veteran_head	veteran_spouse	///
					/*foodexp_pc*/	income_pc	wealth_pc	sup_outside_FU	tax_item_deduct	retire_plan_head	retire_plan_spouse	annuities_IRA	///
					emp_HH_simple	emp_spouse_simple	///
					num_FU_fam	num_child_fam	family_comp_change	couple_status	head_status	spouse_new	///
					grade_comp_head_fam	grade_comp_spouse	attend_college_head	attend_college_spouse	college_yrs_head	college_yrs_spouse	///
					hs_completed_head	hs_completed_spouse	college_completed	college_comp_spouse	other_degree_head	other_degree_spouse					///
					food_stamp_used_1yr	child_meal_assist	WIC_received_last	meal_together	elderly_meal	child_daycare_any	child_daycare_FSP	child_daycare_snack	///
					if	in_sample==1, compact
		
	}
	
	*	Keep only observations where the outcome variable is non-missing
	*	This is necessary for "rforest" command, but it should be safe anyway since we will use only in_sample and out_of_sample.
	keep	if	inlist(1,in_sample,out_of_sample)	
	sort	fam_ID_1999	year
	
	*	Construct new survey weight variables to apply complex survey design into the panel data analyses
	*	This weight construction is based on the following reference
			*	Heeringa, Steven G., Brady T. West, and Patricia A. Berglund. 2010. “Advanced Topics in the Analysis of Survey Data.” In Applied Survey Data Analysis, Boca Raton, FL: Chapman & Hall/CRC. (example 12.3.4)
	
		*	Base weight
		local	var	weight_long_fam_base
		gen	`var'	=	weight_long_fam	if	year==1	//	Base weight is the weight of the first year
		bys	fam_ID_1999:	egen temp	=	max(`var')
		replace	`var'	=	temp
		drop	temp
		lab	var	`var'	"Base weight of the household (longitudinal family weight in 1999)"
		
		*	Level 1 weight (weight for repeated measurement)
		local	var	weight_l1
		gen	`var'	=	weight_long_fam	/	weight_long_fam_base	//	Level 1 weight = wave_speific weight / base weight
		lab	var	`var'	"Level 1 weight"
		
		*	Re-scale level 1 weight (using "Method 1" of Rabe-Hesketh and Skrondal (2006))
		gen		weight_l1_sq	=	(weight_l1)^2
		egen	sum_weight_l1_sq	=	sum(weight_l1_sq), by(fam_ID_1999)
		egen	sum_weight_l1	=	sum(weight_l1), by(fam_ID_1999)
		gen		weight_l1_r	=	weight_l1	*	(sum_weight_l1)	/	(sum_weight_l1_sq)
		
		*	Create a unique PSU identifier to be used as a new PSU
		gen		newsecu	=	(ER31996*100)	+	ER31997	
		
		*	Create two new variables "weight_multi1" and "weight_multi2" from the two newly constructed weight variables above.
		*	This step is required if we want to use "gllamm" command, Generalized Linear Latent and Mixed Model
		gen	weight_multi1	=	weight_long_fam_base
		gen	weight_multi2	=	weight_l1_r
		
		*	For an alternative approach, multiply two weights to be used as a new survey weight
		gen	weight_multi12	=	weight_multi1*weight_multi2
		
		*	To use an alternative approach, change the new surveydata setting as following
		svyset	newsecu	[pweight=weight_multi12] /*,	singleunit(scaled)*/
		
	
	*	Save it as long format
		tempfile	fs_const_long
		save		`fs_const_long'
	
		
		
		
			
	/****************************************************************
		SECTION X: Save and Exit
	****************************************************************/
	
	
	* Make dta
		
		*	Wide data
		use	`fs_const_wide',clear
		notes	drop _dta
		notes:	fs_const_wide / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID household-level constructed data (wide format) 1999 to 2017,
		*notes:	Only individuals appear in all waves are included.
		

		* Git branch info
		stgit9 
		notes : fs_const_wide / Git branch `r(branch)'; commit `r(sha)'.
	
	
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
		save	"${PSID_dtFin}/fs_const_wide.dta", replace
		
		*	Long data
		use	`fs_const_long',clear
		notes	drop _dta
		notes:	fs_const_long / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID constructed data (long format) 1999 to 2017,
		*notes:	Only individuals appear in all waves are included.
		

		* Git branch info
		stgit9 
		notes : fs_const_long / Git branch `r(branch)'; commit `r(sha)'.
	
	
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
		save	"${PSID_dtFin}/fs_const_long.dta", replace
	
	/*
		* Save log
		cap file		close _all
		cap log			close
		copy			"${bl_do_cleaning}/logs/`name_do'.smcl" ///
						"${bl_do_cleaning}/logs/archive/`name_do' - `c(current_date)' - `c(username)'.smcl", replace
		*/
	
	* Exit	
	exit
			