
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_construct
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Feb 17, 2016, by Seungmin Lee (slee31@worldbank.org)
	
	IDS VAR:    	ER13002         // 1999 Family ID

	DESCRIPTION: 	Construct PSID 1999 sample for basic analyses
		
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
		SECTION 1: Open 1999 PSID data(family/individual)
	****************************************************************/	
	
	use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
	clonevar	FUID	=	ER33501
	keep	if	FUID!=0
	tempfile	indiv_1999
	save		`indiv_1999'
	
		*	Individual variable to import
		local	ID_vars			ER33502
		local	age_vars		ER33504
		local	martial_vars
		local	weight_vars		ER33546	ER33547
		local	emp_vars		ER33512
		local	educ_vars		ER33516
		local	splitoff_vars	ER33539	ER33540	ER33541
		local	follow_status	ER33542	
	
	use	"${PSID_dtRaw}/Main/fam1999er.dta", clear	//	Family data
	
	clonevar	FUID	=	ER13002
	tempfile	family_1999
	save		`family_1999'
	
	
	
	* merge	m:1	FUID	using	`family_1999'
	
		*	Demographics
		
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
			
			replace	ER15928=.d	if	ER15928==8
			replace	ER15928=.r	if	ER15928==9
			
			replace	ER15836=.d	if	ER15836==8
			replace	ER15836=.r	if	ER15836==9
			replace	ER15836=.n	if	ER15836==0
			
			
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
												
			label	val	ER15840 ER15932 ethnicity_1digit
			
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
		
			*	Age
			replace	ER13010	=.d	if	ER13010==999	//	Head age, N/A;DK
			replace	ER13012	=.d	if	ER13012==999	//	Wife age, N/A;DK
			replace	ER13012	=.n	if	ER13012==0		//	Wife age, No wife
			replace	ER13014	=.n	if	ER13014==0		//	No child
			
				
									
	
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
		SECTION 3: Summary stats 
		**	This section will be moved to another file later
	****************************************************************/		
	
	*	Age
		*	Household Head age
		summarize	ER13010, pweight=
	
	
	