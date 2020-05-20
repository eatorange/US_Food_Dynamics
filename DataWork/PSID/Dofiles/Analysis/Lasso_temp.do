	*	Recode nonresponses (dk, refuse, inappropriate) as "negative"
	label	define	yes1no0	0	"No"	1	"Yes"
	local	recode_vars	1
	if	`recode_vars'==1	{
		qui	ds	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse	veteran_head	veteran_spouse	tax_item_deduct	///
				retire_plan_head	retire_plan_spouse	annuities_IRA	attend_college_head	attend_college_spouse	hs_completed_head	hs_completed_spouse	///
				college_completed	college_comp_spouse	other_degree_head	other_degree_spouse	food_stamp_used_1yr	child_meal_assist	WIC_received_last	elderly_meal	///
				child_daycare_any	child_daycare_FSP	child_daycare_snack	
		label values	`r(varlist)'	yes1no0
		recode	`r(varlist)'	(0	5	8	9	.d	.r=0)
	}

*	Random Forest (using "rforest")


		*	RF	(when "0" implies "no". Should yield the same result to the previous coding which "5" implies "no")
		local	statevars	lag_avg_foodexp_pc_1-lag_avg_foodexp_pc_5	//	up to the order of 5
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse
		local	demovars	age_head_fam	age_head_fam_sq	race_head_cat_enum1-race_head_cat_enum3	marital_status_fam_enum1-marital_status_fam_enum5	///
							gender_head_fam_enum1-gender_head_fam_enum2	state_resid_fam_enum1-state_resid_fam_enum52	age_spouse	age_spouse_sq	///
							housing_status_enum1-housing_status_enum3	veteran_head veteran_spouse
		local	econvars	avg_income_pc	avg_income_pc_sq	avg_wealth_pc	avg_wealth_pc_sq	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam num_child_fam	family_comp_change_enum1-family_comp_change_enum9	couple_status_enum1-couple_status_enum5	head_status spouse_new
		local	eduvars		attend_college_head attend_college_spouse	college_yrs_head college_yrs_spouse	///
							hs_completed_head	college_completed	other_degree_head	edu_years_head_fam	///
							hs_completed_head_interact college_completed_interact other_degree_head_interact	///
							hs_completed_spouse	college_comp_spouse	other_degree_spouse	edu_years_spouse	///
							hs_completed_spouse_interact college_comp_spouse_interact other_degree_spouse_interact
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	meal_together	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		
	

	
	/*
	local	indepvars	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`childvars'
	local numvars : list sizeof	indepvars
	macro list _numvars
	*/

	*	Construct C&B Measure
	
	
		
		*	Validation
	
	
	*	Check the ratio of food security category of the validation year (2017)
	svy: proportion fs_cat_fam_simp if out_of_sample==1
	local	prop_insecure	=	round(e(b)[1,1]*1000)
	local	prop_secure	=	`prop_insecure'+1
	di "`prop_insecure' and `prop_secure'"
	* among the reduced sample (_N=2,877), 87.60% are “high food security”, “12.40% are food insecurity"
	* We will use this cutoff to validate performance


	foreach	plan	in	thrifty low moderate liberal	{
		
		
		xtile `plan'_pctile_rf = rho1_avg_foodexp_pc_`plan'_rf if !mi(rho1_avg_foodexp_pc_`plan'_rf), nq(1000)
			
		gen		rho1_`plan'_IS_rf	=	0	if	!mi(rho1_avg_foodexp_pc_`plan'_rf)
		replace	rho1_`plan'_IS_rf	=	1	if	inrange(`plan'_pctile_rf,1,`prop_insecure')	//	Food insecure
		
		/*
		gen		rho1_`plan'_MS	=	0	if	!mi(rho1_avg_foodexp_pc_`plan')
		replace	rho1_`plan'_MS	=	1	if	inrange(`plan'_pctile,42,100)	//	Marginal food secure
		*/
		
		gen		rho1_`plan'_HS_rf	=	0	if	!mi(rho1_avg_foodexp_pc_`plan'_rf)
		replace	rho1_`plan'_HS_rf	=	1	if	inrange(`plan'_pctile_rf,`prop_secure',1000)	//	Highly secure
		
	}

	svy: tab rho1_thrifty_HS_rf fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_rf), cell
	svy: tab rho1_low_HS_rf fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_low_rf), cell
	svy: tab rho1_moderate_HS_rf fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_moderate_rf), cell
	svy: tab rho1_liberal_HS_rf fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal_rf), cell


	svy: tab rho1_liberal_HS_rf fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal_rf) & sample_source==1, cell
	svy: tab rho1_liberal_HS_rf fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal_rf) & sample_source==2, cell
	svy: tab rho1_liberal_HS_rf fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal_rf) & sample_source==3, cell

	*graph twoway (kdensity fs_scale_fam)	(kdensity	reverse_RS), title(Distribution of USDA Measure) name(fs_scale, replace)	
							


							
	*	OLS
	local	run_ols	1
	if	`run_ols'==1	{
		
		*	Declare variables
		local	depvar	avg_foodexp_pc
		local	statevars	lag_avg_foodexp_pc_1-lag_avg_foodexp_pc_5
		local	demovars	c.age_head_fam##c.age_head_fam	ib1.race_head_cat	ib2.marital_status_fam	ib1.gender_head_fam	ib0.state_resid_fam	
		local	econvars	c.avg_income_pc##c.avg_income_pc
		local	empvars		emp_HH_simple
		local	familyvars	num_FU_fam num_child_fam	ib0.family_comp_change	ib5.couple_status
		local	eduvars		attend_college_head college_yrs_head college_yrs_spouse	(hs_completed_head	college_completed	other_degree_head)##c.edu_years_head_fam	
		local	foodvars	food_stamp_used_1yr	child_meal_assist ib5.WIC_received_last	meal_together	elderly_meal
		
		*	Step 1

		svy: reg	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	if	in_sample==1
		*svy: glm 	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	if	in_sample==1, family(gamma)	link(log)
		est	sto	ols_step1
					
		gen	ols_step1_sample=1	if	e(sample)==1
		
		predict double mean1_avgfoodexp_ols
		predict double e1_avgfoodexp_ols, r
		gen e1_avgfoodexp_sq_ols = (e1_avgfoodexp_ols)^2
		
		*	Step 2
		*svy: glm `depvar' `statevars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	if	classic_step1_sample==1, family(gamma) 
		svy: reg `depvar' `statevars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	if	ols_step1_sample==1
		gen	ols_step2_sample=1	if	e(sample)==1
		*svy:	reg `e(depvar)' `e(selected)'
		predict	double	var1_avgfoodexp_ols
		est store ols_step2
		
		*	Step 3
		*	Assume the outcome variable follows the Gamma distribution
		gen alpha1_avg_foodexp_pc_ols = (mean1_avgfoodexp_ols)^2 / var1_avgfoodexp_ols	//	shape parameter of Gamma (alpha)
		gen beta1_avg_foodexp_pc_ols = var1_avgfoodexp_ols / mean1_avgfoodexp_ols	//	scale parameter of Gamma (beta)
		
		*	Construct CDF
		foreach	plan	in	thrifty low moderate liberal	{
			
			*	Generate resilience score. 
			*	Should include in-sample as well as out-of-sample to validate its OOS performance
			gen rho1_avg_foodexp_pc_`plan'_ols = gammaptail(alpha1_avg_foodexp_pc_ols, avg_foodexp_W_`plan'/beta1_avg_foodexp_pc_ols)	/*if	(lasso_step1_sample==1)	&	(lasso_step2_sample==1)*/	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
			label	var	rho1_avg_foodexp_pc_`plan'_ols "Resilience score (LASSO), `plan' plan"
		
		}
	}
	
	*	Validation
	*	Check the ratio of food security category of the validation year (2017)
	svy: proportion fs_cat_fam_simp if out_of_sample==1
	local	prop_insecure	=	round(e(b)[1,1]*1000)
	local	prop_secure	=	`prop_insecure'+1
	di "`prop_insecure' and `prop_secure'"
	* among the reduced sample (_N=2,877), 87.60% are “high food security”, “12.40% are food insecurity"
	* We will use this cutoff to validate performance


	foreach	plan	in	thrifty low moderate liberal	{
		
		
		xtile `plan'_pctile_ols = rho1_avg_foodexp_pc_`plan'_ols if !mi(rho1_avg_foodexp_pc_`plan'_ols), nq(1000)
			
		gen		rho1_`plan'_IS_ols	=	0	if	!mi(rho1_avg_foodexp_pc_`plan'_ols)
		replace	rho1_`plan'_IS_ols	=	1	if	inrange(`plan'_pctile_ols,1,`prop_insecure')	//	Food insecure
		
		/*
		gen		rho1_`plan'_MS	=	0	if	!mi(rho1_avg_foodexp_pc_`plan')
		replace	rho1_`plan'_MS	=	1	if	inrange(`plan'_pctile,42,100)	//	Marginal food secure
		*/
		
		gen		rho1_`plan'_HS_ols	=	0	if	!mi(rho1_avg_foodexp_pc_`plan'_ols)
		replace	rho1_`plan'_HS_ols	=	1	if	inrange(`plan'_pctile_ols,`prop_secure',1000)	//	Highly secure
		
	}

	svy: tab rho1_thrifty_HS_ols	fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_ls), cell
	svy: tab rho1_low_HS_ols 		fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_low_ls), cell
	svy: tab rho1_moderate_HS_ols	fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_moderate_ls), cell
	svy: tab rho1_liberal_HS_ols	fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal_ls), cell


	svy: tab rho1_liberal_HS_ols fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_ols) & sample_source==1, cell
	svy: tab rho1_liberal_HS_ols fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_ols) & sample_source==2, cell
	svy: tab rho1_liberal_HS_ols fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_ols) & sample_source==3, cell



