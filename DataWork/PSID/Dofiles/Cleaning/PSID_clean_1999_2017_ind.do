
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
		psid use || age_head_fam [68]V117 [69]V1008 [99]ER13010 [01]ER17013 [03]ER21017 [05]ER25017 [07]ER36017 [09]ER42017 [11]ER47317 [13]ER53017 [15]ER60017 [17]ER66017	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		tempfile	age_head_fam
		save		`age_head_fam'
		
		*	Race of head (fam)
		psid use || race_head_fam [68]V181 [69]V801 [99]ER15928 [01]ER19989 [03]ER23426 [05]ER27393 [07]ER40565 [09]ER46543 [11]ER51904 [13]ER57659 [15]ER64810 [17]ER70882	///
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
		
		*	Total Family Income (fam)
		psid use || total_income_fam [68]V81 [69]V529 /*[70]V1514 [71]V2226 [72]V2852 [73]V3256 [74]V3676 [75]V4154 [76]V5029 [77]V5626 [78]V6173 [79]V6766 [80]V7412 [81]V8065 [82]V8689 [83]V9375 [84]V11022 [85]V12371 [86]V13623 [87]V14670 [88]V16144 [89]V17533 [90]V18875 [91]V20175 [92]V21481 [93]V23322 [94]ER4153 [95]ER6993 [96]ER9244*/ [97]ER12079 [99]ER16462 [01]ER20456 [03]ER24099 [05]ER28037 [07]ER41027 [09]ER46935 [11]ER52343 [13]ER58152 [15]ER65349 [17]ER71426	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		tempfile	total_income_fam
		save		`total_income_fam'
		
		*	Martial Status of Head (fam)
		psid use || marital_status_fam /*[77]V5502 [78]V6034 [79]V6659 [80]V7261 [81]V7952 [82]V8603 [83]V9276 [84]V10426 [85]V11612 [86]V13017 [87]V14120 [88]V15136 [89]V16637 [90]V18055 [91]V19355 [92]V20657 [93]V22412 [94]ER2014 [95]ER5013 [96]ER7013 [97]ER10016*/ [99]ER13021 [01]ER17024 [03]ER21023 [05]ER25023 [07]ER36023 [09]ER42023 [11]ER47323 [13]ER53023 [15]ER60024 [17]ER66024	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear							
	
		tempfile	marital_status_fam
		save		`marital_status_fam'
		
		
		* # of people in FU (fam)
		psid use || num_FU_fam [68]V115 [69]V549 /*[70]V1238 [71]V1941 [72]V2541 [73]V3094 [74]V3507 [75]V3920 [76]V4435 [77]V5349 [78]V5849 [79]V6461 [80]V7066 [81]V7657 [82]V8351 [83]V8960 [84]V10418 [85]V11605 [86]V13010 [87]V14113 [88]V15129 [89]V16630 [90]V18048 [91]V19348 [92]V20650 [93]V22405 [94]ER2006 [95]ER5005 [96]ER7005*/ [97]ER10008 [99]ER13009 [01]ER17012 [03]ER21016 [05]ER25016 [07]ER36016 [09]ER42016 [11]ER47316 [13]ER53016 [15]ER60016 [17]ER66016	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear			
		
		
		tempfile	num_FU_fam
		save		`num_FU_fam'
		 	
		
		*	# of Children in HH (fam)
		psid use || num_child_fam [68]V398 [69]V550 /*[70]V1242 [71]V1945 [72]V2545 [73]V3098 [74]V3511 [75]V3924 [76]V4439 [77]V5353 [78]V5853 [79]V6465 [80]V7070 [81]V7661 [82]V8355 [83]V8964 [84]V10422 [85]V11609 [86]V13014 [87]V14117 [88]V15133 [89]V16634 [90]V18052 [91]V19352 [92]V20654 [93]V22409 [94]ER2010 [95]ER5009 [96]ER7009 [97]ER10012*/ [99]ER13013 [01]ER17016 [03]ER21020 [05]ER25020 [07]ER36020 [09]ER42020 [11]ER47320 [13]ER53020 [15]ER60021 [17]ER66021	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear			
		
		
		tempfile	num_child_fam
		save		`num_child_fam'
		
		*	Gender of Household Head (fam)
		psid use || gender_head_fam [68]V119 [69]V1010 /*[70]V1240 [71]V1943 [72]V2543 [73]V3096 [74]V3509 [75]V3922 [76]V4437 [77]V5351 [78]V5851 [79]V6463 [80]V7068 [81]V7659 [82]V8353 [83]V8962 [84]V10420 [85]V11607 [86]V13012 [87]V14115 [88]V15131 [89]V16632 [90]V18050 [91]V19350 [92]V20652 [93]V22407 [94]ER2008 [95]ER5007 [96]ER7007 [97]ER10010*/ [99]ER13011 [01]ER17014 [03]ER21018 [05]ER25018 [07]ER36018 [09]ER42018 [11]ER47318 [13]ER53018 [15]ER60018 [17]ER66018	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear			
		
		
		tempfile	gender_head_fam
		save		`gender_head_fam'
		
		*	Grades Househould head completed (fam)
		psid use || edu_years_head_fam /*[75]V4093 [76]V4684 [77]V5608 [78]V6157 [79]V6754 [80]V7387 [81]V8039 [82]V8663 [83]V9349 [84]V10996 [91]V20198 [92]V21504 [93]V23333 [94]ER4158 [95]ER6998 [96]ER9249 [97]ER12222*/ [99]ER16516 [01]ER20457 [03]ER24148 [05]ER28047 [07]ER41037 [09]ER46981 [11]ER52405 [13]ER58223 [15]ER65459 [17]ER71538	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	edu_years_head_fam
		save		`edu_years_head_fam'
		
		*	State of Residence (fam)
		psid use || state_resid_fam [68]V93 [69]V537 /*[70]V1103 [71]V1803 [72]V2403 [73]V3003 [74]V3403 [75]V3803 [76]V4303 [77]V5203 [78]V5703 [79]V6303 [80]V6903 [81]V7503 [82]V8203 [83]V8803 [84]V10003 [85]V11103 [86]V12503 [87]V13703 [88]V14803 [89]V16303 [90]V17703 [91]V19003 [92]V20303 [93]V21603 [94]ER4156 [95]ER6996 [96]ER9247 [97]ER12221*/ [99]ER13004 [01]ER17004 [03]ER21003 [05]ER25003 [07]ER36003 [09]ER42003 [11]ER47303 [13]ER53003 [15]ER60003 [17]ER66003	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	state_resid_fam
		save		`state_resid_fam'
		
		*	Food security score (raw)
		psid use || fs_raw_fam	[99]ER14331S [01]ER18470S [03]ER21735S [15]ER60797 [17]ER66845	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	fs_raw_fam
		save		`fs_raw_fam'
		
		*	Food security score (scale)
		psid use || fs_scale_fam	[99]ER14331T [01]ER18470T [03]ER21735T [15]ER60798 [17]ER66846	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	fs_scale_fam
		save		`fs_scale_fam'
		
		*	Food Security Category (fam)
		psid use || fs_cat_fam	[99]ER14331U [01]ER18470U [03]ER21735U [15]ER60799 [17]ER66847	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	fs_cat_fam
		save		`fs_cat_fam'
		
		*	Food Stamp Usage (2 years ago)
		psid use || food_stamp_used_2yr	[99]ER14240 [01]ER18370 [03]ER21636 [15]ER60718 [17]ER66765	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	food_stamp_used_2yr
		save		`food_stamp_used_2yr'
		
		*	Food Stamp Usage (previous year)
		psid use || food_stamp_used_1yr	[99]ER14255 [01]ER18386 [03]ER21652 [15]ER60719 [17]ER66766	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	food_stamp_used_1yr
		save		`food_stamp_used_1yr'
		
		*	Child received free or reduced cost meal (lunch)
		psid use || child_lunch_assist	[99]ER16418 [01]ER20364 [03]ER24069	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	child_lunch_assist_fam
		save		`child_lunch_assist_fam'
		
		*	Child received free or reduced cost meal (breakfast)
		psid use || child_bf_assist	[99]ER16419 [01]ER20365 [03]ER24070	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	child_bf_assist_fam
		save		`child_bf_assist_fam'
		
		*	Child received free or reduced cost meal (breakfast and/or lunch)
		psid use || child_meal_assist	[15]ER60695 [17]ER66742	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	child_meal_assist_fam
		save		`child_meal_assist_fam'
		
		*	WIC received last years
		psid use || WIC_received_last	[99]ER16421 [01]ER20367 [03]ER24072 [15]ER60715 [17]ER66762	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	WIC_received_last
		save		`WIC_received_last'
		
		*	Family composition change
		psid use || family_comp_change	[99]ER13008A [01]ER17007 [03]ER21007 [15]ER60007 [17]ER66007	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	family_comp_change
		save		`family_comp_change'
		
		*	Total food expenditure
		psid use || food_exp_total	[99]ER16515A1 [01]ER20456A1 [03]ER24138A1 /*[05]ER28037A1 [07]ER41027A1 [09]ER46971A1 [11]ER52395A1*/ [13]ER58212A1 [15]ER65410 [17]ER71487	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	food_exp_total
		save		`food_exp_total'
		
		*	Height of the respondent (feet part)
		psid use || height_feet	[99]ER15553 [01]ER19718 [03]ER23133 /*[05]ER27110 [07]ER38321 [09]ER44294 [11]ER49633 [13]ER55381*/ [15]ER62503 [17]ER68568	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	height_feet
		save		`height_feet'
		
		*	Height of the respondent (inch part)
		psid use || height_inch	[99]ER15554 [01]ER19719 [03]ER23134 /*[05]ER27111 [07]ER38322 [09]ER44295 [11]ER49634 [13]ER55382*/ [15]ER62504 [17]ER68569	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	height_inch
		save		`height_inch'
		
		*	Height of the respondent (meters)
		psid use || height_meter	/*[11]ER49635 [13]ER55383*/ [15]ER62505 [17]ER68570	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	height_meter
		save		`height_meter'
		
		*	Weight of the respondent (lbs)
		psid use || weight_lbs	[99]ER15552 [01]ER19717 [03]ER23132 /*[05]ER27109 [07]ER38320 [09]ER44293 [11]ER49631 [13]ER55379*/ [15]ER62501 [17]ER68566	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	weight_lbs
		save		`weight_lbs'
		
		*	Weight of the respondent (kg)
		psid use || weight_kg	/*[11]ER49632 [13]ER55380*/ [15]ER62502 [17]ER68567	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	weight_kg
		save		`weight_kg'
		
		*	Finished high school or GED
		psid use || hs_completed	[99]ER15937 [01]ER19998 [03]ER23435 /*[05]ER27402 [07]ER40574 [09]ER46552 [11]ER51913 [13]ER57669*/ [15]ER64821 [17]ER70893	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	hs_completed
		save		`hs_completed'
		
		*	Finished college
		psid use || college_completed	[99]ER15952 [01]ER20013 [03]ER23450 /*[05]ER27417 [07]ER40589 [09]ER46567 [11]ER51928 [13]ER57684*/ [15]ER64836 [17]ER70908	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	college_completed
		save		`college_completed'
		
		
		
	*	Merge individual cross-wave with family cross-wave
	use	`weight_long_ind', clear
	merge 1:1 x11101ll using `weight_cross_ind', keepusing(weight_cross_ind*) nogen assert(3)
	merge 1:1 x11101ll using `weight_long_fam', keepusing(weight_long_fam*) nogen assert(3)
	merge 1:1 x11101ll using `respondent_ind', keepusing(respondent*) nogen assert(3)
	merge 1:1 x11101ll using `relat_to_head_ind', keepusing(relat_to_head*) nogen assert(3)
	merge 1:1 x11101ll using `main_age_ind', keepusing(age_ind*) nogen assert(3)
	merge 1:1 x11101ll using `edu_years_ind', keepusing(edu_years*) nogen assert(3)
	merge 1:1 x11101ll using `age_head_fam', keepusing(age_head*) nogen assert(3)
	merge 1:1 x11101ll using `race_head_fam', keepusing(race_head_fam*) nogen assert(3)
	merge 1:1 x11101ll using `splitoff_indicator_fam', keepusing(splitoff_indicator*) nogen assert(3)
	merge 1:1 x11101ll using `num_splitoff_fam', keepusing(num_split_fam*) nogen assert(3)
	merge 1:1 x11101ll using `main_fam_ID', keepusing(main_fam_ID*) nogen assert(3)
	merge 1:1 x11101ll using `weight_long_ind', keepusing(weight_long_ind*) nogen assert(3)
	merge 1:1 x11101ll using `weight_cross_ind', keepusing(weight_cross_ind*) nogen assert(3)
	merge 1:1 x11101ll using `weight_long_fam', keepusing(weight_long_fam*) nogen assert(3)
	merge 1:1 x11101ll using `total_income_fam', keepusing(total_income_fam*) nogen assert(3)
	merge 1:1 x11101ll using `marital_status_fam', keepusing(marital_status_fam*) nogen assert(3)
	merge 1:1 x11101ll using `num_FU_fam', keepusing(num_FU_fam*) nogen assert(3)
	merge 1:1 x11101ll using `num_child_fam', keepusing(num_child_fam*) nogen assert(3)
	merge 1:1 x11101ll using `gender_head_fam', keepusing(gender_head_fam*) nogen assert(3)
	merge 1:1 x11101ll using `edu_years_head_fam', keepusing(edu_years_head_fam*) nogen assert(3)
	merge 1:1 x11101ll using `state_resid_fam', keepusing(state_resid_fam*) nogen assert(3)
	merge 1:1 x11101ll using `fs_raw_fam', keepusing(fs_raw_fam*) nogen assert(3)
	merge 1:1 x11101ll using `fs_scale_fam', keepusing(fs_scale_fam*) nogen assert(3)
	merge 1:1 x11101ll using `fs_cat_fam', keepusing(fs_cat_fam*) nogen assert(3)
	merge 1:1 x11101ll using `food_stamp_used_2yr', keepusing(food_stamp_used_2yr*) nogen assert(3)
	merge 1:1 x11101ll using `food_stamp_used_1yr', keepusing(food_stamp_used_1yr*) nogen assert(3)
	merge 1:1 x11101ll using `child_bf_assist_fam', keepusing(child_bf_assist*) nogen assert(3)
	merge 1:1 x11101ll using `child_lunch_assist_fam', keepusing(child_lunch_assist*) nogen assert(3)
	merge 1:1 x11101ll using `child_meal_assist_fam', keepusing(child_meal_assist*) nogen assert(3)
	merge 1:1 x11101ll using `WIC_received_last', keepusing(WIC_received_last*) nogen assert(3)
	merge 1:1 x11101ll using `family_comp_change', keepusing(family_comp_change*) nogen assert(3)
	merge 1:1 x11101ll using `food_exp_total', keepusing(food_exp_total*) nogen assert(3)
	merge 1:1 x11101ll using `height_feet', keepusing(height_feet*) nogen assert(3)
	merge 1:1 x11101ll using `height_inch', keepusing(height_inch*) nogen assert(3)
	merge 1:1 x11101ll using `height_meter', keepusing(height_meter*) nogen assert(3)
	merge 1:1 x11101ll using `weight_lbs', keepusing(weight_lbs*) nogen assert(3)
	merge 1:1 x11101ll using `weight_kg', keepusing(weight_kg*) nogen assert(3)
	merge 1:1 x11101ll using `hs_completed', keepusing(hs_completed*) nogen assert(3)
	merge 1:1 x11101ll using `college_completed', keepusing(college_completed*) nogen assert(3)
	
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
			
		*	Age of Household Head
		replace	age_head_fam1968	=	.d	if	age_head_fam1968==98
		replace	age_head_fam1968	=	.n	if	age_head_fam1968==99
		replace	age_head_fam1969	=	.n	if	age_head_fam1969==99
				
		qui	ds	age_head_fam1999-age_head_fam2017
		foreach	var in `r(varlist)'	{
			replace	`var'=.	if	`var'==999
		}
		
		*	Marital status of head
		qui ds marital_status_fam1999-marital_status_fam2017
		foreach	var in `r(varlist)'	{
			replace	`var'=.d	if	`var'==8
			replace	`var'=.n	if	`var'==9
		}
		
		*	Grade completed of household head (fam)
		qui ds edu_years_head_fam1999-edu_years_head_fam2017
		foreach	var	in	`r(varlist)'	{
			replace	`var'=.n	if	`var'==99
		}
		
		*	Food Stamp & WIC
		qui ds	food_stamp_used_2yr1999-food_stamp_used_1yr2017 WIC_received_last1999-WIC_received_last2017
		foreach	var	in	`r(varlist)'	{
			replace	`var'=.d	if	`var'==8
			replace	`var'=.r	if	`var'==9
			replace	`var'=.n	if	`var'==0
			replace	`var'=0		if	`var'==5
		}
		*	Location
		
			*	State of Residence
				label define	statecode	0	"Inap.: U.S. territory or foreign country"	99	"D.K; N.A"	///
											1	"Alabama"		2	"Arizona"			3	"Arkansas"	///
											4	"California"	5	"Colorado"			6	"Connecticut"	///
											7	"Delaware"		8	"D.C."				9	"Florida"	///
											10	"Georgia"		11	"Idaho"				12	"Illinois"	///
											13	"Indiana"		14	"Iowa"				15	"Kansas"	///
											16	"Kentucky"		17	"Lousiana"			18	"Maine"		///
											19	"Maryland"		20	"Massachusetts"		21	"Michigan"	///
											22	"Minnesota"		23	"Mississippi"		24	"Missouri"	///
											25	"Montana"		26	"Nebraska"			27	"Nevada"	///
											28	"New Hampshire"	29	"New Jersey"		30	"New Mexico"	///
											31	"New York"		32	"North Carolina"	33	"North Dakota"	///
											34	"Ohio"			35	"Oklahoma"			36	"Oregon"	///
											37	"Pennsylvania"	38	"Rhode Island"		39	"South Carolina"	///
											40	"South Dakota"	41	"Tennessee"			42	"Texas"	///
											43	"Utah"			44	"Vermont"			45	"Virginia"	///
											46	"Washington"	47	"West Virginia"		48	"Wisconsin"	///
											49	"Wyoming"		50	"Alaska"			51	"Hawaii"
				lab	val	state_resid_fam* statecode
			
		*	Race
			
			*	1999-2003
			label	define	race_99_03	1 	"White"	///
										2	"Black"	///
										3	"American Indian, Aleut, Eskimo"	///
										4	"Asian, Pacific Islander"	///
										5	"Latino origin or descent"	///
										6	"Color other than black or white"	///
										7	"Other"	///
										8	"DK"	///
										9	"NA; refused"	///
										0 	"Inap.: no wife in FU"
			label	val	race_head_fam1999 race_head_fam2001 race_head_fam2003	race_99_03
			
			*	2015-2017
			label	define	race_15_17	1 	"White"	///
										2	"Black, African-American or Negro"	///
										3	"American Indian or Alaska Native"	///
										4	"Asian"	///
										5	"Native Hawaiian or Pacific Islander"	///
										7	"Other"	///
										9	"DK; NA; refused"	///
										0 	"Inap.: no wife in FU"
			label	val	race_head_fam2015 race_head_fam2017 race_15_17
			
		*	Marital	Status
			label	define	marital_status	1	"Married"	///
											2	"Never married"	///
											3	"Widowed"	///
											4 	"Divorced, annulled"	///
											5	"Separated"	///
											8	"DK"	///
											9	"NA; refused"
			label values	marital_status*	marital_status	
		
		*	Food Security
		label	define	fs_cat	1	"High Food Security"	///
								2	"Marginal Food Security"	///
								3	"Low Food Security"	///
								4 	"Very Low Food Security"
		label values	fs_cat_fam*	fs_cat	

		
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

		
// Grades complete (head):  	[75]V4093 [76]V4684 [77]V5608 [78]V6157 [79]V6754 [80]V7387 [81]V8039 [82]V8663 [83]V9349 [84]V10996 [91]V20198 [92]V21504 [93]V23333 [94]ER4158 [95]ER6998 [96]ER9249 [97]ER12222 [99]ER16516 [01]ER20457 [03]ER24148 [05]ER28047 [07]ER41037 [09]ER46981 [11]ER52405 [13]ER58223 [15]ER65459 [17]ER71538