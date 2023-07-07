*	Recall period
*	This do-file replicates the statistics of recall period in the main text section "Empirical Framework/Data"

	use	"${FSD_dtFin}/FSD_const_long.dta", clear
		
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
		esttab	foodexp_recall_reg	using "${FSD_outTab}/foodexp_recall_reg.csv", ///
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

	