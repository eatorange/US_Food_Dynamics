
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
		SECTION 1: Summary stats 
	****************************************************************/		
	
	*	Individual-level summary stats
	use	"${PSID_dtInt}/PSID_const_1999_ind.dta",	clear
	
		*	Keep relevant variables only
		local	ID_vars			FUID	ER33502
		local	age_vars		ER33504
		local	gender_var		ER32000
		local	educ_vars		ER33516	hs_graduate	bachelor_degree
		*local	martial_vars
		*local	emp_vars		ER33512
		local	splitoff_vars	ER33539	ER33540	ER33541
		local	follow_vars		ER33542
		local	sample_vars		sample_source
		local	weight_vars		ER33546	ER33547	ER33546_int	ER33547_int
		local	survey_vars		ER31996 ER31997
		
		keep	`ID_vars'	`age_vars'	`gender_var'	`weight_vars'	`educ_vars'	`splitoff_vars'	`follow_vars'	`sample_vars'	`survey_vars'
		
		*	Import variables from family data to be analyzed for comparison with census
		loc	import_vars	ER15928	interview_region_census
		merge m:1 FUID using "${PSID_dtInt}/PSID_const_1999_fam.dta", keepusing(`import_vars') nogen assert(3)
		tempfile	1999_indiv
		save		`1999_indiv'
		
		*	Define a matrix where descriptive stats will be stored
		mat	define		desc_stats	=	nullmat(desc_stats)
	
		*	Sample Composition
		svy: tab sample_source, count cellwidth(12) format(%12.2g)
		
		*	Population (to be compared with Census)
			qui	svy: mean FUID
			mat list e(_N_subp), format(%12.2g)
			
			graph pie FUID [pw = ER33547], over(sample_source) ///
			plabel(1 "SRC")	plabel(2 "SEO")	plabel(3 "Refresher") ///
			title(Sample Source(population))
			graph	export	"${PSID_outRaw}/pop_sample_99.png", replace
			graph	close
			
		*	Race
			svy: tab ER15928, count cellwidth(12) format(%12.2g)
			svy: tab ER15928
			
		*	Region
			svy: tab interview_region_census, count cellwidth(12) format(%12.2g)
			svy: tab interview_region_census
		
		*	Age
			
			*	Overall
			svy: mean ER33504	//	Mean, standard error, confidence interval
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER33504, p(25 50 75 90 95)	//	Percentile
			*mat	desc_stats	=	nullmat(desc_stats)	\	e(_N)[1,1], e(b)[1,1]
			histogram ER33504 [fw = ER33547_int], bin(20) title(Distribution of Age)
			graph	export	"${PSID_outRaw}/age_99_dist.png", replace
			graph	close
			
			*	By Source (SRC, SEO, Immgrant Refresher)
			svy: mean ER33504, over(sample_source)	//	Mean, standard error, confidence interval
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER33504, p(25 50 75 90 95) over(sample_source)	//	Percentile
			*mat	desc_stats	=	nullmat(desc_stats)	\	e(_N)[1,1], e(b)[1,1]
			
			svy, subpop(if sample_source==1): mean ER33504	//	Sample size
			svy, subpop(if sample_source==2): mean ER33504
			svy, subpop(if sample_source==3): mean ER33504
			
		*	Gender
			
			*	Overall
			svy: proportion	ER32000
			
			*	By Source
			svy: proportion	ER32000, over(sample_source)
			mat list e(_N_subp), format(%12.2g)
		
		*	Education attained
			
			*	Overall
			svy: mean ER33516	//	Mean, standard error, confidence interval
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER33516, p(25 50 75 90 95)	//	Percentile
			histogram ER33516 [fw = ER33547_int], discrete title(Years of Education)
			graph	export	"${PSID_outRaw}/edu_99_dist.png", replace
			graph	close
			
			*	By sample
			svy: mean ER33516, over(sample_source)	//	Mean, standard error, confidence interval
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER33516, p(25 50 75 90 95) over(sample_source)	//	Percentile
			
			svy, subpop(if sample_source==1): mean ER33516	//	Sample size
			svy, subpop(if sample_source==2): mean ER33516
			svy, subpop(if sample_source==3): mean ER33516
			
			*	Comparison with Census
			
				*	% of HS graduates, age 25-29
				svy, subpop(if inrange(ER33504,25,29)): mean hs_graduate
				
				*	% of Bachelor's, age 25-29
				svy, subpop(if inrange(ER33504,25,29)): mean bachelor_degree	
				
				*	% of HS graduates by gender, age 25>=
				svy, subpop(if ER33504>=25 & !mi(ER33504)): mean hs_graduate, over(ER32000)
				
				*	% of Bachelor's by gender, age 25>=
				svy, subpop(if ER33504>=25 & !mi(ER33504)): mean bachelor_degree, over(ER32000)
						
	
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
			histogram ER13010 [fw = ER16518_int], bin(20) title(Age(Head))
			graph	export	"${PSID_outRaw}/agehead_99_dist.png", replace
			graph	close
			
			*	By sample
			svy: mean	ER13010, over(sample_source)
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER13010, p(25 50 75 90 95) over(sample_source)	//	Percentile
			
			svy, subpop(if sample_source==1): mean ER13010	//	Sample size
			svy, subpop(if sample_source==2): mean ER13010
			svy, subpop(if sample_source==3): mean ER13010
		
		*	Gender (Head)
			
			*	Overall
			svy: proportion	ER13011
			
			*	By sample
			svy: proportion	ER13011, over(sample_source)
			mat list e(_N), format(%12.2g)
			mat list e(_N_subp), format(%12.2g)
		
		*	Family Size
			
			*	Overall
			svy: mean	ER13009
			mat	define	result=r(table)
			estat sd	//	Standard deviation
			epctile ER13009, p(25 50 75 90 95)	//	Percentile
			histogram ER13009 [fw = ER16518_int], discrete title(Family Size)
			graph	export	"${PSID_outRaw}/famsize_99_dist.png", replace
			graph	close
			
			*	By sample
			svy: mean	ER13009, over(sample_source)
			mat	define	result=r(table)
			mat list e(_N), format(%12.2g)
			mat list e(_N_subp), format(%12.2g)
			estat sd	//	Standard deviation
			epctile ER13009, p(25 50 75 90 95)	over(sample_source) //	Percentile
			
		*	Location
			
			*	Overall
			svy: proportion	ER16430
			graph pie FUID [fw = ER16518_int], over(ER16430) ///
			plabel(2 "NE")	plabel(3 "N.Cntrl")	plabel(4 "South")	plabel(5 "West")	///
			title(Region)
			graph	export	"${PSID_outRaw}/location_99_dist.png", replace
			graph	close
			
			*	By sample
			svy: proportion	ER16430, over(sample_source)
			mat list e(_N), format(%12.2g)
			mat list e(_N_subp), format(%12.2g)
		
		*	Ethnicity (Head)

			*	Overall
			svy: proportion	ER15932
			graph pie FUID [fw = ER16518_int], over(ER15932) ///
			plabel(3 "National origin")	plabel(5 "Racial")	///
			title(Ethnicity(Head))
			graph	export	"${PSID_outRaw}/ethnicity_99_dist.png", replace
			graph	close
			
			*	By sample
			svy: proportion	ER15932, over(sample_source)
			mat list e(_N), format(%12.2g)
			mat list e(_N_subp), format(%12.2g)
		
		*	Race (Head)
	
			*	Overall
			svy: proportion	ER15928
			mat list e(_N_subp), format(%12.2g)
			graph pie FUID [pw = ER16518], over(ER15928) ///
			plabel(1 "White")	plabel(2 "Black")	///
			title(Race(Head))
			graph	export	"${PSID_outRaw}/race_99_dist.png", replace
			graph	close
			
			*	By sample
			svy: proportion	ER15928, over(sample_source)
			mat list e(_N), format(%12.2g)
			mat list e(_N_subp), format(%12.2g)
			
			graph pie FUID [pw = ER16518], over(sample_source) ///
			plabel(1 "SRC")	plabel(2 "SEO")	plabel(3 "Refresher") ///
			title(Sample Source(population)_family)
			graph	export	"${PSID_outRaw}/pop_sample_99_fam.png", replace
			graph	close
		