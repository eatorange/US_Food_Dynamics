
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_const_ind
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	2021/4/24, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	fam_ID_1999 // Personal Identification Number

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
	loc	name_do	PSID_const_ind
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doCon}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
		
	/****************************************************************
		SECTION 1: Construct descriptive variables		 									
	****************************************************************/
	
	use	"${PSID_dtInt}/PSID_cleaned_ind.dta", clear
	
	
	*	SECTION 1-1: Survey Information Variables
		
				
		*	1999 Family ID (base-year)
		assert !mi( splitoff_indicator1999) if !mi( x11102_1999)
		generate	fam_ID_1999	=	x11102_1999	if	!mi(x11102_1999)
		lab	var	fam_ID_1999	"Family ID in 1999"
				
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
		label	values		sample_source		sample_source
		label	variable	sample_source	"Source of Sample"	
		
		gen		sample_source_SRC_SEO=1	if	inlist(sample_source,1,2)	//	SRC or SEO
		replace	sample_source_SRC_SEO=0	if	mi(sample_source_SRC_SEO)
		
		label	values	sample_source_SRC_SEO	yesno
		label	variable	sample_source_SRC_SEO	"Sample = SRC or SEO"	
		
					
		*	Week of the year (when survey was done)
		forval	year=1999(2)2017	{
			
			gen	week_of_year`year'	=	week(mdy(interview_month`year',interview_day`year',`year'))
			
			lab	var	week_of_year`year'	"Week of the year (`year')"
			
		}
					
		*	Import variables for sampling error estimation
		preserve
		
			use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
		
			*	Generate a single ID variable
			generate	x11101ll=(ER30001*1000)+ER30002
			
			tempfile	Ind
			save		`Ind'
		
		restore
	
		
	
	*	SECTION 1-2: Demographic Variables
		
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


		*	Family Composition Change
		
			*	As the first step, we construct the maximum sequence number per each family unit per each wave
			*	This maximum sequence number will be used to detect whether family unit has change in composition
			*	This step is needed as "family composition change" variable is not enough: there are families which recorded "no family change" but some family members actually moved out (either to institution or to form other FU)
			*	This could be the reason why PSID guide movie suggested to "keep individuals with a sequence number 1-20"
			
			foreach	year	in	1999	2001	2003	2015	2017	{			
				cap	drop	max_sequence_no`year'
				bys	x11102_`year':	egen	max_sequence_no`year'	=	max(xsqnr_`year')	//	x11102_`year' is household ID per each year. Thus it records the largest sequence number of a family member.
				label	var	max_sequence_no`year'	"Maximum sequence number of FU in `year'"
			}
			

			*	No change (1999-2003, 1999 as base year)
			local	var	fam_comp_nochange_99_03
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0		if	inrange(xsqnr_1999,1,89)	//	Excluding inappropriate (xsqnr_1999==0), thus all individuals as of 1999
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
			
			
		
		*	Region
		**	 This region uses the classificaton the PSID uses, different from this study uses.
		label define	region_residence	0	"Wide Code"	1	"Northeast"	2	"North Central"	3	"South"	4	"West"	///
											5	"Alaska/Hawaii"	6	"Foreign Country"	9	"NA/DK"
		label	values	region_residence*	region_residence
		
		
		*	Combine Urbanicity (99-13) and Metropolitan Area (15-17)
		forvalues	year=1999(2)2013	{
			gen		metro_area`year'	=	1	if	inrange(urbanicity`year',1,3)	//	Metropolitan Area
			replace	metro_area`year'	=	2	if	inrange(urbanicity`year',4,9)	//	Non-metropolitan Area
			replace	metro_area`year'	=	9	if	inrange(urbanicity`year',99,99)	//	NA
			replace	metro_area`year'	=	0	if	inrange(urbanicity`year',0,0)	//	Inapp-foreign country
		}
		
		label define	metro_area	1	"Metroplitan Area"	2	"NOT Metroplitan area"	9	"NA" 	0	"Inapp-foreign country"
		label	values	metro_area*	metro_area
		
		*	Race (category)
		forval	year=1999(2)2017	{
			gen		race_head_cat`year'=.
			replace	race_head_cat`year'=1	if	inlist(race_head_fam`year',1,5)	//	White
			replace	race_head_cat`year'=2	if	race_head_fam`year'==2	//	Black
			replace	race_head_cat`year'=3	if	inlist(race_head_fam`year',3,4,6,7)	//	Native American, Alskat Native, Asian, etc.
			replace	race_head_cat`year'=.n	if	inrange(race_head_fam`year',8,9)
			
			*	Dummy for each variable
			
			label variable	race_head_cat`year'	"Race (Head), `year'"
		}
		label	define	race_cat	1	"White"	2	"Black"	3	"Others"
		label	values	race_head_cat*	race_cat
		
		*	Marital Status (Binary)
		forval	year=1999(2)2017	{
			gen		marital_status_cat`year'=.
			replace	marital_status_cat`year'=1	if	marital_status_fam`year'==1	//	Married
			replace	marital_status_cat`year'=0	if	inrange(marital_status_fam`year',2,5)	//	Never married, widowed, divorced/annulled, separated
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
			
			gen		age_over65`year'	=0	if	inrange(age_head_fam`year',1,64)
			replace	age_over65`year'	=1	if	!mi(age_head_fam`year')	&	!inrange(age_head_fam`year',1,64)
			label	var	age_over65`year'	"65 or older in `year'"
		}
		label	define	age_head_cat	1	"16-24"	2	"25-34"	3	"35-44"	///
										4	"45-54"	5	"55-64"	6	"65 and older"
		label	values	age_head_cat*	age_head_cat
		
		label	define	age_over65	0 "No"	1	"Yes"
		label	values	age_over65*	age_over65
		
		*	Education	(category)
			foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
				gen		grade_comp_cat`year'	=1	if	inrange(grade_comp_head_fam`year',0,11)	//	Less than HS
				replace	grade_comp_cat`year'	=2	if	inrange(grade_comp_head_fam`year',12,12)	//	HS
				replace	grade_comp_cat`year'	=2	if	inrange(grade_comp_head_fam`year',0,11)	&	hs_completed_head`year'	==	1	//	Completed GED -> Treat as HS
				replace	grade_comp_cat`year'	=3	if	inrange(grade_comp_head_fam`year',13,15)	//	Some college
				replace	grade_comp_cat`year'	=4	if	grade_comp_head_fam`year'>=16 & !mi(grade_comp_head_fam`year')	//	College
				replace	grade_comp_cat`year'	=.n	if	mi(grade_comp_head_fam`year')
				label	var	grade_comp_cat`year'	"Grade Household Head Completed, `year'"
				
				gen		grade_comp_cat_spouse`year'	=1	if	inrange(grade_comp_spouse`year',0,11)	//	Less than HS
				replace	grade_comp_cat_spouse`year'	=2	if	inrange(grade_comp_spouse`year',12,12)	//	HS
				replace	grade_comp_cat_spouse`year'	=2	if	inrange(grade_comp_spouse`year',0,11)	&	hs_completed_spouse`year'	==	1	//	Completed GED -> Treat as HS
				replace	grade_comp_cat_spouse`year'	=3	if	inrange(grade_comp_spouse`year',13,15)	//	Some college
				replace	grade_comp_cat_spouse`year'	=4	if	grade_comp_spouse`year'>=16 & !mi(grade_comp_spouse`year')	//	College
				replace	grade_comp_cat_spouse`year'	=.n	if	mi(grade_comp_spouse`year')
				label	var	grade_comp_cat_spouse`year'	"Grade Household Spouse Completed, `year'"
			}
			
			label	define	grade_comp_cat	1	"Less than HS"	2	"HS"	3	"Some College"	4	"College Degree"
			label 	values	grade_comp_cat*	grade_comp_cat
			
			order	grade_comp_cat_spouse*, after(grade_comp_cat2017)
			
		*	Child food assistance program 
		**	Let "N/A (no child)" as 0 for now.
	
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	{
		
			generate	child_meal_assist`year'	=.
			
			*	Merge breakfast and lunch in to one variable, to be compatible with 2013-2017 data.
			*replace		child_meal_assist`year'	=.n	if	child_bf_assist`year'==.n	&	child_lunch_assist`year'==.n
			replace		child_meal_assist`year'	=8	if	inlist(8,child_bf_assist`year',child_lunch_assist`year')	//	"Don't know" if either lunch or breakfast is "don't know'"
			replace		child_meal_assist`year'	=9	if	inlist(9,child_bf_assist`year',child_lunch_assist`year')	//	"Refuse to answer" if either lunch or breakfast is "refuse to answer"
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
				if	emp_status_head`year'==4	&	///	/*	Household head is currently retired	*/		
					inrange(retire_year_head`year',1910,`year')	&	///	/*	Retired year is in between 1910 and the year surveyd (to exclude data entry error)
					inrange(age_head_fam`year',1,120)	&	///	/*	Household head is between 1 and 120 years old (to exclude data entry error)
					`year'>=retire_year_head`year'	//	The year surveyed is later than the year retired (to exclude non-sensible responses)
			lab	var	retire_age`year' "Retirement age in `year'"
		}
		
	
	
	*	SECTION 1-3: Socio-economic variables
			
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

				*	1999-2015
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
				

					
		*	Food stamp usage (current year)
		*	Merge "current year" (99-07) and "last month" (09-17)
		*	Since very little households (less than 0.5% each year) survyed in Jan, we can create dummy for "current year" if household used stamp "last month" (if anyone said "yes" during Feb-Dec, it implies they used stamp in curent year)
		***	Issue: the fact that HH didn't use food stamp last month does NOT necessarily imply that HH didn't use food stamp the entire year.
		foreach	year	in	2009	2011	2013	2015	2017	{
			
			gen		food_stamp_used_0yr`year'	=	0
			replace	food_stamp_used_0yr`year'	=	1	if	food_stamp_used_1month`year'	==	1
			replace	food_stamp_used_0yr`year'	=.		if	mi(food_stamp_used_1month`year')
			
			label	var	food_stamp_used_0yr`year'	"SNAP/food stamp"
		}
		
		order	food_stamp_used_0yr2009-food_stamp_used_0yr2017, after(food_stamp_used_0yr2007)
		
		
		*	Food stamp value
		*	Annualize food stamp value redeemed (in thousands)
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			
			
			*	Previous year
			replace	food_stamp_value_1yr`year'	=	food_stamp_value_1yr`year'	*	52	if	food_stamp_freq_1yr`year'==3	//	If response was weekly, multiply by 52
			replace	food_stamp_value_1yr`year'	=	food_stamp_value_1yr`year'	*	26	if	food_stamp_freq_1yr`year'==4	//	If response was bi-weekly, multiply by 26
			replace	food_stamp_value_1yr`year'	=	food_stamp_value_1yr`year'	*	12	if	food_stamp_freq_1yr`year'==5	//	If response was monthly, multiply by 12
			replace	food_stamp_value_1yr`year'	=	0									if	inlist(food_stamp_freq_1yr`year',7,8,9,0)	//	If others (dk, others, refuse, inapp), assign 0		
			
			label	variable	food_stamp_value_1yr`year'	"Annual food stamp value of the previous year in `year'"
			
			*	Current year
			if	inlist(`year',1999,2001,2003,2005,2007)	{
				
				replace	food_stamp_value_0yr`year'	=	food_stamp_value_0yr`year'	*	52	if	food_stamp_freq_0yr`year'==3	//	If response was weekly, multiply by 52
				replace	food_stamp_value_0yr`year'	=	food_stamp_value_0yr`year'	*	26	if	food_stamp_freq_0yr`year'==4	//	If response was bi-weekly, multiply by 26
				replace	food_stamp_value_0yr`year'	=	food_stamp_value_0yr`year'	*	12	if	food_stamp_freq_0yr`year'==5	//	If response was monthly, multiply by 12
				replace	food_stamp_value_0yr`year'	=	0									if	inlist(food_stamp_freq_0yr`year',7,8,9,0)	//	If others (dk, others, refuse, inapp), assign 0
				
				label	variable	food_stamp_value_0yr`year'	"Annual food stamp value of the current year in `year'"
				
			}
			
			if	inlist(`year',2009,2011,2013,2015,2017)	{	//	These years only have monthly food stamp values redeemed
				
				gen		food_stamp_value_0yr`year'	=	food_stamp_value_1month`year'	*	12	//	Multiply monthly value by 12								
				label	variable	food_stamp_value_0yr`year'	"Annual food stamp value of the current year in `year'"
				
				
			}	
			
			*	Recode other answers as zero.
			recode	food_stamp_value_1yr`year'	food_stamp_value_0yr`year'	(0	5	8	9	.d	.r=0)
			
			gen		food_stamp_value_0yr_pc`year'	=	food_stamp_value_0yr`year'	/	num_FU_fam`year'
			label	var	food_stamp_value_0yr_pc`year'	"Food stamp (per capita) value current year"
			
		}
		
		
		*	Add food stamp value to food expenditures
		forval	year=1999(2)2017	{
			
			egen	food_exp_stamp`year'	=	rowtotal(food_exp_total`year' food_stamp_value_0yr`year')
			
			label	var	food_exp_stamp`year'	"Total food exp with stamp value (`year')"
		}
		
		
		*	Income &  expenditure & wealth & tax per capita
			
			foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
					
					*	Income per capita
					gen	income_pc`year'	=	total_income_fam`year'/num_FU_fam`year'
					
					*	Expenditures, tax, debt and wealth per capita
					
					gen	food_exp_pc`year'			=	food_exp_total`year'/num_FU_fam`year'	//	Without food stamp value
					gen	food_exp_stamp_pc`year'		=	food_exp_stamp`year'/num_FU_fam`year'	//	With food stamp value
					gen	child_exp_pc`year'			=	child_exp_total`year'/num_FU_fam`year'
					gen	edu_exp_pc`year'			=	edu_exp_total`year'/num_FU_fam`year'
					gen	health_exp_pc`year'			=	health_exp_total`year'/num_FU_fam`year'
					gen	house_exp_pc`year'			=	house_exp_total`year'/num_FU_fam`year'
					gen	property_tax_pc`year'		=	property_tax`year'/num_FU_fam`year'
					gen	transport_exp_pc`year'		=	transport_exp`year'/num_FU_fam`year'
					*gen	other_debts_pc`year'		=	other_debts`year'/num_FU_fam`year'
					gen	wealth_pc`year'				=	wealth_total`year'/num_FU_fam`year'
					
					
					if	inrange(`year',2005,2017)	{	//	Cloth (2021-1-31: NOT verified)
						gen	cloth_exp_pc`year'	=	cloth_exp_total`year'/num_FU_fam`year'
						label	variable	cloth_exp_pc`year'	"Cloth expenditure per capita, `year'"
					}
			}
		
	
		*	Winsorize family income and expenditures per capita at top 1%, and scale it to thousand-dollars via division
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			
			foreach	var	in	income_pc	food_exp_pc	food_exp_stamp_pc	child_exp_pc	edu_exp_pc	health_exp_pc	house_exp_pc	property_tax_pc	transport_exp_pc	/*other_debts*/	wealth_pc	{
				
				*	Winsorize top 1% 
				winsor `var'`year' 			if xsqnr_`year'!=0 & inrange(sample_source,1,3), gen(`var'_wins`year') p(0.01) highonly
				
				*	Keep winsorized variables only
				drop	`var'`year'
				rename	`var'_wins`year'		`var'`year'
				
				*	Scale to thousand-dollars
				replace	`var'`year'	=	`var'`year'/1000
				
			}	//	var	
			
			label	variable	income_pc`year'	"Family income per capita (K) - `year'"
			label	variable	food_exp_pc`year'	"Food exp per capita (K) - `year'"
			label	variable	food_exp_stamp_pc`year'	"Food exp (with stamp) per capita (K) - `year'"
			label	variable	child_exp_pc`year'	"Child expenditure per capita (K) - `year'"
			label	variable	edu_exp_pc`year'	"Education expenditure per capita (K) - `year'"
			label	variable	health_exp_pc`year'	"Health expenditure per capita (K) - `year'"
			label	variable	house_exp_pc`year'	"House expenditure per capita (K) - `year'"
			label	variable	property_tax_pc`year'	"Property tax per capita (K) - `year'"
			label	variable	transport_exp_pc`year'	"Transportation expenditure per capita (K) - `year'"
			label	variable	wealth_pc`year'			"Wealth per capita (K) - `year'"
			
		}	//	year
		
		
		*	Employed status (simplified)
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			gen		emp_HH_simple`year'	=.
			replace	emp_HH_simple`year'	=1	if	inrange(emp_status_head`year',1,2)	//	Employed
			replace	emp_HH_simple`year'	=5	if	inrange(emp_status_head`year',3,99)	//	Unemployed (including retired, disabled, keeping house, inapp, ...)
			
			gen		emp_spouse_simple`year'	=.
			replace	emp_spouse_simple`year'	=1	if	inrange(emp_status_spouse`year',1,2)	//	Employed
			replace	emp_spouse_simple`year'	=5	if	inrange(emp_status_spouse`year',3,99)	|	emp_status_spouse`year'==0	//	Unemployed (including retired, disabled, keeping house, inapp, DK, NA,...)	
		}
		
		*	% of children in the households
		foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			gen		ratio_child`year'	=	num_child_fam`year'/num_FU_fam`year'
			label	var	ratio_child`year'	"\% of children population in `year'"
		}
		

	
		*	TFP food plan cost
			
			*	Generate temporary state code variable, as food cost vary by some states (AL, HA, all others)
			forval	year=1999(2)2017	{
				
				gen		state_region_temp`year'	=	1	if	inrange(state_resid_fam`year',0,49)	//	48 states
				replace	state_region_temp`year'	=	2	if	state_resid_fam`year'==50	//	AK
				replace	state_region_temp`year'	=	3	if	state_resid_fam`year'==51	//	HA
				
			}
			
		
		tempfile temp
		save	`temp'
		
			/*
			*	Import monthly food plan cost data, which has cost per gender-age
			import excel "${clouldfolder}/DataWork/USDA/Cost of Food Reports/Food Plans_Cost of Food Reports.xlsx", sheet("thrifty") firstrow clear

			*	Make sure each gender-age-state uniquly identifies observation
			isid	gender	age	state 

			rename	gender	indiv_gender

			tempfile	foodprice_raw
			save	`foodprice_raw'
		
			*	Save data for each year
			forvalues	year=1999(2)2017	{
				
				use	`foodprice_raw', clear
				
				rename	age	age_ind`year'
				rename	state	state_region_temp`year'
				keep	indiv_gender	age_ind`year'	state_region_temp`year'	foodcost_monthly_`year'
				
				tempfile	foodcost_`year'
				save	`foodcost_`year''
				
			}
			*/
			
			forvalues	year=2001(2)2017	{
				
				import excel "${clouldfolder}/DataWork/USDA/Cost of Food Reports/Food Plans_Cost of Food Reports.xlsx", sheet("thrifty_`year'") firstrow clear
						
				reshape long foodcost_, i(gender state age) j(month)
				
				isid	gender	age	state month

				rename	gender	indiv_gender
				rename	age		age_ind`year'
				rename	state	state_region_temp`year'
				rename	month	interview_month`year'
				rename	foodcost_	foodcost_monthly_`year'
				keep	indiv_gender	age_ind`year'	state_region_temp`year'	interview_month`year'	foodcost_monthly_`year'
				
				tempfile foodcost_`year'
				save	`foodcost_`year''
				
			}
			
			
			use	`temp', clear
						
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
			
	
			
			forvalues	year=2001(2)2017	{
				
				merge m:1 indiv_gender age_ind`year'	state_region_temp`year' interview_month`year'	using `foodcost_`year'', keepusing(foodcost_monthly_`year')	nogen keep(1 3)
				replace	foodcost_monthly_`year' = foodcost_monthly_avgadult_`year'	if	mi(age_ind`year')	&	inrange(xsqnr_`year',1,20)
				
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
					*	This step makes all members in a household have the same non-missing value, so they can be treated as duplicates and be dropped when later constructing household-level data
					bys	x11102_`year': egen foodexp_W_`plan'`year'_temp = mean(foodexp_W_`plan'`year')
					drop	foodexp_W_`plan'`year'
					rename	foodexp_W_`plan'`year'_temp	foodexp_W_`plan'`year'
					
					label	var	foodexp_W_`plan'`year'	"`plan' Food Plan (annual per capita) in `year' (K)"
				
				}
	
				
			}
			
			*	Drop variables no longer needed
			drop	foodcost_monthly_????	state_region_temp????
		
		
		*	Food expenditure recall period
		*	They are separately collected from "used food stamp this year(or last monnth)" and from "didn't use...'". We can merge them as a single variable.
		
		lab	define	foodexp_recall_period	2	"Day"	///
											3 	"Week"	///
											4 	"Two weeks"	///
											5 	"Month"	///
											6 	"Year"	///
											7 	"Other"	///
											8 	"DK"	///
											9 	"NA/refused"	///
											0 	"Inap.", replace
		
		forval year=1999(2)2017	{
			foreach	expcat	in	home	away	deliv	{
				
				gen		foodexp_recall_`expcat'`year'	=	foodexp_recall_`expcat'_stamp`year'		if	food_stamp_used_0yr`year'	==	1	//	Stamp users
				replace	foodexp_recall_`expcat'`year'	=	foodexp_recall_`expcat'_nostamp`year'	if	food_stamp_used_0yr`year'	!=	1	//	Non-stamp users
				
				label	var	foodexp_recall_`expcat'`year'	"Food expenditure (`expcat') recall period in `year'"
				label	val	foodexp_recall_`expcat'`year'	foodexp_recall_period
				
			}
			
		}
	
		
		*	Food security category (simplified)
		*	This simplified category is based on Tiehen(2019)
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			clonevar	fs_cat_fam_simp`year'	=	fs_cat_fam`year'
			recode		fs_cat_fam_simp`year'	(3 4=0) (1 2=1)

		}
		label	define	fs_cat_simp	0	"Food Insecure"	1	"Food Secure"
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
		

		tempfile	dta_constructed
		save		`dta_constructed'
		
		

		*	Import variables
		use	`dta_constructed', clear
		merge	m:1	x11101ll	using	`Ind', assert(2 3) keep(3) keepusing(ER31996 ER31997) nogen
		
	*	Keep relevant variables and observations
				
		*	Drop outliers with strange pattern
		drop	if	x11102_1999==10015	//	This Family has outliers (food expenditure in 2009) as well as strange flutation in health expenditure (2007), thus needs to be dropped (* It attrits in 2011 anway)
		
		
		*	Keep	relevant sample
		*	We need to decide what families to track (so we have only 1 obs per family in baseyear)
		keep	if	fam_comp_samehead_99_17==1	//	Families with same household during 1999-2017

		
		*	Drop individual level variables
		drop	x11101ll weight_long_ind* weight_cross_ind* respondent???? relat_to_head* age_ind* edu_years????	relat_to_current_head*	indiv_gender
		
		*	Keep	relevant years
		keep	*1999	*2001	*2003	*2005	*2007	*2009	*2011	*2013	*2015	*2017	/*fam_comp**/	sample_*	ER31996 ER31997		
		
		duplicates drop	
		isid x11102_1999	
		
		
		*	Save it as wide format
		tempfile	fs_const_wide
		save		`fs_const_wide'
		
		
	/****************************************************************
		SECTION 2: Construct a long format data
	****************************************************************/
		
	
	*	Re-shape dataset

		*	Retrieve the list of time-series variables
		qui	ds	*	//	All variables
		local	allvar	`r(varlist)'

		ds	sample_source sample_source_SRC_SEO	fam_ID_1999	ER31996 ER31997
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
		label	var	fs_scale_fam_rescale"USDA food security scale score-rescaled"
		label	var	fs_cat_fam 			"USDA food security category"
		label	var	food_stamp_used_2yr	"Received food Stamp (2 years ago)"
		label	var	food_stamp_used_1yr "Received food stamp (previous year)"
		label	var	food_stamp_used_0yr "Received food stamp (current year)"
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
		label	var	income_pc			"Family income per capita (thousands)"
		label	var	food_exp_pc			"Food exp (without stamp) per capita (thousands)"
		label	var	food_exp_stamp_pc	"Food exp per capita (thousands)"
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
		label	var	child_exp_pc		"Annual child expenditure (pc) (thousands)"
		label	var	edu_exp_pc		"Annual education expenditure (pc) (thousands)"
		label	var	health_exp_pc		"Annual health expenditure (pc) (thousands)"
		label	var	house_exp_pc		"Annual house expenditure (pc) (thousands)"
		label	var	property_tax_pc		"Property tax (pc) (thousands)"
		label	var	transport_exp_pc	"Annual transportation expenditure (pc) (thousands)"
		label	var	wealth_pc		"Wealth (pc) (thousands)"
		label	var	emp_HH_simple		"Employed"
		label	var	emp_spouse_simple		"Employed (spouse)"
		label	var	fs_cat_MS		"Marginal food secure"
		label	var	fs_cat_IS		"Food insecure"
		label	var	fs_cat_VLS		"Very Low food secure"
		label	var	child_bf_assist		"Free/reduced breakfast from school"
		label	var	child_lunch_assist		"Free/reduced lunch from school"
		label	var	other_debts			"Other debts"
		label	var	fs_cat_fam_simp		"Food Security Category (binary)"
		label	var	age_over65		"65 or older"
		label	var	retire_age		"Age of retirement"
		label	var	retire_year_head	"Year of retirement"
		label	var	retire_year_head	"Age when retired"
		label	var	ratio_child			"\% of children population"
		label	var	grade_comp_cat_spouse	"Highest Grade Completed (Spouse)"
		label	var	foodexp_W_thrifty	"Thrifty Food Plan (TFP) cost (annual per capita)"
		label	var	region_residence	"Region of Residence"
		label	var	metro_area			"Residence in Metropolitan Area"
		label	var	foodexp_recall_home		"Food expenditure (at home) recall period"
		label	var	foodexp_recall_away		"Food expenditure (away) recall period"
		label	var	foodexp_recall_deliv	"Food expenditure (delivered) recall period"
		label	var	mental_problem	"Mental problem"
		label	var	week_of_year	"Week of the year"		
		label	var	FPL_		"Federal Poverty Line"
		label	var	income_to_poverty		"Income to Poverty Ratio"
		label	var	income_to_poverty_cat		"Income to Poverty Ratio (category)"
		label	var	food_stamp_value_1yr	"Annual food stamp value of the previous year"
		label	var	food_stamp_value_0yr	"Annual food stamp value of the current year"
			      
		*	Drop variable no longer used.
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
	*	We use the data up to 2015 as "in-sample", and the data in 2017 as "out-of-sample"
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
				college_completed	college_comp_spouse	other_degree_head	other_degree_spouse	food_stamp_used_1yr	food_stamp_used_0yr	///
				child_meal_assist	WIC_received_last	elderly_meal	child_daycare_any	child_daycare_FSP	child_daycare_snack	emp_HH_simple emp_spouse_simple	mental_problem
		label values	`r(varlist)'	yes1no0
		recode	`r(varlist)'	(0	5	8	9	.d	.r=0)
	}
	
	*	Create a lagged variable of the outcome variable and its higher polynomial terms (needed for Shapley decomposition)	
	*	Also create a scaled variable (multiplied by 1,000) and their higher polynomial terms for model selection.
	
	forval	i=1/5	{
		
		*	Lagged food exp and higher order terms
		gen			lag_food_exp_pc_`i'	=	(cl.food_exp_pc)^`i'
		label	var	lag_food_exp_pc_`i'	"Lagged food exp (pc) - `i'th order"
		
		*	Lagged food exp (with stamp) and higher order terms
		gen			lag_food_exp_stamp_pc_`i'	=	(cl.food_exp_stamp_pc)^`i'
		label	var	lag_food_exp_stamp_pc_`i'	"Lagged food exp (pc) (with stamp) - `i'th order"
		
		*	Re-scale created terms 
		gen			lag_food_exp_pc_th_`i'	=	(lag_food_exp_pc_`i')/1000
		label	var	lag_food_exp_pc_th_`i'	"Lagged food exp (pc) - `i'th order ('000)"
		
		gen			lag_food_exp_stamp_pc_th_`i'	=	(lag_food_exp_stamp_pc_`i')/1000
		label	var	lag_food_exp_stamp_pc_th_`i'	"Lagged food exp (pc) (with stamp) - `i'th order ('000)"
				
	}
	
	label	var	lag_food_exp_pc_1	"Lagged food exp per capita"
	order		lag_food_exp_pc_?	lag_food_exp_pc_th_?	,	after(food_exp_pc)
	
	label	var	lag_food_exp_stamp_pc_1	"Lagged food exp (with stamp) per capita"
	order		lag_food_exp_stamp_pc_?	lag_food_exp_stamp_pc_th_?,	after(food_exp_stamp_pc)
	
	 
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
		gen	age_head_fam_sq		=	((age_head_fam)^2)/1000
		label	var	age_head_fam_sq	"Age$^2$/1000"
		gen	age_spouse_sq		=	(age_spouse)^2
		label	var	age_spouse_sq	"Age$^2$ (spouse)"
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
		local	catvars	race_head_cat	marital_status_fam	gender_head_fam	state_resid_fam	housing_status	family_comp_change	couple_status	grade_comp_cat	grade_comp_cat_spouse	year	sample_source	region_residence metro_area
		foreach	var	of	local	catvars	{
			tab	`var',	gen(`var'_enum)
		}
		rename	gender_head_fam_enum1	HH_female
		label	variable	HH_female	"Female"
		
		rename	(race_head_cat_enum1 race_head_cat_enum2 race_head_cat_enum3)	(HH_race_white	HH_race_black	HH_race_other)
		label	variable	HH_race_white	"Race: White"
		label	variable	HH_race_black	"Race: Black"
		label	variable	HH_race_other	"Race: Other"
		gen		HH_race_color=1	if	inlist(1,HH_race_black,HH_race_other)
		replace	HH_race_color=0	if	HH_race_color!=1	&	!mi(HH_race_white)
		label	variable	HH_race_color	"Race: Person of Color"
		
		rename	(grade_comp_cat_enum1	grade_comp_cat_enum2	grade_comp_cat_enum3	grade_comp_cat_enum4)	///
				(highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col)
				
		label	variable	highdegree_NoHS		"Highest degree: less than high school"
		label	variable	highdegree_HS		"Highest degree: high school"
		label	variable	highdegree_somecol	"Highest degree: some college"
		label	variable	highdegree_col		"Highest degree: college"
		
			*	Aggregate some categories
			cap	drop	highdegree_HSorbelow	//	binary for HS or below, or beyond HS.
			gen		highdegree_HSorbelow=0	if	inlist(1,highdegree_somecol,highdegree_col)
			replace	highdegree_HSorbelow=1	if	inlist(1,highdegree_NoHS, highdegree_HS)
		
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
		
		rename	(region_residence_enum1 region_residence_enum2 region_residence_enum3 region_residence_enum4 region_residence_enum5)	///
				(region_NE	region_Ncentral	region_South	region_West	region_ALHA)
				
		label	variable	region_NE		"Region: Northeast"
		label	variable	region_Ncentral	"Region: North Central"
		label	variable	region_South	"Region: South"
		label	variable	region_West		"Region: West"
		label	variable	region_ALHA		"Region: Alaska/Hawaii"
		
		rename	(metro_area_enum2 metro_area_enum3)	///
				(resid_metro	resid_nonmetro)
		label	variable	resid_metro		"Residence: Metropolitan Area"
		label	variable	resid_nonmetro	"Residence: Non-Metropolitan Area"
		
		*	Create a group of state variables, based on John's suggestion (2020/12)
			
			*	Reference state group (New York state)
			gen 	state_bgroup	=	state_resid_fam_enum32	//	NY, reference state
			
			*	Excluded states (AK, HI, Other U.S. territories, Don't know/refuse to answer)
			egen	state_group0	=	rowmax(state_resid_fam_enum1	state_resid_fam_enum50	state_resid_fam_enum51	state_resid_fam_enum52)	//	Inapp, DK/NA, AK, HI
			
			*	Northeast
			egen	state_group1	=	rowmax(	state_resid_fam_enum19 state_resid_fam_enum29 state_resid_fam_enum44	///	//	ME, NH, VT
												state_resid_fam_enum21 state_resid_fam_enum7)	//	MA, CT	
			gen		state_group_NE	=	inlist(1,state_bgroup,state_group1)	//	including NY.
			
			*	Mid-Atlantic
			egen	state_group2	=	rowmax(state_resid_fam_enum38)	//	PA
			egen	state_group3	=	rowmax(state_resid_fam_enum30)	//	NJ
			egen	state_group4	=	rowmax(state_resid_fam_enum9	state_resid_fam_enum8	state_resid_fam_enum20)	//	DC, DE, MD
			egen	state_group5	=	rowmax(state_resid_fam_enum45)	//	VA
			gen		state_group_MidAt	=	inlist(1,state_group2,state_group3,state_group4,state_group5)
			
			*	South
			egen	state_group6	=	rowmax(state_resid_fam_enum33	state_resid_fam_enum39)	//	NC, SC
			egen	state_group7	=	rowmax(state_resid_fam_enum11)	//	GA
			egen	state_group8	=	rowmax(state_resid_fam_enum17	state_resid_fam_enum41	state_resid_fam_enum47)	//	KY, TN, WV
			egen	state_group9	=	rowmax(state_resid_fam_enum10)	//	FL
			egen	state_group10	=	rowmax(state_resid_fam_enum2	state_resid_fam_enum4	state_resid_fam_enum24 state_resid_fam_enum18)	//	AL, AR, MS, LA
			egen	state_group11	=	rowmax(state_resid_fam_enum42)	//	TX
			gen		state_group_South	=	inlist(1,state_group6,state_group7,state_group8,state_group9,state_group10,state_group11)
			
			*	Mid-west
			egen	state_group12	=	rowmax(state_resid_fam_enum35)	//	OH
			egen	state_group13	=	rowmax(state_resid_fam_enum14)	//	IN
			egen	state_group14	=	rowmax(state_resid_fam_enum22)	//	MI
			egen	state_group15	=	rowmax(state_resid_fam_enum13)	//	IL
			egen	state_group16	=	rowmax(state_resid_fam_enum23 state_resid_fam_enum48)	//	MN, WI
			egen	state_group17	=	rowmax(state_resid_fam_enum15	state_resid_fam_enum25)	//	IA, MO
			gen		state_group_MidWest	=	inlist(1,state_group12,state_group13,state_group14,state_group15,state_group16,state_group17)
			
			*	West
			egen	state_group18	=	rowmax(	state_resid_fam_enum16	state_resid_fam_enum27	///	//	KS, NE
												state_resid_fam_enum34	state_resid_fam_enum40	///	//	ND, SD
												state_resid_fam_enum36)	//	OK
			egen	state_group19	=	rowmax(	state_resid_fam_enum3	state_resid_fam_enum6	///	//	AZ, CO
												state_resid_fam_enum12	state_resid_fam_enum26	///	//	ID, MT
												state_resid_fam_enum28	state_resid_fam_enum31	///	//	NV, NM
												state_resid_fam_enum43	state_resid_fam_enum49)		//	UT, WY
			egen	state_group20	=	rowmax(	state_resid_fam_enum37	state_resid_fam_enum46)	//	OR, WA
			egen	state_group21	=	rowmax(	state_resid_fam_enum5)	//	CA	
			gen		state_group_West	=	inlist(1,state_group18,state_group19,state_group20,state_group21)
			
			label var	state_bgroup	"NY"
			label var	state_group0	"AK/HI/U.S. territory/DK/NA"
			label var	state_group1	"ME/NH/VT/MA/CT"
			label var	state_group2	"PA"
			label var	state_group3	"NJ"
			label var	state_group4	"DC/DE/MD"
			label var	state_group5	"VA"
			label var	state_group6	"NC/SC"
			label var	state_group7	"GA"
			label var	state_group8	"KY/TN/WV"
			label var	state_group9	"FL"
			label var	state_group10	"AL/AR/MS/LA"
			label var	state_group11	"TX"
			label var	state_group12	"OH"
			label var	state_group13	"IN"
			label var	state_group14	"MI"
			label var	state_group15	"IL"
			label var	state_group16	"MN/WI"
			label var	state_group17	"IA/MO"
			label var	state_group18	"KS/NE/ND/SD/OK"
			label var	state_group19	"AZ/CO/ID/MT/NV/NM/UT/WY"
			label var	state_group20	"OR/WA"
			label var	state_group21	"CA"
			
			label var	state_group_NE		"Region: NorthEast"
			label var	state_group_MidAt	"Region: Mid-Atlantic"
			label var	state_group_South	"Region: South"
			label var	state_group_MidWest	"Region: MidWest"
			label var	state_group_West	"Region: West"
			
		
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
	
	*	Re-label variables so they correspond to the variable description table (Also need to copy and paste regression result)
	label	var	HH_female			"Female"
	label	var	HH_race_white		"White"
	label	var	HH_race_color		"Non-White"
	label	var	marital_status_cat	"Married"
	label	var	income_pc			"Income per capita"
	label	var	ln_income_pc		"ln(income per capita)"
	label	var	food_exp_pc			"Food expenditure per capita"
	label	var	food_exp_stamp_pc	"Food expenditure per capita (with food stamp)"
	label	var	emp_HH_simple		"Employed"
	label	var	phys_disab_head		"Disabled"
	label	var	num_FU_fam			"Family size"
	label	var	ratio_child			"\% of children"
	label	var	highdegree_NoHS		"Less than high school"
	label	var	highdegree_HS		"High school"
	label	var	highdegree_somecol	"Some college"
	label	var	highdegree_col		"College"
	label	var	food_stamp_used_1yr	"SNAP/food stamp"
	label	var	child_meal_assist	"Child meal"
	label	var	WIC_received_last	"WIC"
	label	var	elderly_meal		"Elderly meal"
	label	var	no_longer_employed	"No longer employed"
	label	var	no_longer_married	"No longer married"
	label 	var	no_longer_own_house	"No longer owns house"
	label	var	became_disabled		"Became disabled"
	
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
		gen	weight_multi1	=	weight_l1_r
		gen	weight_multi2	=	weight_long_fam_base
		
		*	For an alternative approach, multiply two weights to be used as a new survey weight
		gen	weight_multi12	=	weight_multi1*weight_multi2
		
		*	To use an alternative approach, change the new surveydata setting as following
		svyset	newsecu	[pweight=weight_multi12] /*,	singleunit(scaled)*/
		
	
	*	Save it as long format
		tempfile	fs_const_long
		save		`fs_const_long'
	
		
	/****************************************************************
		SECTION 3: Construct PFS	 									
	****************************************************************/		
	
	*	Run do-file which includes macros needed for constructing PFS
	*	This file should have already been executed while "PSID_MasterDofile.do" was executed, but run it again just to make sure.
	include	"${PSID_doAnl}/Macros_for_analyses.do"
	
	*	Asess model performance among GLM, LASSO and Random Forest
	*	Before constructing PFS, we need to decide which model to use for constructing PFS
	*	We make decision based on the out-of-sample prediction performance of equation (1) - constructing conditional mean
	*	Performance will be measured by root mean square prediction error (RMSPE), using 2001-2015 as training sample, and 2017 as out-of-sample
	
	**	This measurement needs not be run every time, thus we toggle it only when needed.
	**	As of Sep 2021, LASSO(1.78) and random forest (1.82) does not perform significantly better than GLM(1.83)
	
	local	model_performance_measure=0
	
	if	`model_performance_measure'==1	{
		
		
			
	*	GLM
	
		*	Declare variables
		local	depvar		food_exp_stamp_pc
		
		*	Step 1
		*	Exclude year 10 (to calculate RMPSE)
		svy, subpop(if ${study_sample} & year!=10): glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}, family(gamma)	link(log)
		est	sto	glm_step1
		
	
		*	Predict fitted value and residual
		gen		glm_step1_sample=1	if	e(sample)==1 & sample_source_SRC_SEO & year!=10	
		replace	glm_step1_sample=1	if	year==10 & l.glm_step1_sample==1
		count if glm_step1_sample==1 & year==10	//	Number of 2017 observations used to measure performance
		scalar step1_N_glm=r(N)
		
		predict double mean1_foodexp_glm	if	glm_step1_sample==1
		predict double e1_foodexp_glm		if	glm_step1_sample==1,r
		gen e1_foodexp_sq_glm = (e1_foodexp_glm)^2
		
		egen e1_total_glm=total(e1_foodexp_sq_glm) if glm_step1_sample==1 & year==10
		gen rmspe_step1_glm = sqrt(e1_total_glm/step1_N_glm)
	
	
	
	
	*	LASSO
		
		*	Features to be tested
		*	To increase predictive power, we include the variables not only those originally included in GLM, but also other variables.
	
		local	depvar	food_exp_stamp_pc
		
		local	statevars	lag_food_exp_stamp_pc_1-lag_food_exp_stamp_pc_5		//	up to the order of 5
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse	mental_problem
		local	demovars	age_head_fam age_head_fam_sq	HH_race_white HH_race_color	marital_status_cat	///
							HH_female age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc		sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	child_in_FU_cat	couple_status_enum1-couple_status_enum4
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse					
		local	foodvars	food_stamp_used_0yr food_stamp_used_1yr	child_meal_assist WIC_received_last		elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_group? state_group1? state_group2?
		local	timevars	year_enum2-year_enum9
		
		
		set	seed	20200505
		
		*	Select optimal lambda
		*	We choose optimal lambda by doing cross-validation, but it takes too much time. Thus we run it only when needed
		
		**	Note: "cvlasso" using training data (2001-2015) gives lse-optimal lambda=45467.265, which does penalize "ALL" variables except those we intentionally didn't penalize (time and state FE). It gives RMPSE=2.600
		**	Thus, we manually tested all the values from 50 to 50000, with increment 100. We found lambda=50 minimuzes MSPE (lopt) and the largest lambda within 1-stdev is lambda=11,800	
		
		local	run_cvlasso=0
		
		if	`run_cvlasso'==1	{
			
			numlist "50000(50)1", descending
			*	Finding optimal lambda using cross-validation (computationally intensive)
			cvlasso	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'		`healthvars'	`familyvars'	`eduvars'	`eduvars'	`foodvars'	`childvars'	`regionvars'	`timevars'		if	${study_sample}==1 & year!=10,	///
				/*lopt lse*/  lambda(`r(numlist)')	seed(20200505)	notpen(`regionvars'	`timevars')	 rolling	/*h(1) fe	prestd 	postres	ols*/	plotcv 
				
			est	store	lasso_step1_lse
			cvlasso, postresult lse
			
			*	Display lambda result
			di "lambda is `e(lambda)'"
			
			*	Save plot
			graph	export	"${PSID_outRaw}/cvlasso_result.png", replace
			graph	close
			
		}
			
			
		*	Run lasso with the optimal lambda value	
		
		*local	lambdaval=exp(14.7)	//	14.7 is as of Aug 21
		*local	lambdaval=2208.348	//	manual lambda value from the cvplot. This is the value slightly higher than lse but give only slightly higher MSPE
		*local	lambdaval=1546.914	//	the lse value found from cvlasso using SRC sample only as of Nov 5.
		*local	lambdaval=45467.265 (lse) // LSE value from training set (excluding 2017)
			
		local	lambdaval=11800	//	temporary value, will find the exact value via cvlasso it later.	
						
		lasso2	`depvar'	`statevars'		`demovars'	`econvars'	`healthvars'	`empvars'		`familyvars'	`eduvars'	`foodvars'	///
								`changevars'	`regionvars'	`timevars'	`childvars'	if	${study_sample}==1 & year!=10,	///
					ols lambda(`lambdaval') notpen(`regionvars'	`timevars')
		est	store	lasso_step1_manual
		lasso2, postresults
				
		*	Manually run post-lasso
			gen		lasso_step1_sample=1	if	e(sample)==1	& year!=10
							
			global selected_step1_lasso `e(selected)'	/*`e(notpen)'*/
			svy:	reg `depvar' ${selected_step1_lasso}	`e(notpen)'	if	lasso_step1_sample==1
			est store postlasso_step1_lse
			
			
			replace	lasso_step1_sample=1 if year==10 & l.lasso_step1_sample==1 // This command should run "after" running post-LASSO, since we don't want 2017 to be included in post-LASSO when validating performance
			count if lasso_step1_sample==1 & year==10	//	Number of 2017 observations used to measure performance
			scalar step1_N_lasso=r(N)
			
			*	Predict conditional means and variance from Post-LASSO
			predict double mean1_foodexp_lasso	if	lasso_step1_sample==1, xb	
			predict double e1_foodexp_lasso	if	lasso_step1_sample==1,r	
			gen e1_foodexp_sq_lasso = (e1_foodexp_lasso)^2

			egen e1_total_lasso=total(e1_foodexp_sq_lasso) if lasso_step1_sample==1 & year==10
			gen rmspe_step1_lasso = sqrt(e1_total_lasso/step1_N_lasso)

	
	
	*	Random forest
		
		*	Features to be tested
		*	To increase predictive power, we include the variables not only those originally included in GLM, but also other variables.
		
		local	depvar		food_exp_stamp_pc

		local	statevars	lag_food_exp_stamp_pc_1	//	RF allows non-linearity, thus need not include higher polynomial terms
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse	mental_problem
		local	demovars	age_head_fam HH_race_white HH_race_color	marital_status_cat	HH_female	age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	child_in_FU_cat	couple_status_enum1-couple_status_enum4
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
		local	foodvars	food_stamp_used_0yr food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_group? state_group1? state_group2?
		local	timevars	year_enum2-year_enum9


		local	tune_iter	0	//	Tune how large the value of iterations() need to be. Computationally intensive thus run only when needed
		local	tune_numvars	0	//	Tune the number of variables. Computationally intensive thus run only when needed
		
		*	Tune how large the value of iterations() need to be
		if	`tune_iter'==1	{
			loc	depvar	food_exp_pc
			generate out_of_bag_error1 = .
			generate validation_error = .
			generate iter1 = .
			local j = 0
			forvalues i = 10(5)500 {
				local j = `j' + 1
				rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	year!=10	&	${study_sample}==1, type(reg)	seed(20200505) iterations(`i') numvars(1)
				quietly replace iter1 = `i' in `j'
				quietly replace out_of_bag_error1 = `e(OOB_Error)' in `j'
				predict p if	out_of_sample==1
				quietly replace validation_error = `e(RMSE)' in `j'
				drop p
			}
			label variable out_of_bag_error1 "Out-of-bag error"
			label variable iter1 "Iterations"
			label variable validation_error "Validation error"
			scatter out_of_bag_error1 iter1, mcolor(blue) msize(tiny)	title(OOB Error and Validation Error) ||	scatter validation_error iter1, mcolor(red) msize(tiny)
		
		*	50 seems to be optimal (as of Sep 12, 2021)
		}	//	tune_iter
		
			
		*	Tune the number of variables
		if	`tune_numvars'==1	{
			loc	depvar	food_exp_pc
			generate oob_error = .
			generate nvars = .
			generate val_error = .
			local j = 0
			forvalues i = 1(1)26 {
				local j = `j'+ 1
				rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
											`foodvars'	`childvars'	`changevars'	`regionvars'	if	year!=10	&	${study_sample}==1,	///
											type(reg)	seed(20200505) iterations(50) numvars(`i')
				quietly replace nvars = `i' in `j'
				quietly replace oob_error = `e(OOB_Error)' in `j'
				predict p	if	out_of_sample==1
				quietly replace val_error = `e(RMSE)' in `j'
				drop p
			}
			label variable oob_error "Out-of-bag error"
			label variable val_error "Validation error"
			label variable nvars "Number of variables randomly selected at each split"
			scatter oob_error nvars, mcolor(blue) msize(tiny)	title(OOB Error and Validation Error)	subtitle(by the number of variables)	///
			||	scatter val_error nvars, mcolor(red) msize(tiny)
			
			frame put val_error nvars, into(mydata)
			frame mydata {
				sort val_error, stable
				local min_val_err = val_error[1]
				local min_nvars = nvars[1]
			}
			frame drop mydata
			display "Minimum Error: `min_val_err'; Corresponding number of variables `min_nvars''"
			* (2020-09-05) Minimum Error: 1.780909180641174; Corresponding number of variables 23'
			* (2021-09-12) (valication without 2017) Minimum Error: 1.808252334594727; Corresponding number of variables 17'
		}	//	tune_numvars
		
		
		*	Run random forest
			cap	drop	rf_step1_sample
			cap	drop	importance_mean
			cap	drop	importance_mean1
			
			loc	depvar	food_exp_pc
			rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	year!=10 & 	${study_sample}==1,	///
									type(reg)	iterations(50)	numvars(17)	seed(20200505) 
			gen		rf_step1_sample=1	if		${study_sample}==1 // For Random Forest, ALL observations are used.
			count	if	rf_step1_sample==1	&	year==10
			scalar step1_N_rf=r(N)
			* Variable importance plot
			matrix importance_mean = e(importance)
			svmat importance_mean
			generate importid_mean=""
			local mynames: rownames importance_mean
			local k: word count `mynames'
			if `k'>_N {
				set obs `k'
			}
			forvalues i = 1(1)`k' {
				local aword: word `i' of `mynames'
				local alabel: variable label `aword'
				if ("`alabel'"!="") qui replace importid_mean= "`alabel'" in `i'
				else qui replace importid_mean= "`aword'" in `i'
			}
			gsort	-importance_mean1
			graph hbar (mean) importance_mean1	in	1/12, over(importid_mean, sort(1) label(labsize(2))) ytitle(Importance) title(Feature Importance for Conditional Mean)
			graph	export	"${PSID_outRaw}/rf_feature_importance_step1.png", replace
			graph	close
			
			putexcel	set "${PSID_outRaw}/Feature_importance", sheet(mean) replace	/*modify*/
			putexcel	A3	=	matrix(importance_mean), names overwritefmt nformat(number_d1)
			
			predict	mean1_foodexp_rf
			*	"rforest" cannot predict residual, so we need to compute it manually
			gen	double e1_foodexp_rf	=	food_exp_pc	-	mean1_foodexp_rf
			gen e1_foodexp_sq_rf = (e1_foodexp_rf)^2
			
			
			egen e1_total_rf=total(e1_foodexp_sq_rf) if rf_step1_sample==1 & year==10
			gen rmspe_step1_rf = sqrt(e1_total_rf/step1_N_rf)
		

		
	}
	
	
	*	Construct PFS
	*	Based on the performance result above, we use GLM to construct
	
	local	depvar		food_exp_stamp_pc

		local	model_selection=0	//	Code that determines how many polynomial orders we should include.
		
		*	Model selection (highest order)
		if	`model_selection'==1	{
			
			cap	drop	glm_order2	glm_order3	glm_order4	glm_order5
			
			local	statevars	lag_food_exp_stamp_pc_th_1
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars', family(gamma)	link(log)
			estadd scalar	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct bic
			est	sto	glm_step1_order1
			
			local	statevars	lag_food_exp_stamp_pc_th_1	lag_food_exp_stamp_pc_th_2
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars'	, family(gamma)	link(log)
			estadd scalar 	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct bic
			est	sto	glm_step1_order2
			predict glm_order2	if	e(sample)==1 & `=e(subpop)'
			
			local	statevars	lag_food_exp_stamp_pc_th_1-lag_food_exp_stamp_pc_th_3
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars'	, family(gamma)	link(log)
			estadd scalar 	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct aic
			est	sto	glm_step1_order3
			predict glm_order3	if	e(sample)==1 & `=e(subpop)'
			
			local	statevars	lag_food_exp_stamp_pc_th_1-lag_food_exp_stamp_pc_th_4
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars'	, family(gamma)	link(log)
			estadd scalar	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct aic
			est	sto	glm_step1_order4
			predict glm_order4	if	e(sample)==1 & `=e(subpop)'
			
			local	statevars	lag_food_exp_stamp_pc_th_1-lag_food_exp_stamp_pc_th_5
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars'	, family(gamma)	link(log)
			estadd scalar	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct aic
			est	sto	glm_step1_order5
			predict glm_order5	if	e(sample)==1 & `=e(subpop)'
			
			*	Output
			**	AER requires NOT to use asterisk(*) to display significance level, so we don't display it here
			**	We can display them by modifying some options
			
			esttab	glm_step1_order1	glm_step1_order2	glm_step1_order3	glm_step1_order4	glm_step1_order5	using "${PSID_outRaw}/GLM_model_selection.csv", ///
					cells(b(nostar fmt(%8.3f)) se(fmt(2) par)) stats(N aic2 bic2, fmt(%8.0fc %8.2fc %8.2fc)) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5% of the sample size)	///
					replace
					
			esttab	glm_step1_order1	glm_step1_order2	glm_step1_order3	glm_step1_order4	glm_step1_order5	using "${PSID_outRaw}/GLM_model_selection.tex", ///
					cells(b(nostar fmt(%8.3f)) se(fmt(2) par)) stats(N aic2 bic2, fmt(%8.0fc %8.2fc %8.2fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5% of the sample size)	///
					replace
			
		}
		
		
		*	Step 1
		*	Note: we use svy: GLM model which generates robust, design-adjusted standard errors based on primary sampling units only (households can be thought of as secondary sampling units in the panel study.)
		*	In other words, this svy: GLM model does NOT take clustering observations within households. (Reference: page 394, "Applied Survey Data Analysis, 1st edition, (2010), Heeringa, West, Berglund")
		*	The reference above used GLLAMM (Generalized Linear Latent and Mixed Model) which generates (1) fixed effects of covariates and time aspect and (2) random effects of individuals where indviduals records over time are clustered (pg.380)
		*	The book runs both svy: GLM and GLLAMM, and they found both yields very similar inferences. We will use this fininding as an argument for using svy: GLM over GLLAMM
			
		*	If we need to use mixed model to account for correlation wihtin households, then we can use the following command instead. The following model is Mixed-effect Generalized Linear Model (MEGLM)
		*	The following command is written based upon (1) Stata manual (2) 2nd edition of the reference above (Heeringa sent me an excerpt as a word file. Check 2021/6/22 email for the record)
			/*	meglm	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars} [pweight=weight_multi2] if `depvar'>0 || fam_ID_1999: ,	///
				pweight(weight_multi1)	family(gamma)	link(log)	vce(cluster fam_ID_1999)	*/
		
		
		svy, subpop(${study_sample}): glm 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}, family(gamma)	link(log)
		est	sto	glm_step1

		
		*	Predict fitted value and residual
		gen	glm_step1_sample=1	if	e(sample)==1 & `=e(subpop)'	//	We need =`e(subpop)' condition, as e(sample) includes both subpopulation and non-subpopulation.
		predict double mean1_foodexp_glm	if	glm_step1_sample==1
		predict double e1_foodexp_glm	if	glm_step1_sample==1,r
		gen e1_foodexp_sq_glm = (e1_foodexp_glm)^2
	
		
		*	Step 2
		local	depvar	e1_foodexp_sq_glm
		
		svy, subpop(${study_sample}): glm 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	, family(gamma)	link(log)
	
		est store glm_step2
		gen	glm_step2_sample=1	if	e(sample)==1 & `=e(subpop)'
		*svy:	reg `e(depvar)' `e(selected)'
		predict	double	var1_foodexp_glm	if	glm_step2_sample==1	
					
		*	Output
		**	For AER manuscript, we omit asterisk(*) to display significance as AER requires not to use.
		**	If we want to diplay star, renable "star" option inside "cells" and "star(* 0.10 ** 0.05 *** 0.01)"
		
			esttab	glm_step1	glm_step2	using "${PSID_outRaw}/GLM_pooled.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N_sub /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	replace
					
			esttab	glm_step1	glm_step2	using "${PSID_outRaw}/GLM_pooled.tex", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita)		replace		
		
		
		
		*	Step 3
		*	Assume the outcome variable follows the Gamma distribution
		gen alpha1_foodexp_pc_glm	= (mean1_foodexp_glm)^2 / var1_foodexp_glm	//	shape parameter of Gamma (alpha)
		gen beta1_foodexp_pc_glm	= var1_foodexp_glm / mean1_foodexp_glm	//	scale parameter of Gamma (beta)
		
		*	Generate PFS by constructing CDF
		gen PFS_glm = gammaptail(alpha1_foodexp_pc_glm, foodexp_W_thrifty/beta1_foodexp_pc_glm)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
		label	var	PFS_glm "PFS"
		
		
	/****************************************************************
		SECTION 4: Categorize food security status based on PFS	 									
	****************************************************************/		
	*	Categorization	//	Generate FS category variables from the PFS
	local	run_categorization	1	

	*	Categorization	
	if	`run_categorization'==1	{
						
		
			*	Summary Statistics of Indicies
			summ	fs_scale_fam_rescale	PFS_glm		///
					if	inlist(year,2,3,9,10)
			
			*	For food security threshold value, we use the ratio from the annual USDA reports.
			*	(https://www.ers.usda.gov/topics/food-nutrition-assistance/food-security-in-the-us/readings/#reports)
			
			*** One thing we need to be careful is that, we need to match the USDA ratio to the "population ratio(weighted)", NOT the "sample ratio(unweighted)"
			*	To get population ratio, we should use "svy: mean"	or "svy: proportion"
			*	The best way to do is let STATA find them automatically, but for now (2020/10/6) I will find them manually.
				*	One idea I have to do it automatically is to use loop(while) until we get the threshold value matching the USDA ratio.
			*	Due to time constraint, I only found it for 2015 (year=9) for OLS, which is needed to generate validation table.
			
			
			local	prop_FI_1	=	0.101	// 1999: 10.1% are food insecure (7.1% are low food secure, 3.0% are very low food secure)
			local	prop_FI_2	=	0.107	// 2001: 10.7% are food insecure (7.4% are low food secure, 3.3% are very low food secure)
			local	prop_FI_3	=	0.112	// 2003: 11.2% are food insecure (7.7% are low food secure, 3.5% are very low food secure)
			local	prop_FI_4	=	0.110	// 2005: 11.0% are food insecure (7.1% are low food secure, 3.9% are very low food secure)
			local	prop_FI_5	=	0.111	// 2007: 11.1% are food insecure (7.0% are low food secure, 4.1% are very low food secure)
			local	prop_FI_6	=	0.147	// 2009: 14.7% are food insecure (9.0% are low food secure, 5.7% are very low food secure)
			local	prop_FI_7	=	0.149	// 2011: 14.9% are food insecure (9.2% are low food secure, 5.7% are very low food secure)
			local	prop_FI_8	=	0.143	// 2013: 14.3% are food insecure (8.7% are low food secure, 5.6% are very low food secure)
			local	prop_FI_9	=	0.127	// 2015: 12.7% are food insecure (7.7% are low food secure, 5.0% are very low food secure)
			local	prop_FI_10	=	0.118	// 2017: 11.8% are food insecure (7.3% are low food secure, 4.5% are very low food secure)
			
			local	prop_VLFS_1		=	0.030	// 1999: 10.1% are food insecure (7.1% are low food secure, 3.0% are very low food secure)
			local	prop_VLFS_2		=	0.033	// 2001: 10.7% are food insecure (7.4% are low food secure, 3.3% are very low food secure)
			local	prop_VLFS_3		=	0.035	// 2003: 11.2% are food insecure (7.7% are low food secure, 3.5% are very low food secure)
			local	prop_VLFS_4		=	0.039	// 2005: 11.0% are food insecure (7.1% are low food secure, 3.9% are very low food secure)
			local	prop_VLFS_5		=	0.041	// 2007: 11.1% are food insecure (7.0% are low food secure, 4.1% are very low food secure)
			local	prop_VLFS_6		=	0.057	// 2009: 14.7% are food insecure (9.0% are low food secure, 5.7% are very low food secure)
			local	prop_VLFS_7		=	0.057	// 2011: 14.9% are food insecure (9.2% are low food secure, 5.7% are very low food secure)
			local	prop_VLFS_8		=	0.056	// 2013: 14.3% are food insecure (8.7% are low food secure, 5.6% are very low food secure)
			local	prop_VLFS_9		=	0.050	// 2015: 12.7% are food insecure (7.7% are low food secure, 5.0% are very low food secure)
			local	prop_VLFS_10	=	0.045	// 2017: 11.8% are food insecure (7.3% are low food secure, 4.5% are very low food secure)
		
			*	Categorize food security status based on the PFS.
			 quietly	{
				foreach	type	in	glm	/*ls	rf*/	{

						
						gen	PFS_FS_`type'	=	0	if	!mi(PFS_`type')	//	Food secure
						gen	PFS_FI_`type'	=	0	if	!mi(PFS_`type')	//	Food insecure (low food secure and very low food secure)
						gen	PFS_LFS_`type'	=	0	if	!mi(PFS_`type')	//	Low food secure
						gen	PFS_VLFS_`type'	=	0	if	!mi(PFS_`type')	//	Very low food secure
						gen	PFS_cat_`type'	=	0	if	!mi(PFS_`type')	//	Categorical variable: FS, LFS or VLFS
												
						*	Generate a variable for the threshold PFS
						gen	PFS_threshold_`type'=.
						
						foreach	year	in	2	3	4	5	6	7	8	9	10	{
							
							di	"current loop is `plan',  in year `year'"
							xtile pctile_`type'_`year' = PFS_`type' if !mi(PFS_`type')	&	year==`year', nq(1000)
	
							* We use loop to find the threshold value for categorizing households as food (in)secure
							local	counter 	=	1	//	reset counter
							local	ratio_FI	=	0	//	reset FI population ratio
							local	ratio_VLFS	=	0	//	reset VLFS population ratio
							
							foreach	indicator	in	FI	VLFS	{
								
								local	counter 	=	1	//	reset counter
								local	ratio_`indicator'	=	0	//	reset population ratio
							
								* To decrease running time, we first loop by 10 
								while (`counter' < 1000 & `ratio_`indicator''<`prop_`indicator'_`year'') {	//	Loop until population ratio > USDA ratio
									
									qui di	"current indicator is `indicator', counter is `counter'"
									qui	replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,`counter')	//	categorize certain number of households at bottom as FI
									qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'	//	Generate population ratio
									local ratio_`indicator' = _b[PFS_`indicator'_`type']
									
									local counter = `counter' + 10	//	Increase counter by 10
								}

								*	Since we first looped by unit of 10, we now have to find to exact value by looping 1 instead of 10.
								qui di "internediate counter is `counter'"
								local	counter=`counter'-10	//	Adjust the counter, since we added extra 10 at the end of the first loop

								while (`counter' > 1 & `ratio_`indicator''>`prop_`indicator'_`year'') {	//	Loop until population ratio < USDA ratio
									
									qui di "counter is `counter'"
									qui	replace	PFS_`indicator'_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',`counter',1000)
									qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'
									local ratio_`indicator' = _b[PFS_`indicator'_`type']
									
									local counter = `counter' - 1
								}
								qui di "Final counter is `counter'"

								*	Now we finalize the threshold value - whether `counter' or `counter'+1
									
									*	Counter
									local	diff_case1	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')

									*	Counter + 1
									qui	replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,`counter'+1)
									qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'
									local	ratio_`indicator' = _b[PFS_`indicator'_`type']
									local	diff_case2	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')
									qui	di "diff_case2 is `diff_case2'"

									*	Compare two threshold values and choose the one closer to the USDA value
									if	(`diff_case1'<`diff_case2')	{
										global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'
									}
									else	{	
										global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'+1
									}
								
								*	Categorize households based on the finalized threshold value.
								qui	{
									replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,${threshold_`indicator'_`plan'_`type'_`year'})
									replace	PFS_`indicator'_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',${threshold_`indicator'_`plan'_`type'_`year'}+1,1000)		
								}	
								di "thresval of `indicator' in year `year' is ${threshold_`indicator'_`plan'_`type'_`year'}"
							}	//	indicator
							
							*	Food secure households
							replace	PFS_FS_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',1,${threshold_FI_`plan'_`type'_`year'})
							replace	PFS_FS_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',${threshold_FI_`plan'_`type'_`year'}+1,1000)
							
							*	Low food secure households
							replace	PFS_LFS_`type'=1	if	year==`year'	&	PFS_FI_`type'==1	&	PFS_VLFS_`type'==0	//	food insecure but NOT very low food secure households			
							
							*	Categorize households into one of the three values: FS, LFS and VLFS						
							replace	PFS_cat_`type'=1	if	year==`year'	&	PFS_VLFS_`type'==1
							replace	PFS_cat_`type'=2	if	year==`year'	&	PFS_LFS_`type'==1
							replace	PFS_cat_`type'=3	if	year==`year'	&	PFS_FS_`type'==1
							assert	PFS_cat_`type'!=0	if	year==`year'
							
							*	Save threshold PFS as global macros and a variable, the average of the maximum PFS among the food insecure households and the minimum of the food secure households					
							qui	summ	PFS_`type'	if	year==`year'	&	PFS_FS_`type'==1	//	Minimum PFS of FS households
							local	min_FS_PFS	=	r(min)
							qui	summ	PFS_`type'	if	year==`year'	&	PFS_FI_`type'==1	//	Maximum PFS of FI households
							local	max_FI_PFS	=	r(max)
							
							*	Save the threshold PFS
							replace	PFS_threshold_`type'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2		if	year==`year'
							*global	PFS_threshold_`type'_`year'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2
							
							
						}	//	year
						
						label	var	PFS_FI_`type'	"Food Insecurity (PFS) (`type')"
						label	var	PFS_FS_`type'	"Food security (PFS) (`type')"
						label	var	PFS_LFS_`type'	"Low food security (PFS) (`type')"
						label	var	PFS_VLFS_`type'	"Very low food security (PFS) (`type')"
						label	var	PFS_cat_`type'	"PFS category: FS, LFS or VLFS"
						

				}	//	type
				
				lab	define	PFS_category	1	"Very low food security (VLFS)"	2	"Low food security (LFS)"	3	"Food security(FS)"
				lab	value	PFS_cat_*	PFS_category
				
			 }	//	qui
			
			
			*	Graph the PFS threshold for each year
			cap drop templine
			gen templine=0.6
			twoway	(connected PFS_threshold_glm year2 if fam_ID_1999==1, lpattern(dot)	mlabel(PFS_threshold_glm) mlabposition(12) mlabformat(%9.3f))	///
					(line templine year2 if fam_ID_1999==1, lpattern(dash)),	///
					/*title(Probability Threshold for being Food Secure)*/	ytitle(Probability)	xtitle(Year)	xlabel(2001(2)2017) legend(off)	///
					name(PFS_Threshold, replace)	graphregion(color(white)) bgcolor(white)
					
			graph	export	"${PSID_outRaw}/Fig_A1_PFS_Thresholds.png", replace
			graph	close
			
			drop	templine
	
		
	}	//	Categorization			

	
	tempfile	fs_const_long
	save		`fs_const_long'
	
	/*
	*	Save, depending on whether food stamp/SNAP value is included in the food expenditure
	if	`include_stamp'==1	{	//	if included, default
		
		save	"${PSID_dtInt}/PFS_cat_ready_fs.dta", replace
	
	}
	else	{	//	if NOT included.
	    
		save	"${PSID_dtInt}/PFS_cat_ready.dta", replace
	}
	*/
	
		
			
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
			