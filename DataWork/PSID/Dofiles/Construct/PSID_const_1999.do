
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_const_1999
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Feb 17, 2020, by Seungmin Lee (slee31@worldbank.org)
	
	IDS VAR:    	ER13002         // 1999 Family ID

	DESCRIPTION: 	Construct PSID 1999 sample for basic analyses
		
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
		SECTION 1: Construct 1999 PSID data(family/individual)
	****************************************************************/	
	
	*	Individual file
	use	"${PSID_dtInt}/PSID_clean_1999_ind.dta", clear
	svyset	ER31997 [pweight=ER33547], strata(ER31996)	//	Define as a survey data. Individual cross-sectional weight
		
		*	Integer part of survey weight
		*	This integer weight can be used as a frequency weight. For more information, please find the following sources
		*	Heeringa, West and Berglund (2010, pages 121-122)
		*	Applied Survey Data Analysis (https://stats.idre.ucla.edu/stata/seminars/applied-svy-stata13/)
			
		gen	ER33547_int	=	int(ER33547)
		gen	ER33546_int	=	int(ER33546)
		
		*	Age Distribution
			loc	var	age_dist
			cap	drop	`var'
			gen		`var'=. //
			replace	`var'=1	if	inrange(ER33504,0,17)
			replace	`var'=2	if	inrange(ER33504,18,29)
			replace	`var'=3	if	inrange(ER33504,30,44)
			replace	`var'=4	if	inrange(ER33504,45,64)
			replace	`var'=5	if	ER33504>=65 & !mi(ER33504)
			lab	var	`var'	"Distribution of Age"
		
		*	Education
			*	High School Graduate
			gen		hs_graduate	=.
			replace	hs_graduate	=0	if	inrange(ER33516,0,11)
			replace	hs_graduate	=1	if	ER33516>=12	&	!mi(ER33516)
			
			*	Bachelor's degree
			gen		bachelor_degree	=.
			replace	bachelor_degree	=0	if	inrange(ER33516,0,15)
			replace	bachelor_degree	=1	if	ER33516>=16	&	!mi(ER33516)
			
			* Distribution
			local	var	edu_dist
			capture	drop	`var'
			gen	`var'=.
			replace	`var'=1	if	inrange(ER33516,0,11)
			replace	`var'=2	if	inrange(ER33516,12,13)
			replace	`var'=3	if	inrange(ER33516,14,15)
			replace	`var'=4	if	ER33516>=16 & !mi(ER33516)
		
		*	Save
		tempfile	indiv_1999
		save		`indiv_1999'
	
	*	Family File
	
	use	"${PSID_dtInt}/PSID_clean_1999_fam.dta", clear	//	Family data
		
		*	Sample source
		gen		sample_source=.
		replace	sample_source=1	if	ER13019<3000	//	SRC
		replace	sample_source=2	if	inrange(ER13019,5000,7000)	//	SEO
		replace	sample_source=3	if	inrange(ER13019,3001,3511)	//	Immigrant Refresher
		
		label	define	sample_source		1	"SRC(Survey Research Center)"	///
											2	"SEO(Survey of Economic Opportunity)"	///
											3	"Immigrant Refresher"
		label	values	sample_source		sample_source
		label	variable	sample_source	"Source of Sample"
		
		*	Age of Household Head
		gen		age_head_cat=1	if	inrange(ER13010,16,24)
		replace	age_head_cat=2	if	inrange(ER13010,25,34)
		replace	age_head_cat=3	if	inrange(ER13010,35,44)
		replace	age_head_cat=4	if	inrange(ER13010,45,54)
		replace	age_head_cat=5	if	inrange(ER13010,55,64)
		replace	age_head_cat=6	if	inrange(ER13010,65,150)
		label	var	age_head_cat	"Age of Household Head (category)"
		
		*	Region (for comparison with 1999 census)
		gen	interview_region_census=.
		replace	interview_region_census=1	if	inlist(ER13004,46,36,4,25,11,49,27,43,5,2,30,50,51)
		replace	interview_region_census=2	if	inlist(ER13004,33,40,26,15,24,14,22,48,12,13,34,21)
		replace	interview_region_census=3	if	ER16430==3
		replace	interview_region_census=4	if	ER16430==1
		replace	interview_region_census=0	if	mi(interview_region_census)
		
		label	define	region_census	1	"West"	2	"Midwest"	3	"South"	4	"Northeast"	0	"N/A"
		label	values	interview_region_census	region_census
		
		*	Education
		gen		edu_years_head_cat=1	if	inrange(ER16516,1,11)
		replace	edu_years_head_cat=2	if	inrange(ER16516,12,12)
		replace	edu_years_head_cat=3	if	inrange(ER16516,13,15)
		replace	edu_years_head_cat=4	if	ER16516>=16 & !mi(ER16516)
		
		label	define	edu_head_cat	1	"Less than HS"	2	"HS"	3	"Some College"	4	"College Degree"
		label 	values	edu_years_head_cat	edu_head_cat
		label	var	edu_years_head_cat	"Years of Household Head Education (category)"
		

		*	Import survey variables from individual data
		merge	1:m	FUID	using	`indiv_1999', keepusing(ER31996 ER31997) keep(3) nogen assert(3)
		duplicates drop
	
		*svyset	ER31997 [pweight=ER16518], strata(ER31996)	//	Define as a survey data, using cross-sectional family weight
		svyset	ER31997 [pweight=ER16518], strata(ER31996)	//	Define as a survey data, using longitudinal family weight, as PSID officially suggested to use longitudinal weight for family cross-sectional analysis. Also some descriptive statistics match with PSID official statistics under this setting (ex. race of head: 12.6%, weighted)
			
			*	Construct integer part of suvey weight to be used as a frequency weight
			*gen	ER16519_int	=	int(ER16519)
			gen	ER16518_int	=	int(ER16518)
		
		*	Save
		tempfile	family_1999
		save		`family_1999'

	
	/****************************************************************
		SECTION 2: Pool out PSID-generated data including splitoff status
	****************************************************************/		
	
	/*
	*	PSID-generated data including splitoff status
	use	"${PSID_dtRaw}/Customized/Splitoff_1968_1999/Family_splitoff_1968_1999.dta", clear
	
	*	Before beginning, generate an indicator stating 1999 sample
	generate	sample_1999	=	1	if	!mi(ER13002)
	lab	var		sample_1999	"Family surveyed in 1999"
	
		
		*	Sample composition
		gen	composition_1999	=.
		
			*	Refresher
				
				*	In 1997, 441 imigrant families were added as a refresher. They have 1968 family ID 3001-3441
				count	if	inrange(ER10005G,3001,3441)	&	!mi(ER10002)
				assert	r(N)==441
				replace	composition_1999	=	4	if	inrange(ER10005G,3001,3441)	&	sample_1999==1
			
				*	In 1999, 70 immigrant families were added as a refresher. They have 1968 Family Id 3442-3511
				count	if	inrange(ER13019,3442,3511)	&	sample_1999==1
				assert	r(N)==70
				replace	composition_1999	=	4	if	inrange(ER13019,3442,3511)	&	sample_1999==1
				
			*	Split-off
			gen		total_splitoff	=	.
			replace	total_splitoff	=.n	if	composition_1999	==	4
			
			*	We will start from 1999
				
				*	Splitoff in 1999
				replace	total_splitoff	=	total_splitoff+1	if	ER13005E==2
				
				
		*/	
		
		*	First find original sample households
		/*
		local	splitoff_vars	V909 V1106 V1806 V2407 V3007 V3407 V3807 V4307 V5207 V5707 ///
								V6307 V6907 V7507 V8207 V8807 V10007 V11107 V12507 V13707 V14807 ///
								V16307 V17707 V19007 V20307 V21606 ER2005F ER5005F ER7005F ER10005F ER13005E
								
		egen	x=rowmax(`splitoff_vars')
		*/
	
	/****************************************************************
		SECTION X: Save and Exit
	****************************************************************/
	
	
	* Make dta
		
		*	Family data
		notes	drop _dta
		notes:	PSID_const_1999_fam / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID data constructed for analyses.
		*notes:	Only individuals appear in all waves are included.
		

		* Git branch info
		stgit9 
		notes : PSID_const_1999_fam / Git branch `r(branch)'; commit `r(sha)'.
	
	
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
		save	"${PSID_dtInt}/PSID_const_1999_fam.dta", replace
	
		*	Individual data
		use	`indiv_1999', clear
		merge	m:1	FUID	using	"${PSID_dtInt}/PSID_const_1999_fam.dta", keepusing(sample_source) nogen assert(3)	//	Merge with survey design variables
		
		notes	drop _dta
		notes:	PSID_const_1999_ind / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID data constructed for analyses.
		notes:	Only individuals living with family during 1999 are included
		

		* Git branch info
		stgit9 
		notes : PSID_const_1999_ind / Git branch `r(branch)'; commit `r(sha)'.
	
	
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
		save	"${PSID_dtInt}/PSID_const_1999_ind.dta", replace
	
	/*
		* Save log
		cap file		close _all
		cap log			close
		copy			"${bl_do_cleaning}/logs/`name_do'.smcl" ///
						"${bl_do_cleaning}/logs/archive/`name_do' - `c(current_date)' - `c(username)'.smcl", replace
		*/
	
	* Exit	
	exit
	
