
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_clean_1999
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Feb 24, 2020, by Seungmin Lee (slee31@worldbank.org)
	
	IDS VAR:    	FUID         	// 1999 Family ID
					FUID & ER33502	// 1999 Individual ID

	DESCRIPTION: 	Clean individual and family data of 1999
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Data cleaning
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID 1999 Family dataset
					${PSID_dtRaw}/Main/fam1999er.dta
					
					* PSID Individual data
					${PSID_dtRaw}/Main/ind2017er.dta
					
	OUTPUTS: 	
					

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
	cd	"${PSID_doCln}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1: Clean 1999 PSID data(family/individual)
	****************************************************************/	
	
		
	*	Individual file
	use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
	
		*	ID
		clonevar	FUID	=	ER33501
		order	FUID
		*keep	if	FUID!=0	&	inrange(ER33502,1,20) //	Keep only individuals living together in 1999
		keep	if	FUID!=0	&	(ER33502!=0) //	New code, to be consistent with official PSID technical report. (sample size N=20515 matches)
	
		*	Age
		replace	ER33504	=.d	if	ER33504==999
	
		*	Gender
		replace	ER32000	=.n	if	ER32000==9
		label	define	gender	1	"Male"	2	"Female"
		label	values	ER32000	gender
		
		*	Education attained
		replace	ER33516=.n	if	inlist(ER33516,0,99)
		replace	ER33516=.d	if	ER33516==98
						
		*	Save
		tempfile	indiv_1999
		save		`indiv_1999'
		
		
	*	Family File
	
	use	"${PSID_dtRaw}/Main/fam1999er.dta", clear	//	Family data
	
		*	ID
		clonevar	FUID	=	ER13002
		order	FUID
		
		*	Age (Household Head)
		replace	ER13010	=.d	if	ER13010==999	//	Head age, N/A;DK
		replace	ER13012	=.d	if	ER13012==999	//	Wife age, N/A;DK
		replace	ER13012	=.n	if	ER13012==0		//	Wife age, No wife
		replace	ER13014	=.n	if	ER13014==0		//	No child
		
		*	Gender (Household Head)
		label values	ER13011	gender
		
		*	Family Size
		*	ER13009
		
		*	Child
		gen		has_child=1 if ER13013>0
		replace	has_child=0 if ER13013==0
		lab	var	has_child	"Family has a child"
		
		*	Education (head)
		replace	ER16516=.n	if	ER16516==99

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
				lab	val	ER13004 statecode
				
				*	Current State
				label	define	FIPScode	0	"Inap.: U.S. territory or foreign country"	99	"D.K; N.A"	///
											1	"Alabama"		2	"Alaska"			4	"Arizona"	///
											5	"Arkansas"	///
											6	"California"	8	"Colorado"			9	"Connecticut"	///
											10	"Delaware"		11	"D.C."				12	"Florida"	///
											13	"Georgia"		15	"Hawaii"	///
											16	"Idaho"			17	"Illinois"	///
											18	"Indiana"		19	"Iowa"				20	"Kansas"	///
											21	"Kentucky"		22	"Lousiana"			23	"Maine"		///
											24	"Maryland"		25	"Massachusetts"		26	"Michigan"	///
											27	"Minnesota"		28	"Mississippi"		29	"Missouri"	///
											30	"Montana"		31	"Nebraska"			32	"Nevada"	///
											33	"New Hampshire"	34	"New Jersey"		35	"New Mexico"	///
											36	"New York"		37	"North Carolina"	38	"North Dakota"	///
											39	"Ohio"			40	"Oklahoma"			41	"Oregon"	///
											42	"Pennsylvania"	44	"Rhode Island"		45	"South Carolina"	///
											46	"South Dakota"	47	"Tennessee"			48	"Texas"	///
											49	"Utah"			50	"Vermont"			51	"Virginia"	///
											53	"Washington"	54	"West Virginia"		55	"Wisconsin"	///
											56	"Wyoming"		
				lab	val	ER13005 FIPScode
				
				*	Interview region (consistent with state of residence)
				label	define	interview_region	1	"Northeast"	///
													2	"North Central"	///
													3	"South"	///
													4	"West"	///
													5	"Alaska, Hawaii"	///
													6	"Foreign Country"	///
													0	"NA"
				label	values	ER16430	interview_region
		
		*	Ethnicity
			
		label	define	ethnicity_1digit	1    "American"	///
											2    "Hyphenated American (e.g., African-American, Mexican-American)"	///
											3    "National origin (e.g., French, German [n.b. PA Dutch=German],Dutch, Iranian,  Scots-Irish)"	///
											4    "Nonspecific Hispanic identity (e.g., Chicano, Latino)"	///	
											5    "Racial (e.g., white or Caucasian, black)"	///
											6    "Religious (e.g., Jewish, Roman Catholic, Baptist)"	///
											7    "Other"	///
											9	"NA; DK"	///
											0	"Inap.: no wife in FU"
												
		label	val	ER15932	ER15840  ethnicity_1digit
		
		label	define	ethnicity_2digits	1	"American (meaning U.S.)"	///
												2	"American Indian, Eskimo, Aleut"	///
												3	"British:  English, Scottish, Irish, Welsh"	///
												4	"Western European"	///
												5	"Eastern European"	///
												6	"Northern European/Scandinavian"	///
												7	"Middle Eastern"	///
												8	"East Asian:  Chinese, Japanese, Korean"	///
												9	"South or Southeast Asian"	///
												10	"Pacific Islander:  Filipino, Indonesian"	///
												11	"Canadian"	///
												12	"Central American:  Nicaraguan, Mexican, etc."	///
												13	"Caribbean:  Cuban, Haitian, etc."	///
												14	"South American:  Peruvian, Chilean, etc."	///
												15	"African"	///
												16	"Oceania:  Australian, New Zealander, New Guinean"	///
												97	"Other"	///
												99	"NA, DK"	///
												0	"NAP: no second mention; one-digit ethnicity=1,4-7,9"
												
		label val	ER15841	ER15842	ER15933	ER15934	ethnicity_2digits
		
		*	Race
		label	define	race	1 	"White"	///
								2	"Black"	///
								3	"American Indian, Aleut, Eskimo"	///
								4	"Asian, Pacific Islander"	///
								5	"Mentions Latino origin or descent"	///
								6	"Mentions color other than black or white"	///
								7	"Other"	///
								8	"DK"	///
								9	"NA; refused"	///
								0 	"Inap.: no wife in FU"
		label	val	ER15928	ER15836	race	
		
		/*
		replace	ER15836=.d	if	ER15836==8
		replace	ER15836=.r	if	ER15836==9
		replace	ER15836=.n	if	ER15836==0
		
		replace	ER15928=.d	if	ER15928==8
		replace	ER15928=.r	if	ER15928==9
		*/
		
		*	Save
		tempfile	family_1999
		save		`family_1999'
		
	/****************************************************************
		SECTION X: Save and Exit
	****************************************************************/
	
	
	* Make dta
		
		*	Family data
		notes	drop _dta
		notes:	PSID_clean_1999_fam / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID data cleaned (1999 family).
		*notes:	Only individuals appear in all waves are included.
		

		* Git branch info
		stgit9 
		notes : PSID_clean_1999_fam / Git branch `r(branch)'; commit `r(sha)'.
	
	
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
		save	"${PSID_dtInt}/PSID_clean_1999_fam.dta", replace
	
		*	Individual data
		use	`indiv_1999', clear
		/*
		merge	m:1	FUID	using	"${PSID_dtInt}/PSID_clean_1999_fam.dta", keepusing(sample_source) nogen assert(3)	//	Merge with survey design variables
		*/
		notes	drop _dta
		notes:	PSID_clean_1999_ind / created by `name_do' - `c(username)' - `c(current_date)' ///
				PSID data cleaned.
		notes:	Only individuals living with family during 1999 are included
		

		* Git branch info
		stgit9 
		notes : PSID_clean_1999_ind / Git branch `r(branch)'; commit `r(sha)'.
	
	
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
		save	"${PSID_dtInt}/PSID_clean_1999_ind.dta", replace
	
	/*
		* Save log
		cap file		close _all
		cap log			close
		copy			"${bl_do_cleaning}/logs/`name_do'.smcl" ///
						"${bl_do_cleaning}/logs/archive/`name_do' - `c(current_date)' - `c(username)'.smcl", replace
		*/
	
	* Exit	
	exit
	
