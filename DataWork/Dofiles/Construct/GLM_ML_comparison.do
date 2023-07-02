
	/*****************************************************************
	PROJECT: 		Food Security Dynamics in the United States, 2001-2017
					
	TITLE:			GLM_ML_comparison.do
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	2023/07/01, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	fam_ID_1999 // Personal Identification Number

	DESCRIPTION: 	Compares model performance across GLM, LASSO and Random Forest
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - GLM with Gamma distribution
					2 - LASSO
					3 - Random Forest
					X - Save and Exit
					
	INPUTS: 		*	Long format data with additional cleaning (PFS not needed).
					${FSD_dtInt}/FSD_long_beforePFS.dta
					
					
	OUTPUTS: 		* MSPE under Cross-validation LASSO
					${FSD_OutFig}/cvlasso_result.png
					
					
					* Feature Importance under random forest
					${FSD_outFig}/rf_feature_importance_step1.png //	Figure
					${FSD_outTab}/Feature_importance.xlsx	//	Table

	NOTE:			*** THIS DO-FILE TAKES A LONG TIME TO RUN ***
	
					*	Assess model performance among GLM, LASSO and Random Forest
					*	Before constructing PFS, we need to decide which model to use for constructing PFS
					*	We make decision based on the out-of-sample prediction performance of equation (1) - constructing conditional mean
					*	Performance will be measured by root mean square prediction error (RMSPE), using 2001-2015 as training sample, and 2017 as out-of-sample
					
					**	This measurement needs not be run every time, thus we toggle it only when needed.
					**	As of Sep 2021, LASSO(1.78) and random forest (1.82) does not perform significantly better than GLM(1.83)
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
	*loc	name_do	PSID_const_ind
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	*cd	"${PSID_doCon}"
	*stgit9
	*di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	*di "Git branch `r(branch)'; commit `r(sha)'."
	
	use	"${FSD_dtInt}/FSD_long_beforePFS.dta", clear
	
	/****************************************************************
		SECTION 1: GLM with Gamma distribution
	****************************************************************/
			
	sort	fam_ID_1999 year
	
	*	Declare variables
	local	depvar		food_exp_stamp_pc
	
	*	Step 1
	*	Exclude year 10 (to calculate RMPSE)
	svy, subpop(if ${study_sample} & year!=10): glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}, family(gamma)	link(log)
	est	sto	glm_step1
	

	*	Predict fitted value and residual
	gen		glm_step1_sample=1	if	e(sample)==1 & sample_source_SRC_SEO & year!=10	
	replace	glm_step1_sample=1	if	year==10 & l.glm_step1_sample==1
	count if glm_step1_sample==1 & year==10	//	Number of 2017 observations used to measure performance
	scalar step1_N_glm=r(N)
	
	predict double mean1_foodexp_glm	if	glm_step1_sample==1
	predict double e1_foodexp_glm		if	glm_step1_sample==1,r
	gen e1_foodexp_sq_glm = (e1_foodexp_glm)^2
	
	egen e1_total_glm=total(e1_foodexp_sq_glm) if glm_step1_sample==1 & year==10
	gen rmspe_step1_glm = sqrt(e1_total_glm/step1_N_glm)	//

	summ	rmspe_step1_glm	//	1.83

	/****************************************************************
		SECTION 2: LASSO
	****************************************************************/	
	
	*	Features to be tested
	*	To increase predictive power, we include the variables not only those originally included in GLM, but also other variables.

	local	depvar	food_exp_stamp_pc
	
	local	statevars	lag_food_exp_stamp_pc_1-lag_food_exp_stamp_pc_5		//	up to the order of 5
	local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse	mental_problem
	local	demovars	age_head_fam age_head_fam_sq	HH_race_white HH_race_color	marital_status_cat	///
						HH_female age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
	local	econvars	ln_income_pc	ln_wealth_pc		sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
	local	empvars		emp_HH_simple	emp_spouse_simple
	local	familyvars	num_FU_fam ratio_child	child_in_FU_cat	couple_status_enum1-couple_status_enum4
	local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse					
	local	foodvars	food_stamp_used_0yr food_stamp_used_1yr	child_meal_assist WIC_received_last		elderly_meal
	local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
	local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
	local	regionvars	state_group? state_group1? state_group2?
	local	timevars	year_enum2-year_enum9
	

	
	*	Select optimal lambda
	*	We choose optimal lambda by doing cross-validation, but it takes too much time. Thus we run it only when needed
	
	**	Note: "cvlasso" using training data (2001-2015) gives lse-optimal lambda=45467.265, which does penalize "ALL" variables except those we intentionally didn't penalize (time and state FE). It gives RMPSE=2.600
	**	Thus, we manually tested all the values from 50 to 50000, with increment 100. We found lambda=50 minimuzes MSPE (lopt) and the largest lambda within 1-stdev is lambda=11,800	

		
		numlist "50000(50)1", descending
		
		*	Finding optimal lambda using cross-validation (computationally intensive)
		cvlasso	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'		`healthvars'	`familyvars'	`eduvars'	`eduvars'	`foodvars'	`childvars'	`regionvars'	`timevars'		if	${study_sample}==1 & year!=10,	///
			/*lopt lse*/  lambda(`r(numlist)')	seed(${seed})	notpen(`regionvars'	`timevars')	 rolling	/*h(1) fe	prestd 	postres	ols*/	plotcv 
			
		est	store	lasso_step1_lse
		cvlasso, postresult lse
		
		*	Display lambda result
		di "lambda is `e(lambda)'"
		assert	e(lambda)==11800	//	Confirm that this value is 11,800
		
		*	Save plot
		graph	export	"${FSD_outFig}/cvlasso_result.png", replace
		graph	close
		

		
		*	Run lasso with the optimal lambda value	
		
		local	lambdaval=11800

		lasso2	`depvar'	`statevars'		`demovars'	`econvars'	`healthvars'	`empvars'		`familyvars'	`eduvars'	`foodvars'	///
								`changevars'	`regionvars'	`timevars'	`childvars'	if	${study_sample}==1 & year!=10,	///
					ols lambda(`lambdaval') notpen(`regionvars'	`timevars')
		est	store	lasso_step1_manual
		lasso2, postresults
			
	*	Manually run post-lasso
		gen		lasso_step1_sample=1	if	e(sample)==1	& year!=10
						
		global selected_step1_lasso `e(selected)'	/*`e(notpen)'*/
		svy:	reg `depvar' ${selected_step1_lasso}	`e(notpen)'	if	lasso_step1_sample==1
		est store postlasso_step1_lse
		
		sort	fam_ID_1999	year
		replace	lasso_step1_sample=1 if year==10 & l.lasso_step1_sample==1 // This command should run "after" running post-LASSO, since we don't want 2017 to be included in post-LASSO when validating performance
		count if lasso_step1_sample==1 & year==10	//	Number of 2017 observations used to measure performance
		scalar step1_N_lasso=r(N)
		
		*	Predict conditional means and variance from Post-LASSO
		predict double mean1_foodexp_lasso	if	lasso_step1_sample==1, xb	
		predict double e1_foodexp_lasso	if	lasso_step1_sample==1,r	
		gen e1_foodexp_sq_lasso = (e1_foodexp_lasso)^2

		egen e1_total_lasso=total(e1_foodexp_sq_lasso) if lasso_step1_sample==1 & year==10
		gen rmspe_step1_lasso = sqrt(e1_total_lasso/step1_N_lasso)
		
		summ	rmspe_step1_lasso // 1.78


	/****************************************************************
		SECTION 3: Random Forest
	****************************************************************/			
		
			
		*	Features to be tested
		*	To increase predictive power, we include the variables not only those originally included in GLM, but also other variables.
		
		local	depvar		food_exp_stamp_pc

		local	statevars	lag_food_exp_stamp_pc_1	//	RF allows non-linearity, thus need not include higher polynomial terms
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse	mental_problem
		local	demovars	age_head_fam HH_race_white HH_race_color	marital_status_cat	HH_female	age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	child_in_FU_cat	couple_status_enum1-couple_status_enum4
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
		local	foodvars	food_stamp_used_0yr food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_group? state_group1? state_group2?
		local	timevars	year_enum2-year_enum9


		*	Tune how large the value of iterations() need to be

			loc	depvar	food_exp_pc
			generate out_of_bag_error1 = .
			generate validation_error = .
			generate iter1 = .
			local j = 0
			forvalues i = 10(5)500 {
				local j = `j' + 1
				rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	year!=10	&	${study_sample}==1, type(reg)	seed(20200505) iterations(`i') numvars(1)
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
		
		*	50 seems to be optimal (as of Sep 12, 2021)

		
			
		*	Tune the number of variables

			loc	depvar	food_exp_pc
			generate oob_error = .
			generate nvars = .
			generate val_error = .
			local j = 0
			forvalues i = 1(1)26 {
				local j = `j'+ 1
				rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
											`foodvars'	`childvars'	`changevars'	`regionvars'	if	year!=10	&	${study_sample}==1,	///
											type(reg)	seed(${seed}) iterations(50) numvars(`i')
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
			* (2021-09-12) (valication without 2017) Minimum Error: 1.808252334594727; Corresponding number of variables 17'
		
		
		*	Run random forest
			cap	drop	rf_step1_sample
			cap	drop	importance_mean
			cap	drop	importance_mean1
			
			loc	depvar	food_exp_pc
			rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	year!=10 & 	${study_sample}==1,	///
									type(reg)	iterations(50)	numvars(17)	seed(${seed}) 
			gen		rf_step1_sample=1	if		${study_sample}==1 // For Random Forest, ALL observations are used.
			count	if	rf_step1_sample==1	&	year==10
			scalar step1_N_rf=r(N)
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
			graph	export	"${FSD_outFig}/rf_feature_importance_step1.png", replace
			graph	close
			
			putexcel	set "${FSD_outTab}/Feature_importance", sheet(mean) replace	/*modify*/
			putexcel	A3	=	matrix(importance_mean), names overwritefmt nformat(number_d1)
			
			predict	mean1_foodexp_rf
			*	"rforest" cannot predict residual, so we need to compute it manually
			gen	double e1_foodexp_rf	=	food_exp_pc	-	mean1_foodexp_rf
			gen e1_foodexp_sq_rf = (e1_foodexp_rf)^2
			
			
			egen e1_total_rf=total(e1_foodexp_sq_rf) if rf_step1_sample==1 & year==10
			gen rmspe_step1_rf = sqrt(e1_total_rf/step1_N_rf)
		
			summ	rmspe_step1_rf	//	1.83
			
			
			
	/****************************************************************
		SECTION 4: Summary and Exit
	****************************************************************/					
	summ	rmspe_step1_glm	rmspe_step1_lasso	rmspe_step1_rf
	
	exit