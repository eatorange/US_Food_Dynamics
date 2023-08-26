
	/*****************************************************************
	PROJECT: 		Food Security Dynamics in the United States, 2001-2017
					
	TITLE:			FSD_clean
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Jun 29, 2023, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	x11101ll        // Individual identifier

	DESCRIPTION: 	Clean individual-level data from 1999 to 2017
		
	ORGANIZATION:	0 -	Preamble
					1 - Import PSID raw data
					2 - Import external (BEA, USDA) data
					3 -	Clean PSID variable labels and values
					
	INPUTS: 		*	PSID Individual & family & wealth raw data
					${FSD_dtRaw}/PSID/fam????er.dta
					${FSD_dtRaw}/PSID/wlth????.dta
					${FSD_dtRaw}/PSID/ind2017er.dta
					
					*	Regional Price Parities data from the BEA
					${FSD_dtRaw}/BEA/Regional_Price_Parities.xls
					
					*	Cost of Food Plan data from the USDA
					${FSD_dtRaw}/USDA/Cost of Food Reports/Food Plans_Cost of Food Reports.xlsx
										
	OUTPUTS: 		*	PSID - Individual-level data, raw aggregated from 1999 to 2017
					${FSD_dtInt}/PSID_raw.dta
					
					*	PSID - Individual-level data with basic cleaning.
					${FSD_dtInt}/PSID_cleaned_ind.dta
					
					*	Regional Price Parities, from 2008 to 2020
					${FSD_dtInt}/RPP_2008_2020.dta
					
					*	Thrifty Food Plan cost data, from 1999 to 2017
					${FSD_dtInt}/foodcost_????.dta (1999 to 2017)

	NOTE:			*
	******************************************************************/

	/****************************************************************
		SECTION 0: Preamble			 									
	****************************************************************/		 
		
	/* 0.1 - Environment setup */
	
	* Clear all stored values in memory from previous projects
	clear			all
	*cap	log			close

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
	*loc	name_do	PSID_cleaned_ind
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	*cd	"${PSID_doCln}"
	*stgit9
	*di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	*di "Git branch `r(branch)'; commit `r(sha)'."
	
	local	import_PSID		1
	local	import_external	1
	local	clean_PSID		1
	
	
	/****************************************************************
		SECTION 1: Retrieve variables on interest and construct a panel data
	****************************************************************/	
	
	
	*	Construct from existing PSID
	*	I found that "psid add" has a critical problem; when using "psid add" command, it imports the values of only strongly balanced observation. In other words, if an observation has a missing interview in any of the wave, that observation gets missing values for ALL the waves.
	*	Therefore, I will use "psid use" command only for each variable and merge them. This takes more time and requires more work than using "psid add", but still takes much less time than manual cleaning
	
	if	`import_PSID==1'	{
		
		* Import relevant variables using "psidtools" command	
					
			*	Survey Weights
			
				*	Longitudinal, individual-level
				psid use || weight_long_ind 	[99]ER33546 [01]ER33637 [03]ER33740 [05]ER33848 [07]ER33950 [09]ER34045 [11]ER34154 [13]ER34268 [15]ER34413 [17]ER34650	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
				
				tempfile	weight_long_ind
				save		`weight_long_ind'
				
				*	Cross-sectional, individual-level
				psid use || weight_cross_ind [99]ER33547 [01]ER33639 [03]ER33742 [05]ER33849 [07]ER33951 [09]ER34046 [11]ER34155 [13]ER34269 [15]ER34414 [17]ER34651	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
				
				tempfile	weight_cross_ind
				save		`weight_cross_ind'
				
				*	Longitudinal, family-level
				psid use || weight_long_fam [99]ER16518 [01]ER20394 [03]ER24179 [05]ER28078 [07]ER41069 [09]ER47012 [11]ER52436 [13]ER58257 [15]ER65492 [17]ER71570	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
				
				tempfile	weight_long_fam
				save		`weight_long_fam'
			
			*	Respondent (ind)
			psid use || respondent	[99]ER33511 [01]ER33611 [03]ER33711 [05]ER33811 [07]ER33911 [09]ER34011 [11]ER34111 [13]ER34211 [15]ER34312 [17]ER34511	///
								using "${FSD_dtRaw}/PSID", design(any) clear
			tempfile	respondent_ind
			save		`respondent_ind'
								
			*	Relation to head (ind)
			psid use || relat_to_head [99]ER33503 [01]ER33603 [03]ER33703 [05]ER33803 [07]ER33903 [09]ER34003 [11]ER34103 [13]ER34203 [15]ER34303 [17]ER34503	///
								using "${FSD_dtRaw}/PSID", design(any) clear
								
			tempfile relat_to_head_ind
			save	`relat_to_head_ind'
			
			*	Month of the interview
			psid use || interview_month [99]ER13006 [01]ER17009 [03]ER21012 [05]ER25012 [07]ER36012 [09]ER42012 [11]ER47312 [13]ER53012 [15]ER60012 [17]ER66012 	///
								using "${FSD_dtRaw}/PSID", design(any) clear
								
			tempfile interview_month
			save	`interview_month'
			
			*	Day of the interview
			psid use || interview_day [99]ER13007 [01]ER17010 [03]ER21013 [05]ER25013 [07]ER36013 [09]ER42013 [11]ER47313 [13]ER53013 [15]ER60013 [17]ER66013	///
								using "${FSD_dtRaw}/PSID", design(any) clear
								
			tempfile interview_day
			save	`interview_day'
			
			
			
			*	Age (indiv)
			psid use || age_ind  [99]ER33504 [01]ER33604 [03]ER33704 [05]ER33804 [07]ER33904 [09]ER34004 [11]ER34104 [13]ER34204 [15]ER34305 [17]ER34504	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
			
			qui ds age_ind*
			foreach var in `r(varlist)'	{
				replace	`var'=.d	if	inlist(`var',999)	//	NA/DK
				replace	`var'=.n	if	inlist(`var',0)		//	Inappropriate (Latino-sample, non-response, etc.)
			}
			
			tempfile	main_age_ind
			save		`main_age_ind'
			
			*	Years of education (indiv)
			psid use || edu_years  [99]ER33516 [01]ER33616 [03]ER33716 [05]ER33817 [07]ER33917 [09]ER34020 [11]ER34119 [13]ER34230 [15]ER34349 [17]ER34548	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			qui ds edu_years*
			foreach var in `r(varlist)'	{
				replace	`var'=.d	if	inlist(`var',98,99)	//	NA/DK
				replace	`var'=.n	if	inlist(`var',0)	//	Inap
			}
			
			
			tempfile	edu_years_ind
			save		`edu_years_ind'
			
			*	Age of head (fam)
			psid use || age_head_fam  [99]ER13010 [01]ER17013 [03]ER21017 [05]ER25017 [07]ER36017 [09]ER42017 [11]ER47317 [13]ER53017 [15]ER60017 [17]ER66017	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	age_head_fam
			save		`age_head_fam'
			
			*	Region
			psid use || region_residence [99]ER16430 [01]ER20376 [03]ER24143 [05]ER28042 [07]ER41032 [09]ER46974 [11]ER52398 [13]ER58215 [15]ER65451 [17]ER71530	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	region_residence
			save		`region_residence'
			
			*	Urbanicity (1999-2013)
			psid use || urbanicity [99]ER16431C [01]ER20377C [03]ER24144A [05]ER28043A [07]ER41033A [09]ER46975A [11]ER52399A [13]ER58216	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	urbanicity
			save		`urbanicity'
			
			*	Metropolitan Area (2015-2017), can be combined with the Urbanicity variable above.
			psid use || metro_area [15]ER65452 [17]ER71531	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	metro_area
			save		`metro_area'
			
			*	Race of head (fam)
			psid use || race_head_fam  [99]ER15928 [01]ER19989 [03]ER23426 [05]ER27393 [07]ER40565 [09]ER46543 [11]ER51904 [13]ER57659 [15]ER64810 [17]ER70882	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	race_head_fam
			save		`race_head_fam'
			
			*	Splitoff indicator (fam)
			psid use || splitoff_indicator [99]ER13005E [01]ER17006 [03]ER21005 [05]ER25005 [07]ER36005 [09]ER42005 [11]ER47305 [13]ER53005 [15]ER60005 [17]ER66005	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	splitoff_indicator_fam
			save		`splitoff_indicator_fam'
			
			*	# of splitoff family from this family (fam)
			psid use || num_split_fam [99]ER16433 [01]ER20379 [03]ER24156 [05]ER28055 [07]ER41045 [09]ER46989 [11]ER52413 [13]ER58231 [15]ER65467 [17]ER71546	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	num_splitoff_fam
			save		`num_splitoff_fam'
			
			*	Main family ID for this splitoff (fam)
			psid use || main_fam_ID [99]ER16434 [01]ER20380 [03]ER24157 [05]ER28056 [07]ER41046 [09]ER46990 [11]ER52414 [13]ER58232 [15]ER65468 [17]ER71547	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	main_fam_ID
			save		`main_fam_ID'
			
			*	Total Family Income (fam)
			psid use || total_income_fam [99]ER16462 [01]ER20456 [03]ER24099 [05]ER28037 [07]ER41027 [09]ER46935 [11]ER52343 [13]ER58152 [15]ER65349 [17]ER71426	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	total_income_fam
			save		`total_income_fam'
			
			*	Martial Status of Head (fam)
			psid use || marital_status_fam  [99]ER13021 [01]ER17024 [03]ER21023 [05]ER25023 [07]ER36023 [09]ER42023 [11]ER47323 [13]ER53023 [15]ER60024 [17]ER66024	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear							
		
			tempfile	marital_status_fam
			save		`marital_status_fam'
			
			
			* # of people in FU (fam)
			psid use || num_FU_fam  [99]ER13009 [01]ER17012 [03]ER21016 [05]ER25016 [07]ER36016 [09]ER42016 [11]ER47316 [13]ER53016 [15]ER60016 [17]ER66016	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear			
			
			
			tempfile	num_FU_fam
			save		`num_FU_fam'
				
			
			*	# of Children in HH (fam)
			psid use || num_child_fam [99]ER13013 [01]ER17016 [03]ER21020 [05]ER25020 [07]ER36020 [09]ER42020 [11]ER47320 [13]ER53020 [15]ER60021 [17]ER66021	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear			
			
			
			tempfile	num_child_fam
			save		`num_child_fam'
			
			*	Gender of Household Head (fam)
			psid use || gender_head_fam  [99]ER13011 [01]ER17014 [03]ER21018 [05]ER25018 [07]ER36018 [09]ER42018 [11]ER47318 [13]ER53018 [15]ER60018 [17]ER66018	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear			
			
			
			tempfile	gender_head_fam
			save		`gender_head_fam'
			
			*	Grades Househould head completed (fam)
			psid use || grade_comp_head_fam  [99]ER16516 [01]ER20457 [03]ER24148 [05]ER28047 [07]ER41037 [09]ER46981 [11]ER52405 [13]ER58223 [15]ER65459 [17]ER71538	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	grade_comp_head_fam
			save		`grade_comp_head_fam'
			
			*	State of Residence (fam)
			psid use || state_resid_fam  [99]ER13004 [01]ER17004 [03]ER21003 [05]ER25003 [07]ER36003 [09]ER42003 [11]ER47303 [13]ER53003 [15]ER60003 [17]ER66003	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	state_resid_fam
			save		`state_resid_fam'
			
			*	Food security score (raw)
			psid use || fs_raw_fam	[99]ER14331S [01]ER18470S [03]ER21735S [15]ER60797 [17]ER66845	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	fs_raw_fam
			save		`fs_raw_fam'
			
			*	Food security score (scale)
			psid use || fs_scale_fam	[99]ER14331T [01]ER18470T [03]ER21735T [15]ER60798 [17]ER66846	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
								
			//	Round the digits
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
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	fs_cat_fam
			save		`fs_cat_fam'
			
			*	Food Stamp Usage (2 years ago)
			psid use || food_stamp_used_2yr	[99]ER14240 [01]ER18370 [03]ER21636 [15]ER60718 [17]ER66765	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	food_stamp_used_2yr
			save		`food_stamp_used_2yr'
			
			*	Food Stamp Usage (previous year)
			psid use || food_stamp_used_1yr [99]ER14255 [01]ER18386 [03]ER21652 [05]ER25654 [07]ER36672 [09]ER42691 [11]ER48007 [13]ER53704 [15]ER60719 [17]ER66766	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	food_stamp_used_1yr
			save		`food_stamp_used_1yr'
			
			*	Food Stamp Usage (Current year)
			psid use || food_stamp_used_0yr	[99]ER14270 [01]ER18402 [03]ER21668 [05]ER25670 [07]ER36688	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	food_stamp_used_0yr
			save		`food_stamp_used_0yr'
			
				
			*	Food Stamp Usage (last month)
			psid use || food_stamp_used_1month	[09]ER42707 [11]ER48023 [13]ER53720 [15]ER60735 [17]ER66782	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	food_stamp_used_1month
			save		`food_stamp_used_1month'
			
			*	Food Stamp Value (amount) (previous year)
			psid use || food_stamp_value_1yr	[99]ER14256 [01]ER18387 [03]ER21653 [05]ER25655 [07]ER36673 [09]ER42692 [11]ER48008 [13]ER53705 [15]ER60720 [17]ER66767	///
					using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
					
			tempfile	food_stamp_value_1yr
			save		`food_stamp_value_1yr'
			
			*	Food Stamp Value (amount) (current year, cumulative)
			psid use || food_stamp_value_0yr	[99]ER14285 [01]ER18417 [03]ER21682 [05]ER25684 [07]ER36702	///
					using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
					
			tempfile	food_stamp_value_0yr
			save		`food_stamp_value_0yr'
			
			*	Food Stamp Value (amount) (last month)
			psid use || food_stamp_value_1month	[09]ER42709 [11]ER48025 [13]ER53722 [15]ER60737 [17]ER66784	///
					using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
					
			tempfile	food_stamp_value_1month
			save		`food_stamp_value_1month'
							
							
			*	Food Stamp Value (time unit)  (previous year)
			psid use || food_stamp_freq_1yr	[99]ER14257 [01]ER18388 [03]ER21654 [05]ER25656 [07]ER36674 [09]ER42693 [11]ER48009 [13]ER53706 [15]ER60721 [17]ER66768	///
					using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
					
			tempfile	food_stamp_freq_1yr
			save		`food_stamp_freq_1yr'
			
			*	Food Stamp Value (time unit)  (current year)
			psid use || food_stamp_freq_0yr	[99]ER14286 [01]ER18418 [03]ER21683 [05]ER25685 [07]ER36703	///
					using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
					
			tempfile	food_stamp_freq_0yr
			save		`food_stamp_freq_0yr'
			
			
			*	Child received free or reduced cost meal (lunch)
			psid use || child_lunch_assist	[99]ER16418 [01]ER20364 [03]ER24069 [05]ER25626 [07]ER36631 [09]ER42650 [11]ER47968	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	child_lunch_assist_fam
			save		`child_lunch_assist_fam'
			
			*	Child received free or reduced cost meal (breakfast)
			psid use || child_bf_assist	[99]ER16419 [01]ER20365 [03]ER24070 [05]ER25627 [07]ER36632 [09]ER42651 [11]ER47969	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	child_bf_assist_fam
			save		`child_bf_assist_fam'
			
			*	Child received free or reduced cost meal (breakfast and/or lunch)
			psid use || child_meal_assist	[13]ER53680 [15]ER60695 [17]ER66742	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	child_meal_assist_fam
			save		`child_meal_assist_fam'
			
			*	WIC received last years
			psid use || WIC_received_last	[99]ER16421 [01]ER20367 [03]ER24072 [05]ER25633 [07]ER36651 [09]ER42670 [11]ER47988 [13]ER53700 [15]ER60715 [17]ER66762	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	WIC_received_last
			save		`WIC_received_last'
			
			*	Family composition change
			psid use || family_comp_change	[99]ER13008A [01]ER17007 [03]ER21007 [05]ER25007 [07]ER36007 [09]ER42007 [11]ER47307 [13]ER53007 [15]ER60007 [17]ER66007	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	family_comp_change
			save		`family_comp_change'
			
			*	Total food expenditure
			psid use || food_exp_total	[99]ER16515A1 [01]ER20456A1 [03]ER24138A1 [05]ER28037A1 [07]ER41027A1 [09]ER46971A1 [11]ER52395A1 [13]ER58212A1 [15]ER65410 [17]ER71487	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	food_exp_total
			save		`food_exp_total'
			
			*	Height of the respondent (feet part)
			psid use || height_feet	[99]ER15553 [01]ER19718 [03]ER23133 [05]ER27110 [07]ER38321 [09]ER44294 [11]ER49633 [13]ER55381 [15]ER62503 [17]ER68568	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	height_feet
			save		`height_feet'
			
			*	Height of the respondent (inch part)
			psid use || height_inch	[99]ER15554 [01]ER19719 [03]ER23134 [05]ER27111 [07]ER38322 [09]ER44295 [11]ER49634 [13]ER55382 [15]ER62504 [17]ER68569	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	height_inch
			save		`height_inch'
			
			*	Height of the respondent (meters)
			psid use || height_meter	[11]ER49635 [13]ER55383 [15]ER62505 [17]ER68570	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	height_meter
			save		`height_meter'
			
			*	Weight of the respondent (lbs)
			psid use || weight_lbs	[99]ER15552 [01]ER19717 [03]ER23132 [05]ER27109 [07]ER38320 [09]ER44293 [11]ER49631 [13]ER55379 [15]ER62501 [17]ER68566	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	weight_lbs
			save		`weight_lbs'
			
			*	Weight of the respondent (kg)
			psid use || weight_kg	[11]ER49632 [13]ER55380 [15]ER62502 [17]ER68567	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	weight_kg
			save		`weight_kg'
			
			*	Finished high school or GED (Head)
			psid use || hs_completed_head	 [99]ER15937 [01]ER19998 [03]ER23435 [05]ER27402 [07]ER40574 [09]ER46552 [11]ER51913 [13]ER57669 [15]ER64821 [17]ER70893	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	hs_completed_head
			save		`hs_completed_head'
			
			*	Finished college (Head)
			psid use || college_completed	[99]ER15952 [01]ER20013 [03]ER23450 [05]ER27417 [07]ER40589 [09]ER46567 [11]ER51928 [13]ER57684 [15]ER64836 [17]ER70908	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	college_completed
			save		`college_completed'
			
			*	Highest college degree completed (Head)
			psid use || college_degree_type	[99]ER15953 [01]ER20014 [03]ER23451 [05]ER27418 [07]ER40590 [09]ER46568 [11]ER51929 [13]ER57685 [15]ER64837 [17]ER70909	///
								using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
			
			tempfile	college_degree_type
			save		`college_degree_type'
					
			
		*	# of days/week eat meal together
			psid use || meal_together  [99]ER14231 [01]ER18361 [03]ER21627 [05]ER25624 [07]ER36629 [09]ER42648 [11]ER47966 [13]ER53678 [15]ER60693 [17]ER66740	///
				using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
					
			tempfile	meal_together
			save		`meal_together'

