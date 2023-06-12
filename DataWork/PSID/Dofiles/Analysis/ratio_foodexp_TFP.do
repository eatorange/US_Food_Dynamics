*	This is the do-file written to follow-up based on the AER rejection comments we received
*	It relicates the entire analyses using food expenditure and its ratio.
*	Currently it is just a copy-and-paste of the analyses file with additional variable construction.
*	Will be integrated into the main do-files once discussed.



*	(2022-8-18) Note: The construction part was imported into "const" file (no longer updated). So I disable it by default. DO NOT make changes here..
local	AER_followup_const=1
local	AER_followup_analyses=1

if	`AER_followup_const'==1	{
	
	*	Generate a ratio variable E* = food exp/TFP

	use	"${PSID_dtFin}/fs_const_long.dta", clear
	cap	drop	ratio_foodexp_TFP
	gen	ratio_foodexp_TFP	=	food_exp_stamp_pc	/	foodexp_W_thrifty
	summ ratio_foodexp_TFP,d
	label variable	ratio_foodexp_TFP	"E; (Food exp/TFP) ratio"


	*	Categorization	
	local	run_categorization=1
	if	`run_categorization'==1	{
						
		
			*	Summary Statistics of Indicies
			summ	fs_scale_fam_rescale	ratio_foodexp_TFP		///
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
					
					gen	E_FS	=	0	if	!mi(ratio_foodexp_TFP)	//	Food secure
					gen	E_FI	=	0	if	!mi(ratio_foodexp_TFP)	//	Food insecure (low food secure and very low food secure)
					gen	E_LFS	=	0	if	!mi(ratio_foodexp_TFP)	//	Low food secure
					gen	E_VLFS	=	0	if	!mi(ratio_foodexp_TFP)	//	Very low food secure
					gen	E_cat	=	0	if	!mi(ratio_foodexp_TFP)	//	Categorical variable: FS, LFS or VLFS
											
					*	Generate a variable for the threshold E (E*)
					gen	E_threshold	=	.
					
					foreach	year	in	2	3	4	5	6	7	8	9	10	{
						
						di	"current loop is in year `year'"
						xtile pctile_E_`year' = ratio_foodexp_TFP if ${study_sample} & !mi(ratio_foodexp_TFP)	&	year==`year', nq(1000)

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
								qui	replace	E_`indicator'=1	if	year==`year'	&	inrange(pctile_E_`year',1,`counter')	//	categorize certain number of households at bottom as FI
								qui	svy, subpop(if ${study_sample} & year_enum`year'): mean 	E_`indicator'	//	Generate population ratio
								local ratio_`indicator' = _b[E_`indicator']
								
								local counter = `counter' + 10	//	Increase counter by 10
							}

							*	Since we first looped by unit of 10, we now have to find to exact value by looping 1 instead of 10.
							di "internediate counter is `counter'"
							local	counter=`counter'-10	//	Adjust the counter, since we added extra 10 at the end of the first loop

							while (`counter' > 1 & `ratio_`indicator''>`prop_`indicator'_`year'') {	//	Loop until population ratio < USDA ratio
								
								qui di "counter is `counter'"
								qui	replace	E_`indicator'=0	if	year==`year'	&	inrange(pctile_E_`year',`counter',1000)
								qui	svy, subpop(if ${study_sample} & year_enum`year'): mean 	E_`indicator'
								local ratio_`indicator' = _b[E_`indicator']
								
								local counter = `counter' - 1
							}
							di "Final counter is `counter'"

							*	Now we finalize the threshold value - whether `counter' or `counter'+1
								
								*	Counter
								local	diff_case1	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')

								*	Counter + 1
								qui	replace	E_`indicator'=1	if	year==`year'	&	inrange(pctile_E_`year',1,`counter'+1)
								qui	svy, subpop(if ${study_sample} & year_enum`year'): mean 	E_`indicator'
								local	ratio_`indicator' = _b[E_`indicator']
								local	diff_case2	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')
								qui	di "diff_case2 is `diff_case2'"

								*	Compare two threshold values and choose the one closer to the USDA value
								if	(`diff_case1'<`diff_case2')	{
									global	threshold_`indicator'_E_`year'	=	`counter'
								}
								else	{	
									global	threshold_`indicator'_E_`year'	=	`counter'+1
								}
							
							*	Categorize households based on the finalized threshold value.
							qui	{
								replace	E_`indicator'=1	if	year==`year'	&	inrange(pctile_E_`year',1,${threshold_`indicator'_E_`year'})
								replace	E_`indicator'=0	if	year==`year'	&	inrange(pctile_E_`year',${threshold_`indicator'_E_`year'}+1,1000)		
							}	
							di "thresval of `indicator' in year `year' is ${threshold_`indicator'_E_`year'}"
						}	//	indicator
						
						*	Food secure households
						replace	E_FS=0	if	year==`year'	&	inrange(pctile_E_`year',1,${threshold_FI_E_`year'})
						replace	E_FS=1	if	year==`year'	&	inrange(pctile_E_`year',${threshold_FI_E_`year'}+1,1000)
						
						*	Low food secure households
						replace	E_LFS=1	if	year==`year'	&	E_FI==1	&	E_VLFS==0	//	food insecure but NOT very low food secure households			
						
						*	Categorize households into one of the three values: FS, LFS and VLFS						
						replace	E_cat=1	if	year==`year'	&	E_VLFS==1
						replace	E_cat=2	if	year==`year'	&	E_LFS==1
						replace	E_cat=3	if	year==`year'	&	E_FS==1
						replace	E_cat=.	if	year==`year'	&	!${study_sample}
						assert	E_cat!=0	if	year==`year'
						
						*	Save threshold PFS as global macros and a variable, the average of the maximum PFS among the food insecure households and the minimum of the food secure households					
						qui	summ	ratio_foodexp_TFP	if	year==`year'	&	E_FS==1	//	Minimum PFS of FS households
						local	min_FS_E	=	r(min)
						qui	summ	ratio_foodexp_TFP	if	year==`year'	&	E_FI==1	//	Maximum PFS of FI households
						local	max_FI_E	=	r(max)
						
						*	Save the threshold PFS
						replace	E_threshold	=	(`min_FS_E'	+	`max_FI_E')/2		if	year==`year'					
						
					}	//	year
					
					label	var	E_FI	"Food Insecurity (E)"
					label	var	E_FS	"Food security (E)"
					label	var	E_LFS	"Low food security (E) "
					label	var	E_VLFS	"Very low food security (E)"
					label	var	E_cat	"E category: FS, LFS or VLFS"
					


				
				lab	define	E_cat	1	"Very low food security (VLFS)"	2	"Low food security (LFS)"	3	"Food securit (FS)"
				lab	value	E_cat	E_cat
				
			 }	//	qui
			
			
			*	Graph the PFS threshold for each year
			cap drop templine templine2
			gen templine=0.6
			gen	templine2=1
			twoway	(connected PFS_threshold_glm	year2 if fam_ID_1999==1, lpattern(dot)		mlabel(PFS_threshold_glm) mlabposition(12) mlabformat(%9.3f))	///
					(connected E_threshold 			year2 if fam_ID_1999==1, lpattern(dash_dot)	mlabel(E_threshold) mlabposition(12) mlabformat(%9.3f))	///
					(line templine year2 if fam_ID_1999==1, lpattern(dash))	///
					(line templine2 year2 if fam_ID_1999==1, lpattern(dash)),	///
					/*title(Probability Threshold for being Food Secure)*/	ytitle(Probability/Ratio)	xtitle(Year)	xlabel(2001(2)2017) ///
					legend(order(1 "P*"	2	"E*"))	///
					name(E_Threshold, replace)	graphregion(color(white)) bgcolor(white)
					
			graph	export	"${PSID_outRaw}/E_Thresholds.png", replace
			graph	close
			
			drop	templine
	
		
	}	//	Categorization			

	svy, subpop(if ${study_sample} & !mi(PFS_glm) & year==10): mean  PFS_FI_glm PFS_FS_glm
	svy, subpop(if ${study_sample} & !mi(E_FI) & year==10): mean  E_FI E_FS
	
		
	*	Generate an indicator that E*<1
	cap	drop	E_below_1
	gen		E_below_1	=	.
	replace	E_below_1	=	1	if	!mi(ratio_foodexp_TFP)	&	ratio_foodexp_TFP<1
	replace	E_below_1	=	0	if	!mi(ratio_foodexp_TFP)	&	ratio_foodexp_TFP>=1
	label	var	E_below_1	"=1 if food exp is less than TFP"
	
	*	Prevalence over time
	preserve
		collapse	fs_cat_IS	E_FI	E_below_1 if ${study_sample}	 [aweight=weight_multi12], by(year2)
		graph	twoway	(bar fs_cat_IS year2)	///
						(connected E_FI	year2)	///
						(connected E_below_1	year2),	///
						title(Prevalence of HFSM FI and E<1) ytitle(Percentage)	///
						legend(order(1 "HFSM FI"	2	"PFS FI" 3	"E=(foodexp/TFP)<1"	) rows(1))	
		graph	export	"${PSID_outRaw}/Prevalence_FI_E_threshold.png", replace
		graph	close
	restore	
		

	cap	drop	HFSM_PFS_available_years
	gen		HFSM_PFS_available_years=0
	replace	HFSM_PFS_available_years=1	if	inlist(year,2,3,9,10)
	
	save	"${PSID_dtFin}/AER_followup_const.dta", replace
	
}

	
	

	
*	Analyses
use	"${PSID_dtFin}/fs_const_long.dta", clear
include	"${PSID_doAnl}/Macros_for_analyses.do"	
	
