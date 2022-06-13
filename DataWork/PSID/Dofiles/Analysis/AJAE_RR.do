	
	local	seam_period=0
	local	RPP=1
	
	
	use	"${PSID_dtFin}/fs_const_long.dta", clear
	
	include	"${PSID_doAnl}/Macros_for_analyses.do"
	
	
	
	if	`seam_period==1'	{
	
	
		*	Food security transition status
		loc	var		FS_trans_status
		cap	drop	`var'
		gen		`var'=0	if	l1.PFS_FI_glm==0	&	PFS_FI_glm==0	//	FS in both periods
		replace	`var'=1	if	l1.PFS_FI_glm==1	&	PFS_FI_glm==0	//	(FI,FS)
		replace	`var'=2	if	l1.PFS_FI_glm==0	&	PFS_FI_glm==1	//	(FI,FS)
		replace	`var'=3	if	l1.PFS_FI_glm==1	&	PFS_FI_glm==1	//	(FI,FI)
		lab	define	`var'	0	"FS/FS"	1	"FI/FS"	2	"FS/FI"	3	"FI/FI"
		lab	val	`var'	`var'
		lab	var	`var'	"Food Security Transition"
		
		*	Replicate spells variable from the original analyses file
		{
			*	Tag balanced sample (Households without any missing PFS throughout the study period)
			*	Unbalanced households will be dropped from spell length analyses not to underestimate spell lengths
			capture	drop	num_nonmissing_PFS
			cap	drop	balanced_PFS
			bys fam_ID_1999: egen num_nonmissing_PFS=count(PFS_FI_glm)
			gen	balanced_PFS=1	if	num_nonmissing_PFS==9

			*	Summary stats of spell lengths among FI incidence
			*mat	summ_spell_length	=	J(9,2,.)	
			cap drop	_seq	_spell	_end
			tsspell, cond(year>=2 & PFS_FI_glm==1)
		
		}
		
		
		*	Seam period (# of months between survey)
		local	var	seam_period
		cap	drop	`var'
		gen	`var'	=	(interview_month - l1.interview_month)+24
		lab	var	`var'	"# of months between interview"
		
		*	Dummy for seam period b/w 24+=-3 months
		cap	drop	seam_21_27
		gen		seam_21_27=.
		replace	seam_21_27=0	if	!mi(`var')	&	!inrange(`var',21,27)
		replace	seam_21_27=1	if	!mi(`var')	&	inrange(`var',21,27)
		lab	var	seam_21_27	"=1 if surveyed between 21~27 months"
		
		*	Dummy for seam period<=24 months
		cap	drop	seam_24_less
		gen		seam_24_less=.
		replace	seam_24_less=0	if	!mi(`var')	&	!inrange(`var',1,24)
		replace	seam_24_less=1	if	!mi(`var')	&	inrange(`var',1,24)
		lab	var	seam_24_less	"=1 if surveyed within 24 months"
		
		*	Category for different seam periods
		loc	var		seam_period_cat
		cap	drop	`var'
		gen	`var'=.	if	mi(seam_period)
		replace	`var'=1	if	inrange(seam_period,1,20)
		replace	`var'=2	if	inrange(seam_period,21,24)
		replace	`var'=3	if	inrange(seam_period,25,27)
		replace	`var'=4	if	inrange(seam_period,27,36)
		lab	define	`var'	1	"<21 months"	2	"21-24 months"	3	"25-27 months"	4	">27 months"
		lab	val	`var'	`var'
		lab	var	`var'	"Seam period (categorical)"
		
		*svy, subpop(${study_sample}): tab `var'
		
		
		tempfile	temp
		save	`temp'
		
		br	fam_ID_1999	year	PFS_FI_glm	FS_trans_status	_seq	_spell	_end	seam*
		
		
		*	Analysis
		
			*	Uncontional distribution of seam period (unweighted)
			tab		seam_period	if ${study_sample}	//	All sample HH
			tab		seam_period	if ${study_sample}	&	_seq==1	&	f1._seq==0	//	Transiently FI households (single-period FI experience)
			summ	seam_21_27	seam_24_less	if ${study_sample}
			
			tab		seam_period_cat	PFS_FI_glm	//	joint distribution of seam period and FI status
			
			sort	fam_ID_1999	year
			summ	PFS_FI_glm	if	 ${study_sample}	&	_seq==1	&	f1._seq==0	&	seam_period_cat==1
			
			*	Conditional distribution of seam period
			tab	seam_period if ${study_sample}	&	_seq==1	//	_seq==1 condition restricts the sample to those who just entered FI
			tab	seam_period if ${study_sample}	&	_seq==1	&	f1._seq==0	//	"_seq==1	&	f1._seq==0"  restricts the sample to those who experienced 1 period of FI
			
			hist	seam_period if ${study_sample},	fraction	title(# of months between surveys)
			hist	seam_period if ${study_sample}	&	_seq==1	&	f1._seq==0,	fraction //	"_seq==1	&	f1._seq==0"  restricts the sample to those who experienced 1 period of FI
				
			twoway	(hist	seam_period if ${study_sample}, fraction color(red))	///
					(hist	seam_period if ${study_sample}	&	_seq==1	&	f1._seq==0, fraction color(blue)),	///
					legend(order(1	"All HH"	2	"Transient FI"))	title(# of months between survey rounds)
			graph	export	"E:\Box\2nd year paper\Draft\20220108_AJAE\R&R\dist_svy_months.png", as(png) replace
					
				
		
			*	Conditional distribution of FI, upon different seam periods
				*	Q. Among differents seam periods, what is the likelihood that we observe sepcific food security stransition status
				*	Why we need to see this? because we might observe different share of food security transition contional upon different seam periods.
				
				tab	PFS_FI_glm	if	 ${study_sample}	&	l1.PFS_FI_glm==1	&	seam_period_cat==1
				tab	PFS_FI_glm	if	 ${study_sample}	&	l1.PFS_FI_glm==1	&	seam_period_cat==2
				tab	PFS_FI_glm	if	 ${study_sample}	&	l1.PFS_FI_glm==1	&	seam_period_cat==3
				tab	PFS_FI_glm	if	 ${study_sample}	&	l1.PFS_FI_glm==1	&	seam_period_cat==4
				
				*	Regression FS status on seam period (for previously FI households)
				reg	PFS_FS_glm	seam_period	if	 ${study_sample}	&	l1.PFS_FI_glm==1
				svy, subpop(if	 ${study_sample}	&	l1.PFS_FI_glm==1):	reg	PFS_FS_glm	seam_period
				
				
			
				
				
			tab FS_trans_status	if	 ${study_sample}	&	seam_period_cat==1
			tab FS_trans_status	if	 ${study_sample}	&	seam_period_cat==2
			tab FS_trans_status	if	 ${study_sample}	&	seam_period_cat==3
			tab FS_trans_status	if	 ${study_sample}	&	seam_period_cat==4

					
			svy, subpop(if ${study_sample}	&	seam_24_less==0):	mean	PFS_FI_glm
			svy, subpop(if ${study_sample}	&	seam_24_less==1):	mean	PFS_FI_glm

		
		tab	PFS_FI_glm	if	${study_sample}	&	seam_24_less==0
		tab	PFS_FI_glm	if	${study_sample}	&	seam_24_less==1
	
	}
	
	
	if	`RPP==1'	{
		
	*	Replicate Table using both PFS and RPP-adjusted PFS
	*	Make sure to use only the sample which has both PFS and RPP-adj PFS, as the latter is available only in certain years
	
	*	Note that the code below is mainly copied from the original code. 
	*	Once we decide to make this code replicable later (ex. include in the Appendix), we can incorporate it into the main analyses do-file.
	
		*	Spell length (Table 1)
		
			{
			
			*	Original PFS
			capture	drop	num_nonmiss_PFS
			cap	drop	balanced_PFS
			bys fam_ID_1999: egen num_nonmiss_PFS=count(PFS_FI_glm)
			gen	balanced_PFS=1	if	num_nonmiss_PFS==9	//	9 waves total
			
			*	RPP-adjusted PFS
			capture	drop	num_nonmiss_PFS_RPPadj
			cap	drop	balanced_PFS_RPPadj
			bys fam_ID_1999: egen num_nonmiss_PFS_RPPadj=count(PFS_FI_glm_RPPadj)	
			gen	balanced_PFS_RPPadj=1	if	num_nonmiss_PFS_RPPadj==5	//	5 waves total
			
			*	Define subsample; households that have (1) balanced PFS across all study waaves (sample as main analysis)  (2)balanced RPP-adj PFS across study waves and (3) 2009-2017 (when both measures are available)
			cap	drop	balanced_PFSs_all	balanced_PFSs_0917
			gen	balanced_PFSs_all=1		if	balanced_PFS==1			&	balanced_PFS_RPPadj==1			//	All HH observations which has balanced PFS and RPP-adj PFS
			gen	balanced_PFSs_0917=1	if	balanced_PFSs_all==1	&	inrange(year2,2009,2017)		//	HH with balanced PFS and RPP-adj PFS, only from 2009 to 2017 
			
			*	Summary stats of spell lengths among FI incidence, using only balanced subsample defind above
			*mat	summ_spell_length	=	J(9,2,.)	
		
				*	PFS (default)
					cap drop	_seq	_spell	_end
					tsspell, cond(year>=6 & PFS_FI_glm==1)	//	Note that "year>=2" is replaced with "year>=6", to include only 2009-2017 with non-missing RPP-adjusted PFS
					svy, subpop(if	${study_sample} & _end==1 & balanced_PFSs_0917==1): mean _seq //	Mean of spell lengths (To get length as an year, multiply spell length by 2).
					svy, subpop(if	${study_sample}	& _end==1 & balanced_PFSs_0917==1): tab _seq //	Tabulation of spell lengths.
					*mat	summ_spell_length	=	e(N),	e(b)
					*mat temp=e(b)
					*mat list temp
					mat	summ_spell_length_PFS	=	e(b)[1..1,2..6]'

					*	Persistence rate conditional upon spell length
					mat	pers_upon_spell_PFS	=	J(5,2,.)	
					forvalues	i=1/4	{	//	counter "i" changed from 8 to 4.
						svy, subpop(if	l._seq==`i'	&	!mi(PFS_FS_glm) &	balanced_PFSs_0917==1): proportion PFS_FS_glm		//	Previously FI
						mat	pers_upon_spell_PFS[`i',1]	=	/*e(N),*/ e(b)[1,1], r(table)[2,1]	//	append the share of households that are NOT food secure (thus remain food insecure)
					}
				
				*	PFS (RPP-adjusted)
					cap drop	_seq	_spell	_end
					tsspell, cond(year>=6 & PFS_FI_glm_RPPadj==1)
					svy, subpop(if	${study_sample} & _end==1 & balanced_PFSs_0917==1): mean _seq //	Mean of spell lengths (To get length as an year, multiply spell length by 2).
					svy, subpop(if	${study_sample}	& _end==1 & balanced_PFSs_0917==1): tab _seq 	//	Tabulation of spell lengths.
					*mat	summ_spell_length	=	e(N),	e(b)
					mat	summ_spell_length_PFS_RPPadj	=	e(b)[1..1,2..6]'

					*	Persistence rate conditional upon spell length
					mat	pers_upon_spell_PFS_RPPadj	=	J(5,2,.)	
					forvalues	i=1/4	{		//	counter "i" changed from 8 to 4.
						svy, subpop(if	l._seq==`i'	&	!mi(PFS_FI_glm_RPPadj) &	balanced_PFSs_0917==1): proportion PFS_FS_glm_RPPadj		//	Previously FI
						mat	pers_upon_spell_PFS_RPPadj[`i',1]	=	/*e(N),*/ e(b)[1,1], r(table)[2,1]
					}
		
			*	Distribution of spell length and conditional persistent (Table 1 of AJAE draft)
			mat spell_dist_comb_RPP	=	summ_spell_length_PFS,	pers_upon_spell_PFS,	summ_spell_length_PFS_RPPadj,	pers_upon_spell_PFS_RPPadj
			mat	rownames	spell_dist_comb_RPP	=	2	4	6	8	10	//	12	14	16	18

			putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices", sheet(spell_dist_comb_RPP) modify	/*replace*/
			putexcel	A5	=	matrix(spell_dist_comb_RPP), names overwritefmt nformat(number_d1)
			
			esttab matrix(spell_dist_comb_RPP, fmt(%9.2f)) using "${PSID_outRaw}/Spell_dist_combined_RPP.tex", replace	

			drop	_seq _spell _end
			
			}
		
		*	Transition matrix (Table 2 - Year and region-only)
		
			{
			
			*	Preamble
			mat drop _all
			cap	drop	??_PFS_FS_glm			??_PFS_FI_glm			??_PFS_LFS_glm			??_PFS_VLFS_glm			??_PFS_cat_glm
			cap	drop	??_PFS_FS_glm_RPPadj	??_PFS_FI_glm_RPPadj	??_PFS_LFS_glm_RPPadj	??_PFS_VLFS_glm_RPPadj	??_PFS_cat_glm_RPPadj
			sort	fam_ID_1999	year
				
			*	Generate lagged FS dummy from PFS, as svy: command does not support factor variable so we can't use l.	
			forvalues	diff=1/9	{
				foreach	category	in	FS	FI	LFS	VLFS	cat	{
					if	`diff'!=9	{
						qui	gen	l`diff'_PFS_`category'_glm			=	l`diff'.PFS_`category'_glm	//	Lag
						qui	gen	l`diff'_PFS_`category'_glm_RPPadj	=	l`diff'.PFS_`category'_glm_RPPadj	//	Lag
					}
					qui	gen	f`diff'_PFS_`category'_glm			=	f`diff'.PFS_`category'_glm	//	Forward
					qui	gen	f`diff'_PFS_`category'_glm_RPPadj	=	f`diff'.PFS_`category'_glm_RPPadj	//	Forward
				}
			}
			
			*	Restrict sample to the observations with
				*	(1)	HH with balanced PFS over the study period (2001-2017)
				*	(2)	HH with balanced RPP-adjusted PFS over the years (2009-2017)
				*	(3) Values from 2011 to 2017 (where lagged PFS(RPP-adj) exists)
			*	Remember that "balanced_PFSs_all" and "balanced_PFSs_0917" variables are constructed for the condition (1) and (2)
		
			
			*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
				
				*	Year
				cap	mat	drop	trans_2by2_year	trans_change_year	trans_2by2_year_RPPadj	trans_change_year_RPPadj
				forvalues	year=7/10	{	//	use values only from 2011 to 2017

					*	Joint distribution	(two-way tabulate), PFS (default)
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017) & year_enum`year'): tabulate l1_PFS_FS_glm	PFS_FS_glm
					mat	trans_2by2_joint_`year' = 	e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`year'	=	e(N_sub)	//	Sample size
					
					*	Joint distribution (two-way tabulate), PFS (RPP-adj)
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017) & year_enum`year'): tabulate l1_PFS_FS_glm_RPPadj	PFS_FS_glm_RPPadj
					mat	trans_2by2_joint_`year'_RPPadj = 	e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`year'_RPPadj	=	e(N_sub)	//	Sample size
					
					*	Marginal distribution (for persistence and entry), PFS (default)
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017)	& year_enum`year'): proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
					scalar	persistence_`year'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 &	balanced_PFSs_all==1 &	inrange(year2,2011,2017)	& year_enum`year'): proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
					scalar	entry_`year'		=	e(b)[1,1]
					
					*	Marginal distribution (for persistence and entry), PFS (RPP-adj)
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017)	& year_enum`year'): proportion	PFS_FS_glm	if	l1_PFS_FS_glm_RPPadj==0	&	!mi(PFS_FS_glm_RPPadj)	//	Previously FI
					scalar	persistence_`year'_RPPadj	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 &	balanced_PFSs_all==1 &	inrange(year2,2011,2017)	& year_enum`year'): proportion	PFS_FS_glm	if	l1_PFS_FS_glm_RPPadj==1	&	!mi(PFS_FS_glm_RPPadj)	//	Previously FS
					scalar	entry_`year'_RPPadj		=	e(b)[1,1]
					
					mat	trans_2by2_`year'	=	samplesize_`year',	trans_2by2_joint_`year',	persistence_`year',	entry_`year'	
					mat	trans_2by2_`year'_RPPadj	=	samplesize_`year'_RPPadj,	trans_2by2_joint_`year'_RPPadj,	persistence_`year'_RPPadj,	entry_`year'_RPPadj	
					
					mat	trans_2by2_year	=	nullmat(trans_2by2_year)	\	trans_2by2_`year'
					mat	trans_2by2_year_RPPadj	=	nullmat(trans_2by2_year_RPPadj)	\	trans_2by2_`year'_RPPadj
				
				}	//	year
				
				*	Region (based on John's suggestion)
				cap	mat	drop	trans_2by2_region	trans_2by2_region_RPP
				foreach	type	in	NE MidAt South MidWest	West	{
				
					*	Joint (PFS default)
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017) & state_group_`type'==1): tabulate l1_PFS_FS_glm	PFS_FS_glm	
					mat	trans_2by2_joint_`type' =	e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Joint (RPP adj PFS)
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017) & state_group_`type'==1): tabulate l1_PFS_FS_glm_RPPadj	PFS_FS_glm_RPPadj
					mat	trans_2by2_joint_`type'_RPPadj =	e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'_RPPadj	=	e(N_sub)	//	Sample size
					
					*	Marginal (PFS default)
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017) & state_group_`type'==1):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017) & state_group_`type'==1):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
					scalar	entry_`type'		=	e(b)[1,1]
					
					*	Marginal (RPP adj PFS)
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017) & state_group_`type'==1):qui proportion	PFS_FS_glm_RPPadj	if	l1_PFS_FS_glm_RPPadj==0	&	!mi(PFS_FS_glm_RPPadj)	//	Previously FI
					scalar	persistence_`type'_RPPadj	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017) & state_group_`type'==1):qui proportion	PFS_FS_glm_RPPadj	if	l1_PFS_FS_glm_RPPadj==1	&	!mi(PFS_FS_glm_RPPadj)	//	Previously FS
					scalar	entry_`type'_RPPadj			=	e(b)[1,1]
					
					mat	trans_2by2_`type'			=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
					mat	trans_2by2_`type'_RPPadj	=	samplesize_`type'_RPPadj,	trans_2by2_joint_`type'_RPPadj,	persistence_`type'_RPPadj,	entry_`type'_RPPadj
				}
				
				mat	trans_2by2_region	=	trans_2by2_NE	\	trans_2by2_MidAt	\	trans_2by2_South	\	trans_2by2_MidWest	\		trans_2by2_West
				mat	trans_2by2_region_RPPadj	=	trans_2by2_NE_RPPadj	\	trans_2by2_MidAt_RPPadj	\	trans_2by2_South_RPPadj	\	trans_2by2_MidWest_RPPadj	\		trans_2by2_West_RPPadj
			
				*	Check regional-level RPP, to see why we see some meaningful differences in regional-level transition
								
				tempfile	temp
				save	`temp'
				
					use	"${PSID_dtInt}/RPP_2008_2020.dta", clear
					merge	1:m	year2	state_str	resid_metro	resid_nonmetro using	`temp', keep(1 3) keepusing(state_group_*)
					
					*	Avg RPP by regional group. We see RPP is higher in NE(106.7) and MidAt(104.0) and lower in South (93.1) and Midwest (93.0)
					summ	RPP	if	inrange(year2,2009,2017)	&	state_group_NE==1	
					summ	RPP	if	inrange(year2,2009,2017)	&	state_group_MidAt==1	
					summ	RPP	if	inrange(year2,2009,2017)	&	state_group_South==1	
					summ	RPP	if	inrange(year2,2009,2017)	&	state_group_MidWest==1	
					summ	RPP	if	inrange(year2,2009,2017)	&	state_group_West==1	
					
				use	`temp', clear
			
				putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices", sheet(trans_RPPadj) modify	/*replace*/
				putexcel	A5	=	matrix(trans_2by2_year), names overwritefmt nformat(number_d1)
				putexcel	A15	=	matrix(trans_2by2_year_RPPadj), names overwritefmt nformat(number_d1)
				putexcel	A25	=	matrix(trans_2by2_region), names overwritefmt nformat(number_d1)
				putexcel	A35	=	matrix(trans_2by2_region_RPPadj), names overwritefmt nformat(number_d1)
				
			}
		
		
		*	Table 3 (Permanent approach) - Total and Region only
		
		if	`run_perm_approach'==1	{
		
		local	test_stationary=0
		
		*	Before we conduct permanent approach, we need to test whether PFS is stationary.
		**	We reject the null hypothesis that all panels have unit roots.
		if	`test_stationary'==1	{
			xtunitroot fisher	PFS_glm if ${study_sample}==1 ,	dfuller lags(0)	//	no-trend
		}
		
		*cap	drop	pfs_glm_normal
		cap	drop	SFIG
		cap	drop	PFS_glm_mean
		*cap	drop	PFS_glm_total
		*cap	drop	PFS_threshold_glm_total
		cap	drop	PFS_glm_mean_normal
		cap	drop	PFS_threshold_glm_mean
		cap	drop	PFS_glm_normal_mean
		cap	drop	SFIG_mean_indiv
		cap	drop	SFIG_mean
		cap	drop	SFIG_transient
		cap	drop	SFIG_deviation
		cap	drop	Total_FI
		cap	drop	Total_FI_HCR
		cap	drop	Total_FI_SFIG
		cap	drop	Transient_FI
		cap	drop	Transient_FI_HCR
		cap	drop	Transient_FI_SFIG
		cap	drop	Chronic_FI
		cap	drop	Chronic_FI_HCR
		cap	drop	Chronic_FI_SFIG
		*gen pfs_glm_normal	=.
		
		*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at household-level.
		*	Since households have different number of non-missing PFS and our cut-off probability varies over time, we cannot simply use "mean" function.
		*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
		
		*	Aggregate PFS over time (numerator)
		cap	drop	PFS_glm_total	PFS_glm_total_RPPadj
		bys	fam_ID_1999:	egen	PFS_glm_total			=	total(PFS_glm)			if	inrange(year,6,10)
		bys	fam_ID_1999:	egen	PFS_glm_total_RPPadj	=	total(PFS_glm_RPPadj)	if	inrange(year,6,10)
		
		*	Aggregate cut-off PFS over time. To add only the years with non-missing PFS, we replace the cut-off PFS of missing PFS years as missing.
		cap	drop	PFS_threshold_glm_total	PFS_threshold_glm_total_RPPadj
		replace	PFS_threshold_glm=.			if	mi(PFS_glm)
		replace	PFS_threshold_glm_RPPadj=.	if	mi(PFS_glm_RPPadj)
		bys	fam_ID_1999:	egen	PFS_threshold_glm_total			=	total(PFS_threshold_glm)		if	inrange(year,6,10)
		bys	fam_ID_1999:	egen	PFS_threshold_glm_total_RPPadj	=	total(PFS_threshold_glm_RPPadj)	if	inrange(year,6,10)
		
		*	Generate (normalized) mean-PFS by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
		gen	PFS_glm_mean_normal			=	PFS_glm_total			/	PFS_threshold_glm_total
		gen	PFS_glm_mean_normal_RPPadj	=	PFS_glm_total_RPPadj	/	PFS_threshold_glm_total_RPPadj
		
		*	Construct FIG and SFIG
		cap	drop	FIG_indiv
		cap	drop	SFIG_indiv
		cap	drop	FIG_indiv_RPPadj
		cap	drop	SFIG_indiv_RPPadj
		gen	FIG_indiv	=.
		gen	SFIG_indiv	=.
		gen	FIG_indiv_RPPadj	=.
		gen	SFIG_indiv_RPPadj	=.
				
			
			cap	drop	pfs_glm_normal
			cap	drop	pfs_glm_normal_RPPadj
			gen pfs_glm_normal			=.
			gen pfs_glm_normal_RPPadj	=.
				
				
			*	Normalized PFS (PFS/threshold PFS)	(PFSit/PFS_underbar_t)
			replace	pfs_glm_normal			=	PFS_glm			/	PFS_threshold_glm
			replace	pfs_glm_normal_RPPadj	=	PFS_glm_RPPadj	/	PFS_threshold_glm_RPPadj
			
			*	Inner term of the food securit gap (FIG) and the squared food insecurity gap (SFIG)
			replace	FIG_indiv	=	(1-pfs_glm_normal)^1	if	!mi(pfs_glm_normal)	&	pfs_glm_normal<1	//	PFS_glm<PFS_threshold_glm
			replace	FIG_indiv	=	0						if	!mi(pfs_glm_normal)	&	pfs_glm_normal>=1	//	PFS_glm>=PFS_threshold_glm
			replace	SFIG_indiv	=	(1-pfs_glm_normal)^2	if	!mi(pfs_glm_normal)	&	pfs_glm_normal<1	//	PFS_glm<PFS_threshold_glm
			replace	SFIG_indiv	=	0						if	!mi(pfs_glm_normal)	&	pfs_glm_normal>=1	//	PFS_glm>=PFS_threshold_glm
			
			replace	FIG_indiv_RPPadj	=	(1-pfs_glm_normal_RPPadj)^1	if	!mi(pfs_glm_normal_RPPadj)	&	pfs_glm_normal_RPPadj<1	//	PFS_glm<PFS_threshold_glm
			replace	FIG_indiv_RPPadj	=	0							if	!mi(pfs_glm_normal_RPPadj)	&	pfs_glm_normal_RPPadj>=1	//	PFS_glm>=PFS_threshold_glm
			replace	SFIG_indiv_RPPadj	=	(1-pfs_glm_normal_RPPadj)^2	if	!mi(pfs_glm_normal_RPPadj)	&	pfs_glm_normal_RPPadj<1	//	PFS_glm<PFS_threshold_glm
			replace	SFIG_indiv_RPPadj	=	0							if	!mi(pfs_glm_normal_RPPadj)	&	pfs_glm_normal_RPPadj>=1	//	PFS_glm>=PFS_threshold_glm
		
			
		*	Total, Transient and Chronic FI

		
			*	Total FI	(Average SFIG over time)
			bys	fam_ID_1999:	egen	Total_FI_HCR	=	mean(PFS_FI_glm)	if	inrange(year,6,10)	//	HCR
			bys	fam_ID_1999:	egen	Total_FI_SFIG	=	mean(SFIG_indiv)	if	inrange(year,6,10)	//	SFIG
			
			bys	fam_ID_1999:	egen	Total_FI_HCR_RPPadj		=	mean(PFS_FI_glm_RPPadj)	if	inrange(year,6,10)	//	HCR
			bys	fam_ID_1999:	egen	Total_FI_SFIG_RPPadj	=	mean(SFIG_indiv_RPPadj)	if	inrange(year,6,10)	//	SFIG
			
			label	var	Total_FI_HCR	"TFI (HCR)"
			label	var	Total_FI_SFIG	"TFI (SFIG)"
			label	var	Total_FI_HCR_RPPadj		"TFI (HCR) - RPPadj"
			label	var	Total_FI_SFIG_RPPadj	"TFI (SFIG) - RPPadj"

			*	Chronic FI (SFIG(with mean PFS))					
			gen		Chronic_FI_HCR=.
			gen		Chronic_FI_SFIG=.
			gen		Chronic_FI_HCR_RPPadj=.
			gen		Chronic_FI_SFIG_RPPadj=.
			
			replace	Chronic_FI_HCR	=	(1-PFS_glm_mean_normal)^0	if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal<1	//	Avg PFS < Avg cut-off PFS
			replace	Chronic_FI_SFIG	=	(1-PFS_glm_mean_normal)^2	if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal<1	//	Avg PFS < Avg cut-off PFS
			replace	Chronic_FI_HCR	=	0							if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
			replace	Chronic_FI_SFIG	=	0							if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
			
			replace	Chronic_FI_HCR_RPPadj	=	(1-PFS_glm_mean_normal_RPPadj)^0	if	!mi(PFS_glm_mean_normal_RPPadj)	&	PFS_glm_mean_normal_RPPadj<1	//	Avg PFS < Avg cut-off PFS
			replace	Chronic_FI_SFIG_RPPadj	=	(1-PFS_glm_mean_normal_RPPadj)^2	if	!mi(PFS_glm_mean_normal_RPPadj)	&	PFS_glm_mean_normal_RPPadj<1	//	Avg PFS < Avg cut-off PFS
			replace	Chronic_FI_HCR_RPPadj	=	0									if	!mi(PFS_glm_mean_normal_RPPadj)	&	PFS_glm_mean_normal_RPPadj>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
			replace	Chronic_FI_SFIG_RPPadj	=	0									if	!mi(PFS_glm_mean_normal_RPPadj)	&	PFS_glm_mean_normal_RPPadj>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
			
			lab	var		Chronic_FI_HCR	"CFI (HCR)"
			lab	var		Chronic_FI_SFIG	"CFI (SFIG)"
			lab	var		Chronic_FI_HCR_RPPadj	"CFI (HCR) - RPP adj"
			lab	var		Chronic_FI_SFIG_RPPadj	"CFI (SFIG) - RPP adj"
			
			**** In several households, CFI is greater than TFI. I assume it is because the threshold probability varies, but need to thoroughly check why.
			**** For now, in that case we treat CFI as equal to the TFI
			**** (2021/1/24) Chris said it is OK to have TFI<CFI. Below is his comments from the e-mail sent on Jan 24, 2021
			**** "That said, it’s fine to have CFI>TFI. That’s the very definition of a household that is chronically food insecure but occasionally food secure (i.e., chronically but not persistently food insecure). The poverty dynamics literature includes this as well, as it reflects the headcount basis for the average period-specific (total) food insecurity (TFI) versus the period-average food insecurity (CFI). "
			*replace	Chronic_FI_HCR	=	Total_FI	if	Chronic_FI>Total_FI
			
			*	Transient FI (TFI - CFI)
			gen	Transient_FI_HCR	=	Total_FI_HCR	-	Chronic_FI_HCR
			gen	Transient_FI_SFIG	=	Total_FI_SFIG	-	Chronic_FI_SFIG
			
			gen	Transient_FI_HCR_RPPadj		=	Total_FI_HCR_RPPadj		-	Chronic_FI_HCR_RPPadj
			gen	Transient_FI_SFIG_RPPadj	=	Total_FI_SFIG_RPPadj	-	Chronic_FI_SFIG_RPPadj
					


		*	Restrict sample to non_missing TFI and CFI, both PFS and RPP-adjusted PFS
		global	nonmissing_TFI_CFI	!mi(Total_FI_HCR)	&	!mi(Chronic_FI_HCR)	&	!mi(Total_FI_HCR_RPPadj)	&	!mi(Chronic_FI_HCR_RPPadj)
		
	
		*	Descriptive stats
			
			**	For now we include households with 5+ PFS.
			**	In this sub-analysis, PFS should be non-missing across all waves (2009,2011,2013,2015,2017)
			cap	drop	num_nonmiss_PFS
			cap	drop	num_nonmiss_PFS_RPPadj
			cap	drop	dyn_sample
			bys fam_ID_1999: egen num_nonmiss_PFS=count(PFS_glm)		if	inrange(year,6,10)
			bys fam_ID_1999: egen num_nonmiss_PFS_RPPadj=count(PFS_glm_RPPadj)	if	inrange(year,6,10)
			
			gen	dyn_sample=1	if	num_nonmiss_PFS>=5	&	inrange(year,6,10)
			
			br	fam_ID_1999	year	PFS_glm	PFS_glm_RPPadj	PFS_FI_glm	PFS_FI_glm_RPPadj	Total_FI_HCR	Chronic_FI_HCR	Total_FI_HCR_RPPadj	Chronic_FI_HCR_RPPadj	num_nonmiss_PFS	dyn_sample	if	${nonmissing_TFI_CFI}	&	inrange(year,6,10)
			
			*	For time-variance categories (ex. education, region), we use the first year (2009) value (as John suggested)
			local	timevar_cat	highdegree_NoHS highdegree_HS highdegree_somecol highdegree_col	///
								state_group_NE state_group_MidAt state_group_South state_group_MidWest state_group_West	resid_metro resid_nonmetro
			foreach	type	of	local	timevar_cat		{
				
				gen		`type'_temp	=	1	if	year==6	&	`type'==1
				replace	`type'_temp	=	0	if	year==6	&	`type'!=1	&	!mi(`type')
				replace	`type'_temp	=	.n	if	year==6	&	mi(`type')
				
				cap	drop	`type'_2009
				bys	fam_ID_1999:	egen	`type'_2009	=	max(`type'_temp)
				drop	`type'_temp
				
			}				
			
			*	If 2009 education is missing, use the earliest available education information
			cap	drop	tempyear
			bys fam_ID_1999: egen tempyear = min(year) if (${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1 & mi(highdegree_NoHS_2009))

			foreach edu in NoHS HS somecol col	{
				
				cap	drop	highdegree_`edu'_2009_temp?
				gen	highdegree_`edu'_2009_temp1	=	highdegree_`edu'	if	year==tempyear
				bys fam_ID_1999: egen highdegree_`edu'_2009_temp2	=	max(highdegree_`edu'_2009_temp1) if !mi(tempyear)
				replace	highdegree_`edu'_2009	=	highdegree_`edu'_2009_temp2	if	!mi(tempyear)
				drop	highdegree_`edu'_2009_temp?
			}
			drop	tempyear
			
		
			*	Generate statistics for tables
			local	exceloption	replace
			foreach	measure	in	HCR	SFIG	{
			
				*	Overall			
					
					*	PFS (default)
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	& ${nonmissing_TFI_CFI} 	&	dyn_sample==1 ):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_all	=	e(b)[1,2]/e(b)[1,1]
					*scalar	samplesize_all	=	e(N_sub)
					mat	perm_stat_2000_all	=	e(N_sub),	e(b), prop_trans_all
				
					*	PFS (RPP-adj)
					svy, subpop(if ${study_sample} &	!mi(PFS_glm_RPPadj)	& ${nonmissing_TFI_CFI} 	&	dyn_sample==1 ):	///
						mean Total_FI_`measure'_RPPadj Chronic_FI_`measure'_RPPadj Transient_FI_`measure'_RPPadj	
					scalar	prop_trans_all_RPPadj	=	e(b)[1,2]/e(b)[1,1]
					*scalar	samplesize_all	=	e(N_sub)
					mat	perm_stat_2000_all_RPPadj	=	e(N_sub),	e(b), prop_trans_all_RPPadj
				
			
				*	Region (based on John's suggestion)
									
					foreach	type	in	NE	MidAt South MidWest West	{
						
						*	PFS (default)
						svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	state_group_`type'==1	):	///
							mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
						scalar	prop_trans_region_`type'	=	e(b)[1,2]/e(b)[1,1]
						mat	perm_stat_2000_region_`type'	=	e(N_sub),	e(b), prop_trans_region_`type'
						
						
						*	PFS (RPP-adjusted)
						svy, subpop(if ${study_sample} &	!mi(PFS_glm_RPPadj)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	state_group_`type'==1	):	///
							mean Total_FI_`measure'_RPPadj Chronic_FI_`measure'_RPPadj Transient_FI_`measure'_RPPadj	
						scalar	prop_trans_`type'_RPPadj	=	e(b)[1,2]/e(b)[1,1]
						mat	perm_stat_2000_`type'_RPPadj	=	e(N_sub),	e(b), prop_trans_`type'_RPPadj
						
						
					}
			
			
			
					mat	perm_stat_2000_region	=	perm_stat_2000_region_NE	\	perm_stat_2000_region_MidAt	\	perm_stat_2000_region_South	\	///
													perm_stat_2000_region_MidWest	\	perm_stat_2000_region_West
													
					mat	perm_stat_2000_region_RPPadj	=	perm_stat_2000_NE_RPPadj	\	perm_stat_2000_MidAt_RPPadj	\	perm_stat_2000_South_RPPadj	\	///
															perm_stat_2000_MidWest_RPPadj	\	perm_stat_2000_West_RPPadj	
				
				
				*	Metropolitan Area
				foreach	type	in	metro	nonmetro	{
					
					
					*	PFS
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	resid_`type'==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_metro_`type'	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_metro_`type'	=	e(N_sub),	e(b), prop_trans_metro_`type'
					
					*	PFS (RPP-adj)
					svy, subpop(if ${study_sample} &	!mi(PFS_glm_RPPadj)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	resid_`type'==1):	///
						mean Total_FI_`measure'_RPPadj Chronic_FI_`measure'_RPPadj Transient_FI_`measure'_RPPadj	
					scalar	prop_trans_`type'_RPPadj	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_`type'_RPPadj	=	e(N_sub),	e(b), prop_trans_`type'_RPPadj
					
				}
			
				mat	perm_stat_2000_metro	=	perm_stat_2000_metro_metro	\	perm_stat_2000_metro_nonmetro
				mat	perm_stat_2000_metro_RPPadj	=	perm_stat_2000_metro_RPPadj	\	perm_stat_2000_nonmetro_RPPadj
				
				
				*	Combine results (Table 6)
				mat	define	blankrow	=	J(1,5,.)
				mat	perm_stat_allcat_`measure'	=	perm_stat_2000_all	\	blankrow	\		///
														perm_stat_2000_region	\	blankrow	\	perm_stat_2000_metro
				mat	perm_stat_allcat_`measure'_RPPadj	=	perm_stat_2000_all_RPPadj	\	blankrow	\		///
														perm_stat_2000_region_RPPadj	\	blankrow	\	perm_stat_2000_metro_RPPadj

				putexcel	set "${PSID_outRaw}/perm_stat", sheet(perm_stat_`measure'_RPPadj) `exceloption'
				putexcel	A3	=	matrix(perm_stat_allcat_`measure'), names overwritefmt nformat(number_d1)
				putexcel	A23	=	matrix(perm_stat_allcat_`measure'_RPPadj), names overwritefmt nformat(number_d1)
				
				esttab matrix(perm_stat_allcat_`measure'_RPPadj, fmt(%9.3f)) using "${PSID_outRaw}/Tab_6_perm_stat_`measure'_RPPadj.tex", replace	
				
				local	exceloption	modify
			}	//	measure
			
					
			
			
			*	Categorize HH into four categories
			*	First, generate dummy whether (1) always or not-always FI (2) Never or sometimes FI
				
				*	PFS
				loc	var1	PFS_FI_always_glm
				loc	var2	PFS_FI_never_glm
				cap	drop	`var1'
				cap	drop	`var2'
				bys	fam_ID_1999:	egen	`var1'	=	min(PFS_FI_glm)	if	inrange(year,6,10)	//	1 if always FI (persistently poor), 0 if sometimes FS (not persistently poor)
				bys	fam_ID_1999:	egen	`var2'	=	min(PFS_FS_glm)	if	inrange(year,6,10)	//	1 if never FI, 0 if sometimes FI (transient)
				replace	`var1'=.	if	inrange(year,1,5)
				replace	`var2'=.	if	inrange(year,1,5)
				
				*	PFS (RPP-adj)
				loc	var1	PFS_FI_always_glm_RPPadj
				loc	var2	PFS_FI_never_glm_RPPadj
				cap	drop	`var1'
				cap	drop	`var2'
				bys	fam_ID_1999:	egen	`var1'	=	min(PFS_FI_glm_RPPadj)	if	inrange(year,6,10)	//	1 if always FI (persistently poor), 0 if sometimes FS (not persistently poor)
				bys	fam_ID_1999:	egen	`var2'	=	min(PFS_FS_glm_RPPadj)	if	inrange(year,6,10)	//	1 if never FI, 0 if sometimes FI (transient)
				replace	`var1'=.	if	inrange(year,1,5)
				replace	`var2'=.	if	inrange(year,1,5)
			
			local	exceloption	modify
			foreach	measure	in	HCR	SFIG	{
				
				
				assert	Total_FI_`measure'==0 		if PFS_FI_never_glm==1		//	Make sure TFI=0 when HH is always FS (PFS>cut-off PFS)
				assert	Total_FI_`measure'_RPPadj==0 if PFS_FI_never_glm_RPPadj==1	//	Make sure TFI=0 when HH is always FS (PFS>cut-off PFS)
				
				*	Categorize households
					
					*	PFS
					cap	drop	PFS_perm_FI_`measure'
					gen		PFS_perm_FI_`measure'=1	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_always_glm==1	///
						//	Persistently FI (CFI>0, always FI)
					replace	PFS_perm_FI_`measure'=2	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_always_glm==0	///
						//	Chronically but not persistently FI (CFI>0, not always FI)
					replace	PFS_perm_FI_`measure'=3	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	PFS_FI_never_glm==0		///
						//	Transiently FI (CFI=0, not always FS)
					replace	PFS_perm_FI_`measure'=4	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	Total_FI_`measure'==0	///
						//	Always FS (CFI=TFI=0)
						
					*	PFS (RPP-adjusted)
					cap	drop	PFS_perm_FI_`measure'_RPPadj
					gen		PFS_perm_FI_`measure'_RPPadj=1	if	Chronic_FI_`measure'_RPPadj>0	&	!mi(Chronic_FI_`measure'_RPPadj)	&	PFS_FI_always_glm_RPPadj==1	///
						//	Persistently FI (CFI>0, always FI)
					replace	PFS_perm_FI_`measure'_RPPadj=2	if	Chronic_FI_`measure'_RPPadj>0	&	!mi(Chronic_FI_`measure'_RPPadj)	&	PFS_FI_always_glm_RPPadj==0	///
						//	Chronically but not persistently FI (CFI>0, not always FI)
					replace	PFS_perm_FI_`measure'_RPPadj=3	if	Chronic_FI_`measure'_RPPadj==0	&	!mi(Chronic_FI_`measure'_RPPadj)	&	PFS_FI_never_glm_RPPadj==0		///
						//	Transiently FI (CFI=0, not always FS)
					replace	PFS_perm_FI_`measure'_RPPadj=4	if	Chronic_FI_`measure'_RPPadj==0	&	!mi(Chronic_FI_`measure'_RPPadj)	&	Total_FI_`measure'_RPPadj==0	///
						//	Always FS (CFI=TFI=0)
					
				label	define	PFS_perm_FI	1	"Persistently FI"	///
											2	"Chronically, but not persistently FI"	///
											3	"Transiently FI"	///
											4	"Never FI"	///
											,	replace
			
				label values	PFS_perm_FI_`measure'	PFS_perm_FI_`measure'_RPPadj
			
			
			
			*	A quick check
			/*
			br	fam_ID_1999	year	PFS_glm	PFS_glm_RPPadj	PFS_FI_glm	PFS_FS_glm	PFS_FI_glm_RPPadj	PFS_FS_glm_RPPadj	Chronic_FI_HCR	PFS_perm_FI_HCR	PFS_perm_FI_HCR_RPPadj
			local	type	NE
			local	measure	HCR
					
			unique	fam_ID_1999	if	${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1
			
			br	fam_ID_1999	year	state_resid_fam	state_group_`type'	dyn_sample	PFS_glm	PFS_glm_RPPadj	PFS_FI_glm	PFS_FI_glm_RPPadj	PFS_FI_always_glm	PFS_FI_always_glm_RPPadj	///
				if	${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1
				
			br	fam_ID_1999	year	state_resid_fam	state_group_`type'	dyn_sample	PFS_glm	PFS_glm_RPPadj	PFS_FI_glm	PFS_FI_glm_RPPadj	PFS_FI_always_glm	PFS_FI_always_glm_RPPadj	///
				if	fam_ID_1999==72
			*/		
			
			*	Descriptive stats
			
				*	Overall
					
					*	PFS
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): proportion	PFS_perm_FI_`measure'
					mat	PFS_perm_FI_all	=	e(N_sub),	e(b)
					
					*	PFS (RPP-adjusted)
					svy, subpop(if ${study_sample} &	!mi(PFS_glm_RPPadj)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): proportion	PFS_perm_FI_`measure'_RPPadj
					mat	PFS_perm_FI_all_RPPadj	=	e(N_sub),	e(b)
							
				
				*	Region
				foreach	type	in	NE	MidAt	South	MidWest West	{
					
					*	PFS
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_region_`type'	=	e(N_sub),	e(b)
					
					*	PFS (RPP-adjusted)
					svy, subpop(if ${study_sample} &	!mi(PFS_glm_RPPadj)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1):	///
						proportion PFS_perm_FI_`measure'_RPPadj
					mat	PFS_perm_FI_`type'_RPPadj	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_region	=	PFS_perm_FI_region_NE	\	PFS_perm_FI_region_MidAt	\	PFS_perm_FI_region_South	\	///
											PFS_perm_FI_region_MidWest	\	PFS_perm_FI_region_West
											
				mat	PFS_perm_FI_region_RPPadj	=	PFS_perm_FI_NE_RPPadj	\	PFS_perm_FI_MidAt_RPPadj	\	PFS_perm_FI_South_RPPadj	\	///
													PFS_perm_FI_MidWest_RPPadj	\	PFS_perm_FI_West_RPPadj
				
				*	Metropolitan
				foreach	type	in	metro	nonmetro	{
					
					*	PFS
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	resid_`type'==1):	///
						proportion PFS_perm_FI_`measure'
					mat	PFS_perm_FI_metro_`type'	=	e(N_sub),	e(b)
					
					*	PFS (RPP-adj)
					svy, subpop(if ${study_sample} &	!mi(PFS_glm_RPPadj)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	resid_`type'==1):	///
						proportion PFS_perm_FI_`measure'_RPPadj
					mat	PFS_perm_FI_`type'_RPPadj	=	e(N_sub),	e(b)
					
				}
				
				mat	PFS_perm_FI_metro			=	PFS_perm_FI_metro_metro	\	PFS_perm_FI_metro_nonmetro
				mat	PFS_perm_FI_metro_RPPadj	=	PFS_perm_FI_metro_RPPadj	\	PFS_perm_FI_nonmetro_RPPadj
				

				*	Combine results (Table 9 of 2020/11/16 draft)
				mat	define	blankrow	=	J(1,5,.)
				mat	PFS_perm_FI_combined_`measure'	=	PFS_perm_FI_all	\	blankrow	\	///
														PFS_perm_FI_region	\	blankrow	\	PFS_perm_FI_metro
				mat	PFS_perm_FI_combined_`measure'_RPPadj	=	PFS_perm_FI_all_RPPadj	\	blankrow	\	///
																PFS_perm_FI_region_RPPadj	\	blankrow	\	PFS_perm_FI_metro_RPPadj	
				
				mat	list	PFS_perm_FI_combined_`measure'
				mat	list	PFS_perm_FI_combined_`measure'_RPPadj
				
				di "excel option is `exceloption'"
				putexcel	set "${PSID_outRaw}/perm_stat", sheet(FI_perm_`measure'_RPPadj) `exceloption'
				putexcel	A3	=	matrix(PFS_perm_FI_combined_`measure'), names overwritefmt nformat(number_d1)
				putexcel	A23	=	matrix(PFS_perm_FI_combined_`measure'_RPPadj), names overwritefmt nformat(number_d1)
			
				*esttab matrix(PFS_perm_FI_combined_`measure', fmt(%9.2f)) using "${PSID_outRaw}/PFS_perm_FI_`measure'.tex", replace	
				
				*	Table 5 & 6 (combined) of Dec 20 draft
				mat	define Table_5_`measure'		=	perm_stat_2000_allcat_`measure',	PFS_perm_FI_combined_`measure'[.,2...]
				mat	define Table_5_`measure'_RPPadj	=	perm_stat_allcat_`measure'_RPPadj,	PFS_perm_FI_combined_`measure'_RPPadj[.,2...]
				
				putexcel	set "${PSID_outRaw}/perm_stat", sheet(Table5_`measure'_RPPadj) `exceloption'
				putexcel	A3	=	matrix(Table_5_`measure'), names overwritefmt nformat(number_d1)
				putexcel	A23	=	matrix(Table_5_`measure'_RPPadj), names overwritefmt nformat(number_d1)
			
				*esttab matrix(Table_5_`measure', fmt(%9.3f)) using "${PSID_outRaw}/Tab_6_`measure'.tex", replace
				
				local	exceloption	modify
				
			}	//	measure
		
		*	Group State-FE of TFI and CFI		
			*	Regression of TFI/CFI on Group state FE
			
			local measure HCR
			
			foreach	depvar	in	Total_FI_`measure'	Chronic_FI_`measure'	Total_FI_`measure'_RPPadj	Chronic_FI_`measure'_RPPadj		{
				
				
				*	With controls/time FE
				qui	svy, subpop(if ${study_sample} &	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' ${regionvars}	///
					${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	year_enum7-year_enum10
				est	store	`depvar'
				
				
			}
			
			*	Output
					
			esttab	Total_FI_`measure'	Chronic_FI_`measure'	Total_FI_`measure'_RPPadj	Chronic_FI_`measure'_RPPadj		using "${PSID_outRaw}/TFI_CFI_regression_RPPadj.csv", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
					title(Regression of TFI/CFI on Characteristics) 	///
					addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
					replace		
			
			
			local	shapley_decomposition=1
			*	Shapley Decomposition
			if	`shapley_decomposition'==1	{
				
				ds	state_group?	state_group1?	state_group2?
				local groupstates `r(varlist)'		
				
				foreach	depvar	in	Total_FI_`measure'	Chronic_FI_`measure'	Total_FI_`measure'_RPPadj	Chronic_FI_`measure'_RPPadj	{
					
					*	Unadjusted
					cap	drop	_mysample
					regress `depvar' 	${demovars}		${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	///
									${foodvars}		${changevars}	 ${regionvars}	year_enum7-year_enum10	///
									if ${study_sample} &	 ${nonmissing_TFI_CFI} 	& dyn_sample==1
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head	mental_problem no_longer_employed	no_longer_married	no_longer_own_house	became_disabled) 
					
					mat	`depvar'_shapind	=	e(shapley),	e(shapley_rel)
					mata : st_matrix("`depvar'_shapsum", colsum(st_matrix("`depvar'_shapind")))
					
					mat	`depvar'_shapley	=	`depvar'_shapind	\	`depvar'_shapsum
					
					
					*	Survey-adjusted (not used since it cannot be decomposed. Check the comment below)
					/*
					cap	drop	_mysample
					svy, subpop(if ${study_sample} &	!mi(PFS_glm)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1):	///
						regress `depvar'  	${demovars}		${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	///
								${foodvars}		${changevars}	 ${regionvars}	year_enum7-year_enum10
					shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head	mental_problem no_longer_employed	no_longer_married	no_longer_own_house	became_disabled)
					*/
					
					*	For some reason, Shapely decomposition does not work properly under the adjusted regression model (they don't sum up to 100%)
					*mat	`depvar'_shapley_indiv	=	e(shapley),	e(shapley_rel)
					*mata : st_matrix("`depvar'_shapley_sum", colsum(st_matrix("`depvar'_shapley_indiv")))
					
					*mat	`depvar'_shapley	=	`depvar'_shapley_indiv	\	`depvar'_shapley_sum
				
				}	//	depvar			
			}	//	shapley
					
			mat	TFI_CFI_`measure'_shapley		=	Total_FI_`measure'_shapley,	Chronic_FI_`measure'_shapley
			mat	TFI_CFI_`measure'_shap_RPPadj	=	Total_FI_`measure'_RPPadj_shapley,	Chronic_FI_`measure'_RPPadj_shapley
				
			putexcel	set "${PSID_outRaw}/perm_stat", sheet(shapley) /*replace*/	modify
			putexcel	A3	=	matrix(TFI_CFI_`measure'_shapley), names overwritefmt nformat(number_d1)
			putexcel	H3	=	matrix(TFI_CFI_`measure'_shap_RPPadj), names overwritefmt nformat(number_d1)
			
			*esttab matrix(TFI_CFI_`measure'_shapley, fmt(%9.3f)) using "${PSID_outRaw}/Tab_7_TFI_CFI_`measure'_shapley.tex", replace	
		
				
		local	measure HCR
		
		coefplot	Total_FI_`measure'	Total_FI_`measure'_RPPadj, 	///
					keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)	///
					xline(0)	graphregion(color(white)) bgcolor(white)	legend(lab (2 "TFI") lab(4 "TFI (RPP-adjusted)") 	rows(1))	name(TFI_FE_All, replace)	ylabel(,labsize(small))	/*xscale(range(-0.05(0.05) 0.10))*/
		graph	export	"${PSID_outRaw}/Fig_6_TFI_`measure'_groupstateFE_All_RPP.png", replace
		graph	close
		
		coefplot	Chronic_FI_`measure'	Chronic_FI_`measure'_RPPadj, 	///
					keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)	///
					xline(0)	graphregion(color(white)) bgcolor(white)	legend(lab (2 "CFI") lab(4 "CFI (RPP-adjusted)") 	rows(1))	name(TFI_CFI_FE_All, replace)	ylabel(,labsize(small))	/*xscale(range(-0.05(0.05) 0.10))*/
		graph	export	"${PSID_outRaw}/Fig_6_CFI_`measure'_groupstateFE_All_RPP.png", replace
		graph	close
			
		*	Quick check the sequence of FS under HFSM
		cap	drop	HFSM_FS_always
		cap	drop	balanced_HFSM
		bys	fam_ID_1999:	egen	HFSM_FS_always	=	min(fs_cat_fam_simp)	//	1 if never food insecure (always food secure under HFSM), 0 if sometimes insecure 
		cap	drop	HFSM_FS_nonmissing
		bys	fam_ID_1999:	egen	HFSM_FS_nonmissing	=	count(fs_cat_fam_simp)	// We can see they all have value 5;	All households have balanded HFSM
										
		*	% of always food secure households under HFSM (this statistics is included after Table 6 (Chronic Food Security Status from Permanent Approach))
		svy, subpop(if ${study_sample}==1 & HFSM_FS_nonmissing==5): mean HFSM_FS_always
		
		
		capture	drop	num_nonmissing_HFSM
		cap	drop	HFSM_total_hf
		bys fam_ID_1999: egen num_nonmissing_HFSM=count(fs_cat_fam_simp)
		bys fam_ID_1999: egen HFSM_total_hf=total(fs_cat_fam_simp)
		
		svy, subpop(if ${study_sample}==1 &  num_nonmissing_HFSM==5): tab HFSM_total_hf
		
		
		
	}

	
		
	}
	
	