*	Child in daycare
			psid use || child_daycare_any [99]ER14233 [01]ER18363 [03]ER21629 [05]ER25629 [07]ER36647 [09]ER42666 [11]ER47984 [13]ER53696 [15]ER60711 [17]ER66758	///
			using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
			tempfile	child_daycare_any
			save		`child_daycare_any'

*	Daycare participates in FSP
			psid use || child_daycare_FSP  	[99]ER14235 [01]ER18365 [03]ER21631 [05]ER25631 [07]ER36649 [09]ER42668 [11]ER47986 [13]ER53698 [15]ER60713 [17]ER66760	///
				using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
					
			tempfile	child_daycare_FSP
			save		`child_daycare_FSP'

*	Offers snack in daycare
			psid use || child_daycare_snack  	[99]ER14235 [01]ER18365 [03]ER21631 [05]ER25631 [07]ER36649 [09]ER42668 [11]ER47986 [13]ER53698 [15]ER60713 [17]ER66760	///
				using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
					
			tempfile	child_daycare_snack
			save		`child_daycare_snack'

*	Age (spouse)
psid use || age_spouse  	[99]ER13012 [01]ER17015 [03]ER21019 [05]ER25019 [07]ER36019 [09]ER42019 [11]ER47319 [13]ER53019 [15]ER60019 [17]ER66019	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	age_spouse
		save		`age_spouse'

