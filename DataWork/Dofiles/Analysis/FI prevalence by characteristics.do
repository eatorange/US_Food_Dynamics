


cap	mat	drop	HCR_PFS_3		HCR_PFS_10
cap mat drop	HCR_HFSM_3		HCR_HFSM_10

		foreach year in	3		10	{	// 2001, 2011, 2017
		   foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
				foreach	race	in	0	1	{	//	People of colors, white
					foreach	gender	in	1	0	{	//	Female, male
						
					svy, subpop(if ${study_sample} & year==`year'	&	HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	mean rho1_thrifty_FS_ols 
					mat	HCR_PFS_`year'	=	nullmat(HCR_PFS_`year')	\	e(b)[1,1]

					svy, subpop(if ${study_sample} & year==`year'	&	HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	mean fs_cat_fam_simp 
					mat	HCR_HFSM_`year'	=	nullmat(HCR_HFSM_`year')	\	e(b)[1,1]

					}	//	gender
				}	//	race
		   }	//	edu
		   
			mat	HCR_all_`year'	=	HCR_PFS_`year',	HCR_HFSM_`year'
			mat list HCR_all_`year'
		   
		}

mat list HCR_all_3
mat list HCR_all_10


tab	fs_cat_fam_simp	rho1_thrifty_FS_ols if ${study_sample}==1, cell
svy, subpop(${study_sample}):	tab	fs_cat_fam_simp	rho1_thrifty_FS_ols

local 


*	Specific year
local year=10
svy, subpop(if ${study_sample} & year==`year'	&	HH_female==1 ):	mean rho1_thrifty_FS_ols 
svy, subpop(if ${study_sample} & year==`year'	&	HH_female==1 ):	mean fs_cat_fam_simp 

svy, subpop(if ${study_sample} & year==`year'	&	HH_race_white==0 ):	mean rho1_thrifty_FS_ols 
svy, subpop(if ${study_sample} & year==`year'	&	HH_race_white==0 ):	mean fs_cat_fam_simp 

svy, subpop(if ${study_sample} & year==`year'	&	income_to_poverty_cat==1 ):	mean rho1_thrifty_FS_ols 
svy, subpop(if ${study_sample} & year==`year'	&	income_to_poverty_cat==1 ):	mean fs_cat_fam_simp 

svy, subpop(if ${study_sample} & year==`year'	&	food_stamp_used_0yr==1 ):	mean rho1_thrifty_FS_ols 
svy, subpop(if ${study_sample} & year==`year'	&	food_stamp_used_0yr==1 ):	mean fs_cat_fam_simp 


*	Overall
svy, subpop(if ${study_sample} & inlist(year,2,3,9,10)	&	income_to_poverty_cat==1 ):	mean rho1_thrifty_FS_ols 
svy, subpop(if ${study_sample} & inlist(year,2,3,9,10)	&	income_to_poverty_cat==1 ):	mean fs_cat_fam_simp 

svy, subpop(if ${study_sample} & inlist(year,2,3,9,10)	&	food_stamp_used_0yr==1 ):	mean rho1_thrifty_FS_ols 
svy, subpop(if ${study_sample} & inlist(year,2,3,9,10)	&	food_stamp_used_0yr==1 ):	mean fs_cat_fam_simp 


