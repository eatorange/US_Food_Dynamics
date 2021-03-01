
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
	
	set	seed 20200513
	
	*	Define global macros
		
		*	Samples to use
		global	study_sample	sample_source_SRC_SEO
		
		*	States (used for regression coefficients plots)
		global	state_Northeast	6.state_resid_fam	18.state_resid_fam	20.state_resid_fam	28.state_resid_fam	///
								29.state_resid_fam	31.state_resid_fam	37.state_resid_fam	/*38.state_resid_fam*/	44.state_resid_fam
		global	state_Ncentral	12.state_resid_fam	13.state_resid_fam	14.state_resid_fam	15.state_resid_fam	///
								21.state_resid_fam	22.state_resid_fam	24.state_resid_fam	26.state_resid_fam	///
								33.state_resid_fam	38.state_resid_fam	40.state_resid_fam	48.state_resid_fam
		global	state_South		1.state_resid_fam	3.state_resid_fam	7.state_resid_fam	8.state_resid_fam	///
								9.state_resid_fam	10.state_resid_fam	16.state_resid_fam	17.state_resid_fam	///
								19.state_resid_fam	23.state_resid_fam	32.state_resid_fam	35.state_resid_fam	///
								39.state_resid_fam	41.state_resid_fam	42.state_resid_fam	45.state_resid_fam	///
								47.state_resid_fam
			*	Without Delarware
			global	state_South_noDE	1.state_resid_fam	3.state_resid_fam	/*7.state_resid_fam*/	8.state_resid_fam	///
										9.state_resid_fam	10.state_resid_fam	16.state_resid_fam	17.state_resid_fam	///
										19.state_resid_fam	23.state_resid_fam	32.state_resid_fam	35.state_resid_fam	///
										39.state_resid_fam	41.state_resid_fam	42.state_resid_fam	45.state_resid_fam	///
										47.state_resid_fam
		global	state_West		2.state_resid_fam	4.state_resid_fam	5.state_resid_fam	11.state_resid_fam	///
								25.state_resid_fam	27.state_resid_fam	30.state_resid_fam	36.state_resid_fam	///
								43.state_resid_fam	46.state_resid_fam	49.state_resid_fam	
		
		
		*	Grouped state (Based on John's suggestion on 2020/12/15)
		
			*	Reference state
			global	state_bgroup	state_resid_fam_enum32	//	NY
			
			*	Excluded states (Alaska, Hawaii, U.S. territory, DK/NA)
			global	state_group0	state_resid_fam_enum1	state_resid_fam_enum52	///	//	Inapp, DK/NA
									state_resid_fam_enum50	state_resid_fam_enum51	//	AK, HI
			global	state_group_ex	${state_group0}
			
			*	Northeast
			global	state_group1	state_resid_fam_enum19 state_resid_fam_enum29 state_resid_fam_enum44	///	//	ME, NH, VT
									state_resid_fam_enum21 state_resid_fam_enum7	//	MA, CT
			global	state_group_NE	${state_group1}
				
			*	Mid-atlantic
			global	state_group2	state_resid_fam_enum38	//	PA
			global	state_group3	state_resid_fam_enum30	//	NJ
			global	state_group4	state_resid_fam_enum9	state_resid_fam_enum8	state_resid_fam_enum20	//	DC, DE, MD
			global	state_group5	state_resid_fam_enum45	//	VA
			global	state_group_MidAt	${state_group2}	${state_group3}	${state_group4}	${state_group5}
			
			*	South
			global	state_group6	state_resid_fam_enum33	state_resid_fam_enum39	//	NC, SC
			global	state_group7	state_resid_fam_enum11	//	GA
			global	state_group8	state_resid_fam_enum17	state_resid_fam_enum41	state_resid_fam_enum47	//	KT, TN, WV
			global	state_group9	state_resid_fam_enum10	//	FL
			global	state_group10	state_resid_fam_enum2	state_resid_fam_enum4	state_resid_fam_enum24 state_resid_fam_enum18	//	AL, AR, MS, LA
			global	state_group11	state_resid_fam_enum42	//	TX
			global	state_group_South	${state_group6}	${state_group7}	${state_group8}	${state_group9}	${state_group10}	${state_group11}
			
			*	Mid-west
			global	state_group12	state_resid_fam_enum35	//	OH
			global	state_group13	state_resid_fam_enum14	//	IN
			global	state_group14	state_resid_fam_enum22 	//	MI
			global	state_group15	state_resid_fam_enum13	//	IL
			global	state_group16	state_resid_fam_enum23 state_resid_fam_enum48	//	MN, WI
			global	state_group17	state_resid_fam_enum15	state_resid_fam_enum25	//	IA, MO
			global	state_group_MidWest	${state_group12}	${state_group13}	${state_group14}	${state_group15}	${state_group16}	${state_group17}
			
			*	West
			global	state_group18	state_resid_fam_enum16	state_resid_fam_enum27	///	//	KS, NE
									state_resid_fam_enum34	state_resid_fam_enum40	///	//	ND, SD
									state_resid_fam_enum36	//	OK
			global	state_group19	state_resid_fam_enum3	state_resid_fam_enum6	///	//	AZ, CO
									state_resid_fam_enum12	state_resid_fam_enum26	///	//	ID, MT
									state_resid_fam_enum28	state_resid_fam_enum31	///	//	NV, NM
									state_resid_fam_enum43	state_resid_fam_enum49		//	UT, WY
			global	state_group20	state_resid_fam_enum37	state_resid_fam_enum46	//	OR, WA
			global	state_group21	state_resid_fam_enum5	//	CA						
			global	state_group_West	${state_group18}	${state_group19}	${state_group20}	${state_group21}	
	
	
	/****************************************************************
		SECTION 1: Construct PFS measurement
	****************************************************************/	

	use	"${PSID_dtFin}/fs_const_long.dta", clear
	
		
	*	OLS
	local	run_GLM	1
		local	model_selection	0
		local	run_ME	0
		
	*	LASSO
	local	run_lasso	0
		local	run_lasso_step1	1
		local	run_lasso_step2	1
		local	run_lasso_step3	1
		
	*	Random Forest
	local	run_rf	1	
		local	tune_iter	0	//	Tuning iteration
		local	tune_numvars	0	//	Tuning numvars
		local	run_rf_step1	1
		local	run_rf_step2	1
		local	run_rf_step3	1
	*svyset	newsecu	[pweight=weight_multi12] /*,	singleunit(scaled)*/
	*svyset	ER31997 [pweight=weight_long_fam], strata(ER31996)	singleunit(scaled)
	
	
	
	*	GLM
	if	`run_GLM'==1	{

		*	Declare variables
		local	depvar		food_exp_pc
		local	statevars	lag_food_exp_pc_1##lag_food_exp_pc_1##lag_food_exp_pc_1	/*##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1	lag_food_exp_pc_1-lag_food_exp_pc_5*/
		local	demovars	age_head_fam age_head_fam_sq	/*HH_race_black	HH_race_other*/	HH_race_color	marital_status_cat	HH_female	/*ib1.race_head_cat*/	/*ib1.gender_head_fam*/		
		local	econvars	ln_income_pc	/*ln_wealth_pc*/	/*income_pc	income_pc_sq	wealth_pc	wealth_pc_sq*/	
		local	healthvars	phys_disab_head
		local	empvars		emp_HH_simple
		local	familyvars	num_FU_fam ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		highdegree_NoHS	highdegree_somecol	highdegree_col	/*attend_college_head college_yrs_head (hs_completed_head	college_completed	other_degree_head)##c.grade_comp_head_fam*/	
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal	/*meal_together*/	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	/*ib0.state_resid_fam*/	state_group? state_group1? state_group2?
		local	timevars	i.year
		
		local	depvar	e1_foodexp_sq_ols
		local	statevars	lag_food_exp_pc_1	lag_food_exp_pc_2 lag_food_exp_pc_3
		br alpha1_foodexp_pc_ols var1_foodexp_ols rho1_foodexp_pc_thrifty_ols `depvar' `statevars'		`demovars'	`econvars'	`healthvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars' if var1_foodexp_ols<0	// `regionvars'	`timevars'	
		
		svy, subpop(if ${study_sample}): mean `depvar' `statevars'		`demovars'	`econvars'	`healthvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'
		svy, subpop(if ${study_sample}	&	var1_foodexp_ols<0): mean `depvar' `statevars'		`demovars'	`econvars'	`healthvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'
		
		local	MEvars	c.lag_food_exp_pc_1	`healthvars'	c.age_head_fam	/*ib1.race_head_cat*/	HH_race_black	HH_race_other	marital_status_cat	HH_female	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'
		
		*summ `depvar'	`lag_food_exp_pc_1'	`age_head_fam'	HH_race_black	HH_race_other	marital_status_cat	HH_female	`econvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'
		
		*	Model selection (highest order)
		if	`model_selection'==1	{
			
			local	statevars	c.lag_food_exp_pc_1
			svy, subpop(${study_sample}): glm 	`depvar'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	`statevars'	/*	if	in_sample==1*/, family(gamma/*poisson*/)	link(log)
			estadd scalar	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			est	sto	ols_step1_order1
			
			local	statevars	c.lag_food_exp_pc_1##c.lag_food_exp_pc_1
			svy, subpop(${study_sample}): glm 	`depvar'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	`statevars'		/*	if	in_sample==1*/, family(gamma/*poisson*/)	link(log)
			estadd scalar aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			est	sto	ols_step1_order2
			
			local	statevars	c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1
			svy, subpop(${study_sample}): glm 	`depvar'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	`statevars'		/*	if	in_sample==1*/, family(gamma/*poisson*/)	link(log)
			estadd scalar aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			est	sto	ols_step1_order3
			
			local	statevars	c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1
			svy, subpop(${study_sample}): glm 	`depvar'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	`statevars'		/*	if	in_sample==1*/, family(gamma/*poisson*/)	link(log)
			estadd scalar aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			est	sto	ols_step1_order4
			
			local	statevars	c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1
			svy, subpop(${study_sample}): glm 	`depvar'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	`statevars'		/*	if	in_sample==1*/, family(gamma/*poisson*/)	link(log)
			estadd scalar aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			est	sto	ols_step1_order5
			
			
			*	Output
			esttab	ols_step1_order1	ols_step1_order2	ols_step1_order3	ols_step1_order4	ols_step1_order5	using "${PSID_outRaw}/GLM_model_selection.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N aic2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5% of the sample size)	///
					replace
					
			esttab	ols_step1_order1	ols_step1_order2	ols_step1_order3	ols_step1_order4	ols_step1_order5	using "${PSID_outRaw}/GLM_model_selection.tex", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N aic2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5% of the sample size)	///
					replace
			
		}
		
		
		*	Step 1
		
			*	All sample
			*svy: glm 	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	if	in_sample==1, family(gamma/*poisson*/)	link(log)
			*	SRC/SEO only
			local	statevars	lag_food_exp_pc_1	lag_food_exp_pc_2 lag_food_exp_pc_3
			
			svy, subpop(${study_sample}): glm 	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	/*if	in_sample==1*/, family(gamma/*poisson*/)	link(log)
		
		est	sto	ols_step1
		
		*	Predict fitted value and residual
		**	As of 2021/1/2, we will include 2017 in our regression sample which was not previously included.
		gen	ols_step1_sample=1	if	e(sample)==1 & `=e(subpop)'	//	We need =`e(subpop)' condition, as e(sample) includes both subpopulation and non-subpopulation.
		predict double mean1_foodexp_ols	if	ols_step1_sample==1
		/*if	((e(sample)==1 & `=e(subpop)')	|	(${study_sample}==1	&	year==10))*/	// Although 2017 sample is not included in estimating the PFS, we can still consturct the 2017 PFS
		predict double e1_foodexp_ols	if	ols_step1_sample==1,r
			/*if	((e(sample)==1 & `=e(subpop)')	|	(${study_sample}==1	&	year==10)), r*/
		gen e1_foodexp_sq_ols = (e1_foodexp_ols)^2

		*	Marginal Effect
		if	`run_ME'==1	{	
			eststo	ols_step1_ME: margins,	dydx(`MEvars')	post
		}
				
		
		*	Step 2
		local	depvar	e1_foodexp_sq_ols
		
			*	All sample
			*svy: reg `depvar' `statevars'		`demovars'	`econvars'	`healthvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	if	ols_step1_sample==1	//	glm does not converge, thus use OLS)
			
			*	SRC only
			svy, subpop(ols_step1_sample): reg `depvar' `statevars'		`demovars'	`econvars'	`healthvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	/*if	ols_step1_sample==1*/	//	glm does not converge, thus use OLS)
		
		est store ols_step2
		gen	ols_step2_sample=1	if	e(sample)==1 & `=e(subpop)'
		*svy:	reg `e(depvar)' `e(selected)'
		predict	double	var1_foodexp_ols	if	ols_step2_sample==1	/*if	((e(sample)==1 & `=e(subpop)')	|	(${study_sample}==1	&	year==10))*/
					
		*	Output
			esttab	ols_step1	ols_step2	using "${PSID_outRaw}/GLM_pooled.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5% of the sample size)	///
					replace
					
			esttab	ols_step1	ols_step2	using "${PSID_outRaw}/GLM_pooled.tex", ///
					cells(b(star fmt(a3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5\% of the sample size)	///
					replace		
		
			
		
		
		*	Marginal Effect
		if	`run_ME'==1	{
		
			eststo	ols_step2_ME: margins,	dydx(`MEvars')	post	
			
			*	Output
			esttab	ols_step1_ME	ols_step2_ME	using "${PSID_outRaw}/OLS_ME.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5% of the sample size)	///
					replace
					
			esttab	ols_step1_ME	ols_step2_ME	using "${PSID_outRaw}/OLS_ME.tex", ///
					cells(b(star fmt(a3)) & se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5\% of the sample size)	///
					replace		
		}
		
		
		*	Step 3
		*	Assume the outcome variable follows the Gamma distribution
		gen alpha1_foodexp_pc_ols = (mean1_foodexp_ols)^2 / var1_foodexp_ols	//	shape parameter of Gamma (alpha)
		gen beta1_foodexp_pc_ols = var1_foodexp_ols / mean1_foodexp_ols	//	scale parameter of Gamma (beta)
		
		*	Construct CDF
		foreach	plan	in	thrifty /*low moderate liberal*/	{
			
			*	Generate PFS. 
			*	Should include in-sample as well as out-of-sample to validate its OOS performance
			gen rho1_foodexp_pc_`plan'_ols = gammaptail(alpha1_foodexp_pc_ols, foodexp_W_`plan'/beta1_foodexp_pc_ols)	/*if	(lasso_step1_sample==1)	&	(lasso_step2_sample==1)*/	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
			label	var	rho1_foodexp_pc_`plan'_ols "PFS (`plan' plan)"
		}
		
		summ alpha1_foodexp_pc_ols	beta1_foodexp_pc_ols	rho1_foodexp_pc_thrifty_ols if ${study_sample}==1
		
	}
	
	*	LASSO
	if	`run_lasso'==1	{
			
		*	Variable selection
		*	when "0" implies "no". Should yield the same result to the previous coding which "5" implies "no"
		local	statevars	lag_food_exp_pc_1-lag_food_exp_pc_5	/*c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1*/		//	up to the order of 5
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse
		local	demovars	age_head_fam age_head_fam_sq	/*HH_race_black HH_race_other*/	HH_race_color	marital_status_cat	/*marital_status_fam_enum1 marital_status_fam_enum3 marital_status_fam_enum4 marital_status_fam_enum5*/	/*age_head_fam	age_head_fam_sq*/	///
							HH_female	/*c.age_spouse##c.age_spouse*/ age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc	/*income_pc	income_pc_sq	wealth_pc	wealth_pc_sq*/	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	/*num_child_fam*/	couple_status_enum1-couple_status_enum4
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
							/*	attend_college_head attend_college_spouse	college_yrs_head college_yrs_spouse	///
							hs_completed_head	college_completed	other_degree_head	grade_comp_head_fam	///
							hs_completed_head_interact college_completed_interact other_degree_head_interact	///
							hs_completed_spouse	college_comp_spouse	other_degree_spouse	grade_comp_spouse	///
							hs_completed_spouse_interact college_comp_spouse_interact other_degree_spouse_interact	*/
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	/*meal_together*/	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	/*state_resid_fam_enum1-state_resid_fam_enum52*/ state_group? state_group1? state_group2?
		local	timevars	year_enum2-year_enum9
		
		
		*	Step 1
		if	`run_lasso_step1'==1	{
		
			*	Feature Selection
			*	Run Lasso with "K-fold" validation	with K=10
		
			local	depvar	food_exp_pc
	
			**	Following "cvlasso" command does k-fold cross-validation to find lambda, but it takes too much time.
			**	Therefore, once it is executed and found lambda, then we run regular lasso using "lasso2"
			**	If there's major change in specification, cvlasso must be executed
			
			set	seed	20200505
			
			
			*	LASSO with K-fold cross validation
			** As of Aug 21, 2020, the estimated lambda with lse is 2016.775 (lse).
			** As of Sep 4, 2020, the estimated lambda with lse is 845.955 (lse). Since this lamba value gives too many variables, we use lambda = exp(8) whose MSPE is only very slightly higher than the MSPE under the lse.
			** As of Sep 11, 2020, the estimated lambda with lse is 1208.72 (lse). Since this lamba value gives too many variables, we use lambda = exp(8) whose MSPE is only very slightly higher than the MSPE under the lse.
			** As of Nov 5, 2020 using SRC sample only, the estimated lambda with lse is 1546.914 (lse).
			
				/*
				*	Finding optimal lambda using cross-validation (computationally intensive)
				cvlasso	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'		`healthvars'	`familyvars'	`eduvars'	///
									`eduvars'	`foodvars'	`childvars'	`regionvars'	`timevars'		if	/*in_sample==1	&*/	${study_sample}==1,	///
					/*lopt*/ lse	seed(20200505)	notpen(`regionvars'	`timevars')	 /*rolling	h(1) fe	prestd 	postres	ols*/	plotcv 
				est	store	lasso_step1_lse
				
				*cvlasso, postresult lopt	//	somehow this command is needed to generate `e(selected)' macro. Need to double-check
				cvlasso, postresult lse
				*/
				
				*	Running lasso with pre-determined lambda value 
				*local	lambdaval=exp(14.7)	//	14.7 is as of Aug 21
				*local	lambdaval=2208.348	//	manual lambda value from the cvplot. This is the value slightly higher than lse but give only slightly higher MSPE
				*local	lambdaval=1546.914	//	the lse value found from cvlasso using SRC sample only as of Nov 5.
				local	lambdaval=2000	//	temporary value, will find the exact value via cvlasso it later.
				lasso2	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`eduvars'	`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	/*in_sample==1	&*/	${study_sample}==1,	///
							ols lambda(`lambdaval') notpen(`regionvars'	`timevars')
				est	store	lasso_step1_manual
				lasso2, postresults
				
			*	Manually run post-lasso
				gen	lasso_step1_sample=1	if	e(sample)==1	
				
				global selected_step1_lasso `e(selected)'	/*`e(notpen)'*/
				svy:	reg `depvar' ${selected_step1_lasso}	`e(notpen)'	if	lasso_step1_sample==1
				est store postlasso_step1_lse
				
				*	Predict conditional means and variance from Post-LASSO
				predict double mean1_foodexp_lasso	if	lasso_step1_sample==1, xb	
					/*if	((lasso_step1_sample==1)	|	(${study_sample}==1	&	year==10)), xb*/
				predict double e1_foodexp_lasso	if	lasso_step1_sample==1,r	
					/*if	((lasso_step1_sample==1)	|	(${study_sample}==1	&	year==10)), r*/
				gen e1_foodexp_sq_lasso = (e1_foodexp_lasso)^2
				
				shapley2, stat(r2)	indepvars(${selected_step1_lasso})
				
				*** To get proper decomposition estimate for the terms including higher order, we must manually run the command by grouping them.
				di "${selected_step1_lasso}"
				est restore postlasso_step1_lse
				shapley2, stat(r2)	group(lag_food_exp_pc_1 lag_food_exp_pc_2, ln_income_pc, ln_wealth_pc, num_FU_fam, food_stamp_used_1yr, no_longer_married)
				est	store	postlasso_step1_shapley
	
		}	//	Step 1

		*	Step 2
		if	`run_lasso_step2'==1	{
		
			local	depvar	e1_foodexp_sq_lasso
			
			*	LASSO
			**	Update (2020/11/5) lse gives 19030.549 (lse), dropping everything. So we use lambda=exp(8.5) from cvplot.
			**	Update (2020/9/4) lopt gives lambda=1052.087, giving too many outputs, and lse ~ exp(10), which gives too little variables. We use somewhere between
			**	As of 2020/5/20, the following cvlasso not only takes too much time, but neither lopt nor lse work - lopt (ln(lambda)=20.78) gives too many variables, and lse (ln(lambda)=24.32) reduces everything.
			**	Therefore, I run regular lasso using "lasso2" and the lambda value in between (ln(lambda)=22.7)
				
				/*
				*	Finding optimal lambda using cross-validation (computationally intensive)		
				cvlasso	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`eduvars'	`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	lasso_step1_sample==1,	///
							/*lopt*/ lse	seed(20200505)	 /*rolling	h(1) fe	prestd 	postres		ols*/	notpen(`regionvars'	`timevars')	plotcv
				est	store	lasso_step2_lse			
				*** Somehow, the lambda from lopt does not reduce dimensionality a lot, and the lambda from lse does not keep ANY RHS varaible.
				*** For now (2020/5/18), we will just use the residual from lopt, but we could improve it later (ex. using the lambda somewhere between lopt and lse)
				
				*	Manually run post-lasso
				cvlasso, postresult lse	//	Need this command to use `e(selected)' macro
				*/
				
				
				*	Running lasso with pre-determined lambda value 				
				set	seed	20205020
				local	lambdaval=exp(9.0)	//	temporary value, will find the exact value via cvlasso later.
				lasso2	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`eduvars'	`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	lasso_step1_sample==1,	///
							ols lambda(`lambdaval') notpen(`regionvars'	`timevars')
				est	store	lasso_step2_manual
				lasso2, postresults
				
			
			*	Manually run post-lasso
			gen	lasso_step2_sample=1	if	e(sample)==1			
			global selected_step2_lasso `e(selected)'	/*`e(notpen)'*/
			svy:	reg `depvar' ${selected_step2_lasso}	`e(notpen)'	if	lasso_step2_sample==1
			
			est store postlasso_step2_manual
			predict	double	var1_foodexp_lasso	if	lasso_step2_sample==1,xb	
				/*if	((lasso_step2_sample==1)	|	(${study_sample}==1	&	year==10)), xb*/
			
			*	Shapley Decomposition
			shapley2, stat(r2)	indepvars(${selected_step2_lasso})
			est	store	lasso_step2_shapley
				
			*** To get proper decomposition estimate for the terms including higher order, we must manually run the command by grouping them.
			di "${selected_step2_lasso}"
			est restore postlasso_step2_manual
			shapley2, stat(r2)	group(lag_food_exp_pc_1 lag_food_exp_pc_2, ln_income_pc, num_FU_fam, couple_status_enum1, no_longer_married)
			*est	store	postlasso_step2_shapley
			
			
		}	//	Step 2
		
		*	Step 3
		if	`run_lasso_step3'==1	{
		
			
			*	Assume the outcome variable follows the Gamma distribution
			gen alpha1_foodexp_pc_lasso = (mean1_foodexp_lasso)^2 / var1_foodexp_lasso	//	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_lasso = var1_foodexp_lasso / mean1_foodexp_lasso	//	scale parameter of Gamma (beta)
			
			*	Construct CDF
			foreach	plan	in	thrifty /*low moderate liberal*/	{
			
				*	Generate resilience score. 
				*	Should include in-sample as well as out-of-sample to validate its OOS performance
				gen rho1_foodexp_pc_`plan'_ls = gammaptail(alpha1_foodexp_pc_lasso, foodexp_W_`plan'/beta1_foodexp_pc_lasso)	/*if	(lasso_step1_sample==1)	&	(lasso_step2_sample==1)*/	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	rho1_foodexp_pc_`plan'_ls "PFS (LASSO), `plan' plan"
				
			}
			
			**	Again, the following cvlasso takes too much time
			**	For now I will use ln(lambda)=4.36, the one found from cvlasso, lse below
			**	If there is major change in the specification, the following cvlasso should be executed
			**	As of 2020/9/4, we do not need the rest of the step 3 codes below.
			
			/*
			
				loc	depvar	rho1_foodexp_pc_thrifty_ls	//	only for thirfty plan
				
				/*
				cvlasso	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
					`familyvars'	`eduvars'	`foodvars'	`childvars'	`changevars'	if	 lasso_step1_sample==1	/*inrange(year,9,10)*/,	///
					/*lopt*/ lse	/*rolling	h(1)*/	seed(20200505)	 /*fe	prestd 	postres	ols*/	plotcv 
				est	store	lasso_step3_lse	
				
				cvlasso, postresult lse
				*/
				
				set	seed	20205020
				local	lambdaval=exp(6.5)
				lasso2	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
								`familyvars'	`eduvars'	`foodvars'	`childvars'	`regionvars'	if	lasso_step1_sample==1,	///
							ols lambda(`lambdaval') 
				
				est	store	lasso_step3_manual
				lasso2, postresults
				
				
				gen	lasso_step3_sample=1	if	e(sample)==1
				
				
				global selected_step3_lasso `e(selected)'
				loc	depvar	rho1_foodexp_pc_thrifty_ls
				svy:	reg `depvar' ${selected_step3_lasso}	if	lasso_step3_sample==1
				est store postlasso_step3_lse
				
				*	lopt gives too many variables, so we won't use decomposition for now.
				shapley2, stat(r2)
				est	store	lasso_step3_shapley
			
			*/
			
		}	//	Step 3
		
	}	//	LASSO
	
	*	Random Forest
	if	`run_rf'==1	{
		
		*	Variable Selection
		local	statevars	lag_food_exp_pc_1 /*-lag_avg_foodexp_pc_5*/	//	RF allows non-linearity, thus need not include higher polynomial terms
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse
		local	demovars	age_head_fam	/*age_head_fam_sq*/	HH_race_white	HH_race_color	marital_status_fam_enum1-marital_status_fam_enum5	///
							HH_female-gender_head_fam_enum2	age_spouse	/*age_spouse_sq*/	///
							housing_status_enum1-housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA	/*income_pc	avg_income_pc_sq	wealth_pc	avg_wealth_pc_sq*/
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	/*num_child_fam*/	/*family_comp_change_enum1-family_comp_change_enum9*/	couple_status_enum1-couple_status_enum5	/*head_status*/ spouse_new
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
							/*attend_college_head attend_college_spouse	college_yrs_head college_yrs_spouse	///
							hs_completed_head	college_completed	other_degree_head	grade_comp_head_fam	///
							hs_completed_head_interact college_completed_interact other_degree_head_interact	///
							hs_completed_spouse	college_comp_spouse	other_degree_spouse	grade_comp_spouse	///
							hs_completed_spouse_interact college_comp_spouse_interact other_degree_spouse_interact	*/
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	/*meal_together*/	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_resid_fam_enum1-state_resid_fam_enum52
		local	timevars	year_enum2-year_enum9
		
		
		*	Tune how large the value of iterations() need to be
		if	`tune_iter'==1	{
			loc	depvar	food_exp_pc
			generate out_of_bag_error1 = .
			generate validation_error = .
			generate iter1 = .
			local j = 0
			forvalues i = 10(5)500 {
				local j = `j' + 1
				rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	/*in_sample==1	&*/	${study_sample}==1, type(reg)	seed(20200505) iterations(`i') numvars(1)
				quietly replace iter1 = `i' in `j'
				quietly replace out_of_bag_error1 = `e(OOB_Error)' in `j'
				predict p if	out_of_sample==1
				quietly replace validation_error = `e(RMSE)' in `j'
				drop p
			}
			label variable out_of_bag_error1 "Out-of-bag error"
			label variable iter1 "Iterations"
			label variable validation_error "Validation error"
			scatter out_of_bag_error1 iter1, mcolor(blue) msize(tiny)	title(OOB Error and Validation Error) ||	scatter validation_error iter1, mcolor(red) msize(tiny)
		
		*	100 seems to be optimal
		}	//	tune_iter
		
			
		*	Tune the number of variables
		if	`tune_numvars'==1	{
			loc	depvar	food_exp_pc
			generate oob_error = .
			generate nvars = .
			generate val_error = .
			local j = 0
			forvalues i = 1(1)26 {
				local j = `j'+ 1
				rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
											`foodvars'	`childvars'	`changevars'	`regionvars'	if	/*in_sample==1	&*/	${study_sample}==1,	///
											type(reg)	seed(20200505) iterations(80) numvars(`i')
				quietly replace nvars = `i' in `j'
				quietly replace oob_error = `e(OOB_Error)' in `j'
				predict p	if	out_of_sample==1
				quietly replace val_error = `e(RMSE)' in `j'
				drop p
			}
			label variable oob_error "Out-of-bag error"
			label variable val_error "Validation error"
			label variable nvars "Number of variables randomly selected at each split"
			scatter oob_error nvars, mcolor(blue) msize(tiny)	title(OOB Error and Validation Error)	subtitle(by the number of variables)	///
			||	scatter val_error nvars, mcolor(red) msize(tiny)
			
			frame put val_error nvars, into(mydata)
			frame mydata {
				sort val_error, stable
				local min_val_err = val_error[1]
				local min_nvars = nvars[1]
			}
			frame drop mydata
			display "Minimum Error: `min_val_err'; Corresponding number of variables `min_nvars''"
			* (2020-09-05) Minimum Error: 1.780909180641174; Corresponding number of variables 23'
		}	//	tune_numvars
		
		
		*	Step 1
		if	`run_rf_step1'==1	{
			
			loc	depvar	food_exp_pc
			rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	/*in_sample==1	&*/	${study_sample}==1,	///
									type(reg)	iterations(80)	numvars(15)	seed(20200505) 
			* Variable importance plot
			matrix importance_mean = e(importance)
			svmat importance_mean
			generate importid_mean=""
			local mynames: rownames importance_mean
			local k: word count `mynames'
			if `k'>_N {
				set obs `k'
			}
			forvalues i = 1(1)`k' {
				local aword: word `i' of `mynames'
				local alabel: variable label `aword'
				if ("`alabel'"!="") qui replace importid_mean= "`alabel'" in `i'
				else qui replace importid_mean= "`aword'" in `i'
			}
			gsort	-importance_mean1
			graph hbar (mean) importance_mean1	in	1/12, over(importid_mean, sort(1) label(labsize(2))) ytitle(Importance) title(Feature Importance for Conditional Mean)
			graph	export	"${PSID_outRaw}/rf_feature_importance_step1.png", replace
			graph	close
			
			putexcel	set "${PSID_outRaw}/Feature_importance", sheet(mean) replace	/*modify*/
			putexcel	A3	=	matrix(importance_mean), names overwritefmt nformat(number_d1)
			
			predict	mean1_foodexp_rf
			*	"rforest" cannot predict residual, so we need to compute it manually
			gen	double e1_foodexp_rf	=	food_exp_pc	-	mean1_foodexp_rf
			gen e1_foodexp_sq_rf = (e1_foodexp_rf)^2
			
		}	//	Step 1
		
		*	Step 2
		if	`run_rf_step2'==1	{
			
			loc	depvar	e1_foodexp_sq_rf
			rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	/*in_sample==1	&*/	${study_sample}==1,	///
									type(reg)	iterations(80)	numvars(15)	seed(20200505) 
			
			* Variable importance plot
			matrix importance_var = e(importance)
			svmat importance_var
			generate importid_var=""
			local mynames: rownames importance_var
			local k: word count `mynames'
			if `k'>_N {
				set obs `k'
			}
			forvalues i = 1(1)`k' {
				local aword: word `i' of `mynames'
				local alabel: variable label `aword'
				if ("`alabel'"!="") qui replace importid_var= "`alabel'" in `i'
				else qui replace importid_var= "`aword'" in `i'
			}
			gsort	-importance_var1
			graph hbar (mean) importance_var1	in	1/12, over(importid_var, sort(1) label(labsize(2))) ytitle(Importance) title(Feature Importance for Conditional Variance)
			graph	export	"${PSID_outRaw}/rf_feature_importance_step2.png", replace
			graph	close
			
			putexcel	set "${PSID_outRaw}/Feature_importance", sheet(var) /*replace*/	modify
			putexcel	A3	=	matrix(importance_var), names overwritefmt nformat(number_d1)
			
			predict	var1_foodexp_rf	/*	in_sample==1	&	${study_sample}==1*/
		}	//	Step 2
		
		
		*	Step 3
		if	`run_rf_step3'==1	{
			
			*	Drop parameters generated from non-SRC sample
			*	Unlike GLM or LASSO, "rforest" command does not allow missing values in dependent variable, thus cannot predict values only for SRC samples from the previous step
			*	As a roundabout, we first predict values for all sample, and drop them for non-SRC sample.
			*	This shouldn't be a big issue as "rforest" are still conducted for the SRC sample only by using "if" in "rforest" command
			*	One small issue is that "rforest" does not specify which observations are used in the estimation (i.e. e(sample) does not exist)
			replace	mean1_foodexp_rf=.	if	${study_sample}!=1	|	year==1
			replace	var1_foodexp_rf=.	if	${study_sample}!=1	|	year==1
			
			*	Assume the outcome variable follows the Gamma distribution
			gen alpha1_foodexp_pc_rf = (mean1_foodexp_rf)^2 / var1_foodexp_rf	//	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_rf = var1_foodexp_rf / mean1_foodexp_rf	//	scale parameter of Gamma (beta)
			
			*	Construct CDF
			foreach	plan	in	thrifty /*low moderate liberal*/	{
				
				*	Generate resilience score. 
				*	Should include in-sample as well as out-of-sample to validate its OOS performance
				gen rho1_foodexp_pc_`plan'_rf = gammaptail(alpha1_foodexp_pc_rf, foodexp_W_`plan'/beta1_foodexp_pc_rf)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	rho1_foodexp_pc_`plan'_rf "PFS (Random Forest), `plan' plan"
			}
			
			*	As of 2020-09-05, we don't need the rest of the step 3 code below, as we will use OLS
			
			/*
			tempfile	bef_rf_step3
			save		`bef_rf_step3'
				keep	if	!mi(rho1_foodexp_pc_thrifty_rf)
				loc	depvar	rho1_foodexp_pc_thrifty_rf
				rforest	`depvar'	`statevars'		`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
										`foodvars'	`childvars'	`changevars'	`regionvars'	if	in_sample==1, type(reg)	iterations(100)	numvars(21)	seed(20200505) 
				predict	rs_rf_hat
				
				* Variable importance plot
				matrix importance_rs = e(importance)
				svmat importance_rs
				generate importid_rs=""
				local mynames: rownames importance_rs
				local k: word count `mynames'
				if `k'>_N {
					set obs `k'
				}
				forvalues i = 1(1)`k' {
					local aword: word `i' of `mynames'
					local alabel: variable label `aword'
					if ("`alabel'"!="") qui replace importid_rs= "`alabel'" in `i'
					else qui replace importid_rs= "`aword'" in `i'
				}
				gsort	-importance_rs1
				graph hbar (mean) importance_rs1	in	1/12, over(importid_var, sort(1) label(labsize(2))) ytitle(Importance) title(Feature Importance for Resilience Score)
				graph	export	"${PSID_outRaw}/rf_feature_importance_step3.png", replace
				graph	close
			use		`bef_rf_step3', clear
			*/
		}	//	Step 3		
	}	//	Random Forest
	
	
	/****************************************************************
		SECTION 2: Summary statistics
	****************************************************************/		
	
	local	run_sumstat	1
	
	if	`run_sumstat'==1	{
	
	*	Summary Statistics (Table 3)
	
		eststo drop	Total SRC	SEO	Imm
		
		local	estimation_year		inrange(year,2,10)
				
		*	Declare variables
		local	demovars	age_head_fam	HH_race_white	HH_race_color	marital_status_cat	HH_female	
		local	econvars	income_pc	food_exp_pc
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	familyvars	num_FU_fam ratio_child
		local	eduvars		highdegree_NoHS	highdegree_HS	highdegree_somecol	highdegree_col
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		
		local	sumvars	`demovars'	`eduvars'		`empvars'	`healthvars'	`econvars'	`familyvars'		`foodvars'		`changevars'

		*cap	drop	sample_source?
		*tab sample_source, gen(sample_source)
		svy, subpop(if ${study_sample} & !mi(rho1_foodexp_pc_thrifty_ols)): mean	`sumvars'
		estat sd
		estadd matrix mean = r(mean)
		estadd matrix sd = r(sd)
		estadd scalar N = e(N_sub), replace
		eststo	Total
		
		svy, subpop(if ${study_sample} & !mi(rho1_foodexp_pc_thrifty_ols)	&	sample_source_SRC==1): mean  `sumvars'
		estat sd
		estadd matrix mean = r(mean)
		estadd matrix sd = r(sd)
		estadd scalar N = e(N_sub), replace
		eststo	SRC
		
		svy, subpop(if ${study_sample} & !mi(rho1_foodexp_pc_thrifty_ols)	&	sample_source_SEO==1): mean  `sumvars'
		estat sd
		estadd matrix mean = r(mean)
		estadd matrix sd = r(sd)
		estadd scalar N = e(N_sub), replace
		eststo	SEO
		
		
		/*
		svy: mean income_pc if `estimation_sample'
		estadd matrix mean = r(table)[1,1...]
		estadd matrix sd = r(table)[2,1...]
		eststo	Total
		svy, subpop(${study_sample}): mean `sumvars'
		estadd matrix mean = r(table)[1,1...]
		estadd matrix sd = r(table)[2,1...]
		estadd scalar N = e(N_sub), replace
		eststo	SRC
		svy, subpop(sample_source_SEO): mean `sumvars'
		estadd matrix mean = r(table)[1,1...]
		estadd matrix sd = r(table)[2,1...]
		estadd scalar N = e(N_sub), replace
		eststo	SEO
		svy, subpop(sample_source_IMM): mean `sumvars'
		estadd matrix mean = r(table)[1,1...]
		estadd matrix sd = r(table)[2,1...]
		estadd scalar N = e(N_sub), replace
		eststo	Imm
		*/
			
		
		esttab *Total SRC SEO using "${PSID_outRaw}/Sumstats.csv", replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ csv ///
		/*addnotes(Includes households in LASSO regression. SRC stands for Survey Research Center composed of nationally representative households, SEO stands for Survey Economic Opportunities composed of low income households, and Immigrants are those newly added to the PSID in 1997 and 1999)*/
		
		esttab *Total SRC SEO using "${PSID_outRaw}/Sumstats.tex", replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ tex ///
		/*addnotes(Includes households in LASSO regression. SRC stands for Survey Research Center composed of nationally representative households, SEO stands for Survey Economic Opportunities composed of low income households, and Immigrants are those newly added to the PSID in 1997 and 1999)*/
		
	}			
	
	/****************************************************************
		SECTION 3: Categorization
	****************************************************************/	
	
	*	Categorization	//	Generate FS category variables from the PFS
	local	run_categorization	1	

	*	Categorization	
	if	`run_categorization'==1	{
						
		
			*	Summary Statistics of Indicies
			summ	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	/*rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf*/	///
					if	inlist(year,2,3,9,10)
			
			*	For food security threshold value, we use the ratio from the annual USDA reports.
			*	(https://www.ers.usda.gov/topics/food-nutrition-assistance/food-security-in-the-us/readings/#reports)
			
			*** One thing we need to be careful is that, we need to match the USDA ratio to the "population ratio(weighted)", NOT the "sample ratio(unweighted)"
			*	To get population ratio, we should use "svy: mean"	or "svy: proportion"
			*	The best way to do is let STATA find them automatically, but for now (2020/10/6) I will find them manually.
				*	One idea I have to do it automatically is to use loop(while) until we get the threshold value matching the USDA ratio.
			*	Due to time constraint, I only found it for 2015 (year=9) for OLS, which is needed to generate validation table.
			
			
			local	prop_FI_1	=	0.101	// 1999: 10.1% are food insecure (7.1% are low food secure, 3.0% are very low food secure)
			local	prop_FI_2	=	0.107	// 2001: 10.7% are food insecure (7.4% are low food secure, 3.3% are very low food secure)
			local	prop_FI_3	=	0.112	// 2003: 11.2% are food insecure (7.7% are low food secure, 3.5% are very low food secure)
			local	prop_FI_4	=	0.110	// 2005: 11.0% are food insecure (7.1% are low food secure, 3.9% are very low food secure)
			local	prop_FI_5	=	0.111	// 2007: 11.1% are food insecure (7.0% are low food secure, 4.1% are very low food secure)
			local	prop_FI_6	=	0.147	// 2009: 14.7% are food insecure (9.0% are low food secure, 5.7% are very low food secure)
			local	prop_FI_7	=	0.149	// 2011: 14.9% are food insecure (9.2% are low food secure, 5.7% are very low food secure)
			local	prop_FI_8	=	0.143	// 2013: 14.3% are food insecure (8.7% are low food secure, 5.6% are very low food secure)
			local	prop_FI_9	=	0.127	// 2015: 12.7% are food insecure (7.7% are low food secure, 5.0% are very low food secure)
			local	prop_FI_10	=	0.118	// 2017: 11.8% are food insecure (7.3% are low food secure, 4.5% are very low food secure)
			
			local	prop_VLFS_1		=	0.030	// 1999: 10.1% are food insecure (7.1% are low food secure, 3.0% are very low food secure)
			local	prop_VLFS_2		=	0.033	// 2001: 10.7% are food insecure (7.4% are low food secure, 3.3% are very low food secure)
			local	prop_VLFS_3		=	0.035	// 2003: 11.2% are food insecure (7.7% are low food secure, 3.5% are very low food secure)
			local	prop_VLFS_4		=	0.039	// 2005: 11.0% are food insecure (7.1% are low food secure, 3.9% are very low food secure)
			local	prop_VLFS_5		=	0.041	// 2007: 11.1% are food insecure (7.0% are low food secure, 4.1% are very low food secure)
			local	prop_VLFS_6		=	0.057	// 2009: 14.7% are food insecure (9.0% are low food secure, 5.7% are very low food secure)
			local	prop_VLFS_7		=	0.057	// 2011: 14.9% are food insecure (9.2% are low food secure, 5.7% are very low food secure)
			local	prop_VLFS_8		=	0.056	// 2013: 14.3% are food insecure (8.7% are low food secure, 5.6% are very low food secure)
			local	prop_VLFS_9		=	0.050	// 2015: 12.7% are food insecure (7.7% are low food secure, 5.0% are very low food secure)
			local	prop_VLFS_10	=	0.045	// 2017: 11.8% are food insecure (7.3% are low food secure, 4.5% are very low food secure)
		
			*	Categorize food security status based on the PFS.
			 quietly	{
				foreach	type	in	ols	ls	rf	{
					foreach	plan	in	thrifty /*low moderate liberal*/	{
						
						gen	rho1_`plan'_FS_`type'	=	0	if	!mi(rho1_foodexp_pc_`plan'_`type')	//	Food secure
						gen	rho1_`plan'_FI_`type'	=	0	if	!mi(rho1_foodexp_pc_`plan'_`type')	//	Food insecure (low food secure and very low food secure)
						gen	rho1_`plan'_LFS_`type'	=	0	if	!mi(rho1_foodexp_pc_`plan'_`type')	//	Low food secure
						gen	rho1_`plan'_VLFS_`type'	=	0	if	!mi(rho1_foodexp_pc_`plan'_`type')	//	Very low food secure
						gen	rho1_`plan'_cat_`type'	=	0	if	!mi(rho1_foodexp_pc_`plan'_`type')	//	Categorical variable: FS, LFS or VLFS
						
						/*	Since we are currently using the USDA FS status as an external threshold for FS/FI categorization using CB measure,
							, we cannot categorize when there is no data of the USDA status unless we use other external source. */
						*replace	rho1_`plan'_FI_`type'=.	if	!inlist(year,2,3,9,10)
						*replace	rho1_`plan'_FS_`type'=.	if	!inlist(year,2,3,9,10)
						
						*	Generate a variable for the threshold PFS
						gen	PFS_threshold_`type'=.
						
						foreach	year	in	2	3	4	5	6	7	8	9	10	{
							
							di	"current loop is `plan', `type' in year `year'"
							xtile `plan'_pctile_`type'_`year' = rho1_foodexp_pc_`plan'_`type' if !mi(rho1_foodexp_pc_`plan'_`type')	&	year==`year', nq(1000)
								
							*replace	rho1_`plan'_FI_`type'	=	1	if	inrange(`plan'_pctile_`type'_`year',1,`prop_FI_`year'')	&	year==`year'	//	Food insecure
							*replace	rho1_`plan'_FS_`type'	=	1	if	inrange(`plan'_pctile_`type'_`year',`prop_FI_`year''+1,1000)	&	year==`year'	//	Highly secure
							
							* We use loop to find the threshold value for categorizing households as food (in)secure
							local	counter 	=	1	//	reset counter
							local	ratio_FI	=	0	//	reset FI population ratio
							local	ratio_VLFS	=	0	//	reset VLFS population ratio
							
							foreach	indicator	in	FI	VLFS	{
								
								local	counter 	=	1	//	reset counter
								local	ratio_`indicator'	=	0	//	reset population ratio
							
								* To decrease running time, we first loop by 10 
								while (`counter' < 1000 & `ratio_`indicator''<`prop_`indicator'_`year'') {	//	Loop until population ratio > USDA ratio
									
									qui di	"current indicator is `indicator', counter is `counter'"
									qui	replace	rho1_`plan'_`indicator'_`type'=1	if	year==`year'	&	inrange(`plan'_pctile_`type'_`year',1,`counter')	//	categorize certain number of households at bottom as FI
									qui	svy, subpop(year_enum`year'): mean 	rho1_`plan'_`indicator'_`type'	//	Generate population ratio
									local ratio_`indicator' = _b[rho1_`plan'_`indicator'_`type']
									
									local counter = `counter' + 10	//	Increase counter by 10
								}

								*	Since we first looped by unit of 10, we now have to find to exact value by looping 1 instead of 10.
								qui di "internediate counter is `counter'"
								local	counter=`counter'-10	//	Adjust the counter, since we added extra 10 at the end of the first loop

								while (`counter' > 1 & `ratio_`indicator''>`prop_`indicator'_`year'') {	//	Loop until population ratio < USDA ratio
									
									qui di "counter is `counter'"
									qui	replace	rho1_`plan'_`indicator'_`type'=0	if	year==`year'	&	inrange(`plan'_pctile_`type'_`year',`counter',1000)
									qui	svy, subpop(year_enum`year'): mean 	rho1_`plan'_`indicator'_`type'
									local ratio_`indicator' = _b[rho1_`plan'_`indicator'_`type']
									
									local counter = `counter' - 1
								}
								qui di "Final counter is `counter'"

								*	Now we finalize the threshold value - whether `counter' or `counter'+1
									
									*	Counter
									local	diff_case1	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')

									*	Counter + 1
									qui	replace	rho1_`plan'_`indicator'_`type'=1	if	year==`year'	&	inrange(`plan'_pctile_`type'_`year',1,`counter'+1)
									qui	svy, subpop(year_enum`year'): mean 	rho1_`plan'_`indicator'_`type'
									local	ratio_`indicator' = _b[rho1_`plan'_`indicator'_`type']
									local	diff_case2	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')
									qui	di "diff_case2 is `diff_case2'"

									*	Compare two threshold values and choose the one closer to the USDA value
									if	(`diff_case1'<`diff_case2')	{
										global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'
									}
									else	{	
										global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'+1
									}
								
								*	Categorize households based on the finalized threshold value.
								qui	{
									replace	rho1_`plan'_`indicator'_`type'=1	if	year==`year'	&	inrange(`plan'_pctile_`type'_`year',1,${threshold_`indicator'_`plan'_`type'_`year'})
									replace	rho1_`plan'_`indicator'_`type'=0	if	year==`year'	&	inrange(`plan'_pctile_`type'_`year',${threshold_`indicator'_`plan'_`type'_`year'}+1,1000)		
								}	
								di "thresval of `indicator' in year `year' is ${threshold_`indicator'_`plan'_`type'_`year'}"
							}	//	indicator
							
							*	Food secure households
							replace	rho1_`plan'_FS_`type'=0	if	year==`year'	&	inrange(`plan'_pctile_`type'_`year',1,${threshold_FI_`plan'_`type'_`year'})
							replace	rho1_`plan'_FS_`type'=1	if	year==`year'	&	inrange(`plan'_pctile_`type'_`year',${threshold_FI_`plan'_`type'_`year'}+1,1000)
							
							*	Low food secure households
							replace	rho1_`plan'_LFS_`type'=1	if	year==`year'	&	rho1_`plan'_FI_`type'==1	&	rho1_`plan'_VLFS_`type'==0	//	food insecure but NOT very low food secure households			
							
							*	Categorize households into one of the three values: FS, LFS and VLFS						
							replace	rho1_`plan'_cat_`type'=1	if	year==`year'	&	rho1_`plan'_VLFS_`type'==1
							replace	rho1_`plan'_cat_`type'=2	if	year==`year'	&	rho1_`plan'_LFS_`type'==1
							replace	rho1_`plan'_cat_`type'=3	if	year==`year'	&	rho1_`plan'_FS_`type'==1
							assert	rho1_`plan'_cat_`type'!=0	if	year==`year'
							
							*	Save threshold PFS as global macros and a variable, the average of the maximum PFS among the food insecure households and the minimum of the food secure households					
							qui	summ	rho1_foodexp_pc_`plan'_`type'	if	year==`year'	&	rho1_`plan'_FS_`type'==1	//	Minimum PFS of FS households
							local	min_FS_PFS	=	r(min)
							qui	summ	rho1_foodexp_pc_`plan'_`type'	if	year==`year'	&	rho1_`plan'_FI_`type'==1	//	Maximum PFS of FI households
							local	max_FI_PFS	=	r(max)
							
							*	Save the threshold PFS
							replace	PFS_threshold_`type'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2		if	year==`year'
							*global	PFS_threshold_`type'_`year'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2
							
							
						}	//	year
						
						label	var	rho1_`plan'_FI_`type'	"Food Insecurity (PFS) (`type')"
						label	var	rho1_`plan'_FS_`type'	"Food security (PFS) (`type')"
						label	var	rho1_`plan'_LFS_`type'	"Low food security (PFS) (`type')"
						label	var	rho1_`plan'_VLFS_`type'	"Very low food security (PFS) (`type')"
						label	var	rho1_`plan'_cat_`type'	"PFS category: FS, LFS or VLFS"
						
					}	//	plan
				}	//	type
				
				lab	define	PFS_category	1	"Very low food security (VLFS)"	2	"Low food security (LFS)"	3	"Food security(FS)"
				lab	value	rho1*_cat_*	PFS_category
				
			 }	//	qui
			
			
			*	Graph the PFS threshold for each year
			cap drop templine
			gen templine=0.6
			twoway	(connected PFS_threshold_ols year2 if fam_ID_1999==1, lpattern(dot)	mlabel(PFS_threshold_ols) mlabposition(12) mlabformat(%9.3f))	///
					(line templine year2 if fam_ID_1999==1, lpattern(dash)),	///
					/*title(Probability Threshold for being Food Secure)*/	ytitle(Probability)	xtitle(Year)	xlabel(2001(2)2017) legend(off)	///
					name(PFS_Threshold, replace)	graphregion(color(white)) bgcolor(white)
					
			graph	export	"${PSID_outRaw}/PFS_Thresholds.png", replace
			graph	close
			
			drop	templine
	
			*	Validation Result
				sort	fam_ID_1999	year
				label	define	valid_result	1	"Classified as food secure"	///
												2	"Mis-classified as food secure"	///
												3	"Mis-classified as food insecure"	///
												4	"Classified as food insecure"
				
				*	USDA
				gen		valid_result_USDA	=	1	if	inrange(year,10,10)	&	!mi(l.rho1_thrifty_FS_ols)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp==1
				replace	valid_result_USDA	=	2	if	inrange(year,10,10)	&	!mi(l.rho1_thrifty_FS_ols)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp==0
				replace	valid_result_USDA	=	3	if	inrange(year,10,10)	&	!mi(l.rho1_thrifty_FS_ols)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp==1
				replace	valid_result_USDA	=	4	if	inrange(year,10,10)	&	!mi(l.rho1_thrifty_FS_ols)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp==0
				/*
					*	By sub-sample
					forval	sampleno=1/3	{
						
						gen		valid_result_USDA_`sampleno'	=	.
						replace	valid_result_USDA_`sampleno'	=	1	if	inrange(year,10,10)	&	!mi(l.rho1_thrifty_FS_ols)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp==1	&	sample_source==`sampleno'
						replace	valid_result_USDA_`sampleno'	=	2	if	inrange(year,10,10)	&	!mi(l.rho1_thrifty_FS_ols)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp!=1	&	sample_source==`sampleno'
						replace	valid_result_USDA_`sampleno'	=	3	if	inrange(year,10,10)	&	!mi(l.rho1_thrifty_FS_ols)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp==1	&	sample_source==`sampleno'
						replace	valid_result_USDA_`sampleno'	=	4	if	inrange(year,10,10)	&	!mi(l.rho1_thrifty_FS_ols)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp!=1	&	sample_source==`sampleno'
						
					}
					
					rename	(valid_result_USDA_1	valid_result_USDA_2		valid_result_USDA_3)	///
							(valid_result_USDA_SRC	valid_result_USDA_SEO	valid_result_USDA_IMM)
							
					label	var	valid_result_USDA		"Validation Result of USDA"
					label	var	valid_result_USDA_SRC	"Validation Result of USDA in SRC"
					label	var	valid_result_USDA_SEO	"Validation Result of USDA in SEO"
					label	var	valid_result_USDA_IMM	"Validation Result of USDA in Immigrants"
				*/
				
				*	GLM, LASSO and RF
				foreach	type	in	ols	ls	rf	{
					
					*	All sample
					
					gen		valid_result_`type'	=	.
					replace	valid_result_`type'	=	1	if	inrange(year,10,10)	&	!mi(l.fs_cat_fam_simp)	&	l.rho1_thrifty_FS_`type'==1	&	fs_cat_fam_simp==1	//	fs_scale_fam_rescale==1
					replace	valid_result_`type'	=	2	if	inrange(year,10,10)	&	!mi(l.fs_cat_fam_simp)	&	l.rho1_thrifty_FS_`type'==1	&	fs_cat_fam_simp==0	//	fs_scale_fam_rescale!=1
					replace	valid_result_`type'	=	3	if	inrange(year,10,10)	&	!mi(l.fs_cat_fam_simp)	&	l.rho1_thrifty_FS_`type'==0	&	fs_cat_fam_simp==1	//	fs_scale_fam_rescale==1
					replace	valid_result_`type'	=	4	if	inrange(year,10,10)	&	!mi(l.fs_cat_fam_simp)	&	l.rho1_thrifty_FS_`type'==0	&	fs_cat_fam_simp==0	//	fs_scale_fam_rescale!=1
					label	var	valid_result_`type'	"Validation Result of `type'"
				/*	
					*	By subsample
					forval	sampleno=1/3	{
						
						gen		valid_result_`type'_`sampleno'	=	.
						replace	valid_result_`type'_`sampleno'	=	1	if	inrange(year,10,10)	&	!mi(l.fs_cat_fam_simp)	&	l.rho1_thrifty_FS_`type'==1	&	fs_cat_fam_simp==1	/*fs_scale_fam_rescale==1*/	&	sample_source==`sampleno'
						replace	valid_result_`type'_`sampleno'	=	2	if	inrange(year,10,10)	&	!mi(l.fs_cat_fam_simp)	&	l.rho1_thrifty_FS_`type'==1	&	fs_cat_fam_simp!=1	/*fs_scale_fam_rescale!=1*/	&	sample_source==`sampleno'
						replace	valid_result_`type'_`sampleno'	=	3	if	inrange(year,10,10)	&	!mi(l.fs_cat_fam_simp)	&	l.rho1_thrifty_FS_`type'==0	&	fs_cat_fam_simp==1	/*fs_scale_fam_rescale==1*/	&	sample_source==`sampleno'
						replace	valid_result_`type'_`sampleno'	=	4	if	inrange(year,10,10)	&	!mi(l.fs_cat_fam_simp)	&	l.rho1_thrifty_FS_`type'==0	&	fs_cat_fam_simp!=1	/*fs_scale_fam_rescale!=1*/	&	sample_source==`sampleno'
						
					}
					
					rename	(valid_result_`type'_1		valid_result_`type'_2	valid_result_`type'_3)	///
							(valid_result_`type'_SRC	valid_result_`type'_SEO	valid_result_`type'_IMM)
							
					label	var	valid_result_`type'_SRC	"Validation Result of `type' in SRC"
					label	var	valid_result_`type'_SEO	"Validation Result of `type' in SEO"
					label	var	valid_result_`type'_IMM	"Validation Result of `type' in Immigrants"
				*/
				}
				
				label	values	valid_result_*	valid_result
				
				
			*	Scatterplot
				*	Compare food security status in 2015 (in-sample) and USDA food security score in 2017 (out-of-sample)
				*	To do this, we need the threshold PFS for being food secure in 2015 
				
				sort	fam_ID_1999	year
				
				foreach	type	in	ols	ls	rf	{
					
					qui	summ	rho1_foodexp_pc_thrifty_`type'	if	rho1_thrifty_FS_`type'==0	&	year==9	//	Maximum PFS of households categorized as food insecure
					local	max_pfs_thrifty_`type'	=	r(max)
					qui	summ	rho1_foodexp_pc_thrifty_`type'	if	rho1_thrifty_FS_`type'==1	&	year==9	//	Minimum PFS of households categorized as food secure
					local	min_pfs_thrifty_`type'	=	r(min)

					global	thresval_`type'	=	(`max_pfs_thrifty_`type''	+	`min_pfs_thrifty_`type'')/2	//	Average of the two scores above is a threshold value.
					
				}
				
				/*
				sort rho1_foodexp_pc_thrifty_ols
				br rho1_foodexp_pc_thrifty_ols rho1_thrifty_FS_ols if year==9
				
				sort rho1_foodexp_pc_thrifty_ls
				br rho1_foodexp_pc_thrifty_ls rho1_thrifty_FS_ls if year==9
				
				sort rho1_foodexp_pc_thrifty_rf
				br rho1_foodexp_pc_thrifty_rf rho1_thrifty_FS_rf if year==9
				
				
				*	As of 2020/9/5, threshold scores are 0.4020(OLS), 0.4527(LASSO), 0.1540(R.Forest)
				global	thresval_ols=0.4007
				global	thresval_ls=0.4543
				global	thresval_rf=0.1611
				
				*/
				
			*	Validation table
			
			eststo drop	valid_result*
			
			foreach	type in USDA	ols	ls	rf	{
				
				di "Validation result of `type' in pooled sample"
				svy: proportion valid_result_`type' if !mi(valid_result_USDA)	&	!mi(valid_result_ols)	&	!mi(valid_result_ls)	&	!mi(valid_result_rf)
				estadd matrix mean = r(table)[1,1...]
				eststo	valid_result_`type'
						
				/*
				foreach sample in SRC SEO IMM	{
					
					di "Validation result of `type' in `sample'"
					*svy: proportion	valid_result_`type'_`sample'
					svy, subpop(sample_source_`sample'): proportion valid_result_`type' // Using "subpop" option gives accurate standard error, but it doesn't matter in this case as it still gives the same point estimate.
					estadd matrix mean = r(table)[1,1...]
					estadd scalar N = e(N_sub), replace
					eststo	valid_result_`type'_`sample'
		
				}
				*/
								
			}				
			
		local	result_output_list	valid_result_USDA	/*valid_result_USDA_SRC	valid_result_USDA_SEO	valid_result_USDA_IMM*/	///
									valid_result_ols	/*valid_result_ols_SRC	valid_result_ols_SEO	valid_result_ols_IMM*/	///
									valid_result_ls		/*valid_result_ls_SRC		valid_result_ls_SEO		valid_result_ls_IMM*/	///
									valid_result_rf		/*valid_result_rf_SRC		valid_result_rf_SEO		valid_result_rf_IMM*/
		
		esttab `result_output_list' using "${PSID_outRaw}/valid_result.csv", replace ///
		cells("mean(pattern(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants")	///
		title (Validation of 2017 Food Security Prediction) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ csv ///
		addnotes(Sample include households surveyed in 2017)
		
		esttab `result_output_list' using "${PSID_outRaw}/valid_result.tex", replace ///
		cells("mean(pattern(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants")	///
		title (Validation of 2017 Food Security Prediction) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ tex ///
		addnotes(Sample include households surveyed in 2017)

	}	//	Categorization			

	
	/****************************************************************
		SECTION 4: Correlation between the PFS and the USDA measure
	****************************************************************/	
	
	*	Correlation	//	Examine correlation between the PFS and the USDA measure
	local	reg_correlation		1	//	Regression coefficient, rank correlation Kolmogorov–Smirnov.
	local	oos_pred_power	0	//	Out-of-sample predictive power
	local	supplement_analysis	0	//	Kolmogorov–Smirnov (between LASSO and RF), distribution across ML PFS, etc.
	
	*	Regression of the USDA scale on the PFS
	if	`reg_correlation'==1	{
		
		foreach	type	in	ols	/*ls	rf*/	{
			
			*	Regression
			svy, subpop(${study_sample}): reg fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_`type'
			est	sto	corr_USDA_`type'_lin_noFE
			svy, subpop(${study_sample}): reg fs_scale_fam_rescale	c.rho1_foodexp_pc_thrifty_`type'##c.rho1_foodexp_pc_thrifty_`type'
			est	sto	corr_USDA_`type'_nonlin_noFE
			svy, subpop(${study_sample}): reg fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_`type'	i.year ib0.state_resid_fam
			est	sto	corr_USDA_`type'_lin_FE
			svy, subpop(${study_sample}): reg fs_scale_fam_rescale	c.rho1_foodexp_pc_thrifty_`type'##c.rho1_foodexp_pc_thrifty_`type' i.year ib0.state_resid_fam
			est	sto	corr_USDA_`type'_nonlin_FE
			
			*	Output (Table A4 of 2020/11/16 draft)
			esttab	corr_USDA_`type'_lin_noFE	corr_USDA_`type'_nonlin_noFE	corr_USDA_`type'_lin_FE		corr_USDA_`type'_nonlin_FE	using "${PSID_outRaw}/USDA_PFS_correlation_`type'.csv", ///
			cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
			title(Regression of the USDA scale on PFS(`type')) replace
			
			esttab	corr_USDA_`type'_lin_noFE	corr_USDA_`type'_nonlin_noFE	corr_USDA_`type'_lin_FE		corr_USDA_`type'_nonlin_FE	using "${PSID_outRaw}/USDA_PFS_correlation_`type'.tex", ///
			cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
			title(Regression of the USDA scale on PFS(`type')) replace
			
						
		*	Spearman's rank correlation
			
			*	Pooled
			spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	///
				if ${study_sample}	&	inlist(year,2,3,9,10),	stats(rho obs p)
			ktau 	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	///
				if ${study_sample}	&	inlist(year,2,3,9,10), stats(taua taub p)
			
			*	By year
			*spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==2,	stats(rho obs p)
			*ktau	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==2,	stats(taua taub score se p)
			*spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==3,	stats(rho obs p)
			*spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==9,	stats(rho obs p)
			*spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==10, stats(rho obs p)
			
			*	Summarize PFS (https://www.stata.com/support/faqs/statistics/percentiles-for-survey-data/)
			summ	fs_scale_fam_rescale 		if ${study_sample}==1	&	inlist(year,2,3,9,10)	&	!mi(rho1_foodexp_pc_thrifty_ols)  [aweight=weight_multi12], detail
			summ	rho1_foodexp_pc_thrifty_ols if ${study_sample}==1	&	inlist(year,2,3,9,10)	&	!mi(fs_scale_fam_rescale)		  [aweight=weight_multi12], detail
						
			*	Mean and St.dev (unadjusted)
			*summ fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols if !mi(fs_scale_fam_rescale) & !mi(rho1_foodexp_pc_thrifty_ols)
			
			*	Density Estimate of Food Security Indicator (Figure A1)
			graph twoway 		(kdensity fs_scale_fam_rescale			if	inlist(year,2,3,9,10)	&	!mi(rho1_foodexp_pc_thrifty_ols))	///
								(kdensity rho1_foodexp_pc_thrifty_ols	if	inlist(year,2,3,9,10)	&	!mi(fs_scale_fam_rescale)),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)		///
								name(thrifty, replace) graphregion(color(white)) bgcolor(white)		///
								legend(lab (1 "USDA scale") lab(2 "PFS") rows(1))				
			/*	note("* The sample includes the waves where both measures are available ('01,'03,'15,'17))"	///
								"* (Unadjusted) Mean/SD: 0.97/0.10(USDA), 0.82/0.22(PFS)")	*/				
			graph	export	"${PSID_outRaw}/Density_USDA_PFS.png", replace
		}		
	}		
	
	*	Out-of-sample predictive power
	**	As of 2021/1/2, we no longer use OOS-predictive power. If we want to re-use it, we need to re-run this file with in_sample==1 (2001 to 2015) only.
	if	`oos_pred_power'==1	{
	
		*	Out-of-sample wellbeing predictive accuracy of the measures (RMSE)
		*	Bivariate regression of USDA food security score on the previous score (USDA, PFS under different construction methods)
		*** As of 12/8/2020, I fixed the code here such that I regress 2017 USDA on the predicted PFS (previously I regressed 2017 USDA on the realized 2015 PFS)
		
			*	Specifiy subsample to be used
				
				*	USDA & PFS available (for main paper)
				cap drop pred_power_sample_main
				qui	reg	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	/*l.rho1_foodexp_pc_thrifty_ols*/	if year_enum10==1
				gen pred_power_sample_main=1 if e(sample)
				
				*	USDA, PFS(GLM), PFS(LASSO), PFS(RF) available (for appendix)
				cap drop pred_power_sample_ML
				qui	reg	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	/*l.rho1_foodexp_pc_thrifty_ols*/	if year_enum10==1
				gen pred_power_sample_ML=1 		if e(sample)
				qui	reg	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ls	/*l.rho1_foodexp_pc_thrifty_ls*/	if year_enum10==1
				replace pred_power_sample_ML=.	if !e(sample)
				qui	reg	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_rf	/*l.rho1_foodexp_pc_thrifty_rf*/	if year_enum10==1
				replace pred_power_sample_ML=.	if !e(sample)
				
			*	Specify which sample to use
			*	We can actually write a loop to generate both, one for main paper and one for appendix. For now I will use local macro to define manually.
			local	pred_power_sample	pred_power_sample_ML
			
			*	Mean of the outcome
			svy, subpop(year_enum10): mean	fs_scale_fam_rescale	//	if	inrange(year,10,10)
			scalar	USDA_mean	=	e(b)[1,1]
			
			*	USDA
							
				*	All sample
				cap drop pred_power_sample
				reg	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	/*l.rho1_foodexp_pc_thrifty_ols*/	if year_enum10==1
				gen pred_power_sample=1		if e(sample)
				reg	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	/*l.fs_scale_fam_rescale*/	if	pred_power_sample==1
				
				svy, subpop(pred_power_sample): proportion valid_result_USDA valid_result_ols
				
				
				local	USDA_rmse_all			=	e(rmse)
				local	USDA_rmse_all_bymean	=	e(rmse)	/	USDA_mean
			
			/*
			*	USDA
							
				*	All sample
				reg	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	`pred_power_sample'==1
				local	USDA_rmse_all			=	e(rmse)
				local	USDA_rmse_all_bymean	=	e(rmse)	/	USDA_mean
				
				
				*	SEO & Imm
				qui	reg	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	inrange(year,10,10)	&	inrange(sample_source,2,3)
				local	USDA_rmse_sub			=	e(rmse)
				local	USDA_rmse_sub_bymean	=	e(rmse)	/	USDA_mean
			*/
				
			*	PFS scores
			foreach	type	in	ols	ls	rf	{
				
				*	All sample
				reg	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_`type'	/*l.rho1_foodexp_pc_thrifty_`type'*/	if	`pred_power_sample'==1
				local	`type'_rmse_all	=	e(rmse)
				local	`type'_rmse_all_bymean	=	e(rmse)	/	USDA_mean
				
				/*
				*	Sub sample
				qui	reg	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_`type'	if	inrange(year,10,10)	&	inrange(sample_source,2,3)
				local	`type'_rmse_sub	=	e(rmse)
				local	`type'_rmse_sub_bymean	=	e(rmse)	/	USDA_mean
				*/
				
			}
			
			*	Divide RMSE by mean outcome
			*	if	greater than 0.5, it is not good for prediction. If less than 0.2, then it is good for predion.

			cap	mat	drop	rmse_all	rmse_eval_all	rmse_all	/*rmse_sub	rmse_eval_sub*/	rmse_eval_table
			mat	define		rmse_all		=	`USDA_rmse_all'	\	`ols_rmse_all'	\	`ls_rmse_all'	\	`rf_rmse_all'
			mat	define		rmse_eval_all	=	`USDA_rmse_all_bymean'	\	`ols_rmse_all_bymean'	\	`ls_rmse_all_bymean'	\	`rf_rmse_all_bymean'
			*mat	define		rmse_sub		=	`USDA_rmse_sub'	\	`ols_rmse_sub'	\	`ls_rmse_sub'	\	`rf_rmse_sub'
			*mat	define		rmse_eval_sub	=	`USDA_rmse_sub_bymean'	\	`ols_rmse_sub_bymean'	\	`ls_rmse_sub_bymean'	\	`rf_rmse_sub_bymean'

			mat	define	rmse_eval_table	=	rmse_all,	rmse_eval_all /*,	rmse_sub,	rmse_eval_sub*/
			mat	list	rmse_eval_table
			
			*	
			
	}							
		
	*	Supplementary analysis	
	if	`supplement_analysis'==1	{
	
		
		*	Kolmogorov–Smirnov (between LASSO and RF)
			
			*	Prepare dataset
			*	K-S test cannot compare distributions from different variables, thus we need to create 1 variable that has all indicators
			
				expand	4
				loc	var	indicator_group
				bys	fam_ID_1999	year:	gen	`var'	=	_n
				label	define	`var'	1	"USDA"	2	"PFS (LASSO)"	3	"PFS (R.Forest)"	4	"PFS (GLM)", replace
				label	values	`var'	`var'
				lab	var	`var'	"Indicator Group"
					
				foreach	plan	in	thrifty	/*low	moderate	liberal*/	{

					loc	generate_indicator	1
					if	`generate_indicator'==1	{
					
						gen		indicator_`plan'	=	.n
						replace	indicator_`plan'	=	fs_scale_fam_rescale		if	inlist(1,in_sample,out_of_sample)	&	indicator_group==1	//	USDA FS (rescaled)
						replace	indicator_`plan'	=	rho1_foodexp_pc_`plan'_ls	if	inlist(1,in_sample,out_of_sample)	&	indicator_group==2	//	CB (LASSO)
						replace	indicator_`plan'	=	rho1_foodexp_pc_`plan'_rf	if	inlist(1,in_sample,out_of_sample)	&	indicator_group==3	//	CB (Random Forest)
						replace	indicator_`plan'	=	rho1_foodexp_pc_`plan'_ols	if	inlist(1,in_sample,out_of_sample)	&	indicator_group==4	//	CB (GLM)
						lab	var	indicator_`plan'	"Indicators (USDA score or Resilence score)"
					
						*	Conduct K-S test
						di	"K-S Test, `plan' food plan"
						ksmirnov	indicator_`plan'	if	inrange(year,9,10)	&	inlist(indicator_group,1,2), by(indicator_group)	//	USDA FS vs CB(LASSO)
						ksmirnov	indicator_`plan'	if	inrange(year,9,10)	&	inlist(indicator_group,1,3), by(indicator_group)	//	USDA FS vs CB(Random Forest)
						ksmirnov	indicator_`plan'	if	inrange(year,9,10)	&	inlist(indicator_group,2,3), by(indicator_group)	//	CB(LASSO) vs CB(Random Forest)
						ksmirnov	indicator_`plan'	if	inrange(year,9,10)	&	inlist(indicator_group,1,4), by(indicator_group)	//	USDA FS vs CB(GLM)
						
					}	//	gen_dinciator
			
			
				*	Distribution (K-density)
				/*
				graph twoway 	(kdensity fs_scale_fam_rescale	if	inrange(year,9,10))	///
								(kdensity rho1_foodexp_pc_`plan'_ls	if	inrange(year,9,10))	///
								(kdensity rho1_foodexp_pc_`plan'_rf	if	inrange(year,9,10)),	///
								title (Distribution of Indicators)	///
								subtitle(USDA food security score and resilience score)	///
								note(note: "constructed from in-sample(2015) and out-of-sample(2017)" "RS cut-off is generated based on `plan' food plan")	///
								legend(lab (1 "USDA scale") lab(2 "RS (LASSO)") lab(3 "RS (R.Forest)")	rows(1))
				
				graph	export	"${PSID_outRaw}/Indicator_Distribution_`plan'.png", replace
				*/
				
			}	//	plan
		
			
			/*
			graph twoway 		(kdensity fs_scale_fam_rescale	if	inlist(year,1,2,3,9,10))	///
								(kdensity rho1_foodexp_pc_low_ols	if	inlist(year,1,2,3,9,10)),	///
								title (Low plan)		name(low, replace)		///
								legend(lab (1 "USDA scale") lab(2 "PFS") rows(1))
								
			graph twoway 		(kdensity fs_scale_fam_rescale	if	inlist(year,1,2,3,9,10))	///
								(kdensity rho1_foodexp_pc_moderate_ols	if	inlist(year,1,2,3,9,10)),	///
								title (Moderate plan)		name(moderate, replace)		///
								legend(lab (1 "USDA scale") lab(2 "PFS") rows(1))
								
			graph twoway	 	(kdensity fs_scale_fam_rescale	if	inlist(year,1,2,3,9,10))	///
								(kdensity rho1_foodexp_pc_liberal_ols	if	inlist(year,1,2,3,9,10)),	///
								title (Liberal plan)	name(liberal, replace)		///
								legend(lab (1 "USDA scale") lab(2 "PFS") rows(1))
								
			grc1leg2		thrifty	/*low	moderate	liberal*/,	title(Distribution of Food Security Indicators) legendfrom(thrifty)	///
							note(note: "the sample includes the waves the USDA scale is constructed (1999,2001,2003,2015,2017)"	///
								"USDA scale is rescaled such that it varies from 0 to 1 and the greater the scale" ///
								"and the higher the scale, the more likely a household is food secure")
			*/

	

			drop	indicator_group indicator_thrifty indicator_low indicator_moderate indicator_liberal
			duplicates drop
	}	//	supplement_analysis		
				
		
	/****************************************************************
		SECTION 5: Regression of Indicators on Correlates
	****************************************************************/
	
	local	USDA_PFS_correlates	1	//	Regression of indicators on correlates
	
		*	Regression of USDA/PFS on correlates
	if	`USDA_PFS_correlates'==1	{
	
		cap	drop	USDA_PFS_available_years
		gen		USDA_PFS_available_years=0
		replace	USDA_PFS_available_years=1	if	inlist(year,2,3,9,10)
		
		cap	drop	age_head_fam_sq_K
		gen	age_head_fam_sq_K	=	age_head_fam_sq/1000
		lab	var	age_head_fam_sq_K	"Age$^2$/1000"	
	
		
		*local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam	c.age_head_fam_sq_K	HH_female	HH_race_color	marital_status_cat
		local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ highdegree_NoHS highdegree_somecol highdegree_col
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	/*ib0.state_resid_fam*/		state_group? state_group1? state_group2?
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.age_over65	///
								c.HH_female#c.age_over65	///
								c.ln_income_pc#c.HH_female#c.age_over65	///
								c.no_longer_married#c.HH_female
		local	timevars	year_enum3-year_enum10
		
		local	MEvars	c.age_head_fam	HH_female	HH_race_color	marital_status_cat	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'	// c.age_over65	
			
			
		*	Regression of 4 different indicators on food security correlates
		
		local	depvar	fs_scale_fam_rescale
		svy, subpop(if ${study_sample} & USDA_PFS_available_years==1): reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'	if	!mi(rho1_foodexp_pc_thrifty_ols)	&	!mi(fs_scale_fam_rescale)
		est	store	USDA_continuous
		*eststo	USDA_cont_ME: margins,	dydx(`MEvars')	post	
		
		local	depvar	rho1_foodexp_pc_thrifty_ols
		svy, subpop(if ${study_sample} & USDA_PFS_available_years==1): reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'	if	!mi(rho1_foodexp_pc_thrifty_ols)	&	!mi(fs_scale_fam_rescale)
		est	store	CB_continuous
		coefplot, keep(`regionvars')
		eststo	CB_cont_ME: margins,	dydx(`MEvars')	post	
		
		local	depvar	fs_cat_fam_simp
		svy, subpop(if ${study_sample} & USDA_PFS_available_years==1): reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'	if	!mi(rho1_foodexp_pc_thrifty_ols)	&	!mi(fs_scale_fam_rescale)
		est	store	USDA_binary
		*eststo	USDA_bin_ME: margins,	dydx(`MEvars')	post	
		
		local	depvar	rho1_thrifty_FS_ols
		svy, subpop(if ${study_sample} & USDA_PFS_available_years==1): reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'	if	!mi(rho1_foodexp_pc_thrifty_ols)	&	!mi(fs_scale_fam_rescale)
		est	store	CB_binary
		*eststo	CB_bin_ME: margins,	dydx(`MEvars')	post	
		
		
		*	Output
			
			*	Food Security Indicators and Their Correlates (Table 4 of 2020/11/16 draft)
			esttab	USDA_continuous	CB_continuous	USDA_binary	CB_binary	using "${PSID_outRaw}/USDA_CB_pooled.csv", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Effect of Correlates on Food Security Status) replace
					
					
			esttab	USDA_continuous	CB_continuous	USDA_binary	CB_binary	using "${PSID_outRaw}/USDA_CB_pooled.tex", ///
					/*cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
					cells(b(star fmt(3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Effect of Correlates on Food Security Status) replace
				
			/*
			esttab	USDA_cont_ME	CB_cont_ME	USDA_bin_ME	CB_bin_ME	using "${PSID_outRaw}/USDA_CB_ME.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Security Status) replace
					
			esttab	USDA_cont_ME	CB_cont_ME	USDA_bin_ME	CB_bin_ME	using "${PSID_outRaw}/USDA_CB_ME.tex", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Security Status) replace
					
			esttab	USDA_continuous	CB_continuous	USDA_binary	CB_binary	/*USDA_cont_ME	CB_cont_ME	USDA_bin_ME	CB_bin_ME*/	using "${PSID_outRaw}/USDA_CB_all.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Security Status) replace
			*/
			
		/*
		*	State-FE (base category is "Inappropriate; foreign country")
		est	restore	CB_continuous
									
			coefplot, keep(${state_Northeast})	xline(0)	graphregion(color(white)) bgcolor(white)	///
									title(Northeast)	name(state_FE_NE, replace)
			coefplot, keep(${state_Ncentral})	xline(0)	graphregion(color(white)) bgcolor(white)	///
									title(North Central)	name(state_FE_NC, replace)
			coefplot, keep(${state_South})		xline(0)	graphregion(color(white)) bgcolor(white)	///
									title(South)	name(state_FE_South, replace)
			coefplot, keep(${state_West})		xline(0)	graphregion(color(white)) bgcolor(white)	///
									title(West)		name(state_FE_West, replace)
			
			graph combine		state_FE_NE	state_FE_NC	state_FE_South	state_FE_West, title(PFS State FE)
			graph	export	"${PSID_outRaw}/PFS_State_FE.png", replace
			graph	close
		*/
		
		
		*	Grouped-state FE (without controls)
		
		
		*	Regress PFS on grouped-state FE (no controls, no time FE)
		local	depvar	rho1_foodexp_pc_thrifty_ols
		svy, subpop(if ${study_sample}): reg	`depvar'	`regionvars'		//	NY is omitted as a reference state
		est	store	PFS_regionFE_nocontrols
		
		local	depvar	rho1_foodexp_pc_thrifty_ols
		svy, subpop(if ${study_sample}): reg	`depvar'	`regionvars'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`timevars'	//	NY is omitted as a reference state
		est	store	PFS_regionFE_controls

		*	Plot grouped-state FE

		coefplot	PFS_regionFE_nocontrols	PFS_regionFE_controls, keep(state_group1)		xline(0)	xscale(range(-0.05(0.05) 0.15))	graphregion(color(white)) bgcolor(white)	///
								title(Northeast)		name(state_group_NE, replace)
		graph	export	"${PSID_outRaw}/PFS_State_Grouped_FE_NE.png", replace
		graph	close
		
		coefplot	PFS_regionFE_nocontrols	PFS_regionFE_controls, keep(state_group2	state_group3	state_group4	state_group5)		xline(0)	xscale(range(-0.05(0.05) 0.15))	graphregion(color(white)) bgcolor(white)	///
								title(Mid-Atlantic)	name(state_group_MA, replace)
		graph	export	"${PSID_outRaw}/PFS_State_Grouped_FE_MA.png", replace
		graph	close
		
		coefplot	PFS_regionFE_nocontrols	PFS_regionFE_controls, keep(state_group6 state_group7 state_group8 state_group9 state_group10 state_group11)		xline(0)	xscale(range(-0.05(0.05) 0.15))	graphregion(color(white)) bgcolor(white)	///
								title(South)	name(state_group_South, replace)
		graph	export	"${PSID_outRaw}/PFS_State_Grouped_FE_South.png", replace
		graph	close
		
		coefplot	PFS_regionFE_nocontrols	PFS_regionFE_controls, keep(state_group12 state_group13 state_group14 state_group15 state_group16 state_group17)		xline(0)	xscale(range(-0.05(0.05) 0.15))	graphregion(color(white)) bgcolor(white)	///
								title(Mid-West)	name(state_group_Midwest, replace)
		graph	export	"${PSID_outRaw}/PFS_State_Grouped_FE_MW.png", replace
		graph	close
		
		
		coefplot	PFS_regionFE_nocontrols	PFS_regionFE_controls, keep(state_group18 state_group19 state_group20 state_group21)		xline(0)	xscale(range(-0.05(0.05) 0.15))	graphregion(color(white)) bgcolor(white)	///
								title(West)	name(state_group_West, replace)
		graph	export	"${PSID_outRaw}/PFS_State_Grouped_FE_West.png", replace
		graph	close
								
		graph combine		state_group_NE	state_group_MA		state_group_South	state_group_Midwest	state_group_West, title(PFS State(Grouped) FE)
		graph	export	"${PSID_outRaw}/PFS_State_Grouped_FE.png", replace
		graph	close
	}
	

	
	
	/****************************************************************
		SECTION 6: Aggregation at Sub-Population Level
	****************************************************************/	
	local	run_pfs_agg_HH	1
	
	* Generate the squared food insecurty gap (SFIG)	
	if	`run_pfs_agg_HH'==1	{
		
		cap	drop	FIG_indiv
		cap	drop	SFIG_indiv
		gen	FIG_indiv=.
		gen	SFIG_indiv	=.
				
		foreach	type	in	ols	/*ls	rf*/	{
				
			cap	drop	pfs_`type'_normal
			gen pfs_`type'_normal	=.
				
				
			*	Normalized PFS (PFS/threshold PFS)	(PFSit/PFS_underbar_t)
			replace	pfs_`type'_normal	=	rho1_foodexp_pc_thrifty_`type'	/	PFS_threshold_`type'
			
			*	Inner term of the food securit gap (FIG) and the squared food insecurity gap (SFIG)
			replace	FIG_indiv	=	(1-pfs_`type'_normal)^1	if	!mi(pfs_`type'_normal)	&	pfs_`type'_normal<1	//	rho1_foodexp_pc_thrifty_`type'<PFS_threshold_`type'
			replace	FIG_indiv	=	0						if	!mi(pfs_`type'_normal)	&	pfs_`type'_normal>=1	//	rho1_foodexp_pc_thrifty_`type'>=PFS_threshold_`type'
			replace	SFIG_indiv	=	(1-pfs_`type'_normal)^2	if	!mi(pfs_`type'_normal)	&	pfs_`type'_normal<1	//	rho1_foodexp_pc_thrifty_`type'<PFS_threshold_`type'
			replace	SFIG_indiv	=	0						if	!mi(pfs_`type'_normal)	&	pfs_`type'_normal>=1	//	rho1_foodexp_pc_thrifty_`type'>=PFS_threshold_`type'
			

			
		}	//	type
		
		*	Limit the sample to non-missing observations in ALL categories (gender, race, education, region)
		*	It is because when we use "subpop()" option in "svy:" prefix, the command includes missing values outside the defined subpopulation in the population estimate (number of obs)
		*	For example, let's say the variable "race" has missing values, both for male and female.
		*	If we use "svy: tab race", the number of population includes only the observations with non-missing race values.
		*	However, if we use "svy, subpop(if male==1): tab race", the the number of observations includes observations with non-missing race values AND missing race values in "female==1"
			* More details: https://www.stata.com/statalist/archive/2010-03/msg01263.html, https://www.stata.com/statalist/archive/2010-03/msg01264.html
		*	This can be remedied by restricting subpopulation to observations with non-missing values in all categories of interest.
		global	nonmissing_FGT	!mi(rho1_thrifty_FI_ols) & !mi(FIG_indiv) & !mi(SFIG_indiv)
					
		
		
		*	Aggregate over households to generate population-level statistics
		*	Input for Figure 2 (Food Security Status by Group) in Dec 2020 draft.
			* Graph can be found in "FGT_year" sheet in "Min_report" Excel file
		
		foreach	group	in	all	male	female	white	black	other	NoHS	HS	somecol	col	NE	MidAt	South	MidWest	West metro nonmetro	{
			cap	mat	drop	sampleno_`group'	HCR_`group'	FIG_`group'	SFIG_`group'
		}
		
		
			*	Yearly decomposition
			forval	year=2/10	{
				
				
				*	Overall
					
				svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
				mat	sampleno_all	=	nullmat(HCR_all),	e(N_sub)
				mat	HCR_all			=	nullmat(HCR_all),	e(b)[1,1]
				mat	FIG_all			=	nullmat(FIG_all),	e(b)[1,2]
				mat	SFIG_all		=	nullmat(SFIG_all),	e(b)[1,3]

				*	Gender
					
					*	Male
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	&	${nonmissing_FGT} & HH_female==0	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_male	=	nullmat(sampleno_male),	e(N_sub)
					mat	HCR_male		=	nullmat(HCR_male),	e(b)[1,1]
					mat	FIG_male		=	nullmat(FIG_male),	e(b)[1,2]
					mat	SFIG_male		=	nullmat(SFIG_male),	e(b)[1,3]
					
					*	Female
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	&	${nonmissing_FGT} & HH_female==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_female	=	nullmat(sampleno_female),	e(N_sub)
					mat	HCR_female		=	nullmat(HCR_female),	e(b)[1,1]
					mat	FIG_female		=	nullmat(FIG_female),	e(b)[1,2]
					mat	SFIG_female		=	nullmat(SFIG_female),	e(b)[1,3]
					
				*	Race
				  
					*	White
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_white==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_white	=	nullmat(sampleno_white),	e(N_sub)
					mat	HCR_white		=	nullmat(HCR_white),	e(b)[1,1]
					mat	FIG_white		=	nullmat(FIG_white),	e(b)[1,2]
					mat	SFIG_white		=	nullmat(SFIG_white),	e(b)[1,3]
					
					*	Black
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_black==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_black	=	nullmat(sampleno_black),	e(N_sub)
					mat	HCR_black		=	nullmat(HCR_black),	e(b)[1,1]
					mat	FIG_black		=	nullmat(FIG_black),	e(b)[1,2]
					mat	SFIG_black		=	nullmat(SFIG_black),	e(b)[1,3]
					
					*	Other
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_other==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_other	=	nullmat(sampleno_other),	e(N_sub)
					mat	HCR_other		=	nullmat(HCR_other),	e(b)[1,1]
					mat	FIG_other		=	nullmat(FIG_other),	e(b)[1,2]
					mat	SFIG_other		=	nullmat(SFIG_other),	e(b)[1,3]	
					
				*	Education
				
					*	Less than High School
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_NoHS==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_NoHS	=	nullmat(sampleno_NoHS),	e(N_sub)
					mat	HCR_NoHS		=	nullmat(HCR_NoHS),	e(b)[1,1]
					mat	FIG_NoHS		=	nullmat(FIG_NoHS),	e(b)[1,2]
					mat	SFIG_NoHS		=	nullmat(SFIG_NoHS),	e(b)[1,3]
					
					*	High School
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_HS==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_HS	=	nullmat(sampleno_HS),	e(N_sub)
					mat	HCR_HS		=	nullmat(HCR_HS),	e(b)[1,1]
					mat	FIG_HS		=	nullmat(FIG_HS),	e(b)[1,2]
					mat	SFIG_HS		=	nullmat(SFIG_HS),	e(b)[1,3]
					
					*	Some College
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_somecol==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_somecol	=	nullmat(sampleno_somecol),	e(N_sub)
					mat	HCR_somecol		=	nullmat(HCR_somecol),	e(b)[1,1]
					mat	FIG_somecol		=	nullmat(FIG_somecol),	e(b)[1,2]
					mat	SFIG_somecol		=	nullmat(SFIG_somecol),	e(b)[1,3]
					
					*	College
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_col==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_col	=	nullmat(sampleno_col),	e(N_sub)
					mat	HCR_col		=	nullmat(HCR_col),	e(b)[1,1]
					mat	FIG_col		=	nullmat(FIG_col),	e(b)[1,2]
					mat	SFIG_col		=	nullmat(SFIG_col),	e(b)[1,3]
				
				*	Region (based on John's suggestion)
					
					foreach	stategroup	in	NE	MidAt	South	MidWest	West	{
						
						svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& state_group_`stategroup'==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
						mat	sampleno_`stategroup'	=	nullmat(sampleno_`stategroup'),	e(N_sub)
						mat	HCR_`stategroup'		=	nullmat(HCR_`stategroup'),	e(b)[1,1]
						mat	FIG_`stategroup'		=	nullmat(FIG_`stategroup'),	e(b)[1,2]
						mat	SFIG_`stategroup'		=	nullmat(SFIG_`stategroup'),	e(b)[1,3]
						
					}
					
					
				*	Metropolitan Area
				 
					*	Metro
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& resid_metro==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_metro	=	nullmat(sampleno_metro),	e(N_sub)
					mat	HCR_metro		=	nullmat(HCR_metro),	e(b)[1,1]
					mat	FIG_metro		=	nullmat(FIG_metro),	e(b)[1,2]
					mat	SFIG_metro		=	nullmat(SFIG_metro),	e(b)[1,3]
					
					*	Non-metro
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& resid_nonmetro==1	&	year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
					mat	sampleno_nonmetro	=	nullmat(sampleno_nonmetro),	e(N_sub)
					mat	HCR_nonmetro		=	nullmat(HCR_nonmetro),	e(b)[1,1]
					mat	FIG_nonmetro		=	nullmat(FIG_nonmetro),	e(b)[1,2]
					mat	SFIG_nonmetro		=	nullmat(SFIG_nonmetro),	e(b)[1,3]
				
				   
			}
			
			mat	define	blankrow_1by9	=	J(1,9,.)
			mat list blankrow_1by9
			foreach measure in HCR FIG SFIG	{
				
				cap	mat	drop	`measure'_year_combined
				mat	`measure'_year_combined	=	`measure'_all	\	blankrow_1by9	 \	`measure'_male	\	`measure'_female	\	blankrow_1by9	 \	///
											 	`measure'_white	\	`measure'_black	\	`measure'_other	\	blankrow_1by9 	 \		`measure'_NoHS	 \	///
												 `measure'_HS	\	`measure'_somecol	\	`measure'_col	\	blankrow_1by9	\	///
												 `measure'_NE	\	`measure'_MidAt	\	`measure'_South	\	`measure'_MidWest	\	`measure'_West	\	blankrow_1by9	\	///
												 `measure'_metro	\	`measure'_nonmetro
				
			}
			cap	mat	drop	FGT_year_combined
			mat	FGT_year_combined	=	blankrow_1by9	\	HCR_year_combined	\	blankrow_1by9	\	blankrow_1by9	\	FIG_year_combined	\	blankrow_1by9	\	blankrow_1by9	\	SFIG_year_combined
			
			putexcel	set "${PSID_outRaw}/FGT_bygroup", sheet(year) replace	/*modify*/
			putexcel	A3	=	matrix(FGT_year_combined), names overwritefmt nformat(number_d1)
			
			*esttab matrix(Jalan_Rav_2000_combined, fmt(%9.4f)) using "${PSID_outRaw}/Jalan_Rav_combined.tex", replace
			
		   *	Categorical decomposition
		   *	Input for Figure 3 in Dec 2020 draft (Food Insecurity Prevalence and Severity by Group).
			*	Data and Graph can be found in "FGT_group" sheet in "Min_report" Excel file.
		  
			*	Aggregate some categories (collapse 4 educational categories into two)
			cap	drop	highdegree_HSorbelow	//	binary for HS or below, or beyond HS.
			gen		highdegree_HSorbelow=0	if	inlist(1,highdegree_somecol,highdegree_col)
			replace	highdegree_HSorbelow=1	if	inlist(1,highdegree_NoHS, highdegree_HS)
			
		   *	Generate group-level aggregates.
		   *	We need to do it twice - one for main graph and one for supplement graph. The latter use more detailed educational category.
		   
		   *	Total population size, which is needed to get the share of each sub-group population to total population later
			qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT}): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
			local	sample_popsize_total=e(N_subpop)
		   
		   
				*	Main graph
				cap	mat	drop	Pop_ratio_all
				cap	mat	drop	HCR_cat	FIG_cat	SFIG_cat
				cap mat drop	HCR_weight_cat	FIG_weight_cat	SFIG_weight_cat
				cap	mat	drop	HCR_weight_cat_all	FIG_weight_cat_all	SFIG_weight_cat_all

			   /*foreach	edu	in	1	2	3	4	{	//	No HS, HS, some col, col*/
			   foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
					foreach	race	in	0	1	{	//	People of colors, white
						foreach	gender	in	1	0	{	//	Female, male
							
							*	FGT measures across all years (Figure 3 in Dec 2020 draft)
							
							qui svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	///
								mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
							
							local	Pop_ratio_all	=	e(N_subpop)/`sample_popsize_total'	//	Share of sub-group pop to total pop.
							mat		Pop_ratio_all	=	nullmat(Pop_ratio_all)	\	`Pop_ratio_all'
							mat	HCR_cat			=	nullmat(HCR_cat)	\	e(b)[1,1]
							mat	FIG_cat			=	nullmat(FIG_cat)	\	e(b)[1,2]
							mat	SFIG_cat		=	nullmat(SFIG_cat)	\	e(b)[1,3]
							
							*	Weighted average for stacked bar graph, by year					
							
							forval	year=2/10	{
								
								*	Generate population size estimate of the sample, which will be used to calculate weighted average.
								qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT} & year==`year'): mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
								local	sample_popsize_year=e(N_subpop)
								
								*	Estimate FGT measures
								qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'	&	year==`year'):	///
									mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
									
								local	Pop_ratio	=	e(N_subpop)/`sample_popsize_year'
								local	HCR_weighted_`year'		=	e(b)[1,1]*`Pop_ratio'
								local	FIG_weighted_`year'		=	e(b)[1,2]*`Pop_ratio'
								local	SFIG_weighted_`year'	=	e(b)[1,3]*`Pop_ratio'
								macro list _HCR_weighted_`year'
								
								mat	HCR_weight_cat	=	nullmat(HCR_weight_cat),	`HCR_weighted_`year''
								mat	FIG_weight_cat	=	nullmat(FIG_weight_cat),	`FIG_weighted_`year''
								mat	SFIG_weight_cat	=	nullmat(SFIG_weight_cat),	`SFIG_weighted_`year''	
				
							}	//	year
							
							mat	HCR_weight_cat_all	=	nullmat(HCR_weight_cat_all)	\	HCR_weight_cat
							mat	FIG_weight_cat_all	=	nullmat(FIG_weight_cat_all)	\	FIG_weight_cat
							mat	SFIG_weight_cat_all	=	nullmat(SFIG_weight_cat_all)	\	SFIG_weight_cat
							
							cap	mat	drop	HCR_weight_cat	FIG_weight_cat	SFIG_weight_cat
							
						}	// gender			
					}	//	race	
			   }	//	edu
			   
				cap	mat	drop	FGT_cat_combined
				mat	FGT_cat_combined	=	Pop_ratio_all,	HCR_cat,	FIG_cat,	SFIG_cat
				
				
				*	Supplementary graph - use 4 educational categories, across all years, no weighted
				cap	mat	drop	Pop_ratio_all_sup	HCR_cat_sup	FIG_cat_sup	SFIG_cat_sup	
				
				 foreach	edu	in	1	2	3	4	{	//	No HS, HS, some col, col
			   /*foreach	edu	in	1	0	{	//	HS or below, beyond HS*/	   
					foreach	race	in	0	1	{	//	People of colors, white
						foreach	gender	in	1	0	{	//	Female, male
							
							*	FGT measures across all years
							
							qui svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_female==`gender' & HH_race_white==`race' & grade_comp_cat==`edu'):	///
								mean rho1_thrifty_FI_ols FIG_indiv	SFIG_indiv
							
							local	Pop_ratio_all_sup	=	e(N_subpop)/`sample_popsize_total'	//	Share of sub-group pop to total pop.
							mat		Pop_ratio_all_sup	=	nullmat(Pop_ratio_all_sup)	\	`Pop_ratio_all_sup'
							mat	HCR_cat_sup			=	nullmat(HCR_cat_sup)	\	e(b)[1,1]
							mat	FIG_cat_sup			=	nullmat(FIG_cat_sup)	\	e(b)[1,2]
							mat	SFIG_cat_sup		=	nullmat(SFIG_cat_sup)	\	e(b)[1,3]
							
						}	// gender			
					}	//	race	
			   }	//	edu
			   
				cap	mat	drop	FGT_cat_combined_sup
				mat	FGT_cat_combined_sup	=	Pop_ratio_all_sup,	HCR_cat_sup,	FIG_cat_sup,	SFIG_cat_sup
				
			   
				putexcel	set "${PSID_outRaw}/FGT_bygroup", sheet(categorical) /*replace*/	modify
				putexcel	A3	=	matrix(FGT_cat_combined), names overwritefmt nformat(number_d1)
				putexcel	A14	=	matrix(HCR_weight_cat_all), names overwritefmt nformat(number_d1)
				putexcel	A24	=	matrix(FIG_weight_cat_all), names overwritefmt nformat(number_d1)
				putexcel	A34	=	matrix(SFIG_weight_cat_all), names overwritefmt nformat(number_d1)
				putexcel	M3	=	matrix(FGT_cat_combined_sup), names overwritefmt nformat(number_d1)
				
				*esttab matrix(Jalan_Rav_2000_combined, fmt(%9.4f)) using "${PSID_outRaw}/Jalan_Rav_combined.tex", replace
	}
				
	
	/****************************************************************
		SECTION 7: Dynamics
	****************************************************************/	
		
	local	run_transition_matrix	1	//	Transition matrix
	local	run_spell_length	1	//	Spell length
	local	run_FS_chron_trans	1	//	Chronic and transient FS (Jalan and Ravallion (2000) Table)
		local	shapley_decomposition	1	//	Shapley decompsition of TFI/CFI (takes time)
	
	
	*	Transition matrices	
	if	`run_transition_matrix'==1	{
	
		*	Preamble
		mat drop _all
		cap	drop	??_rho1_thrifty_FS_ols	??_rho1_thrifty_FI_ols	??_rho1_thrifty_LFS_ols	??_rho1_thrifty_VLFS_ols	??_rho1_thrifty_cat_ols
		sort	fam_ID_1999	year
			
		*	Generate lagged FS dummy from PFS, as svy: command does not support factor variable so we can't use l.	
		forvalues	diff=1/9	{
			foreach	category	in	FS	FI	LFS	VLFS	cat	{
				if	`diff'!=9	{
					gen	l`diff'_rho1_thrifty_`category'_ols	=	l`diff'.rho1_thrifty_`category'_ols	//	Lag
				}
				gen	f`diff'_rho1_thrifty_`category'_ols	=	f`diff'.rho1_thrifty_`category'_ols	//	Forward
			}
		}
		
		*	Restrict sample to the observations with non-missing PFS and lagged PFS
		global	nonmissing_PFS_lags	!mi(l1_rho1_thrifty_FS_ols)	&	!mi(rho1_thrifty_FS_ols)
		
		*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
			
			*	Year
			cap	mat	drop	trans_2by2_year	trans_change_year
			forvalues	year=3/10	{			
				
				
				*	Joint distribution	(two-way tabulate)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & year_enum`year'): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols
				mat	trans_2by2_joint_`year' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`year'	=	e(N_sub)	//	Sample size
				
				*	Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & year_enum`year'): proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
				scalar	persistence_`year'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & year_enum`year'):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
				scalar	entry_`year'	=	e(b)[1,1]
				
				mat	trans_2by2_`year'	=	samplesize_`year',	trans_2by2_joint_`year',	persistence_`year',	entry_`year'	
				mat	trans_2by2_year	=	nullmat(trans_2by2_year)	\	trans_2by2_`year'
				
				
				*	Change in Status (For Figure 3 of 2020/11/16 draft)
				**	Note: here we do NOT limit our sample to non-missing values, as we need the ratio of those with missing values.
				svy, subpop(if ${study_sample} /*& ${nonmissing_PFS_lags}*/	 & !mi(rho1_thrifty_FI_ols)	&	year==`year'): tab 	l1_rho1_thrifty_FI_ols rho1_thrifty_FI_ols, missing
				local	sample_popsize_total=e(N_subpop)
				mat	trans_change_`year' = e(b)[1,5], e(b)[1,2], e(b)[1,8]
				mat	trans_change_year	=	nullmat(trans_change_year)	\	trans_change_`year'
				
				cap	mat	drop	Pop_ratio
				cap	mat	drop	FI_still_`year'	FI_newly_`year'	
				
				foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
					foreach	race	in	0	1	{	//	People of colors, white
						foreach	gender	in	1	0	{	//	Female, male
							
								
							qui	svy, subpop(if	${study_sample} /*& ${nonmissing_PFS_lags}*/	& !mi(rho1_thrifty_FI_ols)	///
												& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'	&	year==`year'):	///
												tab l1_rho1_thrifty_FI_ols rho1_thrifty_FI_ols, missing
												
							local	Pop_ratio	=	e(N_subpop)/`sample_popsize_total'
							local	FI_still_`year'		=	e(b)[1,5]*`Pop_ratio'
							local	FI_newly_`year'		=	e(b)[1,2]*`Pop_ratio'
							
							mat	Pop_ratio	=	nullmat(Pop_ratio)	\	`Pop_ratio'
							mat	FI_still_`year'	=	nullmat(FI_still_`year')	\	`FI_still_`year''
							mat	FI_newly_`year'	=	nullmat(FI_newly_`year')	\	`FI_newly_`year''
							
						}	//	gender
					}	//	race
				}	//	education
				
				mat	FI_still_year_all	=	nullmat(FI_still_year_all),	FI_still_`year'
				mat	FI_newly_year_all	=	nullmat(FI_newly_year_all),	FI_newly_`year'
							
			}	//	year

			
			/*
			*	Age (Income-to-Poverty Ratio less than 2)
			cap	drop	age_group
			gen		age_group=0	if	inrange(age_head_fam,25,44)
			replace	age_group=1	if	inrange(age_head_fam,45,59)
			replace	age_group=2	if	inrange(age_head_fam,60,64)
			replace	age_group=3	if	inrange(age_head_fam,65,69)
			replace	age_group=4	if	inrange(age_head_fam,70,105)
			
			foreach	type	in	0	1	2	3	4	{	//	55~64/65~74
					
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & age_group==`type' & inrange(income_to_poverty_cat,1,2)): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & age_group==`type' & inrange(income_to_poverty_cat,1,2)):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & age_group==`type' & inrange(income_to_poverty_cat,1,2)):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_age	=	trans_2by2_0	\	trans_2by2_1	\	trans_2by2_2	\	trans_2by2_3	\	trans_2by2_4
				mat list trans_2by2_age
			
			*/
			
			
			
			*	Gender
			
				*	Male, Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & gender_head_fam_enum2): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols	
				mat	trans_2by2_joint_male = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_male	=	e(N_sub)	//	Sample size
				
				*	Female, Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_female): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols	
				mat	trans_2by2_joint_female = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_female	=	e(N_sub)	//	Sample size
				
				*	Male, Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & gender_head_fam_enum2):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
				scalar	persistence_male	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & gender_head_fam_enum2):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
				scalar	entry_male	=	e(b)[1,1]
				
				*	Female, Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_female):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
				scalar	persistence_female	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_female):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
				scalar	entry_female	=	e(b)[1,1]
				
				mat	trans_2by2_male		=	samplesize_male,	trans_2by2_joint_male,	persistence_male,	entry_male	
				mat	trans_2by2_female	=	samplesize_female,	trans_2by2_joint_female,	persistence_female,	entry_female
				
				mat	trans_2by2_gender	=	trans_2by2_male	\	trans_2by2_female
				
			*	Race
							
				foreach	type	in	1	0	{	//	white/color
					
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_race	=	trans_2by2_1	\	trans_2by2_0

			*	Region (based on John's suggestion)
			
				foreach	type	in	NE MidAt South MidWest	West	{
				
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_region	=	trans_2by2_NE	\	trans_2by2_MidAt	\	trans_2by2_South	\	trans_2by2_MidWest	\		trans_2by2_West
			
			*	Education
			
			foreach	type	in	NoHS	HS	somecol	col	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			mat	trans_2by2_degree	=	trans_2by2_NoHS	\	trans_2by2_HS	\	trans_2by2_somecol	\	trans_2by2_col
			
			
			*	Disability
			capture	drop	phys_nodisab_head
			gen		phys_nodisab_head=0	if	phys_disab_head==1
			replace	phys_nodisab_head=1	if	phys_disab_head==0
			
			foreach	type	in	nodisab	disab	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			
			mat	trans_2by2_disability	=	trans_2by2_nodisab	\	trans_2by2_disab
			
			*	Food Stamp
			cap drop	food_nostamp_used_1yr
			gen		food_nostamp_used_1yr=1	if	food_stamp_used_1yr==0
			replace	food_nostamp_used_1yr=0	if	food_stamp_used_1yr==1
			
			foreach	type	in	nostamp	stamp	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			
			mat	trans_2by2_foodstamp	=	trans_2by2_nostamp	\	trans_2by2_stamp
			
			*	Shock vars
			*	Create temporary vars to easily write a loop code.
			cap	drop	emp_shock noemp_shock marriage_shock nomarriage_shock disab_shock nodisab_shock	newstamp_shock nonewstamp_shock
			
			clonevar	emp_shock	=	no_longer_employed
			clonevar	marriage_shock	=	no_longer_married
			clonevar	disab_shock		=	became_disabled
			gen 		newstamp_shock=0
			replace		newstamp_shock=1	if	food_stamp_used_1yr==0	&	l.food_stamp_used_1yr==1
			
			gen			noemp_shock=0	if	emp_shock==1
			replace		noemp_shock=1	if	emp_shock==0
			gen			nomarriage_shock=0	if	marriage_shock==1
			replace		nomarriage_shock=1	if	marriage_shock==0
			gen			nodisab_shock=0	if	disab_shock==1
			replace		nodisab_shock=1	if	disab_shock==0
			gen			nonewstamp_shock=0	if	newstamp_shock==1
			replace		nonewstamp_shock=1	if	newstamp_shock==0
			
			cap	mat	drop	trans_2by2_shock
			foreach	type	in	/*noemp*/ emp /*nomarriage*/ marriage /*nodisab*/ disab /*nonewstamp*/ newstamp	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock): tabulate l1_rho1_thrifty_FS_ols	rho1_thrifty_FS_ols	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==0	&	!mi(rho1_thrifty_FS_ols)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock):qui proportion	rho1_thrifty_FS_ols	if	l1_rho1_thrifty_FS_ols==1	&	!mi(rho1_thrifty_FS_ols)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
				mat	trans_2by2_shock	=	nullmat(trans_2by2_shock)	\	trans_2by2_`type'
			}

		*	Combine transition matrices (Table 6 of 2020/11/16 draft)
		
		mat	define	blankrow	=	J(1,7,.)
		mat	trans_2by2_combined	=	trans_2by2_year	\	blankrow	\	trans_2by2_gender	\	blankrow	\	///
									trans_2by2_race	\	blankrow	\	trans_2by2_region	\	blankrow	\	trans_2by2_degree	\	blankrow	\	///
									trans_2by2_disability	\	blankrow	\	trans_2by2_foodstamp	\	blankrow	\	///
									trans_2by2_shock
		
		mat	list	trans_2by2_combined
			
		putexcel	set "${PSID_outRaw}/Transition_Matrices", sheet(2by2) replace	/*modify*/
		putexcel	A3	=	matrix(trans_2by2_combined), names overwritefmt nformat(number_d1)
		
		esttab matrix(trans_2by2_combined, fmt(%9.2f)) using "${PSID_outRaw}/Transition_2by2_combined.tex", replace	
		
		putexcel	set "${PSID_outRaw}/Transition_Matrices", sheet(change) /*replace*/	modify
		putexcel	A3	=	matrix(trans_change_year), names overwritefmt nformat(number_d1)
		putexcel	A13	=	matrix(FI_still_year_all), names overwritefmt nformat(number_d1)
		putexcel	A23	=	matrix(FI_newly_year_all), names overwritefmt nformat(number_d1)
			
	}
	
	*	Spell length
	if	`run_spell_length'==1	{
		
		*	Tag balanced sample (Households with at least one missing PFS throughout the study period)
		*	These households will be dropped from spell length analyses not to underestimate spell lengths
		capture	drop	num_nonmissing_PFS	balanced_PFS
		bys fam_ID_1999: egen num_nonmissing_PFS=count(rho1_thrifty_FI_ols)
		gen	balanced_PFS=1	if	num_nonmissing_PFS==9

		*	Summary stats of spell lengths among FI incidence
		*mat	summ_spell_length	=	J(9,2,.)	
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=2 & rho1_thrifty_FI_ols==1)
		svy, subpop(if	${study_sample} & _end==1 & balanced_PFS==1): mean _seq //	Mean of spell lengths (To get length as an year, multiply spell length by 2)
		svy, subpop(if	${study_sample}	& _end==1 & balanced_PFS==1): tab _seq 	//	Tabulation of spell lengths.
		*mat	summ_spell_length	=	e(N),	e(b)
		mat	summ_spell_length	=	e(b)[1..1,2..10]'

		*	Persistence rate conditional upon spell length (Table 7 of 2020/11/16 draft)
		mat	persistence_upon_spell	=	J(9,2,.)	
		forvalues	i=1/8	{
			svy: proportion rho1_thrifty_FS_ols	if	l._seq==`i'	&	!mi(rho1_thrifty_FS_ols) &	balanced_PFS==1	//	Previously FI
			mat	persistence_upon_spell[`i',1]	=	/*e(N),*/ e(b)[1,1], r(table)[2,1]
		}

		*	Distribution of spell length and conditional persistent (Table 7 of 2020/11/16 draft)
		mat spell_dist_comb	=	summ_spell_length,	persistence_upon_spell
		mat	rownames	spell_dist_comb	=	2	4	6	8	10	12	14	16	18

		esttab matrix(spell_dist_comb, fmt(%9.2f)) using "${PSID_outRaw}/Spell_dist_combined.tex", replace	

		drop	_seq _spell _end

		*	Spell length given household newly become food insecure, by each year
		cap drop FI_duration
		gen FI_duration=.

		cap	mat	drop	dist_spell_length
		mat	dist_spell_length	=	J(8,10,.)

		forval	wave=2/9	{
			
			cap drop FI_duration_year*	_seq _spell _end	
			tsspell, cond(year>=`wave' & rho1_thrifty_FI_ols==1)
			egen FI_duration_year`wave' = max(_seq), by(fam_ID_1999 _spell)
			replace	FI_duration = FI_duration_year`wave' if rho1_thrifty_FI_ols==1 & year==`wave'
					
			*	Replace households that used to be FI last year with missing value (We are only interested in those who newly became FI)
			if	`wave'>=3	{
				replace	FI_duration	=.	if	year==`wave'	&	!(rho1_thrifty_FI_ols==1	&	l.rho1_thrifty_FI_ols==0)
			}
			
		}
		replace FI_duration=.	if	balanced_PFS!=1 //

		*	Figure 4 of 2020/11/16 draft
		mat	dist_spell_length_byyear	=	J(8,10,.)
		forval	wave=2/9	{
			
			local	row=`wave'-1
			svy, subpop(if year==`wave'	&	!mi(FI_duration)): tab FI_duration
			mat	dist_spell_length_byyear[`row',1]	=	e(N_sub), e(b)
			
		}

		putexcel	set "${PSID_outRaw}/Transition_Matrices", sheet(spell_length) modify	/*replace*/
		putexcel	A5	=	matrix(dist_spell_length_byyear), names overwritefmt nformat(number_d1)

		esttab matrix(dist_spell_length_byyear, fmt(%9.2f)) using "${PSID_outRaw}/Dist_spell_length.tex", replace	
	
	}
	
	*	FS_Chronic_Transient	
	if	`run_FS_chron_trans'==1	{
		
		*cap	drop	pfs_ols_normal
		cap	drop	SFIG
		cap	drop	PFS_ols_mean
		cap	drop	PFS_ols_total
		cap	drop	PFS_threshold_ols_total
		cap	drop	PFS_ols_mean_normal
		cap	drop	PFS_threshold_ols_mean
		cap	drop	PFS_ols_normal_mean
		cap	drop	SFIG_mean_indiv
		cap	drop	SFIG_mean
		cap	drop	SFIG_transient
		cap	drop	SFIG_deviation
		cap	drop	Total_FI
		cap	drop	Total_FI_HCR
		cap	drop	Total_FI_SFIG
		cap	drop	Transient_FI
		cap	drop	Transient_FI_HCR
		cap	drop	Transient_FI_SFIG
		cap	drop	Chronic_FI
		cap	drop	Chronic_FI_HCR
		cap	drop	Chronic_FI_SFIG
		*gen pfs_ols_normal	=.
		
		
		
		
		foreach	type	in	ols	/*ls	rf*/	{
				
				*gen	pfs_`type'_mean_normal=.
				*gen	SFIG_mean_indiv=.
				
				
				*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at household-level.
				*	Since households have different number of non-missing PFS and our cut-off probability varies over time, we cannot simply use "mean" function.
				*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
				
				*	Aggregate PFS over time (numerator)
				bys	fam_ID_1999:	egen	PFS_`type'_total	=	total(rho1_foodexp_pc_thrifty_ols)	if	inrange(year,2,10)
				
				*	Aggregate cut-off PFS over time. To add only the years with non-missing PFS, we replace the cut-off PFS of missing PFS years as missing.
				replace	PFS_threshold_`type'=.	if	mi(rho1_foodexp_pc_thrifty_`type')
				bys	fam_ID_1999:	egen	PFS_threshold_`type'_total	=	total(PFS_threshold_`type')	if	inrange(year,2,10)
				
				*	Generate (normalized) mean-PFS by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
				gen	PFS_`type'_mean_normal	=	PFS_`type'_total	/	PFS_threshold_`type'_total
				
					
				*	Total, Transient and Chronic FI

				
					*	Total FI	(Average SFIG over time)
					bys	fam_ID_1999:	egen	Total_FI_HCR	=	mean(rho1_thrifty_FI_ols)	if	inrange(year,2,10)	//	HCR
					bys	fam_ID_1999:	egen	Total_FI_SFIG	=	mean(SFIG_indiv)			if	inrange(year,2,10)	/*!mi(SFIG_indiv)*/	//	SFIG

					*	Chronic FI (SFIG(with mean PFS))					
					gen		Chronic_FI_HCR=.
					gen		Chronic_FI_SFIG=.
					replace	Chronic_FI_HCR	=	(1-PFS_`type'_mean_normal)^0	if	!mi(PFS_`type'_mean_normal)	&	PFS_`type'_mean_normal<1	//	Avg PFS < Avg cut-off PFS
					replace	Chronic_FI_SFIG	=	(1-PFS_`type'_mean_normal)^2	if	!mi(PFS_`type'_mean_normal)	&	PFS_`type'_mean_normal<1	//	Avg PFS < Avg cut-off PFS
					replace	Chronic_FI_HCR	=	0								if	!mi(PFS_`type'_mean_normal)	&	PFS_`type'_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
					replace	Chronic_FI_SFIG	=	0								if	!mi(PFS_`type'_mean_normal)	&	PFS_`type'_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
					
					**** In several households, CFI is greater than TFI. I assume it is because the threshold probability varies, but need to thoroughly check why.
					**** For now, in that case we treat CFI as equal to the TFI
					**** (2021/1/24) Chris said it is OK to have TFI<CFI. Below is his comments from the e-mail sent on Jan 24, 2021
					**** "That said, it’s fine to have CFI>TFI. That’s the very definition of a household that is chronically food insecure but occasionally food secure (i.e., chronically but not persistently food insecure). The poverty dynamics literature includes this as well, as it reflects the headcount basis for the average period-specific (total) food insecurity (TFI) versus the period-average food insecurity (CFI). "
					*replace	Chronic_FI_HCR	=	Total_FI	if	Chronic_FI>Total_FI
					
					*	Transient FI (TFI - CFI)
					gen	Transient_FI_HCR	=	Total_FI_HCR	-	Chronic_FI_HCR
					gen	Transient_FI_SFIG	=	Total_FI_SFIG	-	Chronic_FI_SFIG
							
				
				/*
				*	Mean PFS over time. It will be the input argument for the Chronic Poverty.
				bys	fam_ID_1999: egen	pfs_`type'_mean	=	mean(rho1_foodexp_pc_thrifty_`type')	if	!mi(rho1_foodexp_pc_thrifty_`type')
				
				
				*	First loop
				local	num_years	=	0
				global	PFS_threshold_total=0
				
				forval	year=2/10	{		
							
					
					global	PFS_threshold_total	=	${PFS_threshold_total}	+	${PFS_threshold_`year'}	//	To calculate mean cut-off threshold${PFS_threshold_`year'}
					
					di "threshold of year `year' is ${PFS_threshold_`year'}"
					local	num_years	=	`num_years'+1
					
					/*
					*	Set threshold PFS value for year, which is the average of the maximum PFS of FI households and the minimum PFS of the FS households
					qui	summ	rho1_foodexp_pc_thrifty_`type'	if	rho1_thrifty_FS_`type'==0	&	year==`year'	//	Maximum PFS of households categorized as food insecure
					local	max_pfs_thrifty_`type'_`year'	=	r(max)
					qui	summ	rho1_foodexp_pc_thrifty_`type'	if	rho1_thrifty_FS_`type'==1	&	year==`year'	//	Minimum PFS of households categorized as food secure
					local	min_pfs_thrifty_`type'_`year'	=	r(min)

					global	thresval_`type'_`year'	=	(`max_pfs_thrifty_`type'_`year''	+	`min_pfs_thrifty_`type'_`year'')/2	//	Average of the two scores above is a threshold value.
					global	thresval_`type'_total	=	${thresval_`type'_total}	+	${thresval_`type'_`year'}	//	To calculate mean cut-off threshold
					
					
					*	Normalized PFS (PFS/threshold PFS)	(yit)
					replace	pfs_`type'_normal	=	rho1_foodexp_pc_thrifty_`type'	/	${thresval_`type'_`year'}	if	year==`year'
					
					*	Squared Food Insecurity Gap (SFIG) at each year
					replace	SFIG_indiv	=	(1-pfs_`type'_normal)^2	if	year==`year'	&	!mi(pfs_`type'_normal)	&	rho1_foodexp_pc_thrifty_`type'<${thresval_`type'_`year'}	
					replace	SFIG_indiv	=	0						if	year==`year'	&	!mi(pfs_`type'_normal)	&	rho1_foodexp_pc_thrifty_`type'>=${thresval_`type'_`year'}
					
					
					di "threshold of year `year' is ${thresval_`type'_`year'}"
					local	num_years	=	`num_years'+1
					*/
					
					/*	Outdated code
					*	Normalized Mean PFS
					replace	pfs_`type'_mean_normal	=	pfs_`type'_mean	/	${thresval_`type'_`year'}	if	year==`year'
								
					*	Squared Food Insecurity Gap (SFIG) at each year using Mean PFS
					replace	SFIG_mean_indiv	=	(1-pfs_`type'_mean_normal)^2	if	year==`year'	&	!mi(pfs_`type'_mean_normal)	&	pfs_`type'_mean<${thresval_`type'_`year'}
					replace	SFIG_mean_indiv	=	0								if	year==`year'	&	!mi(pfs_`type'_mean_normal)	&	pfs_`type'_mean>=${thresval_`type'_`year'}
					*/
					
					
				}	//	year
				
				global	PFS_threshold_mean	=	${PFS_threshold_total} / `num_years'
				di "Total threshold is ${PFS_threshold_total}, num_years is `num_years' and mean threshold is ${PFS_threshold_mean}"
				
				
				** This code is wrong. We should get the average PFS first and then normalize it, NOT the other way around (Calvo and Dercon, 2007)
				*	Household-level mean of normalized PFS over time (yi_bar)
				** The difference between "normalized mean PFS" below is that, this one normalize first and then gets them mean, so household i has the same value across time.
				*bys	fam_ID_1999:	egen	pfs_`type'_normal_mean	=	mean(pfs_`type'_normal)
				
				
				
				*	Calculate mean Food Insecurity threshold over time.
				/*	Jalan and Ravallion (2000) used a fixed poverty line across all years, while our cut-off probability line is year-specific.
					Thus we use the mean of those cut-off probabilities as a fixed threshold to categorize households	*/
					
				
				*	Second loop to get mean of normalized PFS over time
				forval	year=2/10	{	
							
					*	Squared Food Insecurity Gap (SFIG) at each year using Mean normalized PFS
					replace	SFIG_mean_indiv	=	(1-pfs_`type'_normal_mean)^2	if	year==`year'	&	!mi(pfs_`type'_normal_mean)	&	pfs_`type'_mean<${PFS_threshold_`year'}
					replace	SFIG_mean_indiv	=	0								if	year==`year'	&	!mi(pfs_`type'_normal_mean)	&	pfs_`type'_mean>=${PFS_threshold_`year'}
					
				}	
				
				
				*	Total, Transient and Chronic FI
				
					*	Total FI
					bys	fam_ID_1999: egen	Total_FI		=	mean(SFIG_indiv)		if	!mi(SFIG_indiv)
					
					*	Transient FI (time mean of SFIG deviation from its mean)
					gen	SFIG_deviation	=	SFIG_indiv	-	SFIG_mean_indiv	//	fluct
					bys	fam_ID_1999:	egen	Transient_FI	=	mean(SFIG_deviation)
					
					*	Chronic FI (Total FI - Transient FI)
					gen	Chronic_FI	=	Total_FI	-	Transient_FI
				
				/*
				bys	fam_ID_1999: egen	SFIG		=	mean(SFIG_indiv)		if	!mi(SFIG_indiv)	//	Overall FI
				bys	fam_ID_1999: egen	SFIG_mean	=	mean(SFIG_mean_indiv)	if	!mi(SFIG_mean_indiv)	//	Chronic FI
				gen	SFIG_transient	=	SFIG	-	SFIG_mean
				*/
				
			*/
			
			}	//	type
		
		
			*	Restrict sample to non_missing TFI and CFI
			global	nonmissing_TFI_CFI	!mi(Total_FI_HCR)	&	!mi(Chronic_FI_HCR)
		
		*	Descriptive stats
			
			**	For now we include households with 5+ PFS.
			cap	drop	num_nonmissing_PFS
			cap	drop	dyn_sample
			bys fam_ID_1999: egen num_nonmissing_PFS=count(rho1_foodexp_pc_thrifty_ols)
			gen	dyn_sample=1	if	num_nonmissing_PFS>=5	&	inrange(year,2,10)
			
			*	For time-variance categories (ex. education, region), we use the first year (2001) value (as John suggested)
			local	timevar_cat	highdegree_NoHS highdegree_HS highdegree_somecol highdegree_col	///
								state_group_NE state_group_MidAt state_group_South state_group_MidWest state_group_West	resid_metro resid_nonmetro
			foreach	type	of	local	timevar_cat		{
				
				gen		`type'_temp	=	1	if	year==2	&	`type'==1
				replace	`type'_temp	=	0	if	year==2	&	`type'!=1	&	!mi(`type')
				replace	`type'_temp	=	.n	if	year==2	&	mi(`type')
				
				cap	drop	`type'_2001
				bys	fam_ID_1999:	egen	`type'_2001	=	max(`type'_temp)
				drop	`type'_temp
				
			}				
			
			*	If 2001 education is missing, use the earliest available education information
			cap	drop	tempyear
			bys fam_ID_1999: egen tempyear = min(year) if (${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1 & mi(highdegree_NoHS_2001))

			foreach edu in NoHS HS somecol col	{
				
				cap	drop	highdegree_`edu'_2001_temp?
				gen	highdegree_`edu'_2001_temp1	=	highdegree_`edu'	if	year==tempyear
				bys fam_ID_1999: egen highdegree_`edu'_2001_temp2	=	max(highdegree_`edu'_2001_temp1) if !mi(tempyear)
				replace	highdegree_`edu'_2001	=	highdegree_`edu'_2001_temp2	if	!mi(tempyear)
				drop	highdegree_`edu'_2001_temp?
			}
			drop	tempyear


			*	Generate statistics for tables
			local	exceloption	replace
			foreach	measure	in	HCR	SFIG	{
			
				*	Overall			
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	& ${nonmissing_TFI_CFI} 	&	dyn_sample==1 ):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_all	=	e(b)[1,2]/e(b)[1,1]
				*scalar	samplesize_all	=	e(N_sub)
				mat	Jalan_Rav_2000_all	=	e(N_sub),	e(b), prop_trans_all
				
				*	Gender
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	gender_head_fam_enum2==1):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_male	=	e(b)[1,2]/e(b)[1,1]
				mat	Jalan_Rav_2000_male	=	e(N_sub),	e(b), prop_trans_male
				
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1 	&	HH_female==1):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_female	=	e(b)[1,2]/e(b)[1,1]
				mat	Jalan_Rav_2000_female	=	e(N_sub),	e(b), prop_trans_female
				
				mat	Jalan_Rav_2000_gender	=	Jalan_Rav_2000_male	\	Jalan_Rav_2000_female
				
				*	Race
				foreach	type	in	1	0	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	HH_race_white==`type'):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_race_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	Jalan_Rav_2000_race_`type'	=	e(N_sub),	e(b), prop_trans_race_`type'
					
				}
				
				mat	Jalan_Rav_2000_race	=	Jalan_Rav_2000_race_1	\	Jalan_Rav_2000_race_0

				*	Region (based on John's suggestion)
				foreach	type	in	NE	MidAt South MidWest West	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	state_group_`type'==1	):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_region_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	Jalan_Rav_2000_region_`type'	=	e(N_sub),	e(b), prop_trans_region_`type'
					
				}
			
				mat	Jalan_Rav_2000_region	=	Jalan_Rav_2000_region_NE	\	Jalan_Rav_2000_region_MidAt	\	Jalan_Rav_2000_region_South	\	///
												Jalan_Rav_2000_region_MidWest	\	Jalan_Rav_2000_region_West
				
				*	Metropolitan Area
				foreach	type	in	metro	nonmetro	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	resid_`type'==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_metro_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	Jalan_Rav_2000_metro_`type'	=	e(N_sub),	e(b), prop_trans_metro_`type'
					
				}
			
				mat	Jalan_Rav_2000_metro	=	Jalan_Rav_2000_metro_metro	\	Jalan_Rav_2000_metro_nonmetro
				
				*	Education degree (Based on 2001 degree)
				foreach	degree	in	NoHS	HS	somecol	col	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	highdegree_`degree'_2001==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_edu_`degree'	=	e(b)[1,2]/e(b)[1,1]
					mat	Jalan_Rav_2000_edu_`degree'	=	e(N_sub),	e(b), prop_trans_edu_`degree'
					
				}
				
				mat	Jalan_Rav_2000_edu	=	Jalan_Rav_2000_edu_NoHS	\	Jalan_Rav_2000_edu_HS	\	Jalan_Rav_2000_edu_somecol	\	Jalan_Rav_2000_edu_col

				
				 *	Further decomposition
			   cap	mat	drop	Jalan_Rav_2000_decomp_`measure'
			   cap	mat	drop	Pop_ratio
			   svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1):	///
				mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure' 
			   local	subsample_tot=e(N_subpop)		   
			   
			   foreach	race	in	 HH_race_color	HH_race_white	{	//	Black, white
					foreach	gender	in	HH_female	gender_head_fam_enum2	{	//	Female, male
						foreach	edu	in	NoHS	HS	somecol	col   	{	//	No HS, HS, some col, col
							svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1  & `gender'==1 & `race'==1 & highdegree_`edu'_2001==1): mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
							local	Pop_ratio	=	e(N_subpop)/`subsample_tot'
							scalar	prop_trans_edu_race_gender	=	e(b)[1,2]/e(b)[1,1]
							mat	Jalan_Rav_2000_decomp_`measure'	=	nullmat(Jalan_Rav_2000_decomp_`measure')	\	`Pop_ratio',	e(b), prop_trans_edu_race_gender
						}	// edu			
					}	//	gender	
			   }	//	race

				
				*	Combine results (Table 8 of 2020/11/16 draft)
				mat	define	blankrow	=	J(1,5,.)
				mat	Jalan_Rav_2000_allcat_`measure'	=	Jalan_Rav_2000_all	\	blankrow	\	Jalan_Rav_2000_gender	\	blankrow	\	Jalan_Rav_2000_race	\	///
												blankrow	\	Jalan_Rav_2000_region	\	blankrow	\	Jalan_Rav_2000_metro	\	blankrow \	///
												Jalan_Rav_2000_edu	//	To be combined with category later.
				mat	Jalan_Rav_2000_combined_`measure'	=	Jalan_Rav_2000_allcat_`measure'	\	blankrow	\	blankrow	\	Jalan_Rav_2000_decomp_`measure'

				putexcel	set "${PSID_outRaw}/Jalan_Rav", sheet(Jalan_Rav_`measure') `exceloption'
				putexcel	A3	=	matrix(Jalan_Rav_2000_combined_`measure'), names overwritefmt nformat(number_d1)
				
				esttab matrix(Jalan_Rav_2000_combined_`measure', fmt(%9.3f)) using "${PSID_outRaw}/Jalan_Rav_combined_`measure'.tex", replace	
				
				local	exceloption	modify
			}
			
			*	Categorize HH into four categories
			*	First, generate dummy whether (1) always or not-always FI (2) Never or sometimes FI
				loc	var1	PFS_FI_always_ols
				loc	var2	PFS_FI_never_ols
				cap	drop	`var1'
				cap	drop	`var2'
				bys	fam_ID_1999:	egen	`var1'	=	min(rho1_thrifty_FI_ols)	//	1 if always below (persistently poor), 0 if sometimes below (not persistently poor)
				bys	fam_ID_1999:	egen	`var2'	=	min(rho1_thrifty_FS_ols)	//	1 if never poor, 0 if sometimes poor (transient)
				replace	`var1'=.	if	year==1
				replace	`var2'=.	if	year==1
			
			local	exceloption	modify
			foreach	measure	in	HCR	SFIG	{
				
				assert	Total_FI_`measure'==0 if PFS_FI_never_ols==1	//	Make sure TFI=0 when HH is always FS (PFS>cut-off PFS)
				
				*	Categorize households
				cap	drop	PFS_perm_FI_`measure'
				gen		PFS_perm_FI_`measure'=1	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_always_ols==1	///
					//	Persistently FI (CFI>0, always FI)
				replace	PFS_perm_FI_`measure'=2	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_always_ols==0	///
					//	Chronically but not persistently FI (CFI>0, not always FI)
				replace	PFS_perm_FI_`measure'=3	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_never_ols==0		///
					//	Transiently FI (CFI=0, not always FS)
				replace	PFS_perm_FI_`measure'=4	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	Total_FI_`measure'==0	///
					//	Always FS (CFI=TFI=0)
					
				label	define	PFS_perm_FI	1	"Persistently FI"	///
											2	"Chronically, but not persistently FI"	///
											3	"Transiently FI"	///
											4	"Never FI"	///
											,	replace
			
				label values	PFS_perm_FI_`measure'	PFS_perm_FI
				
			*	Descriptive stats
			
				*	Overall
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): proportion	PFS_perm_FI_`measure'
				mat	PFS_perm_FI_all	=	e(N_sub),	e(b)
				
				*	Gender
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	gender_head_fam_enum2):	///
					proportion PFS_perm_FI_`measure'
				mat	PFS_perm_FI_male	=	e(N_sub),	e(b)
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_female):	///
					proportion PFS_perm_FI_`measure'
				mat	PFS_perm_FI_female	=	e(N_sub),	e(b)
				
				mat	PFS_perm_FI_gender	=	PFS_perm_FI_male	\	PFS_perm_FI_female
				
			
				*	Race
				foreach	type	in	1	0	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_race_white==`type'):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_race_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_race	=	PFS_perm_FI_race_1	\	PFS_perm_FI_race_0
				
				*	Region
				foreach	type	in	NE	MidAt	South	MidWest West	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_region_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_region	=	PFS_perm_FI_region_NE	\	PFS_perm_FI_region_MidAt	\	PFS_perm_FI_region_South	\	///
											PFS_perm_FI_region_MidWest	\	PFS_perm_FI_region_West
				
				*	Metropolitan
				foreach	type	in	metro	nonmetro	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	resid_`type'==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_metro_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_metro	=	PFS_perm_FI_metro_metro	\	PFS_perm_FI_metro_nonmetro
				
				
				*	Education
				foreach	degree	in	NoHS	HS	somecol	col	{
				    
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	highdegree_`degree'_2001==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_edu_`degree'	=	e(N_sub),	e(b)
					
				}
				mat	PFS_perm_FI_edu	=	PFS_perm_FI_edu_NoHS	\	PFS_perm_FI_edu_HS	\	PFS_perm_FI_edu_somecol	\	PFS_perm_FI_edu_col
				

				*	Combine results (Table 9 of 2020/11/16 draft)
				mat	define	blankrow	=	J(1,5,.)
				mat	PFS_perm_FI_combined_`measure'	=	PFS_perm_FI_all	\	blankrow	\	PFS_perm_FI_gender	\	blankrow	\	PFS_perm_FI_race	\	blankrow	\	///
														PFS_perm_FI_region	\	blankrow	\	PFS_perm_FI_metro	\	blankrow	\	PFS_perm_FI_edu
				
				mat	list	PFS_perm_FI_combined_`measure'
				
				di "excel option is `exceloption'"
				putexcel	set "${PSID_outRaw}/Jalan_Rav", sheet(FI_perm_`measure') `exceloption'
				putexcel	A3	=	matrix(PFS_perm_FI_combined_`measure'), names overwritefmt nformat(number_d1)
			
				esttab matrix(PFS_perm_FI_combined_`measure', fmt(%9.2f)) using "${PSID_outRaw}/PFS_perm_FI_`measure'.tex", replace	
				
				*	Table 5 & 6 (combined) of Dec 20 draft
				mat	define Table_5_`measure'	=	Jalan_Rav_2000_allcat_`measure',	PFS_perm_FI_combined_`measure'[.,2...]
				
				putexcel	set "${PSID_outRaw}/Jalan_Rav", sheet(Table5_`measure') `exceloption'
				putexcel	A3	=	matrix(Table_5_`measure'), names overwritefmt nformat(number_d1)
			
				esttab matrix(Table_5_`measure', fmt(%9.3f)) using "${PSID_outRaw}/Table_5_`measure'.tex", replace
				
				local	exceloption	modify
				
			}	//	measure
		
		*	Group State-FE of TFI and CFI
		local	demovars	age_head_fam age_head_fam_sq	HH_female	HH_race_color	/*HH_race_black HH_race_other*/	marital_status_cat
		local	econvars	ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	num_FU_fam ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ highdegree_NoHS highdegree_somecol highdegree_col	
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_group?	state_group1?	state_group2?	//	excluding NY (state_bgroup) as reference state group.
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.age_over65	///
								c.HH_female#c.age_over65	///
								c.ln_income_pc#c.HH_female#c.age_over65	///
								c.no_longer_married#c.HH_female
		local	timevars	year_enum3-year_enum10
		
			*	Regression of TFI/CFI on Group state FE
			
			foreach	depvar	in	Total_FI	Chronic_FI	Transient_FI	{
				
				/*
				*	Without controls/time FE
				qui	svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' `regionvars'
				est	store	`depvar'_nocontrols
				*/
				
				*	With controls/time FE
				qui	svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' 	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`shockvars'	`regionvars'	`timevars'
				est	store	`depvar'
			}
			
			*	Output
			esttab	Total_FI	Chronic_FI	Transient_FI	using "${PSID_outRaw}/TFI_CFI_regression.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Regression of TFI/CFI on Characteristics) 	///
					addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
					replace
					
			esttab	Total_FI	Chronic_FI		using "${PSID_outRaw}/TFI_CFI_regression.tex", ///
					cells(b(star fmt(a3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Regression of TFI/CFI on Characteristics) 	///
					addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
					replace		
			
			
			local	shapley_decomposition=1
			*	Shapley Decomposition
			if	`shapley_decomposition'==1	{
				
				ds	state_group?	state_group1?	state_group2?
				local groupstates `r(varlist)'
				
				
				foreach	depvar	in	Total_FI	Chronic_FI	{
					
					*	Unadjusted
					cap	drop	_mysample
					regress `depvar' 	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`shockvars'	`regionvars'	`timevars'	 if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head no_longer_employed	no_longer_married	no_longer_own_house	became_disabled) 
					
					mat	`depvar'_shapley_indiv	=	e(shapley),	e(shapley_rel)
					mata : st_matrix("`depvar'_shapley_sum", colsum(st_matrix("`depvar'_shapley_indiv")))
					
					mat	`depvar'_shapley	=	`depvar'_shapley_indiv	\	`depvar'_shapley_sum
					
					
					*	Survey-adjusted
					cap	drop	_mysample
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar'  	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`shockvars'	`regionvars'	`timevars'		
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head no_longer_employed	no_longer_married	no_longer_own_house	became_disabled)
				
				}	//	depvar			
			}	//	shapley
			
			mat	TFI_CFI_shapley	=	Total_FI_shapley,	Chronic_FI_shapley
			
			putexcel	set "${PSID_outRaw}/Jalan_Rav", sheet(shapley) /*replace*/	modify
			putexcel	A3	=	matrix(TFI_CFI_shapley), names overwritefmt nformat(number_d1)
			
			esttab matrix(TFI_CFI_shapley, fmt(%9.3f)) using "${PSID_outRaw}/TFI_CFI_shapley.tex", replace	
		
			*	Northeast & Mid-Atlantic
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group1	state_group2	state_group3	state_group4	state_group5)	xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(Northeast and Mid-Atlantic)	name(TFI_CFI_FE_NE_MA, replace) /*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_NE.png", replace
				graph	close

			/*
			*	Mid-Atlantic
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group2	state_group3	state_group4	state_group5)	xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(TFI_CFI_Mid_Atlantic)	name(TFI_CFI_FE_MA, replace)	xscale(range(-0.05(0.05) 0.10))
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_MA.png", replace
				graph	close
			*/
			
			*	South
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group6 state_group7 state_group8 state_group9 state_group10 state_group11)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(South)	name(TFI_CFI_FE_South, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_South.png", replace
				graph	close
				
			*	Mid-West
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group12 state_group13 state_group14 state_group15 state_group16 state_group17)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(Mid-West)	name(TFI_CFI_FE_MW, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_MW.png", replace
				graph	close
			
			*	West
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group18 state_group19 state_group20 state_group21)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(West)		name(TFI_CFI_FE_West, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_West.png", replace
				graph	close
	
		/*
			graph combine	TFI_CFI_FE_NE_MA	TFI_CFI_FE_South	TFI_CFI_FE_MW	TFI_CFI_FE_West, title(Region Fixed Effects)
			graph	export	"${PSID_outRaw}/TFI_CFI_region_FE.png", replace
			graph	close
		*/
		
	
		
		grc1leg2		TFI_CFI_FE_NE_MA	TFI_CFI_FE_South	TFI_CFI_FE_MW	TFI_CFI_FE_West,	///
											title(Region Fixed Effects) legendfrom(TFI_CFI_FE_NE_MA)	///
											graphregion(color(white))	/*xtob1title	*/
											/*	note(Vertical line is the average retirement age of the year in the sample)	*/
							graph	export	"${PSID_outRaw}/TFI_CFI_region_FE.png", replace
							graph	close
		
		
		
		coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(Regional Fixed Effects)		name(TFI_CFI_FE_All, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_All.png", replace
				graph	close
			
		/*
		preserve
			keep	fam_ID_1999	/*weight_multi12	newsecu*/	sample_source	SFIG	SFIG_mean	SFIG_transient
			duplicates drop
			drop	if	mi(SFIG)
			*	Summary stats (unweighted)
			summ	SFIG	SFIG_mean	SFIG_transient	//	All
			bys	sample_source: summ	SFIG	SFIG_mean	SFIG_transient	//	By sample
		restore
		*/
		
	}
	
	
	/****************************************************************
		SECTION 8: Associations
	****************************************************************/		
	
	local	specification_check	0	//	varying RHS
	local	stationary_check	0	//	Testing stationary of the data
	local	pre_post	0			//	Pre- and Post- Great Recession
	local	pred_PFS_over_age	0	//	Predicted PFS over age
	local	ME_income_level		0	//	Marginal effect over different income level
	
	tsset	fam_ID_1999 year, delta(1)
	
		
	*	Specification check
	if	`specification_check'==1	{
	
		cap	drop	fv
			
			/*
			*	U.S. Life expentancy for male and female (Source: United Nations Population Division)
			
				*	Male
				scalar	life_exp_male_1999	=	73.9
				scalar	life_exp_male_2001	=	74.3
				scalar	life_exp_male_2003	=	74.5
				scalar	life_exp_male_2005	=	75
				scalar	life_exp_male_2007	=	75.5
				scalar	life_exp_male_2009	=	76
				scalar	life_exp_male_2011	=	76.3
				scalar	life_exp_male_2013	=	76.4
				scalar	life_exp_male_2015	=	76.3
				scalar	life_exp_male_2017	=	76.1
				
				*	Female
				scalar	life_exp_female_1999	=	79.4
				scalar	life_exp_female_2001	=	79.5
				scalar	life_exp_female_2003	=	79.7
				scalar	life_exp_female_2005	=	80.1
				scalar	life_exp_female_2007	=	80.6
				scalar	life_exp_female_2009	=	80.9
				scalar	life_exp_female_2011	=	81.1
				scalar	life_exp_female_2013	=	81.2
				scalar	life_exp_female_2015	=	81.2
				scalar	life_exp_female_2017	=	81.1
			*/
											
					
			local	depvar		rho1_foodexp_pc_thrifty_ols
			*local	lagdepvar	l.`depvar'
			local	demovars	c.age_head_fam##c.age_head_fam	HH_female	ib1.race_head_cat	marital_status_cat
			local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
			local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
			local	eduvars		/*attend_college_head*/ ib2.grade_comp_cat	
			local	empvars		emp_HH_simple
			local	healthvars	phys_disab_head
			local	foodvars	food_stamp_used_1yr	/*child_meal_assist WIC_received_last*/	elderly_meal
			local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
			local	regionvars	ib0.state_resid_fam	
			local	interactvars	c.ln_income_pc#c.HH_female	///
									c.ln_income_pc#c.age_over65	///
									c.HH_female#c.age_over65	///
									c.ln_income_pc#c.HH_female#c.age_over65	///
									c.no_longer_married#c.HH_female
			local	timevars	i.year
	
			
			*	OLS
			
				*	Without interaction	&	shocks
				svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	/*`shockvars'		`interactvars'*/	`regionvars'	`timevars'
				*svy: meglm `depvar'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`healthvars'	`foodvars'	`regionvars'
				est	store	Prob_FI_benchmark
					
				*	With interaction	&	shocks
				svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
				*svy: meglm `depvar'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`healthvars'	`foodvars'	`regionvars'
				est	store	Prob_FI_interact
				
				*	Auxiliary regression
				svy: reg	`econvars'	`demovars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
				est	store	Income_interact
				
				esttab	Prob_FI_benchmark	Prob_FI_interact	Income_interact	using "${PSID_outRaw}/Prob_FI_pooled.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Prob(food insecure)-Pooled) replace

				*	Joint Hypothesis test of variables
				est	restore		Prob_FI_interact
				
					*	age and its interaction terms (whether age matters)
					test	age_head_fam c.age_head_fam#c.age_head_fam
					
					*	gender and its interaction terms (whether gender matters)
					test	HH_female	c.ln_income_pc#c.HH_female	c.HH_female#c.age_over65	c.ln_income_pc#c.HH_female#c.age_over65
					
					*	income and its interaction terms (wheter income matters)
					test	c.ln_income_pc	c.ln_income_pc#c.HH_female	c.ln_income_pc#c.age_over65	c.ln_income_pc#c.HH_female#c.age_over65
					
					*	# of FU and # of children (jointly) (whether family size matters)
					//test	c.num_FU_fam c.num_child_fam
					
					*	All terms interacting with outside workinge age (whether being non-working age matters)
					test	c.ln_income_pc#c.age_over65	c.HH_female#c.age_over65	c.ln_income_pc#c.HH_female#c.age_over65
					
					*	No longer married and its interaction term (wheter being no longer married matters)
					test	no_longer_married	c.no_longer_married#c.HH_female
		
					*	Whether all the interaction terms are jointly significant (whether all interaction terms matters)
					test	`interactvars'
	}
		
	*	Test stationary		
	if	`stationary_check'==1	{
		
		*	Convert interaction variables into normal variable, for xtserial test
		cap	drop	race_black
		cap	drop	race_other
		cap	drop	highest_grade?
		cap	drop	income_gender
		cap	drop	income_nonwork
		cap	drop	gender_nonwork
		cap	drop	income_gender_nonwork
		cap	drop	nomarried_gender
		gen	race_black		=	0	if	!mi(race_head_cat)
		replace	race_black	=	1	if	race_head_cat==2
		gen	race_other		=	0	if	!mi(race_head_cat)
		replace	race_other	=	1	if	race_head_cat==3
		tab grade_comp_cat,	gen(highest_grade)
		gen	income_gender	=	c.ln_income_pc#c.HH_female
		gen	income_nonwork	=	c.ln_income_pc#c.age_over65
		gen	gender_nonwork	=	c.HH_female#c.age_over65
		gen	income_gender_nonwork	=	c.ln_income_pc#c.HH_female#c.age_over65
		gen	nomarried_gender	=	c.no_longer_married#c.HH_female
		
				
		local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	HH_female	ib1.race_head_cat	marital_status_cat
		local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ ib2.grade_comp_cat	
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	/*child_meal_assist WIC_received_last*/	elderly_meal
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	ib0.state_resid_fam	
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.age_over65	///
								c.HH_female#c.age_over65	///
								c.ln_income_pc#c.HH_female#c.age_over65	///
								c.no_longer_married#c.HH_female
		local	timevars	i.year
	
		
		*	Chris' suggestion
				
				*	Testing whether dependent variable is stationary (warning: takes some time)
						xtunitroot fisher	rho1_foodexp_pc_thrifty_ols if ${study_sample}==1 ,	dfuller lags(0)	//	trend
						xtunitroot ips		rho1_foodexp_pc_thrifty_ols if ${study_sample}==1 	//,	dfuller lags(0)	//	trend
					
				*	Testing whether there exist serial correlation
				xtserial	rho1_foodexp_pc_thrifty_ols	///	//	depvar
							age_head_fam age_head_fam_sq	race_black	race_other	marital_status_cat ///	//	Demographic vars
							ln_income_pc	///	//	income var
							emp_HH_simple	///	//	emp var
							num_FU_fam	num_child_fam	///	//	family var
							highest_grade1 highest_grade3 highest_grade4	///	//	edu vars
							state_resid_fam_enum2-state_resid_fam_enum52	///	region vars
							no_longer_employed	no_longer_married	no_longer_own_house	became_disabled	///	//	shockvars
							income_gender	income_nonwork	gender_nonwork	income_gender_nonwork	nomarried_gender, output	//	interact vars		
			
				reg	rho1_foodexp_pc_thrifty_ols	l(1/1).rho1_foodexp_pc_thrifty_ols
				
				*	Use pooled data with time FE to estimate conditional mean, and check whether there are serial correlation among residuals
				cap	drop	resid_trend
				svy: reg	`depvar'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`healthvars'	`foodvars'	`shockvars'	`interactvars'	`regionvars'	year	//	include time trend, either as linear or as FE
				predict	resid_withtrend, residual
				
				
				xtreg	resid_withtrend	l.resid_withtrend, vce(cluster fam_ID_1999) fe	//	If the estimate is statistically significant, then there is autocorrelation among residuals.
				
				*	Testing different ARMA(p,q) model
				*	Here we will test p and q from 1  to 3.
				
				forvalues	p=1/3	{
					forvalues	q=1/3	{
						cap	drop	resid_p`p'_q`q'
						
						svy: reg	`depvar'	l(1/`p').`depvar'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`healthvars'	`foodvars'	`shockvars'	`interactvars'	`regionvars'	l(1/`q').resid_withtrend
						predict	resid_p`p'_q`q', resid
						
						xtreg		resid_p`p'_q`q'	l.resid_p`p'_q`q', fe vce(cluster fam_ID_1999)	
						est	store	ARMA_p`p'_q`q'
					}
				}
				
				esttab	ARMA_p1_q1	ARMA_p1_q2	ARMA_p1_q3	///
						ARMA_p2_q1	ARMA_p2_q2	ARMA_p1_q3	///
						ARMA_p3_q1	ARMA_p3_q2	ARMA_p1_q3	///
						using "${PSID_outRaw}/ARMA_check.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Residual Autocorrelation under ARMA(p,q)) replace

				predict temp, residual
				reg		temp l.temp
				est	store	nolag
				xtreg	temp l.temp, fe
				est	store	nolag_fe
				xtreg	temp l.temp, vce(cluster fam_ID_1999) fe
				est	store	nolag_fe_cl
				
				svy: reg	`depvar'	l.`depvar'
				predict	temp_lag, residual
				reg	temp_lag	l.temp_lag
				est	store	onelag
				xtreg	temp_lag	l.temp_lag, fe
				est	store	onelag_fe
				xtreg	temp_lag	l.temp_lag, vce(cluster fam_ID_1999) fe
				est	store	onelag_fe_cl
				
				svy: reg	`depvar'	l.`depvar'	l2.`depvar'	
				predict	temp_lag2, residual
				reg	temp_lag2	l.temp_lag2
				est	store	twolag
				xtreg	temp_lag2	l.temp_lag2, fe
				est	store	twolag_fe
				xtreg	temp_lag2	l.temp_lag2, vce(cluster fam_ID_1999) fe
				est	store	twolag_fe_cl
				
				svy: reg	`depvar'	l.`depvar'	l2.`depvar'		l3.`depvar'
				predict	temp_lag3, residual
				reg	temp_lag3	l.temp_lag3
				est	store	threelag
				xtreg	temp_lag3	l.temp_lag3, fe
				est	store	threelag_fe
				xtreg	temp_lag3	l.temp_lag3, vce(cluster fam_ID_1999) fe
				est	store	threelag_fe_cl
				
				esttab	nolag	nolag_fe	nolag_fe_cl	///
						onelag	onelag_fe	onelag_fe_cl	///	
						twolag	twolag_fe	twolag_fe_cl	///
						threelag	threelag_fe	threelag_fe_cl	///
						using "${PSID_outRaw}/acr_check.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Residual Autocorrelation) replace
				
		/*		
				cap	drop	resid_nocov_tr
				predict	resid_nocov_tr, residual
				
				xtreg	resid_withtimeFE	l.resid_withtimeFE	l2.resid_withtimeFE, fe
				est	store	resid_autocorr_nocluster
				
				xtreg	resid_withtimeFE	l.resid_withtimeFE	l2.resid_withtimeFE, vce(cluster fam_ID_1999) fe
				est	store	resid_autocorr_cluster
				
			
				
				esttab	resid_autocorr_nocluster	resid_autocorr_cluster	using "${PSID_outRaw}/resid_autocorr.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Residual Autocorrelation) replace
				
		
			*	Suppose there is autocorrelation, then ad lagged dep var on RHS
				svy: reg	`depvar'	cl.`depvar'	cl2.`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`shockvars'	`interactvars'	`regionvars'	i.year
				
				cap	drop	resid_withtimeFE
				predict	resid_withtimeFE, residual
				
				xtreg	resid_withtimeFE	l.resid_withtimeFE, fe
				est	store	resid_atcr_lag_nocluster
				
				xtreg	resid_withtimeFE	l.resid_withtimeFE, vce(cluster fam_ID_1999) fe
				est	store	resid_atcr_lag_cluster
				
				esttab	resid_atcr_lag_nocluster	resid_atcr_lag_cluster	using "${PSID_outRaw}/resid_lagdep_autocorr.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Residual Autocorrelation) replace
		*/
	}
	
	*	Pre- and Post- Great Recession
	if	`pre_post'==1	{
		
		cap	drop	pre_recession post_recession	
		gen		pre_recession	=	0
		replace	pre_recession	=	1	if	inrange(year,1,5)	//	Wave 1999 to 2007
		gen		post_recession	=	0
		replace	post_recession	=	1	if	inrange(year,6,10)	//	Wave 2009 to 2017
	
		local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	c.HH_female	c.HH_race_black c.HH_race_other	c.marital_status_cat
		local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ c.highdegree_NoHS c.highdegree_somecol c.highdegree_col
		local	empvars		c.emp_HH_simple
		local	healthvars	c.phys_disab_head
		local	foodvars	c.food_stamp_used_1yr	/*child_meal_assist elderly_meal*/	c.WIC_received_last	
		local	shockvars	c.no_longer_employed	c.no_longer_married	c.no_longer_own_house	c.became_disabled
		local	regionvars	ib0.state_resid_fam	
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.age_over65	///
								c.HH_female#c.age_over65	///
								c.ln_income_pc#c.HH_female#c.age_over65	///
								c.no_longer_married#c.HH_female
		local	timevars	i.year
		
		/*
		*	Benchmark
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'
		est	store	CB_benchmark
		

		*	With interaction, pooled
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		est	store	CB_interact
		*/
		
		*	Determine estimation sample
		cap drop pre_USDA_sample	post_USDA_sample	pre_PFS_sample	post_PFS_sample	pre_sample	post_sample
		
		local	depvar	fs_scale_fam_rescale
		qui svy, subpop(pre_recession):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		gen pre_USDA_sample=1	if	e(sample)==1 & `=e(subpop)'
		
		qui svy, subpop(post_recession):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		gen post_USDA_sample=1	if	e(sample)==1 & `=e(subpop)'
		
		local	depvar	rho1_foodexp_pc_thrifty_ols
		qui svy, subpop(pre_recession):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		gen pre_PFS_sample=1	if	e(sample)==1 & `=e(subpop)'
		
		qui svy, subpop(post_recession):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		gen post_PFS_sample=1	if	e(sample)==1 & `=e(subpop)'
		
		gen	pre_sample=1	if	pre_USDA_sample==1	&	pre_PFS_sample==1
		gen	post_sample=1	if	post_USDA_sample==1	&	post_PFS_sample==1
		
		
		*	USDA
		local	depvar	fs_scale_fam_rescale
		
			*	Pre-recession
			qui svy, subpop(pre_sample):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
			estadd scalar N = e(N_sub), replace
			est	store	pre_recession_USDA
		
			*	Post-recession
			qui svy, subpop(post_sample):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
			estadd scalar N = e(N_sub), replace
			est	store	post_recession_USDA
		
			*	Combined regression for chow test
			*	Time dummies should be dropped to estimate the coefficient on post-recession dummy
			svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	/*`timevars'*/	///
						i.post_recession	i.post_recession#(`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars')
			
			est	store	prepost_USDA
			contrast	post_recession	post_recession#(`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'), overall	post
			est	store	chow_test_USDA
			
		*	PFS
		local	depvar	rho1_foodexp_pc_thrifty_ols
		
			*	Pre-recession	
			qui svy, subpop(pre_sample):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
			estadd scalar N = e(N_sub), replace
			est	store	pre_recession_PFS
		
			*	Post-recession
			qui svy, subpop(post_sample):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
			estadd scalar N = e(N_sub), replace
			est	store	post_recession_PFS
		
			*	Combined regression for chow test (Column 3 and 6 of Table 5, 2020/11/16 draft)
			*	Time dummies should be dropped to estimate the coefficient on post-recession dummy
			svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	/*`timevars'*/	///
						i.post_recession	i.post_recession#(`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars')
			
			est	store	prepost_PFS
			contrast	post_recession	post_recession#(`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'), overall	post
			est	store	chow_test_PFS
		
		
		*	Display output (Column 1,2,4,5 of 2020/11/16 draft)
		
		esttab	pre_recession_USDA	post_recession_USDA	pre_recession_PFS	post_recession_PFS	using "${PSID_outRaw}/prepost_USDA_PFS.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Parameter Stability between Pre- and Post- Recession) replace
				
		esttab	pre_recession_USDA	post_recession_USDA	pre_recession_PFS	post_recession_PFS	using "${PSID_outRaw}/prepost_USDA_PFS.tex", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Parameter Stability between Pre- and Post- Recession) replace
		
	}
		
	*	Predicted PFS over age (Figure 1 of 2020/11/16 draft)
	if	`pred_PFS_over_age'==1	{
		
		cap	drop	fv
			
			*	U.S. Life expentancy for male and female (Source: United Nations Population Division)
			
				*	Male
				scalar	life_exp_male_1999	=	73.9
				scalar	life_exp_male_2001	=	74.3
				scalar	life_exp_male_2003	=	74.5
				scalar	life_exp_male_2005	=	75
				scalar	life_exp_male_2007	=	75.5
				scalar	life_exp_male_2009	=	76
				scalar	life_exp_male_2011	=	76.3
				scalar	life_exp_male_2013	=	76.4
				scalar	life_exp_male_2015	=	76.3
				scalar	life_exp_male_2017	=	76.1
				
				*	Female
				scalar	life_exp_female_1999	=	79.4
				scalar	life_exp_female_2001	=	79.5
				scalar	life_exp_female_2003	=	79.7
				scalar	life_exp_female_2005	=	80.1
				scalar	life_exp_female_2007	=	80.6
				scalar	life_exp_female_2009	=	80.9
				scalar	life_exp_female_2011	=	81.1
				scalar	life_exp_female_2013	=	81.2
				scalar	life_exp_female_2015	=	81.2
				scalar	life_exp_female_2017	=	81.1
				
		*	Prediction
		
		local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	HH_female	HH_race_color	marital_status_cat
		local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ highdegree_NoHS highdegree_somecol highdegree_col
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_group? state_group1? state_group2?
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.age_over65	///
								c.HH_female#c.age_over65	///
								c.ln_income_pc#c.HH_female#c.age_over65	///
								c.no_longer_married#c.HH_female
		local	timevars	year_enum3-year_enum10
		
		
		
			local	depvar	rho1_foodexp_pc_thrifty_ols
			qui svy:	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	///
										`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'
					*est	restore	Prob_FI_interact
					predict fv,xb
					
						*	Over the age, using the deviation from the life expectancy
						cap	drop	dev_from_lifeexp
						gen		dev_from_lifeexp=.
						forvalues	year=1999(2)2017	{
							replace	dev_from_lifeexp	=	age_head_fam-life_exp_male_`year'	if	HH_female==0	&	year2==`year'
							replace	dev_from_lifeexp	=	age_head_fam-life_exp_female_`year'	if	HH_female==1	&	year2==`year'
						}
						label	variable	dev_from_lifeexp	"Deviation from the life expectancy by year and gender"
						
				/*
				twoway	(lpolyci fv dev_from_lifeexp	if	HH_female==0)	///
						(lpolyci fv dev_from_lifeexp	if	HH_female==1),	///
						title(Predicted PFS over the age)	note(Life Expectancy are 73.9(male) and 79.4(female) in 1999 and 76.1(male) and 81.1(female) in 2017) ///
						legend(lab (2 "Male") lab(3 "Female") rows(1))	xtitle(Deviation from the Life Expectancy)
				graph	export	"${PSID_outRaw}/Fitted_age_pooled.png", replace
				graph	close
			
				*	By each year in a single graph
				twoway	(lpoly fv dev_from_lifeexp if year2==1999)	(lpoly fv dev_from_lifeexp if year2==2005)	///
						(lpoly fv dev_from_lifeexp if year2==2011)	(lpoly fv dev_from_lifeexp if year2==2017),	///
						legend(lab (1 "1999") lab(2 "2005") lab(3 "2011") lab(4 "2017") rows(1))	///
						xtitle(Deviation from the Life Expectancy)	ytitle(Predicted PFS)	title(Predicted PFS over Life)
				graph	export	"${PSID_outRaw}/Fitted_age_byyear.png", replace
				graph	close
				*/		
								
						*	W.R.T. average retirement age
							
							*	Average retirement age by year
							forval	year=1999(2)2017	{
								summarize	retire_age	if	retire_year_head==`year'
								*svy, subpop(year_enum`year'): mean retire_age // if	retire_year_head==`year'
							}

							
							*	1999							
							summ	retire_age	if	retire_year_head==1999	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==1),	///
									xline(`r(mean)')	xscale(range(20 100))	yscale(range(0.4(0.2)1))	xtitle(Age)	legend(lab (2 "PFS"))	///
									graphregion(color(white)) bgcolor(white)	///
									title(1999)	name(fv_age_retire_1999, replace)
							
							*	2007
							summ	retire_age	if	retire_year_head==2005	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==4),	///
									xline(`r(mean)')	xscale(range(20 100))	yscale(range(0.4(0.2)1))	xtitle(Age) legend(lab (2 "PFS"))	///
									graphregion(color(white)) bgcolor(white)	///
									title(2005)	name(fv_age_retire_2005, replace)
							
							*	2013
							summ	retire_age	if	retire_year_head==2011	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==7),	///
									xline(`r(mean)')	xscale(range(20 100))	yscale(range(0.4(0.2)1))	xtitle(Age) legend(lab (2 "PFS"))	///
									graphregion(color(white)) bgcolor(white)	///
									title(2011)	name(fv_age_retire_2011, replace)
							
							*	2017
							summ	retire_age	if	retire_year_head==2017	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==10),	///
									xline(`r(mean)')	xscale(range(20 100))	yscale(range(0.4(0.2)1))	xtitle(Age) legend(lab (2 "PFS"))	///
									graphregion(color(white)) bgcolor(white)	///
									title(2017)	name(fv_age_retire_2017, replace)
							
							grc1leg2		fv_age_retire_1999	fv_age_retire_2005	fv_age_retire_2011	fv_age_retire_2017,	///
											/*title(Predicted PFS over age)*/ legendfrom(fv_age_retire_1999)	///
											graphregion(color(white))	/*xtob1title	*/
											/*	note(Vertical line is the average retirement age of the year in the sample)	*/
							graph	export	"${PSID_outRaw}/Fitted_age_retirement.png", replace
							graph	close
			
			
	}
	
	*	Marginal effects over different income level (Figure 2 of 2020/11/16 draft)
	if	`ME_income_level'==1	{
		
		local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	c.HH_female	c.HH_race_black c.HH_race_other	c.marital_status_cat
		local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ c.highdegree_NoHS c.highdegree_somecol c.highdegree_col
		local	empvars		c.emp_HH_simple
		local	healthvars	c.phys_disab_head
		local	foodvars	c.food_stamp_used_1yr	/*child_meal_assist elderly_meal*/	c.WIC_received_last	
		local	shockvars	c.no_longer_employed	c.no_longer_married	c.no_longer_own_house	c.became_disabled
		local	regionvars	ib0.state_resid_fam	
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.age_over65	///
								c.HH_female#c.age_over65	///
								c.ln_income_pc#c.HH_female#c.age_over65	///
								c.no_longer_married#c.HH_female
		local	timevars	i.year
		
		
		svy:	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		gen	marginplot_sample=1	if	e(sample)
		est	store	Prob_FI_interact
		
		svy, subpop(if income_to_poverty_cat==1 & marginplot_sample==1): mean rho1_foodexp_pc_thrifty_ols
		
		*	By income group
		est	restore	Prob_FI_interact
		margins,	dydx(c.ln_income_pc)	over(income_to_poverty_cat)
		marginsplot, title("") xtitle(Income-to-Poverty Ratio)	xlabel(,angle(45))	ytitle(PFS(percentage point))	///
						name(ME_byincome, replace) graphregion(color(white)) bgcolor(white)	///
						/*note(1% change in income increases PFS by y-var percentage point)*/
		graph	export	"${PSID_outRaw}/ME_income_bygroup.png", replace
		graph	close
		
		*	By income group, around poverty threshold
		cap	drop	income_to_poverty_lowtail
		gen	income_to_poverty_lowtail=.	if	!inrange(income_to_poverty,0,3)
		forval	i=0.2(0.2)3.0	{
			
			local	minval	=	`i'-0.2
			local	maxval	=	`i'
			replace	income_to_poverty_lowtail	=	`maxval'*100	if	inrange(income_to_poverty,`minval',`maxval')
		}
		est	restore	Prob_FI_interact
		margins,	dydx(c.ln_income_pc)	over(income_to_poverty_lowtail)
		marginsplot, title("") xtitle(Income to Poverty Ratio(%))	xlabel(,angle(45))	ytitle(PFS(percentage point))	///
						name(ME_byincome_lowtail, replace)	graphregion(color(white)) bgcolor(white)	///
						/*note("Income to Poverty Ratio is calculated by dividing total annual income into Federal Poverty Line" "Semi- elasticity of the PFS")*/
		graph	export	"${PSID_outRaw}/ME_income_lowtail.png", replace
		graph	close
		
		grc1leg2		ME_byincome	ME_byincome_lowtail	,	rows(2) cols(1) 	///
						/*title(Predicted PFS over age) legendfrom(fv_age_retire_1999)*/	///
						graphregion(color(white))	/*xtob1title	*/
						/*	note(Vertical line is the average retirement age of the year in the sample)	*/
		graph	export	"${PSID_outRaw}/ME_income_combined.png", replace
		graph	close		
		
	}


	
/* Junk Code */
/* The following codes are old codes used when outcome variable are non-negative discrete variables (FS score) */		

/*
	*	Declare list of variables
	local	demovars	c.age_head_fam##c.age_head_fam i.race_head_cat gender_head_fam	ib1.marital_status_cat	grade_comp_head_fam
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
				
				
	*	Traditional regression (non-LASSO)
	
		*	Declare list of variables
		
		*	Common controls
		local	demovars	c.age_head_fam##c.age_head_fam i.race_head_cat gender_head_fam	ib1.marital_status_cat	
		local	eduvars		grade_comp_head_fam	c.grade_comp_head_fam#hs_completed c.grade_comp_head_fam#college_completed
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
	/*
	foreach Y in /*avg_foodexp_pc*/	respondent_BMI {
	
		*	Regression
		esttab	base1_`Y'	mean1_`Y'	var1_`Y'	R12_`Y'	using "${PSID_outRaw}/CB_regression_`Y'.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Regression) replace
			
		*	Marginal Effect
		esttab	margin1_base_`Y'	margin1_`Y'	margin2_`Y' 	margin3_`Y' margin3_`Y' 		using "${PSID_outRaw}/CB_ME_`Y'.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels /*drop(_cons)*/	title(Marginal Effects) replace
	}
	*/
	
		/*
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
	

	
		*	Distribution of food expenditure
		graph twoway (kdensity avg_foodexp_pc if year==10) /*(kdensity avg_foodexp_pc if (classic_step1_sample==1)	&	(classic_step2_sample==1) & year==10)*/, ///
				title (Distribution of Avg.food expenditure per capita)	/*///
				subtitle(Entire sample and regression sample)	///
				legend(lab (1 "All sample") lab(2 "Regression sample") rows(1))*/
				
	
		
		*	Distribution of food expenditure
		graph twoway (kdensity avg_foodexp_pc if year==10) (kdensity avg_foodexp_pc if year==10 & cvlass_sample==1), ///
				title (Distribution of Avg.food expenditure per capita)	///
				subtitle(Entire sample and regression sample)	///
				note(note: Top 1% of weight is winsorized)	///
				legend(lab (1 "All sample") lab(2 "Regression sample") rows(1))
				
		graph twoway (kdensity rho1_avg_foodexp_pc_thrifty) , ///
				title (Distribution of Resilience Score)	///
				subtitle(Thrifty Food Plan) name(thrifty, replace)

		graph twoway (kdensity rho1_avg_foodexp_pc_low)	 , ///
				title (Distribution of Resilience Score)	///
				subtitle(Low Food Plan) name(low, replace)
				
		graph twoway (kdensity rho1_avg_foodexp_pc_moderate) , ///
				title (Distribution of Resilience Score)	///
				subtitle(Moderate Food Plan) name(moderate, replace)
				
		graph twoway (kdensity rho1_avg_foodexp_pc_liberal) , ///
				title (Distribution of Resilience Score)	///
				subtitle(Liberal Food Plan) name(liberal, replace)
				
		graph close

		graph combine thrifty	low	moderate	liberal
		*/

	/*			
	local numvars : list sizeof `statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
					`familyvars'	`eduvars'	`foodvars'	`childvars'
	macro list numvars
	*/
	
	graph	twoway	(kdensity	rho1_avg_foodexp_pc_thrifty_ls)	///
				(kdensity	rho1_avg_foodexp_pc_thrifty_rf),	///
				title (Distribution of Resilience Score)	///
				subtitle(by construction method)	///
				note()
				legend(lab (1 "LASSO") lab(2 "RF") rows(1))

	rho1_avg_foodexp_pc_thrifty_ls	rho1_avg_foodexp_pc_thrifty_rf
	
	title (Distribution of Resilience Score)	///
				subtitle(Thrifty Food Plan) name(thrifty, replace)
				
				
				graph	twoway	(kdensity	fs_scale_fam_reverse)	(kdensity	rho1_avg_foodexp_pc_thrifty_ls)
				
				
			foreach	type	in	fs	{
				gen		valid_result_`type'	=	.
				replace	valid_result_`type'	=	1	if	inrange(year,9,10)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp==1
				replace	valid_result_`type'	=	2	if	inrange(year,9,10)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp!=1
				replace	valid_result_`type'	=	3	if	inrange(year,9,10)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp==1
				replace	valid_result_`type'	=	4	if	inrange(year,9,10)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp!=1
				label	var	valid_result_`type'	"Validation Result, `type'"
			}
			
	
		*	Validation Plot 
			*	USDA
					
					*	All sample
					tab	valid_result_USDA	if	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==4, msymbol(square)),	///
									xline(1)	yline(1)	xtitle(USDA measure 2015)	ytitle(USDA Fmeasure 2017)	///
									title(Food Security in 2015 vs Food Security in 2017)	name(USDA_all, replace)	///
									legend(lab (1 "Classified as food secure(76%)") lab(2 "Mis-Classified as food secure(6%)") lab(3 "Mis-Classified as food insecure(8%)")	lab(4 "Classified as food insecure(11%)")	rows(2))	///
									subtitle(Threshold determined by HFSSM)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_USDA_all.png", replace
					graph	close
					
					*	SEO, Immigrants (low incomde households)
					tab	valid_result_USDA	if	inlist(sample_source,2,3)	&	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_rf==1	&	inlist(sample_source,2,3), msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_rf==2	&	inlist(sample_source,2,3), msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_rf==3	&	inlist(sample_source,2,3), msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_rf==4	&	inlist(sample_source,2,3), msymbol(square)),	///
									xline(1)	yline(1)	xtitle(USDA measure 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(USDA_lowinc, replace)	///
									legend(lab (1 "Classified as food secure(57%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(12%)")	lab(4 "Classified as food insecure(23%)")	rows(2))	///
									subtitle(Threshold determined by HFSSM Low income HH)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_USDA_lowinc.png", replace
					graph	close
				
				*	OLS
					
					*	All sample
					tab	valid_result_ols	if	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==4, msymbol(square)),	///
									xline(`thresval_ols')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017) name(OLS_all, replace)	///
									legend(lab (1 "Classified as food secure(73%)") lab(2 "Mis-Classified as food secure(8%)") lab(3 "Mis-Classified as food insecure(11%)")	lab(4 "Classified as food insecure(9%)")	rows(2))	///
									subtitle(Threshold determined by OLS)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_OLS_all.png", replace
					graph	close
					
					*	SEO, Immigrants (low incomde households)
					tab	valid_result_ols	if	inlist(sample_source,2,3)	&	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==1	&	inlist(sample_source,2,3), msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==2	&	inlist(sample_source,2,3), msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==3	&	inlist(sample_source,2,3), msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==4	&	inlist(sample_source,2,3), msymbol(square)),	///
									xline(`thresval_ols')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017) name(OLS_lowinc, replace)	///
									legend(lab (1 "Classified as food secure(49%)") lab(2 "Mis-Classified as food secure(14%)") lab(3 "Mis-Classified as food insecure(19%)")	lab(4 "Classified as food insecure(17%)")	rows(2))	///
									subtitle(Threshold determined by OLS Low income HH)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_OLS_lowinc.png", replace
					graph	close
					
				*	LASSO
					
					*	All sample
					tab	valid_result_ls	if	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==4, msymbol(square)),	///
									xline(`thresval_ls')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(LASSO_all, replace)	///
									legend(lab (1 "Classified as food secure(73%)") lab(2 "Mis-Classified as food secure(8%)") lab(3 "Mis-Classified as food insecure(11%)")	lab(4 "Classified as food insecure(8%)")	rows(2))	///
									subtitle(Threshold determined by LASSO)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_LASSO_all.png", replace
					graph	close
					
					*	SEO, Immigrants (low incomde households)
					tab	valid_result_ls	if	inlist(sample_source,2,3)	&	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==1	&	inlist(sample_source,2,3), msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==2	&	inlist(sample_source,2,3), msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==3	&	inlist(sample_source,2,3), msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==4	&	inlist(sample_source,2,3), msymbol(square)),	///
									xline(`thresval_ls')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(LASSO_lowinc, replace)	///
									legend(lab (1 "Classified as food secure(47%)") lab(2 "Mis-Classified as food secure(14%)") lab(3 "Mis-Classified as food insecure(22%)")	lab(4 "Classified as food insecure(16%)")	rows(2))	///
									subtitle(Threshold determined by LASSO Low income HH)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_LASSO_lowinc.png", replace
					graph	close
				
				*	Random Forest
					
					*	All sample
					tab	valid_result_rf	if	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==4, msymbol(square)),	///
									xline(`thresval_rf')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(RF_all, replace)	///
									legend(lab (1 "Classified as food secure(72%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(11%)")	lab(4 "Classified as food insecure(7%)")	rows(2))	///
									subtitle(Threshold determined by RF)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_RF_all.png", replace
					graph	close
					
					*	SEO, Immigrants (low incomde households)
					tab	valid_result_rf	if	inlist(sample_source,2,3)	&	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==1	&	inlist(sample_source,2,3), msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==2	&	inlist(sample_source,2,3), msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==3	&	inlist(sample_source,2,3), msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==4	&	inlist(sample_source,2,3), msymbol(square)),	///
									xline(`thresval_rf')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(RF_lowinc, replace)	///
									legend(lab (1 "Classified as food secure(49%)") lab(2 "Mis-Classified as food secure(15%)") lab(3 "Mis-Classified as food insecure(20%)")	lab(4 "Classified as food insecure(16%)")	rows(2))	///
									subtitle(Threshold determined by RF Low income HH)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_RF_lowinc.png", replace
					graph	close

					
					
		* Predicative Accuracy Plot
		
				
		
			*	Predictive Power Plot		
			sort	fam_ID_1999	year
				*	USDA
					
					*	All sample
					tab	valid_result_USDA	if	inrange(year,10,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==4, msymbol(square)),	///
									xline(1)	yline(1)	xtitle(USDA scale in 2015)	ytitle(USDA scale in 2017)	///
									title(Validation of Food Security Status Prediction)	name(USDA_all, replace)	///
									legend(lab (1 "Classified as food secure") lab(2 "Mis-Classified as food secure") lab(3 "Mis-Classified as food insecure")	lab(4 "Classified as food insecure")	rows(2))	///
									subtitle(USDA Measure)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_USDA_all.png", replace
					graph	close
					
				
				*	GLM
			
					*	All sample
					tab	valid_result_ols	if	inrange(year,10,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==4, msymbol(square)),	///
									xline(${thresval_ols})	yline(1)	xtitle(PFS in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Prediction of Food Security in 2017) name(GLM_all, replace)	///
									legend(lab (1 "Classified as food secure(72%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(12%)")	lab(4 "Classified as food insecure(7%)")	rows(2))	///
									subtitle(PFS)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_GLM_all.png", replace
					graph	close
					
					
				*	LASSO
					
					*	All sample
					tab	valid_result_ls	if	inrange(year,10,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==4, msymbol(square)),	///
									xline(${thresval_ls})	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(LASSO_all, replace)	///
									legend(lab (1 "Classified as food secure(72%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(12%)")	lab(4 "Classified as food insecure(7%)")	rows(2))	///
									subtitle(PFS by LASSO)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_LASSO_all.png", replace
					graph	close
					
				
				*	Random Forest
					
					*	All sample
					tab	valid_result_rf	if	inrange(year,10,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==4, msymbol(square)),	///
									xline(${thresval_rf})	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(RF_all, replace)	///
									legend(lab (1 "Classified as food secure(72%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(11%)")	lab(4 "Classified as food insecure(7%)")	rows(2))	///
									subtitle(PFS by RF)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_RF_all.png", replace
					graph	close
					

			 grc1leg2		USDA_all	GLM_all	/*LASSO_all	RF_all*/,	legendfrom(USDA_all)	 /*xtob1title*/	ytol1title 	maintotoptitle ///
			 note("Sample include households survey responses in 2017")
			 
			graph	export	"${PSID_outRaw}/Predictive_Power_Plot.png", replace
			graph	close
		

	
	*	Association by year
	if	`by_year'==1	{
	
		local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	HH_female	ib1.race_head_cat	marital_status_cat
		local	econvars	ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	num_FU_fam ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ ib2.grade_comp_cat	
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	/*child_meal_assist	elderly_meal*/ WIC_received_last	
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	ib0.state_resid_fam	
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.age_over65	///
								c.HH_female#c.age_over65	///
								c.ln_income_pc#c.HH_female#c.age_over65	///
								c.no_longer_married#c.HH_female
		local	timevars	i.year
		
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		margins, dydx(HH_female)
				
	
	

			forvalues	year=2/10	{
				
				local	depvar		rho1_foodexp_pc_thrifty_ols
				svy, subpop(year_enum`year'): reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	// if	year==`year'
				*svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year', family(gamma)	link(log)
				estadd scalar N = e(N_sub), replace
				est store CB_cont_year`year'
				
			}
			
			*	Display output
			esttab	CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10	///
			using "${PSID_outRaw}/CB_cont_years.csv", ///
			cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
			
			esttab	CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10	///
			using "${PSID_outRaw}/CB_cont_years.tex", ///
			cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
			
			
			coefplot CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10, vertical keep(c.age_head_fam#c.age_head_fam) drop(_cons)	///
			legend(lab (2 "2001") lab(4 "2003") lab(6 "2005"))
		
	}
					
	
	*	Association
	local	model_check	0	//	varying LHS
	if	`model_check'==1	{
*	Check the association among the factors in the two indicators (USDA, RS)
	
	/*
	*	Take log of income & expenditure variables
	foreach	moneyvars	in	food_exp_pc	income_pc	{
		gen	ln_`moneyvars'	=	log(`moneyvars')
	}
	gen		ln_income_pc_sq	=	(ln_income_pc)^2
	label	var	ln_food_exp_pc	"ln(food expenditure per capita)"
	label	var	ln_income_pc	"ln(income per capita)"
	label	var	ln_income_pc_sq	"ln(income per capita) squared"
	*/
	
	local	depvar		fs_scale_fam_rescale
	local	healthvars	phys_disab_head
	local	demovars	age_head_fam	age_head_fam_sq	ib1.race_head_cat	marital_status_cat	ib1.gender_head_fam	
	local	econvars	c.income_pc	c.income_pc_sq	/*wealth_pc	wealth_pc_sq*/
	local	empvars		emp_HH_simple
	local	familyvars	c.num_FU_fam c.num_child_fam	/*ib0.family_comp_change	ib5.couple_status*/
	local	eduvars		/*attend_college_head*/ ib1.grade_comp_cat	
	local	foodvars	food_stamp_used_1yr	WIC_received_last
	local	regionvars	ib0.state_resid_fam	
	*local	changevars	no_longer_employed	no_longer_married	no_longer_own_house
	
	summ	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars' /*if in_sample==1 & year==10*/
	
	cap	drop	pre_recession post_recession
	gen		pre_recession	=	0
	replace	pre_recession	=	1	if	inrange(year,1,5)	//	Wave 1999 to 2007
	gen		post_recession	=	0
	replace	post_recession	=	1	if	inrange(year,6,10)	//	Wave 2009 to 2017
			
	*** Note: Stata recommends using "subpop" option instead of "if" option, as the variance estimator from the latter "does  not  accurately  measurethe  sample-to-sample  variability  of  the  subpopulation  estimates  for  the  survey  design  that  was  used to collect the data."
	*** However, for some reason Stata does often not allow to use "subpop" option with "glm" command, so I will use "if" option for now.
	
	
	*	USDA (rescaled, continuous)
			
		*	Pooled
		local	depvar		fs_scale_fam_rescale
			
			*	OLS
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est	store	USDA_cont_pooled_OLS
			
			*	GLS
			svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars',	///
						family(gamma)	link(log)
			est	store	USDA_cont_pooled_GLS
		
					
		*	By Pre- and Post- Great Recession
		svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
								i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
		est	store	USDA_cont_prepost
		contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
		
		
		*	By Year
		foreach	year	in	1	2	3	9	10	{
			
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
			*svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year', family(gamma)	link(log)	
			est	store	USDA_cont_year`year'
			
		}

	*	CB score (thrift, continuous)
	
		*	Pooled
		local	depvar		rho1_foodexp_pc_thrifty_ols
		
			*	OLS
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est store CB_cont_pooled_OLS
			
			*	GLS
			svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars', family(gamma)	link(log)
			est store CB_cont_pooled_GLS
		
		*	By Pre- and Post- Great Recession
		svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
								i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
		est	store	CB_cont_prepost
		contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
		mat	CB_cont_prepost_pval=r(p)'
		
		*	By year
		forvalues	year=2/10	{
			
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
			*svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year', family(gamma)	link(log)
			est store CB_cont_year`year'
			
		}
	

	*	USDA (simplified category, binary)
	local	depvar		fs_cat_fam_simp
		
		* LPM (GLM using binominal family distribution & logit link function gives identical results to logit regression. Could check theoretically later why.)
			
			*	Pooled
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est	store	USDA_bin_LPM_pooled
			
			*	By Pre- and Post- Great Recession
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
									i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
			est	store	USDA_bin_LPM_prepost
			contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
			mat	USDA_bin_prepost_pval=r(p)'
			
			*	By year
			foreach	year	in	1	2	3	9	10	{
			
				svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
				est	store	USDA_bin_LPM_year`year'
			
			}
		
		*	Logit
			
			*	Pooled
			svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est store 	USDA_bin_logit_pooled	
			
			*	By Pre- and Post- Great Recession
			svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
									i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
			est	store	USDA_bin_logit_prepost
			*contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
			*mat	USDA_bin_prepost_pval=r(p)'
			
			*	By year
			foreach	year	in	1	2	3	9	10	{
				
				svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
				est store 	USDA_bin_logit_year`year'
				
			}
		
	
	*	CB (binary category)
	local	depvar		rho1_thrifty_FS_ols
	
		* LPM
			
			*	Pooled
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est	store	CB_bin_LPM_pooled
		
			*	By Pre- and Post- Great Recession
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
									i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
			est	store	CB_bin_LPM_prepost
			*contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
			*mat	CB_bin_LPM_prepost_pval=r(p)'
			
			*	By year
			foreach	year	in	2	3	4	5	6	7	8	9	10	{
			
				svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
				est	store	CB_bin_LPM_year`year'
			
			}
			
		* Logit
			
			*	Pooled
			svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est	store	CB_bin_logit_pooled
			
			*	By Pre- and Post- Great Recession
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
									i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
			est	store	CB_bin_logit_prepost
			*contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
			*mat	CB_bin_logit_prepost_pval=r(p)'
		
			*	By year
			foreach	year	in	2	3	4	5	6	7	8	9	10	{
			
				svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
				est	store	CB_bin_logit_year`year'
			
			}
		
		
	*	Output 
	
		*	Pooled
		esttab	USDA_cont_pooled_OLS	CB_cont_pooled_OLS	USDA_cont_pooled_GLS	CB_cont_pooled_GLS	///
				USDA_bin_LPM_pooled CB_bin_LPM_pooled	USDA_bin_logit_pooled	CB_bin_logit_pooled	using "${PSID_outRaw}/USDA_CB_pooled.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Food Security Status-Pooled) replace
				
		*	By Year
		
			*	USDA (continuous)
				
				*	Default
				esttab	USDA_cont_year1	USDA_cont_year2	USDA_cont_year3	USDA_cont_year9	USDA_cont_year10		using "${PSID_outRaw}/USDA_cont_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA Scale Score-continuous) replace
				
				*	Pre- and Post- Great Recession
				esttab	USDA_cont_prepost		using "${PSID_outRaw}/USDA_cont_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA Scale Score-continuous) replace
				
				*	No star for significance
				esttab	USDA_cont_year1	USDA_cont_year2	USDA_cont_year3	USDA_cont_year9	USDA_cont_year10		using "${PSID_outRaw}/USDA_cont_years_nostar.csv", ///
				cells(b(fmt(a3))) /*stats(N r2)*/ label legend nobaselevels drop(_cons)	title(USDA Scale Score-continuous) replace
				
			
			*	CB (continuous)
				
				*	Default
				esttab	CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10	///
				using "${PSID_outRaw}/CB_cont_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
				
				*	Pre- and Post- Recession
				esttab	CB_cont_prepost		using "${PSID_outRaw}/CB_cont_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
				
				*	No-star
				esttab	CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10	///
				using "${PSID_outRaw}/CB_cont_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
				
			*	USDA (binary-LPM)
				
				*	Default
				esttab	USDA_bin_LPM_year1	USDA_bin_LPM_year2	USDA_bin_LPM_year3	USDA_bin_LPM_year9	USDA_bin_LPM_year10		using "${PSID_outRaw}/USDA_bin_LPM_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	Pre- and Post-
				esttab	USDA_bin_LPM_prepost		using "${PSID_outRaw}/USDA_bin_LPM_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	No-star
				esttab	USDA_bin_LPM_year1	USDA_bin_LPM_year2	USDA_bin_LPM_year3	USDA_bin_LPM_year9	USDA_bin_LPM_year10		using "${PSID_outRaw}/USDA_bin_LPM_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				
			*	USDA (binary-logit)
				
				*	Default
				esttab	USDA_bin_logit_year1	USDA_bin_logit_year2	USDA_bin_logit_year3	USDA_bin_logit_year9	USDA_bin_logit_year10	///
				using "${PSID_outRaw}/USDA_bin_logit_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-Logit) replace
				
				*	Pre- and Post-
				esttab	USDA_bin_logit_prepost		using "${PSID_outRaw}/USDA_bin_logit_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	No-star
				esttab	USDA_bin_logit_year1	USDA_bin_logit_year2	USDA_bin_logit_year3	USDA_bin_logit_year9	USDA_bin_logit_year10	///
				using "${PSID_outRaw}/USDA_bin_logit_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
			
			*	CB (binary-LPM)
				
				*	Default
				esttab	CB_bin_LPM_year2	CB_bin_LPM_year3	CB_bin_LPM_year4	CB_bin_LPM_year5	CB_bin_LPM_year6	///
						CB_bin_LPM_year7	CB_bin_LPM_year8	CB_bin_LPM_year9	CB_bin_LPM_year10	///
				using "${PSID_outRaw}/CB_bin_LPM_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB FS Status-LPM) replace
				
				*	Pre- and Post-
				esttab	CB_bin_LPM_prepost		using "${PSID_outRaw}/CB_bin_LPM_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	No star
				esttab	CB_bin_LPM_year2	CB_bin_LPM_year3	CB_bin_LPM_year4	CB_bin_LPM_year5	CB_bin_LPM_year6	///
						CB_bin_LPM_year7	CB_bin_LPM_year8	CB_bin_LPM_year9	CB_bin_LPM_year10	///
				using "${PSID_outRaw}/CB_bin_LPM_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(CB FS Status-LPM) replace
				
			*	CB (binary-logit)
				
				*	Default
				esttab	CB_bin_logit_year2	CB_bin_logit_year3	CB_bin_logit_year4	CB_bin_logit_year5	CB_bin_logit_year6	///
						CB_bin_logit_year7	CB_bin_logit_year8	CB_bin_logit_year9	CB_bin_logit_year10	///
				using "${PSID_outRaw}/CB_bin_logit_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB FS Status-Logit) replace
				
				*	Pre- and Post-
				esttab	CB_bin_logit_prepost		using "${PSID_outRaw}/CB_bin_logit_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	No star
				esttab	CB_bin_logit_year2	CB_bin_logit_year3	CB_bin_logit_year4	CB_bin_logit_year5	CB_bin_logit_year6	///
						CB_bin_logit_year7	CB_bin_logit_year8	CB_bin_logit_year9	CB_bin_logit_year10	///
				using "${PSID_outRaw}/CB_bin_logit_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(CB FS Status-Logit) replace
				
			
			
					
	*	Graphs
	
	
		*	Effect of non-employment
		
			*	fam_ID_1999==33 (No longer employed in 2009) 
			twoway	function y=gammaden(7.842407,0.6806434,0,x), range(0 10)	lpattern(solid)	||	///	//	2007 (pre-loss)
					function y=gammaden(5.639921,0.7594346,0,x), range(0 10)	lpattern(dash)	||	///	//	2009 (job-loss)
					function y=gammaden(7.422701,0.4153742,0,x), range(0 10)	lpattern(dot)	||	///	//	2011 (2 years after job-loss)
					function y=gammaden(7.672119,0.3827603,0,x), range(0 10)	lpattern(dashdot)	||	///	//	2013 (4 years after job-loss)
					function y=gammaden(8.372554,0.487376,0,x), range(0 10)		lpattern(shortdash)		///	//	2015 (6 years after job-loss)
					legend(lab (1 "2007(6.24)") lab(2 "2009(3.64)") lab(3 "2011(2.34)") lab(4 "2013(4.16)") lab(5 "2015(5.2)"))	///
					title(The Effect of Job-Loss on PFS PDF)	subtitle(Job Loss in 2009)	///
					xtitle(food expenditure per capita (thousands))	///
					note(Female-headed household. Job loss in 2009 but re-employed since 2011.)
			graph	export	"${PSID_outRaw}/effect_of_job_loss_on_CB_pdf.png", replace
			graph	close
			
			
		*	Effect of non-married
			
			*	fam_ID_1999=3496 (no longer married in 2007)
			twoway	function y=gammaden(7.061182,0.530853,0,x), range(0 10)	lpattern(solid)	||	///	//	2007 (pre-chock)
					function y=gammaden(8.30407,0.6948747,0,x), range(0 10)	lpattern(dash)	||	///	//	2009 (marriage-shock)
					function y=gammaden(7.236261,0.4517315,0,x), range(0 10)	lpattern(dot)	||	///	//	2011 (2 years after marriage-shock)
					function y=gammaden(4.702001,0.8223391,0,x), range(0 10)	lpattern(dashdot)	||	///	//	2013 (4 years after marriage-shock)
					function y=gammaden(9.6309,0.6496494,0,x), range(0 10)		lpattern(shortdash)		///	//	2015 (6 years after marriage-shock)
					legend(lab (1 "2005(3.21)") lab(2 "2007(4.68)") lab(3 "2009(2.6)") lab(4 "2011(2.6)") lab(5 "2013(5.2)"))	///
					title(The Effect of Marriage Shock on PFS PDF)	subtitle(Marriage shock in 2007)	///
					xtitle(food expenditure per capita (thousands))	///
					note(Male-headed household. No longer married in 2007 and remained since then.)
			graph	export	"${PSID_outRaw}/effect_of_marriage_shock_on_CB_pdf.png", replace
			graph	close

		
		*	Time trend of CB score by year & sample group.
		
			cap	drop	year2
			gen year2 = (year*2)+1997
			
			tsset	fam_ID_1999 year2, delta(2)
			
			*	Ratio of food insecure household (PFS)
			cap	drop	avg_cb_weighted
			cap	drop	avg_cb_weighted_sample
			cap	drop	HH_FS_ratio_PSID
			gen	double avg_cb_weighted=.
			gen	double avg_cb_weighted_sample=.
			gen	double HH_FS_ratio_PSID=.
			forval	year=1999(2)2017	{
				
				* PFS
				if	`year'!=1999	{	
					
					* By year
					qui	svy: mean rho1_foodexp_pc_thrifty_ols if year2==`year'	
					replace	avg_cb_weighted=e(b)[1,1]	if	year2==`year'
					
					* PFS, by year & sample
					forval	sampleno=1/3	{
						quietly	svy: mean rho1_foodexp_pc_thrifty_ols 		if year2==`year'	&	sample_source==`sampleno'
						replace	avg_cb_weighted_sample=e(b)[1,1]	if	year2==`year'	&	sample_source==`sampleno'
					}
				}
				
				* PSID, by year
				if	inlist(`year',1999,2001,2003,2015,2017)	{
					qui	svy:	mean	fs_cat_fam_simp	if year2==`year'	
					replace	HH_FS_ratio_PSID=e(b)[1,1]	if	year2==`year'
				}
			}
			
			*	Ratio of food insecure households (USDA report)
			cap	drop	HH_FS_ratio_USDA
			gen		HH_FS_ratio_USDA	=	(1-0.101)	if	year2==	1999
			replace	HH_FS_ratio_USDA	=	(1-0.107)	if	year2==	2001
			replace	HH_FS_ratio_USDA	=	(1-0.112)	if	year2==	2003
			replace	HH_FS_ratio_USDA	=	(1-0.110)	if	year2==	2005
			replace	HH_FS_ratio_USDA	=	(1-0.111)	if	year2==	2007
			replace	HH_FS_ratio_USDA	=	(1-0.147)	if	year2==	2009
			replace	HH_FS_ratio_USDA	=	(1-0.149)	if	year2==	2011
			replace	HH_FS_ratio_USDA	=	(1-0.143)	if	year2==	2013
			replace	HH_FS_ratio_USDA	=	(1-0.127)	if	year2==	2015
			replace	HH_FS_ratio_USDA	=	(1-0.118)	if	year2==	2017
			lab	var	HH_FS_ratio_USDA	"Ratio of FS households"
			
			
			tsset	fam_ID_1999 year2, delta(2)
			
			sort	fam_ID_1999 year2
			twoway	(connected	HH_FS_ratio_USDA	year2	in	1/10,	yaxis(1) lpattern(solid))	///
					(connected	HH_FS_ratio_PSID	year2	in	1/10,	yaxis(1) lpattern(dot))	///
					(connected	avg_cb_weighted	year2	in	1/10,	yaxis(1) lpattern(dash)),	///
					legend(lab (1 "USDA") lab(2 "PSID") lab(3 "PFS") rows(1))	///
					title(Ratio of being food secure)	subtitle(from 1999 to 2017)
			graph	export	"${PSID_outRaw}/Food_Secure_by_data.png", replace
			graph	close


			tsset	fam_ID_1999	year
			keep	if	fam_ID_1999==1
			drop	if	mi(rho1_foodexp_pc_thrifty_ols)
			
			dfuller	rho1_foodexp_pc_thrifty_ols
			dfgls	rho1_foodexp_pc_thrifty_ols, maxlag(4)
			
			
			
			*	Marginal Effect	
					
					
					*	Income
						
						*	By income group
						est	restore	Prob_FI_interact
						margins,	dydx(c.ln_income_pc)	over(income_to_poverty_cat)
						marginsplot, title(Semi-elasticity of PFS w.r.t. income with 95% CI) xtitle(Income-to-Poverty Ratio)	///
										note(1% change in income increases PFS by y-var percentage point)
						graph	export	"${PSID_outRaw}/ME_income_bygroup.png", replace
						graph	close
						
						*	By income group, around poverty threshold
						cap	drop	income_to_poverty_lowtail
						gen	income_to_poverty_lowtail=.	if	!inrange(income_to_poverty,0,3)
						forval	i=0.2(0.2)3.0	{
							
							local	minval	=	`i'-0.2
							local	maxval	=	`i'
							replace	income_to_poverty_lowtail	=	`maxval'*100	if	inrange(income_to_poverty,`minval',`maxval')
						}
						est	restore	Prob_FI_interact
						margins,	dydx(c.ln_income_pc)	over(income_to_poverty_lowtail)
						marginsplot, title(Marginal Effect of Income on PFS) xtitle(Income to Poverty Ratio(%))	ytitle(PFS(percentage point))	///
										note("Income to Poverty Ratio is calculated by dividing total annual income into Federal Poverty Line" "Change in PFS with respect to 1% increase in per capita income")
						graph	export	"${PSID_outRaw}/ME_income_lowtail.png", replace
						graph	close
			
						*	By year
						forvalues	year=2001(2)2017	{						
							est	restore	Prob_FI_interact
							margins,	dydx(c.ln_income_pc)	subpop(if year2==`year')	over(income_to_poverty_lowtail) post
							est store SE_`year'
							marginsplot,	title(Semi-elasticity of PFS over income in `year')
							graph	export	"${PSID_outRaw}/ME_income_lowtail_`year'.png", replace
							graph	close	
							
						}
						coefplot (SE_2001, msymbol(circle)) (SE_2007, msymbol(diamond))	(SE_2011, msymbol(square))	(SE_2017, msymbol(triangle)), noci	lwidth(*1) connect(l) vertical	///
						xlabel(1 "20" 2 "40"	3	"60"	4	"80"	5	"100"	6	"120"	7	"140"	8	"160"	9	"180"	10	"200"	11	"220"	12	"240"	13	"260"	14	"280")	///
						note("Income to Poverty Ratio is calculated by dividing total annual income into Federal Poverty Line" "Change in PFS with respect to 1% increase in per capita income")	///
						legend(lab (1 "2001") lab(2 "2007") lab (3 "2011") lab(4 "2017")	rows(1))	///
						xtitle (Income to Poverty Ratio(%))	ytitle(PFS(percentage point))	title (Marginal Effect of Income on PFS)	
						graph	export	"${PSID_outRaw}/ME_income_lowtail_byyear.png", replace
						graph	close
						
					*	Elasticity over (thrifty) food plan
					
						*	No control, by year
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	/*c.age_head_fam##c.age_head_fam		ln_income_pc */
						margins, eyex(foodexp_W_thrifty) over(year2) post
						est	store	eyex_foodplan_nocon_year
						marginsplot, title(Elasticity of PFS over thrifty food plan by year)
						
						*	Control (age, income), by year
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	c.age_head_fam##c.age_head_fam		ln_income_pc
						margins, eyex(foodexp_W_thrifty) over(year2) post
						est	store	eyex_foodplan_con_year
						marginsplot, title(Elasticity of PFS over thrifty food plan by year)
						
						*	Graph
						coefplot eyex_foodplan_nocon_year	eyex_foodplan_con_year, lwidth(*1) connect(l) vertical	xlabel(1(1)9)	///
							xtitle (Survey Wave)	ytitle(PFS)	title (Elasticity of PFS over Food Plan by year)	///
							legend(lab (2 "No controls") lab(4 "Controls") rows(1))	///
							note(Controls include age and income)
						graph	export	"${PSID_outRaw}/Elasticity_over_foodplan_year.png", replace
						graph	close
						
						*	No control, by income group
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	/*c.age_head_fam##c.age_head_fam		ln_income_pc */
						margins, eyex(foodexp_W_thrifty) over(income_to_poverty_cat) post
						est	store	eyex_foodplan_nocon_IPR
						marginsplot, title(Elasticity of PFS over thrifty food plan by IPR)
						
						*	Control (age, income), by income group
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	c.age_head_fam##c.age_head_fam		ln_income_pc
						margins, eyex(foodexp_W_thrifty) over(income_to_poverty_cat) post
						est	store	eyex_foodplan_con_IPR
						marginsplot, title(Elasticity of PFS over thrifty food plan by IPR)
						
						*	Graph
						coefplot eyex_foodplan_nocon_IPR	eyex_foodplan_con_IPR, lwidth(*1) connect(l) vertical	xlabel(1(1)11)	///
							xtitle (Income to Poverty Ratio)	ytitle(PFS)	title (Elasticity of PFS over Food Plan by IPR)	///
							legend(lab (2 "No controls") lab(4 "Controls") rows(1))	///
							note(Controls include age and income)
						graph	export	"${PSID_outRaw}/Elasticity_over_foodplan_IPR.png", replace
						graph	close
						
						*	No control, low income group
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	/*c.age_head_fam##c.age_head_fam		ln_income_pc */
						margins, eyex(foodexp_W_thrifty) over(income_to_poverty_lowtail) post
						est	store	eyex_foodplan_nocon_IPRlow
						marginsplot, title(Elasticity of PFS over thrifty food plan by IPR)
						
						*	Control (age, income), low income group
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	c.age_head_fam##c.age_head_fam		ln_income_pc
						margins, eyex(foodexp_W_thrifty) over(income_to_poverty_lowtail) post
						est	store	eyex_foodplan_con_IPRlow
						marginsplot, title(Elasticity of PFS over thrifty food plan by IPR)
						
						*	Graph
						coefplot eyex_foodplan_nocon_IPRlow	eyex_foodplan_con_IPRlow, lwidth(*1) connect(l) vertical	xlabel(0(5)30)	///
							xtitle (Income to Poverty Ratio*10)	ytitle(PFS)	title (Elasticity of PFS over Food Plan by IPR)	///
							legend(lab (1 "No controls") lab(2 "Controls") rows(1))	noci	xline(10)	///
							note(Controls include age and income)
						graph	export	"${PSID_outRaw}/Elasticity_over_foodplan_IPRlow.png", replace
						graph	close
					
					/*
					*	Overall (AME)
					est	restore	Prob_FI_interact
					local	nonlinear_terms	c.age_head_fam	HH_female	c.ln_income_pc	c.age_over65	c.no_longer_married
					eststo	ME_overall: margins,	dydx(`nonlinear_terms'	)	post	//	age, gender and ln(income). Income will be semi-elasticity
					est	restore	Prob_FI_interact
					eststo	ME_overall_atmeans: margins,	dydx(`nonlinear_terms')	atmeans post	//	age, gender and ln(income). Income will be semi-elasticity
					esttab	ME_overall	ME_overall_atmeans	using "${PSID_outRaw}/ME_overall.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels /*drop(_cons)*/	title(Marginal Effect_overall) replace
						
					est	restore	Prob_FI_interact	
					eststo	ME_AME2:	margins,	expression((1/exp(ln_income_pc))*(_b[ln_income_pc]+_b[c.ln_income_pc#c.HH_female]*HH_female+_b[c.ln_income_pc#c.age_over65]*age_over65)+_b[c.ln_income_pc#c.HH_female#c.age_over65]*HH_female*age_over65)	post	//	1st-derivative w.r.t. per capita income
					
					*/
					
					*	Prediction
					est	restore	Prob_FI_interact
					predict fv,xb
					
						*	Over the age, using the deviation from the life expectancy
						cap	drop	dev_from_lifeexp
						gen		dev_from_lifeexp=.
						forvalues	year=1999(2)2017	{
							replace	dev_from_lifeexp	=	age_head_fam-life_exp_male_`year'	if	HH_female==0	&	year2==`year'
							replace	dev_from_lifeexp	=	age_head_fam-life_exp_female_`year'	if	HH_female==1	&	year2==`year'
						}
						label	variable	dev_from_lifeexp	"Deviation from the life expectancy by year and gender"
						
						twoway	(lpolyci fv dev_from_lifeexp	if	HH_female==0)	///
								(lpolyci fv dev_from_lifeexp	if	HH_female==1),	///
								title(Predicted PFS over the age)	note(Life Expectancy are 73.9(male) and 79.4(female) in 1999 and 76.1(male) and 81.1(female) in 2017) ///
								legend(lab (2 "Male") lab(3 "Female") rows(1))	xtitle(Deviation from the Life Expectancy)
						graph	export	"${PSID_outRaw}/Fitted_age_pooled.png", replace
						graph	close
					
						*	By each year in a single graph
						twoway	(lpoly fv dev_from_lifeexp if year2==1999)	(lpoly fv dev_from_lifeexp if year2==2005)	///
								(lpoly fv dev_from_lifeexp if year2==2011)	(lpoly fv dev_from_lifeexp if year2==2017),	///
								legend(lab (1 "1999") lab(2 "2005") lab(3 "2011") lab(4 "2017") rows(1))	///
								xtitle(Deviation from the Life Expectancy)	ytitle(Predicted PFS)	title(Predicted PFS over Life)
						graph	export	"${PSID_outRaw}/Fitted_age_byyear.png", replace
						graph	close
						
								
						*	W.R.T. average retirement age
							
							*	Average retirement age by year
							forval	year=1999(2)2017	{
								summarize	retire_age	if	retire_year_head==`year'
								*svy, subpop(year_enum`year'): mean retire_age // if	retire_year_head==`year'
							}

							
							*	1999							
							summ	retire_age	if	retire_year_head==1999	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==1),	xline(`r(mean)')	xtitle(Age)	legend(lab (2 "PFS"))	title(1999)	name(fv_age_retire_1999, replace)
							
							*	2007
							summ	retire_age	if	retire_year_head==2005	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==4),	xline(`r(mean)')	xtitle(Age) legend(lab (2 "PFS"))	title(2005)	name(fv_age_retire_2005, replace)
							
							*	2013
							summ	retire_age	if	retire_year_head==2011	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==7),	xline(`r(mean)')	xtitle(Age) legend(lab (2 "PFS"))	title(2011)	name(fv_age_retire_2011, replace)
							
							*	2017
							summ	retire_age	if	retire_year_head==2017	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==10),	xline(`r(mean)')	xtitle(Age) legend(lab (2 "PFS"))	title(2017)	name(fv_age_retire_2017, replace)
							
							grc1leg2		fv_age_retire_1999	fv_age_retire_2005	fv_age_retire_2011	fv_age_retire_2017,	title(Predicted PFS over age) legendfrom(fv_age_retire_1999)	///
											note(Vertical line is the average retirement age of the year in the sample)	xtob1title
							graph	export	"${PSID_outRaw}/Fitted_age_retirement.png", replace
							graph	close
							
							
	

				
					
					twoway qfitci fv income_pc, title(Expected PFS over income)
					twoway qfitci fv age_head_fam, title(Expected PFS over age)
													
					twoway lpolyci fv income_pc if income_pc>0, title(Expected PFS over income)
					twoway lpolyci fv age_head_fam	if	HH_female==1, title(Expected PFS over age)
					twoway lpolyci fv age_head_fam	if	HH_female==0, title(Expected PFS over age)
					
					graph	twoway	(scatter rho1_foodexp_pc_thrifty_ols income_pc if income_pc>0)		///
									(lpolyci fv income_pc if income_pc>0, title(Expected PFS over income))
					
					
						*	By year
						cap	drop	year2
						gen year2 = (year*2)+1997
						
						forval	year=1999(2)2017	{
							qui	twoway lpolyci fv income_pc if income_pc>0	&	year2==`year', title(Expected PFS over income in `year')
							graph	export	"${PSID_outRaw}/Fitted_lpoly_income_`year'.png", replace
							graph	close	
							
							qui	twoway lpolyci fv age_head_fam if year2==`year', title(Expected PFS over age in `year')
							graph	export	"${PSID_outRaw}/Fitted_lpoly_age_`year'.png", replace
							graph	close
						}
						
						*	In a single graph
						twoway	(lpoly fv income_pc if income_pc>0	&	year2==1999	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2001	&	income_pc<100)	///
								(lpoly fv income_pc if income_pc>0	&	year2==2003	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2005	&	income_pc<100)	///
								(lpoly fv income_pc if income_pc>0	&	year2==2007	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2009	&	income_pc<100)	///
								(lpoly fv income_pc if income_pc>0	&	year2==2011	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2013	&	income_pc<100)	///
								(lpoly fv income_pc if income_pc>0	&	year2==2015	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2017	&	income_pc<100),	///
								legend(lab (1 "1999") lab(2 "2001") lab(3 "2003") lab(4 "2005") lab(5 "2007") lab(6 "2009") lab(7 "2011") lab(8 "2013") lab(9 "2015") lab(10 "2017") rows(2))	///
								title(Predicted PFS over income)	xtitle(Per capita income (thousands))
						graph	export	"${PSID_outRaw}/Fitted_lpoly_income_all_year.png", replace
						graph	close
						
						twoway	(lpoly fv age_head_fam if year2==1999)	(lpoly fv age_head_fam if year2==2001)	///
								(lpoly fv age_head_fam if year2==2003)	(lpoly fv age_head_fam if year2==2005)	///
								(lpoly fv age_head_fam if year2==2007)	(lpoly fv age_head_fam if year2==2009)	///
								(lpoly fv age_head_fam if year2==2011)	(lpoly fv age_head_fam if year2==2013)	///
								(lpoly fv age_head_fam if year2==2015)	(lpoly fv age_head_fam if year2==2017),	///
								legend(lab (1 "1999") lab(2 "2001") lab(3 "2003") lab(4 "2005") lab(5 "2007") lab(6 "2009") lab(7 "2011") lab(8 "2013") lab(9 "2015") lab(10 "2017") rows(2))	///
								title(Expected PFS over age by year)
						graph	export	"${PSID_outRaw}/Fitted_lpoly_age_all_year.png", replace
						graph	close
		
					*	Compute the marginal effect of some covariates over the range of values.
					*margins, dydx(age_head_fam) over(age_head_fam)
					*marginsplot, title(Marginal Effect of Age with 95% CI)
					
					cap	drop	income_pc_cat
					gen	income_pc_cat=0	if	income_pc<0
					forvalues	i=0(10)150	{
						local	income_min=`i'
						local	income_max=(`i'+10)
						replace	income_pc_cat	=	`i'	if	inrange(income_pc,`income_min',`income_max')
					}
					
					*margins, dydx(income_pc) over(income_pc_cat)
					*marginsplot, title(Marginal Effect of per capita income with 95% CI) xtitle(per capita income group)
				
			*/	
			

** Old version of Jalan & Ravallion Table
/*
	*	FS_Chronic_Transient	
	if	`run_FS_chron_trans'==1	{
		
		*cap	drop	pfs_ols_normal
		cap	drop	SFIG
		cap	drop	PFS_ols_mean
		cap	drop	PFS_ols_total
		cap	drop	PFS_threshold_ols_total
		cap	drop	PFS_ols_mean_normal
		cap	drop	PFS_threshold_ols_mean
		cap	drop	PFS_ols_normal_mean
		cap	drop	SFIG_mean_indiv
		cap	drop	SFIG_mean
		cap	drop	SFIG_transient
		cap	drop	SFIG_deviation
		cap	drop	Total_FI
		cap	drop	Transient_FI
		cap	drop	Chronic_FI
		*gen pfs_ols_normal	=.
		
		
		
		
		foreach	type	in	ols	/*ls	rf*/	{
				
				*gen	pfs_`type'_mean_normal=.
				*gen	SFIG_mean_indiv=.
				
				
				*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at household-level.
				*	Since households have different number of non-missing PFS and our cut-off probability varies over time, we cannot simply use "mean" function.
				*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
				
				*	Aggregate PFS over time (numerator)
				bys	fam_ID_1999:	egen	PFS_`type'_total	=	total(rho1_foodexp_pc_thrifty_ols)	if	inrange(year,2,10)
				
				*	Aggregate cut-off PFS over time. To add only the years with non-missing PFS, we replace the cut-off PFS of missing PFS years as missing.
				replace	PFS_threshold_`type'=.	if	mi(rho1_foodexp_pc_thrifty_`type')
				bys	fam_ID_1999:	egen	PFS_threshold_`type'_total	=	total(PFS_threshold_`type')	if	inrange(year,2,10)
				
				*	Generate (normalized) mean-PFS by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
				gen	PFS_`type'_mean_normal	=	PFS_`type'_total	/	PFS_threshold_`type'_total
				
					
				*	Total, Transient and Chronic FI

				
					*	Total FI	(Average SFIG over time)
					bys	fam_ID_1999:	egen	Total_FI	=	mean(SFIG_indiv)			if	inrange(year,2,10)	/*!mi(SFIG_indiv)*/	//	SFIG

					*	Chronic FI (SFIG(with mean PFS))					
					gen		Chronic_FI.
					replace	Chronic_FI	=	(1-PFS_`type'_mean_normal)^2	if	!mi(PFS_`type'_mean_normal)	&	PFS_`type'_mean_normal<1	//	Avg PFS < Avg cut-off PFS
					replace	Chronic_FI	=	0								if	!mi(PFS_`type'_mean_normal)	&	PFS_`type'_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
					
					**** In several households, CFI is greater than TFI. I assume it is because the threshold probability varies, but need to thoroughly check why.
					**** For now, in that case we treat CFI as equal to the TFI
					replace	Chronic_FI	=	Total_FI	if	Chronic_FI>Total_FI
					
					*	Transient FI (TFI - CFI)
					gen	Transient_FI	=	Total_FI	-	Chronic_FI
							
				
				/*
				*	Mean PFS over time. It will be the input argument for the Chronic Poverty.
				bys	fam_ID_1999: egen	pfs_`type'_mean	=	mean(rho1_foodexp_pc_thrifty_`type')	if	!mi(rho1_foodexp_pc_thrifty_`type')
				
				
				*	First loop
				local	num_years	=	0
				global	PFS_threshold_total=0
				
				forval	year=2/10	{		
							
					
					global	PFS_threshold_total	=	${PFS_threshold_total}	+	${PFS_threshold_`year'}	//	To calculate mean cut-off threshold${PFS_threshold_`year'}
					
					di "threshold of year `year' is ${PFS_threshold_`year'}"
					local	num_years	=	`num_years'+1
					
					/*
					*	Set threshold PFS value for year, which is the average of the maximum PFS of FI households and the minimum PFS of the FS households
					qui	summ	rho1_foodexp_pc_thrifty_`type'	if	rho1_thrifty_FS_`type'==0	&	year==`year'	//	Maximum PFS of households categorized as food insecure
					local	max_pfs_thrifty_`type'_`year'	=	r(max)
					qui	summ	rho1_foodexp_pc_thrifty_`type'	if	rho1_thrifty_FS_`type'==1	&	year==`year'	//	Minimum PFS of households categorized as food secure
					local	min_pfs_thrifty_`type'_`year'	=	r(min)

					global	thresval_`type'_`year'	=	(`max_pfs_thrifty_`type'_`year''	+	`min_pfs_thrifty_`type'_`year'')/2	//	Average of the two scores above is a threshold value.
					global	thresval_`type'_total	=	${thresval_`type'_total}	+	${thresval_`type'_`year'}	//	To calculate mean cut-off threshold
					
					
					*	Normalized PFS (PFS/threshold PFS)	(yit)
					replace	pfs_`type'_normal	=	rho1_foodexp_pc_thrifty_`type'	/	${thresval_`type'_`year'}	if	year==`year'
					
					*	Squared Food Insecurity Gap (SFIG) at each year
					replace	SFIG_indiv	=	(1-pfs_`type'_normal)^2	if	year==`year'	&	!mi(pfs_`type'_normal)	&	rho1_foodexp_pc_thrifty_`type'<${thresval_`type'_`year'}	
					replace	SFIG_indiv	=	0						if	year==`year'	&	!mi(pfs_`type'_normal)	&	rho1_foodexp_pc_thrifty_`type'>=${thresval_`type'_`year'}
					
					
					di "threshold of year `year' is ${thresval_`type'_`year'}"
					local	num_years	=	`num_years'+1
					*/
					
					/*	Outdated code
					*	Normalized Mean PFS
					replace	pfs_`type'_mean_normal	=	pfs_`type'_mean	/	${thresval_`type'_`year'}	if	year==`year'
								
					*	Squared Food Insecurity Gap (SFIG) at each year using Mean PFS
					replace	SFIG_mean_indiv	=	(1-pfs_`type'_mean_normal)^2	if	year==`year'	&	!mi(pfs_`type'_mean_normal)	&	pfs_`type'_mean<${thresval_`type'_`year'}
					replace	SFIG_mean_indiv	=	0								if	year==`year'	&	!mi(pfs_`type'_mean_normal)	&	pfs_`type'_mean>=${thresval_`type'_`year'}
					*/
					
					
				}	//	year
				
				global	PFS_threshold_mean	=	${PFS_threshold_total} / `num_years'
				di "Total threshold is ${PFS_threshold_total}, num_years is `num_years' and mean threshold is ${PFS_threshold_mean}"
				
				
				** This code is wrong. We should get the average PFS first and then normalize it, NOT the other way around (Calvo and Dercon, 2007)
				*	Household-level mean of normalized PFS over time (yi_bar)
				** The difference between "normalized mean PFS" below is that, this one normalize first and then gets them mean, so household i has the same value across time.
				*bys	fam_ID_1999:	egen	pfs_`type'_normal_mean	=	mean(pfs_`type'_normal)
				
				
				
				*	Calculate mean Food Insecurity threshold over time.
				/*	Jalan and Ravallion (2000) used a fixed poverty line across all years, while our cut-off probability line is year-specific.
					Thus we use the mean of those cut-off probabilities as a fixed threshold to categorize households	*/
					
				
				*	Second loop to get mean of normalized PFS over time
				forval	year=2/10	{	
							
					*	Squared Food Insecurity Gap (SFIG) at each year using Mean normalized PFS
					replace	SFIG_mean_indiv	=	(1-pfs_`type'_normal_mean)^2	if	year==`year'	&	!mi(pfs_`type'_normal_mean)	&	pfs_`type'_mean<${PFS_threshold_`year'}
					replace	SFIG_mean_indiv	=	0								if	year==`year'	&	!mi(pfs_`type'_normal_mean)	&	pfs_`type'_mean>=${PFS_threshold_`year'}
					
				}	
				
				
				*	Total, Transient and Chronic FI
				
					*	Total FI
					bys	fam_ID_1999: egen	Total_FI		=	mean(SFIG_indiv)		if	!mi(SFIG_indiv)
					
					*	Transient FI (time mean of SFIG deviation from its mean)
					gen	SFIG_deviation	=	SFIG_indiv	-	SFIG_mean_indiv	//	fluct
					bys	fam_ID_1999:	egen	Transient_FI	=	mean(SFIG_deviation)
					
					*	Chronic FI (Total FI - Transient FI)
					gen	Chronic_FI	=	Total_FI	-	Transient_FI
				
				/*
				bys	fam_ID_1999: egen	SFIG		=	mean(SFIG_indiv)		if	!mi(SFIG_indiv)	//	Overall FI
				bys	fam_ID_1999: egen	SFIG_mean	=	mean(SFIG_mean_indiv)	if	!mi(SFIG_mean_indiv)	//	Chronic FI
				gen	SFIG_transient	=	SFIG	-	SFIG_mean
				*/
				
			*/
			
			}	//	type
		
		
			*	Restrict sample to non_missing TFI and CFI
			global	nonmissing_TFI_CFI	!mi(Total_FI)	&	!mi(Chronic_FI)
		
		*	Descriptive stats
			
			**	For now we include households with 5+ PFS.
			cap	drop	num_nonmissing_PFS
			cap	drop	dyn_sample
			bys fam_ID_1999: egen num_nonmissing_PFS=count(rho1_foodexp_pc_thrifty_ols)
			gen	dyn_sample=1	if	num_nonmissing_PFS>=5	&	inrange(year,2,10)
			
			*	For time-variance categories (ex. education, region), we use the first year (2001) value (as John suggested)
			local	timevar_cat	highdegree_NoHS highdegree_HS highdegree_somecol highdegree_col	///
								state_group_NE state_group_MidAt state_group_South state_group_MidWest state_group_West	resid_metro resid_nonmetro
			foreach	type	of	local	timevar_cat		{
				
				gen		`type'_temp	=	1	if	year==2	&	`type'==1
				replace	`type'_temp	=	0	if	year==2	&	`type'!=1	&	!mi(`type')
				replace	`type'_temp	=	.n	if	year==2	&	mi(`type')
				
				cap	drop	`type'_2001
				bys	fam_ID_1999:	egen	`type'_2001	=	max(`type'_temp)
				drop	`type'_temp
				
			}				
			
			*	If 2001 education is missing, use the earliest available education information
			cap	drop	tempyear
			bys fam_ID_1999: egen tempyear = min(year) if (${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1 & mi(highdegree_NoHS_2001))

			foreach edu in NoHS HS somecol col	{
				
				cap	drop	highdegree_`edu'_2001_temp?
				gen	highdegree_`edu'_2001_temp1	=	highdegree_`edu'	if	year==tempyear
				bys fam_ID_1999: egen highdegree_`edu'_2001_temp2	=	max(highdegree_`edu'_2001_temp1) if !mi(tempyear)
				replace	highdegree_`edu'_2001	=	highdegree_`edu'_2001_temp2	if	!mi(tempyear)
				drop	highdegree_`edu'_2001_temp?
			}
			drop	tempyear


			*	Generate statistics for tables
			
			*	Overall			
			svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	& ${nonmissing_TFI_CFI} 	&	dyn_sample==1 ): mean Total_FI Chronic_FI Transient_FI	
			scalar	prop_trans_all	=	e(b)[1,2]/e(b)[1,1]
			*scalar	samplesize_all	=	e(N_sub)
			mat	Jalan_Rav_2000_all	=	e(N_sub),	e(b), prop_trans_all
			
			*	Gender
			svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	gender_head_fam_enum2==1): mean Total_FI Chronic_FI Transient_FI  	
			scalar	prop_trans_male	=	e(b)[1,2]/e(b)[1,1]
			mat	Jalan_Rav_2000_male	=	e(N_sub),	e(b), prop_trans_male
			
			svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1 	&	HH_female==1): mean Total_FI Chronic_FI Transient_FI  	
			scalar	prop_trans_female	=	e(b)[1,2]/e(b)[1,1]
			mat	Jalan_Rav_2000_female	=	e(N_sub),	e(b), prop_trans_female
			
			mat	Jalan_Rav_2000_gender	=	Jalan_Rav_2000_male	\	Jalan_Rav_2000_female
			
			*	Race
			foreach	type	in	1	0	{
				
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	HH_race_white==`type'): mean Total_FI Chronic_FI Transient_FI 
				scalar	prop_trans_race_`type'	=	e(b)[1,2]/e(b)[1,1]
				mat	Jalan_Rav_2000_race_`type'	=	e(N_sub),	e(b), prop_trans_race_`type'
				
			}
			
			mat	Jalan_Rav_2000_race	=	Jalan_Rav_2000_race_1	\	Jalan_Rav_2000_race_0

			*	Region (based on John's suggestion)
			foreach	type	in	NE	MidAt South MidWest West	{
				
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	state_group_`type'==1	): mean Total_FI Chronic_FI Transient_FI 
				scalar	prop_trans_region_`type'	=	e(b)[1,2]/e(b)[1,1]
				mat	Jalan_Rav_2000_region_`type'	=	e(N_sub),	e(b), prop_trans_region_`type'
				
			}
		
			mat	Jalan_Rav_2000_region	=	Jalan_Rav_2000_region_NE	\	Jalan_Rav_2000_region_MidAt	\	Jalan_Rav_2000_region_South	\	///
											Jalan_Rav_2000_region_MidWest	\	Jalan_Rav_2000_region_West
			
			*	Metropolitan Area
			foreach	type	in	metro	nonmetro	{
				
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	resid_`type'==1): mean Total_FI Chronic_FI Transient_FI 
				scalar	prop_trans_metro_`type'	=	e(b)[1,2]/e(b)[1,1]
				mat	Jalan_Rav_2000_metro_`type'	=	e(N_sub),	e(b), prop_trans_metro_`type'
				
			}
		
			mat	Jalan_Rav_2000_metro	=	Jalan_Rav_2000_metro_metro	\	Jalan_Rav_2000_metro_nonmetro
			
			*	Education degree (Based on 2001 degree)
			foreach	degree	in	NoHS	HS	somecol	col	{
				
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	highdegree_`degree'_2001==1): mean Total_FI Chronic_FI Transient_FI 
				scalar	prop_trans_edu_`degree'	=	e(b)[1,2]/e(b)[1,1]
				mat	Jalan_Rav_2000_edu_`degree'	=	e(N_sub),	e(b), prop_trans_edu_`degree'
				
			}
			
			mat	Jalan_Rav_2000_edu	=	Jalan_Rav_2000_edu_NoHS	\	Jalan_Rav_2000_edu_HS	\	Jalan_Rav_2000_edu_somecol	\	Jalan_Rav_2000_edu_col

			
			 *	Further decomposition
		   cap	mat	drop	Jalan_Rav_2000_decomp
		   cap	mat	drop	Pop_ratio
		   svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1): mean Total_FI Chronic_FI Transient_FI 
		   local	subsample_tot=e(N_subpop)		   
		   
		   foreach	race	in	 HH_race_color	HH_race_white	{	//	Black, white
				foreach	gender	in	HH_female	gender_head_fam_enum2	{	//	Female, male
					foreach	edu	in	NoHS	HS	somecol	col   	{	//	No HS, HS, some col, col
						svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1  & `gender'==1 & `race'==1 & highdegree_`edu'_2001==1): mean Total_FI Chronic_FI Transient_FI
						local	Pop_ratio	=	e(N_subpop)/`subsample_tot'
						scalar	prop_trans_edu_race_gender	=	e(b)[1,2]/e(b)[1,1]
						mat	Jalan_Rav_2000_decomp	=	nullmat(Jalan_Rav_2000_decomp)	\	`Pop_ratio',	e(b), prop_trans_edu_race_gender
					}	// edu			
				}	//	gender	
		   }	//	race

			
			*	Combine results (Table 8 of 2020/11/16 draft)
			mat	define	blankrow	=	J(1,5,.)
			mat	Jalan_Rav_2000_allcat	=	Jalan_Rav_2000_all	\	blankrow	\	Jalan_Rav_2000_gender	\	blankrow	\	Jalan_Rav_2000_race	\	///
											blankrow	\	Jalan_Rav_2000_region	\	blankrow	\	Jalan_Rav_2000_metro	\	blankrow \	///
											Jalan_Rav_2000_edu	//	To be combined with category later.
			mat	Jalan_Rav_2000_combined	=	Jalan_Rav_2000_allcat	\	blankrow	\	blankrow	\	Jalan_Rav_2000_decomp

			putexcel	set "${PSID_outRaw}/Jalan_Rav", sheet(2by2) replace	/*modify*/
			putexcel	A3	=	matrix(Jalan_Rav_2000_combined), names overwritefmt nformat(number_d1)
			
			esttab matrix(Jalan_Rav_2000_combined, fmt(%9.3f)) using "${PSID_outRaw}/Jalan_Rav_combined.tex", replace	
			
			
			*	Categorize HH into four categories
				
				*	Generate mean PFS and mean threshold PFS over time.
				*	Since each household has different years of PFS available, this becomes household-specific
				*	(it would be the same for the households with the same years of the PFS available)
				cap	drop	PFS_ols_mean PFS_threshold_ols_mean
				bys	fam_ID_1999:	egen	PFS_ols_mean	=	mean(rho1_foodexp_pc_thrifty_ols)	if	inrange(year,2,10)	// Intertemporal mean PFS
				bys	fam_ID_1999:	egen	PFS_threshold_ols_mean	=	mean(PFS_threshold_ols)		if	inrange(year,2,10)	// Intertemporal mean threshold PFS
				
				/*
				*	HH PFS is below mean PFS cut-off
				loc	var	PFS_belowmean_ols
				cap	drop	`var1'
				gen		`var1'	=	0
				replace	`var1'	=	1	if	rho1_foodexp_pc_thrifty_ols<${thresval_ols_mean}
				replace	`var1'	=	.	if	mi(rho1_foodexp_pc_thrifty_ols)
				*/
				
				*	Dummy whether (1) always or not-always FI (2) Never or sometimes FI
				loc	var1	PFS_FI_always_ols
				loc	var2	PFS_FI_never_ols
				cap	drop	`var1'
				cap	drop	`var2'
				bys	fam_ID_1999:	egen	`var1'	=	min(rho1_thrifty_FI_ols)	//	1 if always below (persistently poor), 0 if sometimes below (not persistently poor)
				bys	fam_ID_1999:	egen	`var2'	=	min(rho1_thrifty_FS_ols)	//	1 if never poor, 0 if sometimes poor (transient)
				
				
				* HH's mean PFS is below mean PFS cut-off
				loc	var	PFSmean_belowmean_ols
				cap	drop	`var'
				gen		`var'	=	0	if	PFS_ols_mean>PFS_threshold_ols_mean
				replace	`var'	=	1	if	PFS_ols_mean<=PFS_threshold_ols_mean
				replace	`var'	=	.	if	mi(PFS_ols_mean)

				
				*	Categorize households
				cap	drop	PFS_perm_FI
				gen		PFS_perm_FI=1	if	PFS_FI_always_ols==1	//	Persistently poor
				replace	PFS_perm_FI=2	if	PFS_FI_always_ols==0	&	PFSmean_belowmean_ols==1	//	Mean PFS is below mean cut-off, but not always poor
				replace	PFS_perm_FI=3	if	PFS_FI_always_ols==0	&	PFSmean_belowmean_ols==0	//	Mean PFS is above mean cut-off, but sometimes poor
				replace	PFS_perm_FI=4	if	PFS_FI_never_ols==1		//	Never poor
				*replace	PFS_perm_FI=.	if	dyn_sample!=1	//	Treat as missing if not balanced.
				
				label	define	PFS_perm_FI	1	"Persistently poor"	///
											2	"Chronically, but not persistently poor"	///
											3	"Transiently poor"	///
											4	"Never poor"	///
											,	replace
				label values	PFS_perm_FI	PFS_perm_FI
				
			*	Descriptive stats
			
				*	Overall
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): proportion	PFS_perm_FI
				mat	PFS_perm_FI_all	=	e(N_sub),	e(b)
				
				*	Gender
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	gender_head_fam_enum2): proportion PFS_perm_FI
				mat	PFS_perm_FI_male	=	e(N_sub),	e(b)
				svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_female): proportion PFS_perm_FI
				mat	PFS_perm_FI_female	=	e(N_sub),	e(b)
				
				mat	PFS_perm_FI_gender	=	PFS_perm_FI_male	\	PFS_perm_FI_female
				
			
				*	Race
				foreach	type	in	1	0	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_race_white==`type'): proportion PFS_perm_FI
					mat	PFS_perm_FI_race_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_race	=	PFS_perm_FI_race_1	\	PFS_perm_FI_race_0
				
				*	Region
				foreach	type	in	NE	MidAt	South	MidWest West	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1): proportion PFS_perm_FI
					mat	PFS_perm_FI_region_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_region	=	PFS_perm_FI_region_NE	\	PFS_perm_FI_region_MidAt	\	PFS_perm_FI_region_South	\	///
											PFS_perm_FI_region_MidWest	\	PFS_perm_FI_region_West
				
				*	Metropolitan
				foreach	type	in	metro	nonmetro	{
					
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	resid_`type'==1): proportion PFS_perm_FI
					mat	PFS_perm_FI_metro_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_metro	=	PFS_perm_FI_metro_metro	\	PFS_perm_FI_metro_nonmetro
				
				
				*	Education
				foreach	degree	in	NoHS	HS	somecol	col	{
				    
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	highdegree_`degree'_2001==1): proportion PFS_perm_FI
					mat	PFS_perm_FI_edu_`degree'	=	e(N_sub),	e(b)
					
				}
				mat	PFS_perm_FI_edu	=	PFS_perm_FI_edu_NoHS	\	PFS_perm_FI_edu_HS	\	PFS_perm_FI_edu_somecol	\	PFS_perm_FI_edu_col
				

				*	Combine results (Table 9 of 2020/11/16 draft)
				mat	define	blankrow	=	J(1,5,.)
				mat	PFS_perm_FI_combined	=	PFS_perm_FI_all	\	blankrow	\	PFS_perm_FI_gender	\	blankrow	\	PFS_perm_FI_race	\	blankrow	\	///
												PFS_perm_FI_region	\	blankrow	\	PFS_perm_FI_metro	\	blankrow	\	PFS_perm_FI_edu
				
				mat	list	PFS_perm_FI_combined
				
				putexcel	set "${PSID_outRaw}/Jalan_Rav", sheet(FI_perm) /*replace*/	modify
				putexcel	A3	=	matrix(PFS_perm_FI_combined), names overwritefmt nformat(number_d1)
			
				esttab matrix(PFS_perm_FI_combined, fmt(%9.2f)) using "${PSID_outRaw}/PFS_perm_FI.tex", replace	
				
				*	Table 5 & 6 (combined) of Dec 20 draft
				mat	define Table_5	=	Jalan_Rav_2000_allcat,	PFS_perm_FI_combined[.,2...]
				
				putexcel	set "${PSID_outRaw}/Jalan_Rav", sheet(Table5) /*replace*/	modify
				putexcel	A3	=	matrix(Table_5), names overwritefmt nformat(number_d1)
			
				esttab matrix(Table_5, fmt(%9.3f)) using "${PSID_outRaw}/Table_5.tex", replace	
		
		*	Group State-FE of TFI and CFI
		local	demovars	age_head_fam age_head_fam_sq	HH_female	HH_race_color	/*HH_race_black HH_race_other*/	marital_status_cat
		local	econvars	ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	num_FU_fam ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ highdegree_NoHS highdegree_somecol highdegree_col	
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_group?	state_group1?	state_group2?	//	excluding NY (state_bgroup) as reference state group.
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.age_over65	///
								c.HH_female#c.age_over65	///
								c.ln_income_pc#c.HH_female#c.age_over65	///
								c.no_longer_married#c.HH_female
		local	timevars	year_enum3-year_enum10
		
			*	Regression of TFI/CFI on Group state FE
			
			foreach	depvar	in	Total_FI	Chronic_FI	Transient_FI	{
				
				/*
				*	Without controls/time FE
				qui	svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' `regionvars'
				est	store	`depvar'_nocontrols
				*/
				
				*	With controls/time FE
				qui	svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' 	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`shockvars'	`regionvars'	`timevars'
				est	store	`depvar'
			}
			
			*	Output
			esttab	Total_FI	Chronic_FI	Transient_FI	using "${PSID_outRaw}/TFI_CFI_regression.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Regression of TFI/CFI on Characteristics) 	///
					addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
					replace
					
			esttab	Total_FI	Chronic_FI		using "${PSID_outRaw}/TFI_CFI_regression.tex", ///
					cells(b(star fmt(a3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Regression of TFI/CFI on Characteristics) 	///
					addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
					replace		
			
			
			local	shapley_decomposition=1
			*	Shapley Decomposition
			if	`shapley_decomposition'==1	{
				
				ds	state_group?	state_group1?	state_group2?
				local groupstates `r(varlist)'
				
				
				foreach	depvar	in	Total_FI	Chronic_FI	{
					
					*	Unadjusted
					cap	drop	_mysample
					regress `depvar' 	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`shockvars'	`regionvars'	`timevars'	 if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head no_longer_employed	no_longer_married	no_longer_own_house	became_disabled) 
					
					mat	`depvar'_shapley_indiv	=	e(shapley),	e(shapley_rel)
					mata : st_matrix("`depvar'_shapley_sum", colsum(st_matrix("`depvar'_shapley_indiv")))
					
					mat	`depvar'_shapley	=	`depvar'_shapley_indiv	\	`depvar'_shapley_sum
					
					
					*	Survey-adjusted
					cap	drop	_mysample
					svy, subpop(if ${study_sample} &	!mi(rho1_foodexp_pc_thrifty_ols)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar'  	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`shockvars'	`regionvars'	`timevars'		
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head no_longer_employed	no_longer_married	no_longer_own_house	became_disabled)
				
				}	//	depvar			
			}	//	shapley
			
			mat	TFI_CFI_shapley	=	Total_FI_shapley,	Chronic_FI_shapley
			
			putexcel	set "${PSID_outRaw}/Jalan_Rav", sheet(shapley) /*replace*/	modify
			putexcel	A3	=	matrix(TFI_CFI_shapley), names overwritefmt nformat(number_d1)
			
			esttab matrix(TFI_CFI_shapley, fmt(%9.3f)) using "${PSID_outRaw}/TFI_CFI_shapley.tex", replace	
		
			*	Northeast & Mid-Atlantic
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group1	state_group2	state_group3	state_group4	state_group5)	xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(Northeast and Mid-Atlantic)	name(TFI_CFI_FE_NE_MA, replace) /*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_NE.png", replace
				graph	close

			/*
			*	Mid-Atlantic
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group2	state_group3	state_group4	state_group5)	xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(TFI_CFI_Mid_Atlantic)	name(TFI_CFI_FE_MA, replace)	xscale(range(-0.05(0.05) 0.10))
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_MA.png", replace
				graph	close
			*/
			
			*	South
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group6 state_group7 state_group8 state_group9 state_group10 state_group11)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(South)	name(TFI_CFI_FE_South, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_South.png", replace
				graph	close
				
			*	Mid-West
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group12 state_group13 state_group14 state_group15 state_group16 state_group17)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(Mid-West)	name(TFI_CFI_FE_MW, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_MW.png", replace
				graph	close
			
			*	West
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group18 state_group19 state_group20 state_group21)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(West)		name(TFI_CFI_FE_West, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_West.png", replace
				graph	close
	
		/*
			graph combine	TFI_CFI_FE_NE_MA	TFI_CFI_FE_South	TFI_CFI_FE_MW	TFI_CFI_FE_West, title(Region Fixed Effects)
			graph	export	"${PSID_outRaw}/TFI_CFI_region_FE.png", replace
			graph	close
		*/
		
	
		
		grc1leg2		TFI_CFI_FE_NE_MA	TFI_CFI_FE_South	TFI_CFI_FE_MW	TFI_CFI_FE_West,	///
											title(Region Fixed Effects) legendfrom(TFI_CFI_FE_NE_MA)	///
											graphregion(color(white))	/*xtob1title	*/
											/*	note(Vertical line is the average retirement age of the year in the sample)	*/
							graph	export	"${PSID_outRaw}/TFI_CFI_region_FE.png", replace
							graph	close
		
		
		
		coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(Regional Fixed Effects)		name(TFI_CFI_FE_All, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_All.png", replace
				graph	close
			
		/*
		preserve
			keep	fam_ID_1999	/*weight_multi12	newsecu*/	sample_source	SFIG	SFIG_mean	SFIG_transient
			duplicates drop
			drop	if	mi(SFIG)
			*	Summary stats (unweighted)
			summ	SFIG	SFIG_mean	SFIG_transient	//	All
			bys	sample_source: summ	SFIG	SFIG_mean	SFIG_transient	//	By sample
		restore
		*/
		
	}
	
*/
	
	

