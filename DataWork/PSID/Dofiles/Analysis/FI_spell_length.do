cap drop FI_duration
gen FI_duration=.

cap	drop	num_nonmissing_PFS
cap	mat	drop	dist_spell_length
mat	dist_spell_length	=	J(8,10,.)

forval	wave=2/9	{
	
	cap drop FI_duration_year*	_seq _spell _end	
	tsspell, cond(year>=`wave' & rho1_thrifty_FI_ols==1)
	egen FI_duration_year`wave' = max(_seq), by(fam_ID_1999 _spell)
	replace	FI_duration = FI_duration_year`wave' if rho1_thrifty_FI_ols==1 & year==`wave'
			
	*	Replace households that used to be FI last year with missing value (We are only interested in those who newly became FI)
	if	`wave'>=3	{
		replace	FI_duration	=.	if	year==`wave'	&	!(rho1_thrifty_FI_ols==1	&	l.rho1_thrifty_FI_ols==0)
	}
	
}

*	Exclude non-balanced sample (include only households with existing PFS scores through the study period)
bys fam_ID_1999: egen num_nonmissing_PFS=count(rho1_thrifty_FI_ols)
replace FI_duration=.	if	num_nonmissing_PFS<9 //

forval	wave=2/9	{
	
	local	row=`wave'-1
	svy, subpop(if year==`wave'): tab FI_duration
	mat	dist_spell_length[`row',1]	=	e(N_subpop), e(b)
	
}

putexcel	set "${PSID_outRaw}/Transition_Matrices", sheet(spell_length) modify	/*replace*/
putexcel	A5	=	matrix(dist_spell_length), names overwritefmt nformat(number_d1)