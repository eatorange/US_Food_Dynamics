
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_analyses
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Apr 12, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	fam_ID_1999       // Uniquely identifies family (update for your project)

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
	
		*	Regression variables
		
			global	statevars	lag_food_exp_pc_1 lag_food_exp_pc_2	lag_food_exp_pc_3 //	Lagged food expenditure per capita, up to third order
			global	demovars	age_head_fam age_head_fam_sq	HH_race_color	marital_status_cat	HH_female	//	age, age^2, race, marital status, gender
			global	econvars	ln_income_pc	//	log of income per capita
			global	healthvars	phys_disab_head mental_problem	//	physical and mental health
			global	empvars		emp_HH_simple	//	employment status
			global	familyvars	num_FU_fam ratio_child	//	# of family members and % of ratio of children
			global	eduvars		highdegree_NoHS	highdegree_somecol	highdegree_col	//	Highest degree achieved
			global	foodvars	food_stamp_used_0yr	child_meal_assist 		//	Food assistance programs
			global	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled	//	Change in status
			global	regionvars	state_group? state_group1? state_group2?	//	Region (custom group of status)
			global	timevars	year_enum3-year_enum10	//	Year dummies
			

	/****************************************************************
		SECTION 1: Construct PFS measurement
	****************************************************************/	

	use	"${PSID_dtFin}/fs_const_long.dta", clear
	
		
	*	Including stamp value or not
	**	For now, I will add just a code deciding which food expenditure to use - with or without food stamp.
	** I can make this code nicer later.
	
	
	local	include_stamp	1	//	After discussing with Chris and John, we decided NOT to include food stamp as it significantly decrades its matching between the HFSM (Check May 2021 mail). Difference would be included in the Appendix.
		
	*	Determine whether to include stamp value to expenditure or not.
	if	`include_stamp'==1	{
		
		replace	food_exp_pc			=	food_exp_stamp_pc
		
		replace	lag_food_exp_pc_1	=	lag_food_exp_stamp_pc_1
		replace	lag_food_exp_pc_2	=	lag_food_exp_stamp_pc_2
		replace	lag_food_exp_pc_3	=	lag_food_exp_stamp_pc_3
		replace	lag_food_exp_pc_4	=	lag_food_exp_stamp_pc_4
		replace	lag_food_exp_pc_5	=	lag_food_exp_stamp_pc_5
			
		replace	lag_food_exp_pc_th_1	=	lag_food_exp_stamp_pc_th_1
		replace	lag_food_exp_pc_th_2	=	lag_food_exp_stamp_pc_th_2
		replace	lag_food_exp_pc_th_3	=	lag_food_exp_stamp_pc_th_3
		replace	lag_food_exp_pc_th_4	=	lag_food_exp_stamp_pc_th_4
		replace	lag_food_exp_pc_th_5	=	lag_food_exp_stamp_pc_th_5
		
	}
	
	
	
	*	OLS
	local	run_GLM	0
		local	model_selection	1
		local	run_ME	0
		
	*	LASSO
	local	run_lasso	1
		local	run_lasso_step1	1
		local	run_lasso_step2	0
		local	run_lasso_step3	0
		
	*	Random Forest
	local	run_rf	0	
		local	tune_iter	0	//	Tuning iteration
		local	tune_numvars	0	//	Tuning numvars
		local	run_rf_step1	1
		local	run_rf_step2	1
		local	run_rf_step3	1

	
	*	GLM

		*	Declare variables
		local	depvar		food_exp_pc
		
		*	Step 1
		*svy, subpop(${study_sample}): glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}, family(gamma)	link(log)
		*	Exclude year 10 (to calculate RMPSE)
		svy, subpop(if ${study_sample} & year!=10): glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}, family(gamma)	link(log)
		est	sto	ols_step1
		
	
		*	Predict fitted value and residual
		gen		ols_step1_sample=1	if	e(sample)==1 & sample_source_SRC_SEO & year!=10	
		replace	ols_step1_sample=1	if	year==10 & l.ols_step1_sample==1
		count if ols_step1_sample==1 & year==10	//	Number of 2017 observations used to measure performance
		scalar step1_N_ols=r(N)
		
		predict double mean1_foodexp_ols	if	ols_step1_sample==1
		predict double e1_foodexp_ols		if	ols_step1_sample==1,r
		gen e1_foodexp_sq_ols = (e1_foodexp_ols)^2
		
		egen e1_total_ols=total(e1_foodexp_sq_ols) if ols_step1_sample==1 & year==10
		gen rmpse_step1_ols = sqrt(e1_total_ols/step1_N_ols)
		
		
		
		
	*	LASSO
		local	statevars	lag_food_exp_pc_1-lag_food_exp_pc_5	/*c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1*/		//	up to the order of 5
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse	mental_problem
		local	demovars	age_head_fam age_head_fam_sq	HH_race_white HH_race_color	marital_status_cat	/*marital_status_fam_enum1 marital_status_fam_enum3 marital_status_fam_enum4 marital_status_fam_enum5*/	/*age_head_fam	age_head_fam_sq*/	///
							HH_female	/*c.age_spouse##c.age_spouse*/ age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc	/*income_pc	income_pc_sq	wealth_pc	wealth_pc_sq*/	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	/*num_child_fam*/	child_in_FU_cat	couple_status_enum1-couple_status_enum4
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
							/*	attend_college_head attend_college_spouse	college_yrs_head college_yrs_spouse	///
							hs_completed_head	college_completed	other_degree_head	grade_comp_head_fam	///
							hs_completed_head_interact college_completed_interact other_degree_head_interact	///
							hs_completed_spouse	college_comp_spouse	other_degree_spouse	grade_comp_spouse	///
							hs_completed_spouse_interact college_comp_spouse_interact other_degree_spouse_interact	*/
		local	foodvars	food_stamp_used_0yr food_stamp_used_1yr	child_meal_assist WIC_received_last	/*meal_together*/	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	/*state_resid_fam_enum1-state_resid_fam_enum52*/ state_group? state_group1? state_group2?
		local	timevars	year_enum2-year_enum9
		
		

		
			*	Feature Selection
			*	Run Lasso with "K-fold" validation	with K=10
			
			local	depvar	food_exp_pc
	
			**	Following "cvlasso" command does k-fold cross-validation to find lambda, but it takes too much time.
			**	Therefore, once it is executed and found lambda, then we run regular lasso using "lasso2"
			**	If there's major change in specification, cvlasso must be executed
			
			set	seed	20200505
			
			/*
			numlist "50000(50)1", descending
			*	Finding optimal lambda using cross-validation (computationally intensive)
			cvlasso	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'		`healthvars'	`familyvars'	`eduvars'	`eduvars'	`foodvars'	`childvars'	`regionvars'	`timevars'		if	${study_sample}==1 & year!=10,	///
				/*lopt lse*/  lambda(`r(numlist)')	seed(20200505)	notpen(`regionvars'	`timevars')	 rolling	/*h(1) fe	prestd 	postres	ols*/	plotcv 
				
			est	store	lasso_step1_lse
			
			
			*cvlasso, postresult lopt	//	somehow this command is needed to generate `e(selected)' macro. Need to double-check
			cvlasso, postresult lse
			*/
	
				
						*	Running lasso with pre-determined lambda value 
				*local	lambdaval=exp(14.7)	//	14.7 is as of Aug 21
				*local	lambdaval=2208.348	//	manual lambda value from the cvplot. This is the value slightly higher than lse but give only slightly higher MSPE
				*local	lambdaval=1546.914	//	the lse value found from cvlasso using SRC sample only as of Nov 5.
				*local	lambdaval=45467.265 (lse) // LSE value from training set (excluding 2017)
				
				*	"cvlasso" using training data (2001-2015) gives lse-optimal lambda=45467.265, which does penalize "ALL" variables except those we intentionally didn't penalize (time and state FE). It gives RMPSE=2.600
				*	Thus, we manually tested all the values from 50 to 50000, with increment 100. We found lambda=50 minimuzes MSPE (lopt) and the largest lambda within 1-stdev is lambda=11,800
				
				local	lambdaval=11800	//	temporary value, will find the exact value via cvlasso it later.
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
				
				
				replace	lasso_step1_sample=1 if year==10 & l.lasso_step1_sample==1 // This command should run "after" running post-LASSO, since we don't want 2017 to be included in post-LASSO when validating performance
				count if lasso_step1_sample==1 & year==10	//	Number of 2017 observations used to measure performance
				scalar step1_N_lasso=r(N)
				
				*	Predict conditional means and variance from Post-LASSO
				predict double mean1_foodexp_lasso	if	lasso_step1_sample==1, xb	
				predict double e1_foodexp_lasso	if	lasso_step1_sample==1,r	
				gen e1_foodexp_sq_lasso = (e1_foodexp_lasso)^2
		
				egen e1_total_lasso=total(e1_foodexp_sq_lasso) if lasso_step1_sample==1 & year==10
				gen rmpse_step1_lasso = sqrt(e1_total_lasso/step1_N_lasso)
		
		
		
