
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
	
	local	retrieve_vars	1
	local	clean_vars		1
	
	
	*	Construct from existing PSID
	*	I found that "psid add" has a critical problem; when using "psid add" command, it imports the values of only strongly balanced observation. In other words, if an observation has a missing interview in any of the wave, that observation gets missing values for ALL the waves.
	*	Therefore, I will use "psid use" command only for each variable and merge them. This takes more time and requires more work than using "psid add", but still takes much less time than manual cleaning
	
	if	`retrieve_vars==1'	{
	
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
			psid use || num_child_fam [68]V398 [69]V550 /*[70]V1242 [71]V1945 [72]V2545 [73]V3098 [74]V3511 [75]V3924 [76]V4439 [77]V5353 [78]V5853 [79]V6465 [80]V7070 [81]V7661 [82]V8355 [83]V8964 [84]V10422 [85]V11609 [86]V13014 [87]V14117 [88]V15133 [89]V16634 [90]V18052 [91]V19352 [92]V20654 [93]V22409 [94]ER2010 [95]ER5009 [96]ER7009*/ [97]ER10012 [99]ER13013 [01]ER17016 [03]ER21020 [05]ER25020 [07]ER36020 [09]ER42020 [11]ER47320 [13]ER53020 [15]ER60021 [17]ER66021	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear			
			
			
			tempfile	num_child_fam
			save		`num_child_fam'
			
			*	Gender of Household Head (fam)
			psid use || gender_head_fam [68]V119 [69]V1010 /*[70]V1240 [71]V1943 [72]V2543 [73]V3096 [74]V3509 [75]V3922 [76]V4437 [77]V5351 [78]V5851 [79]V6463 [80]V7068 [81]V7659 [82]V8353 [83]V8962 [84]V10420 [85]V11607 [86]V13012 [87]V14115 [88]V15131 [89]V16632 [90]V18050 [91]V19350 [92]V20652 [93]V22407 [94]ER2008 [95]ER5007 [96]ER7007 [97]ER10010*/ [99]ER13011 [01]ER17014 [03]ER21018 [05]ER25018 [07]ER36018 [09]ER42018 [11]ER47318 [13]ER53018 [15]ER60018 [17]ER66018	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear			
			
			
			tempfile	gender_head_fam
			save		`gender_head_fam'
			
			*	Grades Househould head completed (fam)
			psid use || grade_comp_head_fam /*[75]V4093 [76]V4684 [77]V5608 [78]V6157 [79]V6754 [80]V7387 [81]V8039 [82]V8663 [83]V9349 [84]V10996 [91]V20198 [92]V21504 [93]V23333 [94]ER4158 [95]ER6998 [96]ER9249 [97]ER12222*/ [99]ER16516 [01]ER20457 [03]ER24148 [05]ER28047 [07]ER41037 [09]ER46981 [11]ER52405 [13]ER58223 [15]ER65459 [17]ER71538	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	grade_comp_head_fam
			save		`grade_comp_head_fam'
			
			*	State of Residence (fam)
			psid use || state_resid_fam [68]V93 [69]V537 /*[70]V1103 [71]V1803 [72]V2403 [73]V3003 [74]V3403 [75]V3803 [76]V4303 [77]V5203 [78]V5703 [79]V6303 [80]V6903 [81]V7503 [82]V8203 [83]V8803 [84]V10003 [85]V11103 [86]V12503 [87]V13703 [88]V14803 [89]V16303 [90]V17703 [91]V19003 [92]V20303 [93]V21603 [94]ER4156 [95]ER6996 [96]ER9247*/ [97]ER12221 [99]ER13004 [01]ER17004 [03]ER21003 [05]ER25003 [07]ER36003 [09]ER42003 [11]ER47303 [13]ER53003 [15]ER60003 [17]ER66003	///
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
								
			foreach	year	in	1999	2001	2003	2015	2017	{
			    gen	double	fs_scale_fam`year'_temp	=	round(fs_scale_fam`year',0.01)
				drop	fs_scale_fam`year'
				rename	fs_scale_fam`year'_temp	fs_scale_fam`year'
				label	var	fs_scale_fam`year'	"HH Food Security Scale Score"
			}
			
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
			psid use || food_stamp_used_1yr	/*[69]V634 [76]V4366 [77]V5537 [94]ER3059 [95]ER6058 [96]ER8155*/ [97]ER11049 [99]ER14255 [01]ER18386 [03]ER21652 [05]ER25654 [07]ER36672 [09]ER42691 [11]ER48007 [13]ER53704 [15]ER60719 [17]ER66766	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	food_stamp_used_1yr
			save		`food_stamp_used_1yr'
			
			*	Child received free or reduced cost meal (lunch)
			psid use || child_lunch_assist	[99]ER16418 [01]ER20364 [03]ER24069 [05]ER25626 [07]ER36631 [09]ER42650 [11]ER47968	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	child_lunch_assist_fam
			save		`child_lunch_assist_fam'
			
			*	Child received free or reduced cost meal (breakfast)
			psid use || child_bf_assist	[99]ER16419 [01]ER20365 [03]ER24070 [05]ER25627 [07]ER36632 [09]ER42651 [11]ER47969	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	child_bf_assist_fam
			save		`child_bf_assist_fam'
			
			*	Child received free or reduced cost meal (breakfast and/or lunch)
			psid use || child_meal_assist	[13]ER53680 [15]ER60695 [17]ER66742	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	child_meal_assist_fam
			save		`child_meal_assist_fam'
			
			*	WIC received last years
			psid use || WIC_received_last	[99]ER16421 [01]ER20367 [03]ER24072 [05]ER25633 [07]ER36651 [09]ER42670 [11]ER47988 [13]ER53700 [15]ER60715 [17]ER66762	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	WIC_received_last
			save		`WIC_received_last'
			
			*	Family composition change
			psid use || family_comp_change	/*[69]V542 [70]V1109 [71]V1809 [72]V2410 [73]V3010 [74]V3410 [75]V3810 [76]V4310 [77]V5210 [78]V5710 [79]V6310 [80]V6910 [81]V7510 [82]V8210 [83]V8810 [84]V10010 [85]V11112 [86]V12510 [87]V13710 [88]V14810 [89]V16310 [90]V17710 [91]V19010 [92]V20310 [93]V21608 [94]ER2005A [95]ER5004A [96]ER7004A*/ [97]ER10004A [99]ER13008A [01]ER17007 [03]ER21007 [05]ER25007 [07]ER36007 [09]ER42007 [11]ER47307 [13]ER53007 [15]ER60007 [17]ER66007	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	family_comp_change
			save		`family_comp_change'
			
			*	Total food expenditure
			psid use || food_exp_total	[99]ER16515A1 [01]ER20456A1 [03]ER24138A1 [05]ER28037A1 [07]ER41027A1 [09]ER46971A1 [11]ER52395A1 [13]ER58212A1 [15]ER65410 [17]ER71487	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	food_exp_total
			save		`food_exp_total'
			
			*	Height of the respondent (feet part)
			psid use || height_feet	[99]ER15553 [01]ER19718 [03]ER23133 [05]ER27110 [07]ER38321 [09]ER44294 [11]ER49633 [13]ER55381 [15]ER62503 [17]ER68568	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	height_feet
			save		`height_feet'
			
			*	Height of the respondent (inch part)
			psid use || height_inch	[99]ER15554 [01]ER19719 [03]ER23134 [05]ER27111 [07]ER38322 [09]ER44295 [11]ER49634 [13]ER55382 [15]ER62504 [17]ER68569	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	height_inch
			save		`height_inch'
			
			*	Height of the respondent (meters)
			psid use || height_meter	[11]ER49635 [13]ER55383 [15]ER62505 [17]ER68570	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	height_meter
			save		`height_meter'
			
			*	Weight of the respondent (lbs)
			psid use || weight_lbs	[99]ER15552 [01]ER19717 [03]ER23132 [05]ER27109 [07]ER38320 [09]ER44293 [11]ER49631 [13]ER55379 [15]ER62501 [17]ER68566	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	weight_lbs
			save		`weight_lbs'
			
			*	Weight of the respondent (kg)
			psid use || weight_kg	[11]ER49632 [13]ER55380 [15]ER62502 [17]ER68567	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	weight_kg
			save		`weight_kg'
			
			*	Finished high school or GED (Head)
			psid use || hs_completed_head	 	/*[85]V11945 [86]V13568 [87]V14615 [88]V16089 [89]V17486 [90]V18817 [91]V20117 [92]V21423 [93]V23279 [94]ER3948 [95]ER6818 [96]ER9064*/ [97]ER11854 [99]ER15937 [01]ER19998 [03]ER23435 [05]ER27402 [07]ER40574 [09]ER46552 [11]ER51913 [13]ER57669 [15]ER64821 [17]ER70893	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	hs_completed_head
			save		`hs_completed_head'
			
			*	Finished college (Head)
			psid use || college_completed	[99]ER15952 [01]ER20013 [03]ER23450 [05]ER27417 [07]ER40589 [09]ER46567 [11]ER51928 [13]ER57684 [15]ER64836 [17]ER70908	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	college_completed
			save		`college_completed'
			
			*	Highest college degree completed (Head)
			psid use || college_degree_type	[99]ER15953 [01]ER20014 [03]ER23451 [05]ER27418 [07]ER40590 [09]ER46568 [11]ER51929 [13]ER57685 [15]ER64837 [17]ER70909	///
								using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
			
			tempfile	college_degree_type
			save		`college_degree_type'
					
			
		*	# of days/week eat meal together
			psid use || meal_together /*[68]V174 [69]V638 [70]V1380 [71]V2092 [72]V2693 [88]V15760 [89]V17295 [90]V18699 [91]V19999 [92]V21299 [93]V23158 [94]ER3057 [95]ER6056 [96]ER8153*/ [97]ER11047 [99]ER14231 [01]ER18361 [03]ER21627 [05]ER25624 [07]ER36629 [09]ER42648 [11]ER47966 [13]ER53678 [15]ER60693 [17]ER66740	///
				using "${PSID_dtRaw}/Main", keepnotes design(any) clear	
					
			tempfile	meal_together
			save		`meal_together'

*	Child in daycare
			psid use || child_daycare_any [99]ER14233 [01]ER18363 [03]ER21629 [05]ER25629 [07]ER36647 [09]ER42666 [11]ER47984 [13]ER53696 [15]ER60711 [17]ER66758	///
			using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
			tempfile	child_daycare_any
			save		`child_daycare_any'

*	Daycare participates in FSP
			psid use || child_daycare_FSP  	[99]ER14235 [01]ER18365 [03]ER21631 [05]ER25631 [07]ER36649 [09]ER42668 [11]ER47986 [13]ER53698 [15]ER60713 [17]ER66760	///
				using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
					
			tempfile	child_daycare_FSP
			save		`child_daycare_FSP'

*	Offers snack in daycare
			psid use || child_daycare_snack  	[99]ER14235 [01]ER18365 [03]ER21631 [05]ER25631 [07]ER36649 [09]ER42668 [11]ER47986 [13]ER53698 [15]ER60713 [17]ER66760	///
				using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
					
			tempfile	child_daycare_snack
			save		`child_daycare_snack'

*	Age (spouse)
psid use || age_spouse  	[97]ER10011 [99]ER13012 [01]ER17015 [03]ER21019 [05]ER25019 [07]ER36019 [09]ER42019 [11]ER47319 [13]ER53019 [15]ER60019 [17]ER66019	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	age_spouse
		save		`age_spouse'

*	Ethnicity (head)
psid use || ethnicity_head  	[97]ER12165 [99]ER15932 [01]ER19993 [03]ER23430 [05]ER27397 [07]ER40569 [09]ER46547 [11]ER51908 [13]ER57663 [15]ER64815 [17]ER70887	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	ethnicity_head
		save		`ethnicity_head'

*	Ethnicity (spouse)
psid use || ethnicity_spouse 	[97]ER12156 [99]ER15840 [01]ER19901 [03]ER23338 [05]ER27301 [07]ER40476 [09]ER46453 [11]ER51814 [13]ER57553 [15]ER64676 [17]ER70749	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	ethnicity_spouse
		save		`ethnicity_spouse'

*	Race (spouse)
psid use || race_spouse 	[97]ER11760 [99]ER15836 [01]ER19897 [03]ER23334 [05]ER27297 [07]ER40472 [09]ER46449 [11]ER51810 [13]ER57549 [15]ER64671 [17]ER70744	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	race_spouse
		save		`race_spouse'
		
psid use || other_degree_head 	/*[68]V314 [69]V795 [70]V1486 [71]V2198 [72]V2824 [73]V3242 [74]V3664 [75]V4094 [76]V4685 [77]V5609 [78]V6158 [79]V6755 [80]V7388 [81]V8040 [82]V8664 [83]V9350 [84]V10997 [85]V11964 [86]V13587 [87]V14634 [88]V16108 [89]V17505 [90]V18836 [91]V20136 [92]V21442 [93]V23298 [94]ER3967 [95]ER6837 [96]ER9083*/ [97]ER11876 [99]ER15958 [01]ER20019 [03]ER23455 [05]ER27423 [07]ER40595 [09]ER46573 [11]ER51934 [13]ER57690 [15]ER64850 [17]ER70922	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	other_degree_head
		save		`other_degree_head'
		
psid use || other_degree_spouse 	/*[75]V4103 [76]V4696 [77]V5568 [78]V6117 [79]V6714 [80]V7347 [81]V7999 [82]V8623 [83]V9309 [84]V10956 [85]V12319 [86]V13516 [87]V14563 [88]V16037 [89]V17434 [90]V18765 [91]V20065 [92]V21371 [93]V23228 [94]ER3900 [95]ER6770 [96]ER9016*/ [97]ER11788 [99]ER15865 [01]ER19926 [03]ER23363 [05]ER27327 [07]ER40502 [09]ER46479 [11]ER51840 [13]ER57580 [15]ER64711 [17]ER70784	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	other_degree_spouse
		save		`other_degree_spouse'
	
*	Attended college (head)	
psid use || attend_college_head 	/*[85]V11956 [86]V13579 [87]V14626 [88]V16100 [89]V17497 [90]V18828 [91]V20128 [92]V21434 [93]V23290 [94]ER3959 [95]ER6829 [96]ER9075*/ [97]ER11865 [99]ER15948 [01]ER20009 [03]ER23446 [05]ER27413 [07]ER40585 [09]ER46563 [11]ER51924 [13]ER57680 [15]ER64832 [17]ER70904	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	attend_college_head
		save		`attend_college_head'
		
*	Attended college (spouse)	
psid use || attend_college_spouse 	/* [85]V12311 [86]V13510 [87]V14557 [88]V16031 [89]V17428 [90]V18759 [91]V20059 [92]V21365 [93]V23222 [94]ER3894 [95]ER6764 [96]ER9010*/ [97]ER11777 [99]ER15856 [01]ER19917 [03]ER23354 [05]ER27317 [07]ER40492 [09]ER46469 [11]ER51830 [13]ER57570 [15]ER64693 [17]ER70766	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	attend_college_spouse
		save		`attend_college_spouse'

*	Completed college (spouse)
psid use || college_comp_spouse	/*[75]V4105 [76]V4698 [77]V5570 [78]V6119 [79]V6716 [80]V7349 [81]V8001 [82]V8625 [83]V9311 [84]V10958 [85]V12315 [86]V13513 [87]V14560 [88]V16034 [89]V17431 [90]V18762 [91]V20062 [92]V21368 [93]V23225 [94]ER3897 [95]ER6767 [96]ER9013*/ [97]ER11781 [99]ER15860 [01]ER19921 [03]ER23358 [05]ER27321 [07]ER40496 [09]ER46473 [11]ER51834 [13]ER57574 [15]ER64697 [17]ER70770	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	college_comp_spouse
		save		`college_comp_spouse'
		
*	Location of education (head)		
psid use || edu_in_US_head	[97]ER11853 [99]ER15936 [01]ER19997 [03]ER23434 [05]ER27401 [07]ER40573 [09]ER46551 [11]ER51912 [13]ER57668 [15]ER64820 [17]ER70892	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	edu_in_US_head
		save		`edu_in_US_head'

*	Location of education (spouse)
psid use || edu_in_US_spouse	[97]ER11853 [99]ER15936 [01]ER19997 [03]ER23434 [05]ER27401 [07]ER40573 [09]ER46551 [11]ER51912 [13]ER57668 [15]ER64820 [17]ER70892	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	edu_in_US_spouse
		save		`edu_in_US_spouse'

*	Years of college completed (head)
psid use || college_yrs_head	/*[85]V11959 [86]V13582 [87]V14629 [88]V16103 [89]V17500 [90]V18831 [91]V20131 [92]V21437 [93]V23293 [94]ER3962 [95]ER6832 [96]ER9078*/ [97]ER11868 [99]ER15951 [01]ER20012 [03]ER23449 [05]ER27416 [07]ER40588 [09]ER46566 [11]ER51927 [13]ER57683 [15]ER64835 [17]ER70907	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	college_yrs_head
		save		`college_yrs_head'
		
	
*	Years of college completed (spouse)
psid use || college_yrs_spouse	/*[85]V12314 [86]V13512 [87]V14559 [88]V16033 [89]V17430 [90]V18761 [91]V20061 [92]V21367 [93]V23224 [94]ER3896 [95]ER6766 [96]ER9012*/ [97]ER11780 [99]ER15859 [01]ER19920 [03]ER23357 [05]ER27320 [07]ER40495 [09]ER46472 [11]ER51833 [13]ER57573 [15]ER64696 [17]ER70769	///
	using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	college_yrs_spouse
		save		`college_yrs_spouse'

		*	Grades Househould head's spouse completed (fam)
		psid use || grade_comp_spouse /*[75]V4102 [76]V4695 [77]V5567 [78]V6116 [79]V6713 [80]V7346 [81]V7998 [82]V8622 [83]V9308 [84]V10955 [91]V20199 [92]V21505 [93]V23334 [94]ER4159 [95]ER6999 [96]ER9250*/ [97]ER12223 [99]ER16517 [01]ER20458 [03]ER24149 [05]ER28048 [07]ER41038 [09]ER46982 [11]ER52406 [13]ER58224 [15]ER65460 [17]ER71539	///
									using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
				
		tempfile	grade_comp_spouse
		save		`grade_comp_spouse'
				
*	Finished high school or GED (Spouse)
		psid use || hs_completed_spouse	/*[85]V12300 [86]V13503 [87]V14550 [88]V16024 [89]V17421 [90]V18752 [91]V20052 [92]V21358 [93]V23215 [94]ER3887 [95]ER6757 [96]ER9003*/ [97]ER11766 [99]ER15845 [01]ER19906 [03]ER23343 [05]ER27306 [07]ER40481 [09]ER46458 [11]ER51819 [13]ER57559 [15]ER64682 [17]ER70755	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	hs_completed_spouse
		save		`hs_completed_spouse'
		
*	Child care expenditure
		psid use || child_exp_total	[99]ER16515D1 [01]ER20456D1 [03]ER24138D1 [05]ER28037D2 [07]ER41027D2 [09]ER46971D2 [11]ER52395D2 [13]ER58212D2 [15]ER65438 [17]ER71516	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	child_exp_total
		save		`child_exp_total'
		 	
*	Clothing expenditure
		psid use || cloth_exp_total	 	[05]ER28037E1 [07]ER41027E1 [09]ER46971E1 [11]ER52395E1 [13]ER58212E1 [15]ER65446 [17]ER71525	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	cloth_exp_total
		save		`cloth_exp_total'
		
*	Support outside FU
		psid use || sup_outside_FU	 	/*[69]V732 [70]V1399 [71]V2111 [72]V2708 [73]V3211 [74]V3630 [75]V4076 [76]V4620 [77]V5555 [78]V6097 [79]V6690 [80]V7293 [81]V7993 [82]V8612 [83]V9303 [84]V10894 [85]V11896 [86]V13407 [87]V14504 [88]V15779 [89]V17308 [90]V18712 [91]V20012 [92]V21312 [93]V23171 [94]ER3706 [95]ER6708 [96]ER8826*/ [97]ER11708 [99]ER14976 [01]ER19172 [03]ER22537 [05]ER26518 [07]ER37536 [09]ER43527 [11]ER48852 [13]ER54595 [15]ER61706 [17]ER67759 ///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	sup_outside_FU
		save		`sup_outside_FU'
		
*	Education expenditure
		psid use || edu_exp_total 	[99]ER16515C9 [01]ER20456C9 [03]ER24138C9 [05]ER28037D1 [07]ER41027D1 [09]ER46971D1 [11]ER52395D1 [13]ER58212D1 [15]ER65437 [17]ER71515	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	edu_exp_total
		save		`edu_exp_total'
		
*	Health expenditure
		psid use || health_exp_total 	[99]ER16515D2 [01]ER20456D2 [03]ER24138D2 [05]ER28037D3 [07]ER41027D3 [09]ER46971D3 [11]ER52395D3 [13]ER58212D3 [15]ER65439 [17]ER71517	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	health_exp_total
		save		`health_exp_total'
		
*	Housing expenditure
		psid use || house_exp_total 	[99]ER16515A5 [01]ER20456A5 [03]ER24138A5 [05]ER28037A5 [07]ER41027A5 [09]ER46971A5 [11]ER52395A5 [13]ER58212A5 [15]ER65414 [17]ER71491	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear		
		
		tempfile	house_exp_total
		save		`house_exp_total'
		
*	Itemizied Deduction (Tax)
		psid use || tax_item_deduct 	 	/*[84]V10876 [85]V11895 [86]V13406 [87]V14503 [88]V15772 [89]V17307 [90]V18711 [91]V20011 [92]V21311 [93]V23170 [94]ER3705 [95]ER6707 [96]ER8825*/ [97]ER11707 [99]ER14973 [01]ER19161 [03]ER22534 [05]ER26515 [07]ER37533 [09]ER43524 [11]ER48849 [13]ER54592 [15]ER61703 [17]ER67756	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear	
							
		tempfile	tax_item_deduct
		save		`tax_item_deduct'
							
*	Property Tax
		psid use || property_tax 	 	[99]ER16515A8 [01]ER20456A8 [03]ER24138A8 [05]ER28037A8 [07]ER41027A8 [09]ER46971A8 [11]ER52395A8 [13]ER58212A8 [15]ER65417 [17]ER71495	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	property_tax
		save		`property_tax'
							
*	Transport Expenditure Tax
		psid use || transport_exp 	 	[99]ER16515B6 [01]ER20456B6 [03]ER24138B6 [05]ER28037B7 [07]ER41027B7 [09]ER46971B7 [11]ER52395B7 [13]ER58212B7 [15]ER65425 [17]ER71503	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear	
		
		tempfile	transport_exp
		save		`transport_exp'
		
*	Couple_status
		psid use || couple_status 	 	/*[83]V9421 [84]V11067 [85]V12428 [86]V13667 [87]V14714 [88]V16189 [89]V17567 [90]V18918 [91]V20218 [92]V21524 [93]V23338 [94]ER4159C [95]ER6999C [96]ER9250C*/ [97]ER12223C [99]ER16425 [01]ER20371 [03]ER24152 [05]ER28051 [07]ER41041 [09]ER46985 [11]ER52409 [13]ER58227 [15]ER65463 [17]ER71542	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear	
		
		tempfile	couple_status
		save		`couple_status'
		
*	Head status
		psid use || head_status 	 	/* 	[69]V791 [70]V1461 [71]V2165 [72]V2791 [73]V3217 [74]V3639 [75]V4114 [76]V4658 [77]V5578 [78]V6127 [79]V6724 [80]V7357 [81]V8009 [82]V8633 [83]V9319 [84]V10966 [85]V11906 [86]V13533 [87]V14580 [88]V16054 [89]V17451 [90]V18782 [91]V20082 [92]V21388 [93]V23245 [94]ER3917 [95]ER6787 [96]ER9033*/ [97]ER11812 [99]ER15890 [01]ER19951 [03]ER23388 [05]ER27352 [07]ER40527 [09]ER46504 [11]ER51865 [13]ER57618 [15]ER64769 [17]ER70841	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	head_status
		save		`head_status'
							
							
*	New spouse (need to merge "no wife" and "not new" in 1999/2001)
		psid use || spouse_new 	 	/* 	[73]V3215 [74]V3637 [75]V4107 [76]V4694 [77]V5566 [78]V6115 [79]V6712 [80]V7345 [81]V7997 [82]V8621 [83]V9307 [84]V10954 [86]V13484 [87]V14531 [88]V16005 [89]V17402 [90]V18733 [91]V20033 [92]V21339 [93]V23196 [94]ER3863 [95]ER6733 [96]ER8979*/ [97]ER11731 [99]ER15805 [01]ER19866 [03]ER23303 [05]ER27263 [07]ER40438 [09]ER46410 [11]ER51771 [13]ER57508 [15]ER64630 [17]ER70703	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	spouse_new
		save		`spouse_new'
		
		
*	All other debts
**	This variable exists only untill 2009. Since 2011, debts are splitted into sub-categories (credit card, student loan, etc.).
**	To use this variable for longer time series, make sure to aggregate those sub-categories properly by checking the questionnaire.
		psid use || other_debts 	 	/* 	[84]V10933 [89]V17335 [94]ER3753*/ [99]ER15031 [01]ER19227 [03]ER22622 [05]ER26603 [07]ER37621 [09]ER43612	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
		
		tempfile	other_debts
		save		`other_debts'
		
*	Drink alcohol (head)
		psid use || alcohol_head 	 	 	[99]ER15550 [01]ER19715 [03]ER23130 [05]ER27105 [07]ER38316 [09]ER44289 [11]ER49627 [13]ER55375 [15]ER62497 [17]ER68562	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	alcohol_head
		save		`alcohol_head'
		
*	Drink alcohol (spouse)
		psid use || alcohol_spouse 	 	 	[99]ER15658 [01]ER19823 [03]ER23257 [05]ER27228 [07]ER39413 [09]ER45386 [11]ER50745 [13]ER56491 [15]ER63613 [17]ER69689	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	alcohol_spouse
		save		`alcohol_spouse'
		
*	# of drink/week (head)
		psid use || num_drink_head	 	 	[99]ER15551 [01]ER19716 [03]ER23131 [05]ER27107 [07]ER38318 [09]ER44291 [11]ER49629 [13]ER55377 [15]ER62499 [17]ER68564	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	num_drink_head
		save		`num_drink_head'
		
*	# of drink/week (spouse)
		psid use || num_drink_spouse	 	 [99]ER15659 [01]ER19824 [03]ER23258 [05]ER27230 [07]ER39415 [09]ER45388 [11]ER50747 [13]ER56493 [15]ER63615 [17]ER69691	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	num_drink_spouse
		save		`num_drink_spouse'
		
*	Smoke (head)
		psid use || smoke_head	 	 /*[86]V13441*/ [99]ER15543 [01]ER19708 [03]ER23123 [05]ER27098 [07]ER38309 [09]ER44282 [11]ER49620 [13]ER55368 [15]ER62490 [17]ER68555	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	smoke_head
		save		`smoke_head'
		
*	Smoke (spouse)
		psid use || smoke_spouse 	 /*[86]V13476*/ [99]ER15651 [01]ER19816 [03]ER23250 [05]ER27221 [07]ER39406 [09]ER45379 [11]ER50738 [13]ER56484 [15]ER63606 [17]ER69682	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	smoke_spouse
		save		`smoke_spouse'
		
*	Daily Smoke (head)
		psid use || num_smoke_head	 	 /*[86]V13442*/ [99]ER15544 [01]ER19709 [03]ER23124 [05]ER27099 [07]ER38310 [09]ER44283 [11]ER49621 [13]ER55369 [15]ER62491 [17]ER68556	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	num_smoke_head
		save		`num_smoke_head'
		
*	Daily Smoke (spouse)
		psid use || num_smoke_spouse 	 /*[86]V13477*/ [99]ER15652 [01]ER19817 [03]ER23251 [05]ER27222 [07]ER39407 [09]ER45380 [11]ER50739 [13]ER56485 [15]ER63607 [17]ER69683	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	num_smoke_spouse
		save		`num_smoke_spouse'
		
*	Physical Disability (head)
		psid use || phys_disab_head 	/*[72]V2718 [73]V3244 [74]V3666 [75]V4145 [76]V4625 [77]V5560 [78]V6102 [79]V6710 [80]V7343 [81]V7974 [82]V8616 [83]V9290 [84]V10879 [85]V11993 [86]V13427 [87]V14515 [88]V15994 [89]V17391 [90]V18722 [91]V20022 [92]V21322 [93]V23181 [94]ER3854 [95]ER6724 [96]ER8970*/ [97]ER11724 [99]ER15449 [01]ER19614 [03]ER23014 [05]ER26995 [07]ER38206 [09]ER44179 [11]ER49498 [13]ER55248 [15]ER62370 [17]ER68424	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	phys_disab_head
		save		`phys_disab_head'
		
*	Physical Disability (spouse)
		psid use || phys_disab_spouse 	/*[76]V4766 [81]V7982 [82]V8619 [83]V9295 [84]V10886 [85]V12346 [86]V13462 [87]V14526 [88]V16000 [89]V17397 [90]V18728 [91]V20028 [92]V21329 [93]V23188 [94]ER3859 [95]ER6729 [96]ER8975*/ [97]ER11728 [99]ER15557 [01]ER19722 [03]ER23141 [05]ER27118 [07]ER39303 [09]ER45276 [11]ER50616 [13]ER56364 [15]ER63486 [17]ER69551	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	phys_disab_spouse
		save		`phys_disab_spouse'
		
*	Housing status
		psid use || housing_status 	/*[68]V103 [69]V593 [70]V1264 [71]V1967 [72]V2566 [73]V3108 [74]V3522 [75]V3939 [76]V4450 [77]V5364 [78]V5864 [79]V6479 [80]V7084 [81]V7675 [82]V8364 [83]V8974 [84]V10437 [85]V11618 [86]V13023 [87]V14126 [88]V15140 [89]V16641 [90]V18072 [91]V19372 [92]V20672 [93]V22427 [94]ER2032 [95]ER5031 [96]ER7031*/ [97]ER10035 [99]ER13040 [01]ER17043 [03]ER21042 [05]ER25028 [07]ER36028 [09]ER42029 [11]ER47329 [13]ER53029 [15]ER60030 [17]ER66030	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	housing_status
		save		`housing_status'
		
*	Elderly meal
		psid use || elderly_meal 	[99]ER16416 [01]ER20362 [03]ER24067 [05]ER25637 [07]ER36655 [09]ER42674 [11]ER47990 [13]ER53702 [15]ER60717 [17]ER66764	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	elderly_meal
		save		`elderly_meal'
		
*	Retirement plan (head)
		psid use || retire_plan_head 	/*[75]V4004 [84]V10480 [89]V16809*/ [99]ER15156 [01]ER19327 [03]ER22722 [05]ER26703 [07]ER37739 [09]ER43712 [11]ER49057 [13]ER54813 [15]ER61933 [17]ER67987	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	retire_plan_head
		save		`retire_plan_head'
		
*	Retirement plan (spouse)
		psid use || retire_plan_spouse	 	/*[84]V10694 [89]V17128*/ [99]ER15302 [01]ER19470 [03]ER22866 [05]ER26847 [07]ER37971 [09]ER43944 [11]ER49276 [13]ER55029 [15]ER62150 [17]ER68204	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	retire_plan_spouse
		save		`retire_plan_spouse'
		
*	Private annuities or IRA
		psid use || annuities_IRA 	[99]ER15012 [01]ER19208 [03]ER22588 [05]ER26569 [07]ER37587 [09]ER43578 [11]ER48903 [13]ER54653 [15]ER61764 [17]ER67817	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	annuities_IRA
		save		`annuities_IRA'
		
*	Veteran (head)
		psid use || veteran_head 	/*[68]V315 [69]V796 [70]V1487 [71]V2199 [72]V2825 [73]V3243 [74]V3665 [75]V4140 [76]V4683 [77]V5603 [78]V6152 [79]V6749 [80]V7382 [81]V8034 [82]V8658 [83]V9344 [84]V10991 [85]V11940 [86]V13567 [87]V14614 [88]V16088 [89]V17485 [90]V18816 [91]V20116 [92]V21422 [93]V23278 [94]ER3947 [95]ER6817 [96]ER9063*/ [97]ER11852 [99]ER15935 [01]ER19996 [03]ER23433 [05]ER27400 [07]ER40572 [09]ER46550 [11]ER51911 [13]ER57666 [15]ER64818 [17]ER70890	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	veteran_head
		save		`veteran_head'
		
*	Veteran (spouse)
		psid use || veteran_spouse 	 	/*[85]V12295 [86]V13502 [87]V14549 [88]V16023 [89]V17420 [90]V18751 [91]V20051 [92]V21357 [93]V23214 [94]ER3886 [95]ER6756 [96]ER9002*/ [97]ER11764 [99]ER15843 [01]ER19904 [03]ER23341 [05]ER27304 [07]ER40479 [09]ER46456 [11]ER51817 [13]ER57556 [15]ER64679 [17]ER70752	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	veteran_spouse
		save		`veteran_spouse'
		
*	Total wealth (including home equity)
		psid use || wealth_total 	 	/*[84]S117 [89]S217 [94]S317*/ [99]S417 [01]S517 [03]S617 [05]S717 [07]S817 [09]ER46970 [11]ER52394 [13]ER58211 [15]ER65408 [17]ER71485	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	wealth_total
		save		`wealth_total'
		
*	Employment Status (head)
		psid use || emp_status_head 	 	/*[94]ER2069 [95]ER5068 [96]ER7164*/ [97]ER10081 [99]ER13205 [01]ER17216 [03]ER21123 [05]ER25104 [07]ER36109 [09]ER42140 [11]ER47448 [13]ER53148 [15]ER60163 [17]ER66164	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	emp_status_head
		save		`emp_status_head'
		
		
*	Employment Status (spouse)
		psid use || emp_status_spouse 	 	 /* [94]ER2563 [95]ER5562 [96]ER7658*/ [97]ER10563 [99]ER13717 [01]ER17786 [03]ER21373 [05]ER25362 [07]ER36367 [09]ER42392 [11]ER47705 [13]ER53411 [15]ER60426 [17]ER66439	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	emp_status_spouse
		save		`emp_status_spouse'
		
*	Retirement year (head)
		psid use || retire_year_head 	 	[99]ER13208 [01]ER17219 [03]ER21126 [05]ER25107 [07]ER36112 [09]ER42143 [11]ER47451 [13]ER53151 [15]ER60166 [17]ER66167	///
							using "${PSID_dtRaw}/Main", keepnotes design(any) clear
							
		tempfile	retire_year_head
		save		`retire_year_head'
		
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
		merge 1:1 x11101ll using `grade_comp_head_fam', keepusing(grade_comp_head_fam*) nogen assert(3)
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
		merge 1:1 x11101ll using `hs_completed_head', keepusing(hs_completed_head*) nogen assert(3)
		merge 1:1 x11101ll using `college_completed', keepusing(college_completed*) nogen assert(3)
		merge 1:1 x11101ll using `college_degree_type', keepusing(college_degree_type*) nogen assert(3)
		merge 1:1 x11101ll using `meal_together', keepusing(meal_together*) nogen assert(3)
		merge 1:1 x11101ll using `child_daycare_any', keepusing(child_daycare_any*) nogen assert(3)
		merge 1:1 x11101ll using `child_daycare_FSP', keepusing(child_daycare_FSP*) nogen assert(3)
		merge 1:1 x11101ll using `child_daycare_snack', keepusing(child_daycare_snack*) nogen assert(3)
		merge 1:1 x11101ll using `age_spouse', keepusing(age_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `ethnicity_head', keepusing(ethnicity_head*) nogen assert(3)
		merge 1:1 x11101ll using `ethnicity_spouse', keepusing(ethnicity_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `race_spouse', keepusing(race_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `other_degree_head', keepusing(other_degree_head*) nogen assert(3)
		merge 1:1 x11101ll using `other_degree_spouse', keepusing(other_degree_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `attend_college_head', keepusing(attend_college_head*) nogen assert(3)
		merge 1:1 x11101ll using `attend_college_spouse', keepusing(attend_college_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `college_comp_spouse', keepusing(college_comp_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `edu_in_US_head', keepusing(edu_in_US_head*) nogen assert(3)
		merge 1:1 x11101ll using `edu_in_US_spouse', keepusing(edu_in_US_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `college_yrs_head', keepusing(college_yrs_head*) nogen assert(3)
		merge 1:1 x11101ll using `college_yrs_spouse', keepusing(college_yrs_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `grade_comp_spouse', keepusing(grade_comp_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `hs_completed_spouse', keepusing(hs_completed_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `child_exp_total', keepusing(child_exp_total*) nogen assert(3)
		merge 1:1 x11101ll using `cloth_exp_total', keepusing(cloth_exp_total*) nogen assert(3)
		merge 1:1 x11101ll using `sup_outside_FU', keepusing(sup_outside_FU*) nogen assert(3)
		merge 1:1 x11101ll using `edu_exp_total', keepusing(edu_exp_total*) nogen assert(3)
		merge 1:1 x11101ll using `health_exp_total', keepusing(health_exp_total*) nogen assert(3)
		merge 1:1 x11101ll using `house_exp_total', keepusing(house_exp_total*) nogen assert(3)
		merge 1:1 x11101ll using `tax_item_deduct', keepusing(tax_item_deduct*) nogen assert(3)
		merge 1:1 x11101ll using `property_tax', keepusing(property_tax*) nogen assert(3)
		merge 1:1 x11101ll using `transport_exp', keepusing(transport_exp*) nogen assert(3)
		merge 1:1 x11101ll using `couple_status', keepusing(couple_status*) nogen assert(3)
		merge 1:1 x11101ll using `head_status', keepusing(head_status*) nogen assert(3)
		merge 1:1 x11101ll using `spouse_new', keepusing(spouse_new*) nogen assert(3)
		merge 1:1 x11101ll using `other_debts', keepusing(other_debts*) nogen assert(3)
		merge 1:1 x11101ll using `alcohol_head', keepusing(alcohol_head*) nogen assert(3)
		merge 1:1 x11101ll using `alcohol_spouse', keepusing(alcohol_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `num_drink_head', keepusing(num_drink_head*) nogen assert(3)
		merge 1:1 x11101ll using `num_drink_spouse', keepusing(num_drink_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `smoke_head', keepusing(smoke_head*) nogen assert(3)
		merge 1:1 x11101ll using `smoke_spouse', keepusing(smoke_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `num_smoke_head', keepusing(num_smoke_head*) nogen assert(3)
		merge 1:1 x11101ll using `num_smoke_spouse', keepusing(num_smoke_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `phys_disab_head', keepusing(phys_disab_head*) nogen assert(3)
		merge 1:1 x11101ll using `phys_disab_spouse', keepusing(phys_disab_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `housing_status', keepusing(housing_status*) nogen assert(3)
		merge 1:1 x11101ll using `elderly_meal', keepusing(elderly_meal*) nogen assert(3)
		merge 1:1 x11101ll using `retire_plan_head', keepusing(retire_plan_head*) nogen assert(3)
		merge 1:1 x11101ll using `retire_plan_spouse', keepusing(retire_plan_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `annuities_IRA', keepusing(annuities_IRA*) nogen assert(3)
		merge 1:1 x11101ll using `veteran_head', keepusing(veteran_head*) nogen assert(3)
		merge 1:1 x11101ll using `veteran_spouse', keepusing(veteran_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `wealth_total', keepusing(wealth_total*) nogen assert(3)
		merge 1:1 x11101ll using `emp_status_head', keepusing(emp_status_head*) nogen assert(3)
		merge 1:1 x11101ll using `emp_status_spouse', keepusing(emp_status_spouse*) nogen assert(3)
		merge 1:1 x11101ll using `retire_year_head', keepusing(retire_year_head*) nogen assert(3)
		
		qui		compress
		save	"${PSID_dtInt}/PSID_raw_1999_2017_ind.dta", replace
	}	
	
	/****************************************************************
		SECTION 2: Clean variable labels and values
	****************************************************************/	
		
	if	`clean_vars'==1	{
		
		use	"${PSID_dtInt}/PSID_raw_1999_2017_ind.dta", clear
		
		*	Clean
		
			*	Define variable labels for multiple variables
				
				*	YesNo
				label	define	yesno	1	"Yes"	0	"No"
				
				*	YesNO5
				label	define	yesno5	1	"Yes"	5	"No"
				
				*	Yes/No/Don't Know/Refuse
				label	define	YNDR	1	"Yes"	5	"No"	8	"Don't Know"	9	"N/A; refuse"
				
				*	Yes/No/Don't Know/Refuse/Inapproriate
				label	define	YNDRI	1	"Yes"	5	"No"	8	"Don't Know"	9	"N/A; refuse"	0	"Inapp"
			
				*	Split-off indicator
				label	define	splitoff_indicator	1	"Reinterview family"	///
													2	"Split-off from reinterview family"	///
													3	"Recontact family"	///
													4	"Split-off from recontact family"	///
													5	"New 2017 Immigrants"
			*	Assign value labels
			local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017

				*	Respondent
				*	Individuals who were not in survey sample in that year were recorded as "0", so it is safe to treat them as missing.
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
					
			qui	ds	age_head_fam1999-age_head_fam2017 age_spouse1997-age_spouse2017
			foreach	var in `r(varlist)'	{
				replace	`var'=.d	if	`var'==999
				*replace	`var'=.n	if	`var'==0
			}
			
			
			*	Marital status of head
			qui ds marital_status_fam1999-marital_status_fam2017
			foreach	var in `r(varlist)'	{
				replace	`var'=.d	if	`var'==8
				replace	`var'=.n	if	`var'==9
			}
			
			
			*	Grade completed of household head (fam)
			qui ds grade_comp_head_fam1999-grade_comp_head_fam2017 grade_comp_spouse1997-grade_comp_spouse2017
			foreach	var	in	`r(varlist)'	{
				replace	`var'=.n	if	`var'==99	//	Recode it as they are continuous variables
			}
			
			*	Food Stamp & WIC			
			qui ds	food_stamp_used_1yr*	
			lab	val	`r(varlist)'	YNDR
			
			qui ds	WIC_received_last*	
			lab	val	`r(varlist)'	YNDRI
			
			/*	For now, use the entire categorical variables without recoding non-responses as missing.
			qui ds	food_stamp_used_1yr1999-food_stamp_used_1yr2017 WIC_received_last1999-WIC_received_last2017
			foreach	var	in	`r(varlist)'	{
				replace	`var'=.d	if	`var'==8
				replace	`var'=.r	if	`var'==9
				replace	`var'=.n	if	`var'==0	//	Treat "inappropriate" as "no"
				replace	`var'=0		if	`var'==5
			}
			*/	
			
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
				*label	val	race_head_fam1999 race_head_fam2001 race_head_fam2003	race_spouse1999-race_spouse2003	race_99_03
				
				*	2005-2017
				label	define	race_05_17	1 	"White"	///
											2	"Black, African-American or Negro"	///
											3	"American Indian or Alaska Native"	///
											4	"Asian"	///
											5	"Native Hawaiian or Pacific Islander"	///
											7	"Other"	///
											9	"DK; NA; refused"	///
											0 	"Inap.: no wife in FU"
				*label	val	race_head_fam2005-race_head_fam2017	race_spouse2005-race_spouse2017 race_05_17
				
				*	Recode race variables to be compatible across the years
				
					*	In	1999-2003, (1) merge "Color other than black or white"	into "Other" (2) Merge "DK" into "NA;refused"	(3)	"Latino origin" to "white"
					**	(3) is very rough recoding, as 1/3 of the respondents in that categories in 2003 answered as "other" in 2005. Still, 2/3 of the respondents answered as "white"
						recode	race_head_fam1999 race_head_fam2001 race_head_fam2003	race_spouse1999-race_spouse2003	(6=7)	(8=9)	(5=1)
					
					*	In	2005-2017 data, (i) Merge "Asian" and "Native Hawaiian and Pacific Islander"
						recode	race_head_fam2005-race_head_fam2017	race_spouse2005-race_spouse2017	(5=4)
						
					*	Define a new variable lable
					label	define	race_all	1 	"White"	///
												2	"Black, African-American or Negro"	///
												3	"American Indian or Alaska Native"	///
												4	"Asian, Native Hawaiian or Pacific Islander"	///
												7	"Other"	///
												9	"DK; NA; refused"	///
												0 	"Inap.: no wife in FU"
					label	values	race_head_fam* race_spouse*	race_all
				
				
			*	Ethnicity
				label	define	ethnicity	1 	"American"	///
											2 	"Hyphenated American"	///
											3 	"National origin"	///
											4 	"Nonspecific Hispanic identity"	/// 
											5 	"Racial"	///
											6 	"Religious" 	///
											7 	"Other"	///
											8 	"DK"	///
											9 	"NA; refused"
				qui	ds	ethnicity_head* ethnicity_spouse*
				label	val	`r(varlist)'	ethnicity
				
				
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
			
			*	Family composition change
			label	define	family_comp_change	0 	"No change in family members"	///
										1 	"Change in members other than Head or Wife"	///
										2 	"Head same but Wife change"	///
										3	"Wife is now head"	///
										4 	"Female Head got married, husband (non-sample member) now Head"	///
										5	"Some sample member other than Head or Wife has become Head"	///
										6 	"Some female in FU other than Head got married and non-sample member now Head"	///
										7 	"Female Head with husband in institution; husband now Head"	///
										9 	"NA"
			label	values	family_comp_change*	family_comp_change
			
			*	Weight and Height
			foreach	year	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
			
			*	Treat missing values
				
				*	Height (Feet)
				replace	height_feet`year'	=.d	if	height_feet`year'==8
				replace	height_feet`year'	=.r	if	height_feet`year'==9
				replace	height_feet`year'	=.n	if	height_feet`year'==0
				
				*	Height (Inches)
				replace	height_inch`year'	=.d	if	height_inch`year'==98
				replace	height_inch`year'	=.r	if	height_inch`year'==99	
				
				*	Height (Meters)
				if	inrange(`year',2011,2017)	{
					replace	height_meter`year'	=.n	if	height_meter`year'==0
					replace	height_meter`year'	=.d	if	height_meter`year'==8
					replace	height_meter`year'	=.r	if	height_meter`year'==9	
				}
				
				*	Weight (lbs)
				replace	weight_lbs`year'	=.d	if	weight_lbs`year'==998
				replace	weight_lbs`year'	=.r	if	weight_lbs`year'==999			
				replace	weight_lbs`year'	=.n	if	inlist(weight_lbs`year',0,6)
				
				*	Weight (Kilo)
				if	inrange(`year',2011,2017)	{
					replace	weight_kg`year'	=.n	if	weight_kg`year'==0
					replace	weight_kg`year'	=.d	if	weight_kg`year'==998
					replace	weight_kg`year'	=.r	if	weight_kg`year'==999	
				}
			}
		
			
		*	Meal together	-	ordered categorical
		**	Ordered categorical, so it seems OK to recode nonresponses as missing.
			qui	ds	meal_together*
			foreach	var	in	`r(varlist)'	{
				replace	`var'=.d	if	`var'==8
				replace	`var'=.r	if	`var'==9
				*replace	`var'=.n	if	`var'==0
			}
			
		*	Daycare variables	-	categorical
			qui	ds	child_daycare*
			label	value	`r(varlist)'	YNDRI
		
		*	Degree Completed	-	categorical
			
			*	High School Degree (head, spouse)
			qui	ds	hs_completed_head* hs_completed_spouse*
			recode	`r(varlist)'	(1 2=1)	(3=5)	//	Treat "GED" as "graduated from HS"
			
			qui	ds	hs_completed_head* hs_completed_spouse*	college_completed*	college_comp_spouse*
			label	value	`r(varlist)'	YNDRI
			

			
		*	Other degrees/certificates/vocational	-	categorical
			qui	ds	other_degree*
			label	value	`r(varlist)'	YNDRI
			
		*	Attended college
			qui	ds	attend_college*
			label	value	`r(varlist)'	YNDRI
			
		*	Location of eduction
			label	define	edu_location	1 	"United States only"	///
											2 	"Outside U.S. only"	///
											3 	"Both in the U.S. and outside"	///
											4 	"Education data last collected before 1997"	///
											5 	"Had no education"	///
											8 	"Don't Know"	///
											9 	"NA; refused"	///
											0 	"Inap.: no wife in FU"
			qui	ds	edu_in_US*
			label	value	`r(varlist)'	edu_location
			
		*	Years of college education - ordered categorical
		**	Recode nonresponses as missing, so we can treat it as continuous
			qui	ds	college_yrs_head* college_yrs_spouse*
			recode	`r(varlist)'	(8=.d)	(9=.r)
		
		*	Years of education - continuous (head), ordered categorical (spouse)
		**	Recode nonresponses as missing
		**	For spouse, need to be careful in treating "0".
			qui	ds	grade_comp_head_fam* grade_comp_spouse*
			recode	`r(varlist)'	(99=.n)
			
		*	Support from the outside FU	-	YNDR
			ds	sup_outside_FU*
			label	value	`r(varlist)'	YNDR
			
		*	Itemized deduction	-	YNDRI
			qui	ds	tax_item_deduct*
			label	value	`r(varlist)'	YNDRI
			
		*	Couple status
			label define	couple_status	1 	"Head with wife"	///
											2 	"Head with partner"	///
											3 	"Head (female) with husband"	///
											4 	"Head with first-year cohabitor" ///
											5 	"Head only in FU"
			label values	couple_status*	couple_status
			
		*	Change in Head/Spouse	-	YesNo
		**	Need to recode 1999/2001 spouse file to be compatible with the other years
			recode	spouse_new1999 spouse_new2001	(0=5)
			label values	head_status*	spouse_new*	yesno5
			
		*	Alcohol & Smoke (head/spouse)	-	YNDRI
			label value	alcohol_head* alcohol_spouse*	smoke_head* smoke_spouse*	YNDRI
			
		*	# of drink (head/spouse)	-	ordered categorical (1999-2003), continuous (2005-)
			
			*	1999-2003
			label	define	num_drink_cat	1 	"Less than one a day"	///
											2 	"1-2 a day"	///
											3 	"3-4 a day"	///
											4 	"5 or more a day"	///
											8 	"DK"	///
											9 	"NA; refused"	///
											0 	"Inap.: head does not drink alcoholic beverages"
			label	value	num_drink_head1999-num_drink_head2003 num_drink_spouse1999-num_drink_spouse2003		num_drink_cat
			
			*	2005-2017
			qui	ds	num_drink_head2005-num_drink_head2017 num_drink_spouse2005-num_drink_spouse2017
			recode	`r(varlist)'	(98=.d)	(99=.r)
			
		*	#	of smoke (head/spouse)	-	continuous
			qui	ds	num_smoke*
			recode	`r(varlist)'	(998=.d)	(999=.r)
		
		*	Disability	-	categorical
			qui	ds	phys_disab*
			label	values	`r(varlist)'	YNDRI
			
		*	Housing status	-	categorical
			label	define	housing_status	1	"Owns a house"	5	"Rent"	8	"Neither"
			qui	ds	housing_status*
			label value	`r(varlist)'	housing_status
			
		*	Elderly	Meal Assistance	-	categorical
			label	values	elderly_meal*	YNDRI
			
		*	Retirement Plan (head/spouse)	-	cateogorical
			label	values	retire_plan*	YNDRI
			
		*	Annuities/IRA	-	categorical
			label	values	annuities_IRA*	YNDR
			
		*	Veterans (head/spouse)	-	categorical
			label	values	veteran*	YNDRI
			
		*	Employment Status (head/spouse)
			label	define	emp_status	0	"Inapp"	///
										1 	"Working now"	///
										2 	"Temporal leave"	///
										3 	"Looking for work, unemployed"	///
										4 	"Retired"	///
										5 	"Disabled"	///
										6 	"Keeping house"	///
										7 	"Student"	///
										8 	"Other"	///
										98 	"Don't KNow'"	///
										99 	"NA; refused"
			label	values	emp_status*	emp_status
			
	}
		
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