
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
	
	*	Construct from existing PSID
	*	I found that "psid add" has a critical problem; when using "psid add" command, it imports the values of only strongly balanced observation. In other words, if an observation has a missing interview in any of the wave, that observation gets missing values for ALL the waves.
	*	Therefore, I will us "psid use" command only for each variable and merge them. This takes much more time than using "psid add", but still takes much less time than manual cleaning
	
	* Import relevant variables using "psidtools" command
			
		*	Respondent (ind)
		psid use || respondent	[99]ER33511 [01]ER33611 [03]ER33711 [05]ER33811 [07]ER33911 [09]ER34011 [11]ER34111 [13]ER34211 [15]ER34312 [17]ER34511	///
							using "${PSID_dtRaw}/Main", design(any) clear
		tempfile	respondent_ind
		save		`respondent_ind'
							
		*	Relation to head (ind)
		psid use || relat_to_head [99]ER33503 [01]ER33603 [03]ER33703 [05]ER33803 [07]ER33903 [09]ER34003 [11]ER34103 [13]ER34203 [15]ER34303 [17]ER34503	///
							using "${PSID_dtRaw}/Main", design(any) clear
							
		tempfile relat_to_head_ind
		save	`relat_to_head_ind'

		*	Splitoff indicator (fam)
		psid use || splitoff_indicator [99]ER13005E [01]ER17006 [03]ER21005 [05]ER25005 [07]ER36005 [09]ER42005 [11]ER47305 [13]ER53005 [15]ER60005 [17]ER66005	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		tempfile	splitoff_indicator_fam
		save		`splitoff_indicator_fam'
		
		*	# of splitoff family from this family (fam)
		psid use || num_split_fam [99]ER16433 [01]ER20379 [03]ER24156 [05]ER28055 [07]ER41045 [09]ER46989 [11]ER52413 [13]ER58231 [15]ER65467 [17]ER71546	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		tempfile	num_splitoff_fam
		save		`num_splitoff_fam'
		
		*	Main family ID for this splitoff (fam)
		psid use || main_fam_ID [99]ER16434 [01]ER20380 [03]ER24157 [05]ER28056 [07]ER41046 [09]ER46990 [11]ER52414 [13]ER58232 [15]ER65468 [17]ER71547	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		tempfile	main_fam_ID
		save		`main_fam_ID'
		
		
		
	*	Merge individual cross-wave with family cross-wave
	use	`respondent_ind', clear
	merge 1:1 x11101ll using `relat_to_head_ind', keepusing(relat_to_head*) nogen assert(3)
	merge 1:1 x11101ll using `splitoff_indicator_fam', keepusing(splitoff_indicator*) nogen assert(3)
	merge 1:1 x11101ll using `num_splitoff_fam', keepusing(num_split_fam*) nogen assert(3)
	merge 1:1 x11101ll using `main_fam_ID', keepusing(main_fam_ID*) nogen assert(3)
	
	*	Clean
	
		*	Define variable labels for multiple variables
			label	define	yesno	1	"Yes"	0	"No"
		
			label	define	splitoff_indicator	1	"Reinterview family"	///
												2	"Split-off from reinterview family"	///
												3	"Recontact family"	///
												4	"Split-off from recontact family"	///
												5	"New 2017 Immigrants"
		*	Assign value labels
		local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017

			*	Respondent
			foreach year of local years	{
				
				*	Respondent
				replace	respondent`year'	=.n	if	respondent`year'==0
				replace	respondent`year'	=0	if	respondent`year'==5
				
			}
		
			label values	respondent*	yesno
			
			*	Other variables
			label values	splitoff_indicator*	splitoff_indicator
			
					
	*	Construct
		
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
				
		tempfile	tracking_const_ind
		save		`tracking_const_ind'
		
		
	
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
// Respondent: [99]ER33511 [01]ER33611 [03]ER33711 [05]ER33811 [07]ER33911 [09]ER34011 [11]ER34111 [13]ER34211 [15]ER34312 [17]ER34511

// Sequence Num: [99]ER33502 [01]ER33602 [03]ER33702 [05]ER33802 [07]ER33902 [09]ER34002 [11]ER34102 [13]ER34202 [15]ER34302 [17]ER34502

// Relation to head:  	[68]ER30003 [69]ER30022 [70]ER30045 [71]ER30069 [72]ER30093 [73]ER30119 [74]ER30140 [75]ER30162 [76]ER30190 [77]ER30219 [78]ER30248 [79]ER30285 [80]ER30315 [81]ER30345 [82]ER30375 [83]ER30401 [84]ER30431 [85]ER30465 [86]ER30500 [87]ER30537 [88]ER30572 [89]ER30608 [90]ER30644 [91]ER30691 [92]ER30735 [93]ER30808 [94]ER33103 [95]ER33203 [96]ER33303 [97]ER33403 [99]ER33503 [01]ER33603 [03]ER33703 [05]ER33803 [07]ER33903 [09]ER34003 [11]ER34103 [13]ER34203 [15]ER34303 [17]ER34503
	
// Split-off indicator (family):  	[69]V909 [70]V1106 [71]V1806 [72]V2407 [73]V3007 [74]V3407 [75]V3807 [76]V4307 [77]V5207 [78]V5707 [79]V6307 [80]V6907 [81]V7507 [82]V8207 [83]V8807 [84]V10007 [85]V11107 [86]V12507 [87]V13707 [88]V14807 [89]V16307 [90]V17707 [91]V19007 [92]V20307 [93]V21606 [94]ER2005F [95]ER5005F [96]ER7005F [97]ER10005F [99]ER13005E [01]ER17006 [03]ER21005 [05]ER25005 [07]ER36005 [09]ER42005 [11]ER47305 [13]ER53005 [15]ER60005 [17]ER66005	

// Number of splitoff interviews; [99]ER16433 [01]ER20379 [03]ER24156 [05]ER28055 [07]ER41045 [09]ER46989 [11]ER52413 [13]ER58231 [15]ER65467 [17]ER71546

// Main family ID for this splitoff: [99]ER16434 [01]ER20380 [03]ER24157 [05]ER28056 [07]ER41046 [09]ER46990 [11]ER52414 [13]ER58232 [15]ER65468 [17]ER71547


		
		
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
			