*	Rank correlation between HFSM and PFS, E
{

	*	between HFSM and PFS

		*	Spearman (all sample)
		spearman	fs_scale_fam_rescale	PFS_glm		///
				if ${study_sample}	&	inlist(year,2,3,9,10),	stats(rho obs p)
		mat	corr_spearman_all_HFSM_PFS	=	r(rho), r(p)
		
		*	Spearman (HFSM FI households only)
		spearman	fs_scale_fam_rescale	PFS_glm		///
				if ${study_sample}	&	inlist(year,2,3,9,10)	&	fs_cat_fam_simp==0,	stats(rho obs p)
		mat	corr_spearman_FI_HFSM_PFS	=	r(rho), r(p)	
	
		*	Tau's b (all sample)
		ktau 	fs_scale_fam_rescale	PFS_glm		///
				if ${study_sample}	&	inlist(year,2,3,9,10), stats(taua taub p)
		mat	corr_kendall_all_HFSM_PFS	=	r(tau_b), r(p)
		
		*	Tau's b (HFSM FI household only)
		ktau 	fs_scale_fam_rescale	PFS_glm		///
				if ${study_sample}	&	inlist(year,2,3,9,10)	&	fs_cat_fam_simp==0, stats(taua taub p)
		mat	corr_kendall_FI_HFSM_PFS	=	r(tau_b), r(p)
		
		
		mat	corr_HFSM_PFS	=	corr_spearman_all_HFSM_PFS	\	corr_spearman_FI_HFSM_PFS	\	corr_kendall_all_HFSM_PFS	\	corr_kendall_FI_HFSM_PFS
		
	*	Between HFSM and E*
		
		*	Spearman (all sample)
		spearman	fs_scale_fam_rescale	ratio_foodexp_TFP		///
				if ${study_sample}	&	inlist(year,2,3,9,10),	stats(rho obs p)
		mat	corr_spearman_all_HFSM_E	=	r(rho), r(p)	
		
		*	Spearman (HFSM FI households only)
		spearman	fs_scale_fam_rescale	ratio_foodexp_TFP		///
				if ${study_sample}	&	inlist(year,2,3,9,10)	&	fs_cat_fam_simp==0,	stats(rho obs p)
		mat	corr_spearman_FI_HFSM_E	=	r(rho), r(p)	
	
		*	Tau's b (all sample)
		ktau 	fs_scale_fam_rescale	ratio_foodexp_TFP		///
				if ${study_sample}	&	inlist(year,2,3,9,10), stats(taua taub p)
		mat	corr_kendall_all_HFSM_E	=	r(tau_b), r(p)
		
		*	Tau's b (HFSM FI household only)
		ktau 	fs_scale_fam_rescale	ratio_foodexp_TFP		///
				if ${study_sample}	&	inlist(year,2,3,9,10)	&	fs_cat_fam_simp==0, stats(taua taub p)
		mat	corr_kendall_FI_HFSM_E	=	r(tau_b), r(p)
		
		mat	corr_HFSM_E	=	corr_spearman_all_HFSM_E	\	corr_spearman_FI_HFSM_E	\	corr_kendall_all_HFSM_E	\	corr_kendall_FI_HFSM_E
		
	mat	corr_all	=	corr_HFSM_PFS,	corr_HFSM_E
	mat	list	corr_all
		
}