*	Ethnicity (head)
psid use || ethnicity_head  	[99]ER15932 [01]ER19993 [03]ER23430 [05]ER27397 [07]ER40569 [09]ER46547 [11]ER51908 [13]ER57663 [15]ER64815 [17]ER70887	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	ethnicity_head
		save		`ethnicity_head'

*	Ethnicity (spouse)
psid use || ethnicity_spouse 	[99]ER15840 [01]ER19901 [03]ER23338 [05]ER27301 [07]ER40476 [09]ER46453 [11]ER51814 [13]ER57553 [15]ER64676 [17]ER70749	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	ethnicity_spouse
		save		`ethnicity_spouse'

*	Race (spouse)
psid use || race_spouse 	 [99]ER15836 [01]ER19897 [03]ER23334 [05]ER27297 [07]ER40472 [09]ER46449 [11]ER51810 [13]ER57549 [15]ER64671 [17]ER70744	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	race_spouse
		save		`race_spouse'
		
psid use || other_degree_head  [99]ER15958 [01]ER20019 [03]ER23455 [05]ER27423 [07]ER40595 [09]ER46573 [11]ER51934 [13]ER57690 [15]ER64850 [17]ER70922	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	other_degree_head
		save		`other_degree_head'
		
psid use || other_degree_spouse 	[99]ER15865 [01]ER19926 [03]ER23363 [05]ER27327 [07]ER40502 [09]ER46479 [11]ER51840 [13]ER57580 [15]ER64711 [17]ER70784	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	other_degree_spouse
		save		`other_degree_spouse'
	
*	Attended college (head)	
psid use || attend_college_head  [99]ER15948 [01]ER20009 [03]ER23446 [05]ER27413 [07]ER40585 [09]ER46563 [11]ER51924 [13]ER57680 [15]ER64832 [17]ER70904	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	attend_college_head
		save		`attend_college_head'
		