****** cvlasso does not generate e(selected) macro, which has the list of the seletected variables.
****** For now, we need to "manually" type the list of selected variables from the result. Need to contact the authors for more information.
/*


loc	selectedvars	cl.avg_foodexp_pc cl.avg_foodexp_pc#cl.avg_foodexp_pc c.respondent_BMI i1b5.alcohol_spouse c.age_head_fam i(19 20 26 27 28 31 35 39 48)b0.state_resid_fam c.age_spouse i9b5.veteran_spouse c.avg_income_pc c.avg_wealth_pc ///
					ib5.retire_plan_head i1b5.emp_HH_simple i1b5.emp_spouse_simple num_FU_fam	ib0.family_comp_change	i1b5.hs_completed_head (i9b5.other_degree_spouse)##c.edu_years_spouse ib5.food_stamp_used_1yr	i0b5.WIC_received_last	///
					ib5.child_daycare_any	i8b5.child_daycare_snack

*	Step 1
svy: reg avg_foodexp_pc `selectedvars'	if	cvlass_sample==1	
	
est sto mean1_avg_foodexp_pc
	
predict double mean2_avgfoodexp, xb
predict double e2_avgfoodexp, r


*	Step 2
gen e2_avgfoodexp_sq = e2_avgfoodexp^2

svy: reg e2_avgfoodexp_sq `selectedvars'	if	cvlass_sample==1	


predict	double	var2_avgfoodexp, xb

*	Step 3

gen alpha1_avg_foodexp_pc = mean2_avgfoodexp^2 / var2_avgfoodexp	//	shape parameter of Gamma (alpha)
gen beta1_avg_foodexp_pc = var2_avgfoodexp / mean2_avgfoodexp	//	scale parameter of Gamma (beta)
foreach	plan	in	thrifty low moderate liberal	{
	gen rho1_avg_foodexp_pc_`plan' = gammaptail(alpha1_avg_foodexp_pc, avg_foodexp_W_`plan'/beta1_avg_foodexp_pc)	if	(cvlass_sample==1)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
	label	var	rho1_avg_foodexp_pc_`plan' "Resilience score, `plan' plan"
}



		

/*
** Testing estimability of margin.
svy: reg avg_foodexp_pc cl.avg_foodexp_pc cl.avg_foodexp_pc#cl.avg_foodexp_pc c.respondent_BMI c.age_head_fam c.age_spouse i0b5.WIC_received_last // i1b5.alcohol_spouse
margins, dydx(cl.avg_foodexp_pc) emptycells(reweight)


dataex fam_ID_1999 year ER31996 ER31997  avg_foodexp_pc  respondent_BMI age_head_fam WIC_received_last in 1/30


/*
margins, dydx(cl.avg_childexp_pc) /*at( mpg=(10(5)40) foreign = (0 1))*/ atmeans post
marginsplot, noci
*/


