cap	mat	drop	FI_2005_2007
cap mat drop 	FI_allyears
	* Year 5 & 6 (2007, 2009. To compare with the USDA estimates)
	qui svy, subpop(if ${study_sample}==1 & inrange(year,5,6)):	///
		mean rho1_foodexp_pc_thrifty_ols rho1_thrifty_FI_ols	//Total_FI	Chronic_FI
		
		mat FI_2005_2007 = nullmat(FI_2005_2007)	\	e(N_sub), r(table)[1,2] //, r(table)[2,2]*1.645
		
	*	All years
	qui svy, subpop(if ${study_sample}==1):	///
		mean rho1_foodexp_pc_thrifty_ols rho1_thrifty_FI_ols	//Total_FI	Chronic_FI
		
		mat FI_allyears = nullmat(FI_allyears)	\	e(N_sub), r(table)[1,2] //, r(table)[2,2]*1.645	
		
forval no=1/51	{
			
	* Year 5 & 6 (2007, 2009. To compare with the USDA estimates)
	qui svy, subpop(if ${study_sample}==1 & inrange(year,5,6) & state_resid_fam_enum`no'==1):	///
		mean rho1_foodexp_pc_thrifty_ols rho1_thrifty_FI_ols	//Total_FI	Chronic_FI
		
		mat FI_2005_2007 = nullmat(FI_2005_2007)	\	e(N_sub), r(table)[1,2] //, r(table)[2,2]*1.645
		
	*	All years
	qui svy, subpop(if ${study_sample}==1 & state_resid_fam_enum`no'==1):	///
		mean rho1_foodexp_pc_thrifty_ols rho1_thrifty_FI_ols	//Total_FI	Chronic_FI
		
		mat FI_allyears = nullmat(FI_allyears)	\	e(N_sub), r(table)[1,2] //, r(table)[2,2]*1.645	
		
}


	putexcel	set "${PSID_outRaw}/FI_prevalence", sheet(2005_2007) replace	/*modify*/
	putexcel	A3	=	matrix(FI_2005_2007), names overwritefmt nformat(number_d1)
	putexcel	set "${PSID_outRaw}/FI_prevalence", sheet(all_years) /*replace*/	modify
	putexcel	A3	=	matrix(FI_allyears), names overwritefmt nformat(number_d1)
	
	


