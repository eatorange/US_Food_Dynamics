
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_CB_Measurement
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Apr 12, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	        // Uniquely identifies family (update for your project)

	DESCRIPTION: 	Construct Cisse and Barrett (CB) measurement
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - 
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID 1999-2017 Panel Constructed (ind & family)
					${PSID_dtFin}/PSID_const_1999_2017_ind.dta
					
			
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
	loc	name_do	PSID_CB_measurement
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doAnl}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1: Prepare dataset
	****************************************************************/		
	
	*	Construct additional variables
	*	Most of them are from Tiehen (2019) replication
	
		use	"${PSID_dtFin}/PSID_const_1999_2017_ind.dta",	clear
		
		*	Racial category
		
		foreach	year	in	1999 2001 2003 2015 2017	{
			gen		race_head_cat`year'=.
			replace	race_head_cat`year'=1	if	inlist(race_head_fam`year',1,5)
			replace	race_head_cat`year'=2	if	race_head_fam`year'==2
			replace	race_head_cat`year'=3	if	inlist(race_head_fam`year',3,4,6,7)
			replace	race_head_cat`year'=.n	if	inrange(race_head_fam`year',8,9)
			
			*	Dummy for each variable
			
			label variable	race_head_cat`year'	"Racial Category of Head, `year'"
		}
		label	define	race_cat	1	"White"	2	"Black"	3	"Others"
		label	values	race_head_cat*	race_cat
		
		
		
		*	Marital Status (Binary)
		foreach	year	in	1999	2001	2003	2015	2017	{
			gen		marital_status_cat`year'=.
			replace	marital_status_cat`year'=1	if	marital_status_fam`year'==1
			replace	marital_status_cat`year'=2	if	inrange(marital_status_fam`year',2,5)
			replace	marital_status_cat`year'=.n	if	inrange(marital_status_fam`year',8,9)
			
			label variable	marital_status_cat`year'	"Marital Status of Head, `year'"
		}
		label	define	marital_status_cat	1	"Married"	2	"Not Married"
		label	values	marital_status_cat*	marital_status_cat
		
		*	Children in Household (Binary)
		foreach	year	in	1999	2001	2003	2015	2017	{
			gen		child_in_FU_cat`year'=.
			replace	child_in_FU_cat`year'=1		if	num_child_fam`year'>=1	&	!mi(num_child_fam`year')
			replace	child_in_FU_cat`year'=2		if	num_child_fam`year'==0
			*replace	child_in_FU_cat`year'=.n	if	!inrange(xsqnr_`year',1,89)
			
			label variable	child_in_FU_cat`year'	"Children in Household, `year'"
		}
		label	define	child_in_FU_cat	1	"Children in Household"	2	"No Children in Household"
		label	values	child_in_FU_cat*	child_in_FU_cat
		
		*	Age of Head (Category)
		foreach	year	in	1999	2001	2003	2015	2017	{
			gen		age_head_cat`year'=1	if	inrange(age_head_fam`year',16,24)
			replace	age_head_cat`year'=2	if	inrange(age_head_fam`year',25,34)
			replace	age_head_cat`year'=3	if	inrange(age_head_fam`year',35,44)
			replace	age_head_cat`year'=4	if	inrange(age_head_fam`year',45,54)
			replace	age_head_cat`year'=5	if	inrange(age_head_fam`year',55,64)
			replace	age_head_cat`year'=6	if	age_head_fam`year'>=65	&	!mi(age_head_fam`year'>=65)
			replace	age_head_cat`year'=.	if	mi(age_head_fam`year')
			
			label	var	age_head_cat`year'	"Age of Household Head (category), `year'"
		}
		label	define	age_head_cat	1	"16-24"	2	"25-34"	3	"35-44"	///
										4	"45-54"	5	"55-64"	6	"65 and older"
		label	values	age_head_cat*	age_head_cat
		
		*	Recode gender
		foreach	year	in	1999	2001	2003	2015	2017	{
			replace	gender_head_fam`year'	=	0	if	gender_head_fam`year'==2
			
			label	var	gender_head_fam`year'	"Gender Household Head (category), `year'"
		}
		label	define	gender_head_cat	0	"Female"	1	"Male"
		label	values	gender_head_fam*	gender_head_cat
		
		*	Create dummy variables for food security status, compatible with literature
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			generate	fs_cat_MS`year'		=	0	if	!mi(fs_cat_fam`year')
			generate	fs_cat_IS`year'		=	0	if	!mi(fs_cat_fam`year')
			generate	fs_cat_VLS`year'	=	0	if	!mi(fs_cat_fam`year')
					
			replace		fs_cat_MS`year'	=	1	if	inrange(fs_cat_fam`year',2,4)
			replace		fs_cat_IS`year'	=	1	if	inrange(fs_cat_fam`year',3,4)
			replace		fs_cat_VLS`year'	=	1	if	fs_cat_fam`year'==4
			
			label	var	fs_cat_VLS`year'	"Very Low Food Secure (cum) - `year'"
			label	var	fs_cat_IS`year'		"Food Insecure (cum) - `year'"
			label	var	fs_cat_MS`year'		"Any Insecure (cum) - `year'"
		}
		
		*	Recode child-related variables from missing to zero, to be included in the regression model
		foreach	year	in	1999	2001	2003	2015	2017	{
				replace	WIC_received_last`year'=0	if	child_meal_assist`year'==2
				replace	child_meal_assist`year'=0	if	child_meal_assist`year'==2
		}
		
		tempfile	dta_constructed
		save		`dta_constructed'
	

	
	*	Import variables for sampling error estimation
		use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
		*	Generate a single ID variable
		generate	x11101ll=(ER30001*1000)+ER30002
		
		tempfile	Ind
		save		`Ind'
	
		*	Import variables
		use	`dta_constructed', clear
		merge	m:1	x11101ll	using	`Ind', assert(2 3) keep(3) keepusing(ER31996 ER31997) nogen
		
	*	Make family-level data
	
		*	Keep relevant family-level variables only
		loc	interview_ID	x11102*	x11101ll	fam_ID_1999
		loc	weightvars		weight_long_fam*
		loc	samplingvars	sample_source	ER31996	ER31997
		loc	demovars		age_head*	race_head*		marital_status*	gender_head_fam*	state_resid_fam*	
		loc	familyvars		num_FU_fam*	num_child_fam*	family_comp_change*	child_in_FU*	fam_comp_nochange_99_03	fam_comp_samehead_99_03
		loc	socioeconvars	edu_years_head_fam*	FPL*	grade_comp*	college_completed*	hs_completed*	total_income_fam*	income_pc*	food_exp_pc*	avg_income_pc*	avg_foodexp_pc*
		loc	foodvars		fs_raw*	fs_scale*	fs_cat*	food_stamp_used*	child_meal_assist*	WIC_received*
		loc	healthvars		respondent_BMI*
		
		keep	`interview_ID'	`weightvars'	`samplingvars'	`demovars'	`familyvars'	`socioeconvars'	`foodvars'	`healthvars'
		save	`dta_constructed', replace
		
	
		
	*	Re-shape dataset
	*	Before re-shaping data, we need to decide what families to track (so we have only 1 obs per family in baseyear)
		
		*	
		*keep	if	fam_comp_nochange_99_03==1	//	Families with no member change during 1999-2003
		keep	if	fam_comp_samehead_99_03==1	//	Families with same household during 1999-2003
		
		*	Keep relevant years and variables
		keep	*1999	*2001	*2003	sample_source	ER31996 ER31997
		duplicates drop
		
		*	Re-shape data
		reshape	long	x11102_ weight_long_fam age_head_fam race_head_fam total_income_fam total_income_fam_wins		///
						marital_status_fam num_FU_fam num_child_fam	gender_head_fam edu_years_head_fam state_resid_fam  	///
						fs_raw_fam	fs_scale_fam	fs_cat_fam	food_stamp_used_2yr	food_stamp_used_1yr	///
						child_meal_assist WIC_received_last family_comp_change FPL_ FPL_cat grade_comp_cat race_head_cat marital_status_cat	///
						child_in_FU_cat age_head_cat fs_cat_VLS fs_cat_IS fs_cat_MS	///
						hs_completed college_completed respondent_BMI income_pc food_exp_pc avg_income_pc	avg_foodexp_pc,	///
						i(fam_ID_1999)	j(year)
						
		*	Label variables after reshape
		label	var	year				"Year"
		label	var	x11102_				"Interview No."	
		label	var	weight_long_fam		"Longitudinal Family Weight"
		label	var	age_head_fam		"Age of Household Head"
		label	var	race_head_fam		"Race of Household Head"
		label	var	total_income_fam	"Total Household Income"
		label	var	marital_status_fam	"Marital Status of Head"
		label	var	num_FU_fam			"# of Family members"
		label	var	num_child_fam		"# of Children"
		label	var	gender_head_fam		"Gender of Household Head"
		label	var	edu_years_head_fam	"Years of Education"
		label	var	state_resid_fam		"State of Residence"
		label 	var	fs_raw_fam 			"Food Security Score (Raw)"
		label 	var	fs_scale_fam 		"Food Security Score (Scale)"
		label	var	fs_cat_fam 			"Food Security Category"
		label	var	food_stamp_used_2yr	"Received Food Stamp (2 years ago)"
		label	var	food_stamp_used_1yr "Received Food Stamp (1 year ago)"
		label	var	child_meal_assist	"Received Child Free Meal"
		label	var	WIC_received_last	"Received WIC"
		label	var	family_comp_change	"Change in Family Composition"
		label	var	grade_comp_cat		"Highest Grade Completed"
		label	var	race_head_cat		"Race of Household Head"
		label	var	marital_status_cat	"Marital Status of Head"
		label	var	child_in_FU_cat		"Household has a child"
		label	var	age_head_cat 		"Age of Household Head (category)"
		label	var	total_income_fam_wins	"Total Household Income (winsorized)"
		label	var	hs_completed		"HH completed high school/GED"
		label	var	college_completed	"HH has college degree"
		label	var	respondent_BMI		"Respondent's Body Mass Index"
		label	var	income_pc			"Family income per capita"
		label	var	food_exp_pc			"Food expenditure per capita"
		label	var	avg_income_pc		"Average income over two years per capita"
		label	var	avg_foodexp_pc		"Average food expenditure over two years per capita"
		      
	
	/****************************************************************
		SECTION 2: Construct CB measurement
	****************************************************************/	
	
	*	Define the data as survey data and time-series data
	svyset	ER31997 [pweight=weight_long_fam], strata(ER31996)	singleunit(scaled)
	xtset fam_ID_1999 year,	delta(2)
	
	*	Review outcome variables
		
		*	Correlation between FS scores and outcome variables
		corr fs_scale_fam income_pc	food_exp_pc  avg_income_pc avg_foodexp_pc	respondent_BMI
		
		*	Data plot of the outcome variables
		kdensity income_pc, 		title(Household Income per capita) xtitle(Household Income per capita)
		graph	export	"${PSID_outRaw}/kdensity_income_pc.png",	replace
		
		kdensity food_exp_pc, 		title(Household food expenditure per capita) xtitle(Household food expenditure per capita)
		graph	export	"${PSID_outRaw}/kdensity_food_exp_pc.png",	replace
		
		kdensity avg_income_pc, 	title(Average income per capita) xtitle(Average per capita income over the two years)
		graph	export	"${PSID_outRaw}/kdensity_avg_income_pc.png",	replace
		
		kdensity avg_foodexp_pc, 	title(Average food expenditure per capita) xtitle(Average per capita food expenditure over the two years)
		graph	export	"${PSID_outRaw}/kdensity_avg_foodexp_pc.png",	replace
		
		kdensity respondent_BMI, 	title(Respondent BMI) xtitle(Respondent Body Mass Index)
		graph	export	"${PSID_outRaw}/kdensity_resp_BMI.png",	replace
		
		gen		log_respondent_BMI	=	log(respondent_BMI)
		kdensity log_respondent_BMI, 	title(log(Respondent BMI)) xtitle(Log of Respondent Body Mass Index)
		graph	export	"${PSID_outRaw}/kdensity_log_resp_BMI.png",	replace
		graph	close
		drop	log_respondent_BMI
	
	*	Declare list of variables
		
		*	Common controls
		local	demovars	c.age_head_fam##c.age_head_fam i.race_head_cat gender_head_fam	ib1.marital_status_cat	
		local	eduvars		edu_years_head_fam	c.edu_years_head_fam#hs_completed c.edu_years_head_fam#college_completed
		local	econvars	/*total_income_fam_wins*/	avg_income_pc	c.avg_income_pc#c.avg_income_pc
		local	famvars		num_FU_fam	num_child_fam
		local	foodvars	food_stamp_used_1yr	child_meal_assist	WIC_received_last*
		
		*	Threshold values
		scalar	wbar2_avg_foodexp_pc=1000
		scalar	wbar2_respondent_BMI=18.5
		
		
		*	AIC for model specification
		foreach Y in avg_foodexp_pc	respondent_BMI {
			
			svy: glm `Y' cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 	//	
			svy: estat ic
			est sto AIC1_`Y'
			predict AIC1_`Y'
			
			/*
			svy: glm `Y' cl.`Y'##cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 	//	
			est sto AIC2_`Y'
			predict AIC2_`Y'
			
			svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 	//	
			est sto AIC3_`Y'
			predict AIC3_`Y'
			*/
			
		}
	
	* Run (BMI)
  foreach Y in /*avg_foodexp_pc*/	respondent_BMI {
   *Mean Specifications 

    *One period lag, with squares and cubes
	
		*	Without controls
		*svy: nbreg `Y' cl.`Y'##cl.`Y'##cl.`Y' 	// nbreg
		svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y', family(gamma)
		est sto base1_`Y'
		margins, dydx(*) atmeans post	//	marginal effect
		est	sto	margin1_base_`Y'
  	
		*	With controls
		svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 	//	
		est sto mean1_`Y'
		predict mean1_`Y'
		predict e1_`Y', r
		margins, dydx(*) atmeans post	//	marginal effect
		est	sto	margin1_`Y'
      
  *Variance Specification
     
	*One-period lag, with squares and cubes
	 gen e1`Y'_sq = e1_`Y'^2	//	(SL: squared residual?)
	 
     svy: glm e1`Y'_sq cl.`Y'##cl.`Y'##cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 
	 est sto var1_`Y'
	 predict var1_`Y'
	 margins, dydx(*) atmeans post	//	(SL: why do we use GLM instead of OLS? Why didn't we use it in the first step?)
     est	sto margin2_`Y'  

	
  *Resilience Scores & Regressions (using poverty line for OUTCOME, wbar2_`Y'), based on negative binomial distribution
     *One-period lag, with squares and cubes
	 
		gen alpha1_`Y' = mean1_`Y'^2 / var1_`Y'	
		gen beta1_`Y' = var1_`Y' / mean1_`Y'
		gen rho1_`Y' = 1 - gammap(alpha1_`Y', wbar2_`Y'/beta1_`Y')
	
		*	Now regress RHS variables on this predicted probability
		*reg rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' ndvi_z_var, vce(cluster geo_region)	//	(SL: Do we use LPM, not logit?) (Joan: rho1 is continuous b/w 0 and 1)
	   *est sto R1_`Y'
		svy: reg rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`eduvars'	`famvars'	`foodvars'
		est sto R12_`Y'
		margins, dydx(*) atmeans post	//	(SL: why do we use GLM instead of OLS? Why didn't we use it in the first step?)
		est	sto margin3_`Y'
		*svy: reg	rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`eduvars'	`famvars'	`foodvars'
		*svy: fracreg logit	rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`eduvars'	`famvars'	`foodvars'
	    *est sto R12_frac_`Y'  
		*margins, dydx(*) atmeans post
		*est	sto margin3_frac_`Y'
		
  }

	*	Output result
	
	foreach Y in /*avg_foodexp_pc*/	respondent_BMI {
	
		*	Regression
		esttab	base1_`Y'	mean1_`Y'	var1_`Y'	R12_`Y'	using "${PSID_outRaw}/CB_regression_`Y'.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Regression) replace
			
		*	Marginal Effect
		esttab	margin1_base_`Y'	margin1_`Y'	margin2_`Y' 	margin3_`Y' margin3_`Y' 		using "${PSID_outRaw}/CB_ME_`Y'.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels /*drop(_cons)*/	title(Marginal Effects) replace
	}			
	exit
							