*	Attended college (spouse)	
psid use || attend_college_spouse 	[99]ER15856 [01]ER19917 [03]ER23354 [05]ER27317 [07]ER40492 [09]ER46469 [11]ER51830 [13]ER57570 [15]ER64693 [17]ER70766	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	attend_college_spouse
		save		`attend_college_spouse'

*	Completed college (spouse)
psid use || college_comp_spouse	[99]ER15860 [01]ER19921 [03]ER23358 [05]ER27321 [07]ER40496 [09]ER46473 [11]ER51834 [13]ER57574 [15]ER64697 [17]ER70770	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	college_comp_spouse
		save		`college_comp_spouse'
		
*	Location of education (head)		
psid use || edu_in_US_head	 [99]ER15936 [01]ER19997 [03]ER23434 [05]ER27401 [07]ER40573 [09]ER46551 [11]ER51912 [13]ER57668 [15]ER64820 [17]ER70892	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	edu_in_US_head
		save		`edu_in_US_head'

*	Location of education (spouse)
psid use || edu_in_US_spouse	[99]ER15936 [01]ER19997 [03]ER23434 [05]ER27401 [07]ER40573 [09]ER46551 [11]ER51912 [13]ER57668 [15]ER64820 [17]ER70892	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	edu_in_US_spouse
		save		`edu_in_US_spouse'

*	Years of college completed (head)
psid use || college_yrs_head	 [99]ER15951 [01]ER20012 [03]ER23449 [05]ER27416 [07]ER40588 [09]ER46566 [11]ER51927 [13]ER57683 [15]ER64835 [17]ER70907	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	college_yrs_head
		save		`college_yrs_head'
		
	
*	Years of college completed (spouse)
psid use || college_yrs_spouse	 [99]ER15859 [01]ER19920 [03]ER23357 [05]ER27320 [07]ER40495 [09]ER46472 [11]ER51833 [13]ER57573 [15]ER64696 [17]ER70769	///
	using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	college_yrs_spouse
		save		`college_yrs_spouse'

		*	Grades Househould head's spouse completed (fam)
		psid use || grade_comp_spouse [99]ER16517 [01]ER20458 [03]ER24149 [05]ER28048 [07]ER41038 [09]ER46982 [11]ER52406 [13]ER58224 [15]ER65460 [17]ER71539	///
									using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
				
		tempfile	grade_comp_spouse
		save		`grade_comp_spouse'
				
*	Finished high school or GED (Spouse)
		psid use || hs_completed_spouse	 [99]ER15845 [01]ER19906 [03]ER23343 [05]ER27306 [07]ER40481 [09]ER46458 [11]ER51819 [13]ER57559 [15]ER64682 [17]ER70755	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	hs_completed_spouse
		save		`hs_completed_spouse'
		
