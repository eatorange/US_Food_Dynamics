use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam1999er.dta", clear

clonevar interviewno_1999=ER13002
tempfile fam1999
save	`fam1999'

use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\ind2017er.dta", clear
clonevar interviewno_1999=ER33501

tempfile ind2017
save	`ind2017'

use `fam1999', clear
loc fam	0
loc	ind	1

use `fam1999', clear
if	`fam'==1	{
	merge 1:m interviewno_1999 using `ind2017', assert(2 3) keep(3) keepusing(/*ER33546 ER33547*/ ER31996 ER31997) nogen
	duplicates drop

	egen fs_score = rowtotal (ER14331A-ER14331R)

	gen		fs_cat1 =	0	if	fs_score==0
	replace	fs_cat1	=	1	if	inrange(fs_score,1,2)
	replace	fs_cat1	=	2	if	(inrange(fs_score,3,7)	&	ER14331Y==1)	|	///
								(inrange(fs_score,3,5)	&	ER14331Y==0)
	replace	fs_cat1	=	3	if	(inrange(fs_score,8,18)	&	ER14331Y==1)	|	///
								(inrange(fs_score,6,10)	&	ER14331Y==0)

	gen		fs_cat2 =	0	if	fs_score==0
	replace	fs_cat2	=	1	if	inrange(fs_score,1,2)
	replace	fs_cat2	=	2	if	(inrange(fs_score,3,7)	&	inrange(ER13013,1,18))	|	///
								(inrange(fs_score,3,5)	&	ER13013==0)
	replace	fs_cat2	=	3	if	(inrange(fs_score,8,18)	&	inrange(ER13013,1,18))	|	///
								(inrange(fs_score,6,10)	&	ER13013==0)


	svyset	ER31997 [pweight=ER16518], strata(ER31996)
	svy: proportion ER14331U fs_cat1 fs_cat2

	svyset	ER31997 [pweight=ER16519], strata(ER31996)
	svy: proportion ER14331U fs_cat1 fs_cat2
}


if	`ind'==1	{
	merge 1:m interviewno_1999 using `ind2017', assert(2 3) keep(3) keepusing(ER33546 ER33547 ER31996 ER31997 ER33502) nogen
	keep	if	inrange(ER33502,1,89)
	
	svyset	ER31997 [pweight=ER33547], strata(ER31996)
	svy: proportion ER14331U
	
	svyset	ER31997 [pweight=ER33546], strata(ER31996)
	svy: proportion ER14331U
}