/* Junk Code */
/* The following codes are old codes used when outcome variable are non-negative discrete variables (FS score) */		

/*
	*	Declare list of variables
	local	demovars	c.age_head_fam##c.age_head_fam i.race_head_cat gender_head_fam	ib1.marital_status_cat	edu_years_head_fam
	local	econvars	total_income_fam_wins
	local	famvars		num_FU_fam	num_child_fam
	local	foodvars	food_stamp_used_1yr	child_meal_assist	WIC_received_last*
	
	* Run 
  foreach Y in fs_scale_fam {
   *Mean Specifications 

    *One period lag, with squares and cubes
	
		*	Without controls
		*svy: nbreg `Y' cl.`Y'##cl.`Y'##cl.`Y' 	// nbreg
		svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y' , /*vce(cluster ER31996)*/ family(nbinomial) // glm with nbinomial distribution, allows residual prediction
		est sto base1_`Y'
		margins, dydx(*) atmeans post	//	marginal effect
		est	sto	margin1_base_`Y'
  }	
		*	With controls
		*svy: nbreg `Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars'	//	nbreg
		svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars', /*vce(cluster ER31996)*/ family(nbinomial) 	//	 glm with nbinomial distribution, allows residual prediction
		est sto mean1_`Y'
		predict mean1_`Y'
		predict e1_`Y', r
		margins, dydx(*) atmeans post	//	marginal effect
		est	sto	margin1_`Y'
      
  *Variance Specification - Negative binomial
     
	*One-period lag, with squares and cubes
	 gen e1`Y'_sq = e1_`Y'^2	//	(SL: squared residual?)
     svy: glm e1`Y'_sq cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars', /*vce(cluster ER31996)*/ family(nbinomial) 
	 est sto var1_`Y'
	 predict var1_`Y'
	 margins, dydx(*) atmeans post	//	(SL: why do we use GLM instead of OLS? Why didn't we use it in the first step?)
     est	sto margin2_`Y'  

	
  *Resilience Scores & Regressions (using poverty line for OUTCOME, wbar2_`Y'), based on negative binomial distribution
     *One-period lag, with squares and cubes
	 
		***************Need to double-check method of moments
		*	From the first and the second moments we estimated above, we use method of moments to estimate distribution parameter.
		*	For X ~ NB(r,p), where r is the number of failures and p is the success probability,
		*	mu = pr/(1-p), sigma2 = pr/(1-p)^2
		*	Solve the system and we get p = 1 - (mu/sigma2), r = mu^2/(sig2-mu)
		
		gen	prob_`Y'	=	1-(mean1_`Y'/var1_`Y')
		gen	gamma_`Y'	=	(mean1_`Y')^2/(var1_`Y'-mean1_`Y')
		
		*	Now estimate CDF of NB(n,r,p) where n is the number of success (support, x-axis)
		*	We use n=2.32, the threshold of food security scale score indicating ANY food insecurity
		*	Source: "Measuring Food Security in the United States: Guide to Measuring Household Food Security, Revised 2000 (Bickel et al., 2000)
		scalar	n=2.32
		gen rho1_`Y' = nbinomial(n,gamma_`Y',prob_`Y')	//	Probability of being food secure (FS scale score <=2.32)
	
		*	Now regress RHS variables on this predicted probability
		*reg rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' ndvi_z_var, vce(cluster geo_region)	//	(SL: Do we use LPM, not logit?) (Joan: rho1 is continuous b/w 0 and 1)
	   *est sto R1_`Y'
		svy: reg rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars', /*vce(cluster geo_region)*/
		est sto R12_`Y'
		margins, dydx(*) atmeans post	//	(SL: why do we use GLM instead of OLS? Why didn't we use it in the first step?)
		est	sto margin3_`Y'
		svy: fracreg logit	rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars', /*vce(cluster geo_region)*/
	    est sto R12_frac_`Y'  
		margins, dydx(*) atmeans post
		est	sto margin3_frac_`Y'
		
  }

	*	Output result
	
	local	Y	fs_scale_fam
	
		*	Regression
		esttab	base1_fs_scale_fam	mean1_fs_scale_fam	var1_fs_scale_fam	R12_fs_scale_fam	R12_frac_fs_scale_fam	using "${PSID_outRaw}/CB_regression.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Regression) replace
			
		*	Marginal Effect
		esttab	margin1_base_`Y'	margin1_`Y'	margin2_`Y' 	margin3_`Y' margin3_frac_`Y' 		using "${PSID_outRaw}/CB_ME.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels /*drop(_cons)*/	title(Marginal Effects) replace