*	Child care expenditure
		psid use || child_exp_total	[99]ER16515D1 [01]ER20456D1 [03]ER24138D1 [05]ER28037D2 [07]ER41027D2 [09]ER46971D2 [11]ER52395D2 [13]ER58212D2 [15]ER65438 [17]ER71516	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	child_exp_total
		save		`child_exp_total'
		 	
*	Clothing expenditure
		psid use || cloth_exp_total	 	[05]ER28037E1 [07]ER41027E1 [09]ER46971E1 [11]ER52395E1 [13]ER58212E1 [15]ER65446 [17]ER71525	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	cloth_exp_total
		save		`cloth_exp_total'
		
*	Support outside FU
		psid use || sup_outside_FU	  [99]ER14976 [01]ER19172 [03]ER22537 [05]ER26518 [07]ER37536 [09]ER43527 [11]ER48852 [13]ER54595 [15]ER61706 [17]ER67759 ///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	sup_outside_FU
		save		`sup_outside_FU'
		
*	Education expenditure
		psid use || edu_exp_total 	[99]ER16515C9 [01]ER20456C9 [03]ER24138C9 [05]ER28037D1 [07]ER41027D1 [09]ER46971D1 [11]ER52395D1 [13]ER58212D1 [15]ER65437 [17]ER71515	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	edu_exp_total
		save		`edu_exp_total'
		
*	Health expenditure
		psid use || health_exp_total 	[99]ER16515D2 [01]ER20456D2 [03]ER24138D2 [05]ER28037D3 [07]ER41027D3 [09]ER46971D3 [11]ER52395D3 [13]ER58212D3 [15]ER65439 [17]ER71517	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	health_exp_total
		save		`health_exp_total'
		
*	Housing expenditure
		psid use || house_exp_total 	[99]ER16515A5 [01]ER20456A5 [03]ER24138A5 [05]ER28037A5 [07]ER41027A5 [09]ER46971A5 [11]ER52395A5 [13]ER58212A5 [15]ER65414 [17]ER71491	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear		
		
		tempfile	house_exp_total
		save		`house_exp_total'
		
*	Itemizied Deduction (Tax)
		psid use || tax_item_deduct 	 [99]ER14973 [01]ER19161 [03]ER22534 [05]ER26515 [07]ER37533 [09]ER43524 [11]ER48849 [13]ER54592 [15]ER61703 [17]ER67756	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
							
		tempfile	tax_item_deduct
		save		`tax_item_deduct'
							
*	Property Tax
		psid use || property_tax 	 	[99]ER16515A8 [01]ER20456A8 [03]ER24138A8 [05]ER28037A8 [07]ER41027A8 [09]ER46971A8 [11]ER52395A8 [13]ER58212A8 [15]ER65417 [17]ER71495	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	property_tax
		save		`property_tax'
							
*	Transport Expenditure Tax
		psid use || transport_exp 	 	[99]ER16515B6 [01]ER20456B6 [03]ER24138B6 [05]ER28037B7 [07]ER41027B7 [09]ER46971B7 [11]ER52395B7 [13]ER58212B7 [15]ER65425 [17]ER71503	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
		
		tempfile	transport_exp
		save		`transport_exp'
		
*	Couple_status
		psid use || couple_status 	  [99]ER16425 [01]ER20371 [03]ER24152 [05]ER28051 [07]ER41041 [09]ER46985 [11]ER52409 [13]ER58227 [15]ER65463 [17]ER71542	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear	
		
		tempfile	couple_status
		save		`couple_status'
		
*	Head status
		psid use || head_status 	 [99]ER15890 [01]ER19951 [03]ER23388 [05]ER27352 [07]ER40527 [09]ER46504 [11]ER51865 [13]ER57618 [15]ER64769 [17]ER70841	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	head_status
		save		`head_status'
							
							
*	New spouse (need to merge "no wife" and "not new" in 1999/2001)
		psid use || spouse_new 	 	[99]ER15805 [01]ER19866 [03]ER23303 [05]ER27263 [07]ER40438 [09]ER46410 [11]ER51771 [13]ER57508 [15]ER64630 [17]ER70703	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	spouse_new
		save		`spouse_new'
		
		
*	All other debts
**	This variable exists only untill 2009. Since 2011, debts are splitted into sub-categories (credit card, student loan, etc.).
**	To use this variable for longer time series, make sure to aggregate those sub-categories properly by checking the questionnaire.
		psid use || other_debts 	 [99]ER15031 [01]ER19227 [03]ER22622 [05]ER26603 [07]ER37621 [09]ER43612	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
		
		tempfile	other_debts
		save		`other_debts'
		
*	Drink alcohol (head)
		psid use || alcohol_head 	 	 	[99]ER15550 [01]ER19715 [03]ER23130 [05]ER27105 [07]ER38316 [09]ER44289 [11]ER49627 [13]ER55375 [15]ER62497 [17]ER68562	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	alcohol_head
		save		`alcohol_head'
		
*	Drink alcohol (spouse)
		psid use || alcohol_spouse 	 	 	[99]ER15658 [01]ER19823 [03]ER23257 [05]ER27228 [07]ER39413 [09]ER45386 [11]ER50745 [13]ER56491 [15]ER63613 [17]ER69689	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	alcohol_spouse
		save		`alcohol_spouse'
		
*	# of drink/week (head)
		psid use || num_drink_head	 	 	[99]ER15551 [01]ER19716 [03]ER23131 [05]ER27107 [07]ER38318 [09]ER44291 [11]ER49629 [13]ER55377 [15]ER62499 [17]ER68564	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	num_drink_head
		save		`num_drink_head'
		
*	# of drink/week (spouse)
		psid use || num_drink_spouse	 	 [99]ER15659 [01]ER19824 [03]ER23258 [05]ER27230 [07]ER39415 [09]ER45388 [11]ER50747 [13]ER56493 [15]ER63615 [17]ER69691	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	num_drink_spouse
		save		`num_drink_spouse'
		
*	Smoke (head)
		psid use || smoke_head	 	 [99]ER15543 [01]ER19708 [03]ER23123 [05]ER27098 [07]ER38309 [09]ER44282 [11]ER49620 [13]ER55368 [15]ER62490 [17]ER68555	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	smoke_head
		save		`smoke_head'
		
