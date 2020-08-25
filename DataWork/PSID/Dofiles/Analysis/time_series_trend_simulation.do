
/*
graph	twoway	(scatter rho1_foodexp_pc_thrifty_ols num_child_fam if income_pc>0)		///
				(line fv num_child_fam, title(Expected Pr(FS) over income))
				

margins, dydx(num_child_fam) over(income_to_poverty_cat)
				
twoway lpolyci fv age_head_fam, title(Expected Pr(FS) over age)

*/

*	Data setup
clear
set	obs	1000
gen	year=mod(_n,10)
replace	year=10	if	year==0
sort year
gen	hhid=mod(_n,100)
replace	hhid=100	if	hhid==0

xtset hhid year

*	Error without serial correlation
gen	eps=rnormal()	
gen y=3+4*year+eps // True model: y = b0 + b1*year + eps

*	Year as trend
reg y year
predict resid_yr, residual

*	Year as fixed effect
reg	y	i.year
predict	resid_fe, residual

*	Reg of resid on lagged resid
	
	*	year trend
	xtreg	resid_yr	l.resid_yr,	fe	//	FE
	xtreg	resid_yr	l.resid_yr, vce(cluster hhid) fe	//	FE with panel clustered SE

	*	year FE
	xtreg	resid_fe	l.resid_fe, fe
	xtreg	resid_fe	l.resid_fe, vce(cluster hhid) fe


*	Error with serial correlation
gen	eps_acr	=	rnormal() if year==1
bys	hhid:	replace	eps_acr	=	(1*l.eps_acr)+eps	if	year!=1
gen	y_acr	=	rnormal(6,1)	if	year==1
replace	y_acr	=	3+(2*l.y_acr)+4*year+eps_acr	if	year!=1	//	True model: y = b0 + b1*l.y + b2*year + eps_acr

*	year as trend
reg	y_acr	year
predict	resid_acr_tr, residual
xtreg	y_acr	year, fe


*	year as FE
reg	y_acr	i.year
predict	resid_acr_fe,	residual
xtreg	y_acr	i.year, fe


	
	*	year trend
	xtreg	resid_acr_tr	l.resid_acr_tr, fe
	xtreg	resid_acr_tr	l.resid_acr_tr, vce(cluster hhid) fe

	*	year fe
	xtreg	resid_acr_fe	l.resid_acr_fe, fe
	xtreg	resid_acr_fe	l.resid_acr_fe, vce(cluster hhid) fe


*	Reg with lagged
reg		y_acr	l.y_acr	year
predict	resid_lag_acr_tr, residual

reg		resid_lag_acr_tr	l.resid_lag_acr_tr
xtreg	resid_lag_acr_tr	l.resid_lag_acr_tr,fe
xtreg	resid_lag_acr_tr	l.resid_lag_acr_tr,vce(cluster hhid) fe