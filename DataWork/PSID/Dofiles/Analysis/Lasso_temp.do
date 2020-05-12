




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



