
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_CB_Measurement
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Apr 12, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	        // Uniquely identifies family (update for your project)

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
	
	/****************************************************************
		SECTION 1: Prepare dataset
	****************************************************************/		
	
	*	Construct additional variables
	*	Most of them are from Tiehen (2019) replication
	
		use	"${PSID_dtFin}/PSID_const_1999_2017_ind.dta",	clear
		
		*	Racial category
		forval	year=1999(2)2017	{
			gen		race_head_cat`year'=.
			replace	race_head_cat`year'=1	if	inlist(race_head_fam`year',1,5)
			replace	race_head_cat`year'=2	if	race_head_fam`year'==2
			replace	race_head_cat`year'=3	if	inlist(race_head_fam`year',3,4,6,7)
			replace	race_head_cat`year'=.n	if	inrange(race_head_fam`year',8,9)
			
			*	Dummy for each variable
			
			label variable	race_head_cat`year'	"Racial Category of Head, `year'"
		}
		label	define	race_cat	1	"White"	2	"Black"	3	"Others"
		label	values	race_head_cat*	race_cat
		
		*	Marital Status (Binary)
		forval	year=1999(2)2017	{
			gen		marital_status_cat`year'=.
			replace	marital_status_cat`year'=1	if	marital_status_fam`year'==1
			replace	marital_status_cat`year'=0	if	inrange(marital_status_fam`year',2,5)
			replace	marital_status_cat`year'=.n	if	inrange(marital_status_fam`year',8,9)
			
			label variable	marital_status_cat`year'	"Head Married, `year'"
		}
		label	define	marital_status_cat	1	"Married"	0	"Not Married"
		label	values	marital_status_cat*	marital_status_cat
		
		*	Children in Household (Binary)
		forval	year=1999(2)2017	{
			gen		child_in_FU_cat`year'=.
			replace	child_in_FU_cat`year'=1		if	num_child_fam`year'>=1	&	!mi(num_child_fam`year')
			replace	child_in_FU_cat`year'=2		if	num_child_fam`year'==0
			*replace	child_in_FU_cat`year'=.n	if	!inrange(xsqnr_`year',1,89)
			
			label variable	child_in_FU_cat`year'	"Children in Household, `year'"
		}
		label	define	child_in_FU_cat	1	"Children in Household"	2	"No Children in Household"
		label	values	child_in_FU_cat*	child_in_FU_cat
		
		*	Age of Head (Category)
		forval	year=1999(2)2017	{
			gen		age_head_cat`year'=1	if	inrange(age_head_fam`year',16,24)
			replace	age_head_cat`year'=2	if	inrange(age_head_fam`year',25,34)
			replace	age_head_cat`year'=3	if	inrange(age_head_fam`year',35,44)
			replace	age_head_cat`year'=4	if	inrange(age_head_fam`year',45,54)
			replace	age_head_cat`year'=5	if	inrange(age_head_fam`year',55,64)
			replace	age_head_cat`year'=6	if	age_head_fam`year'>=65	&	!mi(age_head_fam`year'>=65)
			replace	age_head_cat`year'=.	if	mi(age_head_fam`year')
			
			label	var	age_head_cat`year'	"Age of Household Head (category), `year'"
			
			gen		non_working_age`year'	=0	if	inrange(age_head_fam`year',16,64)
			replace	non_working_age`year'	=1	if	!mi(age_head_fam`year')	&	!inrange(age_head_fam`year',16,64)
		}
		label	define	age_head_cat	1	"16-24"	2	"25-34"	3	"35-44"	///
										4	"45-54"	5	"55-64"	6	"65 and older"
		label	values	age_head_cat*	age_head_cat
		
		label	define	non_working_age	0 "Working age (16-64)"	1	"Outside working age (65 or older)"
		label	values	non_working_age*	non_working_age
		
		*	Recode gender
		forval	year=1999(2)2017	{
			replace	gender_head_fam`year'	=	0	if	gender_head_fam`year'==2
			
			label	var	gender_head_fam`year'	"Gender Household Head (category), `year'"
		}
		label	define	gender_head_cat	0	"Female"	1	"Male"
		label	values	gender_head_fam*	gender_head_cat
		
		*	Create dummy variables for food security status, compatible with literature
		foreach	year	in	1999	2001	2003	2015	2017	{
			
			generate	fs_cat_MS`year'		=	0	if	!mi(fs_cat_fam`year')
			generate	fs_cat_IS`year'		=	0	if	!mi(fs_cat_fam`year')
			generate	fs_cat_VLS`year'	=	0	if	!mi(fs_cat_fam`year')
					
			replace		fs_cat_MS`year'	=	1	if	inrange(fs_cat_fam`year',2,4)
			replace		fs_cat_IS`year'	=	1	if	inrange(fs_cat_fam`year',3,4)
			replace		fs_cat_VLS`year'	=	1	if	fs_cat_fam`year'==4
			
			label	var	fs_cat_VLS`year'	"Very Low Food Secure (cum) - `year'"
			label	var	fs_cat_IS`year'		"Food Insecure (cum) - `year'"
			label	var	fs_cat_MS`year'		"Any Insecure (cum) - `year'"
		}
		/*
		*	Recode child-related variables from missing to zero, to be included in the regression model
		forval	year=1999(2)2017	{
				replace	WIC_received_last`year'=0	if	child_meal_assist`year'==2
				replace	child_meal_assist`year'=0	if	child_meal_assist`year'==2
		}
		*/
		tempfile	dta_constructed
		save		`dta_constructed'
	

	
	*	Import variables for sampling error estimation
		use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
	
		*	Generate a single ID variable
		generate	x11101ll=(ER30001*1000)+ER30002
		
		tempfile	Ind
		save		`Ind'
	
		*	Import variables
		use	`dta_constructed', clear
		merge	m:1	x11101ll	using	`Ind', assert(2 3) keep(3) keepusing(ER31996 ER31997) nogen
		
	*	Keep relevant variables and observations
				
		*	Drop outliers with strange pattern
		drop	if	x11102_1999==10015	//	This Family has outliers (food expenditure in 2009) as well as strange flutation in health expenditure (2007), thus needs to be dropped (* It attrits in 2011 anway)
		
		
		*	Keep	relevant sample
		*	We need to decide what families to track (so we have only 1 obs per family in baseyear)
		keep	if	fam_comp_samehead_99_17==1	//	Families with same household during 1999-2017
		*keep	if	fam_comp_nochange_99_03==1	//	Families with no member change during 1999-2003
		*keep	if	fam_comp_samehead_99_03==1	//	Families with same household during 1999-2003
		*keep	if	fam_comp_samehead_99_03==1	//	Families with same household during 1999-2003

		
		*	Drop individual level variables
		drop	x11101ll weight_long_ind* weight_cross_ind* respondent???? relat_to_head* age_ind* edu_years????	relat_to_current_head*	
		*	Keep	relevant years
		keep	*1999	*2001	*2003	*2005	*2007	*2009	*2011	*2013	*2015	*2017	/*fam_comp**/	sample_source	ER31996 ER31997		
		
		duplicates drop	
		
		/*
		*	Keep relevant family-level variables only
		loc	interview_ID	x11102*	x11101ll	fam_ID_1999
		loc	weightvars		weight_long_fam*
		loc	samplingvars	sample_source	ER31996	ER31997
		loc	demovars		age_head*	age_spouse*	race_head*	ethnicity*	race_spouse*		marital_status*	gender_head_fam*	state_resid_fam*
		loc	familyvars		num_FU_fam*	num_child_fam*	family_comp_change*	child_in_FU*	fam_comp_nochange_99_03	fam_comp_samehead_99_03	fam_comp_samehead_99_17	child_daycare*
		loc	socioeconvars	grade_comp_head_fam*	FPL*	grade_comp*	college_completed*	hs_completed*	total_income_fam*	income_pc*		avg_income_pc*	avg_foodexp_pc*
		loc	expenditurevars	food_exp*	
		loc	foodvars		fs_raw*	fs_scale*	fs_cat*	food_stamp_used*	child_meal_assist*	WIC_received*	meal_together*
		loc	healthvars		height_meter*	weight_kg*	respondent_BMI*	
		
		keep	`interview_ID'	`weightvars'	`samplingvars'	`demovars'	`familyvars'	`socioeconvars'	`expenditurevars'	`foodvars'	`healthvars'
		save	`dta_constructed', replace
		
		*	Keep relevant years and variables
		keep	*1999	*2001	*2003	sample_source	ER31996 ER31997
		duplicates drop	
		*/
		
	*	Re-shape dataset

		*	Retrieve the list of time-series variables
		qui	ds	*	//	All variables
		local	allvar	`r(varlist)'

		ds	sample_source	fam_ID_1999	ER31996 ER31997
		local	uniqvars	`r(varlist)'	//	Variables that are not time-series (not to be reshaped)
		
		local	allrelevars:	list	allvar	-	uniqvars	//	Keep time-series variables only
		
		foreach var of	local	allrelevars	{
			
			loc	pos=strlen("`var'")
			loc	newvar=substr("`var'",1,`pos'-4)	//	Trim the last 4 characters (years in this case)
				
			local	newvarlist	`newvarlist'	`newvar'
		}
		local	allrelevars_uniq:	list	uniq	newvarlist	//	Drop duplicates

		
		reshape	long	`allrelevars_uniq',	i(fam_ID_1999)	j(year)
		
						
		*	Label variables after reshape
		label	var	year				"Year"
		label	var	x11102_				"Interview No."	
		label	var	weight_long_fam		"Longitudinal Family Weight"
		label	var	age_head_fam		"Age"
		label	var	race_head_fam		"Race of Household Head"
		label	var	total_income_fam	"Total Household Income"
		label	var	marital_status_fam	"Marital Status of Head"
		label	var	num_FU_fam			"Number of Family members"
		label	var	num_child_fam		"# of Children"
		label	var	gender_head_fam		"Gender of Household Head"
		label	var	grade_comp_head_fam	"Grades completed(head)"
		label	var	state_resid_fam		"State of Residence"
		label 	var	fs_raw_fam 			"Food Security Raw Score"
		label 	var	fs_scale_fam 		"Food Security Scale Score"
		label	var	fs_scale_fam_rescale	"Food Security Scale Score (USDA)-rescaled"
		label	var	fs_cat_fam 			"Food Security Category"
		label	var	food_stamp_used_2yr	"Received Food Stamp (2 years ago)"
		label	var	food_stamp_used_1yr "Received food stamp"
		label	var	child_meal_assist	"Received child free meal at school"
		label	var	WIC_received_last	"Received foods through WIC"
		label	var	family_comp_change	"Change in Family Composition"
		label	var	grade_comp_cat		"Highest Grade Completed (Head)"
		label	var	race_head_cat		"Race of Household Head"
		label	var	marital_status_cat	"Married"
		label	var	child_in_FU_cat		"Household has a child"
		label	var	age_head_cat 		"Age of Household Head (category)"
		label	var	total_income_fam	"Total Household Income"
		label	var	hs_completed_head	"HH completed high school/GED"
		label	var	college_completed	"HH has college degree"
		label	var	respondent_BMI		"Respondent's Body Mass Index"
		label	var	income_pc			"Family income per capita (thousands)"
		label	var	food_exp_pc			"Food expenditure per capita (thousands)"
		label	var	avg_income_pc		"Average income over two years per capita"
		label	var	avg_foodexp_pc		"Average food expenditure over two years per capita"
		label	var	splitoff_indicator		"Splitoff indicator"
		label	var	num_split_fam		"# of splits"
		label	var	main_fam_ID		"Family ID"
		label	var	food_exp_total		"Total food expenditure"
		label	var	height_feet		"Respondent height (feet)"
		label	var	height_inch		"Respondent height (inch)"
		label	var	height_meter		"Respondent height (meters)"
		label	var	weight_lbs		"Respondent weight (lbs)"
		label	var	weight_kg		"Respondent weight (Kg)"
		label	var	meal_together		"Meal together/wk"
		label	var	child_daycare_any		"Child in daycare"
		label	var	child_daycare_FSP		"Child daycare in FSP"
		label	var	child_daycare_snack		"Child daycare offers snack"
		label	var	age_spouse		"Age (spouse)"
		label	var	ethnicity_head		"Ethnicity (head)"
		label	var	ethnicity_spouse	"Ethnicity (spouse)"
		label	var	race_spouse		"Race(spouse)"
		label	var	other_degree_head		"Other degree (head)"
		label	var	other_degree_spouse		"Other degree (spouse)"
		label	var	attend_college_head		"Attend college (head)"
		label	var	attend_college_spouse		"Attend college (spouse)"
		label	var	college_comp_spouse		"College degree (spouse)"
		label	var	edu_in_US_head		"Education in the U.S. (head)"
		label	var	edu_in_US_spouse		"Education in the U.S. (spouse)"
		label	var	college_yrs_head		"Yrs in collge (head)"
		label	var	college_yrs_spouse		"Yrs in collge (spouse)"
		label	var	grade_comp_spouse		"Grades completed (spouse)"
		label	var	hs_completed_spouse		"HS degree (spouse)"
		label	var	child_exp_total		"Annual child expenditure"
		*label	var	cloth_exp_total		"Annual cloth expenditure"
		label	var	sup_outside_FU		"Support from outside family"
		label	var	edu_exp_total		"Annual education expenditure"
		label	var	health_exp_total	"Annual health expenditure"
		label	var	house_exp_total		"Annual housing expenditure"
		label	var	tax_item_deduct		"Itemized tax deduction"

		label	var	property_tax		"Property tax ($)"
		label	var	transport_exp		"Annual transport expenditure"

		label	var	couple_status		"Coupling status"
		label	var	head_status		"New head"
		label	var	spouse_new		"New spouse"
		label	var	alcohol_head	"Drink alcohol (head)"
		label	var	num_drink_head		"# of drink (head)"
		label	var	num_drink_spouse	"# of drink (spouse)"
		label	var	smoke_head		"Smoking (head)"
		label	var	smoke_spouse	"Smoking (spouse)"
		label	var	num_smoke_head		"# of smoking (head)"
		label	var	num_smoke_spouse	"# of smoking (spouse)"
		label	var	phys_disab_head		"Physical Disability (head)"
		label	var	phys_disab_spouse	"Physical Disability (spouse)"
		label	var	housing_status		"Housing status"
		label	var	elderly_meal	"Received free/reduced cost elderly meal"
		label	var	retire_plan_head		"Retirement plan (head)"
		label	var	retire_plan_spouse	"Retirement plan (spouse)"
		label	var	annuities_IRA		"Annuities_IRA"
		label	var	veteran_head	"Veteran (head)"
		label	var	veteran_spouse	"Veteran (spouse)"
		label	var	wealth_total	"Total wealth"
		label	var	emp_status_head	"Employement status (head)"
		label	var	emp_status_spouse	"Employement status(spouse)"
		label	var	alcohol_spouse	"Drink alcohol (spouse)"
		*label	var	relat_to_current_head	"Veteran (head)"
		label	var	child_exp_pc		"Annual child expenditure (pc) (thousands)"
		label	var	edu_exp_pc		"Annual education expenditure (pc) (thousands)"
		label	var	health_exp_pc		"Annual health expenditure (pc) (thousands)"
		label	var	house_exp_pc		"Annual house expenditure (pc) (thousands)"
		label	var	property_tax_pc		"Property tax (pc) (thousands)"
		label	var	transport_exp_pc	"Annual transportation expenditure (pc) (thousands)"
		label	var	wealth_pc		"Wealth (pc) (thousands)"
		*label	var	cloth_exp_pc		"Annual cloth expenditure (pc)"
		label	var	avg_childexp_pc		"Avg child expenditure (pc)"
		label	var	avg_eduexp_pc		"Avg education expenditure (pc)"
		label	var	avg_healthexp_pc		"Avg health expenditure (pc)"
		label	var	avg_houseexp_pc		"Avg house expenditure (pc)"
		label	var	avg_proptax_pc		"Avg property expenditure (pc)"
		label	var	avg_transexp_pc		"Avg transportation expenditure (pc)"
		label	var	avg_wealth_pc		"Avg wealth (pc)"
		label	var	emp_HH_simple		"Employed"
		label	var	emp_spouse_simple		"Employed (spouse)"
		label	var	fs_cat_MS		"Marginal food secure"
		label	var	fs_cat_IS		"Food insecure"
		label	var	fs_cat_VLS		"Very Low food secure"
		label	var	child_bf_assist		"Free/reduced breakfast from school"
		label	var	child_lunch_assist		"Free/reduced lunch from school"
		label	var	splitoff_dummy		"Splitoff ummy"
		label	var	accum_splitoff		"Accumulated splitoff"
		label	var	other_debts			"Other debts"
		label	var	fs_cat_fam_simp		"Food Security Category (binary)"
		label	var	non_working_age		"Ouside working age"
		label	var	retire_year_head	"Year of retirement"
		label	var	retire_year_head	"Age when retired"
		label	var	ratio_child			"Percetange of children population"
		label	var	grade_comp_cat_spouse	"Highest Grade Completed (Spouse)"

		*label	var	cloth_exp_total		"Total cloth expenditure"
		
		label	var	FPL_		"Federal Poverty Line"
		label	var	income_to_poverty		"Income to Poverty Ratio"
		label	var	income_to_poverty_cat		"Income to Poverty Ratio (category)"
			      
		drop	height_feet		height_inch	  weight_lbs	child_bf_assist	child_lunch_assist	food_exp_total	child_exp_total	edu_exp_total	health_exp_total	///
				house_exp_total	property_tax	transport_exp	wealth_total	/*cloth_exp_total*/
		
		
	*	Recode N/A & nonrespones reponses of "some" variables
	***	Recoding nonresponses & N/As should be done carefully, as there could be statistical difference between responses and non-responses. Judgements must be done by variable-level
	***	Among the variables with nonresponeses (ex. DK, Refusal), some of them have very small fraction of nonrespones (ex.less than 0.1%) This implies that they can be relatively recoded as missing safely.

		*	Recode variables which have a very small fraction of non-responses & N/As
		qui	ds	food_stamp_used_2yr	food_stamp_used_1yr	child_meal_assist	WIC_received_last	college_completed	child_daycare_any	college_comp_spouse	sup_outside_FU	///
				alcohol_head	smoke_spouse	phys_disab_head  phys_disab_spouse	elderly_meal	retire_plan_head retire_plan_spouse	annuities_IRA	alcohol_spouse	///
				
	    recode	`r(varlist)'	(8=.d)	(9=.r)
		
		replace	alcohol_head=.n	if	alcohol_head==0	// only 1 obs
		replace	smoke_head=.n	if	smoke_head==0	// only 1 obs
                                               
	*	Recode time variables, to start from 1 and increase by 1 in every wave
	replace	year	=	(year-1997)/2
	
	*	Generate in-sample and out-of-sample for performance check
	*	We use the data up to 2015 as "in-sample", and the data in 2018 as "out-of-sample"
	gen		in_sample	=	0
	replace	in_sample	=	1	if	inrange(year,1,9)
	label	var	in_sample	"In-sample (1999~2015)"
	
	gen		out_of_sample	=	0
	replace	out_of_sample	=	1	if	year==10
	label	var	out_of_sample	"Out of sample (2017)"
	
	*	Define the data as survey data and time-series data
	svyset	ER31997 [pweight=weight_long_fam], strata(ER31996)	singleunit(scaled)
	xtset fam_ID_1999 year,	delta(1)
	
	cap	drop	year2
	gen year2 = (year*2)+1997	//	actual year
	
	*	Recode nonresponses (dk, refuse, inappropriate) as "negative"
	label	define	yes1no0	0	"No"	1	"Yes"
	local	recode_vars	1
	if	`recode_vars'==1	{
		qui	ds	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse	veteran_head	veteran_spouse	tax_item_deduct	///
				retire_plan_head	retire_plan_spouse	annuities_IRA	attend_college_head	attend_college_spouse	hs_completed_head	hs_completed_spouse	///
				college_completed	college_comp_spouse	other_degree_head	other_degree_spouse	food_stamp_used_1yr	child_meal_assist	WIC_received_last	elderly_meal	///
				child_daycare_any	child_daycare_FSP	child_daycare_snack	emp_HH_simple emp_spouse_simple
		label values	`r(varlist)'	yes1no0
		recode	`r(varlist)'	(0	5	8	9	.d	.r=0)
	}
	
	*	Create a lagged variable of the outcome variable and its higher polynomial terms (needed for Shapley decomposition)	
	forval	i=1/5	{
		
		gen	lag_food_exp_pc_`i'	=	(cl.food_exp_pc)^`i'
		label	var	lag_food_exp_pc_`i'	"Lagged food exp (pc) - `i'th polynimial	order"
		
		*gen	lag_avg_foodexp_pc_`i'	=	(cl.avg_foodexp_pc)^`i'
		*label	var	lag_avg_foodexp_pc_`i'	"Lagged avg. food exp (pc) `i'th polynimial	order"
		
	}
	order	lag_food_exp_pc_1-lag_food_exp_pc_5,	after(food_exp_pc)
	*order	lag_avg_foodexp_pc_1-lag_avg_foodexp_pc_5,	after(avg_foodexp_pc)
	 
	*	Create variables of status change (employment, marital status, ....) which could affect food expenditure
		
		*	No longer employed (employed in the previous period, but not employed in the current period)
		local	var	no_longer_employed
		gen		`var'=0
		replace	`var'=1	if	emp_HH_simple==0	&	l.emp_HH_simple==1
		label	var	`var'	"No longer employed"
		
		*	No longer married (married in the previous period, but no longer married (widowed, divorced, separated) in the current period)
		local	var	no_longer_married
		gen		`var'=0
		replace	`var'=1	if	inrange(marital_status_fam,3,5)	&	l.marital_status_fam==1	//	
		label	var	`var'	"No longer married"
		
		*	No longer owns house (Owned a house in the previous period, but no longer own (rent or else) in the current period)
		local	var	no_longer_own_house
		gen		`var'=0
		replace	`var'=1	if	inlist(housing_status,5,8)	&	l.housing_status==1	//	
		label	var	`var'	"No longer owns house"
		
		*	Household head became physically disabled
		local	var	became_disabled
		gen		`var'=0
		replace	`var'=1	if	phys_disab_head==1	&	l.phys_disab_head==0	//	
		label	var	`var'	"Became disabled"	
		
	
	*	Create additional variables, as "rforest" does accept none of the interaction, factor variable and time series variable

		*	Non-linear terms of income & wealth	&	age
		gen	income_pc_sq	=	(income_pc)^2
		label	var	income_pc_sq	"(Income per capita)^2"
		gen	wealth_pc_sq	=	(wealth_pc)^2
		label	var	wealth_pc_sq	"(Wealth per capita)^2"
		gen	age_head_fam_sq		=	(age_head_fam)^2
		gen	age_spouse_sq		=	(age_spouse)^2
		gen	income_pc_orig	=	income_pc*1000	//	Non-scaled, unit is dollars
		gen	invhyp_age	=	asinh(age_head_fam)	//	Inverse hyperbolic transformation of age
		gen	asinh_income	=	asinh(income_pc*1000)	//	Inverse hyperbolic transformation of income
		gen	ln_income_pc	=	ln(income_pc*1000)	//	Log of income
		lab	var	ln_income_pc	"Log of income per capita"
		gen	ln_wealth_pc	=	ln(wealth_pc*1000)	//	Log of income
		lab	var	ln_wealth_pc	"Log of wealth per capita"
		gen	income_cubic	=	(income_pc)^3	//	Cubic of income
		
		*	Decompose unordered categorical variables
		local	catvars	race_head_cat	marital_status_fam	gender_head_fam	state_resid_fam	housing_status	family_comp_change	couple_status	grade_comp_cat	grade_comp_cat_spouse	year	sample_source
		foreach	var	of	local	catvars	{
			tab	`var',	gen(`var'_enum)
		}
		rename	gender_head_fam_enum1	HH_female
		label	variable	HH_female	"Gender:Female"
		
		rename	(race_head_cat_enum1 race_head_cat_enum2 race_head_cat_enum3)	(HH_race_white	HH_race_black	HH_race_other)
		label	variable	HH_race_white	"Race: White"
		label	variable	HH_race_black	"Race: Black"
		label	variable	HH_race_other	"Race: Other"
		
		rename	(grade_comp_cat_enum1	grade_comp_cat_enum2	grade_comp_cat_enum3	grade_comp_cat_enum4)	///
				(highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col)
				
		label	variable	highdegree_NoHS		"Highest Degree: Less than High School"
		label	variable	highdegree_HS		"Highest Degree: High School"
		label	variable	highdegree_somecol	"Highest Degree: Some College"
		label	variable	highdegree_col		"Highest Degree: College"
		
		rename	(grade_comp_cat_spouse_enum1	grade_comp_cat_spouse_enum2	grade_comp_cat_spouse_enum3	grade_comp_cat_spouse_enum4)	///
				(highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse)
				
		label	variable	highdegree_NoHS_spouse		"Highest Degree: Less than High School (Spouse)"
		label	variable	highdegree_HS_spouse		"Highest Degree: High School (Spouse)"
		label	variable	highdegree_somecol_spouse	"Highest Degree: Some College (Spouse)"
		label	variable	highdegree_col_spouse		"Highest Degree: College (Spouse)"
		
		rename	(sample_source_enum1	sample_source_enum2	sample_source_enum3)	///
				(sample_source_SRC	sample_source_SEO	sample_source_IMM)
				
		label	variable	sample_source_SRC	"Sample: SRC"
		label	variable	sample_source_SEO	"Sample: SEO"
		label	variable	sample_source_IMM	"Sample: Immigrants"
		
		*	Interaction variables
			
			*	Male education
			foreach	var	in	hs_completed_head	college_completed	other_degree_head	{
				gen	`var'_interact	=	`var'*grade_comp_head_fam
			}
		
			*	Female education
			foreach	var	in	hs_completed_spouse	college_comp_spouse	other_degree_spouse	{
				gen	`var'_interact	=	`var'*grade_comp_spouse
			}	
	
	sort	fam_ID_1999 year,	stable
	
	*	Codebook (To share with John, Chris and Liz)
	local	codebook	0
	if	`codebook'==1	{
		codebook	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse			///
					age_head_fam	age_spouse	race_head_cat	marital_status_fam		gender_head_fam		state_resid_fam	housing_status	veteran_head	veteran_spouse	///
					/*foodexp_pc*/	income_pc	wealth_pc	sup_outside_FU	tax_item_deduct	retire_plan_head	retire_plan_spouse	annuities_IRA	///
					emp_HH_simple	emp_spouse_simple	///
					num_FU_fam	num_child_fam	family_comp_change	couple_status	head_status	spouse_new	///
					grade_comp_head_fam	grade_comp_spouse	attend_college_head	attend_college_spouse	college_yrs_head	college_yrs_spouse	///
					hs_completed_head	hs_completed_spouse	college_completed	college_comp_spouse	other_degree_head	other_degree_spouse					///
					food_stamp_used_1yr	child_meal_assist	WIC_received_last	meal_together	elderly_meal	child_daycare_any	child_daycare_FSP	child_daycare_snack	///
					if	in_sample==1, compact
		
	}
	
	*	Keep only observations where the outcome variable is non-missing
	*	This is necessary for "rforest" command, but it should be safe anyway since we will use only in_sample and out_of_sample.
	keep	if	inlist(1,in_sample,out_of_sample)	
	sort	fam_ID_1999	year
	
	*	Construct new survey weight variables to apply complex survey design into the panel data analyses
	*	This weight construction is based on the following reference
			*	Heeringa, Steven G., Brady T. West, and Patricia A. Berglund. 2010. “Advanced Topics in the Analysis of Survey Data.” In Applied Survey Data Analysis, Boca Raton, FL: Chapman & Hall/CRC. (example 12.3.4)
	
		*	Base weight
		local	var	weight_long_fam_base
		gen	`var'	=	weight_long_fam	if	year==1	//	Base weight is the weight of the first year
		bys	fam_ID_1999:	egen temp	=	max(`var')
		replace	`var'	=	temp
		drop	temp
		lab	var	`var'	"Base weight of the household (longitudinal family weight in 1999)"
		
		*	Level 1 weight (weight for repeated measurement)
		local	var	weight_l1
		gen	`var'	=	weight_long_fam	/	weight_long_fam_base	//	Level 1 weight = wave_speific weight / base weight
		lab	var	`var'	"Level 1 weight"
		
		*	Re-scale level 1 weight (using "Method 1" of Rabe-Hesketh and Skrondal (2006))
		gen		weight_l1_sq	=	(weight_l1)^2
		egen	sum_weight_l1_sq	=	sum(weight_l1_sq), by(fam_ID_1999)
		egen	sum_weight_l1	=	sum(weight_l1), by(fam_ID_1999)
		gen		weight_l1_r	=	weight_l1	*	(sum_weight_l1)	/	(sum_weight_l1_sq)
		
		*	Create a unique PSU identifier to be used as a new PSU
		gen		newsecu	=	(ER31996*100)	+	ER31997	
		
		*	Create two new variables "weight_multi1" and "weight_multi2" from the two newly constructed weight variables above.
		*	This step is required if we want to use "gllamm" command, Generalized Linear Latent and Mixed Model
		gen	weight_multi1	=	weight_long_fam_base
		gen	weight_multi2	=	weight_l1_r
		
		*	For an alternative approach, multiply two weights to be used as a new survey weight
		gen	weight_multi12	=	weight_multi1*weight_multi2
		
		*	To use an alternative approach, change the new surveydata setting as following
		svyset	newsecu	[pweight=weight_multi12] /*,	singleunit(scaled)*/
		
	
	*	Save data
	tempfile	data_prep
	save		`data_prep'
	
	

	/****************************************************************
		SECTION 2: Construct CB measurement
	****************************************************************/	
	

	*	We will use three methods - classic OLS, LASSO and Random Forest

	
	*	OLS
	local	run_ols	1
		local	run_ME	1
	
	*	LASSO
	local	run_lasso	0
		local	run_lasso_step1	1
		local	run_lasso_step2	1
		local	run_lasso_step3	1
		
	*	Random Forest
	local	run_rf	0	
		local	tune_iter	0	//	Tuning iteration
		local	tune_numvars	0	//	Tuning numvars
		local	run_rf_step1	1
		local	run_rf_step2	1
		local	run_rf_step3	1
	*svyset	newsecu	[pweight=weight_multi12] /*,	singleunit(scaled)*/
	*svyset	ER31997 [pweight=weight_long_fam], strata(ER31996)	singleunit(scaled)
	
	*	OLS
	if	`run_ols'==1	{
		
		*	Declare variables
		local	depvar		food_exp_pc
		local	statevars	c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1##c.lag_food_exp_pc_1	/*lag_food_exp_pc_1-lag_food_exp_pc_5*/
		local	healthvars	phys_disab_head
		local	demovars	c.age_head_fam##c.age_head_fam	ib1.race_head_cat	marital_status_cat	ib1.gender_head_fam	
		local	econvars	/*income_pc	income_pc_sq	wealth_pc	wealth_pc_sq*/	ln_income_pc	ln_wealth_pc
		local	empvars		emp_HH_simple
		local	familyvars	num_FU_fam ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head college_yrs_head (hs_completed_head	college_completed	other_degree_head)##c.grade_comp_head_fam*/	highdegree_NoHS	highdegree_somecol	highdegree_col
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	/*meal_together*/	elderly_meal
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	ib0.state_resid_fam	
		local	timevars	i.year
		
		local	MEvars	c.lag_food_exp_pc_1	`healthvars'	c.age_head_fam	ib1.race_head_cat	marital_status_cat	ib1.gender_head_fam	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'
		
		
		*	Step 1
		*svy: reg	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	if	in_sample==1
		svy: glm 	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	if	in_sample==1, family(gamma)	link(log)
		
		est	sto	ols_step1
		
		gen	ols_step1_sample=1	if	e(sample)==1
		predict double mean1_foodexp_ols
		predict double e1_foodexp_ols, r
		gen e1_foodexp_sq_ols = (e1_foodexp_ols)^2
		
		
		*	Marginal Effect
		if	`run_ME'==1	{
		
			eststo	ols_step1_ME: margins,	dydx(`MEvars')	post
		
		}
				
		
		*	Step 2
		local	depvar	e1_foodexp_sq_ols
		
		*svy: glm `depvar' `statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	if	ols_step1_sample==1, family(poisson)	//	glm does not converge, thus use OLS
		svy: reg `depvar' `statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	`timevars'	if	ols_step1_sample==1
		est store ols_step2
		
		gen	ols_step2_sample=1	if	e(sample)==1
		*svy:	reg `e(depvar)' `e(selected)'
		predict	double	var1_foodexp_ols
		
		
		*	Marginal Effect
		if	`run_ME'==1	{
		
			eststo	ols_step2_ME: margins,	dydx(`MEvars')	post	
			
			*	Output
			esttab	ols_step1_ME	ols_step2_ME	using "${PSID_outRaw}/OLS_ME.csv", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 1999 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5% of the sample size)	///
					replace
					
			esttab	ols_step1_ME	ols_step2_ME	using "${PSID_outRaw}/OLS_ME.tex", ///
					cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Average Marginal Effects on Food Expenditure per capita) 	///
					addnotes(Sample includes household responses from 1999 to 2015. Base household is as follows: Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.	///
					23 observations with negative income are dropped which account for less than 0.5\% of the sample size)	///
					replace		
		}
		
		
		
		
		*	Step 3
		*	Assume the outcome variable follows the Gamma distribution
		gen alpha1_foodexp_pc_ols = (mean1_foodexp_ols)^2 / var1_foodexp_ols	//	shape parameter of Gamma (alpha)
		gen beta1_foodexp_pc_ols = var1_foodexp_ols / mean1_foodexp_ols	//	scale parameter of Gamma (beta)
		
		*	Construct CDF
		foreach	plan	in	thrifty low moderate liberal	{
			
			*	Generate resilience score. 
			*	Should include in-sample as well as out-of-sample to validate its OOS performance
			gen rho1_foodexp_pc_`plan'_ols = gammaptail(alpha1_foodexp_pc_ols, foodexp_W_`plan'/beta1_foodexp_pc_ols)	/*if	(lasso_step1_sample==1)	&	(lasso_step2_sample==1)*/	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
			label	var	rho1_foodexp_pc_`plan'_ols "Resilience score (OLS) (`plan' plan)"
		}
		
		*local	depvar	rho1_foodexp_pc_thrifty_ols
		*svy: reg	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`changevars'	`regionvars'	if	ols_step1_sample==1	
		
	}
	
	*	LASSO
	if	`run_lasso'==1	{
		
		*	Variable selection
		*	when "0" implies "no". Should yield the same result to the previous coding which "5" implies "no"
		local	statevars	lag_food_exp_pc_1-lag_food_exp_pc_5	//	up to the order of 5
		local	healthvars	/*respondent_BMI*/	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse
		local	demovars	age_head_fam	age_head_fam_sq	HH_race_black HH_race_other	marital_status_cat	/*marital_status_fam_enum1 marital_status_fam_enum3 marital_status_fam_enum4 marital_status_fam_enum5*/	///
							HH_female	age_spouse	age_spouse_sq	housing_status_enum1 housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc	/*income_pc	income_pc_sq	wealth_pc	wealth_pc_sq*/	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	/*num_child_fam*/	couple_status_enum1-couple_status_enum4
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
							/*	attend_college_head attend_college_spouse	college_yrs_head college_yrs_spouse	///
							hs_completed_head	college_completed	other_degree_head	grade_comp_head_fam	///
							hs_completed_head_interact college_completed_interact other_degree_head_interact	///
							hs_completed_spouse	college_comp_spouse	other_degree_spouse	grade_comp_spouse	///
							hs_completed_spouse_interact college_comp_spouse_interact other_degree_spouse_interact	*/
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	/*meal_together*/	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	ib0.state_resid_fam	/*state_resid_fam_enum2-state_resid_fam_enum52*/
		local	timevars	i.year
		
		
		*	Step 1
		if	`run_lasso_step1'==1	{
		
			*	Feature Selection
			*	Run Lasso with "K-fold" validation	with K=10
		
			local	depvar	food_exp_pc
	
			**	Following "cvlasso" command does k-fold cross-validation to find lambda, but it takes too much time.
			**	Therefore, once it is executed and found lambda, then we run regular lasso using "lasso2"
			**	If there's major change in specification, cvlasso must be executed
			
			set	seed	20200505
			
			/*
			*	LASSO with K-fold cross validation
			** As of Aug 21, 2020, the estimated lambda with lse is 2016.775 (lse).
			** As of Sep 4, 2020, the estimated lambda with lse is 845.955 (lse). Since this lamba value gives too many variables, we use lambda = exp(8) whose MSPE is only very slightly higher than the MSPE under the lse.
			** As of Sep 11, 2020, the estimated lambda with lse is 1208.72 (lse). Since this lamba value gives too many variables, we use lambda = exp(8) whose MSPE is only very slightly higher than the MSPE under the lse.
			cvlasso	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'		`healthvars'	`familyvars'	`eduvars'	///
								`eduvars'	`foodvars'	`childvars'	`regionvars'	`timevars'		if	in_sample==1,	///
				/*lopt*/ lse	seed(20200505)	notpen(`regionvars'	`timevars')	 /*rolling	h(1) fe	prestd 	postres	ols*/	plotcv 
			est	store	lasso_step1_lse
			
			*cvlasso, postresult lopt	//	somehow this command is needed to generate `e(selected)' macro. Need to double-check
			cvlasso, postresult lse
			*/
			
			*local	lambdaval=exp(14.7)	//	14.7 is as of Aug 21
			local	lambdaval=2208.348	//	manual lambda value from the cvplot. This is the value slightly higher than lse but give only slightly higher MSPE
			lasso2	`depvar'	`statevars'	`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
								`eduvars'	`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	in_sample==1,	///
						ols lambda(`lambdaval') notpen(`regionvars'	`timevars')
			est	store	lasso_step1_manual
			lasso2, postresults
			
			
			gen	lasso_step1_sample=1	if	e(sample)==1		

	
			*	Manually run post-lasso
				global selected_step1_lasso `e(selected)'	`e(notpen)'
				svy:	reg `depvar' ${selected_step1_lasso}	if	lasso_step1_sample==1
				est store postlasso_step1_lse
				
				*	Predict conditional means and variance from Post-LASSO
				predict double mean1_foodexp_lasso, xb
				predict double e1_foodexp_lasso, r
				gen e1_foodexp_sq_lasso = (e1_foodexp_lasso)^2
				
				shapley2, stat(r2)	indepvars(`e(selected)')
				est	store	postlasso_step1_shapley
	
		}	//	Step 1

		*	Step 2
		if	`run_lasso_step2'==1	{
		
			local	depvar	e1_foodexp_sq_lasso
			
			*	LASSO
			**	Update (2020/9/4) lopt gives lambda=1052.087, giving too many outputs, and lse ~ exp(10), which gives too little variables. We use somewhere between
			**	As of 2020/5/20, the following cvlasso not only takes too much time, but neither lopt nor lse work - lopt (ln(lambda)=20.78) gives too many variables, and lse (ln(lambda)=24.32) reduces everything.
			**	Therefore, I run regular lasso using "lasso2" and the lambda value in between (ln(lambda)=22.7)
			
						
			/*	
			cvlasso	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
								`eduvars'	`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	lasso_step1_sample==1,	///
						/*lopt*/ lse	seed(20200505)	 /*rolling	h(1) fe	prestd 	postres		ols*/	notpen(`regionvars'	`timevars')	plotcv
			est	store	lasso_step2_lse			
			*** Somehow, the lambda from lopt does not reduce dimensionality a lot, and the lambda from lse does not keep ANY RHS varaible.
			*** For now (2020/5/18), we will just use the residual from lopt, but we could improve it later (ex. using the lambda somewhere between lopt and lse)
			
			*	Manually run post-lasso
			cvlasso, postresult lse	//	Need this command to use `e(selected)' macro
			*/
			
			
			set	seed	20205020
			local	lambdaval=exp(8.3)
			lasso2	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
								`eduvars'	`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	lasso_step1_sample==1,	///
						ols lambda(`lambdaval') notpen(`regionvars'	`timevars')
			est	store	lasso_step2_manual
			
			
			gen	lasso_step2_sample=1	if	e(sample)==1	
			lasso2, postresults
			global selected_step2_lasso `e(selected)'	`e(notpen)'
			svy:	reg `depvar' ${selected_step2_lasso}	if	lasso_step2_sample==1
			
			est store postlasso_step2_manual
			predict	double	var1_foodexp_lasso, xb
			
			*	lopt gives too many variables, so we won't use decomposition for now.
			shapley2, stat(r2)	indepvars(`e(selected)')
			est	store	lasso_step2_shapley
			
			
		}	//	Step 2
		
		*	Step 3
		if	`run_lasso_step3'==1	{
		
			
			*	Assume the outcome variable follows the Gamma distribution
			gen alpha1_foodexp_pc_lasso = (mean1_foodexp_lasso)^2 / var1_foodexp_lasso	//	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_lasso = var1_foodexp_lasso / mean1_foodexp_lasso	//	scale parameter of Gamma (beta)
			
			*	Construct CDF
			foreach	plan	in	thrifty low moderate liberal	{
			
				*	Generate resilience score. 
				*	Should include in-sample as well as out-of-sample to validate its OOS performance
				gen rho1_foodexp_pc_`plan'_ls = gammaptail(alpha1_foodexp_pc_lasso, foodexp_W_`plan'/beta1_foodexp_pc_lasso)	/*if	(lasso_step1_sample==1)	&	(lasso_step2_sample==1)*/	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	rho1_foodexp_pc_`plan'_ls "Resilience score (LASSO), `plan' plan"
				
			}
			
			**	Again, the following cvlasso takes too much time
			**	For now I will use ln(lambda)=4.36, the one found from cvlasso, lse below
			**	If there is major change in the specification, the following cvlasso should be executed
			**	As of 2020/9/4, we do not need the rest of the step 3 codes below.
			
			/*
			
				loc	depvar	rho1_foodexp_pc_thrifty_ls	//	only for thirfty plan
				
				/*
				cvlasso	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
					`familyvars'	`eduvars'	`foodvars'	`childvars'	`changevars'	if	 lasso_step1_sample==1	/*inrange(year,9,10)*/,	///
					/*lopt*/ lse	/*rolling	h(1)*/	seed(20200505)	 /*fe	prestd 	postres	ols*/	plotcv 
				est	store	lasso_step3_lse	
				
				cvlasso, postresult lse
				*/
				
				set	seed	20205020
				local	lambdaval=exp(6.5)
				lasso2	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
								`familyvars'	`eduvars'	`foodvars'	`childvars'	`regionvars'	if	lasso_step1_sample==1,	///
							ols lambda(`lambdaval') 
				
				est	store	lasso_step3_manual
				lasso2, postresults
				
				
				gen	lasso_step3_sample=1	if	e(sample)==1
				
				
				global selected_step3_lasso `e(selected)'
				loc	depvar	rho1_foodexp_pc_thrifty_ls
				svy:	reg `depvar' ${selected_step3_lasso}	if	lasso_step3_sample==1
				est store postlasso_step3_lse
				
				*	lopt gives too many variables, so we won't use decomposition for now.
				shapley2, stat(r2)
				est	store	lasso_step3_shapley
			
			*/
			
		}	//	Step 3
		
	}	//	LASSO
	
	*	Random Forest
	if	`run_rf'==1	{
		
		*	Variable Selection
		local	statevars	lag_food_exp_pc_1 /*-lag_avg_foodexp_pc_5*/	//	RF allows non-linearity, thus need not include higher polynomial terms
		local	healthvars	alcohol_head alcohol_spouse	smoke_head smoke_spouse	phys_disab_head phys_disab_spouse
		local	demovars	age_head_fam	/*age_head_fam_sq*/	HH_race_white-HH_race_other	marital_status_fam_enum1-marital_status_fam_enum5	///
							HH_female-gender_head_fam_enum2	age_spouse	/*age_spouse_sq*/	///
							housing_status_enum1-housing_status_enum3	veteran_head veteran_spouse
		local	econvars	ln_income_pc	ln_wealth_pc	sup_outside_FU	tax_item_deduct	retire_plan_head retire_plan_spouse	annuities_IRA	/*income_pc	avg_income_pc_sq	wealth_pc	avg_wealth_pc_sq*/
		local	empvars		emp_HH_simple	emp_spouse_simple
		local	familyvars	num_FU_fam ratio_child	/*num_child_fam*/	/*family_comp_change_enum1-family_comp_change_enum9*/	couple_status_enum1-couple_status_enum5	/*head_status*/ spouse_new
		local	eduvars		highdegree_NoHS	highdegree_HS		highdegree_somecol	highdegree_col	highdegree_NoHS_spouse			highdegree_HS_spouse		highdegree_somecol_spouse	highdegree_col_spouse
							/*attend_college_head attend_college_spouse	college_yrs_head college_yrs_spouse	///
							hs_completed_head	college_completed	other_degree_head	grade_comp_head_fam	///
							hs_completed_head_interact college_completed_interact other_degree_head_interact	///
							hs_completed_spouse	college_comp_spouse	other_degree_spouse	grade_comp_spouse	///
							hs_completed_spouse_interact college_comp_spouse_interact other_degree_spouse_interact	*/
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	/*meal_together*/	elderly_meal
		local	childvars	child_daycare_any child_daycare_FSP child_daycare_snack	
		local	changevars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	state_resid_fam_enum1-state_resid_fam_enum52
		local	timevars	year_enum1-year_enum10
		
		
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
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	in_sample==1, type(reg)	seed(20200505) iterations(`i') numvars(1)
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
		
		*	100 seems to be optimal
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
											`foodvars'	`childvars'	`changevars'	`regionvars'	if	in_sample==1, type(reg)	seed(20200505) iterations(100) numvars(`i')
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
		}	//	tune_numvars
		
		
		*	Step 1
		if	`run_rf_step1'==1	{
			
			loc	depvar	food_exp_pc
			rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	in_sample==1, type(reg)	iterations(80)	numvars(23)	seed(20200505) 
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
			
			predict	mean1_foodexp_rf
			*	"rforest" cannot predict residual, so we need to compute it manually
			gen	double e1_foodexp_rf	=	food_exp_pc	-	mean1_foodexp_rf
			gen e1_foodexp_sq_rf = (e1_foodexp_rf)^2
			
		}	//	Step 1
		
		*	Step 2
		if	`run_rf_step2'==1	{
			
			loc	depvar	e1_foodexp_sq_rf
			rforest	`depvar'	`statevars'		`demovars'	`econvars'	`empvars'	`healthvars'	`familyvars'	`eduvars'	///
									`foodvars'	`childvars'	`changevars'	`regionvars'	`timevars'	if	in_sample==1, type(reg)	iterations(80)	numvars(23)	seed(20200505) 
			
			* Variable importance plot
			matrix importance_var = e(importance)
			svmat importance_var
			generate importid_var=""
			local mynames: rownames importance_var
			local k: word count `mynames'
			if `k'>_N {
				set obs `k'
			}
			forvalues i = 1(1)`k' {
				local aword: word `i' of `mynames'
				local alabel: variable label `aword'
				if ("`alabel'"!="") qui replace importid_var= "`alabel'" in `i'
				else qui replace importid_var= "`aword'" in `i'
			}
			gsort	-importance_var1
			graph hbar (mean) importance_var1	in	1/12, over(importid_var, sort(1) label(labsize(2))) ytitle(Importance) title(Feature Importance for Conditional Variance)
			graph	export	"${PSID_outRaw}/rf_feature_importance_step2.png", replace
			graph	close
			
			predict	var1_foodexp_rf
		}	//	Step 2
		
		
		*	Step 3
		if	`run_rf_step3'==1	{
			
			*	Assume the outcome variable follows the Gamma distribution
			gen alpha1_foodexp_pc_rf = (mean1_foodexp_rf)^2 / var1_foodexp_rf	//	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_rf = var1_foodexp_rf / mean1_foodexp_rf	//	scale parameter of Gamma (beta)
			
			*	Construct CDF
			foreach	plan	in	thrifty low moderate liberal	{
				
				*	Generate resilience score. 
				*	Should include in-sample as well as out-of-sample to validate its OOS performance
				gen rho1_foodexp_pc_`plan'_rf = gammaptail(alpha1_foodexp_pc_rf, foodexp_W_`plan'/beta1_foodexp_pc_rf)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	rho1_foodexp_pc_`plan'_rf "Resilience score (Random Forest), `plan' plan"
			}
			
			*	As of 2020-09-05, we don't need the rest of the step 3 code below, as we will use OLS
			
			/*
			tempfile	bef_rf_step3
			save		`bef_rf_step3'
				keep	if	!mi(rho1_foodexp_pc_thrifty_rf)
				loc	depvar	rho1_foodexp_pc_thrifty_rf
				rforest	`depvar'	`statevars'		`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
										`foodvars'	`childvars'	`changevars'	`regionvars'	if	in_sample==1, type(reg)	iterations(100)	numvars(21)	seed(20200505) 
				predict	rs_rf_hat
				
				* Variable importance plot
				matrix importance_rs = e(importance)
				svmat importance_rs
				generate importid_rs=""
				local mynames: rownames importance_rs
				local k: word count `mynames'
				if `k'>_N {
					set obs `k'
				}
				forvalues i = 1(1)`k' {
					local aword: word `i' of `mynames'
					local alabel: variable label `aword'
					if ("`alabel'"!="") qui replace importid_rs= "`alabel'" in `i'
					else qui replace importid_rs= "`aword'" in `i'
				}
				gsort	-importance_rs1
				graph hbar (mean) importance_rs1	in	1/12, over(importid_var, sort(1) label(labsize(2))) ytitle(Importance) title(Feature Importance for Resilience Score)
				graph	export	"${PSID_outRaw}/rf_feature_importance_step3.png", replace
				graph	close
			use		`bef_rf_step3', clear
			*/
		}	//	Step 3		
	}	//	Random Forest
	
	
	*	Validation
	local	run_validation	1
		local	CB_cat	1		//	Generate FS category variables from CB measure
		local	valid_others	1	//	rank correlation, figure, etc.

	*	Validation	
	if	`run_validation'==1	{
		
		if	`CB_cat'==1	{
		
			
			/*	// We no longer calculate CB threshold value from the PSID data. We use annual USDA report below.
			*	Check the ratio of food security category for each year
			foreach	year	in	1	2	3	9	10	{
				
				cap	mat	drop	fs_`year'_freq	fs_`year'_ratio
				qui	tab	fs_cat_fam_simp if year==`year',	matcell(fs_`year'_freq)
				mat	define	fs_`year'_ratio	=	fs_`year'_freq	/	r(N)
				local	prop_insecure_`year'	=	round(fs_`year'_ratio[1,1]*1000)
				mat list fs_`year'_ratio
				di "proportion is `prop_insecure_`year''"
				mat	drop	fs_`year'_freq	fs_`year'_ratio	
			}
			*/
			
			*	For food security threshold value, we use the ratio from the annual USDA reports.
			*	(https://www.ers.usda.gov/topics/food-nutrition-assistance/food-security-in-the-us/readings/#reports)
			
			local	prop_insecure_1		=	101	// 1999: 10.1% are food insecure
			local	prop_insecure_2		=	107	// 2001: 10.7% are food insecure
			local	prop_insecure_3		=	112	// 2003: 11.2% are food insecure
			local	prop_insecure_4		=	110	// 2005: 11.0% are food insecure
			local	prop_insecure_5		=	111	// 2007: 11.1% are food insecure
			local	prop_insecure_6		=	147	// 2009: 14.7% are food insecure
			local	prop_insecure_7		=	149	// 2011: 14.9% are food insecure
			local	prop_insecure_8		=	143	// 2013: 14.3% are food insecure
			local	prop_insecure_9		=	127	// 2015: 12.7% are food insecure
			local	prop_insecure_10	=	118	// 2017: 11.8% are food insecure
		
			*	Categorize food security status based on the CB score.
			foreach	type	in	ols	ls	rf	{
				foreach	plan	in	thrifty /*low moderate liberal*/	{
					
					gen		rho1_`plan'_IS_`type'	=	0	if	!mi(rho1_foodexp_pc_`plan'_`type')	//	Food insecure
					gen		rho1_`plan'_HS_`type'	=	0	if	!mi(rho1_foodexp_pc_`plan'_`type')	//	Highly secure
					
					/*	Since we are currently using the USDA FS status as an external threshold for FS/FI categorization using CB measure,
						, we cannot categorize when there is no data of the USDA status unless we use other external source. */
					*replace	rho1_`plan'_IS_`type'=.	if	!inlist(year,2,3,9,10)
					*replace	rho1_`plan'_HS_`type'=.	if	!inlist(year,2,3,9,10)
					
					foreach	year	in	2	3	4	5	6	7	8	9	10	{
					
						xtile `plan'_pctile_`type'_`year' = rho1_foodexp_pc_`plan'_`type' if !mi(rho1_foodexp_pc_`plan'_`type')	&	year==`year', nq(1000)
							
						replace	rho1_`plan'_IS_`type'	=	1	if	inrange(`plan'_pctile_`type'_`year',1,`prop_insecure_`year'')	&	year==`year'	//	Food insecure
						replace	rho1_`plan'_HS_`type'	=	1	if	inrange(`plan'_pctile_`type'_`year',`prop_insecure_`year''+1,1000)	&	year==`year'	//	Highly secure
					}
					
					label	var	rho1_`plan'_IS_`type'	"Food Insecure (CB) (Thrifty)"
					label	var	rho1_`plan'_HS_`type'	"Highly Food secure (CB) (Thrifty)"
					
				}	//	plan
			}	//	type
		}	//	CB_cat

	*svy: tab rho1_thrifty_HS_lasso fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_ls), cell
	*svy: tab rho1_low_HS_lasso fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_low_ls), cell
	*svy: tab rho1_moderate_HS_lasso fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_moderate_ls), cell
	*svy: tab rho1_liberal_HS_lasso fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal_ls), cell


	*svy: tab rho1_liberal_HS_lasso fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_ls) & sample_source==1, cell
	*svy: tab rho1_liberal_HS_lasso fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_ls) & sample_source==2, cell
	*svy: tab rho1_liberal_HS_lasso fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty_ls) & sample_source==3, cell
	
	if	`valid_others'==1	{
	
		*	Summary Statistics of Indicies
		summ	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	///
				if	inlist(year,2,3,9,10)
		
		*	Spearman's rank correlation
			
			*	Pooled
			spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if inlist(year,2,3,9,10),	stats(rho obs p)
			
			*	By year
			spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==2,	stats(rho obs p)
			spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==3,	stats(rho obs p)
			spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==9,	stats(rho obs p)
			spearman	fs_scale_fam_rescale	rho1_foodexp_pc_thrifty_ols	rho1_foodexp_pc_thrifty_ls	rho1_foodexp_pc_thrifty_rf	if year==10, stats(rho obs p)
		
		*	Kolmogorov–Smirnov (between LASSO and RF)
			
			*	Prepare dataset
			*	K-S test cannot compare distributions from different variables, thus we need to create 1 variable that has all indicators
			
				expand	4
				loc	var	indicator_group
				bys	fam_ID_1999	year:	gen	`var'	=	_n
				label	define	`var'	1	"USDA"	2	"CB (LASSO)"	3	"CB (R.Forest)"	4	"FSPS (GLM)", replace
				label	values	`var'	`var'
				lab	var	`var'	"Indicator Group"
					
				foreach	plan	in	thrifty	low	moderate	liberal	{

					loc	generate_indicator	1
					if	`generate_indicator'==1	{
					
						gen		indicator_`plan'	=	.n
						replace	indicator_`plan'	=	fs_scale_fam_rescale		if	inlist(1,in_sample,out_of_sample)	&	indicator_group==1	//	USDA FS (rescaled)
						replace	indicator_`plan'	=	rho1_foodexp_pc_`plan'_ls	if	inlist(1,in_sample,out_of_sample)	&	indicator_group==2	//	CB (LASSO)
						replace	indicator_`plan'	=	rho1_foodexp_pc_`plan'_rf	if	inlist(1,in_sample,out_of_sample)	&	indicator_group==3	//	CB (Random Forest)
						replace	indicator_`plan'	=	rho1_foodexp_pc_`plan'_ols	if	inlist(1,in_sample,out_of_sample)	&	indicator_group==4	//	CB (GLM)
						lab	var	indicator_`plan'	"Indicators (USDA score or Resilence score)"
					
						*	Conduct K-S test
						di	"K-S Test, `plan' food plan"
						ksmirnov	indicator_`plan'	if	inrange(year,9,10)	&	inlist(indicator_group,1,2), by(indicator_group)	//	USDA FS vs CB(LASSO)
						ksmirnov	indicator_`plan'	if	inrange(year,9,10)	&	inlist(indicator_group,1,3), by(indicator_group)	//	USDA FS vs CB(Random Forest)
						ksmirnov	indicator_`plan'	if	inrange(year,9,10)	&	inlist(indicator_group,2,3), by(indicator_group)	//	CB(LASSO) vs CB(Random Forest)
						ksmirnov	indicator_`plan'	if	inrange(year,9,10)	&	inlist(indicator_group,1,4), by(indicator_group)	//	USDA FS vs CB(GLM)
						
					}	//	gen_dinciator
			
			
				*	Distribution (K-density)
				/*
				graph twoway 	(kdensity fs_scale_fam_rescale	if	inrange(year,9,10))	///
								(kdensity rho1_foodexp_pc_`plan'_ls	if	inrange(year,9,10))	///
								(kdensity rho1_foodexp_pc_`plan'_rf	if	inrange(year,9,10)),	///
								title (Distribution of Indicators)	///
								subtitle(USDA food security score and resilience score)	///
								note(note: "constructed from in-sample(2015) and out-of-sample(2017)" "RS cut-off is generated based on `plan' food plan")	///
								legend(lab (1 "USDA scale") lab(2 "RS (LASSO)") lab(3 "RS (R.Forest)")	rows(1))
				
				graph	export	"${PSID_outRaw}/Indicator_Distribution_`plan'.png", replace
				*/
				
			}	//	plan
										
			
			*	Output graph and combine them
			graph twoway 		(kdensity fs_scale_fam_rescale	if	inlist(year,1,2,3,9,10))	///
								(kdensity rho1_foodexp_pc_thrifty_ols	if	inlist(year,1,2,3,9,10)),	///
								title (Thrifty plan)		name(thrifty, replace)		///
								legend(lab (1 "USDA scale") lab(2 "FSPS") rows(1))
								
			graph twoway 		(kdensity fs_scale_fam_rescale	if	inlist(year,1,2,3,9,10))	///
								(kdensity rho1_foodexp_pc_low_ols	if	inlist(year,1,2,3,9,10)),	///
								title (Low plan)		name(low, replace)		///
								legend(lab (1 "USDA scale") lab(2 "FSPS") rows(1))
								
			graph twoway 		(kdensity fs_scale_fam_rescale	if	inlist(year,1,2,3,9,10))	///
								(kdensity rho1_foodexp_pc_moderate_ols	if	inlist(year,1,2,3,9,10)),	///
								title (Moderate plan)		name(moderate, replace)		///
								legend(lab (1 "USDA scale") lab(2 "FSPS") rows(1))
								
			graph twoway	 	(kdensity fs_scale_fam_rescale	if	inlist(year,1,2,3,9,10))	///
								(kdensity rho1_foodexp_pc_liberal_ols	if	inlist(year,1,2,3,9,10)),	///
								title (Liberal plan)	name(liberal, replace)		///
								legend(lab (1 "USDA scale") lab(2 "FSPS") rows(1))
								
			grc1leg2		thrifty	low	moderate	liberal,	title(Distribution of Food Security Indicators) legendfrom(thrifty)	///
							note(note: "the sample includes the waves the USDA scale is constructed (1999,2001,2003,2015,2017)"	///
								"USDA scale is rescaled such that it varies from 0 to 1 and the greater the scale" ///
								"and the higher the scale, the more likely a household is food secure")
							
			graph	export	"${PSID_outRaw}/dist_indicators_plan.png", replace
	

			drop	indicator_group indicator_thrifty indicator_low indicator_moderate indicator_liberal
			duplicates drop
			
				
			*	Validation Result
				sort	fam_ID_1999	year
				label	define	valid_result	1	"Classified as food secure"	///
												2	"Mis-classified as food secure"	///
												3	"Mis-classified as food insecure"	///
												4	"Classified as food insecure"
				
				*	USDA
				gen		valid_result_USDA	=	1	if	inrange(year,10,10)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp==1
				replace	valid_result_USDA	=	2	if	inrange(year,10,10)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp!=1
				replace	valid_result_USDA	=	3	if	inrange(year,10,10)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp==1
				replace	valid_result_USDA	=	4	if	inrange(year,10,10)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp!=1
				
					*	By sub-sample
					forval	sampleno=1/3	{
						
						gen		valid_result_USDA_`sampleno'	=	.
						replace	valid_result_USDA_`sampleno'	=	1	if	inrange(year,10,10)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp==1	&	sample_source==`sampleno'
						replace	valid_result_USDA_`sampleno'	=	2	if	inrange(year,10,10)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp!=1	&	sample_source==`sampleno'
						replace	valid_result_USDA_`sampleno'	=	3	if	inrange(year,10,10)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp==1	&	sample_source==`sampleno'
						replace	valid_result_USDA_`sampleno'	=	4	if	inrange(year,10,10)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp!=1	&	sample_source==`sampleno'
						
					}
					
					rename	(valid_result_USDA_1	valid_result_USDA_2		valid_result_USDA_3)	///
							(valid_result_USDA_SRC	valid_result_USDA_SEO	valid_result_USDA_IMM)
							
					label	var	valid_result_USDA		"Validation Result of USDA"
					label	var	valid_result_USDA_SRC	"Validation Result of USDA in SRC"
					label	var	valid_result_USDA_SEO	"Validation Result of USDA in SEO"
					label	var	valid_result_USDA_IMM	"Validation Result of USDA in Immigrants"
				
				
				*	GLM, LASSO and RF
				foreach	type	in	ols	ls	rf	{
					
					*	All sample
					
					gen		valid_result_`type'	=	.
					replace	valid_result_`type'	=	1	if	inrange(year,10,10)	&	l.rho1_thrifty_HS_`type'==1	&	fs_scale_fam_rescale==1
					replace	valid_result_`type'	=	2	if	inrange(year,10,10)	&	l.rho1_thrifty_HS_`type'==1	&	fs_scale_fam_rescale!=1
					replace	valid_result_`type'	=	3	if	inrange(year,10,10)	&	l.rho1_thrifty_HS_`type'==0	&	fs_scale_fam_rescale==1
					replace	valid_result_`type'	=	4	if	inrange(year,10,10)	&	l.rho1_thrifty_HS_`type'==0	&	fs_scale_fam_rescale!=1
					label	var	valid_result_`type'	"Validation Result of `type'"
					
					*	By subsample
					forval	sampleno=1/3	{
						
						gen		valid_result_`type'_`sampleno'	=	.
						replace	valid_result_`type'_`sampleno'	=	1	if	inrange(year,10,10)	&	l.rho1_thrifty_HS_`type'==1	&	fs_scale_fam_rescale==1	&	sample_source==`sampleno'
						replace	valid_result_`type'_`sampleno'	=	2	if	inrange(year,10,10)	&	l.rho1_thrifty_HS_`type'==1	&	fs_scale_fam_rescale!=1	&	sample_source==`sampleno'
						replace	valid_result_`type'_`sampleno'	=	3	if	inrange(year,10,10)	&	l.rho1_thrifty_HS_`type'==0	&	fs_scale_fam_rescale==1	&	sample_source==`sampleno'
						replace	valid_result_`type'_`sampleno'	=	4	if	inrange(year,10,10)	&	l.rho1_thrifty_HS_`type'==0	&	fs_scale_fam_rescale!=1	&	sample_source==`sampleno'
						
					}
					
					rename	(valid_result_`type'_1		valid_result_`type'_2	valid_result_`type'_3)	///
							(valid_result_`type'_SRC	valid_result_`type'_SEO	valid_result_`type'_IMM)
							
					label	var	valid_result_`type'_SRC	"Validation Result of `type' in SRC"
					label	var	valid_result_`type'_SEO	"Validation Result of `type' in SEO"
					label	var	valid_result_`type'_IMM	"Validation Result of `type' in Immigrants"
				}
				
				label	values	valid_result_*	valid_result
				
				
			*	Scatterplot
				*	Compare resilience status in 2015 (in-sample) and USDA food security score in 2017 (out-of-sample)
				*	To do this, we need the threshold resilience score for being food secure in 2015 
				
				sort	fam_ID_1999	year
				
				sort rho1_foodexp_pc_thrifty_ols
				br rho1_foodexp_pc_thrifty_ols rho1_thrifty_HS_ols if year==9
				
				sort rho1_foodexp_pc_thrifty_ls
				br rho1_foodexp_pc_thrifty_ls rho1_thrifty_HS_ls if year==9
				
				sort rho1_foodexp_pc_thrifty_rf
				br rho1_foodexp_pc_thrifty_rf rho1_thrifty_HS_rf if year==9
				
				
				*	As of 2020/9/5, threshold scores are 0.4020(OLS), 0.4527(LASSO), 0.1540(R.Forest)
				global	thresval_ols=0.4007
				global	thresval_ls=0.4543
				global	thresval_rf=0.1611
				
			*	Validation table
			
			eststo drop	valid_result*
			
			foreach	type in USDA	ols	ls	rf	{
				
				di "Validation result of `type' in pooled sample"
				svy: proportion valid_result_`type'
				estadd matrix mean = r(table)[1,1...]
				eststo	valid_result_`type'
						
				
				foreach sample in SRC SEO IMM	{
					
					di "Validation result of `type' in `sample'"
					*svy: proportion	valid_result_`type'_`sample'
					svy, subpop(sample_source_`sample'): proportion valid_result_`type' // Using "subpop" option gives accurate standard error, but it doesn't matter in this case as it still gives the same point estimate.
					estadd matrix mean = r(table)[1,1...]
					estadd scalar N = e(N_sub), replace
					eststo	valid_result_`type'_`sample'
		
				}
								
			}				
			
		local	result_output_list	valid_result_USDA	valid_result_USDA_SRC	valid_result_USDA_SEO	valid_result_USDA_IMM	///
									valid_result_ols	valid_result_ols_SRC	valid_result_ols_SEO	valid_result_ols_IMM	///
									valid_result_ls		valid_result_ls_SRC		valid_result_ls_SEO		valid_result_ls_IMM	///
									valid_result_rf		valid_result_rf_SRC		valid_result_rf_SEO		valid_result_rf_IMM
		
		esttab `result_output_list' using "${PSID_outRaw}/valid_result.csv", replace ///
		cells("mean(pattern(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants")	///
		title (Validation of 2017 Food Security Prediction) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ csv ///
		addnotes(Sample include households surveyed in 2017)
		
		esttab `result_output_list' using "${PSID_outRaw}/valid_result.tex", replace ///
		cells("mean(pattern(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants" "All" "SRC" "SEO" "Immigrants")	///
		title (Validation of 2017 Food Security Prediction) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ tex ///
		addnotes(Sample include households surveyed in 2017)
		
		
			*	Predictive Power Plot		
			sort	fam_ID_1999	year
				*	USDA
					
					*	All sample
					tab	valid_result_USDA	if	inrange(year,10,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==4, msymbol(square)),	///
									xline(1)	yline(1)	xtitle(USDA scale in 2015)	ytitle(USDA scale in 2017)	///
									title(Validation of Food Security Status Prediction)	name(USDA_all, replace)	///
									legend(lab (1 "Classified as food secure") lab(2 "Mis-Classified as food secure") lab(3 "Mis-Classified as food insecure")	lab(4 "Classified as food insecure")	rows(2))	///
									subtitle(USDA Measure)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_USDA_all.png", replace
					graph	close
					
				
				*	GLM
			
					*	All sample
					tab	valid_result_ols	if	inrange(year,10,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==4, msymbol(square)),	///
									xline(${thresval_ols})	yline(1)	xtitle(FSPS in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Prediction of Food Security in 2017) name(GLM_all, replace)	///
									legend(lab (1 "Classified as food secure(72%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(12%)")	lab(4 "Classified as food insecure(7%)")	rows(2))	///
									subtitle(FSPS)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_GLM_all.png", replace
					graph	close
					
			/*		
				*	LASSO
					
					*	All sample
					tab	valid_result_ls	if	inrange(year,10,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==4, msymbol(square)),	///
									xline(${thresval_ls})	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(LASSO_all, replace)	///
									legend(lab (1 "Classified as food secure(72%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(12%)")	lab(4 "Classified as food insecure(7%)")	rows(2))	///
									subtitle(FSPS by LASSO)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_LASSO_all.png", replace
					graph	close
					
				
				*	Random Forest
					
					*	All sample
					tab	valid_result_rf	if	inrange(year,10,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==4, msymbol(square)),	///
									xline(${thresval_rf})	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(RF_all, replace)	///
									legend(lab (1 "Classified as food secure(72%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(11%)")	lab(4 "Classified as food insecure(7%)")	rows(2))	///
									subtitle(FSPS by RF)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_RF_all.png", replace
					graph	close
				*/	

			 grc1leg2		USDA_all	GLM_all	/*LASSO_all	RF_all*/,	legendfrom(USDA_all)	 /*xtob1title*/	ytol1title 	maintotoptitle ///
			 note("Sample include households survey responses in 2017")
			 
			graph	export	"${PSID_outRaw}/Predictive_Power_Plot.png", replace
			graph	close
		
					
			
		*	Out-of-sample wellbeing predictive accuracy of resilience measures (RMSE)
		*	Bivariate regression of USDA food security score on the previous score (USDA, CB scores under different construction methods)
		
			*	Mean of the outcome
			qui	summarize	fs_scale_fam_rescale	if	inrange(year,10,10)
			scalar	USDA_mean	=	r(mean)
			
			*	USDA
							
				*	All sample
				qui	reg	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	inrange(year,10,10)
				local	USDA_rmse_all			=	e(rmse)
				local	USDA_rmse_all_bymean	=	e(rmse)	/	USDA_mean
				
				*	SEO & Imm
				qui	reg	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	inrange(year,10,10)	&	inrange(sample_source,2,3)
				local	USDA_rmse_sub			=	e(rmse)
				local	USDA_rmse_sub_bymean	=	e(rmse)	/	USDA_mean
				
			*	FSPS scores
			foreach	type	in	ols	ls	rf	{
				
				*	All sample
				qui	reg	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_`type'	if	inrange(year,10,10)
				local	`type'_rmse_all	=	e(rmse)
				local	`type'_rmse_all_bymean	=	e(rmse)	/	USDA_mean
				
				*	Sub sample
				qui	reg	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_`type'	if	inrange(year,10,10)	&	inrange(sample_source,2,3)
				local	`type'_rmse_sub	=	e(rmse)
				local	`type'_rmse_sub_bymean	=	e(rmse)	/	USDA_mean
				
				
			}
			
			*	Divide RMSE by mean outcome
			*	if	greater than 0.5, it is not good for prediction. If less than 0.2, then it is good for predion.

			cap	mat	drop	rmse_all	rmse_eval_all	rmse_all	rmse_sub	rmse_eval_sub	rmse_eval_table
			mat	define		rmse_all		=	`USDA_rmse_all'	\	`ols_rmse_all'	\	`ls_rmse_all'	\	`rf_rmse_all'
			mat	define		rmse_eval_all	=	`USDA_rmse_all_bymean'	\	`ols_rmse_all_bymean'	\	`ls_rmse_all_bymean'	\	`rf_rmse_all_bymean'
			mat	define		rmse_sub		=	`USDA_rmse_sub'	\	`ols_rmse_sub'	\	`ls_rmse_sub'	\	`rf_rmse_sub'
			mat	define		rmse_eval_sub	=	`USDA_rmse_sub_bymean'	\	`ols_rmse_sub_bymean'	\	`ls_rmse_sub_bymean'	\	`rf_rmse_sub_bymean'

			mat	define	rmse_eval_table	=	rmse_all,	rmse_eval_all,	rmse_sub,	rmse_eval_sub
			mat	list	rmse_eval_table
			
			/*
			reg	fs_scale_fam_rescale	l.rho1_avg_foodexp_pc_thrifty_ols	if	inrange(year,9,10)	//	OLS
			reg	fs_scale_fam_rescale	l.rho1_avg_foodexp_pc_thrifty_ls	if	inrange(year,9,10)	//	LASSO
			reg	fs_scale_fam_rescale	l.rho1_avg_foodexp_pc_thrifty_rf	if	inrange(year,9,10)	//	Random Forest
			*/
			
		}	// valid_others
	}	//	validation
		
		
	*	Association
	local	model_check	0	//	varying LHS
	local	specification_check	1	//	varying RHS
		local	prep_spec	1
		local	spec_analysis	1
		local	stationary_check	0
	local	indicator_comparison	0
	local	pre_post	0
	local	by_year	0	

	
							
	
	if	`indicator_comparison'==1	{
	
		
		local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	HH_female	ib1.race_head_cat	marital_status_cat
		local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ ib2.grade_comp_cat	
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	ib0.state_resid_fam	
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.non_working_age	///
								c.HH_female#c.non_working_age	///
								c.ln_income_pc#c.HH_female#c.non_working_age	///
								c.no_longer_married#c.HH_female
		local	timevars	i.year
		
		local	MEvars	c.age_head_fam	HH_female	ib1.race_head_cat	marital_status_cat	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'	// c.non_working_age	
			
		*	Regression of 4 different indicators on food security correlates
		
		local	depvar	fs_scale_fam_rescale
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'
		est	store	USDA_continuous
		eststo	USDA_cont_ME: margins,	dydx(`MEvars')	post	
		
		local	depvar	rho1_foodexp_pc_thrifty_ols
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'
		est	store	CB_continuous
		eststo	CB_cont_ME: margins,	dydx(`MEvars')	post	
		
		local	depvar	fs_cat_fam_simp
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'
		est	store	USDA_binary
		eststo	USDA_bin_ME: margins,	dydx(`MEvars')	post	
		
		local	depvar	rho1_thrifty_HS_ols
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'
		est	store	CB_binary
		eststo	CB_bin_ME: margins,	dydx(`MEvars')	post	
		
		
		*	Output
		esttab	USDA_continuous	CB_continuous	USDA_binary	CB_binary	using "${PSID_outRaw}/USDA_CB_pooled.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Average Marginal Effects on Food Security Status) replace
				
		esttab	USDA_continuous	CB_continuous	USDA_binary	CB_binary	using "${PSID_outRaw}/USDA_CB_pooled.tex", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Average Marginal Effects on Food Security Status) replace
				
		esttab	USDA_cont_ME	CB_cont_ME	USDA_bin_ME	CB_bin_ME	using "${PSID_outRaw}/USDA_CB_ME.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Average Marginal Effects on Food Security Status) replace
				
		esttab	USDA_cont_ME	CB_cont_ME	USDA_bin_ME	CB_bin_ME	using "${PSID_outRaw}/USDA_CB_ME.tex", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Average Marginal Effects on Food Security Status) replace
				
		esttab	USDA_continuous	CB_continuous	USDA_binary	CB_binary	USDA_cont_ME	CB_cont_ME	USDA_bin_ME	CB_bin_ME	using "${PSID_outRaw}/USDA_CB_all.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Average Marginal Effects on Food Security Status) replace
		
	}
	
	if	`pre_post'==1	{
		
		cap	drop	pre_recession post_recession
		gen		pre_recession	=	0
		replace	pre_recession	=	1	if	inrange(year,1,5)	//	Wave 1999 to 2007
		gen		post_recession	=	0
		replace	post_recession	=	1	if	inrange(year,6,10)	//	Wave 2009 to 2017
	
		local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	c.HH_female	c.HH_race_black c.HH_race_other	c.marital_status_cat
		local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ c.highest_grade1 c.highest_grade3 c.highest_grade4	
		local	empvars		c.emp_HH_simple
		local	healthvars	c.phys_disab_head
		local	foodvars	c.food_stamp_used_1yr	/*child_meal_assist elderly_meal*/	c.WIC_received_last	
		local	shockvars	c.no_longer_employed	c.no_longer_married	c.no_longer_own_house	c.became_disabled
		local	regionvars	ib0.state_resid_fam	
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.non_working_age	///
								c.HH_female#c.non_working_age	///
								c.ln_income_pc#c.HH_female#c.non_working_age	///
								c.no_longer_married#c.HH_female
		local	timevars	i.year
		
		
		*	Benchmark
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		/*`interactvars'*/	`regionvars'	`timevars'
		est	store	CB_benchmark
		
		*	With interaction, pooled
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		est	store	CB_interact
		
		*	With interaction, pre-recession
		svy, subpop(pre_recession):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		estadd scalar N = e(N_sub), replace
		est	store	CB_pre_recession
		
		*	With interaction, post-recession
		svy, subpop(post_recession):	reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		estadd scalar N = e(N_sub), replace
		est	store	CB_post_recession
		
		*	Combined regression for chow test
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'	///
					i.post_recession	i.post_recession#(`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars')
		
		est	store	CB_prepost_combined
		contrast	post_recession	post_recession#(`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'), overall	post
		est	store	chow_test
		
		*	Display output
		
		esttab	CB_interact	CB_pre_recession	CB_post_recession	using "${PSID_outRaw}/CB_pre_post.tex", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
				title(Parameter Stability between Pre- and Post- Recession) replace
		
		esttab	CB_interact	CB_pre_recession	CB_post_recession		///
		using "${PSID_outRaw}/CB_pre_post.csv", ///
		cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Parameter Stability between Pre- and Post- Recession) replace
		
		*	Display output
		esttab	CB_interact	CB_pre_recession	CB_post_recession		///
		using "${PSID_outRaw}/CB_pre_post.tex", ///
		cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Parameter Stability between Pre- and Post- Recession) replace
		
	}

	
	
	if	`by_year'==1	{
	
		local	depvar		rho1_foodexp_pc_thrifty_ols
		*local	lagdepvar	l.`depvar'
		local	demovars	c.age_head_fam##c.age_head_fam	HH_female	ib1.race_head_cat	marital_status_cat
		local	econvars	ln_income_pc	/*wealth_pc	wealth_pc_sq*/
		local	familyvars	num_FU_fam ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
		local	eduvars		/*attend_college_head*/ ib2.grade_comp_cat	
		local	empvars		emp_HH_simple
		local	healthvars	phys_disab_head
		local	foodvars	food_stamp_used_1yr	/*child_meal_assist	elderly_meal*/ WIC_received_last	
		local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
		local	regionvars	ib0.state_resid_fam	
		local	interactvars	c.ln_income_pc#c.HH_female	///
								c.ln_income_pc#c.non_working_age	///
								c.HH_female#c.non_working_age	///
								c.ln_income_pc#c.HH_female#c.non_working_age	///
								c.no_longer_married#c.HH_female
		local	timevars	i.year
		
		svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
		margins, dydx(HH_female)
				
		*	By year
			forvalues	year=2/10	{
				
				local	depvar		rho1_foodexp_pc_thrifty_ols
				svy, subpop(year_enum`year'): reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	// if	year==`year'
				*svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year', family(gamma)	link(log)
				estadd scalar N = e(N_sub), replace
				est store CB_cont_year`year'
				
			}
			
			*	Display output
			esttab	CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10	///
			using "${PSID_outRaw}/CB_cont_years.csv", ///
			cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
			
			esttab	CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10	///
			using "${PSID_outRaw}/CB_cont_years.tex", ///
			cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
			
			
			coefplot CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10, vertical keep(c.age_head_fam#c.age_head_fam) drop(_cons)	///
			legend(lab (2 "2001") lab(4 "2003") lab(6 "2005"))
		
	}

	*	Association
	if	`model_check'==1	{
*	Check the association among the factors in the two indicators (USDA, RS)
	
	/*
	*	Take log of income & expenditure variables
	foreach	moneyvars	in	food_exp_pc	income_pc	{
		gen	ln_`moneyvars'	=	log(`moneyvars')
	}
	gen		ln_income_pc_sq	=	(ln_income_pc)^2
	label	var	ln_food_exp_pc	"ln(food expenditure per capita)"
	label	var	ln_income_pc	"ln(income per capita)"
	label	var	ln_income_pc_sq	"ln(income per capita) squared"
	*/
	
	local	depvar		fs_scale_fam_rescale
	local	healthvars	phys_disab_head
	local	demovars	age_head_fam	age_head_fam_sq	ib1.race_head_cat	marital_status_cat	ib1.gender_head_fam	
	local	econvars	c.income_pc	c.income_pc_sq	/*wealth_pc	wealth_pc_sq*/
	local	empvars		emp_HH_simple
	local	familyvars	c.num_FU_fam c.num_child_fam	/*ib0.family_comp_change	ib5.couple_status*/
	local	eduvars		/*attend_college_head*/ ib1.grade_comp_cat	
	local	foodvars	food_stamp_used_1yr	WIC_received_last
	local	regionvars	ib0.state_resid_fam	
	*local	changevars	no_longer_employed	no_longer_married	no_longer_own_house
	
	summ	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars' if in_sample==1 & year==10
	
	cap	drop	pre_recession post_recession
	gen		pre_recession	=	0
	replace	pre_recession	=	1	if	inrange(year,1,5)	//	Wave 1999 to 2007
	gen		post_recession	=	0
	replace	post_recession	=	1	if	inrange(year,6,10)	//	Wave 2009 to 2017
			
	*** Note: Stata recommends using "subpop" option instead of "if" option, as the variance estimator from the latter "does  not  accurately  measurethe  sample-to-sample  variability  of  the  subpopulation  estimates  for  the  survey  design  that  was  used to collect the data."
	*** However, for some reason Stata does often not allow to use "subpop" option with "glm" command, so I will use "if" option for now.
	
	
	*	USDA (rescaled, continuous)
			
		*	Pooled
		local	depvar		fs_scale_fam_rescale
			
			*	OLS
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est	store	USDA_cont_pooled_OLS
			
			*	GLS
			svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars',	///
						family(gamma)	link(log)
			est	store	USDA_cont_pooled_GLS
		
					
		*	By Pre- and Post- Great Recession
		svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
								i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
		est	store	USDA_cont_prepost
		contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
		
		
		*	By Year
		foreach	year	in	1	2	3	9	10	{
			
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
			*svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year', family(gamma)	link(log)	
			est	store	USDA_cont_year`year'
			
		}

	*	CB score (thrift, continuous)
	
		*	Pooled
		local	depvar		rho1_foodexp_pc_thrifty_ols
		
			*	OLS
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est store CB_cont_pooled_OLS
			
			*	GLS
			svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars', family(gamma)	link(log)
			est store CB_cont_pooled_GLS
		
		*	By Pre- and Post- Great Recession
		svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
								i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
		est	store	CB_cont_prepost
		contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
		mat	CB_cont_prepost_pval=r(p)'
		
		*	By year
		forvalues	year=2/10	{
			
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
			*svy: glm	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year', family(gamma)	link(log)
			est store CB_cont_year`year'
			
		}
	

	*	USDA (simplified category, binary)
	local	depvar		fs_cat_fam_simp
		
		* LPM (GLM using binominal family distribution & logit link function gives identical results to logit regression. Could check theoretically later why.)
			
			*	Pooled
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est	store	USDA_bin_LPM_pooled
			
			*	By Pre- and Post- Great Recession
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
									i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
			est	store	USDA_bin_LPM_prepost
			contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
			mat	USDA_bin_prepost_pval=r(p)'
			
			*	By year
			foreach	year	in	1	2	3	9	10	{
			
				svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
				est	store	USDA_bin_LPM_year`year'
			
			}
		
		*	Logit
			
			*	Pooled
			svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est store 	USDA_bin_logit_pooled	
			
			*	By Pre- and Post- Great Recession
			svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
									i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
			est	store	USDA_bin_logit_prepost
			*contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
			*mat	USDA_bin_prepost_pval=r(p)'
			
			*	By year
			foreach	year	in	1	2	3	9	10	{
				
				svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
				est store 	USDA_bin_logit_year`year'
				
			}
		
	
	*	CB (binary category)
	local	depvar		rho1_thrifty_HS_ols
	
		* LPM
			
			*	Pooled
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est	store	CB_bin_LPM_pooled
		
			*	By Pre- and Post- Great Recession
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
									i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
			est	store	CB_bin_LPM_prepost
			*contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
			*mat	CB_bin_LPM_prepost_pval=r(p)'
			
			*	By year
			foreach	year	in	2	3	4	5	6	7	8	9	10	{
			
				svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
				est	store	CB_bin_LPM_year`year'
			
			}
			
		* Logit
			
			*	Pooled
			svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'
			est	store	CB_bin_logit_pooled
			
			*	By Pre- and Post- Great Recession
			svy: reg	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	///
									i.post_recession##(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars')
			est	store	CB_bin_logit_prepost
			*contrast	post_recession	post_recession#(`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'), overall
			*mat	CB_bin_logit_prepost_pval=r(p)'
		
			*	By year
			foreach	year	in	2	3	4	5	6	7	8	9	10	{
			
				svy: logit	`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`regionvars'	if	year==`year'
				est	store	CB_bin_logit_year`year'
			
			}
		
		
	*	Output 
	
		*	Pooled
		esttab	USDA_cont_pooled_OLS	CB_cont_pooled_OLS	USDA_cont_pooled_GLS	CB_cont_pooled_GLS	///
				USDA_bin_LPM_pooled CB_bin_LPM_pooled	USDA_bin_logit_pooled	CB_bin_logit_pooled	using "${PSID_outRaw}/USDA_CB_pooled.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Food Security Status-Pooled) replace
				
		*	By Year
		
			*	USDA (continuous)
				
				*	Default
				esttab	USDA_cont_year1	USDA_cont_year2	USDA_cont_year3	USDA_cont_year9	USDA_cont_year10		using "${PSID_outRaw}/USDA_cont_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA Scale Score-continuous) replace
				
				*	Pre- and Post- Great Recession
				esttab	USDA_cont_prepost		using "${PSID_outRaw}/USDA_cont_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA Scale Score-continuous) replace
				
				*	No star for significance
				esttab	USDA_cont_year1	USDA_cont_year2	USDA_cont_year3	USDA_cont_year9	USDA_cont_year10		using "${PSID_outRaw}/USDA_cont_years_nostar.csv", ///
				cells(b(fmt(a3))) /*stats(N r2)*/ label legend nobaselevels drop(_cons)	title(USDA Scale Score-continuous) replace
				
			
			*	CB (continuous)
				
				*	Default
				esttab	CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10	///
				using "${PSID_outRaw}/CB_cont_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
				
				*	Pre- and Post- Recession
				esttab	CB_cont_prepost		using "${PSID_outRaw}/CB_cont_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
				
				*	No-star
				esttab	CB_cont_year2	CB_cont_year3	CB_cont_year4	CB_cont_year5	CB_cont_year6	CB_cont_year7	CB_cont_year8	CB_cont_year9	CB_cont_year10	///
				using "${PSID_outRaw}/CB_cont_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(CB Measure-continuous) replace
				
			*	USDA (binary-LPM)
				
				*	Default
				esttab	USDA_bin_LPM_year1	USDA_bin_LPM_year2	USDA_bin_LPM_year3	USDA_bin_LPM_year9	USDA_bin_LPM_year10		using "${PSID_outRaw}/USDA_bin_LPM_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	Pre- and Post-
				esttab	USDA_bin_LPM_prepost		using "${PSID_outRaw}/USDA_bin_LPM_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	No-star
				esttab	USDA_bin_LPM_year1	USDA_bin_LPM_year2	USDA_bin_LPM_year3	USDA_bin_LPM_year9	USDA_bin_LPM_year10		using "${PSID_outRaw}/USDA_bin_LPM_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				
			*	USDA (binary-logit)
				
				*	Default
				esttab	USDA_bin_logit_year1	USDA_bin_logit_year2	USDA_bin_logit_year3	USDA_bin_logit_year9	USDA_bin_logit_year10	///
				using "${PSID_outRaw}/USDA_bin_logit_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-Logit) replace
				
				*	Pre- and Post-
				esttab	USDA_bin_logit_prepost		using "${PSID_outRaw}/USDA_bin_logit_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	No-star
				esttab	USDA_bin_logit_year1	USDA_bin_logit_year2	USDA_bin_logit_year3	USDA_bin_logit_year9	USDA_bin_logit_year10	///
				using "${PSID_outRaw}/USDA_bin_logit_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
			
			*	CB (binary-LPM)
				
				*	Default
				esttab	CB_bin_LPM_year2	CB_bin_LPM_year3	CB_bin_LPM_year4	CB_bin_LPM_year5	CB_bin_LPM_year6	///
						CB_bin_LPM_year7	CB_bin_LPM_year8	CB_bin_LPM_year9	CB_bin_LPM_year10	///
				using "${PSID_outRaw}/CB_bin_LPM_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB FS Status-LPM) replace
				
				*	Pre- and Post-
				esttab	CB_bin_LPM_prepost		using "${PSID_outRaw}/CB_bin_LPM_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	No star
				esttab	CB_bin_LPM_year2	CB_bin_LPM_year3	CB_bin_LPM_year4	CB_bin_LPM_year5	CB_bin_LPM_year6	///
						CB_bin_LPM_year7	CB_bin_LPM_year8	CB_bin_LPM_year9	CB_bin_LPM_year10	///
				using "${PSID_outRaw}/CB_bin_LPM_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(CB FS Status-LPM) replace
				
			*	CB (binary-logit)
				
				*	Default
				esttab	CB_bin_logit_year2	CB_bin_logit_year3	CB_bin_logit_year4	CB_bin_logit_year5	CB_bin_logit_year6	///
						CB_bin_logit_year7	CB_bin_logit_year8	CB_bin_logit_year9	CB_bin_logit_year10	///
				using "${PSID_outRaw}/CB_bin_logit_years.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(CB FS Status-Logit) replace
				
				*	Pre- and Post-
				esttab	CB_bin_logit_prepost		using "${PSID_outRaw}/CB_bin_logit_prepost.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(USDA FS Status-LPM) replace
				
				*	No star
				esttab	CB_bin_logit_year2	CB_bin_logit_year3	CB_bin_logit_year4	CB_bin_logit_year5	CB_bin_logit_year6	///
						CB_bin_logit_year7	CB_bin_logit_year8	CB_bin_logit_year9	CB_bin_logit_year10	///
				using "${PSID_outRaw}/CB_bin_logit_years_nostar.csv", ///
				cells(b(fmt(a3))) stats(N r2) label legend nobaselevels drop(_cons)	title(CB FS Status-Logit) replace
				
			
}

	*	Specification check
	if	`specification_check'==1	{
	
		*	Preparation
		if	`prep_spec'==1	{
		
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
			
											
			
			tsset	fam_ID_1999 year, delta(1)
			
			local	depvar		rho1_foodexp_pc_thrifty_ols
			*local	lagdepvar	l.`depvar'
			local	demovars	c.age_head_fam##c.age_head_fam	HH_female	ib1.race_head_cat	marital_status_cat
			local	econvars	c.ln_income_pc	/*wealth_pc	wealth_pc_sq*/
			local	familyvars	c.num_FU_fam c.ratio_child	/*ib0.family_comp_change	ib5.couple_status*/
			local	eduvars		/*attend_college_head*/ ib2.grade_comp_cat	
			local	empvars		emp_HH_simple
			local	healthvars	phys_disab_head
			local	foodvars	food_stamp_used_1yr	/*child_meal_assist WIC_received_last*/	elderly_meal
			local	shockvars	no_longer_employed	no_longer_married	no_longer_own_house	became_disabled
			local	regionvars	ib0.state_resid_fam	
			local	interactvars	c.ln_income_pc#c.HH_female	///
									c.ln_income_pc#c.non_working_age	///
									c.HH_female#c.non_working_age	///
									c.ln_income_pc#c.HH_female#c.non_working_age	///
									c.no_longer_married#c.HH_female
			local	timevars	i.year
	
	}	

		*	Specification analysis		
		if	`spec_analysis'==1	{
			
			*	OLS
			
				*	Without interaction	&	shocks
				svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	/*`shockvars'		`interactvars'*/	`regionvars'	`timevars'
				*svy: meglm `depvar'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`healthvars'	`foodvars'	`regionvars'
				est	store	Prob_FI_benchmark
					
				*	With interaction	&	shocks
				svy: reg	`depvar'	`demovars'	`econvars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
				*svy: meglm `depvar'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`healthvars'	`foodvars'	`regionvars'
				est	store	Prob_FI_interact
				
				*	Auxiliary regression
				svy: reg	`econvars'	`demovars'	`familyvars'	`eduvars'	`empvars'	`healthvars'	`foodvars'	`shockvars'		`interactvars'	`regionvars'	`timevars'
				est	store	Income_interact
				
				esttab	Prob_FI_benchmark	Prob_FI_interact	Income_interact	using "${PSID_outRaw}/Prob_FI_pooled.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Prob(food insecure)-Pooled) replace

				*	Joint Hypothesis test of variables
				est	restore		Prob_FI_interact
				
					*	age and its interaction terms (whether age matters)
					test	age_head_fam c.age_head_fam#c.age_head_fam
					
					*	gender and its interaction terms (whether gender matters)
					test	HH_female	c.ln_income_pc#c.HH_female	c.HH_female#c.non_working_age	c.ln_income_pc#c.HH_female#c.non_working_age
					
					*	income and its interaction terms (wheter income matters)
					test	c.ln_income_pc	c.ln_income_pc#c.HH_female	c.ln_income_pc#c.non_working_age	c.ln_income_pc#c.HH_female#c.non_working_age
					
					*	# of FU and # of children (jointly) (whether family size matters)
					//test	c.num_FU_fam c.num_child_fam
					
					*	All terms interacting with outside workinge age (whether being non-working age matters)
					test	c.ln_income_pc#c.non_working_age	c.HH_female#c.non_working_age	c.ln_income_pc#c.HH_female#c.non_working_age
					
					*	No longer married and its interaction term (wheter being no longer married matters)
					test	no_longer_married	c.no_longer_married#c.HH_female
		
					*	Whether all the interaction terms are jointly significant (whether all interaction terms matters)
					test	`interactvars'
				
				*	Marginal Effect
					
					
					*	Income
						
						*	By income group
						est	restore	Prob_FI_interact
						margins,	dydx(c.ln_income_pc)	over(income_to_poverty_cat)
						marginsplot, title(Semi-elasticity of FSPS w.r.t. income with 95% CI) xtitle(Income-to-Poverty Ratio)	///
										note(1% change in income increases FSPS by y-var percentage point)
						graph	export	"${PSID_outRaw}/ME_income_bygroup.png", replace
						graph	close
						
						*	By income group, around poverty threshold
						cap	drop	income_to_poverty_lowtail
						gen	income_to_poverty_lowtail=.	if	!inrange(income_to_poverty,0,3)
						forval	i=0.2(0.2)3.0	{
							
							local	minval	=	`i'-0.2
							local	maxval	=	`i'
							replace	income_to_poverty_lowtail	=	`maxval'*100	if	inrange(income_to_poverty,`minval',`maxval')
						}
						est	restore	Prob_FI_interact
						margins,	dydx(c.ln_income_pc)	over(income_to_poverty_lowtail)
						marginsplot, title(Marginal Effect of Income on FSPS) xtitle(Income to Poverty Ratio(%))	ytitle(FSPS(percentage point))	///
										note("Income to Poverty Ratio is calculated by dividing total annual income into Federal Poverty Line" "Change in FSPS with respect to 1% increase in per capita income")
						graph	export	"${PSID_outRaw}/ME_income_lowtail.png", replace
						graph	close
						
						*	By year
						forvalues	year=2001(2)2017	{						
							est	restore	Prob_FI_interact
							margins,	dydx(c.ln_income_pc)	subpop(if year2==`year')	over(income_to_poverty_lowtail) post
							est store SE_`year'
							marginsplot,	title(Semi-elasticity of FSPS over income in `year')
							graph	export	"${PSID_outRaw}/ME_income_lowtail_`year'.png", replace
							graph	close	
							
						}
						coefplot (SE_2001, msymbol(circle)) (SE_2007, msymbol(diamond))	(SE_2011, msymbol(square))	(SE_2017, msymbol(triangle)), noci	lwidth(*1) connect(l) vertical	///
						xlabel(1 "20" 2 "40"	3	"60"	4	"80"	5	"100"	6	"120"	7	"140"	8	"160"	9	"180"	10	"200"	11	"220"	12	"240"	13	"260"	14	"280")	///
						note("Income to Poverty Ratio is calculated by dividing total annual income into Federal Poverty Line" "Change in FSPS with respect to 1% increase in per capita income")	///
						legend(lab (1 "2001") lab(2 "2007") lab (3 "2011") lab(4 "2017")	rows(1))	///
						xtitle (Income to Poverty Ratio(%))	ytitle(FSPS(percentage point))	title (Marginal Effect of Income on FSPS)	
						graph	export	"${PSID_outRaw}/ME_income_lowtail_byyear.png", replace
						graph	close
						
					*	Elasticity over (thrifty) food plan
					
						*	No control, by year
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	/*c.age_head_fam##c.age_head_fam		ln_income_pc */
						margins, eyex(foodexp_W_thrifty) over(year2) post
						est	store	eyex_foodplan_nocon_year
						marginsplot, title(Elasticity of FSPS over thrifty food plan by year)
						
						*	Control (age, income), by year
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	c.age_head_fam##c.age_head_fam		ln_income_pc
						margins, eyex(foodexp_W_thrifty) over(year2) post
						est	store	eyex_foodplan_con_year
						marginsplot, title(Elasticity of FSPS over thrifty food plan by year)
						
						*	Graph
						coefplot eyex_foodplan_nocon_year	eyex_foodplan_con_year, lwidth(*1) connect(l) vertical	xlabel(1(1)9)	///
							xtitle (Survey Wave)	ytitle(FSPS)	title (Elasticity of FSPS over Food Plan by year)	///
							legend(lab (2 "No controls") lab(4 "Controls") rows(1))	///
							note(Controls include age and income)
						graph	export	"${PSID_outRaw}/Elasticity_over_foodplan_year.png", replace
						graph	close
						
						*	No control, by income group
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	/*c.age_head_fam##c.age_head_fam		ln_income_pc */
						margins, eyex(foodexp_W_thrifty) over(income_to_poverty_cat) post
						est	store	eyex_foodplan_nocon_IPR
						marginsplot, title(Elasticity of FSPS over thrifty food plan by IPR)
						
						*	Control (age, income), by income group
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	c.age_head_fam##c.age_head_fam		ln_income_pc
						margins, eyex(foodexp_W_thrifty) over(income_to_poverty_cat) post
						est	store	eyex_foodplan_con_IPR
						marginsplot, title(Elasticity of FSPS over thrifty food plan by IPR)
						
						*	Graph
						coefplot eyex_foodplan_nocon_IPR	eyex_foodplan_con_IPR, lwidth(*1) connect(l) vertical	xlabel(1(1)11)	///
							xtitle (Income to Poverty Ratio)	ytitle(FSPS)	title (Elasticity of FSPS over Food Plan by IPR)	///
							legend(lab (2 "No controls") lab(4 "Controls") rows(1))	///
							note(Controls include age and income)
						graph	export	"${PSID_outRaw}/Elasticity_over_foodplan_IPR.png", replace
						graph	close
						
						*	No control, low income group
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	/*c.age_head_fam##c.age_head_fam		ln_income_pc */
						margins, eyex(foodexp_W_thrifty) over(income_to_poverty_lowtail) post
						est	store	eyex_foodplan_nocon_IPRlow
						marginsplot, title(Elasticity of FSPS over thrifty food plan by IPR)
						
						*	Control (age, income), low income group
						est	restore	Prob_FI_interact
						svy: reg rho1_foodexp_pc_thrifty_ols	foodexp_W_thrifty	c.age_head_fam##c.age_head_fam		ln_income_pc
						margins, eyex(foodexp_W_thrifty) over(income_to_poverty_lowtail) post
						est	store	eyex_foodplan_con_IPRlow
						marginsplot, title(Elasticity of FSPS over thrifty food plan by IPR)
						
						*	Graph
						coefplot eyex_foodplan_nocon_IPRlow	eyex_foodplan_con_IPRlow, lwidth(*1) connect(l) vertical	xlabel(0(5)30)	///
							xtitle (Income to Poverty Ratio*10)	ytitle(FSPS)	title (Elasticity of FSPS over Food Plan by IPR)	///
							legend(lab (1 "No controls") lab(2 "Controls") rows(1))	noci	xline(10)	///
							note(Controls include age and income)
						graph	export	"${PSID_outRaw}/Elasticity_over_foodplan_IPRlow.png", replace
						graph	close
					
					/*
					*	Overall (AME)
					est	restore	Prob_FI_interact
					local	nonlinear_terms	c.age_head_fam	HH_female	c.ln_income_pc	c.non_working_age	c.no_longer_married
					eststo	ME_overall: margins,	dydx(`nonlinear_terms'	)	post	//	age, gender and ln(income). Income will be semi-elasticity
					est	restore	Prob_FI_interact
					eststo	ME_overall_atmeans: margins,	dydx(`nonlinear_terms')	atmeans post	//	age, gender and ln(income). Income will be semi-elasticity
					esttab	ME_overall	ME_overall_atmeans	using "${PSID_outRaw}/ME_overall.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels /*drop(_cons)*/	title(Marginal Effect_overall) replace
						
					est	restore	Prob_FI_interact	
					eststo	ME_AME2:	margins,	expression((1/exp(ln_income_pc))*(_b[ln_income_pc]+_b[c.ln_income_pc#c.HH_female]*HH_female+_b[c.ln_income_pc#c.non_working_age]*non_working_age)+_b[c.ln_income_pc#c.HH_female#c.non_working_age]*HH_female*non_working_age)	post	//	1st-derivative w.r.t. per capita income
					
					*/
					
					*	Prediction
					est	restore	Prob_FI_interact
					predict fv,xb
					
						*	Over the age, using the deviation from the life expectancy
						cap	drop	dev_from_lifeexp
						gen		dev_from_lifeexp=.
						forvalues	year=1999(2)2017	{
							replace	dev_from_lifeexp	=	age_head_fam-life_exp_male_`year'	if	HH_female==0	&	year2==`year'
							replace	dev_from_lifeexp	=	age_head_fam-life_exp_female_`year'	if	HH_female==1	&	year2==`year'
						}
						label	variable	dev_from_lifeexp	"Deviation from the life expectancy by year and gender"
						
						twoway	(lpolyci fv dev_from_lifeexp	if	HH_female==0)	///
								(lpolyci fv dev_from_lifeexp	if	HH_female==1),	///
								title(Predicted FSPS over the age)	note(Life Expectancy are 73.9(male) and 79.4(female) in 1999 and 76.1(male) and 81.1(female) in 2017) ///
								legend(lab (2 "Male") lab(3 "Female") rows(1))	xtitle(Deviation from the Life Expectancy)
						graph	export	"${PSID_outRaw}/Fitted_age_pooled.png", replace
						graph	close
					
						*	By each year in a single graph
						twoway	(lpoly fv dev_from_lifeexp if year2==1999)	(lpoly fv dev_from_lifeexp if year2==2005)	///
								(lpoly fv dev_from_lifeexp if year2==2011)	(lpoly fv dev_from_lifeexp if year2==2017),	///
								legend(lab (1 "1999") lab(2 "2005") lab(3 "2011") lab(4 "2017") rows(1))	///
								xtitle(Deviation from the Life Expectancy)	ytitle(Predicted FSPS)	title(Predicted FSPS over Life)
						graph	export	"${PSID_outRaw}/Fitted_age_byyear.png", replace
						graph	close
						
								
						*	W.R.T. average retirement age
							
							*	Average retirement age by year
							forval	year=1999(2)2017	{
								summarize	retire_age	if	retire_year_head==`year'
								*svy, subpop(year_enum`year'): mean retire_age // if	retire_year_head==`year'
							}

							
							*	1999							
							summ	retire_age	if	retire_year_head==1999	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==1),	xline(`r(mean)')	xtitle(Age)	legend(lab (2 "FSPS"))	title(1999)	name(fv_age_retire_1999, replace)
							
							*	2007
							summ	retire_age	if	retire_year_head==2005	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==4),	xline(`r(mean)')	xtitle(Age) legend(lab (2 "FSPS"))	title(2005)	name(fv_age_retire_2005, replace)
							
							*	2013
							summ	retire_age	if	retire_year_head==2011	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==7),	xline(`r(mean)')	xtitle(Age) legend(lab (2 "FSPS"))	title(2011)	name(fv_age_retire_2011, replace)
							
							*	2017
							summ	retire_age	if	retire_year_head==2017	&	e(sample)
							graph	twoway	(lpolyci fv age_head_fam	if	year==10),	xline(`r(mean)')	xtitle(Age) legend(lab (2 "FSPS"))	title(2017)	name(fv_age_retire_2017, replace)
							
							grc1leg2		fv_age_retire_1999	fv_age_retire_2005	fv_age_retire_2011	fv_age_retire_2017,	title(Predicted FSPS over age) legendfrom(fv_age_retire_1999)	///
											note(Vertical line is the average retirement age of the year in the sample)	xtob1title
							graph	export	"${PSID_outRaw}/Fitted_age_retirement.png", replace
							graph	close
							
							
	

				
					
					twoway qfitci fv income_pc, title(Expected FSPS over income)
					twoway qfitci fv age_head_fam, title(Expected FSPS over age)
													
					twoway lpolyci fv income_pc if income_pc>0, title(Expected FSPS over income)
					twoway lpolyci fv age_head_fam	if	HH_female==1, title(Expected FSPS over age)
					twoway lpolyci fv age_head_fam	if	HH_female==0, title(Expected FSPS over age)
					
					graph	twoway	(scatter rho1_foodexp_pc_thrifty_ols income_pc if income_pc>0)		///
									(lpolyci fv income_pc if income_pc>0, title(Expected FSPS over income))
					
					
						*	By year
						cap	drop	year2
						gen year2 = (year*2)+1997
						
						forval	year=1999(2)2017	{
							qui	twoway lpolyci fv income_pc if income_pc>0	&	year2==`year', title(Expected FSPS over income in `year')
							graph	export	"${PSID_outRaw}/Fitted_lpoly_income_`year'.png", replace
							graph	close	
							
							qui	twoway lpolyci fv age_head_fam if year2==`year', title(Expected FSPS over age in `year')
							graph	export	"${PSID_outRaw}/Fitted_lpoly_age_`year'.png", replace
							graph	close
						}
						
						*	In a single graph
						twoway	(lpoly fv income_pc if income_pc>0	&	year2==1999	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2001	&	income_pc<100)	///
								(lpoly fv income_pc if income_pc>0	&	year2==2003	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2005	&	income_pc<100)	///
								(lpoly fv income_pc if income_pc>0	&	year2==2007	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2009	&	income_pc<100)	///
								(lpoly fv income_pc if income_pc>0	&	year2==2011	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2013	&	income_pc<100)	///
								(lpoly fv income_pc if income_pc>0	&	year2==2015	&	income_pc<100)	(lpoly fv income_pc if income_pc>0	&	year2==2017	&	income_pc<100),	///
								legend(lab (1 "1999") lab(2 "2001") lab(3 "2003") lab(4 "2005") lab(5 "2007") lab(6 "2009") lab(7 "2011") lab(8 "2013") lab(9 "2015") lab(10 "2017") rows(2))	///
								title(Predicted FSPS over income)	xtitle(Per capita income (thousands))
						graph	export	"${PSID_outRaw}/Fitted_lpoly_income_all_year.png", replace
						graph	close
						
						twoway	(lpoly fv age_head_fam if year2==1999)	(lpoly fv age_head_fam if year2==2001)	///
								(lpoly fv age_head_fam if year2==2003)	(lpoly fv age_head_fam if year2==2005)	///
								(lpoly fv age_head_fam if year2==2007)	(lpoly fv age_head_fam if year2==2009)	///
								(lpoly fv age_head_fam if year2==2011)	(lpoly fv age_head_fam if year2==2013)	///
								(lpoly fv age_head_fam if year2==2015)	(lpoly fv age_head_fam if year2==2017),	///
								legend(lab (1 "1999") lab(2 "2001") lab(3 "2003") lab(4 "2005") lab(5 "2007") lab(6 "2009") lab(7 "2011") lab(8 "2013") lab(9 "2015") lab(10 "2017") rows(2))	///
								title(Expected FSPS over age by year)
						graph	export	"${PSID_outRaw}/Fitted_lpoly_age_all_year.png", replace
						graph	close
		
					*	Compute the marginal effect of some covariates over the range of values.
					*margins, dydx(age_head_fam) over(age_head_fam)
					*marginsplot, title(Marginal Effect of Age with 95% CI)
					
					cap	drop	income_pc_cat
					gen	income_pc_cat=0	if	income_pc<0
					forvalues	i=0(10)150	{
						local	income_min=`i'
						local	income_max=(`i'+10)
						replace	income_pc_cat	=	`i'	if	inrange(income_pc,`income_min',`income_max')
					}
					
					*margins, dydx(income_pc) over(income_pc_cat)
					*marginsplot, title(Marginal Effect of per capita income with 95% CI) xtitle(per capita income group)
				
				
				
		}
		
		*	Test stationary		
		if	`stationary_check'==1	{
			
			*	Convert interaction variables into normal variable, for xtserial test
			cap	drop	race_black
			cap	drop	race_other
			cap	drop	highest_grade?
			cap	drop	income_gender
			cap	drop	income_nonwork
			cap	drop	gender_nonwork
			cap	drop	income_gender_nonwork
			cap	drop	nomarried_gender
			gen	race_black		=	0	if	!mi(race_head_cat)
			replace	race_black	=	1	if	race_head_cat==2
			gen	race_other		=	0	if	!mi(race_head_cat)
			replace	race_other	=	1	if	race_head_cat==3
			tab grade_comp_cat,	gen(highest_grade)
			gen	income_gender	=	c.ln_income_pc#c.HH_female
			gen	income_nonwork	=	c.ln_income_pc#c.non_working_age
			gen	gender_nonwork	=	c.HH_female#c.non_working_age
			gen	income_gender_nonwork	=	c.ln_income_pc#c.HH_female#c.non_working_age
			gen	nomarried_gender	=	c.no_longer_married#c.HH_female
			
		
			*	Chris' suggestion
					
					*	Testing whether dependent variable is stationary (warning: takes some time)
						*	xtunitroot fisher	rho1_foodexp_pc_thrifty_ols,	dfuller	lags(1)	trend
						
					*	Testing whether there exist serial correlation
					xtserial	rho1_foodexp_pc_thrifty_ols	///	//	depvar
								age_head_fam age_head_fam_sq	race_black	race_other	marital_status_cat ///	//	Demographic vars
								ln_income_pc	///	//	income var
								emp_HH_simple	///	//	emp var
								num_FU_fam	num_child_fam	///	//	family var
								highest_grade1 highest_grade3 highest_grade4	///	//	edu vars
								state_resid_fam_enum2-state_resid_fam_enum52	///	region vars
								no_longer_employed	no_longer_married	no_longer_own_house	became_disabled	///	//	shockvars
								income_gender	income_nonwork	gender_nonwork	income_gender_nonwork	nomarried_gender, output	//	interact vars		
				
					reg	rho1_foodexp_pc_thrifty_ols	l(1/1).rho1_foodexp_pc_thrifty_ols
					
					*	Use pooled data with time FE to estimate conditional mean, and check whether there are serial correlation among residuals
					cap	drop	resid_trend
					svy: reg	`depvar'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`healthvars'	`foodvars'	`shockvars'	`interactvars'	`regionvars'	year	//	include time trend, either as linear or as FE
					predict	resid_withtrend, residual
					
					
					xtreg	resid_withtrend	l.resid_withtrend, vce(cluster fam_ID_1999) fe	//	If the estimate is statistically significant, then there is autocorrelation among residuals.
					
					*	Testing different ARMA(p,q) model
					*	Here we will test p and q from 1  to 3.
					
					forvalues	p=1/3	{
						forvalues	q=1/3	{
							cap	drop	resid_p`p'_q`q'
							
							svy: reg	`depvar'	l(1/`p').`depvar'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`healthvars'	`foodvars'	`shockvars'	`interactvars'	`regionvars'	l(1/`q').resid_withtrend
							predict	resid_p`p'_q`q', resid
							
							xtreg		resid_p`p'_q`q'	l.resid_p`p'_q`q', fe vce(cluster fam_ID_1999)	
							est	store	ARMA_p`p'_q`q'
						}
					}
					
					esttab	ARMA_p1_q1	ARMA_p1_q2	ARMA_p1_q3	///
							ARMA_p2_q1	ARMA_p2_q2	ARMA_p1_q3	///
							ARMA_p3_q1	ARMA_p3_q2	ARMA_p1_q3	///
							using "${PSID_outRaw}/ARMA_check.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Residual Autocorrelation under ARMA(p,q)) replace
		ggggg
					predict temp, residual
					reg		temp l.temp
					est	store	nolag
					xtreg	temp l.temp, fe
					est	store	nolag_fe
					xtreg	temp l.temp, vce(cluster fam_ID_1999) fe
					est	store	nolag_fe_cl
					
					svy: reg	`depvar'	l.`depvar'
					predict	temp_lag, residual
					reg	temp_lag	l.temp_lag
					est	store	onelag
					xtreg	temp_lag	l.temp_lag, fe
					est	store	onelag_fe
					xtreg	temp_lag	l.temp_lag, vce(cluster fam_ID_1999) fe
					est	store	onelag_fe_cl
					
					svy: reg	`depvar'	l.`depvar'	l2.`depvar'	
					predict	temp_lag2, residual
					reg	temp_lag2	l.temp_lag2
					est	store	twolag
					xtreg	temp_lag2	l.temp_lag2, fe
					est	store	twolag_fe
					xtreg	temp_lag2	l.temp_lag2, vce(cluster fam_ID_1999) fe
					est	store	twolag_fe_cl
					
					svy: reg	`depvar'	l.`depvar'	l2.`depvar'		l3.`depvar'
					predict	temp_lag3, residual
					reg	temp_lag3	l.temp_lag3
					est	store	threelag
					xtreg	temp_lag3	l.temp_lag3, fe
					est	store	threelag_fe
					xtreg	temp_lag3	l.temp_lag3, vce(cluster fam_ID_1999) fe
					est	store	threelag_fe_cl
					
					esttab	nolag	nolag_fe	nolag_fe_cl	///
							onelag	onelag_fe	onelag_fe_cl	///	
							twolag	twolag_fe	twolag_fe_cl	///
							threelag	threelag_fe	threelag_fe_cl	///
							using "${PSID_outRaw}/acr_check.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Residual Autocorrelation) replace
					
			/*		
					cap	drop	resid_nocov_tr
					predict	resid_nocov_tr, residual
					
					xtreg	resid_withtimeFE	l.resid_withtimeFE	l2.resid_withtimeFE, fe
					est	store	resid_autocorr_nocluster
					
					xtreg	resid_withtimeFE	l.resid_withtimeFE	l2.resid_withtimeFE, vce(cluster fam_ID_1999) fe
					est	store	resid_autocorr_cluster
					
				
					
					esttab	resid_autocorr_nocluster	resid_autocorr_cluster	using "${PSID_outRaw}/resid_autocorr.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Residual Autocorrelation) replace
					
			
				*	Suppose there is autocorrelation, then ad lagged dep var on RHS
					svy: reg	`depvar'	cl.`depvar'	cl2.`depvar'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	`foodvars'	`shockvars'	`interactvars'	`regionvars'	i.year
					
					cap	drop	resid_withtimeFE
					predict	resid_withtimeFE, residual
					
					xtreg	resid_withtimeFE	l.resid_withtimeFE, fe
					est	store	resid_atcr_lag_nocluster
					
					xtreg	resid_withtimeFE	l.resid_withtimeFE, vce(cluster fam_ID_1999) fe
					est	store	resid_atcr_lag_cluster
					
					esttab	resid_atcr_lag_nocluster	resid_atcr_lag_cluster	using "${PSID_outRaw}/resid_lagdep_autocorr.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Residual Autocorrelation) replace
			*/
		}
		
}
			
	*	Graphs
	
	
		*	Effect of non-employment
		
			*	fam_ID_1999==33 (No longer employed in 2009) 
			twoway	function y=gammaden(7.842407,0.6806434,0,x), range(0 10)	lpattern(solid)	||	///	//	2007 (pre-loss)
					function y=gammaden(5.639921,0.7594346,0,x), range(0 10)	lpattern(dash)	||	///	//	2009 (job-loss)
					function y=gammaden(7.422701,0.4153742,0,x), range(0 10)	lpattern(dot)	||	///	//	2011 (2 years after job-loss)
					function y=gammaden(7.672119,0.3827603,0,x), range(0 10)	lpattern(dashdot)	||	///	//	2013 (4 years after job-loss)
					function y=gammaden(8.372554,0.487376,0,x), range(0 10)		lpattern(shortdash)		///	//	2015 (6 years after job-loss)
					legend(lab (1 "2007(6.24)") lab(2 "2009(3.64)") lab(3 "2011(2.34)") lab(4 "2013(4.16)") lab(5 "2015(5.2)"))	///
					title(The Effect of Job-Loss on FSPS PDF)	subtitle(Job Loss in 2009)	///
					xtitle(food expenditure per capita (thousands))	///
					note(Female-headed household. Job loss in 2009 but re-employed since 2011.)
			graph	export	"${PSID_outRaw}/effect_of_job_loss_on_CB_pdf.png", replace
			graph	close
			
			
		*	Effect of non-married
			
			*	fam_ID_1999=3496 (no longer married in 2007)
			twoway	function y=gammaden(7.061182,0.530853,0,x), range(0 10)	lpattern(solid)	||	///	//	2007 (pre-chock)
					function y=gammaden(8.30407,0.6948747,0,x), range(0 10)	lpattern(dash)	||	///	//	2009 (marriage-shock)
					function y=gammaden(7.236261,0.4517315,0,x), range(0 10)	lpattern(dot)	||	///	//	2011 (2 years after marriage-shock)
					function y=gammaden(4.702001,0.8223391,0,x), range(0 10)	lpattern(dashdot)	||	///	//	2013 (4 years after marriage-shock)
					function y=gammaden(9.6309,0.6496494,0,x), range(0 10)		lpattern(shortdash)		///	//	2015 (6 years after marriage-shock)
					legend(lab (1 "2005(3.21)") lab(2 "2007(4.68)") lab(3 "2009(2.6)") lab(4 "2011(2.6)") lab(5 "2013(5.2)"))	///
					title(The Effect of Marriage Shock on FSPS PDF)	subtitle(Marriage shock in 2007)	///
					xtitle(food expenditure per capita (thousands))	///
					note(Male-headed household. No longer married in 2007 and remained since then.)
			graph	export	"${PSID_outRaw}/effect_of_marriage_shock_on_CB_pdf.png", replace
			graph	close

		
		*	Time trend of CB score by year & sample group.
		
			cap	drop	year2
			gen year2 = (year*2)+1997
			
			tsset	fam_ID_1999 year2, delta(2)
			
			*	Ratio of food insecure household (FSPS)
			cap	drop	avg_cb_weighted
			cap	drop	avg_cb_weighted_sample
			cap	drop	HH_FS_ratio_PSID
			gen	double avg_cb_weighted=.
			gen	double avg_cb_weighted_sample=.
			gen	double HH_FS_ratio_PSID=.
			forval	year=1999(2)2017	{
				
				* FSPS
				if	`year'!=1999	{	
					
					* By year
					qui	svy: mean rho1_foodexp_pc_thrifty_ols if year2==`year'	
					replace	avg_cb_weighted=e(b)[1,1]	if	year2==`year'
					
					* FSPS, by year & sample
					forval	sampleno=1/3	{
						quietly	svy: mean rho1_foodexp_pc_thrifty_ols 		if year2==`year'	&	sample_source==`sampleno'
						replace	avg_cb_weighted_sample=e(b)[1,1]	if	year2==`year'	&	sample_source==`sampleno'
					}
				}
				
				* PSID, by year
				if	inlist(`year',1999,2001,2003,2015,2017)	{
					qui	svy:	mean	fs_cat_fam_simp	if year2==`year'	
					replace	HH_FS_ratio_PSID=e(b)[1,1]	if	year2==`year'
				}
			}
			
			*	Ratio of food insecure households (USDA report)
			cap	drop	HH_FS_ratio_USDA
			gen		HH_FS_ratio_USDA	=	(1-0.101)	if	year2==	1999
			replace	HH_FS_ratio_USDA	=	(1-0.107)	if	year2==	2001
			replace	HH_FS_ratio_USDA	=	(1-0.112)	if	year2==	2003
			replace	HH_FS_ratio_USDA	=	(1-0.110)	if	year2==	2005
			replace	HH_FS_ratio_USDA	=	(1-0.111)	if	year2==	2007
			replace	HH_FS_ratio_USDA	=	(1-0.147)	if	year2==	2009
			replace	HH_FS_ratio_USDA	=	(1-0.149)	if	year2==	2011
			replace	HH_FS_ratio_USDA	=	(1-0.143)	if	year2==	2013
			replace	HH_FS_ratio_USDA	=	(1-0.127)	if	year2==	2015
			replace	HH_FS_ratio_USDA	=	(1-0.118)	if	year2==	2017
			lab	var	HH_FS_ratio_USDA	"Ratio of FS households"
			
			
			tsset	fam_ID_1999 year2, delta(2)
			
			sort	fam_ID_1999 year2
			twoway	(connected	HH_FS_ratio_USDA	year2	in	1/10,	yaxis(1) lpattern(solid))	///
					(connected	HH_FS_ratio_PSID	year2	in	1/10,	yaxis(1) lpattern(dot))	///
					(connected	avg_cb_weighted	year2	in	1/10,	yaxis(1) lpattern(dash)),	///
					legend(lab (1 "USDA") lab(2 "PSID") lab(3 "FSPS") rows(1))	///
					title(Ratio of being food secure)	subtitle(from 1999 to 2017)
			graph	export	"${PSID_outRaw}/Food_Secure_by_data.png", replace
			graph	close


			tsset	fam_ID_1999	year
			keep	if	fam_ID_1999==1
			drop	if	mi(rho1_foodexp_pc_thrifty_ols)
			
			dfuller	rho1_foodexp_pc_thrifty_ols
			dfgls	rho1_foodexp_pc_thrifty_ols, maxlag(4)
			
	*	Summary Statistics (Table 3)
	
		eststo drop	Total SRC	SEO	Imm

		local	sumvars	age_head_fam HH_female	HH_race_white HH_race_black HH_race_other	marital_status_cat	num_FU_fam num_child_fam	///
						emp_HH_simple	income_pc	food_exp_pc	 college_completed phys_disab_head	food_stamp_used_1yr 	 
		cap	drop	sample_source?
		tab sample_source, gen(sample_source)
		
		svy: mean `sumvars'
		estadd matrix mean = r(table)[1,1...]
		estadd matrix sd = r(table)[2,1...]
		eststo	Total
		svy, subpop(sample_source_SRC): mean `sumvars'
		estadd matrix mean = r(table)[1,1...]
		estadd matrix sd = r(table)[2,1...]
		estadd scalar N = e(N_sub), replace
		eststo	SRC
		svy, subpop(sample_source_SEO): mean `sumvars'
		estadd matrix mean = r(table)[1,1...]
		estadd matrix sd = r(table)[2,1...]
		estadd scalar N = e(N_sub), replace
		eststo	SEO
		svy, subpop(sample_source_IMM): mean `sumvars'
		estadd matrix mean = r(table)[1,1...]
		estadd matrix sd = r(table)[2,1...]
		estadd scalar N = e(N_sub), replace
		eststo	Imm
		
			
		
		esttab *Total SRC SEO Imm using tt3.csv, replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ csv ///
		addnotes(Includes households in LASSO regression. SRC stands for Survey Research Center composed of nationally representative households, SEO stands for Survey Economic Opportunities composed of low income households, and Immigrants are those newly added to the PSID in 1997 and 1999)
		
		esttab *Total SRC SEO Imm using tt3.tex, replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ tex ///
		addnotes(Includes households in LASSO regression. SRC stands for Survey Research Center composed of nationally representative households, SEO stands for Survey Economic Opportunities composed of low income households, and Immigrants are those newly added to the PSID in 1997 and 1999)
		
		

	
/* Junk Code */
/* The following codes are old codes used when outcome variable are non-negative discrete variables (FS score) */		

/*
	*	Declare list of variables
	local	demovars	c.age_head_fam##c.age_head_fam i.race_head_cat gender_head_fam	ib1.marital_status_cat	grade_comp_head_fam
	local	econvars	total_income_fam_wins
	local	famvars		num_FU_fam	num_child_fam
	local	foodvars	food_stamp_used_1yr	child_meal_assist	WIC_received_last*
	
	* Run 
  foreach Y in fs_scale_fam {
   *Mean Specifications 

    *One period lag, with squares and cubes
	
		*	Without controls
		*svy: nbreg `Y' cl.`Y'##cl.`Y'##cl.`Y' 	// nbreg
		svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y' , /*vce(cluster ER31996)*/ family(nbinomial) // glm with nbinomial distribution, allows residual prediction
		est sto base1_`Y'
		margins, dydx(*) atmeans post	//	marginal effect
		est	sto	margin1_base_`Y'
  }	
		*	With controls
		*svy: nbreg `Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars'	//	nbreg
		svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars', /*vce(cluster ER31996)*/ family(nbinomial) 	//	 glm with nbinomial distribution, allows residual prediction
		est sto mean1_`Y'
		predict mean1_`Y'
		predict e1_`Y', r
		margins, dydx(*) atmeans post	//	marginal effect
		est	sto	margin1_`Y'
      
  *Variance Specification - Negative binomial
     
	*One-period lag, with squares and cubes
	 gen e1`Y'_sq = e1_`Y'^2	//	(SL: squared residual?)
     svy: glm e1`Y'_sq cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars', /*vce(cluster ER31996)*/ family(nbinomial) 
	 est sto var1_`Y'
	 predict var1_`Y'
	 margins, dydx(*) atmeans post	//	(SL: why do we use GLM instead of OLS? Why didn't we use it in the first step?)
     est	sto margin2_`Y'  

	
  *Resilience Scores & Regressions (using poverty line for OUTCOME, wbar2_`Y'), based on negative binomial distribution
     *One-period lag, with squares and cubes
	 
		***************Need to double-check method of moments
		*	From the first and the second moments we estimated above, we use method of moments to estimate distribution parameter.
		*	For X ~ NB(r,p), where r is the number of failures and p is the success probability,
		*	mu = pr/(1-p), sigma2 = pr/(1-p)^2
		*	Solve the system and we get p = 1 - (mu/sigma2), r = mu^2/(sig2-mu)
		
		gen	prob_`Y'	=	1-(mean1_`Y'/var1_`Y')
		gen	gamma_`Y'	=	(mean1_`Y')^2/(var1_`Y'-mean1_`Y')
		
		*	Now estimate CDF of NB(n,r,p) where n is the number of success (support, x-axis)
		*	We use n=2.32, the threshold of food security scale score indicating ANY food insecurity
		*	Source: "Measuring Food Security in the United States: Guide to Measuring Household Food Security, Revised 2000 (Bickel et al., 2000)
		scalar	n=2.32
		gen rho1_`Y' = nbinomial(n,gamma_`Y',prob_`Y')	//	Probability of being food secure (FS scale score <=2.32)
	
		*	Now regress RHS variables on this predicted probability
		*reg rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' ndvi_z_var, vce(cluster geo_region)	//	(SL: Do we use LPM, not logit?) (Joan: rho1 is continuous b/w 0 and 1)
	   *est sto R1_`Y'
		svy: reg rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars', /*vce(cluster geo_region)*/
		est sto R12_`Y'
		margins, dydx(*) atmeans post	//	(SL: why do we use GLM instead of OLS? Why didn't we use it in the first step?)
		est	sto margin3_`Y'
		svy: fracreg logit	rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`famvars'	`foodvars', /*vce(cluster geo_region)*/
	    est sto R12_frac_`Y'  
		margins, dydx(*) atmeans post
		est	sto margin3_frac_`Y'
		
  }

	*	Output result
	
	local	Y	fs_scale_fam
	
		*	Regression
		esttab	base1_fs_scale_fam	mean1_fs_scale_fam	var1_fs_scale_fam	R12_fs_scale_fam	R12_frac_fs_scale_fam	using "${PSID_outRaw}/CB_regression.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Regression) replace
			
		*	Marginal Effect
		esttab	margin1_base_`Y'	margin1_`Y'	margin2_`Y' 	margin3_`Y' margin3_frac_`Y' 		using "${PSID_outRaw}/CB_ME.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels /*drop(_cons)*/	title(Marginal Effects) replace
				
				
	*	Traditional regression (non-LASSO)
	
		*	Declare list of variables
		
		*	Common controls
		local	demovars	c.age_head_fam##c.age_head_fam i.race_head_cat gender_head_fam	ib1.marital_status_cat	
		local	eduvars		grade_comp_head_fam	c.grade_comp_head_fam#hs_completed c.grade_comp_head_fam#college_completed
		local	econvars	/*total_income_fam_wins*/	avg_income_pc	c.avg_income_pc#c.avg_income_pc
		local	famvars		num_FU_fam	num_child_fam
		local	foodvars	food_stamp_used_1yr	child_meal_assist	WIC_received_last*
		
		*	Threshold values
		scalar	wbar2_avg_foodexp_pc=1000
		scalar	wbar2_respondent_BMI=18.5
		
		
		*	AIC for model specification
		foreach Y in avg_foodexp_pc	respondent_BMI {
			
			svy: glm `Y' cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 	//	
			svy: estat ic
			est sto AIC1_`Y'
			predict AIC1_`Y'
			
			/*
			svy: glm `Y' cl.`Y'##cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 	//	
			est sto AIC2_`Y'
			predict AIC2_`Y'
			
			svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 	//	
			est sto AIC3_`Y'
			predict AIC3_`Y'
			*/
			
		}
	
	* Run (BMI)
  foreach Y in /*avg_foodexp_pc*/	respondent_BMI {
   *Mean Specifications 

    *One period lag, with squares and cubes
	
		*	Without controls
		*svy: nbreg `Y' cl.`Y'##cl.`Y'##cl.`Y' 	// nbreg
		svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y', family(gamma)
		est sto base1_`Y'
		margins, dydx(*) atmeans post	//	marginal effect
		est	sto	margin1_base_`Y'
  	
		*	With controls
		svy: glm `Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 	//	
		est sto mean1_`Y'
		predict mean1_`Y'
		predict e1_`Y', r
		margins, dydx(*) atmeans post	//	marginal effect
		est	sto	margin1_`Y'
      
  *Variance Specification
     
	*One-period lag, with squares and cubes
	 gen e1`Y'_sq = e1_`Y'^2	//	(SL: squared residual?)
	 
     svy: glm e1`Y'_sq cl.`Y'##cl.`Y'##cl.`Y' `demovars' `eduvars'	`econvars'	`famvars'	`foodvars', family(gamma) 
	 est sto var1_`Y'
	 predict var1_`Y'
	 margins, dydx(*) atmeans post	//	(SL: why do we use GLM instead of OLS? Why didn't we use it in the first step?)
     est	sto margin2_`Y'  

	
  *Resilience Scores & Regressions (using poverty line for OUTCOME, wbar2_`Y'), based on negative binomial distribution
     *One-period lag, with squares and cubes
	 
		gen alpha1_`Y' = mean1_`Y'^2 / var1_`Y'	
		gen beta1_`Y' = var1_`Y' / mean1_`Y'
		gen rho1_`Y' = 1 - gammap(alpha1_`Y', wbar2_`Y'/beta1_`Y')
	
		*	Now regress RHS variables on this predicted probability
		*reg rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' ndvi_z_var, vce(cluster geo_region)	//	(SL: Do we use LPM, not logit?) (Joan: rho1 is continuous b/w 0 and 1)
	   *est sto R1_`Y'
		svy: reg rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`eduvars'	`famvars'	`foodvars'
		est sto R12_`Y'
		margins, dydx(*) atmeans post	//	(SL: why do we use GLM instead of OLS? Why didn't we use it in the first step?)
		est	sto margin3_`Y'
		*svy: reg	rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`eduvars'	`famvars'	`foodvars'
		*svy: fracreg logit	rho1_`Y' cl.`Y'##cl.`Y'##cl.`Y' `demovars' `econvars'	`eduvars'	`famvars'	`foodvars'
	    *est sto R12_frac_`Y'  
		*margins, dydx(*) atmeans post
		*est	sto margin3_frac_`Y'
		
  }

	*	Output result
	/*
	foreach Y in /*avg_foodexp_pc*/	respondent_BMI {
	
		*	Regression
		esttab	base1_`Y'	mean1_`Y'	var1_`Y'	R12_`Y'	using "${PSID_outRaw}/CB_regression_`Y'.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels drop(_cons)	title(Regression) replace
			
		*	Marginal Effect
		esttab	margin1_base_`Y'	margin1_`Y'	margin2_`Y' 	margin3_`Y' margin3_`Y' 		using "${PSID_outRaw}/CB_ME_`Y'.csv", ///
				cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels /*drop(_cons)*/	title(Marginal Effects) replace
	}
	*/
	
		/*
	*	Review outcome variables
		
		*	Correlation between FS scores and outcome variables
		corr fs_scale_fam income_pc	food_exp_pc  avg_income_pc avg_foodexp_pc	respondent_BMI
		
		*	Data plot of the outcome variables
		kdensity income_pc, 		title(Household Income per capita) xtitle(Household Income per capita)
		graph	export	"${PSID_outRaw}/kdensity_income_pc.png",	replace
		
		kdensity food_exp_pc, 		title(Household food expenditure per capita) xtitle(Household food expenditure per capita)
		graph	export	"${PSID_outRaw}/kdensity_food_exp_pc.png",	replace
		
		kdensity avg_income_pc, 	title(Average income per capita) xtitle(Average per capita income over the two years)
		graph	export	"${PSID_outRaw}/kdensity_avg_income_pc.png",	replace
		
		kdensity avg_foodexp_pc, 	title(Average food expenditure per capita) xtitle(Average per capita food expenditure over the two years)
		graph	export	"${PSID_outRaw}/kdensity_avg_foodexp_pc.png",	replace
		
		kdensity respondent_BMI, 	title(Respondent BMI) xtitle(Respondent Body Mass Index)
		graph	export	"${PSID_outRaw}/kdensity_resp_BMI.png",	replace
		
		gen		log_respondent_BMI	=	log(respondent_BMI)
		kdensity log_respondent_BMI, 	title(log(Respondent BMI)) xtitle(Log of Respondent Body Mass Index)
		graph	export	"${PSID_outRaw}/kdensity_log_resp_BMI.png",	replace
		graph	close
		drop	log_respondent_BMI
	

	
		*	Distribution of food expenditure
		graph twoway (kdensity avg_foodexp_pc if year==10) /*(kdensity avg_foodexp_pc if (classic_step1_sample==1)	&	(classic_step2_sample==1) & year==10)*/, ///
				title (Distribution of Avg.food expenditure per capita)	/*///
				subtitle(Entire sample and regression sample)	///
				legend(lab (1 "All sample") lab(2 "Regression sample") rows(1))*/
				
	
		
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
		*/

	/*			
	local numvars : list sizeof `statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
					`familyvars'	`eduvars'	`foodvars'	`childvars'
	macro list numvars
	*/
	
	graph	twoway	(kdensity	rho1_avg_foodexp_pc_thrifty_ls)	///
				(kdensity	rho1_avg_foodexp_pc_thrifty_rf),	///
				title (Distribution of Resilience Score)	///
				subtitle(by construction method)	///
				note()
				legend(lab (1 "LASSO") lab(2 "RF") rows(1))

	rho1_avg_foodexp_pc_thrifty_ls	rho1_avg_foodexp_pc_thrifty_rf
	
	title (Distribution of Resilience Score)	///
				subtitle(Thrifty Food Plan) name(thrifty, replace)
				
				
				graph	twoway	(kdensity	fs_scale_fam_reverse)	(kdensity	rho1_avg_foodexp_pc_thrifty_ls)
				
				
			foreach	type	in	fs	{
				gen		valid_result_`type'	=	.
				replace	valid_result_`type'	=	1	if	inrange(year,9,10)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp==1
				replace	valid_result_`type'	=	2	if	inrange(year,9,10)	&	l.fs_cat_fam_simp==1	&	fs_cat_fam_simp!=1
				replace	valid_result_`type'	=	3	if	inrange(year,9,10)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp==1
				replace	valid_result_`type'	=	4	if	inrange(year,9,10)	&	l.fs_cat_fam_simp==0	&	fs_cat_fam_simp!=1
				label	var	valid_result_`type'	"Validation Result, `type'"
			}
			
	
		*	Validation Plot 
			*	USDA
					
					*	All sample
					tab	valid_result_USDA	if	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_USDA==4, msymbol(square)),	///
									xline(1)	yline(1)	xtitle(USDA measure 2015)	ytitle(USDA Fmeasure 2017)	///
									title(Food Security in 2015 vs Food Security in 2017)	name(USDA_all, replace)	///
									legend(lab (1 "Classified as food secure(76%)") lab(2 "Mis-Classified as food secure(6%)") lab(3 "Mis-Classified as food insecure(8%)")	lab(4 "Classified as food insecure(11%)")	rows(2))	///
									subtitle(Threshold determined by HFSSM)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_USDA_all.png", replace
					graph	close
					
					*	SEO, Immigrants (low incomde households)
					tab	valid_result_USDA	if	inlist(sample_source,2,3)	&	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_rf==1	&	inlist(sample_source,2,3), msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_rf==2	&	inlist(sample_source,2,3), msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_rf==3	&	inlist(sample_source,2,3), msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.fs_scale_fam_rescale	if	valid_result_rf==4	&	inlist(sample_source,2,3), msymbol(square)),	///
									xline(1)	yline(1)	xtitle(USDA measure 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(USDA_lowinc, replace)	///
									legend(lab (1 "Classified as food secure(57%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(12%)")	lab(4 "Classified as food insecure(23%)")	rows(2))	///
									subtitle(Threshold determined by HFSSM Low income HH)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_USDA_lowinc.png", replace
					graph	close
				
				*	OLS
					
					*	All sample
					tab	valid_result_ols	if	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==4, msymbol(square)),	///
									xline(`thresval_ols')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017) name(OLS_all, replace)	///
									legend(lab (1 "Classified as food secure(73%)") lab(2 "Mis-Classified as food secure(8%)") lab(3 "Mis-Classified as food insecure(11%)")	lab(4 "Classified as food insecure(9%)")	rows(2))	///
									subtitle(Threshold determined by OLS)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_OLS_all.png", replace
					graph	close
					
					*	SEO, Immigrants (low incomde households)
					tab	valid_result_ols	if	inlist(sample_source,2,3)	&	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==1	&	inlist(sample_source,2,3), msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==2	&	inlist(sample_source,2,3), msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==3	&	inlist(sample_source,2,3), msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ols	if	valid_result_ols==4	&	inlist(sample_source,2,3), msymbol(square)),	///
									xline(`thresval_ols')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017) name(OLS_lowinc, replace)	///
									legend(lab (1 "Classified as food secure(49%)") lab(2 "Mis-Classified as food secure(14%)") lab(3 "Mis-Classified as food insecure(19%)")	lab(4 "Classified as food insecure(17%)")	rows(2))	///
									subtitle(Threshold determined by OLS Low income HH)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_OLS_lowinc.png", replace
					graph	close
					
				*	LASSO
					
					*	All sample
					tab	valid_result_ls	if	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==4, msymbol(square)),	///
									xline(`thresval_ls')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(LASSO_all, replace)	///
									legend(lab (1 "Classified as food secure(73%)") lab(2 "Mis-Classified as food secure(8%)") lab(3 "Mis-Classified as food insecure(11%)")	lab(4 "Classified as food insecure(8%)")	rows(2))	///
									subtitle(Threshold determined by LASSO)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_LASSO_all.png", replace
					graph	close
					
					*	SEO, Immigrants (low incomde households)
					tab	valid_result_ls	if	inlist(sample_source,2,3)	&	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==1	&	inlist(sample_source,2,3), msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==2	&	inlist(sample_source,2,3), msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==3	&	inlist(sample_source,2,3), msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_ls	if	valid_result_ls==4	&	inlist(sample_source,2,3), msymbol(square)),	///
									xline(`thresval_ls')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(LASSO_lowinc, replace)	///
									legend(lab (1 "Classified as food secure(47%)") lab(2 "Mis-Classified as food secure(14%)") lab(3 "Mis-Classified as food insecure(22%)")	lab(4 "Classified as food insecure(16%)")	rows(2))	///
									subtitle(Threshold determined by LASSO Low income HH)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_LASSO_lowinc.png", replace
					graph	close
				
				*	Random Forest
					
					*	All sample
					tab	valid_result_rf	if	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==1, msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==2, msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==3, msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==4, msymbol(square)),	///
									xline(`thresval_rf')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(RF_all, replace)	///
									legend(lab (1 "Classified as food secure(72%)") lab(2 "Mis-Classified as food secure(9%)") lab(3 "Mis-Classified as food insecure(11%)")	lab(4 "Classified as food insecure(7%)")	rows(2))	///
									subtitle(Threshold determined by RF)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_RF_all.png", replace
					graph	close
					
					*	SEO, Immigrants (low incomde households)
					tab	valid_result_rf	if	inlist(sample_source,2,3)	&	inrange(year,9,10)
					graph	twoway	(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==1	&	inlist(sample_source,2,3), msymbol(circle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==2	&	inlist(sample_source,2,3), msymbol(diamond))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==3	&	inlist(sample_source,2,3), msymbol(triangle))	///
									(scatter	fs_scale_fam_rescale	l.rho1_foodexp_pc_thrifty_rf	if	valid_result_rf==4	&	inlist(sample_source,2,3), msymbol(square)),	///
									xline(`thresval_rf')	yline(1)	xtitle(Resilience Score in 2015)	ytitle(USDA Food Security Score in 2017)	///
									title(Resilience in 2015 vs Food Security in 2017)	name(RF_lowinc, replace)	///
									legend(lab (1 "Classified as food secure(49%)") lab(2 "Mis-Classified as food secure(15%)") lab(3 "Mis-Classified as food insecure(20%)")	lab(4 "Classified as food insecure(16%)")	rows(2))	///
									subtitle(Threshold determined by RF Low income HH)
					
					graph	export	"${PSID_outRaw}/OOB_prediction_RF_lowinc.png", replace
					graph	close
