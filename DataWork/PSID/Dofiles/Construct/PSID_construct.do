
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_construct
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Feb 08, 2016, by Seungmin Lee (slee31@worldbank.org)
	
	IDS VAR:    	x11101ll         // Uniquely identifies households (update for your project)

	DESCRIPTION: 	Construct PSID Data for analyses
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Data cleaning
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID Cleaned Data
			
	OUTPUTS: 		* Constructed

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
		SECTION 1: Pool out variables of interest from multiple waves
	****************************************************************/	
	
	*	2017 Cross-individual data
	use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
		*	Generate a single ID variable
		generate	x11101ll=(ER30001*1000)+ER30002
		
		tempfile	Ind
		save		`Ind'
		
	*	Pull out variables of interest from multiple waves
	** ("psidtools" command must be installed.). It should be installed when "PSID_MasterDofile" is executed.
	
		*	Weights
		
			*	Family Weight (longitudinal)
			psid use || fam_weight_long [99]ER16518 [01]ER20394 [03]ER24179 [05]ER28078 ///
										[07]ER41069 [09]ER47012 [11]ER52436 ///
										[13]ER58257 [15]ER65492 [17]ER71570	///
						using "${PSID_dtRaw}/Main", keepnotes // design(any)
						
			*	Individual weight (longitudinal)
			psid add || ind_weight_long [99]ER33546 [01]ER33637 [03]ER33740 [05]ER33848 ///
										[07]ER33950 [09]ER34045 [11]ER34154 ///
										[13]ER34268 [15]ER34413 [17]ER34650		///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes
						
			*	Individual weight (cross-sectional)
			psid add || ind_weight_cross	[99]ER33547 [01]ER33639 [03]ER33742 [05]ER33849 ///
											[07]ER33951 [09]ER34046 [11]ER34155 ///
											[13]ER34269 [15]ER34414 [17]ER34651	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
		*	Family Composition
		
			*	# of people in FU
			psid add || num_in_FU 	[99]ER13009 [01]ER17012 [03]ER21016 [05]ER25016 ///
									[07]ER36016 [09]ER42016 [11]ER47316 [13]ER53016 [15]ER60016 [17]ER66016	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Family Composition			
			psid add || fam_comp_change 	[99]ER13008A [01]ER17007 [03]ER21007 [05]ER25007 ///
											[07]ER36007 [09]ER42007 [11]ER47307 [13]ER53007	///
											[15]ER60007 [17]ER66007	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
		
		*	Expenditures
		
			*	Total family food expenditure (Home + Away + Delivered)
			psid add || food_exp_tot 	[99]ER16515A1 [01]ER20456A1 [03]ER24138A1 [05]ER28037A1 ///
										[07]ER41027A1 [09]ER46971A1 [11]ER52395A1 [13]ER58212A1 ///
										[15]ER65410 [17]ER71487	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Family food expenditure (At home)
			psid add || food_exp_home 	[99]ER16515A2 [01]ER20456A2 [03]ER24138A2 [05]ER28037A2 ///
										[07]ER41027A2 [09]ER46971A2 [11]ER52395A2 [13]ER58212A2 ///
										[15]ER65411 [17]ER71488	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Family food expenditure (away)
			psid add || food_exp_away	[99]ER16515A3 [01]ER20456A3 [03]ER24138A3 [05]ER28037A3 ///
										[07]ER41027A3 [09]ER46971A3 [11]ER52395A3 [13]ER58212A3 ///
										[15]ER65412 [17]ER71489	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Family food expenditure (delivered)
			psid add || food_exp_delivered 	[99]ER16515A4 [01]ER20456A4 [03]ER24138A4 [05]ER28037A4 ///
											[07]ER41027A4 [09]ER46971A4 [11]ER52395A4 [13]ER58212A4 ///
											[15]ER65413 [17]ER71490	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes
						
		*	Income
		
			*	Total family income
			psid add || fam_income_tot 	[99]ER16462 [01]ER20456 [03]ER24099 [05]ER28037 [07]ER41027 ///
										[09]ER46935 [11]ER52343 [13]ER58152 [15]ER65349 [17]ER71426	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
		*	Food security (available from '99-'03, '15-'17)

			*	Food security score (raw, household)
			psid add || fs_hh_raw [99]ER14331S [01]ER18470S [03]ER21735S [15]ER60797 [17]ER66845	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes
						
			*	Food security score (scale, houseohld)
			psid add || fs_hh_scale [99]ER14331T [01]ER18470T [03]ER21735T [15]ER60798 [17]ER66846	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Food security category (household)
			psid add || fs_hh_cat [99]ER14331U [01]ER18470U [03]ER21735U [15]ER60799 [17]ER66847	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Food security score (raw, children)
			psid add || fs_child_raw [99]ER14331V [01]ER18470V [03]ER21735V [15]ER60800 [17]ER66848		///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Food security score (scale, children)
			psid add || fs_child_scale [99]ER14331W [01]ER18470W [03]ER21735W [15]ER60801 [17]ER66849	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Food security category (children)
			psid add || fs_child_cat  	[99]ER14331X [01]ER18470X [03]ER21735X [15]ER60802 [17]ER66850	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
		*	Food assistance
		
			*	Received Elderly meal
			psid add || food_elderly_meal  	[99]ER16416 [01]ER20362 [03]ER24067 [05]ER25637 [07]ER36655 ///
											[09]ER42674 [11]ER47990 [13]ER53702 [15]ER60717 [17]ER66764	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes
						
			*	Received WIC meal
			psid add || food_WIC_received	[99]ER16421 [01]ER20367 [03]ER24072 [05]ER25633 [07]ER36651 ///
											[09]ER42670 [11]ER47988 [13]ER53700 [15]ER60715 [17]ER66762	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
			
			*	Received school meal (breakfast) ('99-'11)
			psid add || food_school_breakfast	[99]ER16419 [01]ER20365 [03]ER24070 [05]ER25627 [07]ER36632 ///
												[09]ER42651 [11]ER47969	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Received school meal (lunch) ('99-'11)
			psid add || food_school_lunch	[99]ER16418 [01]ER20364 [03]ER24069 [05]ER25626 [07]ER36631 ///
											[09]ER42650 [11]ER47968	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 	
						
			*	Received school meal (breakfast or lunch) ('13-'17)
			psid add || food_school_any	[13]ER53680 [15]ER60695 [17]ER66742	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
			*	Received food stamp (last year)
			psid add || food_stamp_1yr	[99]ER14255 [01]ER18386 [03]ER21652 [05]ER25654 [07]ER36672 ///
										[09]ER42691 [11]ER48007 [13]ER53704 [15]ER60719 [17]ER66766	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes
						
			*	Received food stamp (2 years ago)
			psid add || food_stamp_2yr	[99]ER14240 [01]ER18370 [03]ER21636 [05]ER25638 [07]ER36656 ///
										[09]ER42675	[11]ER47991 [13]ER53703 [15]ER60718 [17]ER66765	///
						using "E:\Box\2nd year paper\PSID_TEST\Output", keepnotes 
						
	*	Additional cleaning before reshaping to long format
	
		*	Merge child free school meal variables
		forvalues	year=1999(2)2011	{
			generate	food_school_any`year'=99
			replace	food_school_any`year'=1	if	food_school_breakfast`year'==1 & food_school_lunch`year'!=1	//	Breakfast only
			replace	food_school_any`year'=2	if	food_school_breakfast`year'!=1 & food_school_lunch`year'==1	//	Lunch only
			replace	food_school_any`year'=3	if	food_school_breakfast`year'==1 & food_school_lunch`year'==1	//	Both
			replace	food_school_any`year'=5	if	food_school_breakfast`year'==5 & food_school_lunch`year'==5	//	Neither
			
			replace	food_school_any`year'=8	if	food_school_breakfast`year'==8 & food_school_lunch`year'==8	//	DK
			
			replace	food_school_any`year'=9	if	food_school_breakfast`year'==9 & food_school_lunch`year'==9	//	NA; refused
			replace	food_school_any`year'=0	if	food_school_breakfast`year'==0 & food_school_lunch`year'==0	//	No children
			
		}
						
		drop	food_school_lunch*	food_school_breakfast*
		
		*	Generate per capita and quantiles
		
		forvalues	year=1999(2)2017	{
			
			*	Per capita
			generate	fam_income_pc`year'	=	fam_income_tot`year'/num_in_FU`year'
			generate	food_exp_pc`year'	=	food_exp_tot`year'/num_in_FU`year'
			
			*	Quantile
			xtile	fam_income_pc_qt`year'	=	fam_income_pc`year', n(10)	//	per capita income
			xtile	food_exp_pc_qt`year'	=	food_exp_pc`year',	n(10)	//	per capita food expenditure
			
			if	inrange(`year',1999,2003) | inrange(`year',2015,2017)	{
				xtile	fs_hh_scale_qt`year'	=	fs_hh_scale`year',	n(10)	//	food security scale
			}
		}
	
		
		
	/****************************************************************
		SECTION 2: Re-shape into long format
	****************************************************************/
						
	*	Re-shape it and define the data as panel data
	psid long
	xtset x11101ll wave, delta(2)

	*	Import variables needed for survey design setting
	merge	m:1	x11101ll	using	`Ind', assert(2 3) keep(3) keepusing(ER31996 ER31997) nogen
	
	*	Rename & re-label variables
				
		label	var	wave	"Wave"
		isid	x11101ll	wave
		label	variable	x11102 "Interview No."
		
	*	Additional cleaning after reshaping

		*	Generate per capita variables
			
			/*
			*	Income
			loc	var	fam_income_pc
			generate	`var'	=	fam_income_tot/num_in_FU
			label	var	`var'	"Household income per capita"
			
			*	Food expenditure
			loc	var	food_exp_pc
			generate	`var'	=	food_exp_tot/num_in_FU
			label	var	`var'	"Food expenditure per capita"
			*/
			
		*	Recode variables for descriptive analyses
			
			*	Food security score (-9 is replaced with missing)
			replace	fs_child_raw=. 		if	fs_child_raw==-9
			replace	fs_child_scale=.	if	fs_child_scale==-9
			
			replace	fs_child_cat	=.n	if	fs_child_cat==0	//	No Child(N/A)
			
			
			*	Elderly food
			loc	var	food_elderly_meal
			replace	`var'	=	.d	if	`var'==8
			replace	`var'	=	.r	if	`var'==9
			replace	`var'	=	.	if	`var'==0
			replace	`var'	=	0	if	`var'==5
			
			*	WIC
			loc	var	food_WIC_received
			replace	`var'	=	.d	if	`var'==8
			replace	`var'	=	.r	if	`var'==9
			replace	`var'	=	.	if	`var'==0
			replace	`var'	=	0	if	`var'==5
			
			*	Free or reduced school meal
			loc	var	food_school_any
			replace	`var'	=	.d	if	`var'==8
			replace	`var'	=	.r	if	`var'==9
			replace	`var'	=	.	if	inlist(`var',0,99)
			replace	`var'	=	0	if	`var'==5
			replace	`var'	=	1	if	inrange(`var',1,3)
			
			*	Food Stamp (last year)
			loc	var	food_stamp_1yr
			replace	`var'	=	.d	if	`var'==8
			replace	`var'	=	.r	if	`var'==9
			replace	`var'	=	.	if	`var'==0
			replace	`var'	=	0	if	`var'==5
			
			*	Food Stamp (2 years ago)
			loc	var	food_stamp_2yr
			replace	`var'	=	.d	if	`var'==8
			replace	`var'	=	.r	if	`var'==9
			replace	`var'	=	.	if	`var'==0
			replace	`var'	=	0	if	`var'==5
	
		*	Variable Labeling

			*	Food security category (Household)
			label define	fs_hh_cat	1	"High FS"	2	"Marginal FS"	3	"Low FS"	4	"Very Low FS", replace
			label	val	fs_hh_cat fs_hh_cat
			
			label	define	fs_child_cat	1	"High FS"	2	"Low FS"	3	"Very Low FS"
			label	val	fs_child_cat	fs_child_cat
			
			label	var	fam_income_pc	"Family income per capita"
			label	var	food_exp_pc		"Family food expenditure per capita"
	

	
/****************************************************************
		SECTION X: Save and Exit
	****************************************************************/
	
	
	* Make dta
	notes	drop _dta
	notes:	PSID_interm / created by `name_do' - `c(username)' - `c(current_date)' ///
			PSID data constructed for analyses.
	notes:	Only individuals appear in all waves are included.
	

	* Git branch info
	stgit9 
	notes : PSID_interm / Git branch `r(branch)'; commit `r(sha)'.
	
	
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
	save	"${PSID_dtInt}/PSID_interm.dta", replace
	
	/*
	* Save log
	cap file		close _all
	cap log			close
	copy			"${bl_do_cleaning}/logs/`name_do'.smcl" ///
					"${bl_do_cleaning}/logs/archive/`name_do' - `c(current_date)' - `c(username)'.smcl", replace
	*/
	
	* Exit	
	exit

