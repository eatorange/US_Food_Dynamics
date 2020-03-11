
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_clean_1999_2017_ind
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Feb 24, 2020, by Seungmin Lee (slee31@worldbank.org)
	
	IDS VAR:    	ER13002         // 1999 Family ID

	DESCRIPTION: 	Clean (& construct) individual-level data from 1999 to 2017
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Retrieve variables on interest and construct a panel data
					2 - Clean variable labels and values
					X - Save and Exit
					
	INPUTS: 		* PSID Individual & family raw data
					${PSID_dtRaw}/Main
										
	OUTPUTS: 		* PSID panel data (individual)
										
					* PSID 1999 Constructed (individual)
					${PSID_dtInt}/PSID_clean_1999_2017_ind.dta
					

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
	loc	name_do	PSID_clean_1999_2017_ind
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doCln}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1: Retrieve variables on interest and construct a panel data
	****************************************************************/	
	
	*	Construct from existing PSID
	*	I found that "psid add" has a critical problem; when using "psid add" command, it imports the values of only strongly balanced observation. In other words, if an observation has a missing interview in any of the wave, that observation gets missing values for ALL the waves.
	*	Therefore, I will us "psid use" command only for each variable and merge them. This takes more time and requires more work than using "psid add", but still takes much less time than manual cleaning
	
	* Import relevant variables using "psidtools" command	
				
		*	Survey Weights
		
			*	Longitudinal, individual-level
			psid use || weight_long_ind [68]ER30019 [69]ER30042 [70]ER30066 [71]ER30090 [72]ER30116 [73]ER30137 [74]ER30159 [75]ER30187 [76]ER30216 [77]ER30245 [78]ER30282 [79]ER30312 [80]ER30342 [81]ER30372 [82]ER30398 [83]ER30428 [84]ER30462 [85]ER30497 [86]ER30534 [87]ER30569 [88]ER30605 [89]ER30641 [90]ER30686 [91]ER30730 [92]ER30803	[93]ER30864 [94]ER33119 [95]ER33275 [96]ER33318	[97]ER33430	[99]ER33546 [01]ER33637 [03]ER33740 [05]ER33848 [07]ER33950 [09]ER34045 [11]ER34154 [13]ER34268 [15]ER34413 [17]ER34650	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear	
			
			tempfile	weight_long_ind
			save		`weight_long_ind'
			
			*	Cross-sectional, individual-level
			psid use || weight_cross_ind [99]ER33547 [01]ER33639 [03]ER33742 [05]ER33849 [07]ER33951 [09]ER34046 [11]ER34155 [13]ER34269 [15]ER34414 [17]ER34651	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear	
			
			tempfile	weight_cross_ind
			save		`weight_cross_ind'
			
			*	Longitudinal, family-level
			psid use || weight_long_fam [99]ER16518 [01]ER20394 [03]ER24179 [05]ER28078 [07]ER41069 [09]ER47012 [11]ER52436 [13]ER58257 [15]ER65492 [17]ER71570	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear	
			
			tempfile	weight_long_fam
			save		`weight_long_fam'
		
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
		
		*	Age (indiv)
		psid use || age_ind [68]ER30004 [69]ER30023 [70]ER30046 [71]ER30070 [72]ER30094 [73]ER30120 [74]ER30141 [75]ER30163 [76]ER30191 [77]ER30220 [78]ER30249 [79]ER30286 [80]ER30316 [81]ER30346 [82]ER30376 [83]ER30402 [84]ER30432 [85]ER30466 [86]ER30501 [87]ER30538 [88]ER30573 [89]ER30609 [90]ER30645 [91]ER30692 [92]ER30736 [93]ER30809 [94]ER33104 [95]ER33204 [96]ER33304 [97]ER33404 [99]ER33504 [01]ER33604 [03]ER33704 [05]ER33804 [07]ER33904 [09]ER34004 [11]ER34104 [13]ER34204 [15]ER34305 [17]ER34504	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
		
		qui ds age_ind*
		foreach var in `r(varlist)'	{
			replace	`var'=.d	if	inlist(`var',999)
			replace	`var'=.n	if	inlist(`var',0)
		}
		
		tempfile	main_age_ind
		save		`main_age_ind'
		
		*	Years of education (indiv)
		psid use || edu_years [68]ER30010 [70]ER30052 [71]ER30076 [72]ER30100 [73]ER30126 [74]ER30147 [75]ER30169 [76]ER30197 [77]ER30226 [78]ER30255 [79]ER30296 [80]ER30326 [81]ER30356 [82]ER30384 [83]ER30413 [84]ER30443 [85]ER30478 [86]ER30513 [87]ER30549 [88]ER30584 [89]ER30620 [90]ER30657 [91]ER30703 [92]ER30748 [93]ER30820 [94]ER33115 [95]ER33215 [96]ER33315 [97]ER33415 [99]ER33516 [01]ER33616 [03]ER33716 [05]ER33817 [07]ER33917 [09]ER34020 [11]ER34119 [13]ER34230 [15]ER34349 [17]ER34548	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		qui ds edu_years*
		foreach var in `r(varlist)'	{
			replace	`var'=.d	if	`var'==98
			replace	`var'=.n	if	inlist(`var',0,99)
		}
		
		
		tempfile	edu_years_ind
		save		`edu_years_ind'
		
		*	Age of head (fam)
		psid use || age_head [68]V117 [69]V1008 [99]ER13010 [01]ER17013 [03]ER21017 [05]ER25017 [07]ER36017 [09]ER42017 [11]ER47317 [13]ER53017 [15]ER60017 [17]ER66017	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		tempfile	age_head_fam
		save		`age_head_fam'
		
		*	Race of head (fam)
		psid use || race_head [68]V181 [69]V801 [99]ER15928 [01]ER19989 [03]ER23426 [05]ER27393 [07]ER40565 [09]ER46543 [11]ER51904 [13]ER57659 [15]ER64810 [17]ER70882	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		tempfile	race_head_fam
		save		`race_head_fam'
		
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
	use	`weight_long_ind', clear
	merge 1:1 x11101ll using `weight_cross_ind', keepusing(weight_cross_ind*) nogen assert(3)
	merge 1:1 x11101ll using `weight_long_fam', keepusing(weight_long_fam*) nogen assert(3)
	merge 1:1 x11101ll using `respondent_ind', keepusing(respondent*) nogen assert(3)
	merge 1:1 x11101ll using `relat_to_head_ind', keepusing(relat_to_head*) nogen assert(3)
	merge 1:1 x11101ll using `main_age_ind', keepusing(age_ind*) nogen assert(3)
	merge 1:1 x11101ll using `edu_years_ind', keepusing(edu_years*) nogen assert(3)
	merge 1:1 x11101ll using `age_head_fam', keepusing(age_head*) nogen assert(3)
	merge 1:1 x11101ll using `race_head_fam', keepusing(race_head*) nogen assert(3)
	merge 1:1 x11101ll using `splitoff_indicator_fam', keepusing(splitoff_indicator*) nogen assert(3)
	merge 1:1 x11101ll using `num_splitoff_fam', keepusing(num_split_fam*) nogen assert(3)
	merge 1:1 x11101ll using `main_fam_ID', keepusing(main_fam_ID*) nogen assert(3)
	merge 1:1 x11101ll using `weight_long_ind', keepusing(weight_long_ind*) nogen assert(3)
	merge 1:1 x11101ll using `weight_cross_ind', keepusing(weight_cross_ind*) nogen assert(3)
	merge 1:1 x11101ll using `weight_long_fam', keepusing(weight_long_fam*) nogen assert(3)
	

	
	/****************************************************************
		SECTION 2: Clean variable labels and values
	****************************************************************/	
		
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
			

	/****************************************************************
		SECTION X: Save and Exit
	****************************************************************/
	
	
	* Make dta
		
		*	Individual data
		notes	drop _dta
		notes:	PSID_clean_1999_2017_ind / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID individual data from 1999 to 2017
		*notes:	Only individuals appear in all waves are included.
		

		* Git branch info
		stgit9 
		notes : PSID_clean_1999_2017_ind / Git branch `r(branch)'; commit `r(sha)'.
	
	
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
		save	"${PSID_dtInt}/PSID_clean_1999_2017_ind.dta", replace
	
	/*
		* Save log
		cap file		close _all
		cap log			close
		copy			"${bl_do_cleaning}/logs/`name_do'.smcl" ///
						"${bl_do_cleaning}/logs/archive/`name_do' - `c(current_date)' - `c(username)'.smcl", replace
		*/
	
	* Exit	
	exit
			
			
			/*							
// Respondent: [99]ER33511 [01]ER33611 [03]ER33711 [05]ER33811 [07]ER33911 [09]ER34011 [11]ER34111 [13]ER34211 [15]ER34312 [17]ER34511

// Sequence Num: [99]ER33502 [01]ER33602 [03]ER33702 [05]ER33802 [07]ER33902 [09]ER34002 [11]ER34102 [13]ER34202 [15]ER34302 [17]ER34502

// Relation to head:  	[68]ER30003 [69]ER30022 [70]ER30045 [71]ER30069 [72]ER30093 [73]ER30119 [74]ER30140 [75]ER30162 [76]ER30190 [77]ER30219 [78]ER30248 [79]ER30285 [80]ER30315 [81]ER30345 [82]ER30375 [83]ER30401 [84]ER30431 [85]ER30465 [86]ER30500 [87]ER30537 [88]ER30572 [89]ER30608 [90]ER30644 [91]ER30691 [92]ER30735 [93]ER30808 [94]ER33103 [95]ER33203 [96]ER33303 [97]ER33403 [99]ER33503 [01]ER33603 [03]ER33703 [05]ER33803 [07]ER33903 [09]ER34003 [11]ER34103 [13]ER34203 [15]ER34303 [17]ER34503
	
// Split-off indicator (family):  	[69]V909 [70]V1106 [71]V1806 [72]V2407 [73]V3007 [74]V3407 [75]V3807 [76]V4307 [77]V5207 [78]V5707 [79]V6307 [80]V6907 [81]V7507 [82]V8207 [83]V8807 [84]V10007 [85]V11107 [86]V12507 [87]V13707 [88]V14807 [89]V16307 [90]V17707 [91]V19007 [92]V20307 [93]V21606 [94]ER2005F [95]ER5005F [96]ER7005F [97]ER10005F [99]ER13005E [01]ER17006 [03]ER21005 [05]ER25005 [07]ER36005 [09]ER42005 [11]ER47305 [13]ER53005 [15]ER60005 [17]ER66005	

// Number of splitoff interviews; [99]ER16433 [01]ER20379 [03]ER24156 [05]ER28055 [07]ER41045 [09]ER46989 [11]ER52413 [13]ER58231 [15]ER65467 [17]ER71546

// Main family ID for this splitoff: [99]ER16434 [01]ER20380 [03]ER24157 [05]ER28056 [07]ER41046 [09]ER46990 [11]ER52414 [13]ER58232 [15]ER65468 [17]ER71547

// Age: [68]ER30004 [69]ER30023 [70]ER30046 [71]ER30070 [72]ER30094 [73]ER30120 [74]ER30141 [75]ER30163 [76]ER30191 [77]ER30220 [78]ER30249 [79]ER30286 [80]ER30316 [81]ER30346 [82]ER30376 [83]ER30402 [84]ER30432 [85]ER30466 [86]ER30501 [87]ER30538 [88]ER30573 [89]ER30609 [90]ER30645 [91]ER30692 [92]ER30736 [93]ER30809 [94]ER33104 [95]ER33204 [96]ER33304 [97]ER33404 [99]ER33504 [01]ER33604 [03]ER33704 [05]ER33804 [07]ER33904 [09]ER34004 [11]ER34104 [13]ER34204 [15]ER34305 [17]ER34504

// Years of education: [68]ER30010 [70]ER30052 [71]ER30076 [72]ER30100 [73]ER30126 [74]ER30147 [75]ER30169 [76]ER30197 [77]ER30226 [78]ER30255 [79]ER30296 [80]ER30326 [81]ER30356 [82]ER30384 [83]ER30413 [84]ER30443 [85]ER30478 [86]ER30513 [87]ER30549 [88]ER30584 [89]ER30620 [90]ER30657 [91]ER30703 [92]ER30748 [93]ER30820 [94]ER33115 [95]ER33215 [96]ER33315 [97]ER33415 [99]ER33516 [01]ER33616 [03]ER33716 [05]ER33817 [07]ER33917 [09]ER34020 [11]ER34119 [13]ER34230 [15]ER34349 [17]ER34548

// Age of head: [68]V117 [69]V1008 [70]V1239 [71]V1942 [72]V2542 [73]V3095 [74]V3508 [75]V3921 [76]V4436 [77]V5350 [78]V5850 [79]V6462 [80]V7067 [81]V7658 [82]V8352 [83]V8961 [84]V10419 [85]V11606 [86]V13011 [87]V14114 [88]V15130 [89]V16631 [90]V18049 [91]V19349 [92]V20651 [93]V22406 [94]ER2007 [95]ER5006 [96]ER7006 [97]ER10009 [99]ER13010 [01]ER17013 [03]ER21017 [05]ER25017 [07]ER36017 [09]ER42017 [11]ER47317 [13]ER53017 [15]ER60017 [17]ER66017

// Race of head:  	[68]V181 [69]V801 [70]V1490 [71]V2202 [72]V2828 [73]V3300 [74]V3720 [75]V4204 [76]V5096 [77]V5662 [78]V6209 [79]V6802 [80]V7447 [81]V8099 [82]V8723 [83]V9408 [84]V11055 [85]V11938 [86]V13565 [87]V14612 [88]V16086 [89]V17483 [90]V18814 [91]V20114 [92]V21420 [93]V23276 [94]ER3944 [95]ER6814 [96]ER9060 [97]ER11848 [99]ER15928 [01]ER19989 [03]ER23426 [05]ER27393 [07]ER40565 [09]ER46543 [11]ER51904 [13]ER57659 [15]ER64810 [17]ER70882

		