*	Random Forest		
		
*	Variable Selection
		local	statevars	lag_food_exp_pc_1 /*-lag_avg_foodexp_pc_5*/	//	RF allows non-linearity, thus need not include higher polynomial terms
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse	mental_problem
		local	demovars	age_head_fam HH_race_white HH_race_color	marital_status_cat	HH_female	age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	/*num_child_fam*/	child_in_FU_cat	couple_status_enum1-couple_status_enum4
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
		local	foodvars	food_stamp_used_0yr food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_group? state_group1? state_group2?
		local	timevars	year_enum2-year_enum9

		
	*	Random Forest
	local	run_rf	0	
		local	tune_iter	0	//	Tuning iteration
		local	tune_numvars	0	//	Tuning numvars
		local	run_rf_step1	1
		local	run_rf_step2	1
		local	run_rf_step3	1
		
		
		
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
											`foodvars'	`childvars'	`changevars'	`regionvars'	if	year!=10	&	${study_sample}==1,	///
											type(reg)	seed(20200505) iterations(50) numvars(`i')
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
		}	//	tune_numvars
		
		
		*	Step 1
		if	`run_rf_step1'==1	{
			
			cap	drop	rf_step1_sample
			cap	drop	importance_mean
			cap	drop	importance_mean1
			
			local	statevars	lag_food_exp_pc_1-lag_food_exp_pc_5	/*c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1*/		//	up to the order of 5
			local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse	mental_problem
			local	demovars	age_head_fam age_head_fam_sq	HH_race_white HH_race_color	marital_status_cat	/*marital_status_fam_enum1 marital_status_fam_enum3 marital_status_fam_enum4 marital_status_fam_enum5*/	/*age_head_fam	age_head_fam_sq*/	///
								HH_female	/*c.age_spouse##c.age_spouse*/ age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
			local	econvars	ln_income_pc	ln_wealth_pc	/*income_pc	income_pc_sq	wealth_pc	wealth_pc_sq*/	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
			local	empvars		emp_HH_simple	emp_spouse_simple
			local	familyvars	num_FU_fam ratio_child	/*num_child_fam*/	child_in_FU_cat	couple_status_enum1-couple_status_enum4
			local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
								/*	attend_college_head attend_college_spouse	college_yrs_head college_yrs_spouse	///
								hs_completed_head	college_completed	other_degree_head	grade_comp_head_fam	///
								hs_completed_head_interact college_completed_interact other_degree_head_interact	///
								hs_completed_spouse	college_comp_spouse	other_degree_spouse	grade_comp_spouse	///
								hs_completed_spouse_interact college_comp_spouse_interact other_degree_spouse_interact	*/
			local	foodvars	food_stamp_used_0yr food_stamp_used_1yr	child_meal_assist WIC_received_last	/*meal_together*/	elderly_meal
			local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
			local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
			local	regionvars	/*state_resid_fam_enum1-state_resid_fam_enum52*/ state_group? state_group1? state_group2?
			local	timevars	year_enum2-year_enum9
			
			
			loc	depvar	food_exp_pc
			rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	year!=10 & 	${study_sample}==1,	///
									type(reg)	iterations(50)	numvars(17)	seed(20200505) 
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
			graph	export	"${PSID_outRaw}/rf_feature_importance_step1.png", replace
			graph	close
			
			putexcel	set "${PSID_outRaw}/Feature_importance", sheet(mean) replace	/*modify*/
			putexcel	A3	=	matrix(importance_mean), names overwritefmt nformat(number_d1)
			
			predict	mean1_foodexp_rf
			*	"rforest" cannot predict residual, so we need to compute it manually
			gen	double e1_foodexp_rf	=	food_exp_pc	-	mean1_foodexp_rf
			gen e1_foodexp_sq_rf = (e1_foodexp_rf)^2
			
			
			egen e1_total_rf=total(e1_foodexp_sq_rf) if rf_step1_sample==1 & year==10
			gen rmpse_step1_rf = sqrt(e1_total_rf/step1_N_rf)
		
		}