*	Smoke (spouse)
		psid use || smoke_spouse 	 [99]ER15651 [01]ER19816 [03]ER23250 [05]ER27221 [07]ER39406 [09]ER45379 [11]ER50738 [13]ER56484 [15]ER63606 [17]ER69682	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	smoke_spouse
		save		`smoke_spouse'
		
*	Daily Smoke (head)
		psid use || num_smoke_head	  [99]ER15544 [01]ER19709 [03]ER23124 [05]ER27099 [07]ER38310 [09]ER44283 [11]ER49621 [13]ER55369 [15]ER62491 [17]ER68556	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	num_smoke_head
		save		`num_smoke_head'
		
*	Daily Smoke (spouse)
		psid use || num_smoke_spouse  [99]ER15652 [01]ER19817 [03]ER23251 [05]ER27222 [07]ER39407 [09]ER45380 [11]ER50739 [13]ER56485 [15]ER63607 [17]ER69683	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	num_smoke_spouse
		save		`num_smoke_spouse'
		
*	Physical Disability (head)
		psid use || phys_disab_head  [99]ER15449 [01]ER19614 [03]ER23014 [05]ER26995 [07]ER38206 [09]ER44179 [11]ER49498 [13]ER55248 [15]ER62370 [17]ER68424	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	phys_disab_head
		save		`phys_disab_head'
		
*	Physical Disability (spouse)
		psid use || phys_disab_spouse  [99]ER15557 [01]ER19722 [03]ER23141 [05]ER27118 [07]ER39303 [09]ER45276 [11]ER50616 [13]ER56364 [15]ER63486 [17]ER69551	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	phys_disab_spouse
		save		`phys_disab_spouse'
		
*	Housing status
		psid use || housing_status [99]ER13040 [01]ER17043 [03]ER21042 [05]ER25028 [07]ER36028 [09]ER42029 [11]ER47329 [13]ER53029 [15]ER60030 [17]ER66030	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	housing_status
		save		`housing_status'
		
*	Elderly meal
		psid use || elderly_meal 	[99]ER16416 [01]ER20362 [03]ER24067 [05]ER25637 [07]ER36655 [09]ER42674 [11]ER47990 [13]ER53702 [15]ER60717 [17]ER66764	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	elderly_meal
		save		`elderly_meal'
		
*	Retirement plan (head)
		psid use || retire_plan_head 	[99]ER15156 [01]ER19327 [03]ER22722 [05]ER26703 [07]ER37739 [09]ER43712 [11]ER49057 [13]ER54813 [15]ER61933 [17]ER67987	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	retire_plan_head
		save		`retire_plan_head'
		
*	Retirement plan (spouse)
		psid use || retire_plan_spouse	  [99]ER15302 [01]ER19470 [03]ER22866 [05]ER26847 [07]ER37971 [09]ER43944 [11]ER49276 [13]ER55029 [15]ER62150 [17]ER68204	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	retire_plan_spouse
		save		`retire_plan_spouse'
		
*	Private annuities or IRA
		psid use || annuities_IRA 	[99]ER15012 [01]ER19208 [03]ER22588 [05]ER26569 [07]ER37587 [09]ER43578 [11]ER48903 [13]ER54653 [15]ER61764 [17]ER67817	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	annuities_IRA
		save		`annuities_IRA'
		
*	Veteran (head)
		psid use || veteran_head 	[99]ER15935 [01]ER19996 [03]ER23433 [05]ER27400 [07]ER40572 [09]ER46550 [11]ER51911 [13]ER57666 [15]ER64818 [17]ER70890	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	veteran_head
		save		`veteran_head'
		
*	Veteran (spouse)
		psid use || veteran_spouse 	 	[99]ER15843 [01]ER19904 [03]ER23341 [05]ER27304 [07]ER40479 [09]ER46456 [11]ER51817 [13]ER57556 [15]ER64679 [17]ER70752	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	veteran_spouse
		save		`veteran_spouse'
		
*	Total wealth (including home equity)
		psid use || wealth_total 	  [99]S417 [01]S517 [03]S617 [05]S717 [07]S817 [09]ER46970 [11]ER52394 [13]ER58211 [15]ER65408 [17]ER71485	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	wealth_total
		save		`wealth_total'
		
		
*	Employment Status (head)
		psid use || emp_status_head 	  [99]ER13205 [01]ER17216 [03]ER21123 [05]ER25104 [07]ER36109 [09]ER42140 [11]ER47448 [13]ER53148 [15]ER60163 [17]ER66164	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	emp_status_head
		save		`emp_status_head'
		
		
*	Employment Status (spouse)
		psid use || emp_status_spouse 	 	 [99]ER13717 [01]ER17786 [03]ER21373 [05]ER25362 [07]ER36367 [09]ER42392 [11]ER47705 [13]ER53411 [15]ER60426 [17]ER66439	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	emp_status_spouse
		save		`emp_status_spouse'
		
*	Retirement year (head)
		psid use || retire_year_head 	 	[99]ER13208 [01]ER17219 [03]ER21126 [05]ER25107 [07]ER36112 [09]ER42143 [11]ER47451 [13]ER53151 [15]ER60166 [17]ER66167	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	retire_year_head
		save		`retire_year_head'
		
*	Food expenditure recall period (at home, no food stamp)
		psid use || foodexp_recall_home_nostamp 	 	[99]ER14296 [01]ER18432 [03]ER21697 [05]ER25699 [07]ER36717 [09]ER42723 [11]ER48039 [13]ER53736 [15]ER60751 [17]ER66798 	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	foodexp_recall_home_nostamp
		save		`foodexp_recall_home_nostamp'
		
*	Food expenditure recall period (at home, food stamp)
		psid use || foodexp_recall_home_stamp 	 	[99]ER14289 [01]ER18422 [03]ER21687 [05]ER25689 [07]ER36707 [09]ER42713 [11]ER48029 [13]ER53726 [15]ER60741 [17]ER66788	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	foodexp_recall_home_stamp
		save		`foodexp_recall_home_stamp'
		
