/*
	local	demovars	c.age_head_fam##c.age_head_fam i.race_head_cat gender_head_fam	ib1.marital_status_cat	
	local	eduvars		edu_years_head_fam	c.edu_years_head_fam#hs_completed c.edu_years_head_fam#college_completed
	local	econvars	/*total_income_fam_wins*/	avg_income_pc	c.avg_income_pc#c.avg_income_pc
	local	famvars		num_FU_fam	num_child_fam
	local	foodvars	food_stamp_used_1yr	child_meal_assist	WIC_received_last*
*/
local	depvar	c.avg_foodexp_pc
local	statevars	cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc	//	up to the order of 5
local	healthvars	respondent_BMI	ib5.alcohol_head ib5.alcohol_spouse	ib5.smoke_head ib5.smoke_spouse	ib5.phys_disab_head ib5.phys_disab_spouse
local	demovars	c.age_head_fam##c.age_head_fam	ib1.race_head_cat	ib2.marital_status_fam	ib1.gender_head_fam	ib0.state_resid_fam	c.age_spouse##c.age_spouse	ib5.housing_status	ib5.veteran_head ib5.veteran_spouse
local	econvars	c.avg_income_pc##c.avg_income_pc	c.avg_wealth_pc##c.avg_wealth_pc	ib5.sup_outside_FU	ib5.tax_item_deduct	ib5.retire_plan_head ib5.retire_plan_spouse	ib5.annuities_IRA
local	empvars		ib5.emp_HH_simple	ib5.emp_spouse_simple
local	familyvars	num_FU_fam num_child_fam	ib0.family_comp_change	ib5.couple_status	ib5.head_status ib5.spouse_new
local	eduvars		ib5.attend_college_head ib5.attend_college_spouse	college_yrs_head college_yrs_spouse	(ib5.hs_completed_head	ib5.college_completed	ib5.other_degree_head)##c.edu_years_head_fam	(ib5.hs_completed_spouse	ib5.college_comp_spouse	ib5.other_degree_spouse)##c.edu_years_spouse
local	foodvars	ib5.food_stamp_used_1yr	ib5.child_meal_assist ib5.WIC_received_last	meal_together	ib5.elderly_meal
local	childvars	ib5.child_daycare_any ib5.child_daycare_FSP ib5.child_daycare_snack	

*	Recode nonresponses (dk, refuse, inappropriate) as "negative"
qui	ds	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse	veteran_head	veteran_spouse	tax_item_deduct	///
		retire_plan_spouse	retire_plan_spouse	annuities_IRA	attend_college_head	attend_college_spouse	hs_completed_head	hs_completed_spouse	///
		college_completed	college_comp_spouse	other_degree_head	other_degree_spouse	food_stamp_used_1yr	child_meal_assist	WIC_received_last	elderly_meal	///
		child_daycare_any	child_daycare_FSP	child_daycare_snack
*recode	`r(varlist)'	(0	8	9	.d	.r=5)
codebook		`r(varlist)'	
		


*	Feature Selection
*	Run Lasso with "rolling ahead" validation
cvlasso	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
			`familyvars'	`eduvars'	`foodvars'	`childvars',	///
		lopt /*lse*/	rolling	h(1)	seed(20200505)	prestd fe /*postres		ols*/	plotcv 

gen	cvlass_sample=1	if	e(sample)==1		

/*		
predict double mean1_avgfoodexp, lopt
predict double e1_avgfoodexp, lopt e

gen e1_avgfoodexp_sq = e1_avgfoodexp^2
*/


****** cvlasso does not generate e(selected) macro, which has the list of the seletected variables.
****** For now, we need to "manually" type the list of selected variables from the result. Need to contact the authors for more information.
-*


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


predict	var2_avgfoodexp, xb

*	Step 3

gen alpha1_avg_foodexp_pc = mean2_avgfoodexp^2 / var2_avgfoodexp	//	shape parameter of Gamma (alpha)
gen beta1_avg_foodexp_pc = var2_avgfoodexp / mean2_avgfoodexp	//	scale parameter of Gamma (beta)
foreach	plan	in	thrifty low moderate liberal	{
	gen rho1_avg_foodexp_pc_`plan' = gammaptail(alpha1_avg_foodexp_pc, avg_foodexp_W_`plan'/beta1_avg_foodexp_pc)	if	(cvlass_sample==1)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
	label	var	rho1_avg_foodexp_pc_`plan' "Resilience score, `plan' plan"
}


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
		
			
*	Validation
* among the reduced sample (_N=1,724), 89.85% are “high food security”, “5.92% are marginal food security”, 4.23% are “food insecurity”
* We will use this cutoff to validate performance

clonevar	fs_cat_fam_simp	=	fs_cat_fam
*recode		fs_cat_fam_simp	(3,4=1) (1,2=1)
*label	define	fs_cat_simp	1	"High Secure"	2	"Marginal Secure"	3	"Insecure"
recode		fs_cat_fam_simp	(2 3 4=0) (1=1)
label	define	fs_cat_simp	0	"Food Insecure (any)"	1	"Food Secure", replace
label values	fs_cat_fam_simp	fs_cat_simp

foreach	plan	in	thrifty low moderate liberal	{
	
	
	xtile `plan'_pctile = rho1_avg_foodexp_pc_`plan' if !mi(rho1_avg_foodexp_pc_`plan'), nq(1000)
	
	gen		rho1_`plan'_IS	=	0	if	!mi(rho1_avg_foodexp_pc_`plan')
	replace	rho1_`plan'_IS	=	1	if	inrange(`plan'_pctile,1,41)	//	Food insecure
	
	gen		rho1_`plan'_MS	=	0	if	!mi(rho1_avg_foodexp_pc_`plan')
	replace	rho1_`plan'_MS	=	1	if	inrange(`plan'_pctile,42,101)	//	Marginal food secure
	
	gen		rho1_`plan'_HS	=	0	if	!mi(rho1_avg_foodexp_pc_`plan')
	replace	rho1_`plan'_HS	=	1	if	inrange(`plan'_pctile,102,1000)	//	Highly secure
	
}

graph twoway (kdensity fs_scale_fam), title(Distribution of USDA Measure) name(fs_scale)	
graph combine thrifty	fs_scale

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