* Import food price

** Temporary code for merging price data. This code should be moved to "construct" do file later
tempfile temp
save	`temp'

*	clean food price data
import excel "E:\Box\US Food Security Dynamics\DataWork\USDA\Food Plans_Cost of Food Reports.xlsx", sheet("food_cost_month") firstrow clear
recode year /*(2014=2015) (2016=2017)*/ (2014=9) (2016=10)
	
	*	calculate adult expenditure by average male and female
	foreach	plan	in	thrifty low moderate liberal	{
	    egen	adult_`plan'	=	rowmean(male_`plan' female_`plan')
	}
tempfile monthly_foodprice
save 	`monthly_foodprice'

*	Merge food price data into the main data
use	`temp', clear
use `temp', clear
merge m:1 year using `monthly_foodprice', assert(1	3) nogen

*	Calculate annual household food expenditure per each 
	
	*	Yearly food expenditure = monthly food expenditure * 12
	*	Monthly food expenditure is calculated by the (# of children * children cost) + (# of adult * adult cost)
	foreach	plan	in	thrifty low moderate liberal	{
		
		*	Unadjusted
		gen	double	foodexp_W_`plan'	=	((num_child_fam*child_`plan')	+	((num_FU_fam-num_child_fam)*adult_`plan'))*12
		
		*	Adjust by the number of families
		replace	foodexp_W_`plan'	=	foodexp_W_`plan'*1.2	if	num_FU_fam==1	//	1 person family
		replace	foodexp_W_`plan'	=	foodexp_W_`plan'*1.1	if	num_FU_fam==2	//	2 people family
		replace	foodexp_W_`plan'	=	foodexp_W_`plan'*1.05	if	num_FU_fam==3	//	3 people family
		replace	foodexp_W_`plan'	=	foodexp_W_`plan'*0.95	if	inlist(num_FU_fam,5,6)	//	5-6 people family
		replace	foodexp_W_`plan'	=	foodexp_W_`plan'*0.90	if	num_FU_fam>=7	//	7+ people family
		
		*	Divide by the number of families to get the threshold value(W) per capita
		replace	foodexp_W_`plan'	=	foodexp_W_`plan'/num_FU_fam
		
		*	Get the average value per capita
		sort	fam_ID_1999	year
		gen	avg_foodexp_W_`plan'	=	(foodexp_W_`plan'+l.foodexp_W_`plan')/2
	}

