*	Appendix D: Additional Tables and Figures
	
	*	The following do-file replicates the following tables/figures in Appendix D
	
		*	Table D3 - Description of Variables and Summary Statistics
		*	Table D4 - Estimates of Annual per capita Food Expenditure
		*	Figure D1 - Probability Thresholds for being Food Secure
		*	Figure D2 - Density Estimates of Food Security Indicators
		*	Figure D3 - Predicted PFS over ages
		
	*	Some tables/figures in Appendix D are NOT replicated in this do-file. Please check the following do-files for their replication.
		
		*	Table D5: FSD_const.do, under "Construct PFS"
		*	Table D6: FSD_analyses.do, under "Perpanent Apporach"
		*	Table D7: FSD_analyses.do, under "Permanent Approach"
		*	Figure D4: FSD_analyses.do, under section "Spells Apporach"
		*	Figure D5: FSD_analyses.do, under section "Permanent Approach"
		
	
	use	"${FSD_dtFin}/FSD_const_long.dta", clear

/****************************************************************
	Section 1: Table D3 & D4
****************************************************************/
	{
		
		*	Sample information
		svy: mean  sample_source_SRC_SEO	//	Share of SRC + SEO households in entire PSID sample (93%)
		count if ${study_sample} & !mi(PFS_glm)	//	# of obs in the sample
		unique	fam_ID_1999	if	${study_sample} & !mi(PFS_glm)	//	# of households in the sample
				
		
		eststo drop	Total SRC	SEO	Imm
			
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
		local	regionvars	state_group_NE state_group_MidAt state_group_South state_group_MidWest state_group_West
		
		local	sumvars	`demovars'	`eduvars'		`empvars'	`healthvars'	`econvars'	`familyvars'		`foodvars'		`changevars'	`regionvars'	`outcomevars'	

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
			
		
		*	Output
		esttab *Total SRC SEO using "${FSD_outTab}/Tab_D3.csv", replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics)	csv 
		
		esttab *Total SRC SEO using "${FSD_outTab}/Tab_D3.tex", replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics)	tex 		
		
	
	*	Table D4: Estimates of Annual per capita Food Expenditure
	
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
			**	Some journals require NOT to use asterisk(*) to display significance level, so we don't display it here
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
			
	}
	
/****************************************************************
	Section 2: Figure D1, D2 and D3
****************************************************************/
	
		
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
			
	*	Figure D2

		*	Density Estimate of Food Security Indicator
		graph twoway 		(kdensity fs_scale_fam_rescale			if	inlist(year,2,3,9,10)	&	!mi(PFS_glm))	///
							(kdensity PFS_glm	if	inlist(year,2,3,9,10)	&	!mi(fs_scale_fam_rescale)),	///
							/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)		///
							name(thrifty, replace) graphregion(color(white)) bgcolor(white)		///
							legend(lab (1 "FSSS (rescaled)") lab(2 "PFS") rows(1))					
		graph	export	"${FSD_outFig}/Fig_D2.png", replace
		
		
		
		
		
		
	*	Figure D3: Predicted PFS over age 
			
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
				
				*	(Fig D3)
				grc1leg2		fv_age_retire_1999	fv_age_retire_2005	fv_age_retire_2011	fv_age_retire_2017,	///
								/*title(Predicted PFS over age)*/ legendfrom(fv_age_retire_1999)	///
								graphregion(color(white))	/*xtob1title	*/
								/*	note(Vertical line is the average retirement age of the year in the sample)	*/
				graph	export	"${FSD_outFig}/Fig_D3.png", replace
				graph	close
			
		
		
			
		