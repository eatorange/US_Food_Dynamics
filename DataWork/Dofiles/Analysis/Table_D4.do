	
	*	The following do-file replicates the following table/figure
	
		*	Table D4 - Estimates of Annual per capita Food Expenditure
		*	Figure D1: Probability Thresholds for being Food Secure
		
	
	use	"${FSD_dtFin}/fs_const_long.dta", clear


	*	Table 4: Estimates of Annual per capita Food Expenditure
	
		local	depvar		food_exp_stamp_pc

		*	Model selection (highest order)
		cap	drop	glm_order2	glm_order3	glm_order4	glm_order5
			local	depvar		food_exp_stamp_pc
			local	statevars	lag_food_exp_stamp_pc_1
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars', family(gamma)	link(log)
			estadd scalar	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct bic
			est	sto	glm_step1_order1
			
			local	statevars	lag_food_exp_stamp_pc_1	lag_food_exp_stamp_pc_2
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars'	, family(gamma)	link(log)
			estadd scalar 	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct bic
			est	sto	glm_step1_order2
			predict glm_order2	if	e(sample)==1 & `=e(subpop)'
			
			local	statevars	lag_food_exp_stamp_pc_1 lag_food_exp_stamp_pc_2	lag_food_exp_stamp_pc_th_3 // lag_food_exp_stamp_pc_th_1-lag_food_exp_stamp_pc_th_3
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars'	, family(gamma)	link(log)
			estadd scalar 	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct aic
			est	sto	glm_step1_order3
			predict glm_order3	if	e(sample)==1 & `=e(subpop)'
			
			local	statevars	lag_food_exp_stamp_pc_1 lag_food_exp_stamp_pc_2	lag_food_exp_stamp_pc_th_3	lag_food_exp_stamp_pc_th_4
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars'	, family(gamma)	link(log)
			estadd scalar	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct aic
			est	sto	glm_step1_order4
			predict glm_order4	if	e(sample)==1 & `=e(subpop)'
			
			local	statevars	lag_food_exp_stamp_pc_1 lag_food_exp_stamp_pc_2	lag_food_exp_stamp_pc_th_3	lag_food_exp_stamp_pc_th_4	lag_food_exp_stamp_pc_th_5
			svy, subpop(${study_sample}): glm 	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	`statevars'	, family(gamma)	link(log)
			estadd scalar	aic2	=	e(aic)	//	Somehow e(aic) is not properly displayed when we use "aic" directly in esttab command. So we use "aic2" to display correct aic
			estadd scalar	bic2	=	e(bic)	//	Somehow e(bic) is not properly displayed when we use "bic" directly in esttab command. So we use "bic2" to display correct aic
			est	sto	glm_step1_order5
			predict glm_order5	if	e(sample)==1 & `=e(subpop)'
			
			*	Output
			**	AER requires NOT to use asterisk(*) to display significance level, so we don't display it here
			**	We can display them by modifying some options
			
			esttab	glm_step1_order1	glm_step1_order2	glm_step1_order3	glm_step1_order4	glm_step1_order5	using "${FSD_outTab}/Tab_D4.csv", replace ///
					cells(b(nostar fmt(%8.3f)) se(fmt(3) par)) stats(N aic2 bic2, fmt(%8.0fc %8.3fc %8.3fc)) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					keep(lag_food_exp_stamp_pc_1	lag_food_exp_stamp_pc_2	lag_food_exp_stamp_pc_th_3	lag_food_exp_stamp_pc_th_4	lag_food_exp_stamp_pc_th_5)	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. )	
					
			esttab	glm_step1_order1	glm_step1_order2	glm_step1_order3	glm_step1_order4	glm_step1_order5	using "${FSD_outTab}/Tab_D4.tex", ///
					cells(b(nostar fmt(%8.3f)) se(fmt(3) par)) stats(N aic2 bic2, fmt(%8.0fc %8.3fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	///
					keep(lag_food_exp_stamp_pc_1	lag_food_exp_stamp_pc_2	lag_food_exp_stamp_pc_th_3	lag_food_exp_stamp_pc_th_4	lag_food_exp_stamp_pc_th_5)	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 2001 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor.)	///
					replace
			
		
		
	*	Figure D1
	
				*	Graph the PFS threshold for each year
			cap drop templine
			gen templine=0.6
			twoway	(connected PFS_threshold_glm year2 if fam_ID_1999==1, lpattern(dot)	mlabel(PFS_threshold_glm) mlabposition(12) mlabformat(%9.3f))	///
					(line templine year2 if fam_ID_1999==1, lpattern(dash)),	///
					/*title(Probability Threshold for being Food Secure)*/	ytitle(Probability)	xtitle(Year)	xlabel(2001(2)2017) legend(off)	///
					name(PFS_Threshold, replace)	graphregion(color(white)) bgcolor(white)
					
			graph	export	"${FSD_outFig}/Fig_D1.png", replace
			graph	close
			
			drop	templine
		