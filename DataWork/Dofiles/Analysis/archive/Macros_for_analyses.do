*	Define  macros for analyses
		
	*	Study samplm
		global	study_sample	sample_source_SRC_SEO
		
	*	States (used for regression coefficients plots)
		global	state_Northeast	6.state_resid_fam	18.state_resid_fam	20.state_resid_fam	28.state_resid_fam	///
								29.state_resid_fam	31.state_resid_fam	37.state_resid_fam	/*38.state_resid_fam*/	44.state_resid_fam
		global	state_Ncentral	12.state_resid_fam	13.state_resid_fam	14.state_resid_fam	15.state_resid_fam	///
								21.state_resid_fam	22.state_resid_fam	24.state_resid_fam	26.state_resid_fam	///
								33.state_resid_fam	38.state_resid_fam	40.state_resid_fam	48.state_resid_fam
		global	state_South		1.state_resid_fam	3.state_resid_fam	7.state_resid_fam	8.state_resid_fam	///
								9.state_resid_fam	10.state_resid_fam	16.state_resid_fam	17.state_resid_fam	///
								19.state_resid_fam	23.state_resid_fam	32.state_resid_fam	35.state_resid_fam	///
								39.state_resid_fam	41.state_resid_fam	42.state_resid_fam	45.state_resid_fam	///
								47.state_resid_fam
			*	Without Delarware
			global	state_South_noDE	1.state_resid_fam	3.state_resid_fam	/*7.state_resid_fam*/	8.state_resid_fam	///
										9.state_resid_fam	10.state_resid_fam	16.state_resid_fam	17.state_resid_fam	///
										19.state_resid_fam	23.state_resid_fam	32.state_resid_fam	35.state_resid_fam	///
										39.state_resid_fam	41.state_resid_fam	42.state_resid_fam	45.state_resid_fam	///
										47.state_resid_fam
		global	state_West		2.state_resid_fam	4.state_resid_fam	5.state_resid_fam	11.state_resid_fam	///
								25.state_resid_fam	27.state_resid_fam	30.state_resid_fam	36.state_resid_fam	///
								43.state_resid_fam	46.state_resid_fam	49.state_resid_fam	
		
		
		*	Grouped state (Based on John's suggestion on 2020/12/15)
		
			*	Reference state
			global	state_bgroup	state_resid_fam_enum32	//	NY
			
			*	Excluded states (Alaska, Hawaii, U.S. territory, DK/NA)
			global	state_group0	state_resid_fam_enum1	state_resid_fam_enum52	///	//	Inapp, DK/NA
									state_resid_fam_enum50	state_resid_fam_enum51	//	AK, HI
			global	state_group_ex	${state_group0}
			
			*	Northeast
			global	state_group1	state_resid_fam_enum19 state_resid_fam_enum29 state_resid_fam_enum44	///	//	ME, NH, VT
									state_resid_fam_enum21 state_resid_fam_enum7	//	MA, CT
			global	state_group_NE	${state_group1}
				
			*	Mid-atlantic
			global	state_group2	state_resid_fam_enum38	//	PA
			global	state_group3	state_resid_fam_enum30	//	NJ
			global	state_group4	state_resid_fam_enum9	state_resid_fam_enum8	state_resid_fam_enum20	//	DC, DE, MD
			global	state_group5	state_resid_fam_enum45	//	VA
			global	state_group_MidAt	${state_group2}	${state_group3}	${state_group4}	${state_group5}
			
			*	South
			global	state_group6	state_resid_fam_enum33	state_resid_fam_enum39	//	NC, SC
			global	state_group7	state_resid_fam_enum11	//	GA
			global	state_group8	state_resid_fam_enum17	state_resid_fam_enum41	state_resid_fam_enum47	//	KT, TN, WV
			global	state_group9	state_resid_fam_enum10	//	FL
			global	state_group10	state_resid_fam_enum2	state_resid_fam_enum4	state_resid_fam_enum24 state_resid_fam_enum18	//	AL, AR, MS, LA
			global	state_group11	state_resid_fam_enum42	//	TX
			global	state_group_South	${state_group6}	${state_group7}	${state_group8}	${state_group9}	${state_group10}	${state_group11}
			
			*	Mid-west
			global	state_group12	state_resid_fam_enum35	//	OH
			global	state_group13	state_resid_fam_enum14	//	IN
			global	state_group14	state_resid_fam_enum22 	//	MI
			global	state_group15	state_resid_fam_enum13	//	IL
			global	state_group16	state_resid_fam_enum23 state_resid_fam_enum48	//	MN, WI
			global	state_group17	state_resid_fam_enum15	state_resid_fam_enum25	//	IA, MO
			global	state_group_MidWest	${state_group12}	${state_group13}	${state_group14}	${state_group15}	${state_group16}	${state_group17}
			
			*	West
			global	state_group18	state_resid_fam_enum16	state_resid_fam_enum27	///	//	KS, NE
									state_resid_fam_enum34	state_resid_fam_enum40	///	//	ND, SD
									state_resid_fam_enum36	//	OK
			global	state_group19	state_resid_fam_enum3	state_resid_fam_enum6	///	//	AZ, CO
									state_resid_fam_enum12	state_resid_fam_enum26	///	//	ID, MT
									state_resid_fam_enum28	state_resid_fam_enum31	///	//	NV, NM
									state_resid_fam_enum43	state_resid_fam_enum49		//	UT, WY
			global	state_group20	state_resid_fam_enum37	state_resid_fam_enum46	//	OR, WA
			global	state_group21	state_resid_fam_enum5	//	CA						
			global	state_group_West	${state_group18}	${state_group19}	${state_group20}	${state_group21}	
	
	*	Regression variables
		
			*global	statevars			lag_food_exp_pc_1 lag_food_exp_pc_2	lag_food_exp_pc_3 //	Lagged food expenditure per capita, up to third order
			*global	statevars_rescaled	lag_food_exp_pc_1 lag_food_exp_pc_2	lag_food_exp_pc_th_3 //	Same as "statevars", but replaced the third order with re-scaled version (to properly display coefficients)
			global	statevars			lag_food_exp_stamp_pc_1 lag_food_exp_stamp_pc_2	lag_food_exp_stamp_pc_3 //	Lagged food expenditure per capita, up to third order
			global	statevars_rescaled	lag_food_exp_stamp_pc_1 lag_food_exp_stamp_pc_2	lag_food_exp_stamp_pc_th_3 //	Same as "statevars", but replaced the third order with re-scaled version (to properly display coefficients)
			
			
			global	demovars			age_head_fam age_head_fam_sq	HH_race_color	marital_status_cat	HH_female	//	age, age^2, race, marital status, gender
			global	econvars			ln_income_pc	//	log of income per capita
			global	healthvars			phys_disab_head mental_problem	//	physical and mental health
			global	empvars				emp_HH_simple	//	employment status
			global	familyvars			num_FU_fam ratio_child	//	# of family members and % of ratio of children
			global	eduvars				highdegree_NoHS	highdegree_somecol	highdegree_col	//	Highest degree achieved
			global	foodvars			food_stamp_used_0yr	child_meal_assist 		//	Food assistance programs
			global	changevars			no_longer_employed	no_longer_married	no_longer_own_house	became_disabled	//	Change in status
			global	regionvars			state_group? state_group1? state_group2?	//	Region (custom group of status)
			global	timevars			year_enum3-year_enum10	//	Year dummies
			