*	Food expenditure recall period (away from home, no food stamp)
		psid use || foodexp_recall_away_nostamp 	 	[99]ER14301 [01]ER18439 [03]ER21704 [05]ER25706 [07]ER36724 [09]ER42730 [11]ER48046 [13]ER53743 [15]ER60758 [17]ER66805	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	foodexp_recall_away_nostamp
		save		`foodexp_recall_away_nostamp'
		
*	Food expenditure recall period (away from home, food stamp)
		psid use || foodexp_recall_away_stamp 	 	[99]ER14294 [01]ER18429 [03]ER21694 [05]ER25696 [07]ER36714 [09]ER42720 [11]ER48036 [13]ER53733 [15]ER60748 [17]ER66795	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	foodexp_recall_away_stamp
		save		`foodexp_recall_away_stamp'
		
*	Food expenditure recall period (delivered, no food stamp)
		psid use || foodexp_recall_deliv_nostamp 	 	[99]ER14299 [01]ER18436 [03]ER21701 [05]ER25703 [07]ER36721 [09]ER42727 [11]ER48043 [13]ER53740 [15]ER60755 [17]ER66802	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	foodexp_recall_deliv_nostamp
		save		`foodexp_recall_deliv_nostamp'
		
*	Food expenditure recall period (delivered, food stamp)
		psid use || foodexp_recall_deliv_stamp 	 	[99]ER14292 [01]ER18426 [03]ER21691 [05]ER25693 [07]ER36711 [09]ER42717 [11]ER48033 [13]ER53730 [15]ER60745 [17]ER66792	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	foodexp_recall_deliv_stamp
		save		`foodexp_recall_deliv_stamp'
		