tempfile temp2
save `temp2'



	*	Recoding variables
	
		*	Recode nonresponses (dk, refuse, inappropriate) as "negative"
		***	"5" implies "no"
	local	recode_vars	1
	if	`recode_vars'==1	{
		qui	ds	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse	veteran_head	veteran_spouse	tax_item_deduct	///
				retire_plan_head	retire_plan_spouse	annuities_IRA	attend_college_head	attend_college_spouse	hs_completed_head	hs_completed_spouse	///
				college_completed	college_comp_spouse	other_degree_head	other_degree_spouse	food_stamp_used_1yr	child_meal_assist	WIC_received_last	elderly_meal	///
				child_daycare_any	child_daycare_FSP	child_daycare_snack	
		recode	`r(varlist)'	(0	8	9	.d	.r=5)
	}
	

		*	LASSO	(when "5" implies "no". Should yield the same result when "0" implies "no")
		local	statevars	cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc	//	up to the order of 5
		local	healthvars	/*respondent_BMI*/	ib5.alcohol_head ib5.alcohol_spouse	ib5.smoke_head ib5.smoke_spouse	ib5.phys_disab_head ib5.phys_disab_spouse
		local	demovars	c.age_head_fam##c.age_head_fam	ib1.race_head_cat	ib2.marital_status_fam	ib1.gender_head_fam	ib0.state_resid_fam	c.age_spouse##c.age_spouse	ib5.housing_status	ib5.veteran_head ib5.veteran_spouse
		local	econvars	c.avg_income_pc##c.avg_income_pc	c.avg_wealth_pc##c.avg_wealth_pc	ib5.sup_outside_FU	ib5.tax_item_deduct	ib5.retire_plan_head ib5.retire_plan_spouse	ib5.annuities_IRA
		local	empvars		ib5.emp_HH_simple	ib5.emp_spouse_simple
		local	familyvars	num_FU_fam num_child_fam	ib0.family_comp_change	ib5.couple_status	ib5.head_status ib5.spouse_new
		local	eduvars		ib5.attend_college_head ib5.attend_college_spouse	college_yrs_head college_yrs_spouse	(ib5.hs_completed_head	ib5.college_completed	ib5.other_degree_head)##c.edu_years_head_fam	(ib5.hs_completed_spouse	ib5.college_comp_spouse	ib5.other_degree_spouse)##c.edu_years_spouse
		local	foodvars	ib5.food_stamp_used_1yr	ib5.child_meal_assist ib5.WIC_received_last	meal_together	ib5.elderly_meal
		local	childvars	ib5.child_daycare_any ib5.child_daycare_FSP ib5.child_daycare_snack	