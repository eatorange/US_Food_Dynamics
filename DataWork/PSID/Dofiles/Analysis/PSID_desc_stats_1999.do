
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_desc_stats_1999
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Feb 18, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	FUID         // Uniquely identifies family (update for your project)

	DESCRIPTION: 	Generate descriptives stats(tables, plots)
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Descriptive Stats
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID 1999 Constructed (family)
					${PSID_dtInt}/PSID_const_1999_fam.dta
					
					* PSID 1999 Constructed (individual)
					${PSID_dtInt}/PSID_const_1999_ind.dta
			
	OUTPUTS: 		* Graphs & Tables

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
	version			14

	* Set basic memory limits
	set maxvar 		32767
	set matsize		11000

	* Set default options
	set more		off
	pause			on
	set varabbrev	off
	
	* Filename and log
	loc	name_do	PSID_descriptive_stats
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doAnl}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 3: Summary stats 
		**	This section will be moved to another file later
	****************************************************************/		
	
	*	Individual-level summary stats
	use	"${PSID_dtInt}/PSID_const_1999_ind.dta",	clear
	
		*	Define a matrix where descriptive stats will be stored
		mat	define		desc_stats	=	nullmat(desc_stats)
	
		*	Sample Composition
		svy: tab sample_source, count cellwidth(12) format(%12.2g)
		
		*	Age
			
			*	Overall
			svy: mean ER33504	//	Mean, standard error, confidence interval
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER33504, p(25 50 75 90 95)	//	Percentile
			*mat	desc_stats	=	nullmat(desc_stats)	\	e(_N)[1,1], e(b)[1,1]
			
			*	By Source (SRC, SEO, Immgrant Refresher)
			svy: mean ER33504, over(sample_source)	//	Mean, standard error, confidence interval
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER33504, p(25 50 75 90 95) over(sample_source)	//	Percentile
			*mat	desc_stats	=	nullmat(desc_stats)	\	e(_N)[1,1], e(b)[1,1]
			
		*	Gender
			
			*	Overall
			svy: proportion	ER32000
			
			*	By Source
			svy: proportion	ER32000, over(sample_source)
			mat list e(_N_subp)
		
		*	Education attained
			
			*	Overall
			svy: mean ER33516	//	Mean, standard error, confidence interval
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER33516, p(25 50 75 90 95)	//	Percentile
			
			*	By sample
			svy: mean ER33516, over(sample_source)	//	Mean, standard error, confidence interval
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER33516, p(25 50 75 90 95) over(sample_source)	//	Percentile
		
	
	*	Family_level
	use	"${PSID_dtInt}/PSID_const_1999_fam.dta", clear
	
		*	Sample Composition
		svy: tab sample_source, count cellwidth(12) format(%12.2g)
		
		*	Age	(Head)
			
			*	Overall
			svy: mean	ER13010
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER13010, p(25 50 75 90 95)	//	Percentile
			
			*	By sample
			svy: mean	ER13010, over(sample_source)
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER13010, p(25 50 75 90 95) over(sample_source)	//	Percentile
		
		*	Gender (Head)
			
			*	Overall
			svy: proportion	ER13011
			
			*	By sample
			svy: proportion	ER13011, over(sample_source)
			mat list e(_N)
			mat list e(_N_subp)
		
		*	Family Size
			
			*	Overall
			svy: mean	ER13009
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER13009, p(25 50 75 90 95)	//	Percentile
			
			*	By sample
			svy: mean	ER13009, over(sample_source)
			mat	define	result=r(table)
			mat list e(_N)
			mat list e(_N_subp)
			estat sd	//	Standard deviation
			epctile ER13009, p(25 50 75 90 95)	over(sample_source) //	Percentile
			
		*	Location
			
			*	Overall
			svy: proportion	ER16430
			
			*	By sample
			svy: proportion	ER16430, over(sample_source)
			mat list e(_N)
			mat list e(_N_subp)
		
		*	Ethnicity (Head)

			*	Overall
			svy: proportion	ER15932
			
			*	By sample
			svy: proportion	ER15932, over(sample_source)
			mat list e(_N)
			mat list e(_N_subp)
		
		*	Race (Head)
	
			*	Overall
			svy: proportion	ER15928
			
			*	By sample
			svy: proportion	ER15928, over(sample_source)
			mat list e(_N)
			mat list e(_N_subp)