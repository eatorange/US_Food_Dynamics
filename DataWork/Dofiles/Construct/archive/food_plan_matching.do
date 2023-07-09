use	"${PSID_dtInt}/PSID_clean_1999_2017_ind.dta", clear 

forvalues	year=1999(2)1999	{

	*	Num of family member
	bys x11102_`year': egen num_fu_`year' = count(xsqnr_`year') if inrange(xsqnr_`year',1,20) 
	
	*	Num of children
	bys x11102_`year': egen num_child_`year' = count(xsqnr_`year') if inrange(xsqnr_`year',1,20) &	inrange(age_ind`year',1,17)
	replace	num_child_`year'=0	if	!mi(x11102_`year') & mi(num_child_`year')

	br x11102_`year' xsqnr_`year'	num_fu_`year'	num_child_`year'
	keep	x11102_`year'	num_fu_`year'	num_child_`year'

	foreach var in num_fu_`year' num_child_`year'	{
		bys x11102_`year': egen `var'_max = max(`var')
		drop	`var'
		rename	`var'_max	`var'
	}

	*duplicates drop
	*drop if mi(x11102_`year')

}

rename x11102_2009 ER42002
merge 1:1 ER42002 using "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam2009er.dta" , keepusing(ER42016 ER42020)
gen diff_FU=1 if num_fu_2009 != ER42016
gen diff_child=1 if num_child_2009!=ER42020
*tab diff_child

*br if diff_child==1

   