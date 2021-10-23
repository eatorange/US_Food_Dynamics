*	This is the do-file written to follow-up based on the AER rejection comments we received
*	Will be integrated into the main do-files once discussed.

*	Generate a ratio variable E* = food exp/TFP
 include	"${PSID_doAnl}/Macros_for_analyses.do"
use	"${PSID_dtFin}/fs_const_long.dta", clear
cap	drop	ratio_foodexp_TFP
gen	ratio_foodexp_TFP	=	food_exp_stamp_pc	/	foodexp_W_thrifty
summ ratio_foodexp_TFP,d
label variable	ratio_foodexp_TFP	"(Food exp/TFP) ratio"

*	Rank correlation between HFSM and PFS/E

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
		
		
		
	*	Generate an indicator that E*<1
	cap	drop	E_below_1
	gen		E_below_1	=	.
	replace	E_below_1	=	1	if	!mi(ratio_foodexp_TFP)	&	ratio_foodexp_TFP<1
	replace	E_below_1	=	0	if	!mi(ratio_foodexp_TFP)	&	ratio_foodexp_TFP>=1
	label	var	E_below_1	"=1 if food exp is less than TFP"
	
	*	Prevalence over time
	preserve
		collapse	fs_cat_IS	PFS_FI_glm	E_below_1 if ${study_sample}	 [aweight=weight_multi12], by(year2)
		graph	twoway	(bar fs_cat_IS year2)	///
						(connected PFS_FI_glm	year2)	///
						(connected E_below_1	year2),	///
						title(Prevalence of HFSM FI and E<1) ytitle(Percentage)	///
						legend(order(1 "HFSM FI"	2	"PFS FI" 3	"E=(foodexp/TFP)<1"	) rows(1))	
		graph	export	"${PSID_outRaw}/Prevalence_FI_E_threshold.png", replace
		graph	close
	restore	
		

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
	
	
	cap	drop	HFSM_PFS_available_years
	gen		HFSM_PFS_available_years=0
	replace	HFSM_PFS_available_years=1	if	inlist(year,2,3,9,10)
	
	
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