*	Mental health (emotional, nervous, or psychiatric problems)
		psid use || mental_problem 	 	[99]ER15494 [01]ER19659 [03]ER23059 [05]ER27045 [07]ER38256 [09]ER44229 [11]ER49562 [13]ER55311 [15]ER62433 [17]ER68487	///
							using "${FSD_dtRaw}/PSID", keepnotes design(any) clear
							
		tempfile	mental_problem
		save		`mental_problem'
		
		
	*	Lastly, prepare individual gender variable which cannot be imported using "psidtools" command below, as it is uniform across the wave.
	*	Individual gender variable will be used in constructing the thrifty food plan (TFP) variable
		use	"${FSD_dtRaw}/PSID/ind2017er.dta", clear
		gen	x11101ll	=	(ER30001*1000) + ER30002 // Personal identifier
		isid	x11101ll
		clonevar indiv_gender	=	ER32000	//	Gender variable
		
		tempfile indiv_gender
		save	 `indiv_gender'
		
		*	Merge individual cross-wave with family cross-wave
		use	`weight_long_ind', clear
		merge 1:1 x11101ll using `weight_cross_ind', keepusing(weight_cross_ind*) nogen assert(3)
		merge 1:1 x11101ll using `weight_long_fam', keepusing(weight_long_fam*) nogen assert(3)
		merge 1:1 x11101ll using `respondent_ind', keepusing(respondent*) nogen assert(3)
		merge 1:1 x11101ll using `interview_month', keepusing(interview_month*) nogen assert(3)
		merge 1:1 x11101ll using `interview_day', keepusing(interview_day*) nogen assert(3)
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
		merge 1:1 x11101ll using `food_stamp_used_0yr', keepusing(food_stamp_used_0yr*) nogen assert(3)
		merge 1:1 x11101ll using `food_stamp_used_1month', keepusing(food_stamp_used_1month*) nogen assert(3)
		merge 1:1 x11101ll using `food_stamp_value_1yr', keepusing(food_stamp_value_1yr*) nogen assert(3)
		merge 1:1 x11101ll using `food_stamp_value_0yr', keepusing(food_stamp_value_0yr*) nogen assert(3)
		merge 1:1 x11101ll using `food_stamp_value_1month', keepusing(food_stamp_value_1month*) nogen assert(3)
		merge 1:1 x11101ll using `food_stamp_freq_1yr', keepusing(food_stamp_freq_1yr*) nogen assert(3)
		merge 1:1 x11101ll using `food_stamp_freq_0yr', keepusing(food_stamp_freq_0yr*) nogen assert(3)
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
		merge 1:1 x11101ll using `indiv_gender', keepusing(indiv_gender) nogen assert(3)
		merge 1:1 x11101ll using `region_residence', keepusing(region_residence*) nogen assert(3)
		merge 1:1 x11101ll using `urbanicity', keepusing(urbanicity*) nogen assert(3)
		merge 1:1 x11101ll using `metro_area', keepusing(metro_area*) nogen assert(3)
		merge 1:1 x11101ll using `foodexp_recall_home_nostamp', keepusing(foodexp_recall_home_nostamp*) nogen assert(3)
		merge 1:1 x11101ll using `foodexp_recall_home_stamp', keepusing(foodexp_recall_home_stamp*) nogen assert(3)
		merge 1:1 x11101ll using `foodexp_recall_away_nostamp', keepusing(foodexp_recall_away_nostamp*) nogen assert(3)
		merge 1:1 x11101ll using `foodexp_recall_away_stamp', keepusing(foodexp_recall_away_stamp*) nogen assert(3)
		merge 1:1 x11101ll using `foodexp_recall_deliv_nostamp', keepusing(foodexp_recall_deliv_nostamp*) nogen assert(3)
		merge 1:1 x11101ll using `foodexp_recall_deliv_stamp', keepusing(foodexp_recall_deliv_stamp*) nogen assert(3)
		merge 1:1 x11101ll using `mental_problem', keepusing(mental_problem*) nogen assert(3)
		
					
		qui		compress
		save	"${FSD_dtInt}/PSID_raw.dta", replace
	}	
	
	/****************************************************************
		SECTION 2: Import external (BEA and USDA) data
	****************************************************************/	
	
	if	`import_external'==1	{
		
		*	External data
					
			*	Regional price parity (RPP)
			*	It will be imported into main data to adjust federal-level TFP cost.
			*	Source: https://www.bea.gov/data/prices-inflation/regional-price-parities-state-and-metro-area
					
			import	excel	"${FSD_dtRaw}/BEA/Regional_Price_Parities.xls", firstrow cellrange(A6) clear
			keep	if	Description=="RPPs: All items"
			drop	if	GeoName=="United States"
			
			*	Generate metro/non-metro indicator
			gen		resid_metro=0
			replace	resid_metro=1	if	regexm(GeoName,"Metropolitan Portion")
			
			gen		resid_nonmetro=0
			replace	resid_nonmetro=1	if	regexm(GeoName,"Nonmetropolitan Portion")
			
			*	Replace name
			replace	GeoName	=	subinstr(GeoName, " (Metropolitan Portion)","",.)
			replace	GeoName	=	subinstr(GeoName, " (Nonmetropolitan Portion)","",.)
			replace	GeoName="D.C."	if	GeoName=="District of Columbia"
					
			drop	GeoFips	LineCode Description
		
			rename	GeoName	state_str
			rename (E-Q) RPP#, addnumber(2008)
			
			reshape	long	RPP, i(state_str	resid_metro	resid_nonmetro)	j(year2)
			
			
			*	Replace zero-RPP in some non-metropolitan area with non-zero indices from metropolitan area
			*	Some states (D.C., Delaware, RI, NJ) have zero RPP in non-metropolitan area (dunno why). Note that they use non-zero metropolitan RPP as state-level RPP.
			*	In our data, several observations belong to these metropolitan area, ending up their RPP being zero (thus their RPP-adjusted TFPP will be zero.)
			*	To avoid it, we import non-zero metropolitan RPP into zero non-metropolitan RPP (which is also used as state-level RPP) for these states.
			sort	state_str	year2	resid_metro	resid_nonmetro
			by		state_str	year2:	replace	RPP=RPP[_n+1]	if	RPP==0
			
			lab	var	RPP	"Regional Price Parity"		
			drop	if	inlist(year2,2008,2010,2012,2014,2016,2018,2019,2020)
			
			compress
			save	"${FSD_dtInt}/RPP_2008_2020.dta", replace
			
			
			
			*	Thrifty Food Plan (TFP) cost
			
			forvalues	year=2001(2)2017	{
				
				import excel "${FSD_dtRaw}/USDA/Cost of Food Reports/Food Plans_Cost of Food Reports.xlsx", sheet("thrifty_`year'") firstrow clear
						
				reshape long foodcost_, i(gender state age) j(month)
				
				isid	gender	age	state month

				rename	gender	indiv_gender
				rename	age		age_ind`year'
				rename	state	state_region_temp`year'
				rename	month	interview_month`year'
				rename	foodcost_	foodcost_monthly_`year'
				keep	indiv_gender	age_ind`year'	state_region_temp`year'	interview_month`year'	foodcost_monthly_`year'
				
				save	"${FSD_dtInt}/foodcost_`year'.dta", replace
						
			}
			
			
	}

	
	/****************************************************************
		SECTION 3: Clean PSID variable labels and values
	****************************************************************/	
	
	if	`clean_PSID'==1	{	
		
		use	"${FSD_dtInt}/PSID_raw.dta", clear
		
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
			qui	ds	age_head_fam1999-age_head_fam2017 age_spouse1999-age_spouse2017
			foreach	var in `r(varlist)'	{
				replace	`var'=.d	if	`var'==999
			}
			
			
			*	Marital status of head
			qui ds marital_status_fam1999-marital_status_fam2017
			foreach	var in `r(varlist)'	{
				replace	`var'=.d	if	`var'==8	//	DK
				replace	`var'=.n	if	`var'==9	//	NA, refused.
			}
			
			
			*	Grade completed of household head (fam)
			qui ds grade_comp_head_fam1999-grade_comp_head_fam2017 grade_comp_spouse1999-grade_comp_spouse2017
			foreach	var	in	`r(varlist)'	{
				replace	`var'=.n	if	`var'==99	//	NA/DK/Refuse (Recode it as they are continuous variables)
			}
			
			*	Food Stamp & WIC			
			qui ds	food_stamp_used_1yr*	
			lab	val	`r(varlist)'	YNDR
			
			qui ds	WIC_received_last*	
			lab	val	`r(varlist)'	YNDRI
			
			*	Food stamp value
			qui	ds	food_stamp_value_1yr1999-food_stamp_value_1yr2017	food_stamp_value_0yr1999-food_stamp_value_0yr2007 food_stamp_value_1month2009-food_stamp_value_1month2017
			foreach	var	in	`r(varlist)'	{
				
				replace	`var'=0	if	`var'==999998
				replace	`var'=0	if	`var'==999999
				
			}
			
			
			*	Location
			
				*	State of Residence
					label define	statecode	0	"Inap.: U.S. territory or foreign country"	99	"D.K; N.A"	///
												1	"Alabama"		2	"Arizona"			3	"Arkansas"	///
												4	"California"	5	"Colorado"			6	"Connecticut"	///
												7	"Delaware"		8	"D.C."				9	"Florida"	///
												10	"Georgia"		11	"Idaho"				12	"Illinois"	///
												13	"Indiana"		14	"Iowa"				15	"Kansas"	///
												16	"Kentucky"		17	"Louisiana"			18	"Maine"		///
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
			
				*	2005-2017
				label	define	race_05_17	1 	"White"	///
											2	"Black, African-American or Negro"	///
											3	"American Indian or Alaska Native"	///
											4	"Asian"	///
											5	"Native Hawaiian or Pacific Islander"	///
											7	"Other"	///
											9	"DK; NA; refused"	///
											0 	"Inap.: no wife in FU"

				*	Recode race variables to be compatible across the years
				
					*	In	1999-2003, (1) merge "Color other than black or white"	into "Other" (2) Merge "DK" into "NA;refused"	
						recode	race_head_fam1999 race_head_fam2001 race_head_fam2003	race_spouse1999-race_spouse2003	(6=7)	(8=9)	// (5=1)
					
					*	Replace "Latino origin" with other races, depending on their responses.
						foreach	race	in	race_head_fam1999	race_head_fam2001	race_head_fam2003	{
								replace	`race'	=	race_head_fam2005	if	`race'==5	//	Assign 2005 response to pre-2005 respones
							
						}
						foreach	race	in	race_spouse1999	race_spouse2001	race_spouse2003	{
								replace	`race'	=	race_head_fam2005	if	`race'==5	//	Assign 2005 response to pre-2005 respones
							
						}
						
					
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
			
			*	Food Security (FSSS)
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
												8	"Other"	///
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
			
			
			
	
	* Save
		
		notes	drop _dta
		notes:	PSID_cleaned_ind / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID individual data (wide-format) from 1999 to 2017
		

		* Git branch info
		*stgit9 
		*notes : PSID_cleaned_ind / Git branch `r(branch)'; commit `r(sha)'.

		qui		compress
		save	"${FSD_dtInt}/PSID_cleaned_ind.dta", replace
		
	}
		
		
	* Exit	
	exit