*	Regression of indicators on covariates
{
		
	*	HFSM, with region FE
		local	depvar	fs_scale_fam_rescale
		svy, subpop(if ${study_sample} & HFSM_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(ratio_foodexp_TFP)):	///
			reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
		est	store	HFSM_regionFE	
		
	*	PFS, with region FE
		local	depvar	PFS_FS_glm
		svy, subpop(if ${study_sample} & HFSM_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(ratio_foodexp_TFP)):	///
			reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
		est	store	PFS_regionFE	
	
	*	E, with region FE
		local	depvar	ratio_foodexp_TFP
		svy, subpop(if ${study_sample} & HFSM_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(ratio_foodexp_TFP)):	///
			reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
		est	store	E_regionFE

		
		esttab	HFSM_regionFE	PFS_regionFE	E_regionFE	using "${PSID_outRaw}/HFSM_PFS_E_association.csv", ///
		cells(b(star fmt(3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
		title(Effect of Correlates on Food Security Status) replace

		esttab	HFSM_regionFE	PFS_regionFE	E_regionFE	using "${PSID_outRaw}/HFSM_PFS_E_association.tex", ///
		/*cells(b(star fmt(3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	*/	///
		cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
		title(Effect of Correlates on Food Security Status) replace
		
}



	
	/****************************************************************
		SECTION 5: Household-level Dynamics
	****************************************************************/	
		
	local	run_spell_length	1	//	Spell length
	local	run_transition_matrix	1	//	Transition matrix
	local	run_perm_approach	1	//	Chronic and transient FS (Jalan and Ravallion (2000) Table)
		local	test_stationary	0	//	Test whether PFS is stationary (computationally intensive)
		local	shapley_decomposition	1	//	Shapley decompsition of TFI/CFI (takes time)

			
	*	Spell length
	if	`run_spell_length'==1	{
		
		*	Tag balanced sample (Households without any missing PFS throughout the study period)
		*	Unbalanced households will be dropped from spell length analyses not to underestimate spell lengths
		capture	drop	num_nonmissing_E
		cap	drop	balanced_E
		bys fam_ID_1999: egen num_nonmissing_E=count(E_FI)
		gen	balanced_E=1	if	num_nonmissing_E==9

		*	Summary stats of spell lengths among FI incidence
		*mat	summ_spell_length	=	J(9,2,.)	
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=2 & E_FI==1)
		svy, subpop(if	${study_sample} & _end==1 & balanced_E==1): mean _seq //	Mean of spell lengths (To get length as an year, multiply spell length by 2)
		svy, subpop(if	${study_sample}	& _end==1 & balanced_E==1): tab _seq 	//	Tabulation of spell lengths.
		*mat	summ_spell_length	=	e(N),	e(b)
		mat	summ_spell_length	=	e(b)[1..1,2..10]'

		*	Persistence rate conditional upon spell length (Table 7 of 2020/11/16 draft)
		tsset // need to run befor the code below
		mat	persistence_upon_spell	=	J(9,2,.)	
		forvalues	i=1/8	{
			svy, subpop(if l._seq==`i'	&	!mi(E_FS) &	balanced_E==1): proportion E_FS		//	Previously FI
			mat	persistence_upon_spell[`i',1]	=	/*e(N),*/ e(b)[1,1], r(table)[2,1]
		}

		*	Distribution of spell length and conditional persistent (Table 7 of 2020/11/16 draft)
		mat spell_dist_comb	=	summ_spell_length,	persistence_upon_spell
		mat	rownames	spell_dist_comb	=	2	4	6	8	10	12	14	16	18

		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices_E", sheet(spell_dist_comb) modify	/*replace*/
		putexcel	A5	=	matrix(spell_dist_comb), names overwritefmt nformat(number_d1)
		
		esttab matrix(spell_dist_comb, fmt(%9.2f)) using "${PSID_outRaw}/Spell_dist_combined_E.tex", replace	

		drop	_seq _spell _end

		*	Spell length given household newly become food insecure, by each year
		cap drop FI_duration
		gen FI_duration=.

		cap	mat	drop	dist_spell_length
		mat	dist_spell_length	=	J(8,10,.)

		forval	wave=2/9	{
			
			cap drop FI_duration_year*	_seq _spell _end	
			tsspell, cond(year>=`wave' & E_FI==1)
			egen FI_duration_year`wave' = max(_seq), by(fam_ID_1999 _spell)
			replace	FI_duration = FI_duration_year`wave' if E_FI==1 & year==`wave'
					
			*	Replace households that used to be FI last year with missing value (We are only interested in those who newly became FI)
			if	`wave'>=3	{
				replace	FI_duration	=.	if	year==`wave'	&	!(E_FI==1	&	l.E_FI==0)
			}
			
		}
		replace FI_duration=.	if	balanced_E!=1 //

		*	Figure 4 of 2020/11/16 draft
		mat	dist_spell_length_byyear	=	J(8,10,.)
		forval	wave=2/9	{
			
			local	row=`wave'-1
			svy, subpop(if year==`wave'	&	!mi(FI_duration)): tab FI_duration
			mat	dist_spell_length_byyear[`row',1]	=	e(N_sub), e(b)
			
		}

		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices_E", sheet(spell_length) modify	/*replace*/
		putexcel	A5	=	matrix(dist_spell_length_byyear), names overwritefmt nformat(number_d1)
		
		esttab matrix(dist_spell_length_byyear, fmt(%9.2f)) using "${PSID_outRaw}/Tab_4_Dist_spell_length_E.tex", replace	
		
		
		*	Figure 2
		preserve
			
			clear
			
			set	obs	10
			
			mat	dist_spell_length_byyear_tr	=	dist_spell_length_byyear'
			svmat	dist_spell_length_byyear_tr
			rename	(dist_spell_length_byyear_tr?)	(yr_2001	yr_2003	yr_2005	yr_2007	yr_2009	yr_2011	yr_2013	yr_2015)
			drop	in	1
			
			gen	spell_length	=	(2*_n)
			
			
			*	Figure 2 (Spell Length of Food Insecurity (2003-2015))
			local	marker_2003	mcolor(gs0)	msymbol(circle)
			local	marker_2005	mcolor(gs2)		msymbol(diamond)
			local	marker_2007	mcolor(gs4)	msymbol(triangle)
			local	marker_2009	mcolor(gs6)		msymbol(square)
			local	marker_2011	mcolor(gs8)	msymbol(plus)
			local	marker_2013	mcolor(gs10)	msymbol(X)
			local	marker_2015	mcolor(gs12)	msymbol(V)			
			
			twoway	(connected	yr_2003	spell_length	in	1/7, `marker_2003'	lpattern(solid))			(connected	yr_2003	spell_length	in	8, `marker_2003')	///
					(connected	yr_2005	spell_length	in	1/6, `marker_2005'	lpattern(dash))				(connected	yr_2005	spell_length	in	7, `marker_2005')	///
					(connected	yr_2007	spell_length	in	1/5, `marker_2007'	lpattern(dot))				(connected	yr_2007	spell_length	in	6, `marker_2007')	///
					(connected	yr_2009	spell_length	in	1/4, `marker_2009'	lpattern(dash_dot))			(connected	yr_2009	spell_length	in	5, `marker_2009')	///
					(connected	yr_2011	spell_length	in	1/3, `marker_2011'	lpattern(shortdash))		(connected	yr_2011	spell_length	in	4, `marker_2011')	///
					(connected	yr_2013	spell_length	in	1/2, `marker_2013'	lpattern(shortdash_dot))	(connected	yr_2013	spell_length	in	3, `marker_2013')	///
					(connected	yr_2015	spell_length	in	1/6, `marker_2015'	lpattern(longdash))			(connected	yr_2015	spell_length	in	2, `marker_2015'),	///
					xtitle(Years)	ytitle(Percentage)	legend(order(1 "2003"	3	"2005"	5	"2007"	7	"2009"	9	"2011"	11	"2013"	13	"2015") rows(2))	///
					xlabel(0(2)16)	ylabel(0(0.1)0.7)	graphregion(color(white)) bgcolor(white)	ysize(2)	xsize(4)
			
			graph	export	"${PSID_outRaw}/Fig_B1_FI_spell_length_E.png", replace
			graph	close
			
			
			*	Figure A4 (Spell Length of Food Insecurity (2001))
			twoway	(connected	yr_2001	spell_length	in	1/8, mcolor(blue)	lpattern(dash))	///
					(connected	yr_2001	spell_length	in	9, mcolor(blue)),	///
					xtitle(Years)	ytitle(Percentage)	legend(off)	xlabel(0(2)18)	ylabel(0(0.05)0.4)	graphregion(color(white)) bgcolor(white)	ysize(2)	xsize(4)
			
			graph	export	"${PSID_outRaw}/Fig_A4_FI_spell_length_2001_E.png", replace
			graph	close
			
		restore
		
	
	}
	
	*	Transition matrices	
	if	`run_transition_matrix'==1	{
	
		*	Preamble
		mat drop _all
		cap	drop	??_E_FS	??_E_FI	??_E_LFS	??_E_VLFS	??_E_cat
		sort	fam_ID_1999	year
			
		*	Generate lagged FS dummy from PFS, as svy: command does not support factor variable so we can't use l.	
		forvalues	diff=1/9	{
			foreach	category	in	FS	FI	LFS	VLFS	cat	{
				if	`diff'!=9	{
					qui	gen	l`diff'_E_`category'	=	l`diff'.E_`category'	//	Lag
				}
				qui	gen	f`diff'_E_`category'	=	f`diff'.E_`category'	//	Forward
			}
		}
		
		*	Restrict sample to the observations with non-missing PFS and lagged PFS
		global	nonmissing_E_lags	!mi(l1_E_FS)	&	!mi(E_FS)
		
		*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
			
			*	Year
			cap	mat	drop	trans_2by2_year	trans_change_year
			forvalues	year=3/10	{			

				*	Joint distribution	(two-way tabulate)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & year_enum`year'): tabulate l1_E_FS	E_FS
				mat	trans_2by2_joint_`year' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`year'	=	e(N_sub)	//	Sample size
				
				*	Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & year_enum`year'): proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
				scalar	persistence_`year'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & year_enum`year'):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
				scalar	entry_`year'	=	e(b)[1,1]
				
				mat	trans_2by2_`year'	=	samplesize_`year',	trans_2by2_joint_`year',	persistence_`year',	entry_`year'	
				mat	trans_2by2_year	=	nullmat(trans_2by2_year)	\	trans_2by2_`year'
				
				
				*	Change in Status (For Figure 3 of 2020/11/16 draft)
				**	Note: here we do NOT limit our sample to non-missing values, as we need the ratio of those with missing values.
				svy, subpop(if ${study_sample}  & !mi(E_FI)	&	year==`year'): tab 	l1_E_FI E_FI, missing
				local	sample_popsize_total=e(N_subpop)
				mat	trans_change_`year' = e(b)[1,5], e(b)[1,2], e(b)[1,8]
				mat	trans_change_year	=	nullmat(trans_change_year)	\	trans_change_`year'
				
				cap	mat	drop	Pop_ratio
				cap	mat	drop	FI_still_`year'	FI_newly_`year'	
				
				foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
					foreach	race	in	0	1	{	//	People of colors, white
						foreach	gender	in	1	0	{	//	Female, male
							
								
							qui	svy, subpop(if	${study_sample} & !mi(E_FI)	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'	&	year==`year'):	tab l1_E_FI E_FI, missing
												
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
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & gender_head_fam_enum2): tabulate l1_E_FS	E_FS	
				mat	trans_2by2_joint_male = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_male	=	e(N_sub)	//	Sample size
				
				*	Female, Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & HH_female): tabulate l1_E_FS	E_FS	
				mat	trans_2by2_joint_female = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_female	=	e(N_sub)	//	Sample size
				
				*	Male, Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & gender_head_fam_enum2):qui proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
				scalar	persistence_male	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & gender_head_fam_enum2):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
				scalar	entry_male	=	e(b)[1,1]
				
				*	Female, Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & HH_female):qui proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
				scalar	persistence_female	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & HH_female):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
				scalar	entry_female	=	e(b)[1,1]
				
				mat	trans_2by2_male		=	samplesize_male,	trans_2by2_joint_male,	persistence_male,	entry_male	
				mat	trans_2by2_female	=	samplesize_female,	trans_2by2_joint_female,	persistence_female,	entry_female
				
				mat	trans_2by2_gender	=	trans_2by2_male	\	trans_2by2_female
				
			*	Race
							
				foreach	type	in	1	0	{	//	white/color
					
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & HH_race_white==`type'): tabulate l1_E_FS	E_FS	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & HH_race_white==`type'):qui proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & HH_race_white==`type'):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_race	=	trans_2by2_1	\	trans_2by2_0

			*	Region (based on John's suggestion)
			
				foreach	type	in	NE MidAt South MidWest	West	{
				
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & state_group_`type'==1): tabulate l1_E_FS	E_FS	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & state_group_`type'==1):qui proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & state_group_`type'==1):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_region	=	trans_2by2_NE	\	trans_2by2_MidAt	\	trans_2by2_South	\	trans_2by2_MidWest	\		trans_2by2_West
			
			*	Education
			
			foreach	type	in	NoHS	HS	somecol	col	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & highdegree_`type'): tabulate l1_E_FS	E_FS	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & highdegree_`type'):qui proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & highdegree_`type'):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
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
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & phys_`type'_head): tabulate l1_E_FS	E_FS	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & phys_`type'_head):qui proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & phys_`type'_head):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
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
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & food_`type'_used_1yr): tabulate l1_E_FS	E_FS	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & food_`type'_used_1yr):qui proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & food_`type'_used_1yr):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
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
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & `type'_shock): tabulate l1_E_FS	E_FS	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & `type'_shock):qui proportion	E_FS	if	l1_E_FS==0	&	!mi(E_FS)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_E_lags} & `type'_shock):qui proportion	E_FS	if	l1_E_FS==1	&	!mi(E_FS)	//	Previously FS
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
			
		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices_E", sheet(2by2) replace	/*modify*/
		putexcel	A3	=	matrix(trans_2by2_combined), names overwritefmt nformat(number_d1)
		
		esttab matrix(trans_2by2_combined, fmt(%9.2f)) using "${PSID_outRaw}/Tab_5_Trans_2by2_combined_E.tex", replace	
		
		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices_E", sheet(change) /*replace*/	modify
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
						graphregion(color(white)) bgcolor(white) asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(yellow*0.6)) bar(3, fcolor(gs1))	///
							ytitle(Fraction of Population)	ylabel(0(.025)0.153)
			graph	export	"${PSID_outRaw}/Fig_B2_FI_change_status_byyear_E.png", replace
			graph	close
				
			*	Figure 4 (Change in Food Security Status by Group)
			*	Figure 4a
			graph bar FI_newly_year_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	ytitle(Population prevalence(%))	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
						asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Newly Food Insecure)	name(Newly_FI, replace) scale(0.8)     
			
			
			*	Figure 4b
			graph bar FI_still_year_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))*/	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
						asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Still Food Insecure)	name(Still_FI, replace)	scale(0.8)  
						
						
			grc1leg Newly_FI Still_FI, rows(1) legendfrom(Newly_FI)	graphregion(color(white)) /*(white)*/
			graph	export	"${PSID_outRaw}/Fig_B3_FI_change_status_bygroup_E.png", replace
			graph	close
		
		restore
			
	}
	
	*	Permanent approach	
	if	`run_perm_approach'==1	{
		
		
		*	Before we conduct permanent approach, we need to test whether PFS is stationary.
		**	We reject the null hypothesis that all panels have unit roots.
		if	`test_stationary'==1	{
			xtunitroot fisher	ratio_foodexp_TFP if ${study_sample}==1 ,	dfuller lags(0)	//	no-trend
		}
		
		*cap	drop	E_normal
		cap	drop	SFIG
		cap	drop	E_mean
		cap	drop	E_total
		cap	drop	E_threshold_total
		cap	drop	E_mean_normal
		cap	drop	E_threshold_mean
		cap	drop	E_normal_mean
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
		*gen E_normal	=.
		
		*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at household-level.
		*	Since households have different number of non-missing PFS and our cut-off probability varies over time, we cannot simply use "mean" function.
		*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
		
		*	Aggregate PFS over time (numerator)
		bys	fam_ID_1999:	egen	E_total	=	total(ratio_foodexp_TFP)	if	inrange(year,2,10)
		
		*	Aggregate cut-off PFS over time. To add only the years with non-missing PFS, we replace the cut-off PFS of missing PFS years as missing.
		replace	E_threshold=.	if	mi(ratio_foodexp_TFP)
		bys	fam_ID_1999:	egen	E_threshold_total	=	total(E_threshold)	if	inrange(year,2,10)
		
		*	Generate (normalized) mean-E by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
		gen	E_mean_normal	=	E_total	/	E_threshold_total
		
		*	Construct FIG and SFIG
		cap	drop	FIG_indiv
		cap	drop	SFIG_indiv
		gen	FIG_indiv=.
		gen	SFIG_indiv	=.
				
			
			cap	drop	E_normal
			gen E_normal	=.
				
				
			*	Normalized E (E/threshold E)	(Eit/E_underbar_t)
			replace	E_normal	=	ratio_foodexp_TFP	/	E_threshold
			
			*	Inner term of the food securit gap (FIG) and the squared food insecurity gap (SFIG)
			replace	FIG_indiv	=	(1-E_normal)^1	if	!mi(E_normal)	&	E_normal<1	//	ratio_foodexp_TFP<E_threshold
			replace	FIG_indiv	=	0				if	!mi(E_normal)	&	E_normal>=1	//	ratio_foodexp_TFP>=E_threshold
			replace	SFIG_indiv	=	(1-E_normal)^2	if	!mi(E_normal)	&	E_normal<1	//	ratio_foodexp_TFP<E_threshold
			replace	SFIG_indiv	=	0				if	!mi(E_normal)	&	E_normal>=1	//	ratio_foodexp_TFP>=E_threshold
		
			
		*	Total, Transient and Chronic FI

		
			*	Total FI	(Average SFIG over time)
			bys	fam_ID_1999:	egen	Total_FI_HCR	=	mean(E_FI)	if	inrange(year,2,10)	//	HCR
			bys	fam_ID_1999:	egen	Total_FI_SFIG	=	mean(SFIG_indiv)	if	inrange(year,2,10)	//	SFIG
			
			label	var	Total_FI_HCR	"TFI (HCR)"
			label	var	Total_FI_SFIG	"TFI (SFIG)"

			*	Chronic FI (SFIG(with mean E))					
			gen		Chronic_FI_HCR=.
			gen		Chronic_FI_SFIG=.
			replace	Chronic_FI_HCR	=	(1-E_mean_normal)^0	if	!mi(E_mean_normal)	&	E_mean_normal<1		//	Avg E < Avg cut-off E
			replace	Chronic_FI_SFIG	=	(1-E_mean_normal)^2	if	!mi(E_mean_normal)	&	E_mean_normal<1		//	Avg E < Avg cut-off E
			replace	Chronic_FI_HCR	=	0					if	!mi(E_mean_normal)	&	E_mean_normal>=1	//	Avg E >= Avg cut-off E (thus zero CFI)
			replace	Chronic_FI_SFIG	=	0					if	!mi(E_mean_normal)	&	E_mean_normal>=1	//	Avg E >= Avg cut-off E (thus zero CFI)
			
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
			
			**	For now we include households with 5+ E.
			cap	drop	num_nonmissing_E
			cap	drop	dyn_sample
			bys fam_ID_1999: egen num_nonmissing_E=count(ratio_foodexp_TFP)
			gen	dyn_sample=1	if	num_nonmissing_E>=5	&	inrange(year,2,10)
			
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
			bys fam_ID_1999: egen tempyear = min(year) if (${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1 & mi(highdegree_NoHS_2001))

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
				svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	& ${nonmissing_TFI_CFI} 	&	dyn_sample==1 ):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_all	=	e(b)[1,2]/e(b)[1,1]
				*scalar	samplesize_all	=	e(N_sub)
				mat	perm_stat_2000_all	=	e(N_sub),	e(b), prop_trans_all
				
				*	Gender
				svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	gender_head_fam_enum2==1):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_male	=	e(b)[1,2]/e(b)[1,1]
				mat	perm_stat_2000_male	=	e(N_sub),	e(b), prop_trans_male
				
				svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1 	&	HH_female==1):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
				scalar	prop_trans_female	=	e(b)[1,2]/e(b)[1,1]
				mat	perm_stat_2000_female	=	e(N_sub),	e(b), prop_trans_female
				
				mat	perm_stat_2000_gender	=	perm_stat_2000_male	\	perm_stat_2000_female
				
				*	Race
				foreach	type	in	1	0	{
					
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	HH_race_white==`type'):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_race_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_race_`type'	=	e(N_sub),	e(b), prop_trans_race_`type'
					
				}
				
				mat	perm_stat_2000_race	=	perm_stat_2000_race_1	\	perm_stat_2000_race_0

				*	Region (based on John's suggestion)
				foreach	type	in	NE	MidAt South MidWest West	{
					
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	state_group_`type'==1	):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_region_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_region_`type'	=	e(N_sub),	e(b), prop_trans_region_`type'
					
				}
			
				mat	perm_stat_2000_region	=	perm_stat_2000_region_NE	\	perm_stat_2000_region_MidAt	\	perm_stat_2000_region_South	\	///
												perm_stat_2000_region_MidWest	\	perm_stat_2000_region_West
				
				*	Metropolitan Area
				foreach	type	in	metro	nonmetro	{
					
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	resid_`type'==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_metro_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_metro_`type'	=	e(N_sub),	e(b), prop_trans_metro_`type'
					
				}
			
				mat	perm_stat_2000_metro	=	perm_stat_2000_metro_metro	\	perm_stat_2000_metro_nonmetro
				
				*	Education degree (Based on 2001 degree)
				foreach	degree	in	NoHS	HS	somecol	col	{
					
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	highdegree_`degree'_2001==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_edu_`degree'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_edu_`degree'	=	e(N_sub),	e(b), prop_trans_edu_`degree'
					
				}
				
				mat	perm_stat_2000_edu	=	perm_stat_2000_edu_NoHS	\	perm_stat_2000_edu_HS	\	perm_stat_2000_edu_somecol	\	perm_stat_2000_edu_col

				
				 *	Further decomposition
			   cap	mat	drop	perm_stat_2000_decomp_`measure'
			   cap	mat	drop	Pop_ratio
			   svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1):	///
				mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure' 
			   local	subsample_tot=e(N_subpop)		   
			   
			   foreach	race	in	 HH_race_color	HH_race_white	{	//	Black, white
					foreach	gender	in	HH_female	gender_head_fam_enum2	{	//	Female, male
						foreach	edu	in	NoHS	HS	somecol	col   	{	//	No HS, HS, some col, col
							svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1  & `gender'==1 & `race'==1 & highdegree_`edu'_2001==1): mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
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
												perm_stat_2000_edu	//	To be combined with category later.
				mat	perm_stat_2000_combined_`measure'	=	perm_stat_2000_allcat_`measure'	\	blankrow	\	blankrow	\	perm_stat_2000_decomp_`measure'

				putexcel	set "${PSID_outRaw}/perm_stat_E", sheet(perm_stat_`measure') `exceloption'
				putexcel	A3	=	matrix(perm_stat_2000_combined_`measure'), names overwritefmt nformat(number_d1)
				
				esttab matrix(perm_stat_2000_combined_`measure', fmt(%9.3f)) using "${PSID_outRaw}/Tab_6_perm_stat_`measure'_E.tex", replace	
				
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
									legend(lab (1 "Total Food Insecurity (TFI)") lab(2 "Chronic Food Insecurity (CFI)") size(vsmall) rows(1))	bar(1, fcolor(blue*0.5)) bar(2, fcolor(yellow*0.6))	graphregion(color(white)) bgcolor(white)
				graph	export	"${PSID_outRaw}/Fig_B4_TFI_CFI_bygroup_E.png", replace
				graph	close
				
					
			restore
			
			
			
			*	Categorize HH into four categories
			*	First, generate dummy whether (1) always or not-always FI (2) Never or sometimes FI
				loc	var1	E_FI_always
				loc	var2	E_FI_never
				cap	drop	`var1'
				cap	drop	`var2'
				bys	fam_ID_1999:	egen	`var1'	=	min(E_FI)	//	1 if always FI (persistently poor), 0 if sometimes FS (not persistently poor)
				bys	fam_ID_1999:	egen	`var2'	=	min(E_FS)	//	1 if never FI, 0 if sometimes FI (transient)
				replace	`var1'=.	if	year==1
				replace	`var2'=.	if	year==1
			
			local	exceloption	modify
			foreach	measure	in	HCR	SFIG	{
				
				assert	Total_FI_`measure'==0 if E_FI_never==1	//	Make sure TFI=0 when HH is always FS (E>cut-off E)
				
				*	Categorize households
				cap	drop	E_perm_FI_`measure'
				gen		E_perm_FI_`measure'=1	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	E_FI_always==1	///
					//	Persistently FI (CFI>0, always FI)
				replace	E_perm_FI_`measure'=2	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	E_FI_always==0	///
					//	Chronically but not persistently FI (CFI>0, not always FI)
				replace	E_perm_FI_`measure'=3	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	E_FI_never==0		///
					//	Transiently FI (CFI=0, not always FS)
				replace	E_perm_FI_`measure'=4	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	Total_FI_`measure'==0	///
					//	Always FS (CFI=TFI=0)
					
				label	define	E_perm_FI	1	"Persistently FI"	///
											2	"Chronically, but not persistently FI"	///
											3	"Transiently FI"	///
											4	"Never FI"	///
											,	replace
			
				label values	E_perm_FI_`measure'	E_perm_FI
				
			*	Descriptive stats
			
				*	Overall
				svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): proportion	E_perm_FI_`measure'
				mat	E_perm_FI_all	=	e(N_sub),	e(b)
				
				*	Gender
				svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	gender_head_fam_enum2):	///
					proportion E_perm_FI_`measure'
				mat	E_perm_FI_male	=	e(N_sub),	e(b)
				svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_female):	///
					proportion E_perm_FI_`measure'
				mat	E_perm_FI_female	=	e(N_sub),	e(b)
				
				mat	E_perm_FI_gender	=	E_perm_FI_male	\	E_perm_FI_female
				
			
				*	Race
				foreach	type	in	1	0	{
					
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_race_white==`type'):	///
						proportion E_perm_FI_`measure'
					mat	E_perm_FI_race_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	E_perm_FI_race	=	E_perm_FI_race_1	\	E_perm_FI_race_0
				
				*	Region
				foreach	type	in	NE	MidAt	South	MidWest West	{
					
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1):	///
						proportion E_perm_FI_`measure'
					mat	E_perm_FI_region_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	E_perm_FI_region	=	E_perm_FI_region_NE	\	E_perm_FI_region_MidAt	\	E_perm_FI_region_South	\	///
											E_perm_FI_region_MidWest	\	E_perm_FI_region_West
				
				*	Metropolitan
				foreach	type	in	metro	nonmetro	{
					
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	resid_`type'==1):	///
						proportion E_perm_FI_`measure'
					mat	E_perm_FI_metro_`type'	=	e(N_sub),	e(b)
					
				}
				
				mat	E_perm_FI_metro	=	E_perm_FI_metro_metro	\	E_perm_FI_metro_nonmetro
				
				
				*	Education
				foreach	degree	in	NoHS	HS	somecol	col	{
				    
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	highdegree_`degree'_2001==1):	///
						proportion E_perm_FI_`measure'
					mat	E_perm_FI_edu_`degree'	=	e(N_sub),	e(b)
					
				}
				mat	E_perm_FI_edu	=	E_perm_FI_edu_NoHS	\	E_perm_FI_edu_HS	\	E_perm_FI_edu_somecol	\	E_perm_FI_edu_col
				

				*	Combine results (Table 9 of 2020/11/16 draft)
				mat	define	blankrow	=	J(1,5,.)
				mat	E_perm_FI_combined_`measure'	=	E_perm_FI_all	\	blankrow	\	E_perm_FI_gender	\	blankrow	\	E_perm_FI_race	\	blankrow	\	///
														E_perm_FI_region	\	blankrow	\	E_perm_FI_metro	\	blankrow	\	E_perm_FI_edu
				
				mat	list	E_perm_FI_combined_`measure'
				
				di "excel option is `exceloption'"
				putexcel	set "${PSID_outRaw}/perm_stat", sheet(FI_perm_`measure') `exceloption'
				putexcel	A3	=	matrix(E_perm_FI_combined_`measure'), names overwritefmt nformat(number_d1)
			
				esttab matrix(E_perm_FI_combined_`measure', fmt(%9.2f)) using "${PSID_outRaw}/E_perm_FI_`measure'.tex", replace	
				
				*	Table 5 & 6 (combined) of Dec 20 draft
				mat	define Table_5_`measure'_E	=	perm_stat_2000_allcat_`measure',	E_perm_FI_combined_`measure'[.,2...]
				
				putexcel	set "${PSID_outRaw}/perm_stat_E", sheet(Table5_`measure'_E) `exceloption'
				putexcel	A3	=	matrix(Table_5_`measure'_E), names overwritefmt nformat(number_d1)
			
				esttab matrix(Table_5_`measure'_E, fmt(%9.3f)) using "${PSID_outRaw}/Tab_6_`measure'_E.tex", replace
				
				local	exceloption	modify
				
			}	//	measure
		
		*	Group State-FE of TFI and CFI		
			*	Regression of TFI/CFI on Group state FE
			
			local measure HCR
			
			foreach	depvar	in	Total_FI_`measure'	Chronic_FI_`measure'	Transient_FI_`measure'	{
				
				
				*	Without controls/time FE
				qui	svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' ${regionvars}
				est	store	`depvar'_nocontrols
				
				
				*	With controls/time FE
				qui	svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' ${regionvars}	///
					${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}
				est	store	`depvar'
			}
			
			*	Output
			esttab	Total_FI_`measure'_nocontrols	Chronic_FI_`measure'_nocontrols	Transient_FI_`measure'_nocontrols Total_FI_`measure'	Chronic_FI_`measure'	Transient_FI_`measure'	using "${PSID_outRaw}/TFI_CFI_regression_E.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Regression of TFI/CFI on Characteristics) 	///
					addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
					replace
					
			esttab	Total_FI_`measure'	Chronic_FI_`measure'		using "${PSID_outRaw}/TFI_CFI_regression_E.tex", ///
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
									if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head	mental_problem no_longer_employed	no_longer_married	no_longer_own_house	became_disabled) 
					
					mat	`depvar'_shapley_indiv	=	e(shapley),	e(shapley_rel)
					mata : st_matrix("`depvar'_shapley_sum", colsum(st_matrix("`depvar'_shapley_indiv")))
					
					mat	`depvar'_shapley	=	`depvar'_shapley_indiv	\	`depvar'_shapley_sum
					
					
					*	Survey-adjusted
					cap	drop	_mysample
					svy, subpop(if ${study_sample} &	!mi(ratio_foodexp_TFP)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1):	///
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
			
			putexcel	set "${PSID_outRaw}/perm_stat_E", sheet(shapley) /*replace*/	modify
			putexcel	A3	=	matrix(TFI_CFI_`measure'_shapley), names overwritefmt nformat(number_d1)
			
			esttab matrix(TFI_CFI_`measure'_shapley, fmt(%9.3f)) using "${PSID_outRaw}/Tab_7_TFI_CFI_`measure'_shapley_E.tex", replace	
		

				
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
				graph	export	"${PSID_outRaw}/TFI_CFI_`measure'_groupstateFE_All_nocontrol_E.png", replace
				graph	close
				
		coefplot	(Total_FI_`measure', mcolor(blue*0.5) msymbol(diamond))	(Chronic_FI_`measure', mcolor(green*0.6)	msymbol(circle)), 	///
					keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)	///
					xline(0)	graphregion(color(white)) bgcolor(white)	legend(lab (2 "TFI") lab(4 "CFI") rows(1))	name(TFI_CFI_FE_All, replace)	ylabel(,labsize(small))	/*xscale(range(-0.05(0.05) 0.10))*/
				graph	export	"${PSID_outRaw}/Fig_B5_TFI_CFI_`measure'_groupstateFE_All_E.png", replace
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
		global	nonmissing_FGT	!mi(E_FI) & !mi(FIG_indiv) & !mi(SFIG_indiv)
					
		
		
		*	Aggregate over households to generate population-level statistics
		*	Input for Figure 2 (Food Security Status by Group) in Dec 2020 draft.
			* Graph can be found in "FGT_year" sheet in "Min_report" Excel file
		
		foreach	group	in	all	male	female	white	black	other	NoHS	HS	somecol	col	NE	MidAt	South	MidWest	West metro nonmetro	{
			cap	mat	drop	sampleno_`group'	HCR_`group'	FIG_`group'	SFIG_`group'
		}
		
		
			*	Yearly decomposition
			forval	year=2/10	{
				
				
				*	Overall
					
				svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& year==`year'): mean E_FI FIG_indiv	SFIG_indiv
				mat	sampleno_all	=	nullmat(HCR_all),	e(N_sub)
				mat	HCR_all			=	nullmat(HCR_all),	e(b)[1,1]
				mat	FIG_all			=	nullmat(FIG_all),	e(b)[1,2]
				mat	SFIG_all		=	nullmat(SFIG_all),	e(b)[1,3]

				*	Gender
					
					*	Male
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	&	${nonmissing_FGT} & HH_female==0	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_male	=	nullmat(sampleno_male),	e(N_sub)
					mat	HCR_male		=	nullmat(HCR_male),	e(b)[1,1]
					mat	FIG_male		=	nullmat(FIG_male),	e(b)[1,2]
					mat	SFIG_male		=	nullmat(SFIG_male),	e(b)[1,3]
					
					*	Female
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	&	${nonmissing_FGT} & HH_female==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_female	=	nullmat(sampleno_female),	e(N_sub)
					mat	HCR_female		=	nullmat(HCR_female),	e(b)[1,1]
					mat	FIG_female		=	nullmat(FIG_female),	e(b)[1,2]
					mat	SFIG_female		=	nullmat(SFIG_female),	e(b)[1,3]
					
				*	Race
				  
					*	White
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_white==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_white	=	nullmat(sampleno_white),	e(N_sub)
					mat	HCR_white		=	nullmat(HCR_white),	e(b)[1,1]
					mat	FIG_white		=	nullmat(FIG_white),	e(b)[1,2]
					mat	SFIG_white		=	nullmat(SFIG_white),	e(b)[1,3]
					
					*	Black
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_black==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_black	=	nullmat(sampleno_black),	e(N_sub)
					mat	HCR_black		=	nullmat(HCR_black),	e(b)[1,1]
					mat	FIG_black		=	nullmat(FIG_black),	e(b)[1,2]
					mat	SFIG_black		=	nullmat(SFIG_black),	e(b)[1,3]
					
					*	Other
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_other==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_other	=	nullmat(sampleno_other),	e(N_sub)
					mat	HCR_other		=	nullmat(HCR_other),	e(b)[1,1]
					mat	FIG_other		=	nullmat(FIG_other),	e(b)[1,2]
					mat	SFIG_other		=	nullmat(SFIG_other),	e(b)[1,3]	
					
				*	Education
				
					*	Less than High School
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_NoHS==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_NoHS	=	nullmat(sampleno_NoHS),	e(N_sub)
					mat	HCR_NoHS		=	nullmat(HCR_NoHS),	e(b)[1,1]
					mat	FIG_NoHS		=	nullmat(FIG_NoHS),	e(b)[1,2]
					mat	SFIG_NoHS		=	nullmat(SFIG_NoHS),	e(b)[1,3]
					
					*	High School
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_HS==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_HS	=	nullmat(sampleno_HS),	e(N_sub)
					mat	HCR_HS		=	nullmat(HCR_HS),	e(b)[1,1]
					mat	FIG_HS		=	nullmat(FIG_HS),	e(b)[1,2]
					mat	SFIG_HS		=	nullmat(SFIG_HS),	e(b)[1,3]
					
					*	Some College
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_somecol==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_somecol	=	nullmat(sampleno_somecol),	e(N_sub)
					mat	HCR_somecol		=	nullmat(HCR_somecol),	e(b)[1,1]
					mat	FIG_somecol		=	nullmat(FIG_somecol),	e(b)[1,2]
					mat	SFIG_somecol		=	nullmat(SFIG_somecol),	e(b)[1,3]
					
					*	College
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_col==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_col	=	nullmat(sampleno_col),	e(N_sub)
					mat	HCR_col		=	nullmat(HCR_col),	e(b)[1,1]
					mat	FIG_col		=	nullmat(FIG_col),	e(b)[1,2]
					mat	SFIG_col		=	nullmat(SFIG_col),	e(b)[1,3]
				
				*	Region (based on John's suggestion)
					
					foreach	stategroup	in	NE	MidAt	South	MidWest	West	{
						
						svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& state_group_`stategroup'==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
						mat	sampleno_`stategroup'	=	nullmat(sampleno_`stategroup'),	e(N_sub)
						mat	HCR_`stategroup'		=	nullmat(HCR_`stategroup'),	e(b)[1,1]
						mat	FIG_`stategroup'		=	nullmat(FIG_`stategroup'),	e(b)[1,2]
						mat	SFIG_`stategroup'		=	nullmat(SFIG_`stategroup'),	e(b)[1,3]
						
					}
					
					
				*	Metropolitan Area
				 
					*	Metro
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& resid_metro==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
					mat	sampleno_metro	=	nullmat(sampleno_metro),	e(N_sub)
					mat	HCR_metro		=	nullmat(HCR_metro),	e(b)[1,1]
					mat	FIG_metro		=	nullmat(FIG_metro),	e(b)[1,2]
					mat	SFIG_metro		=	nullmat(SFIG_metro),	e(b)[1,3]
					
					*	Non-metro
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& resid_nonmetro==1	&	year==`year'): mean E_FI FIG_indiv	SFIG_indiv
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
			
			putexcel	set "${PSID_outRaw}/FGT_bygroup_E", sheet(year) replace	/*modify*/
			putexcel	A3	=	matrix(FGT_year_combined), names overwritefmt nformat(number_d1)
			
			*esttab matrix(perm_stat_2000_combined, fmt(%9.4f)) using "${PSID_outRaw}/perm_stat_combined.tex", replace
			
		   *	Categorical decomposition
		   *	Input for Figure 3 in Dec 2020 draft (Food Insecurity Prevalence and Severity by Group).
			*	Data and Graph can be found in "FGT_group" sheet in "Min_report" Excel file.
		  
		   *	Generate group-level aggregates.
		   *	We need to do it twice - one for main graph and one for supplement graph. The latter use more detailed educational category.
		   
		   *	Total population size, which is needed to get the share of each sub-group population to total population later
			qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT}): mean E_FI FIG_indiv	SFIG_indiv
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
								mean E_FI FIG_indiv	SFIG_indiv
							
							local	Pop_ratio_all	=	e(N_subpop)/`sample_popsize_total'	//	Share of sub-group pop to total pop.
							mat		Pop_ratio_all	=	nullmat(Pop_ratio_all)	\	`Pop_ratio_all'
							mat	HCR_cat			=	nullmat(HCR_cat)	\	e(b)[1,1]
							mat	FIG_cat			=	nullmat(FIG_cat)	\	e(b)[1,2]
							mat	SFIG_cat		=	nullmat(SFIG_cat)	\	e(b)[1,3]
							
							*	Weighted average for stacked bar graph, by year					
							
							forval	year=2/10	{
								
								*	Generate population size estimate of the sample, which will be used to calculate weighted average.
								qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT} & year==`year'): mean E_FI FIG_indiv	SFIG_indiv
								local	sample_popsize_year=e(N_subpop)
								
								*	Estimate FGT measures
								qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'	&	year==`year'):	///
									mean E_FI FIG_indiv	SFIG_indiv
									
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
								mean E_FI FIG_indiv	SFIG_indiv
							
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
				
			   
				putexcel	set "${PSID_outRaw}/FGT_bygroup_E", sheet(categorical) /*replace*/	modify
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
											13	"Sol/NonWhite/Female (0.9%)"		14	"Col/NonWhite/Male (2.2%)"		15	"Col/White/Female (4.4%)"		16	"Col/White/Male (29.2%)",	replace
				label	values	fig7_cat	fig7_cat
				
				
				*	Generate category variable for Fig 8 and A5
				
				
				svmat	FGT_cat_combined_sup
				rename	FGT_cat_combined_sup?	(pop_ratio	HCR	FIG	SFIG)
				
				*	Figure 7	(Food Insecurity Prevalence and Severity by Group)
				graph hbar HCR SFIG, over(fig7_cat, sort(HCR) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "HCR") lab(2 "SFIG") size(small) rows(1))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(yellow*0.6))	graphregion(color(white)) bgcolor(white)
				graph	export	"${PSID_outRaw}/Fig_B6_FGT_group_decomposition_E.png", replace
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
							
				*	Figure 8 (Food Security Status By Group and Yea)
				grc1leg Fig8_HCR Fig8_SFIG, rows(2) legendfrom(Fig8_HCR)	graphregion(color(white)) /*(white)*/
				graph	export	"${PSID_outRaw}/Fig_B7_FGT_group_change_E.png", replace
				graph	close
				
				
				*	Figure A5	(Food Insecurity Status (FIG) by Group and Year)
				graph bar FIG_weight_cat_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))	ylabel(0(.025)0.1)*/	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
							asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	/*title((b) By Group and Year)*/	name(FigA5_b, replace) scale(0.8) 
				graph	export	"${PSID_outRaw}/Fig_A5_FGT_group_change_FIG_E.png", replace
				graph	close
							
			restore
				
				
		*	Food Security Prevalence over different groups	(Table 8)
		cap	mat	drop	HCR_group_PFS_3 HCR_group_PFS_7 HCR_group_PFS_10 HCR_group_PFS_all

		
		foreach year in	3	7	10	{	// 2003, 2011, 2017
		   foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
				foreach	race	in	0	1	{	//	People of colors, white
					foreach	gender	in	1	0	{	//	Female, male
							
					*	FS prevalence
							
					qui svy, subpop(if ${study_sample} & year==`year'	&	HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	mean E_FI 
							
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
		   		
			qui svy, subpop(if ${study_sample} & year==`year'):	mean E_FI 
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
		
		putexcel	set "${PSID_outRaw}/FGT_bygroup_E", sheet(HCR_desc) /*replace*/	modify
		putexcel	A3	=	matrix(HCR_group_PFS_all), names overwritefmt nformat(number_d1)
		//putexcel	F3	=	matrix(HCR_group_HFSM_all), names overwritefmt nformat(number_d1)
			
		esttab matrix(HCR_group_PFS_all, fmt(%9.2f)) using "${PSID_outRaw}/Tab_8_HCR_prepost_E.tex", replace
		
	}
				
