
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
			replace	marital_status_cat`year'=2	if	inrange(marital_status_fam`year',2,5)
			replace	marital_status_cat`year'=.n	if	inrange(marital_status_fam`year',8,9)
			
			label variable	marital_status_cat`year'	"Marital Status of Head, `year'"
		}
		label	define	marital_status_cat	1	"Married"	2	"Not Married"
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
		}
		label	define	age_head_cat	1	"16-24"	2	"25-34"	3	"35-44"	///
										4	"45-54"	5	"55-64"	6	"65 and older"
		label	values	age_head_cat*	age_head_cat
		
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
		loc	socioeconvars	edu_years_head_fam*	FPL*	grade_comp*	college_completed*	hs_completed*	total_income_fam*	income_pc*		avg_income_pc*	avg_foodexp_pc*
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

		*	Retrieve the list time-series variables
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
		label	var	age_head_fam		"Age of Household Head"
		label	var	race_head_fam		"Race of Household Head"
		label	var	total_income_fam	"Total Household Income"
		label	var	marital_status_fam	"Marital Status of Head"
		label	var	num_FU_fam			"# of Family members"
		label	var	num_child_fam		"# of Children"
		label	var	gender_head_fam		"Gender of Household Head"
		label	var	edu_years_head_fam	"Years of Education"
		label	var	state_resid_fam		"State of Residence"
		label 	var	fs_raw_fam 			"Food Security Score (Raw)"
		label 	var	fs_scale_fam 		"Food Security Score (Scale)"
		label	var	fs_cat_fam 			"Food Security Category"
		label	var	food_stamp_used_2yr	"Received Food Stamp (2 years ago)"
		label	var	food_stamp_used_1yr "Received Food Stamp (1 year ago)"
		label	var	child_meal_assist	"Received Child Free Meal"
		label	var	WIC_received_last	"Received WIC"
		label	var	family_comp_change	"Change in Family Composition"
		label	var	grade_comp_cat		"Highest Grade Completed"
		label	var	race_head_cat		"Race of Household Head"
		label	var	marital_status_cat	"Marital Status of Head"
		label	var	child_in_FU_cat		"Household has a child"
		label	var	age_head_cat 		"Age of Household Head (category)"
		label	var	total_income_fam_wins	"Total Household Income (winsorized)"
		label	var	hs_completed_head		"HH completed high school/GED"
		label	var	college_completed	"HH has college degree"
		label	var	respondent_BMI		"Respondent's Body Mass Index"
		label	var	income_pc			"Family income per capita"
		label	var	food_exp_pc			"Food expenditure per capita"
		label	var	avg_income_pc		"Average income over two years per capita"
		label	var	avg_foodexp_pc		"Average food expenditure over two years per capita"
		
		label	var	splitoff_indicator		"Splitoff indicator"
		label	var	num_split_fam		"# of splits"
		label	var	main_fam_ID		"Family ID"
		label	var	food_exp_total_wins		"Total food expenditure"
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
		label	var	edu_years_spouse		"Yrs schooling (spouse)"
		label	var	hs_completed_spouse		"HS degree (spouse)"
		label	var	child_exp_total_wins		"Annual child expenditure"
		label	var	cloth_exp_total_wins		"Annual cloth expenditure"
		label	var	sup_outside_FU		"Support from outside family"
		label	var	edu_exp_total_wins		"Annual education expenditure"
		label	var	health_exp_total_wins	"Annual health expenditure"
		label	var	house_exp_total_wins		"Annual housing expenditure"
		label	var	tax_item_deduct		"Itemized tax deduction"

		label	var	property_tax_wins		"Property tax ($)"
		label	var	transport_exp_wins		"Annual transport expenditure"

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
		label	var	elderly_meal	"Elderly meal"
		label	var	retire_plan_head		"Retirement plan (head)"
		label	var	retire_plan_spouse	"Retirement plan (spouse)"
		label	var	annuities_IRA		"Annuities_IRA"
		label	var	veteran_head	"Veteran (head)"
		label	var	veteran_spouse	"Veteran (spouse)"
		label	var	wealth_total_wins	"Total wealth"
		label	var	emp_status_head	"Employement status (head)"
		label	var	emp_status_spouse	"Employement status(spouse)"
		label	var	alcohol_spouse	"Drink alcohol (spouse)"
		*label	var	relat_to_current_head	"Veteran (head)"
		label	var	child_exp_pc		"Annual child expenditure (pc)"
		label	var	edu_exp_pc		"Annual education expenditure (pc)"
		label	var	health_exp_pc		"Annual health expenditure (pc)"
		label	var	house_exp_pc		"Annual house expenditure (pc)"
		label	var	property_tax_pc		"Property tax (pc)"
		label	var	transport_exp_pc	"Annual transportation expenditure (pc)"
		label	var	wealth_pc		"Wealth (pc)"
		label	var	cloth_exp_pc		"Annual cloth expenditure (pc)"
		label	var	avg_childexp_pc		"Avg child expenditure (pc)"
		label	var	avg_eduexp_pc		"Avg education expenditure (pc)"
		label	var	avg_healthexp_pc		"Avg health expenditure (pc)"
		label	var	avg_houseexp_pc		"Avg house expenditure (pc)"
		label	var	avg_proptax_pc		"Avg property expenditure (pc)"
		label	var	avg_transexp_pc		"Avg transportation expenditure (pc)"
		label	var	avg_wealth_pc		"Avg wealth (pc)"
		label	var	emp_HH_simple		"Employed status (simplified, head)"
		label	var	emp_spouse_simple		"Employed status (simplified, spouse)"
		label	var	fs_cat_MS		"Marginal food secure"
		label	var	fs_cat_IS		"Food insecure"
		label	var	fs_cat_VLS		"Very Low food secure"
		label	var	child_bf_assist		"Free/reduced breakfast from school"
		label	var	child_lunch_assist		"Free/reduced lunch from school"
		label	var	splitoff_dummy		"Splitoff ummy"
		label	var	accum_splitoff		"Accumulated splitoff"
		label	var	other_debts			"Other debts"

		label	var	cloth_exp_total_wins		"Other debts"
		
		label	var	FPL_		"Federal Poverty Line"
		label	var	FPL_cat		"Federal Poverty Line category"
			      
		drop	height_feet		height_inch	  weight_lbs	child_bf_assist	child_lunch_assist	food_exp_total	child_exp_total	edu_exp_total	health_exp_total	///
				house_exp_total	property_tax	transport_exp	wealth_total	cloth_exp_total
		
		
	*	Recode N/A & nonrespones reponses of "some" variables
	***	Recoding nonresponses & N/As should be done carefully, as there could be statistical difference between responses and non-responses. Judgements must be done by variable-level
	***	Among the variables with nonresponeses (ex. DK, Refusal), some of them have very small fraction of nonrespones (ex.less than 0.1%) This implies that they can be relatively recoded as missing safely.

		*	Recode variables which have a very small fraction of non-responses & N/As
		qui	ds	food_stamp_used_2yr	food_stamp_used_1yr	child_meal_assist	WIC_received_last	college_completed	child_daycare_any	college_comp_spouse	sup_outside_FU	///
				alcohol_head	smoke_spouse	phys_disab_head  phys_disab_spouse	elderly_meal	retire_plan_head retire_plan_spouse	annuities_IRA	alcohol_spouse	///
				
	    recode	`r(varlist)'	(8=.d)	(9=.r)
		
		replace	alcohol_head=.n	if	alcohol_head==0	// only 1 obs
		replace	smoke_head=.n	if	smoke_head==0	// only 1 obs
                                               
	
	/****************************************************************
		SECTION 2: Construct CB measurement
	****************************************************************/	
	
	*	Recode time variables, to start from 1 and increase by 1 in every wave
	replace	year	=	(year-1997)/2
	
	*	Define the data as survey data and time-series data
	svyset	ER31997 [pweight=weight_long_fam], strata(ER31996)	singleunit(scaled)
	xtset fam_ID_1999 year,	delta(1)
	
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
		graph twoway (kdensity avg_foodexp_pc if year==10) (kdensity avg_foodexp_pc if (cvlass_sample==1)	&	(cvlass_sample2==1)), ///
				title (Distribution of Avg.food expenditure per capita)	///
				subtitle(Entire sample and regression sample)	///
				legend(lab (1 "All sample") lab(2 "Regression sample") rows(1))
				
				
		*	Summary statistics
		eststo drop	Total SRC	SEO	Imm

		local	sumvars	age_head_fam num_FU_fam num_child_fam edu_years_head_fam alcohol_head smoke_head	fs_scale_fam food_stamp_used_1yr 	///
						income_pc food_exp_pc edu_exp_pc health_exp_pc	///

		preserve
		recode		alcohol_head	smoke_head		food_stamp_used_1yr	(5=0)
						
						
		estpost summarize	`sumvars' if inrange(year,3,10) /*& cvlass_sample==1*/
		est store Total
		estpost summarize	`sumvars' if inrange(year,3,10) /*& cvlass_sample==1*/ & sample_source==1
		est store SRC
		estpost summarize	`sumvars' if inrange(year,3,10) /*& cvlass_sample==1*/ & sample_source==2
		est store SEO
		estpost summarize	`sumvars' if inrange(year,3,10) /*& cvlass_sample==1*/ & sample_source==3
		est store Imm


		esttab Total SRC SEO Imm using tt2.csv, replace ///
		cells("mean(pattern(1 1 1 1) fmt(2)) sd(pattern(1 1 1 1) fmt(2))") label	///
		nonumbers mtitles("Total" "SRC" "SEO" "Immigrants") ///
		title (Summary Statistics) ///
		/*coeflabels(avg_foodexp_pc "Avg. Food Exp" avg_wealth_pc "YYY")*/ csv ///
		addnotes(Includes households in LASSO regression. SRC stands for Survey Research Center composed of nationally representative households, SEO stands for Survey Economic Opportunities composed of low income households, and Immigrants are those newly added to the PSID in 1997 and 1999)

		restore
		
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
	
	*	Variable selection
	
	local	statevars	cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc##cl.avg_foodexp_pc	//	up to the order of 5
	local	healthvars	respondent_BMI	ib5.alcohol_head ib5.alcohol_spouse	ib5.smoke_head ib5.smoke_spouse	ib5.phys_disab_head ib5.phys_disab_spouse
	local	demovars	c.age_head_fam##c.age_head_fam	ib1.race_head_cat	ib2.marital_status_fam	ib1.gender_head_fam	ib0.state_resid_fam	c.age_spouse##c.age_spouse	ib5.housing_status	ib5.veteran_head ib5.veteran_spouse
	local	econvars	c.avg_income_pc##c.avg_income_pc	c.avg_wealth_pc##c.avg_wealth_pc	ib5.sup_outside_FU	ib5.tax_item_deduct	ib5.retire_plan_head ib5.retire_plan_spouse	ib5.annuities_IRA
	local	empvars		ib5.emp_HH_simple	ib5.emp_spouse_simple
	local	familyvars	num_FU_fam num_child_fam	ib0.family_comp_change	ib5.couple_status	ib5.head_status ib5.spouse_new
	local	eduvars		ib5.attend_college_head ib5.attend_college_spouse	college_yrs_head college_yrs_spouse	(ib5.hs_completed_head	ib5.college_completed	ib5.other_degree_head)##c.edu_years_head_fam	(ib5.hs_completed_spouse	ib5.college_comp_spouse	ib5.other_degree_spouse)##c.edu_years_spouse
	local	foodvars	ib5.food_stamp_used_1yr	ib5.child_meal_assist ib5.WIC_received_last	meal_together	ib5.elderly_meal
	local	childvars	ib5.child_daycare_any ib5.child_daycare_FSP ib5.child_daycare_snack	

	/*			
	local numvars : list sizeof `statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
					`familyvars'	`eduvars'	`foodvars'	`childvars'
	macro list numvars
	*/
	

		
	*	Recode nonresponses (dk, refuse, inappropriate) as "negative"
	local	recode_vars	1
	if	`recode_vars'==1	{
		qui	ds	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse	veteran_head	veteran_spouse	tax_item_deduct	///
				retire_plan_head	retire_plan_spouse	annuities_IRA	attend_college_head	attend_college_spouse	hs_completed_head	hs_completed_spouse	///
				college_completed	college_comp_spouse	other_degree_head	other_degree_spouse	food_stamp_used_1yr	child_meal_assist	WIC_received_last	elderly_meal	///
				child_daycare_any	child_daycare_FSP	child_daycare_snack	
		recode	`r(varlist)'	(0	8	9	.d	.r=5)
	}
	
	
	*	Codebook (To share with John, Chris and Liz)
	/*	
	codebook	respondent_BMI	alcohol_head	alcohol_spouse	smoke_head	smoke_spouse	phys_disab_head	phys_disab_spouse			///
				age_head_fam	age_spouse	race_head_cat	marital_status_fam		gender_head_fam		state_resid_fam	housing_status	veteran_head	veteran_spouse	///
				avg_income_pc	avg_wealth_pc	sup_outside_FU	tax_item_deduct	retire_plan_head	retire_plan_spouse	annuities_IRA	///
				emp_HH_simple	emp_spouse_simple	///
				num_FU_fam	num_child_fam	family_comp_change	couple_status	head_status	spouse_new	///
				edu_years_head_fam	edu_years_spouse	attend_college_head	attend_college_spouse	college_yrs_head	college_yrs_spouse	///
				hs_completed_head	hs_completed_spouse	college_completed	college_comp_spouse	other_degree_head	other_degree_spouse					///
				food_stamp_used_1yr	child_meal_assist	WIC_received_last	meal_together	elderly_meal	child_daycare_any	child_daycare_FSP	child_daycare_snack, compact
				
	*/			
				
	
	*	Step 1
	local	run_step1	1
	if	`run_step1'==1	{
		
		*	Feature Selection
		*	Run Lasso with "rolling ahead" validation
		
		local	depvar	c.avg_foodexp_pc
		*local	depvar	c.fs_scale_fam
		*local	statevars	cl.fs_scale_fam##cl.fs_scale_fam##cl.fs_scale_fam##cl.fs_scale_fam##cl.fs_scale_fam
		
		cvlasso	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
					`familyvars'	`eduvars'	`foodvars'	`childvars' if inlist(year,1,2,3,9,10),	///
				lopt /*lse*/	rolling	h(1)	seed(20200505)	prestd fe /*postres		ols*/	plotcv 

		gen	cvlass_sample=1	if	e(sample)==1		

		*	Predict conditional means and variance from LASSO (original LASSO)
		predict double mean1_avgfoodexp, lopt
		predict double e1_avgfoodexp, lopt e
		gen e1_avgfoodexp_sq = e1_avgfoodexp^2

		*	Post-lasso estimation
		cvlasso, postresult lopt	//	somehow this command is needed to generate `e(selected)' macro. Need to double-check
		global selected `e(selected)'
		*svy:	reg `e(depvar)' `e(selected)'
		*est store step1_postlasso
	}

	*	Step 2
	local	run_step2	1
	if	`run_step2'==0	{
		
		local	depvar	e1_avgfoodexp_sq

		cvlasso	`depvar'	`statevars'	`healthvars'	`demovars'	`econvars'	`empvars'	`familyvars'	`eduvars'	///
						`familyvars'	`eduvars'	`foodvars'	`childvars',	///
					lopt /*lse*/	rolling	h(1)	seed(20200505)	prestd fe /*postres		ols*/	plotcv ///

		gen	cvlass_sample2=1	if	e(sample)==1
		
		predict	double	var2_avgfoodexp, xb
		
		svy:	reg `e(depvar)' `e(selected)'
		est store step2_postlasso
	}

	*	Step 3
	local	run_step3	1
	if	`run_step3'==1	{
		
		*	Assume the outcome variable follows the Gamma distribution
		gen alpha1_avg_foodexp_pc = mean1_avgfoodexp^2 / var2_avgfoodexp	//	shape parameter of Gamma (alpha)
		gen beta1_avg_foodexp_pc = var2_avgfoodexp / mean1_avgfoodexp	//	scale parameter of Gamma (beta)
		
		*	Construct CDF
		foreach	plan	in	thrifty low moderate liberal	{
			gen rho1_avg_foodexp_pc_`plan' = gammaptail(alpha1_avg_foodexp_pc, avg_foodexp_W_`plan'/beta1_avg_foodexp_pc)	if	(cvlass_sample==1)	&	(cvlass_sample2==1)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
			label	var	rho1_avg_foodexp_pc_`plan' "Resilience score, `plan' plan"
		}
	}
	
				
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
		replace	rho1_`plan'_MS	=	1	if	inrange(`plan'_pctile,42,100)	//	Marginal food secure
		
		gen		rho1_`plan'_HS	=	0	if	!mi(rho1_avg_foodexp_pc_`plan')
		replace	rho1_`plan'_HS	=	1	if	inrange(`plan'_pctile,101,1000)	//	Highly secure
		
	}

	svy: tab rho1_thrifty_HS fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_thrifty), cell
	svy: tab rho1_low_HS fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_low), cell
	svy: tab rho1_moderate_HS fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_moderate), cell
	svy: tab rho1_liberal_HS fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal), cell


	svy: tab rho1_liberal_HS fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal) & sample_source==1, cell
	svy: tab rho1_liberal_HS fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal) & sample_source==2, cell
	svy: tab rho1_liberal_HS fs_cat_fam_simp if !mi(rho1_avg_foodexp_pc_liberal) & sample_source==3, cell


	graph twoway (kdensity fs_scale_fam), title(Distribution of USDA Measure) name(fs_scale)	
	graph combine thrifty	fs_scale

								
/* Junk Code */
/* The following codes are old codes used when outcome variable are non-negative discrete variables (FS score) */		

/*
	*	Declare list of variables
	local	demovars	c.age_head_fam##c.age_head_fam i.race_head_cat gender_head_fam	ib1.marital_status_cat	edu_years_head_fam
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
		local	eduvars		edu_years_head_fam	c.edu_years_head_fam#hs_completed c.edu_years_head_fam#college_completed
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