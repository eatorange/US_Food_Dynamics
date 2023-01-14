
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
	version			16

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
	
	*	Declare global macro
	include	"${PSID_doAnl}/Macros_for_analyses.do"
			
			
		
	/*
	local	include_stamp	1	//	Turn it on to include food stamp value in food expenditure value.
		
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
	
	*/

	/****************************************************************
		SECTION 1: Summary statistics
	****************************************************************/	

	use	"${PSID_dtFin}/fs_const_long.dta", clear
	
	local	run_sumstat	1
	
	if	`run_sumstat'==1	{
	
	*	Summary Statistics (Table 3)
	
		eststo drop	Total SRC	SEO	Imm
		
		local	estimation_year		inrange(year,2,10)
				
		*	Declare variables
		local	demovars	age_head_fam	HH_race_white	HH_race_color	marital_status_cat	HH_female	
		local	econvars	income_pc	food_exp_stamp_pc
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head	mental_problem
		local	familyvars	num_FU_fam ratio_child	childage_in_FU_nochild childage_in_FU_presch childage_in_FU_sch childage_in_FU_both
		local	eduvars		highdegree_NoHS	highdegree_HS	highdegree_somecol	highdegree_col
		local	foodvars	/*food_stamp_used_1yr*/	food_stamp_used_0yr	child_meal_assist // 2022-12-15: Changed "last year" to "this year", since we add this year's stamp value to food expenditure.
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local 	outcomevars	PFS_glm
		
		local	sumvars	`demovars'	`eduvars'		`empvars'	`healthvars'	`econvars'	`familyvars'		`foodvars'		`changevars'	`outcomevars'

		*cap	drop	sample_source?
		*tab sample_source, gen(sample_source)
		svy, subpop(if ${study_sample} & !mi(PFS_glm)): mean	`sumvars'
		estat sd
		estadd matrix mean = r(mean)
		estadd matrix sd = r(sd)
		estadd scalar N = e(N_sub), replace
		eststo	Total
		
		svy, subpop(if ${study_sample} & !mi(PFS_glm)	&	sample_source_SRC==1): mean  `sumvars'
		estat sd
		estadd matrix mean = r(mean)
		estadd matrix sd = r(sd)
		estadd scalar N = e(N_sub), replace
		eststo	SRC
		
		svy, subpop(if ${study_sample} & !mi(PFS_glm)	&	sample_source_SEO==1): mean  `sumvars'
		estat sd
		estadd matrix mean = r(mean)
		estadd matrix sd = r(sd)
		estadd scalar N = e(N_sub), replace
		eststo	SEO
			
		
		*	Table 1 (Summary Statistics)
		esttab *Total SRC SEO using "${PSID_outRaw}/Tab_1_Sumstats.csv", replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics)	csv 
		
		esttab *Total SRC SEO using "${PSID_outRaw}/Tab_1_Sumstats.tex", replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics)	tex 		
		
	}			
	

	/****************************************************************
		SECTION 2: Recall period & redemption information
	****************************************************************/	

	{
		
		*	Count the number of non-missing PFS obs within household over time. We will restrict our analysis on households with non-missing PFS 
		cap	drop	num_nonmissing_PFS
		bys fam_ID_1999: egen num_nonmissing_PFS = count(PFS_glm)
				
		*	Frequency table of recall period
		*	We focus on at-home expenditure, as most households report it.
		**	This frequency table shows that 90% of HH report weekly expenditure, and 5% report monthly recall expenditure
		svy, subpop(if ${study_sample}==1 & num_nonmissing_PFS!=0	&	year!=1 ): tab foodexp_recall_home	//	Adjusted
		
		*	Stability of recall period within household over time
		cap drop	foodexp_recall_num
		cap	drop	foodexp_recall_num_temp
		qui unique foodexp_recall_home if year!=1  , by(fam_ID_1999) gen(foodexp_recall_num_temp)	//	Number of unique recall period. One non-missing obs per household. I did not exclude "Inappropriate", as responses like "refuse to answer/NA" implies unstability in recall period.
		bys fam_ID_1999: egen foodexp_recall_num = max(foodexp_recall_num_temp)
		drop	foodexp_recall_num_temp	
		
		*	The code below shows that 57% of HHs used single recall period, and 31% used only two recall periods.
		*	We argue that household reported food expenditure stablely over time if the number of unique report period is low.
		svy, subpop(if ${study_sample}==1 & num_nonmissing_PFS!=0	&	year==2 ): tab foodexp_recall_num	//	Adjusted, "year==2" is to count only 1 obs per household.
		
		
		*	Consistency of recall period within household over time.
		cap	drop	foodexp_recall_home_mean
		bys fam_ID_1999: egen foodexp_recall_home_mean = mean(foodexp_recall_home) if year!=1	//	Exclude 1999 expenditure from analysis (1999 is NOT a sample year)
		tab	foodexp_recall_home_mean	if	num_nonmissing_PFS!=0 & year==2 // count only 1 obs per household via !mi(foodexp_recall_num)
		
		*	Mean=3 & foodexp_recall_num=1 implies households reported weekly expenditure only over the study period.
		cap	drop	foodexp_recall_home_weekonly
		gen		foodexp_recall_home_weekonly	=	0
		replace	foodexp_recall_home_weekonly	=	1	if	foodexp_recall_num==1	&	foodexp_recall_home_mean==3
		
		**	The code below shows that 57% of HH reported weekly expenditure only over time.
		svy, subpop(if ${study_sample}==1 & num_nonmissing_PFS!=0 &	year==2	 ): tab foodexp_recall_home_weekonly	//	Adjusted
		

			*	Let's examine household characteristics of households reporting multiple recall period (3 or more) over the survey period.
		local	var	foodexp_recall_home_multiple
		cap	drop	`var'
		gen		`var'	=	0	if	!mi(foodexp_recall_num)
		replace	`var'	=	1	if	!mi(foodexp_recall_num)	&	foodexp_recall_num>=3
		
		
		local	demovars	age_head_fam 
		local	econvars	ln_income_pc	food_exp_stamp_pc
		local	healthvars	phys_disab_head mental_problem
		local	empvars		emp_HH_simple
		local	familyvars	num_FU_fam ratio_child
		local	eduvars		highdegree_NoHS	highdegree_somecol	highdegree_col	
		local	foodvars	food_stamp_used_0yr	child_meal_assist
		
		*	Simple OLS
		svy, subpop(if ${study_sample} & !mi(PFS_glm)): reg `var' 	`demovars'	`econvars'	`healthvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	
		est	store	foodexp_recall_reg
		
		*	Output
		esttab	foodexp_recall_reg	using "${PSID_outRaw}/foodexp_recall_reg.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Conditional Mean and Variance of Food Expenditure per capita) 	///			
				replace
		
		
		*	Food stamp value
		cap	mat	drop	food_stamp_value_0yr
		forval	year=2/5	{
			
			svy, subpop(if ${study_sample}==1 & year==`year'	&	food_stamp_used_0yr==1	&	food_stamp_freq_0yr==5): mean food_stamp_value_0yr	//	Adjusted
			mat	food_stamp_value_0yr	=	nullmat(food_stamp_value_0yr) \ e(b)[1,1]
			
		}
		mat	list	food_stamp_value_0yr
		
		
		*	Food stamp value by recall period
		svy, subpop(if ${study_sample}==1 & food_stamp_used_0yr==1	): tab food_stamp_freq_0yr
		
		svy, subpop(if ${study_sample}==1 & food_stamp_used_0yr==1	&	food_stamp_freq_0yr==3	): mean food_stamp_value_0yr
		svy, subpop(if ${study_sample}==1 & food_stamp_used_0yr==1	&	food_stamp_freq_0yr==5	): mean food_stamp_value_0yr
		svy, subpop(if ${study_sample}==1 & food_stamp_used_0yr==1	&	food_stamp_freq_0yr==6	): mean food_stamp_value_0yr
		
		svy, subpop(if ${study_sample}==1 & year==5	&	food_stamp_used_0yr==1	&	food_stamp_freq_0yr==3	 ): mean food_stamp_value_0yr
		svy, subpop(if ${study_sample}==1 & year==5	&	food_stamp_used_0yr==1	&	food_stamp_freq_0yr==5	 ): mean food_stamp_value_0yr
		svy, subpop(if ${study_sample}==1 & year==5	&	food_stamp_used_0yr==1	&	food_stamp_freq_0yr==6	 ): mean food_stamp_value_0yr
		
		*	PFS and food stamp redemption by the week of the survey
		cap	mat	drop	PFS_byweek_all
		cap	mat	drop	PFS_byweek_FI
		cap	mat	drop	week
		cap	mat	drop	foodstamp_byweek
		
		forval	week=1/52	{
				
				*di "current week is `week'"
				mat	week	=	nullmat(week)	\	`week'
				
				
				*	All households
				qui count	if	${study_sample}==1	&	year!=1	&	week_of_year==`week'
				if	r(N)==0	{
					
					mat	PFS_byweek_all		=	nullmat(PFS_byweek_all)	\	0
					mat	PFS_byweek_FI		=	nullmat(PFS_byweek_FI)	\	0
					mat	foodstamp_byweek	=	nullmat(foodstamp_byweek)	\	0
					
					continue
					
				}		
				qui	svy, subpop(if ${study_sample}==1	&	year!=1	&	week_of_year==`week'):	mean	PFS_glm	//	PFS
				mat	PFS_byweek_all	=	nullmat(PFS_byweek_all)	\	e(b)[1,1]
				
				qui	svy, subpop(if ${study_sample}==1	&	year!=1	&	week_of_year==`week'):	mean	food_stamp_used_0yr	//	Food stamp usage
				mat	foodstamp_byweek	=	nullmat(foodstamp_byweek)	\	e(b)[1,1]
				
				*	FI households
				qui count	if	${study_sample}==1	&	year!=1	&	week_of_year==`week'	&	PFS_FI_glm==1
				if	r(N)==0	{
					
					mat	PFS_byweek_FI	=	nullmat(PFS_byweek_FI)	\	0
					continue
					
				}		
				qui	svy, subpop(if ${study_sample}==1	&	year!=1	&	week_of_year==`week'	&	PFS_FI_glm==1):	mean	PFS_glm
				
				
				mat	PFS_byweek_FI	=	nullmat(PFS_byweek_FI)	\	e(b)[1,1]
			
		}
		
		cap	mat	drop	PFS_byweek_table
		mat	PFS_byweek_table	=	week,	PFS_byweek_all,	PFS_byweek_FI
		mat	list	PFS_byweek_table
		mat list	foodstamp_byweek
		
		*	Simple regression of PFS on interview dummy.
		svy, subpop(if ${study_sample}==1): reg PFS_glm	ib47.week_of_year
	}
	
	/****************************************************************
		SECTION 3: Correlation between the PFS and HFSM
	****************************************************************/	
	
	{
			
		*	Create decile indicator
		cap	drop	PFS_decile_cutoff
		cap	drop	PFS_decile
		pctile 	PFS_decile_cutoff = PFS_glm [pweight=weight_multi12] if (${study_sample}==1	&	inlist(year,2,3,9,10)), nq(10)
		
		gen		PFS_decile=.
		quietly	summarize	PFS_decile_cutoff	in	1
		replace	PFS_decile=1	if	inrange(PFS_glm,0,r(mean))
		forvalues	i=1/8	{
			
			local	j=`i'+1
			qui	summ	PFS_decile_cutoff	in	`i'
			local	minPFS=r(mean)
			qui	summ	PFS_decile_cutoff	in	`j'
			local	maxPFS=r(mean)
			
			replace	PFS_decile	=	`j'	if	inrange(PFS_glm,`minPFS',`maxPFS')
		}
		
		qui	summarize	PFS_decile_cutoff	in	9
		replace	PFS_decile	=	10	if	inrange(PFS_glm,r(mean),1)

		
			
		*	Simple inclusion and exclusion
		
			*	All population
			**	This code gives type I (3.2%) and type II (9.9%) error rates
			svy, subpop(${study_sample}):	tab	fs_cat_fam_simp	PFS_FS_glm
			
			*	IPR below 130%
			*svy, subpop(if ${study_sample} & income_to_poverty<1.3):	tab	fs_cat_fam_simp	PFS_FS_glm
			
			*	SNAP recepients
			*svy, subpop(if ${study_sample} & food_stamp_used_0yr==1):	tab	fs_cat_fam_simp	PFS_FS_glm	
			
		
		*	Rank correlation (spearman, Kendall's tau)
		**	This part shows spearman and Kendall's tau (0.31, 0.25)
			
			*	Pooled
			cap	mat	drop	corr_all
			cap	mat	drop	corr_spearman
			cap	mat	drop	corr_kendall
			
			spearman	fs_scale_fam_rescale	PFS_glm		///
				if ${study_sample}	&	inlist(year,2,3,9,10),	stats(rho obs p)
			mat	corr_spearman	=	r(rho)	
			ktau 	fs_scale_fam_rescale	PFS_glm		///
				if ${study_sample}	&	inlist(year,2,3,9,10), stats(taua taub p)
			mat	corr_kendall	=	r(tau_b)
			
			/*
			*	By PFS decile
								
				*	Check correlation per each decile
				forvalues	i=1/10	{
					
					spearman	fs_scale_fam_rescale	PFS_glm	/*rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf*/	///
						if ${study_sample}	&	inlist(year,2,3,9,10)	&	PFS_decile==`i',	stats(rho obs p)
						
					mat	corr_spearman	=	nullmat(corr_spearman)	\	r(rho)	
						
					ktau 	fs_scale_fam_rescale	PFS_glm	/*rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf*/	///
						if ${study_sample}	&	inlist(year,2,3,9,10)	&	PFS_decile==`i', stats(taua taub p)
						
					mat	corr_kendall	=	nullmat(corr_kendall)	\	r(tau_b)		
					
				}
				
				*	Correlation table, aggregated
				mat	corr_all	=	corr_spearman,	corr_kendall
				mat list corr_all
			*/
						
			*	Frequencyy table of the HFSM (goes to footnote: 90% of HHs have HFSM 1, )
			svy, subpop(if ${study_sample}==1 & !mi(PFS_glm) & !mi(fs_scale_fam_rescale)): tab fs_scale_fam_rescale
			
			*	Summarize PFS (https://www.stata.com/support/faqs/statistics/percentiles-for-survey-data/) (Goes to the FN11 and Fig A2)
			summ	fs_scale_fam_rescale 		if ${study_sample}==1	&	inlist(year,2,3,9,10)	&	!mi(PFS_glm)  [aweight=weight_multi12], detail
			summ	PFS_glm if ${study_sample}==1	&	inlist(year,2,3,9,10)	&	!mi(fs_scale_fam_rescale)		  [aweight=weight_multi12], detail
			
			
			*	Density Estimate of Food Security Indicator (Figure A1)
			graph twoway 		(kdensity fs_scale_fam_rescale			if	inlist(year,2,3,9,10)	&	!mi(PFS_glm))	///
								(kdensity PFS_glm	if	inlist(year,2,3,9,10)	&	!mi(fs_scale_fam_rescale)),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)		///
								name(thrifty, replace) graphregion(color(white)) bgcolor(white)		///
								legend(lab (1 "HFSM (rescaled)") lab(2 "PFS") rows(1))					
			graph	export	"${PSID_outRaw}/Fig_A2_Density_HFSM_PFS.png", replace
			
			
			*	Scatterplot and Fitted value of the USDA on PFS
			graph	twoway (qfitci fs_scale_fam_rescale PFS_glm)	(scatter fs_scale_fam_rescale PFS_glm) if ${study_sample},	///
				xtitle(PFS)	ytitle(HFSM (rescaled))	///
				legend(order(1 "95% CI" 2 "Fitted Value"))
				
			graph	export	"${PSID_outRaw}/qfitci_HFSM_PFS.png", replace
			graph	close

			
			*	Regression
				
				*	All study sample
				svy, subpop(${study_sample}): reg fs_scale_fam_rescale	PFS_glm
				est	sto	corr_glm_lin_noFE
				svy, subpop(${study_sample}): reg fs_scale_fam_rescale	c.PFS_glm##c.PFS_glm
				est	sto	corr_glm_nonlin_noFE
				svy, subpop(${study_sample}): reg fs_scale_fam_rescale	PFS_glm	i.year state_group? state_group1? state_group2?
				est	sto	corr_glm_lin_FE
				svy, subpop(${study_sample}): reg fs_scale_fam_rescale	c.PFS_glm##c.PFS_glm i.year state_group? state_group1? state_group2?
				est	sto	corr_glm_nonlin_FE
				
				*	Bottom 20% of the PFS
				svy, subpop(if	${study_sample}==1	&	inlist(PFS_decile,1,2)): reg fs_scale_fam_rescale	PFS_glm
				est	sto	corr_glm_lin_low20_noFE
				svy, subpop(if	${study_sample}==1	&	inlist(PFS_decile,1,2)): reg fs_scale_fam_rescale	c.PFS_glm##c.PFS_glm
				est	sto	corr_glm_nonlin_low20_noFE
				svy, subpop(if	${study_sample}==1	&	inlist(PFS_decile,1,2)): reg fs_scale_fam_rescale	PFS_glm	i.year state_group? state_group1? state_group2?
				est	sto	corr_glm_lin_low20_FE
				svy, subpop(if	${study_sample}==1	&	inlist(PFS_decile,1,2)): reg fs_scale_fam_rescale	c.PFS_glm##c.PFS_glm i.year state_group? state_group1? state_group2?
				est	sto	corr_glm_nonlin_low20_FE
			
			*	Output (Table A4 of 2020/11/16 draft)
			**	AER requires not to use asterisk(*) for significance level, so we currently do not display it
			**	We can display it by modifying some options
			
			esttab	corr_glm_lin_noFE		corr_glm_nonlin_noFE			corr_glm_lin_FE			corr_glm_nonlin_FE	///
					corr_glm_lin_low20_noFE	corr_glm_nonlin_low20_noFE	corr_glm_lin_low20_FE	corr_glm_nonlin_low20_FE	///
					using "${PSID_outRaw}/Tab_2_HFSM_PFS_correlation.csv", ///
			cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
			title(Regression of the USDA scale on PFS(glm)) replace
			
			
			esttab			corr_glm_lin_noFE		corr_glm_nonlin_noFE			corr_glm_lin_FE			corr_glm_nonlin_FE	///
				using "${PSID_outRaw}/Tab_2_HFSM_PFS_correlation.tex", ///
			cells(b(nostar fmt(%8.3f)) se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc	%8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
			title(Regression of the USDA scale on PFS(glm)) replace
			
				
	}		
	
		
	/****************************************************************
		SECTION 4: Regression of Indicators on Correlates
	****************************************************************/
	
	{
	
		cap	drop	HFSM_PFS_available_years
		gen		HFSM_PFS_available_years=0
		replace	HFSM_PFS_available_years=1	if	inlist(year,2,3,9,10)
		
		
		
		*	Regression of 4 different settings
		
			*	HFSM, without region FE
			local	depvar	fs_scale_fam_rescale	
			svy, subpop(if ${study_sample} & HFSM_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)):	///
				reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	
			est	store	HFSM_noregionFE	
			
			*	PFS, without region FE
			local	depvar	PFS_glm
			svy, subpop(if ${study_sample} & HFSM_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)):	///
				reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	
			est	store	PFS_noregionFE	
			
			*	HFSM, with region FE
			local	depvar	fs_scale_fam_rescale
			svy, subpop(if ${study_sample} & HFSM_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)):	///
				reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
			est	store	HFSM_regionFE	
			
			*	PFS, with region FE
			local	depvar	PFS_FS_glm
			svy, subpop(if ${study_sample} & HFSM_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)):	///
				reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
			est	store	PFS_regionFE	
					
		
		*	Output
		**	AER requires NOT to use asterisk(*) to denote significance level, so we do not display in this code.
		**	We can display them by disabling "nostar" and enabling "star" option
			
			*	Food Security Indicators and Their Correlates (Table 4 of 2020/11/16 draft)
			esttab	HFSM_noregionFE	PFS_noregionFE	HFSM_regionFE	PFS_regionFE	using "${PSID_outRaw}/Tab_3_HFSM_PFS_association.csv", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Effect of Correlates on Food Security Status) replace
					
					
			esttab	HFSM_noregionFE	PFS_noregionFE	HFSM_regionFE	PFS_regionFE	using "${PSID_outRaw}/Tab_3_HFSM_PFS_association.tex", ///
					/*cells(b(star fmt(3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	*/	///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
					title(Effect of Correlates on Food Security Status) replace
	
		
		*	Predicted PFS over age (Fig A3)
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
		
		local	depvar		PFS_glm
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	HH_female	HH_race_color	marital_status_cat
		local	econvars	c.ln_income_pc	
		local	familyvars	c.num_FU_fam c.ratio_child	
		local	eduvars		highdegree_NoHS highdegree_somecol highdegree_col
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_group? state_group1? state_group2?
		local	timevars	year_enum3-year_enum10
		
				
			local	depvar	PFS_glm
			*qui svy:	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	///
										`foodvars'	`shockvars'			`regionvars'	`timevars'
			qui	svy, subpop(${study_sample}): reg 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}
			
			
		predict fv,xb
		
			*	Over the age, using the deviation from the life expectancy
			cap	drop	dev_from_lifeexp
			gen		dev_from_lifeexp=.
			forvalues	year=1999(2)2017	{
				replace	dev_from_lifeexp	=	age_head_fam-life_exp_male_`year'	if	HH_female==0	&	year2==`year'
				replace	dev_from_lifeexp	=	age_head_fam-life_exp_female_`year'	if	HH_female==1	&	year2==`year'
			}
			label	variable	dev_from_lifeexp	"Deviation from the life expectancy by year and gender"
			
					
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
				graph	export	"${PSID_outRaw}/Fig_A3_Fitted_age_retirement.png", replace
				graph	close
			
		
		
		/*
		*	Grouped-state FE (without controls)
		
		
		*	Regress PFS on grouped-state FE (no controls, no time FE)
		local	depvar	PFS_glm
		svy, subpop(if ${study_sample}): reg	`depvar'	${regionvars}		//	NY is omitted as a reference state
		est	store	PFS_regionFE_nocontrols
		
		local	depvar	PFS_glm
		svy, subpop(if ${study_sample}): reg	`depvar'	${regionvars}	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}		//	NY is omitted as a reference state
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
								
		
		
				
		coefplot	PFS_regionFE_nocontrols	PFS_regionFE_controls, keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)		xline(0)	graphregion(color(white)) bgcolor(white)	///
				title(Regional Fixed Effects)		name(TFI_CFI_FE_All, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/PFS_groupstateFE_All.png", replace
				graph	close

			
		*/
	}

	
	
	/****************************************************************
		SECTION 5: Household-level Dynamics
	****************************************************************/	
		
	local	run_spell_length	0	//	Spell length
	local	run_transition_matrix	0	//	Transition matrix
	local	run_perm_approach	1	//	Chronic and transient FS (Jalan and Ravallion (2000) Table)
		local	test_stationary	0	//	Test whether PFS is stationary (computationally intensive)
		local	shapley_decomposition	1	//	Shapley decompsition of TFI/CFI (takes time)

			
	*	Spell length
	if	`run_spell_length'==1	{
		
		*	Tag balanced sample (Households without any missing PFS throughout the study period)
		*	Unbalanced households will be dropped from spell length analyses not to underestimate spell lengths
		capture	drop	num_nonmissing_PFS
		cap	drop	balanced_PFS
		bys fam_ID_1999: egen num_nonmissing_PFS=count(PFS_FI_glm)
		gen	balanced_PFS=1	if	num_nonmissing_PFS==9

		*	Summary stats of spell lengths among FI incidence
		*mat	summ_spell_length	=	J(9,2,.)	
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=2 & PFS_FI_glm==1)
		svy, subpop(if	${study_sample} & _end==1 & balanced_PFS==1): mean _seq //	Mean of spell lengths (To get length as an year, multiply spell length by 2)
		svy, subpop(if	${study_sample}	& _end==1 & balanced_PFS==1): tab _seq 	//	Tabulation of spell lengths.
		*mat	summ_spell_length	=	e(N),	e(b)
		mat	summ_spell_length	=	e(b)[1..1,2..10]'

		*	Persistence rate conditional upon spell length (Table 7 of 2020/11/16 draft)
		mat	persistence_upon_spell	=	J(9,2,.)	
		forvalues	i=1/8	{
			svy, subpop(if	l._seq==`i'	&	!mi(PFS_FS_glm) &	balanced_PFS==1): proportion PFS_FS_glm		//	Previously FI
			mat	persistence_upon_spell[`i',1]	=	/*e(N),*/ e(b)[1,1], r(table)[2,1]
		}

		*	Distribution of spell length and conditional persistent (Table 7 of 2020/11/16 draft)
		mat spell_dist_comb	=	summ_spell_length,	persistence_upon_spell
		mat	rownames	spell_dist_comb	=	2	4	6	8	10	12	14	16	18

		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices", sheet(spell_dist_comb) modify	/*replace*/
		putexcel	A5	=	matrix(spell_dist_comb), names overwritefmt nformat(number_d1)
		
		esttab matrix(spell_dist_comb, fmt(%9.2f)) using "${PSID_outRaw}/Spell_dist_combined.tex", replace	

		drop	_seq _spell _end

		*	Spell length given household newly become food insecure, by each year
		cap drop FI_duration
		gen FI_duration=.

		cap	mat	drop	dist_spell_length
		mat	dist_spell_length	=	J(8,10,.)

		forval	wave=2/9	{
			
			cap drop FI_duration_year*	_seq _spell _end	
			tsspell, cond(year>=`wave' & PFS_FI_glm==1)
			egen FI_duration_year`wave' = max(_seq), by(fam_ID_1999 _spell)
			replace	FI_duration = FI_duration_year`wave' if PFS_FI_glm==1 & year==`wave'
					
			*	Replace households that used to be FI last year with missing value (We are only interested in those who newly became FI)
			if	`wave'>=3	{
				replace	FI_duration	=.	if	year==`wave'	&	!(PFS_FI_glm==1	&	l.PFS_FI_glm==0)
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

		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices", sheet(spell_length) modify	/*replace*/
		putexcel	A5	=	matrix(dist_spell_length_byyear), names overwritefmt nformat(number_d1)
		
		esttab matrix(dist_spell_length_byyear, fmt(%9.2f)) using "${PSID_outRaw}/Tab_4_Dist_spell_length.tex", replace	
		
		
		*	Figure 1
		preserve
			
			clear
			
			set	obs	10
			
			mat	dist_spell_length_byyear_tr	=	dist_spell_length_byyear'
			svmat	dist_spell_length_byyear_tr
			rename	(dist_spell_length_byyear_tr?)	(yr_2001	yr_2003	yr_2005	yr_2007	yr_2009	yr_2011	yr_2013	yr_2015)
			drop	in	1
			
			gen	spell_length	=	(2*_n)
			
			
			*	Figure 1 (Spell Length of Food Insecurity (2003-2015))
			local	marker_2003	mcolor(blue)	msymbol(circle)
			local	marker_2005	mcolor(red)		msymbol(diamond)
			local	marker_2007	mcolor(green)	msymbol(triangle)
			local	marker_2009	mcolor(gs5)		msymbol(square)
			local	marker_2011	mcolor(orange)	msymbol(plus)
			local	marker_2013	mcolor(brown)	msymbol(X)
			local	marker_2015	mcolor(gs13)	msymbol(V)			
			
			twoway	(connected	yr_2003	spell_length	in	1/7, `marker_2003'	lpattern(solid))			(connected	yr_2003	spell_length	in	8, `marker_2003')	///
					(connected	yr_2005	spell_length	in	1/6, `marker_2005'	lpattern(dash))				(connected	yr_2005	spell_length	in	7, `marker_2005')	///
					(connected	yr_2007	spell_length	in	1/5, `marker_2007'	lpattern(dot))				(connected	yr_2007	spell_length	in	6, `marker_2007')	///
					(connected	yr_2009	spell_length	in	1/4, `marker_2009'	lpattern(dash_dot))			(connected	yr_2009	spell_length	in	5, `marker_2009')	///
					(connected	yr_2011	spell_length	in	1/3, `marker_2011'	lpattern(shortdash))		(connected	yr_2011	spell_length	in	4, `marker_2011')	///
					(connected	yr_2013	spell_length	in	1/2, `marker_2013'	lpattern(shortdash_dot))	(connected	yr_2013	spell_length	in	3, `marker_2013')	///
					(connected	yr_2015	spell_length	in	1/6, `marker_2015'	lpattern(longdash))			(connected	yr_2015	spell_length	in	2, `marker_2015'),	///
					xtitle(Years)	ytitle(Fraction)	legend(order(1 "2003"	3	"2005"	5	"2007"	7	"2009"	9	"2011"	11	"2013"	13	"2015") rows(1))	///
					xlabel(0(2)16)	ylabel(0(0.1)0.7)	graphregion(color(white)) bgcolor(white)	ysize(2)	xsize(4)
			
			graph	export	"${PSID_outRaw}/Fig_2_FI_spell_length.png", replace
			graph	close
			
			*	Figure 2a (with selected years only. For presentation)
			local	marker_2003	mcolor(blue)	msymbol(circle)
			local	marker_2005	mcolor(red)		msymbol(diamond)
			local	marker_2007	mcolor(green)	msymbol(triangle)
			local	marker_2013	mcolor(brown)	msymbol(X)		
			
			twoway	(connected	yr_2003	spell_length	in	1/7, `marker_2003'	lpattern(solid))			(connected	yr_2003	spell_length	in	8, `marker_2003')	///
					(connected	yr_2005	spell_length	in	1/6, `marker_2005'	lpattern(dash))				(connected	yr_2005	spell_length	in	7, `marker_2005')	///
					(connected	yr_2007	spell_length	in	1/5, `marker_2007'	lpattern(dot))				(connected	yr_2007	spell_length	in	6, `marker_2007')	///
					(connected	yr_2013	spell_length	in	1/2, `marker_2013'	lpattern(shortdash_dot))	(connected	yr_2013	spell_length	in	3, `marker_2013'),	///
					xtitle(Years)	ytitle(Fraction)	legend(order(1 "2003"	3	"2005"	5	"2007"	7	"2013") rows(1))	///
					xlabel(0(2)16)	ylabel(0(0.1)0.7)	graphregion(color(white)) bgcolor(white)	ysize(2)	xsize(4)
			
			graph	export	"${PSID_outRaw}/Fig_2a_FI_spell_length_ppt.png", replace
			graph	close
			
			
			
			*	Figure A4 (Spell Length of Food Insecurity (2001))
			twoway	(connected	yr_2001	spell_length	in	1/8, mcolor(blue)	lpattern(dash))	///
					(connected	yr_2001	spell_length	in	9, mcolor(blue)),	///
					xtitle(Years)	ytitle(Percentage)	legend(off)	xlabel(0(2)18)	ylabel(0(0.05)0.4)	graphregion(color(white)) bgcolor(white)	ysize(2)	xsize(4)
			
			graph	export	"${PSID_outRaw}/Fig_A4_FI_spell_length_2001.png", replace
			graph	close
			
		restore
		
	
	}
	
	*	Transition matrices	
	if	`run_transition_matrix'==1	{
	
		*	Preamble
		mat drop _all
		cap	drop	??_PFS_FS_glm	??_PFS_FI_glm	??_PFS_LFS_glm	??_PFS_VLFS_glm	??_PFS_cat_glm
		sort	fam_ID_1999	year
			
		*	Generate lagged FS dummy from PFS, as svy: command does not support factor variable so we can't use l.	
		forvalues	diff=1/9	{
			foreach	category	in	FS	FI	LFS	VLFS	cat	{
				if	`diff'!=9	{
					qui	gen	l`diff'_PFS_`category'_glm	=	l`diff'.PFS_`category'_glm	//	Lag
				}
				qui	gen	f`diff'_PFS_`category'_glm	=	f`diff'.PFS_`category'_glm	//	Forward
			}
		}
		
		*	Restrict sample to the observations with non-missing PFS and lagged PFS
		global	nonmissing_PFS_lags	!mi(l1_PFS_FS_glm)	&	!mi(PFS_FS_glm)
		
		*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
			
			*	Year
			cap	mat	drop	trans_2by2_year	trans_change_year
			forvalues	year=3/10	{			

				*	Joint distribution	(two-way tabulate)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & year_enum`year'): tabulate l1_PFS_FS_glm	PFS_FS_glm
				mat	trans_2by2_joint_`year' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`year'	=	e(N_sub)	//	Sample size
				
				*	Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & year_enum`year'): proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`year'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & year_enum`year'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`year'	=	e(b)[1,1]
				
				mat	trans_2by2_`year'	=	samplesize_`year',	trans_2by2_joint_`year',	persistence_`year',	entry_`year'	
				mat	trans_2by2_year	=	nullmat(trans_2by2_year)	\	trans_2by2_`year'
				
				
				*	Change in Status (For Figure 3 of 2020/11/16 draft)
				**	Note: here we do NOT limit our sample to non-missing values, as we need the ratio of those with missing values.
				svy, subpop(if ${study_sample}  & !mi(PFS_FI_glm)	&	year==`year'): tab 	l1_PFS_FI_glm PFS_FI_glm, missing
				local	sample_popsize_total=e(N_subpop)
				mat	trans_change_`year' = e(b)[1,5], e(b)[1,2], e(b)[1,8]
				mat	trans_change_year	=	nullmat(trans_change_year)	\	trans_change_`year'
				
				cap	mat	drop	Pop_ratio
				cap	mat	drop	FI_still_`year'	FI_newly_`year'	
				
				foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
					foreach	race	in	0	1	{	//	People of colors, white
						foreach	gender	in	1	0	{	//	Female, male
							
								
							qui	svy, subpop(if	${study_sample} & !mi(PFS_FI_glm)	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'	&	year==`year'):	tab l1_PFS_FI_glm PFS_FI_glm, missing
												
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

			
					
			*	Gender
			
				*	Male, Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & gender_head_fam_enum2): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_male = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_male	=	e(N_sub)	//	Sample size
				
				*	Female, Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_female): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_female = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_female	=	e(N_sub)	//	Sample size
				
				*	Male, Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & gender_head_fam_enum2):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_male	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & gender_head_fam_enum2):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_male	=	e(b)[1,1]
				
				*	Female, Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_female):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_female	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_female):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_female	=	e(b)[1,1]
				
				mat	trans_2by2_male		=	samplesize_male,	trans_2by2_joint_male,	persistence_male,	entry_male	
				mat	trans_2by2_female	=	samplesize_female,	trans_2by2_joint_female,	persistence_female,	entry_female
				
				mat	trans_2by2_gender	=	trans_2by2_male	\	trans_2by2_female
				
			*	Race
							
				foreach	type	in	1	0	{	//	white/color
					
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'): tabulate l1_PFS_FS_glm	PFS_FS_glm	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_race	=	trans_2by2_1	\	trans_2by2_0

			*	Region (based on John's suggestion)
			
				foreach	type	in	NE MidAt South MidWest	West	{
				
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1): tabulate l1_PFS_FS_glm	PFS_FS_glm	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_region	=	trans_2by2_NE	\	trans_2by2_MidAt	\	trans_2by2_South	\	trans_2by2_MidWest	\		trans_2by2_West
			
			*	Education
			
			foreach	type	in	NoHS	HS	somecol	col	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
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
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			
			mat	trans_2by2_disability	=	trans_2by2_nodisab	\	trans_2by2_disab
			
			*	Child status (by age)
			foreach	type	in	nochild	presch	sch	both	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & childage_in_FU_`type'): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & childage_in_FU_`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & childage_in_FU_`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			
			mat	trans_2by2_child	=	trans_2by2_nochild	\	trans_2by2_presch	\	trans_2by2_sch	\	trans_2by2_both
			
			*	Food Stamp
			cap drop	food_nostamp_used_1yr
			gen		food_nostamp_used_1yr=1	if	food_stamp_used_1yr==0
			replace	food_nostamp_used_1yr=0	if	food_stamp_used_1yr==1
			
			foreach	type	in	nostamp	stamp	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
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
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
				mat	trans_2by2_shock	=	nullmat(trans_2by2_shock)	\	trans_2by2_`type'
			}

		*	Combine transition matrices (Table 6 of 2020/11/16 draft)
		
		mat	define	blankrow	=	J(1,7,.)
		mat	trans_2by2_combined	=	trans_2by2_year	\	blankrow	\	trans_2by2_gender	\	blankrow	\	///
									trans_2by2_race	\	blankrow	\	trans_2by2_region	\	blankrow	\	trans_2by2_degree	\	blankrow	\	///
									trans_2by2_disability	\	blankrow	\	trans_2by2_child	\	blankrow \	trans_2by2_foodstamp	\	blankrow	\	///
									trans_2by2_shock
		
		mat	list	trans_2by2_combined
			
		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices", sheet(2by2) replace	/*modify*/
		putexcel	A3	=	matrix(trans_2by2_combined), names overwritefmt nformat(number_d1)
		
		esttab matrix(trans_2by2_combined, fmt(%9.2f)) using "${PSID_outRaw}/Tab_5_Trans_2by2_combined.tex", replace	
		
		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices", sheet(change) /*replace*/	modify
		putexcel	A3	=	matrix(trans_change_year), names overwritefmt nformat(number_d1)
		putexcel	A13	=	matrix(FI_still_year_all), names overwritefmt nformat(number_d1)
		putexcel	A23	=	matrix(FI_newly_year_all), names overwritefmt nformat(number_d1)
		
		*	Figure 3 & 4
		*	Need to plot from matrix, thus create a temporary dataset to do this
		preserve
		
			clear
			
			set	obs	8
			gen	year	=	_n
			replace	year	=	2001	+	(2*year)
			
			*	Matrix for Figure 3
			svmat trans_change_year
			rename	(trans_change_year?)	(still_FI	newly_FI	status_unknown)
			label var	still_FI		"Still food insecure"
			label var	newly_FI		"Newly food insecure"
			label var	status_unknown	"Previous status unknown"

			egen	FI_prevalence	=	rowtotal(still_FI	newly_FI	status_unknown)
			label	var	FI_prevalence	"Annual FI prevalence"
			
			*	Matrix for Figure 4a
			**	Figure 4 matrices (FI_still_year_all, FI_newly_year_all) have years in column and category as row, so they need to be transposed)
			foreach	fs_category	in	FI_still_year_all	FI_newly_year_all	{
				
				mat		`fs_category'_tr=`fs_category''
				svmat 	`fs_category'_tr
			}
			
			*	Figure 3	(Change in food security status by year)
			graph bar still_FI newly_FI	status_unknown, over(year) stack legend(lab (1 "Still FI") lab(2 "Newly FI") lab(3 "Previous status unknown") rows(1))	///
						graphregion(color(white)) bgcolor(white) asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(orange)) bar(3, fcolor(gs12))	///
						ytitle(Fraction of Population)	ylabel(0(.025)0.153)
			graph	export	"${PSID_outRaw}/Fig_3_FI_change_status_byyear.png", replace
			graph	close
				
			*	Figure 4 (Change in Food Security Status by Group)
			*	Figure 4a
			graph bar FI_newly_year_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	ytitle(Fraction of Population)	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
						bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Newly Food Insecure)	name(Newly_FI, replace) scale(0.8)     
			
			
			*	Figure 4b
			graph bar FI_still_year_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))*/	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
						bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Still Food Insecure)	name(Still_FI, replace)	scale(0.8)  
						
						
			grc1leg Newly_FI Still_FI, rows(1) legendfrom(Newly_FI)	graphregion(color(white)) /*(white)*/
			graph	export	"${PSID_outRaw}/Fig_4_FI_change_status_bygroup.png", replace
			graph	close
			
			
			*	Figure 4c (legend on the right side. For presentation)
			
			*	Figure 4aa
			graph bar FI_newly_year_all_tr?, over(year, label(labsize(small))) stack	graphregion(color(white)) bgcolor(white)	ytitle(Fraction of Population)	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(8) cols(1) position(3) rowgap(2pt))		///
						bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Newly Food Insecure)	name(Newly_FI_aa, replace) scale(0.8)     
			
			
			*	Figure 4bb
			graph bar FI_still_year_all_tr?, over(year, label(labsize(small))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))*/	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(8) cols(1) position(3) rowgap(2pt))	///
						bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Still Food Insecure)	name(Still_FI_bb, replace)	scale(0.8)  
			
			
			
			*	Figure 4c (legend on the right side. For presentation)
			grc1leg Newly_FI_aa Still_FI_bb, rows(1) cols(2) legendfrom(Newly_FI_aa)	graphregion(color(white)) position(3)	graphregion(color(white))	name(Fig4c, replace) ysize(4) xsize(9.0)
			graph display Fig4c, ysize(4) xsize(9.0)
			graph	export	"${PSID_outRaw}/Fig_4c_FI_change_status_bygroup_ppt.png", as(png) replace
			graph	close
			
			
		restore
			
	}
	
	*	Permanent approach	
	if	`run_perm_approach'==1	{
		
		
		*	Before we conduct permanent approach, we need to test whether PFS is stationary.
		**	We reject the null hypothesis that all panels have unit roots.
		if	`test_stationary'==1	{
			xtunitroot fisher	PFS_glm if ${study_sample}==1 ,	dfuller lags(0)	//	no-trend
		}
		
		*cap	drop	pfs_glm_normal
		cap	drop	SFIG
		cap	drop	PFS_glm_mean
		cap	drop	PFS_glm_total
		cap	drop	PFS_threshold_glm_total
		cap	drop	PFS_glm_mean_normal
		cap	drop	PFS_threshold_glm_mean
		cap	drop	PFS_glm_normal_mean
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
		*gen pfs_glm_normal	=.
		
		*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at household-level.
		*	Since households have different number of non-missing PFS and our cut-off probability varies over time, we cannot simply use "mean" function.
		*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
		
		*	Aggregate PFS over time (numerator)
		bys	fam_ID_1999:	egen	PFS_glm_total	=	total(PFS_glm)	if	inrange(year,2,10)
		
		*	Aggregate cut-off PFS over time. To add only the years with non-missing PFS, we replace the cut-off PFS of missing PFS years as missing.
		replace	PFS_threshold_glm=.	if	mi(PFS_glm)
		bys	fam_ID_1999:	egen	PFS_threshold_glm_total	=	total(PFS_threshold_glm)	if	inrange(year,2,10)
		
		*	Generate (normalized) mean-PFS by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
		gen	PFS_glm_mean_normal	=	PFS_glm_total	/	PFS_threshold_glm_total
		
		*	Construct FIG and SFIG
		cap	drop	FIG_indiv
		cap	drop	SFIG_indiv
		gen	FIG_indiv=.
		gen	SFIG_indiv	=.
				
			
			cap	drop	pfs_glm_normal
			gen pfs_glm_normal	=.
				
				
			*	Normalized PFS (PFS/threshold PFS)	(PFSit/PFS_underbar_t)
			replace	pfs_glm_normal	=	PFS_glm	/	PFS_threshold_glm
			
			*	Inner term of the food securit gap (FIG) and the squared food insecurity gap (SFIG)
			replace	FIG_indiv	=	(1-pfs_glm_normal)^1	if	!mi(pfs_glm_normal)	&	pfs_glm_normal<1	//	PFS_glm<PFS_threshold_glm
			replace	FIG_indiv	=	0						if	!mi(pfs_glm_normal)	&	pfs_glm_normal>=1	//	PFS_glm>=PFS_threshold_glm
			replace	SFIG_indiv	=	(1-pfs_glm_normal)^2	if	!mi(pfs_glm_normal)	&	pfs_glm_normal<1	//	PFS_glm<PFS_threshold_glm
			replace	SFIG_indiv	=	0						if	!mi(pfs_glm_normal)	&	pfs_glm_normal>=1	//	PFS_glm>=PFS_threshold_glm
		
			
		*	Total, Transient and Chronic FI

		
			*	Total FI	(Average SFIG over time)
			bys	fam_ID_1999:	egen	Total_FI_HCR	=	mean(PFS_FI_glm)	if	inrange(year,2,10)	//	HCR
			bys	fam_ID_1999:	egen	Total_FI_SFIG	=	mean(SFIG_indiv)	if	inrange(year,2,10)	//	SFIG
			
			label	var	Total_FI_HCR	"TFI (HCR)"
			label	var	Total_FI_SFIG	"TFI (SFIG)"

			*	Chronic FI (SFIG(with mean PFS))					
			gen		Chronic_FI_HCR=.
			gen		Chronic_FI_SFIG=.
			replace	Chronic_FI_HCR	=	(1-PFS_glm_mean_normal)^0	if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal<1	//	Avg PFS < Avg cut-off PFS
			replace	Chronic_FI_SFIG	=	(1-PFS_glm_mean_normal)^2	if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal<1	//	Avg PFS < Avg cut-off PFS
			replace	Chronic_FI_HCR	=	0								if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
			replace	Chronic_FI_SFIG	=	0								if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
			
			lab	var		Chronic_FI_HCR	"CFI (HCR)"
			lab	var		Chronic_FI_SFIG	"CFI (SFIG)"
			
			**** In several households, CFI is greater than TFI. I assume it is because the threshold probability varies, but need to thoroughly check why.
			**** For now, in that case we treat CFI as equal to the TFI
			**** (2021/1/24) Chris said it is OK to have TFI<CFI. Below is his comments from the e-mail sent on Jan 24, 2021
			**** "That said, it’s fine to have CFI>TFI. That’s the very definition of a household that is chronically food insecure but occasionally food secure (i.e., chronically but not persistently food insecure). The poverty dynamics literature includes this as well, as it reflects the headcount basis for the average period-specific (total) food insecurity (TFI) versus the period-average food insecurity (CFI). "
			*replace	Chronic_FI_HCR	=	Total_FI	if	Chronic_FI>Total_FI
			
			*	Transient FI (TFI - CFI)
			gen	Transient_FI_HCR	=	Total_FI_HCR	-	Chronic_FI_HCR
			gen	Transient_FI_SFIG	=	Total_FI_SFIG	-	Chronic_FI_SFIG
					


		*	Restrict sample to non_missing TFI and CFI
		global	nonmissing_TFI_CFI	!mi(Total_FI_HCR)	&	!mi(Chronic_FI_HCR)
		
		*	Descriptive stats
			
			**	For now we include households with 5+ PFS.
			cap	drop	num_nonmissing_PFS
			cap	drop	dyn_sample
			bys fam_ID_1999: egen num_nonmissing_PFS=count(PFS_glm)
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
			bys fam_ID_1999: egen tempyear = min(year) if (${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1 & mi(highdegree_NoHS_2001))

			foreach edu in NoHS HS somecol col	{
				
				cap	drop	highdegree_`edu'_2001_temp?
				gen	highdegree_`edu'_2001_temp1	=	highdegree_`edu'	if	year==tempyear
				bys fam_ID_1999: egen highdegree_`edu'_2001_temp2	=	max(highdegree_`edu'_2001_temp1) if !mi(tempyear)
				replace	highdegree_`edu'_2001	=	highdegree_`edu'_2001_temp2	if	!mi(tempyear)
				drop	highdegree_`edu'_2001_temp?
			}
			drop	tempyear
			
			*	(Temporary) For having a child or not, I use a new variable showing whether a HH "ever" had a child. This variable is time-invariant across periods within households.
			*	We can come up with more complex definition (ex. share of periods having a child, etc.)
			cap	drop	child_ever_had	child_ever_had_enum1	child_ever_had_enum2	child_nothad	child_had
			
			loc	var	child_ever_had
			bys	fam_ID_1999:	egen	`var'=max(child_in_FU_cat)	//	If HH had a child at leat in 1 period, this value should be 1. Otherwise it is zero.
			label	var	`var'	"Ever had a child"
			label	value	`var'	yesno			
			
			tab	`var', gen(`var'_enum)
			rename	(child_ever_had_enum1	child_ever_had_enum2)	(child_nothad	child_had)
			label	var	child_nothad	"No child at all"
			label	var	child_had		"Had a child"
			label value	child_nothad	child_had	yesno


			*	Generate statistics for tables
			local	exceloption	replace
			foreach	measure	in	HCR	SFIG	{
			
				*	Overall			
				svy, subpop(if ${study_sample} &	!mi(PFS_glm)	& ${nonmissing_TFI_CFI} 	&	dyn_sample==1 ):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_all	=	e(b)[1,2]/e(b)[1,1]
				*scalar	samplesize_all	=	e(N_sub)
				mat	perm_stat_2000_all	=	e(N_sub),	e(b), prop_trans_all
				
				*	Gender
				svy, subpop(if ${study_sample} &	!mi(PFS_glm) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	gender_head_fam_enum2==1):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_male	=	e(b)[1,2]/e(b)[1,1]
				mat	perm_stat_2000_male	=	e(N_sub),	e(b), prop_trans_male
				
				svy, subpop(if ${study_sample} &	!mi(PFS_glm) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1 	&	HH_female==1):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_female	=	e(b)[1,2]/e(b)[1,1]
				mat	perm_stat_2000_female	=	e(N_sub),	e(b), prop_trans_female
				
				mat	perm_stat_2000_gender	=	perm_stat_2000_male	\	perm_stat_2000_female
				
				*	Race
				foreach	type	in	1	0	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	HH_race_white==`type'):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_race_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_race_`type'	=	e(N_sub),	e(b), prop_trans_race_`type'
					
				}
				
				mat	perm_stat_2000_race	=	perm_stat_2000_race_1	\	perm_stat_2000_race_0

				*	Region (based on John's suggestion)
				foreach	type	in	NE	MidAt South MidWest West	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	state_group_`type'==1	):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_region_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_region_`type'	=	e(N_sub),	e(b), prop_trans_region_`type'
					
				}
			
				mat	perm_stat_2000_region	=	perm_stat_2000_region_NE	\	perm_stat_2000_region_MidAt	\	perm_stat_2000_region_South	\	///
												perm_stat_2000_region_MidWest	\	perm_stat_2000_region_West
				
				*	Metropolitan Area
				foreach	type	in	metro	nonmetro	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	resid_`type'==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_metro_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_metro_`type'	=	e(N_sub),	e(b), prop_trans_metro_`type'
					
				}
			
				mat	perm_stat_2000_metro	=	perm_stat_2000_metro_metro	\	perm_stat_2000_metro_nonmetro
				
				*	Ever had a child
				foreach	type	in	nothad	had	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	child_`type'==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_child_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_child_`type'	=	e(N_sub),	e(b), prop_trans_child_`type'
					
				}
			
				mat	perm_stat_2000_child	=	perm_stat_2000_child_nothad	\	perm_stat_2000_child_had
				
				
				*	Education degree (Based on 2001 degree)
				foreach	degree	in	NoHS	HS	somecol	col	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	highdegree_`degree'_2001==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_edu_`degree'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_edu_`degree'	=	e(N_sub),	e(b), prop_trans_edu_`degree'
					
				}
				
				mat	perm_stat_2000_edu	=	perm_stat_2000_edu_NoHS	\	perm_stat_2000_edu_HS	\	perm_stat_2000_edu_somecol	\	perm_stat_2000_edu_col

				
				 *	Further decomposition
			   cap	mat	drop	perm_stat_2000_decomp_`measure'
			   cap	mat	drop	Pop_ratio
			   svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1):	///
				mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure' 
			   local	subsample_tot=e(N_subpop)		   
			   
			   foreach	race	in	 HH_race_color	HH_race_white	{	//	Black, white
					foreach	gender	in	HH_female	gender_head_fam_enum2	{	//	Female, male
						foreach	edu	in	NoHS	HS	somecol	col   	{	//	No HS, HS, some col, col
							svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1  & `gender'==1 & `race'==1 & highdegree_`edu'_2001==1): mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
							local	Pop_ratio	=	e(N_subpop)/`subsample_tot'
							scalar	prop_trans_edu_race_gender	=	e(b)[1,2]/e(b)[1,1]
							mat	perm_stat_2000_decomp_`measure'	=	nullmat(perm_stat_2000_decomp_`measure')	\	`Pop_ratio',	e(b), prop_trans_edu_race_gender
						}	// edu			
					}	//	gender	
			   }	//	race

				
				*	Combine results (Table 6)
				mat	define	blankrow	=	J(1,5,.)
				mat	perm_stat_2000_allcat_`measure'	=	perm_stat_2000_all	\	blankrow	\	perm_stat_2000_gender	\	blankrow	\	perm_stat_2000_race	\	///
												blankrow	\	perm_stat_2000_region	\	blankrow	\	perm_stat_2000_metro	\	blankrow \	///
												perm_stat_2000_child	\	blankrow	\	perm_stat_2000_edu	//	To be combined with category later.
				mat	perm_stat_2000_combined_`measure'	=	perm_stat_2000_allcat_`measure'	\	blankrow	\	blankrow	\	perm_stat_2000_decomp_`measure'

				putexcel	set "${PSID_outRaw}/perm_stat", sheet(perm_stat_`measure') `exceloption'
				putexcel	A3	=	matrix(perm_stat_2000_combined_`measure'), names overwritefmt nformat(number_d1)
				
				esttab matrix(perm_stat_2000_combined_`measure', fmt(%9.3f)) using "${PSID_outRaw}/Tab_6_perm_stat_`measure'.tex", replace	
				
				local	exceloption	modify
			}	//	measure
			
			*	Plot Figure 5: Chronic Food Insecurity by Group (HCR)
			preserve
			
				clear
				
				set	obs	16
				gen		race_gender	=	1	in	1/4
				replace	race_gender	=	2	in	5/8
				replace	race_gender	=	3	in	9/12
				replace	race_gender	=	4	in	13/16
				
				label	define	race_gender	1	"Non-White/Female"	2	"Non-White/Male"	3	"White/Female"	4	"White/Male",	replace
				label	values	race_gender	race_gender
				
				gen		education	=	mod(_n,4)
				replace	education	=	4	if	education==0
				
				label	define	education	1	"Less than High School"	2	"High School"	3	"Some College"	4	"College",	replace
				label	values	education	education
				
				gen	edu_fig5	=	_n
				
				//	Currently we use the value for the proportion of each category from the pre-calculated value. It would be better if we can automatically update it as analyses are updated.
				label	define	edu_fig5	1	"Less than High School (2%)"	2	"High School (2.4%)"	3	"Some College (1.4%)"	4	"College (0.6%)"	///
											5	"Less than High School (0.8%)"	6	"High School (2.7%)"	7	"Some College (2.7%)"	8	"College (1.9%)"	///
											9	"Less than High School (1.5%)"	10	"High School (5.6%)"	11	"Some College (4.6%)"	12	"College (4%)"		///
											13	"Less than High School (4.7%)"	14	"High School (21.4%)"	15	"Some College (16.3%)"	16	"College (27.5%)",	replace
				label	values	edu_fig5	edu_fig5
				
			
				
				svmat	perm_stat_2000_decomp_HCR
				rename	perm_stat_2000_decomp_HCR?	(pop_ratio	TFI	CFI	TFF_minus_CFI	ratio_CFI_TFI)
				
				*	Figure 5
				graph hbar TFI CFI, over(edu_fig5, sort(education) descending	label(labsize(vsmall)))	over(race_gender, descending	label(labsize(vsmall) angle(vertical)))	nofill	///	/*	"nofill" option is needed to drop missing categories
									legend(lab (1 "TFI") lab(2 "CFI") /*size(vsmall)*/ rows(1))	bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6))	graphregion(color(white)) bgcolor(white)
				graph	export	"${PSID_outRaw}/Fig_5_TFI_CFI_bygroup.png", replace
				graph	close
				
					
			restore
			
			
			
			*	Categorize HH into four categories
			*	First, generate dummy whether (1) always or not-always FI (2) Never or sometimes FI
				loc	var1	PFS_FI_always_glm
				loc	var2	PFS_FI_never_glm
				cap	drop	`var1'
				cap	drop	`var2'
				bys	fam_ID_1999:	egen	`var1'	=	min(PFS_FI_glm)	//	1 if always FI (persistently poor), 0 if sometimes FS (not persistently poor)
				bys	fam_ID_1999:	egen	`var2'	=	min(PFS_FS_glm)	//	1 if never FI, 0 if sometimes FI (transient)
				replace	`var1'=.	if	year==1
				replace	`var2'=.	if	year==1
			
			local	exceloption	modify
			foreach	measure	in	HCR	SFIG	{
				
				
				assert	Total_FI_`measure'==0 if PFS_FI_never_glm==1	//	Make sure TFI=0 when HH is always FS (PFS>cut-off PFS)
				
				*	Categorize households
				cap	drop	PFS_perm_FI_`measure'
				gen		PFS_perm_FI_`measure'=1	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_always_glm==1	///
					//	Persistently FI (CFI>0, always FI)
				replace	PFS_perm_FI_`measure'=2	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_always_glm==0	///
					//	Chronically but not persistently FI (CFI>0, not always FI)
				replace	PFS_perm_FI_`measure'=3	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_never_glm==0		///
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
				svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): proportion	PFS_perm_FI_`measure'
				mat	PFS_perm_FI_all	=	e(N_sub),	e(b)
				
				*	Gender
				svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	gender_head_fam_enum2):	///
					proportion PFS_perm_FI_`measure'
				mat	PFS_perm_FI_male	=	e(N_sub),	e(b)
				svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_female):	///
					proportion PFS_perm_FI_`measure'
				mat	PFS_perm_FI_female	=	e(N_sub),	e(b)
				
				mat	PFS_perm_FI_gender	=	PFS_perm_FI_male	\	PFS_perm_FI_female
				
			
				*	Race
				foreach	type	in	1	0	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_race_white==`type'):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_race_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_race	=	PFS_perm_FI_race_1	\	PFS_perm_FI_race_0
				
				*	Region
				foreach	type	in	NE	MidAt	South	MidWest West	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_region_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_region	=	PFS_perm_FI_region_NE	\	PFS_perm_FI_region_MidAt	\	PFS_perm_FI_region_South	\	///
											PFS_perm_FI_region_MidWest	\	PFS_perm_FI_region_West
				
				*	Metropolitan
				foreach	type	in	metro	nonmetro	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	resid_`type'==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_metro_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_metro	=	PFS_perm_FI_metro_metro	\	PFS_perm_FI_metro_nonmetro
				
				*	Child
				foreach	type	in	nothad	had	{
					
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	child_`type'==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_child_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_child	=	PFS_perm_FI_child_nothad	\	PFS_perm_FI_child_had
				
				
				*	Education
				foreach	degree	in	NoHS	HS	somecol	col	{
				    
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	highdegree_`degree'_2001==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_edu_`degree'	=	e(N_sub),	e(b)
					
				}
				mat	PFS_perm_FI_edu	=	PFS_perm_FI_edu_NoHS	\	PFS_perm_FI_edu_HS	\	PFS_perm_FI_edu_somecol	\	PFS_perm_FI_edu_col
				

				*	Combine results (Table 9 of 2020/11/16 draft)
				mat	define	blankrow	=	J(1,5,.)
				mat	PFS_perm_FI_combined_`measure'	=	PFS_perm_FI_all	\	blankrow	\	PFS_perm_FI_gender	\	blankrow	\	PFS_perm_FI_race	\	blankrow	\	///
														PFS_perm_FI_region	\	blankrow	\	PFS_perm_FI_metro	\	blankrow	\	PFS_perm_FI_child	\	blankrow	\	PFS_perm_FI_edu
				
				mat	list	PFS_perm_FI_combined_`measure'
				
				di "excel option is `exceloption'"
				putexcel	set "${PSID_outRaw}/perm_stat", sheet(FI_perm_`measure') `exceloption'
				putexcel	A3	=	matrix(PFS_perm_FI_combined_`measure'), names overwritefmt nformat(number_d1)
			
				esttab matrix(PFS_perm_FI_combined_`measure', fmt(%9.2f)) using "${PSID_outRaw}/PFS_perm_FI_`measure'.tex", replace	
				
				*	Table 5 & 6 (combined) of Dec 20 draft
				mat	define Table_5_`measure'	=	perm_stat_2000_allcat_`measure',	PFS_perm_FI_combined_`measure'[.,2...]
				
				putexcel	set "${PSID_outRaw}/perm_stat", sheet(Table5_`measure') `exceloption'
				putexcel	A3	=	matrix(Table_5_`measure'), names overwritefmt nformat(number_d1)
			
				esttab matrix(Table_5_`measure', fmt(%9.3f)) using "${PSID_outRaw}/Tab_6_`measure'.tex", replace
				
				local	exceloption	modify
				
			}	//	measure
		
		*	Group State-FE of TFI and CFI		
			*	Regression of TFI/CFI on Group state FE
			
			local measure HCR
			
			foreach	depvar	in	Total_FI_`measure'	Chronic_FI_`measure'	Transient_FI_`measure'	{
				
				
				*	Without controls/time FE
				qui	svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' ${regionvars}
				est	store	`depvar'_nocontrols
				
				
				*	With controls/time FE
				qui	svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' ${regionvars}	///
					${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}
				est	store	`depvar'
			}
			
			*	Output
			esttab	Total_FI_`measure'_nocontrols	Chronic_FI_`measure'_nocontrols	Transient_FI_`measure'_nocontrols Total_FI_`measure'	Chronic_FI_`measure'	Transient_FI_`measure'	using "${PSID_outRaw}/TFI_CFI_regression.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Regression of TFI/CFI on Characteristics) 	///
					addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
					replace
					
			esttab	Total_FI_`measure'	Chronic_FI_`measure'		using "${PSID_outRaw}/TFI_CFI_regression.tex", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
					title(Regression of TFI/CFI on Characteristics) 	///
					addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
					replace		
			
			
			local	shapley_decomposition=1
			*	Shapley Decomposition
			if	`shapley_decomposition'==1	{
				
				ds	state_group?	state_group1?	state_group2?
				local groupstates `r(varlist)'		
				
				foreach	depvar	in	Total_FI_`measure'	Chronic_FI_`measure'	{
					
					*	Unadjusted
					cap	drop	_mysample
					regress `depvar' 	${demovars}		${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	///
									${foodvars}		${changevars}	 ${regionvars}	${timevars}	///
									if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head	mental_problem no_longer_employed	no_longer_married	no_longer_own_house	became_disabled) 
					
					mat	`depvar'_shapley_indiv	=	e(shapley),	e(shapley_rel)
					mata : st_matrix("`depvar'_shapley_sum", colsum(st_matrix("`depvar'_shapley_indiv")))
					
					mat	`depvar'_shapley	=	`depvar'_shapley_indiv	\	`depvar'_shapley_sum
					
					
					*	Survey-adjusted
					cap	drop	_mysample
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1):	///
						regress `depvar'  	${demovars}		${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	///
								${foodvars}		${changevars}	 ${regionvars}	${timevars}
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head	mental_problem no_longer_employed	no_longer_married	no_longer_own_house	became_disabled)
					
					*	For some reason, Shapely decomposition does not work properly under the adjusted regression model (they don't sum up to 100%)
					*mat	`depvar'_shapley_indiv	=	e(shapley),	e(shapley_rel)
					*mata : st_matrix("`depvar'_shapley_sum", colsum(st_matrix("`depvar'_shapley_indiv")))
					
					*mat	`depvar'_shapley	=	`depvar'_shapley_indiv	\	`depvar'_shapley_sum
				
				}	//	depvar			
			}	//	shapley
			
			mat	TFI_CFI_`measure'_shapley	=	Total_FI_`measure'_shapley,	Chronic_FI_`measure'_shapley
			
			putexcel	set "${PSID_outRaw}/perm_stat", sheet(shapley) /*replace*/	modify
			putexcel	A3	=	matrix(TFI_CFI_`measure'_shapley), names overwritefmt nformat(number_d1)
			
			esttab matrix(TFI_CFI_`measure'_shapley, fmt(%9.3f)) using "${PSID_outRaw}/Tab_7_TFI_CFI_`measure'_shapley.tex", replace	
		

				
			*	Northeast & Mid-Atlantic
				
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI_`measure'	Chronic_FI_`measure', keep(state_group1	state_group2	state_group3	state_group4	state_group5)	xline(0)	graphregion(color(white)) bgcolor(white)	///
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
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI_`measure'	Chronic_FI_`measure', keep(state_group6 state_group7 state_group8 state_group9 state_group10 state_group11)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(South)	name(TFI_CFI_FE_South, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_South.png", replace
				graph	close
				
			*	Mid-West
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI_`measure'	Chronic_FI_`measure', keep(state_group12 state_group13 state_group14 state_group15 state_group16 state_group17)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(Mid-West)	name(TFI_CFI_FE_MW, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_MW.png", replace
				graph	close
			
			*	West
				coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI_`measure'	Chronic_FI_`measure', keep(state_group18 state_group19 state_group20 state_group21)		xline(0)	graphregion(color(white)) bgcolor(white)	///
										title(West)		name(TFI_CFI_FE_West, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_West.png", replace
				graph	close
	
		/*
			graph combine	TFI_CFI_FE_NE_MA	TFI_CFI_FE_South	TFI_CFI_FE_MW	TFI_CFI_FE_West, title(Region Fixed Effects)
			graph	export	"${PSID_outRaw}/TFI_CFI_region_FE.png", replace
			graph	close
		
		
	
		
		grc1leg2		TFI_CFI_FE_NE_MA	TFI_CFI_FE_South	TFI_CFI_FE_MW	TFI_CFI_FE_West,	///
											title(Region Fixed Effects) legendfrom(TFI_CFI_FE_NE_MA)	///
											graphregion(color(white))	/*xtob1title	*/
											/*	note(Vertical line is the average retirement age of the year in the sample)	*/
							graph	export	"${PSID_outRaw}/TFI_CFI_`measure'_region_FE.png", replace
							graph	close
		
		*/
		
		coefplot	Total_FI_`measure'_nocontrols	Chronic_FI_`measure'_nocontrols, 	///
					keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)	///
					xline(0)	graphregion(color(white)) bgcolor(white)	/*title(Regional Fixed Effects)*/	legend(lab (2 "TFI") lab(4 "CFI") /*size(vsmall)*/ rows(1))	name(TFI_CFI_FE_All, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/TFI_CFI_`measure'_groupstateFE_All_nocontrol.png", replace
				graph	close
				
	
		coefplot	Total_FI_`measure'	Chronic_FI_`measure', 	///
					keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)	///
					xline(0)	graphregion(color(white)) bgcolor(white)	legend(lab (2 "TFI") lab(4 "CFI") rows(1))	name(TFI_CFI_FE_All, replace)	ylabel(,labsize(small))	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/Fig_6_TFI_CFI_`measure'_groupstateFE_All.png", replace
				graph	close
			
		*	Quick check the sequence of FS under HFSM
		cap	drop	HFSM_FS_always
		cap	drop	balanced_HFSM
		bys	fam_ID_1999:	egen	HFSM_FS_always	=	min(fs_cat_fam_simp)	//	1 if never food insecure (always food secure under HFSM), 0 if sometimes insecure 
		cap	drop	HFSM_FS_nonmissing
		bys	fam_ID_1999:	egen	HFSM_FS_nonmissing	=	count(fs_cat_fam_simp)	// We can see they all have value 5;	All households have balanded HFSM
										
		*	% of always food secure households under HFSM (this statistics is included after Table 6 (Chronic Food Security Status from Permanent Approach))
		svy, subpop(if ${study_sample}==1 & HFSM_FS_nonmissing==5): mean HFSM_FS_always
		
		
		capture	drop	num_nonmissing_HFSM
		cap	drop	HFSM_total_hf
		bys fam_ID_1999: egen num_nonmissing_HFSM=count(fs_cat_fam_simp)
		bys fam_ID_1999: egen HFSM_total_hf=total(fs_cat_fam_simp)
		
		svy, subpop(if ${study_sample}==1 &  num_nonmissing_HFSM==5): tab HFSM_total_hf
		
		
		
	}

	
	/****************************************************************
		SECTION 6: Groupwise Decomposition
	****************************************************************/	
	local	groupwise_decomp	1
	
	* Generate the squared food insecurty gap (SFIG)	
	if	`groupwise_decomp'==1	{
		
		
		*	Limit the sample to non-missing observations in ALL categories (gender, race, education, region)
		*	It is because when we use "subpop()" option in "svy:" prefix, the command includes missing values outside the defined subpopulation in the population estimate (number of obs)
		*	For example, let's say the variable "race" has missing values, both for male and female.
		*	If we use "svy: tab race", the number of population includes only the observations with non-missing race values.
		*	However, if we use "svy, subpop(if male==1): tab race", the the number of observations includes observations with non-missing race values AND missing race values in "female==1"
			* More details: https://www.stata.com/statalist/archive/2010-03/msg01263.html, https://www.stata.com/statalist/archive/2010-03/msg01264.html
		*	This can be remedied by restricting subpopulation to observations with non-missing values in all categories of interest.
		global	nonmissing_FGT	!mi(PFS_FI_glm) & !mi(FIG_indiv) & !mi(SFIG_indiv)
					
		
		
		*	Aggregate over households to generate population-level statistics
		*	Input for Figure 2 (Food Security Status by Group) in Dec 2020 draft.
			* Graph can be found in "FGT_year" sheet in "Min_report" Excel file
		
		foreach	group	in	all	male	female	white	black	other	NoHS	HS	somecol	col	NE	MidAt	South	MidWest	West metro nonmetro	nochild	presch	sch	both	{
			cap	mat	drop	sampleno_`group'	HCR_`group'	FIG_`group'	SFIG_`group'
		}
		
		
			*	Yearly decomposition
			forval	year=2/10	{
				
				
				*	Overall
					
				svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
				mat	sampleno_all	=	nullmat(HCR_all),	e(N_sub)
				mat	HCR_all			=	nullmat(HCR_all),	e(b)[1,1]
				mat	FIG_all			=	nullmat(FIG_all),	e(b)[1,2]
				mat	SFIG_all		=	nullmat(SFIG_all),	e(b)[1,3]

				*	Gender
					
					*	Male
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	&	${nonmissing_FGT} & HH_female==0	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_male	=	nullmat(sampleno_male),	e(N_sub)
					mat	HCR_male		=	nullmat(HCR_male),	e(b)[1,1]
					mat	FIG_male		=	nullmat(FIG_male),	e(b)[1,2]
					mat	SFIG_male		=	nullmat(SFIG_male),	e(b)[1,3]
					
					*	Female
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	&	${nonmissing_FGT} & HH_female==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_female	=	nullmat(sampleno_female),	e(N_sub)
					mat	HCR_female		=	nullmat(HCR_female),	e(b)[1,1]
					mat	FIG_female		=	nullmat(FIG_female),	e(b)[1,2]
					mat	SFIG_female		=	nullmat(SFIG_female),	e(b)[1,3]
					
				*	Race
				  
					*	White
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_white==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_white	=	nullmat(sampleno_white),	e(N_sub)
					mat	HCR_white		=	nullmat(HCR_white),	e(b)[1,1]
					mat	FIG_white		=	nullmat(FIG_white),	e(b)[1,2]
					mat	SFIG_white		=	nullmat(SFIG_white),	e(b)[1,3]
					
					*	Black
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_black==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_black	=	nullmat(sampleno_black),	e(N_sub)
					mat	HCR_black		=	nullmat(HCR_black),	e(b)[1,1]
					mat	FIG_black		=	nullmat(FIG_black),	e(b)[1,2]
					mat	SFIG_black		=	nullmat(SFIG_black),	e(b)[1,3]
					
					*	Other
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_other==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_other	=	nullmat(sampleno_other),	e(N_sub)
					mat	HCR_other		=	nullmat(HCR_other),	e(b)[1,1]
					mat	FIG_other		=	nullmat(FIG_other),	e(b)[1,2]
					mat	SFIG_other		=	nullmat(SFIG_other),	e(b)[1,3]	
					
				*	Education
				
					*	Less than High School
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_NoHS==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_NoHS	=	nullmat(sampleno_NoHS),	e(N_sub)
					mat	HCR_NoHS		=	nullmat(HCR_NoHS),	e(b)[1,1]
					mat	FIG_NoHS		=	nullmat(FIG_NoHS),	e(b)[1,2]
					mat	SFIG_NoHS		=	nullmat(SFIG_NoHS),	e(b)[1,3]
					
					*	High School
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_HS==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_HS	=	nullmat(sampleno_HS),	e(N_sub)
					mat	HCR_HS		=	nullmat(HCR_HS),	e(b)[1,1]
					mat	FIG_HS		=	nullmat(FIG_HS),	e(b)[1,2]
					mat	SFIG_HS		=	nullmat(SFIG_HS),	e(b)[1,3]
					
					*	Some College
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_somecol==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_somecol	=	nullmat(sampleno_somecol),	e(N_sub)
					mat	HCR_somecol		=	nullmat(HCR_somecol),	e(b)[1,1]
					mat	FIG_somecol		=	nullmat(FIG_somecol),	e(b)[1,2]
					mat	SFIG_somecol		=	nullmat(SFIG_somecol),	e(b)[1,3]
					
					*	College
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_col==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_col	=	nullmat(sampleno_col),	e(N_sub)
					mat	HCR_col		=	nullmat(HCR_col),	e(b)[1,1]
					mat	FIG_col		=	nullmat(FIG_col),	e(b)[1,2]
					mat	SFIG_col		=	nullmat(SFIG_col),	e(b)[1,3]
				
				*	Region (based on John's suggestion)
					
					foreach	stategroup	in	NE	MidAt	South	MidWest	West	{
						
						svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& state_group_`stategroup'==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
						mat	sampleno_`stategroup'	=	nullmat(sampleno_`stategroup'),	e(N_sub)
						mat	HCR_`stategroup'		=	nullmat(HCR_`stategroup'),	e(b)[1,1]
						mat	FIG_`stategroup'		=	nullmat(FIG_`stategroup'),	e(b)[1,2]
						mat	SFIG_`stategroup'		=	nullmat(SFIG_`stategroup'),	e(b)[1,3]
						
					}
					
				*	Child
				
					*	No child
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& childage_in_FU_nochild==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_nochild	=	nullmat(sampleno_nochild),	e(N_sub)
					mat	HCR_nochild		=	nullmat(HCR_nochild),	e(b)[1,1]
					mat	FIG_nochild		=	nullmat(FIG_nochild),	e(b)[1,2]
					mat	SFIG_nochild		=	nullmat(SFIG_nochild),	e(b)[1,3]
					
					*	Pre-schooler only
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& childage_in_FU_presch==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_presch	=	nullmat(sampleno_presch),	e(N_sub)
					mat	HCR_presch		=	nullmat(HCR_presch),	e(b)[1,1]
					mat	FIG_presch		=	nullmat(FIG_presch),	e(b)[1,2]
					mat	SFIG_presch	=	nullmat(SFIG_presch),	e(b)[1,3]
					
					*	Schooler only
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& childage_in_FU_sch==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_sch	=	nullmat(sampleno_sch),	e(N_sub)
					mat	HCR_sch		=	nullmat(HCR_sch),	e(b)[1,1]
					mat	FIG_sch		=	nullmat(FIG_sch),	e(b)[1,2]
					mat	SFIG_sch		=	nullmat(SFIG_sch),	e(b)[1,3]
					
					*	Both
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& childage_in_FU_both==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_both	=	nullmat(sampleno_both),	e(N_sub)
					mat	HCR_both		=	nullmat(HCR_both),	e(b)[1,1]
					mat	FIG_both		=	nullmat(FIG_both),	e(b)[1,2]
					mat	SFIG_both		=	nullmat(SFIG_both),	e(b)[1,3]
				
				
				*	Metropolitan Area
				 
					*	Metro
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& resid_metro==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
					mat	sampleno_metro	=	nullmat(sampleno_metro),	e(N_sub)
					mat	HCR_metro		=	nullmat(HCR_metro),	e(b)[1,1]
					mat	FIG_metro		=	nullmat(FIG_metro),	e(b)[1,2]
					mat	SFIG_metro		=	nullmat(SFIG_metro),	e(b)[1,3]
					
					*	Non-metro
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& resid_nonmetro==1	&	year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
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
												 `measure'_nochild	\	`measure'_presch	\	`measure'_sch	\	`measure'_both	\	blankrow_1by9	\	///
												 `measure'_metro	\	`measure'_nonmetro
				
			}
			cap	mat	drop	FGT_year_combined
			mat	FGT_year_combined	=	blankrow_1by9	\	HCR_year_combined	\	blankrow_1by9	\	blankrow_1by9	\	FIG_year_combined	\	blankrow_1by9	\	blankrow_1by9	\	SFIG_year_combined
			
			putexcel	set "${PSID_outRaw}/FGT_bygroup", sheet(year) replace	/*modify*/
			putexcel	A3	=	matrix(FGT_year_combined), names overwritefmt nformat(number_d1)
			
			*esttab matrix(perm_stat_2000_combined, fmt(%9.4f)) using "${PSID_outRaw}/perm_stat_combined.tex", replace
			
		   *	Categorical decomposition
		   *	Input for Figure 3 in Dec 2020 draft (Food Insecurity Prevalence and Severity by Group).
			*	Data and Graph can be found in "FGT_group" sheet in "Min_report" Excel file.
		  
		   *	Generate group-level aggregates.
		   *	We need to do it twice - one for main graph and one for supplement graph. The latter use more detailed educational category.
		   
		   *	Total population size, which is needed to get the share of each sub-group population to total population later
			qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT}): mean PFS_FI_glm FIG_indiv	SFIG_indiv
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
								mean PFS_FI_glm FIG_indiv	SFIG_indiv
							
							local	Pop_ratio_all	=	e(N_subpop)/`sample_popsize_total'	//	Share of sub-group pop to total pop.
							mat		Pop_ratio_all	=	nullmat(Pop_ratio_all)	\	`Pop_ratio_all'
							mat	HCR_cat			=	nullmat(HCR_cat)	\	e(b)[1,1]
							mat	FIG_cat			=	nullmat(FIG_cat)	\	e(b)[1,2]
							mat	SFIG_cat		=	nullmat(SFIG_cat)	\	e(b)[1,3]
							
							*	Weighted average for stacked bar graph, by year					
							
							forval	year=2/10	{
								
								*	Generate population size estimate of the sample, which will be used to calculate weighted average.
								qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT} & year==`year'): mean PFS_FI_glm FIG_indiv	SFIG_indiv
								local	sample_popsize_year=e(N_subpop)
								
								*	Estimate FGT measures
								qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'	&	year==`year'):	///
									mean PFS_FI_glm FIG_indiv	SFIG_indiv
									
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
								mean PFS_FI_glm FIG_indiv	SFIG_indiv
							
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
				putexcel	A3	=	matrix(FGT_cat_combined), names overwritefmt nformat(number_d1)			//	HCR, FIG and SFIG by different groups (across all years)
				putexcel	A14	=	matrix(HCR_weight_cat_all), names overwritefmt nformat(number_d1)		//	HCR by different groups by each year. Input for Fig 8a
				putexcel	A24	=	matrix(FIG_weight_cat_all), names overwritefmt nformat(number_d1)		//	FIG by different groups by each year.	Input for Fig A5
				putexcel	A34	=	matrix(SFIG_weight_cat_all), names overwritefmt nformat(number_d1)		//	SFIG by different groups by each year.	Input for Fig 8b
				putexcel	M3	=	matrix(FGT_cat_combined_sup), names overwritefmt nformat(number_d1)	//	Input for Fig 7 "Food Insecurity Prevalence and Severity by Group"
				
				
			*	Figure 7
			preserve
			
				clear
				
				set	obs	16
				
				*	Generate category variable 
				gen	fig7_cat	=	_n
				
					//	Currently we use the value for the proportion of each category from the pre-calculated value. It would be better if we can automatically update it as analyses are updated.
				label	define	fig7_cat	1	"NoHS/NonWhite/Female (1.6%)"		2	"NoHS/NonWhite/Male (0.8%)"		3	"NoHS/White/Female (1.2%)"		4	"NoHS/White/Male (4%)"	///
											5	"HS/NonWhite/Female (2.4%)"			6	"HS/NonWhite/Male (2.5%)"		7	"HS/White/Female (5%)"			8	"HS/White/Male (21%)"	///
											9	"SomeCol/NonWhite/Female (1.4%)"	10	"SomeCol/NonWhite/Male (2.6%)"	11	"SomeCol/White/Female (5%)"		12	"SomeCol/White/Male (15.8%)"		///
											13	"Col/NonWhite/Female (0.9%)"		14	"Col/NonWhite/Male (2.2%)"		15	"Col/White/Female (4.4%)"		16	"Col/White/Male (29.2%)",	replace
				label	values	fig7_cat	fig7_cat
				
				
				*	Generate category variable for Fig 8 and A5
				
				
				svmat	FGT_cat_combined_sup
				rename	FGT_cat_combined_sup?	(pop_ratio	HCR	FIG	SFIG)
				
				*	Figure 7	(Food Insecurity Prevalence and Severity by Group)
				graph hbar HCR SFIG, over(fig7_cat, sort(HCR) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "HCR") lab(2 "SFIG") size(small) rows(1))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6))	graphregion(color(white)) bgcolor(white)
				graph	export	"${PSID_outRaw}/Fig_7_FGT_group_decomposition.png", replace
				graph	close
				
				*	Figure 7a	(Figure 7 with selected groups. For presentation)
				drop	in	2/6
				drop	in	3/7
				drop	in	4/5
				
				graph hbar HCR SFIG, over(fig7_cat, sort(HCR) descending	label(labsize(medium)))	legend(lab (1 "HCR") lab(2 "SFIG") size(small) rows(1))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6))	graphregion(color(white)) bgcolor(white) blabel(bar, format(%4.3f) size(vsmall))
				graph	export	"${PSID_outRaw}/Fig_7a_FGT_group_decomposition_ppt.png", replace
				graph	close
				
				/*
				*	Figure A5-a	(Food Insecurity Prevalence and Severity by Group - FIG)
				graph hbar FIG, over(fig7_cat, sort(FIG) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "FIG") size(small) rows(1))	///
							bar(1, fcolor(yellow*0.5)) /*bar(2, fcolor(green*0.6))*/	graphregion(color(white)) bgcolor(white)	title((a) FI Severity by Group) ytitle(FIG) name(FIG_bygroup)
				graph	export	"${PSID_outRaw}/FGT_group_decomposition_FIG.png", replace
				graph	close
				*/
			
			restore
			
			*	Figure 8, A5
			
			preserve
			
				clear
			
				set	obs	9
				gen	year	=	_n
				replace	year	=	1999	+	(2*year)
				
				*	Input matrices
				**	Input matrices (HCR_weight_cat_all, FIG_weight_cat_all,	SFIG_weight_cat_all) have years in column and category as row, so they need to be transposed)
				foreach	FGT_category	in	HCR_weight_cat_all FIG_weight_cat_all	SFIG_weight_cat_all{
					
					mat		`FGT_category'_tr=`FGT_category''
					svmat 	`FGT_category'_tr
				}
				
			
				
				*	Figure 8a	(HCR)
				graph bar HCR_weight_cat_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))	ylabel(0(.025)0.1)*/	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
							asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Headcount Ratio)	name(Fig8_HCR, replace) scale(0.8)     

							
				*	Figure 8b	(SFIG)
				graph bar SFIG_weight_cat_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))	ylabel(0(.025)0.1)*/	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
							asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Squared Food Insecurity Gap)	name(Fig8_SFIG, replace) scale(0.8)   
							
				*	Figure 8 (Food Security Status By Group and Year)
				grc1leg Fig8_HCR Fig8_SFIG, rows(2) legendfrom(Fig8_HCR)	graphregion(color(white)) /*(white)*/
				graph	export	"${PSID_outRaw}/Fig_8_FGT_group_change.png", as(png) replace
				graph	close
				
				*	Figure 8aa (Figure 8a with different legend position. For presentation)
				graph bar HCR_weight_cat_all_tr?, over(year) stack	graphregion(color(white)) bgcolor(white)	ysize(2) xsize(4)	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(8) cols(1) position(3) rowgap(2pt))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Headcount Ratio)	name(Fig8aa_HCR, replace) scale(0.8)
				
							
				*	Figure 8bb	(Figure 8b with different legend position. For presentation)
				graph bar SFIG_weight_cat_all_tr?, over(year) stack	graphregion(color(white)) bgcolor(white)	ysize(2) xsize(4)	///	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(8) cols(1) position(3) rowgap(2pt))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Squared Food Insecurity Gap)	name(Fig8bb_SFIG, replace) scale(0.8)  
				
				*	Figure 8c	(Figure 8 with different legend for presentation)
				grc1leg Fig8aa_HCR Fig8bb_SFIG, rows(1) cols(2) legendfrom(Fig8aa_HCR)	graphregion(color(white)) position(3)	graphregion(color(white))	name(Fig8c, replace) 
				graph display Fig8c, ysize(4) xsize(9.0)
				graph	export	"${PSID_outRaw}/Fig_8c_FGT_group_chang_ppt.png", as(png) replace
				graph	close
				
				
				*	Figure A5	(Food Insecurity Status (FIG) by Group and Year)
				graph bar FIG_weight_cat_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))	ylabel(0(.025)0.1)*/	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
							asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	/*title((b) By Group and Year)*/	name(FigA5_b, replace) scale(0.8) 
				graph	export	"${PSID_outRaw}/Fig_A5_FGT_group_change_FIG.png", replace
				graph	close
							
			restore
				
				
		*	Food Security Prevalence over different groups	(Table 8)
		cap	mat	drop	HCR_group_PFS_3 HCR_group_PFS_7 HCR_group_PFS_10 HCR_group_PFS_all

		
		foreach year in	3	7	10	{	// 2003, 2011, 2017
		   foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
				foreach	race	in	0	1	{	//	People of colors, white
					foreach	gender	in	1	0	{	//	Female, male
							
					*	FS prevalence
							
					qui svy, subpop(if ${study_sample} & year==`year'	&	HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	mean PFS_FI_glm 
							
					mat	HCR_group_PFS_`year'	=	nullmat(HCR_group_PFS_`year')	\	e(b)[1,1]
					
					/*
					if	inlist(`year',3,10)	{
						
						qui svy, subpop(if ${study_sample} & year==`year'	&	HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	mean HFSM_FI 
						
						mat	HCR_group_HFSM_`year'	=	nullmat(HCR_group_HFSM_`year')	\	e(b)[1,1]
						
					}
					*/								
					}	// gender			
				}	//	race	
		   }	//	edu	 
		   
		   *	Overall prevalence (should be equal to the HFSM prevalence)
		   		
			qui svy, subpop(if ${study_sample} & year==`year'):	mean PFS_FI_glm 
			mat	HCR_group_PFS_`year'	=	nullmat(HCR_group_PFS_`year')	\	e(b)[1,1]
			
			/*
			if	inlist(`year',3,10)	{
				qui svy, subpop(if ${study_sample} & year==`year'):	mean HFSM_FI 
			}
			mat	HCR_group_HFSM_`year'	=	nullmat(HCR_group_HFSM_`year')	\	e(b)[1,1]
			*/
			
		}	// year
		
		mat	HCR_group_PFS_all	=	HCR_group_PFS_3,	HCR_group_PFS_7,	HCR_group_PFS_10
		//mat	HCR_group_HFSM_all	=	HCR_group_HFSM_3,	HCR_group_HFSM_10
		
		putexcel	set "${PSID_outRaw}/FGT_bygroup", sheet(HCR_desc) /*replace*/	modify
		putexcel	A3	=	matrix(HCR_group_PFS_all), names overwritefmt nformat(number_d1)
		//putexcel	F3	=	matrix(HCR_group_HFSM_all), names overwritefmt nformat(number_d1)
			
		esttab matrix(HCR_group_PFS_all, fmt(%9.2f)) using "${PSID_outRaw}/Tab_8_HCR_prepost.tex", replace
		
	}
	

