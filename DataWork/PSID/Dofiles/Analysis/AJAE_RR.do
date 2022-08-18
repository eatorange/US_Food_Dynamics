	
	local	seam_period=0
	local	RPP=1
	local	HFSM_dynamics=0	//	Replicate spells analysis using HFSM
	local	GLM_dist=0
	
	use	"${PSID_dtFin}/fs_const_long.dta", clear
	
	include	"${PSID_doAnl}/Macros_for_analyses.do"
	
	*	In 2003 (year 3), 11.2% are food insecure
	*	However, there's huge gap between 
	
	tab	fs_cat_IS if year==3
	
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
	
	use	"${PSID_dtFin}/fs_const_long.dta", clear
	
	include	"${PSID_doAnl}/Macros_for_analyses.do"
	
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
			
			sort fam_ID_1999 year	//	Need for conditional persistence
		
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
				svy, subpop(if	l._seq==1	&	!mi(PFS_FS_glm) &	balanced_PFSs_0917==1): proportion PFS_FS_glm		//	Previously FI
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
					svy, subpop(if ${study_sample}==1 & balanced_PFSs_all==1 &	inrange(year2,2011,2017)	& year_enum`year'): proportion	PFS_FS_glm_RPPadj	if	l1_PFS_FS_glm_RPPadj==0	&	!mi(PFS_FS_glm_RPPadj)	//	Previously FI
					scalar	persistence_`year'_RPPadj	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 &	balanced_PFSs_all==1 &	inrange(year2,2011,2017)	& year_enum`year'): proportion	PFS_FS_glm_RPPadj	if	l1_PFS_FS_glm_RPPadj==1	&	!mi(PFS_FS_glm_RPPadj)	//	Previously FS
					scalar	entry_`year'_RPPadj		=	e(b)[1,1]
					
					mat	trans_2by2_`year'			=	samplesize_`year',	trans_2by2_joint_`year',	persistence_`year',	entry_`year'	
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
		
		
		
		*	Kernel density plot by region
			*	Average threshold over 5 years
			*	Annual sample sizes are nearly the same, so should be safe to aggregate
			summ PFS_threshold_glm if !mi(PFS_glm) & inrange(year2,2009,2017)
			local	PFS_threshold=round(r(mean),0.01)
			summ PFS_threshold_glm_RPPadj if !mi(PFS_glm_RPPadj) & inrange(year2,2009,2017)
			local	PFS_RPPadj_threshold=round(r(mean),0.01)
			

			twoway	(kdensity PFS_glm	if	state_group_NE==1	& inrange(year2,2009,2017), 	xline(`PFS_threshold', lc(blue) lpattern(dot)) lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "NE")))	///
					(kdensity PFS_glm	if	state_group_MidWest==1	& inrange(year2,2009,2017), 	xline(`PFS_RPPadj_threshold', lc(green) lpattern(dash))   lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Midwest")))	///
					(kdensity PFS_glm_RPPadj	if	state_group_NE==1	& inrange(year2,2009,2017), 	lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "NE (RPP-adj)")))	///
					(kdensity PFS_glm_RPPadj	if	state_group_MidWest==1	& inrange(year2,2009,2017),   lc(black) lp(dash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "Midwest (RPP-adj)"))),	///
					title("PFS distribution by region and thresholds (2009-2017)") ytitle("Density") xtitle("PFS")
			graph	export	"${PSID_outRaw}/PFS_dist_NE_Midwest.png",as(png) replace
			graph	close	
	}

	
		
	}
	
	if	`sample_rep'==1	{
	    
		use	"${PSID_dtFin}/fs_const_long.dta", clear
		include	"${PSID_doAnl}/Macros_for_analyses.do"
		
		*	We found a sampling issue; the ratio of food insecure households under the HFSM in the balanced study sample is different from that in the USDA report.
		*	To address this concern, we check if "ordering" is preserved
		
		*	First we observe the discrepancy in FI prevalence between the raw data and our study sample
		local	sample_discrepancy=0
		if	`sample_discrepancy'==1	{
		
			*	PSID raw data (family-level )
				
				*	1999
				use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam1999er.dta", clear	
				di	_N	//	6,997 obs
				tab	ER14331U			//	10.0% are food insecure (6,997)
				tab	ER14331U	[aw=ER16518]	//	(longitudinal weight, 7.8% are food insecure (6,851)
				tab	ER14331U	[aw=ER16519]	//	(cross-sectional weight, 8.1% are food insecure (6,997)	
				
				
				*	2001
				use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam2001er.dta", clear	
				di	_N	//	7,406 obs
				tab ER18470U	//	8.9% are food insecure
				tab	ER18470U	[aw=ER20394]	//	(longitudinal weight, 6.1% are food insecure (7,195)
				tab	ER18470U	[aw=ER20459]	//	(cross-sectional weight, 6.6% are food insecure (7,406)
				
				*	2003
				use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam2003er.dta", clear	
				di	_N	//	9,048 obs
				tab	ER21735U	//	16.9% are food insecure
				tab	ER21735U	[aw=ER24179]	//	(longitudinal weight, 6.8% are food insecure (7,565)
				tab	ER21735U	[aw=ER24180]	//	(cross-sectional weight, 6.8% are food insecure (7,822)
				
				*	2015
				*	(note: no cross-sectional weight available in this year)
				use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam2015er.dta", clear	
				di	_N	//	9,048 obs
				tab	ER60799	//	16.9% are food insecure 
				tab	ER60799	[aw=ER65492]	//	(longitudinal weight, 12.5% are food insecure (9,048)
				
				*	2017
				use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam2017er.dta", clear	
				di	_N	//	9,607 obs
				tab	ER66847	//	15.6% are food insecure
				tab	ER66847	[aw=ER71570]	//	(longitudinal weight, 10.0% are food insecure (9,155)
				tab	ER66847	[aw=ER71571]	//	(cross-sectional weight, 12.3% are food insecure (9,607)
			
			
		/*
		*	PSID raw data (individual-level, unweighted)
		use	"${PSID_dtInt}/PSID_raw_ind.dta", clear
		keep	x11102_2003		fs_cat_fam2003
		duplicates drop
		drop	if	mi(x11102_2003)	//	7,822 obs
		tab fs_cat_fam2003	//	9.0% are food insecure, same as above
		
		*	PSID cleaned data (indiv-level, unweighted)
		use	"${PSID_dtInt}/PSID_cleaned_ind.dta", clear
		keep	x11102_2003	fs_cat_fam2003
		duplicates drop	
		drop	if	mi(x11102_2003)	//	7,822 obs
		tab fs_cat_fam2003	//	9.0% are food insecure, same as above
		*/
		

		*	PSID mid-constructed data (indiv-level) - same as raw data, as no observations have been dropped
		/*	(2022-8-17) I lost the code generating "fs_const_wide_allind.dta", so I temporarily disable it. I don't think it is necessary anyway.
		use	"${PSID_dtFin}/fs_const_wide_allind.dta", clear
		
		preserve
		foreach	year	in	1999	2001	2003	2015	2017	{
		    
			keep	x11102_`year'	fs_cat_fam_simp`year'	 weight_long_fam`year'
			duplicates drop	
			drop	if	mi(x11102_`year')	//	Sample size
			tab fs_cat_fam_simp`year'	//	Food insecure category
			tab fs_cat_fam_simp`year'	[aw=weight_long_fam`year']	//	Food insecure category
			
			restore,	preserve
		}
		*/
	
			*	PSID (Balanced sample)
			use	"${PSID_dtFin}/fs_const_long.dta", clear
			include	"${PSID_doAnl}/Macros_for_analyses.do"
			isid	fam_ID_1999	year
			
			
				*	To have a brief understanding, here the difference in summary stats of same sample (1999) across different methods
				*	We can conclude that weight methods doesn't really matter a lot, while weight itself does matter.
				
					*	Balanced sample 1999 including immigrants
					*	It shows the different weight methods between aw and pw are very trival (7.037 vs 7.042)
					summ	fs_cat_IS	if	year2==1999	//	unweighted
					summ	fs_cat_IS	 [aw=weight_long_fam]	if	year2==1999	//	analytic weight using longitudinal family weight. This is the method used by Hoynes et al. (2016 AER paper)
					svy, subpop(if	year2==1999):	mean	fs_cat_IS	//	sampling weight suggested by the PSID. This is the one we have been using so far.
				
					*	Balanced sample 1999 excluding immigrants
					*	It also shows the difference b/w aw and pw are trivial (5.6 vs 5.7)
					summ	fs_cat_IS	if	year2==1999	&	sample_source_SRC_SEO==1	//	unweighted
					summ	fs_cat_IS	 [aw=weight_long_fam]	if	year2==1999	&	sample_source_SRC_SEO==1	//	analytic weight using longitudinal family weight. This is the method used by Hoynes et al. (2016 AER paper)
					svy, subpop(if	year2==1999	&	sample_source_SRC_SEO==1):	mean	fs_cat_IS	//	sampling weight suggested by the PSID. This is the one we have been using so far.

			
			foreach	year2	in	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	{
				
				di	"year is `year2'"
				
				if	inlist(`year2',1999,2001,2003,2015,2017)	{
				
				*	HFSM, Unweighted
				tab	fs_cat_IS	if	year2==`year2'	//	including immigrants
				tab	fs_cat_IS	if	year2==`year2'	& sample_source_SRC_SEO==1	//	excluding immigransts (study sample)
				
			
				*	HFSM, Weighted
				svy, subpop(if year2==`year2'):	mean	fs_cat_IS	//	including immigrants
				svy, subpop(if year2==`year2' & sample_source_SRC_SEO==1):	mean	fs_cat_IS	//	excluding immigransts (study sample)
				
				}
				
				*	PFS, weighted (should match the USDA statistics)
				if	inrange(`year2',2001,2017)	{
								
					svy, subpop(if year2==`year2' & ${study_sample}):	mean	PFS_FI_glm	//	including immigrants
				
				}
				
			}
			
		}	//	sample_discrepancy
				
		*	Categorize under new thresholds
		cap	drop	PFS_glm_newratio
		clonevar	PFS_glm_newratio	=	PFS_glm
		
		*	Categorization	
		local	run_categorization=1
		if	`run_categorization'==1	{
							
				*	For food security threshold value, we use the ratio from the annual USDA reports.
				*	(https://www.ers.usda.gov/topics/food-nutrition-assistance/food-security-in-the-us/readings/#reports)
				
				*** One thing we need to be careful is that, we need to match the USDA ratio to the "population ratio(weighted)", NOT the "sample ratio(unweighted)"
				*	To get population ratio, we should use "svy: mean"	or "svy: proportion"
				*	The best way to do is let STATA find them automatically, but for now (2020/10/6) I will find them manually.
					*	One idea I have to do it automatically is to use loop(while) until we get the threshold value matching the USDA ratio.
				*	Due to time constraint, I only found it for 2015 (year=9) for OLS, which is needed to generate validation table.
				
				
				local	prop_FI_1	=	0.057	// 
				local	prop_FI_2	=	0.043	//
				local	prop_FI_3	=	0.040	// 
				*local	prop_FI_4	=	0.110	// 
				*local	prop_FI_5	=	0.111	// 
				*local	prop_FI_6	=	0.147	// 
				*local	prop_FI_7	=	0.149	// 
				*local	prop_FI_8	=	0.143	// 
				local	prop_FI_9	=	0.071	//
				local	prop_FI_10	=	0.049	// 
				
				*local	prop_VLFS_1		=	0.030	// 1999: 10.1% are food insecure (7.1% are low food secure, 3.0% are very low food secure)
				*local	prop_VLFS_2		=	0.033	// 2001: 10.7% are food insecure (7.4% are low food secure, 3.3% are very low food secure)
				**local	prop_VLFS_4		=	0.039	// 2005: 11.0% are food insecure (7.1% are low food secure, 3.9% are very low food secure)
				*local	prop_VLFS_6		=	0.057	// 2009: 14.7% are food insecure (9.0% are low food secure, 5.7% are very low food secure)
				*local	prop_VLFS_7		=	0.057	// 2011: 14.9% are food insecure (9.2% are low food secure, 5.7% are very low food secure)
				*local	prop_VLFS_8		=	0.056	// 2013: 14.3% are food insecure (8.7% are low food secure, 5.6% are very low food secure)
				*local	prop_VLFS_9		=	0.050	// 2015: 12.7% are food insecure (7.7% are low food secure, 5.0% are very low food secure)
				*local	prop_VLFS_10	=	0.045	// 2017: 11.8% are food insecure (7.3% are low food secure, 4.5% are very low food secure)
			
				*	Categorize food security status based on the PFS.
				* quietly	{
					foreach	type	in	glm_newratio		/*ls	rf*/	{

							
							gen	PFS_FS_`type'	=	0	if	!mi(PFS_`type')	//	Food secure
							gen	PFS_FI_`type'	=	0	if	!mi(PFS_`type')	//	Food insecure (low food secure and very low food secure)
							*gen	PFS_LFS_`type'	=	0	if	!mi(PFS_`type')	//	Low food secure
							*gen	PFS_VLFS_`type'	=	0	if	!mi(PFS_`type')	//	Very low food secure
							*gen	PFS_cat_`type'	=	0	if	!mi(PFS_`type')	//	Categorical variable: FS, LFS or VLFS
													
							*	Generate a variable for the threshold PFS
							gen	PFS_threshold_`type'=.
							
							foreach	year	in	2	3	/*4	5	6	7	8*/	9	10	{
								
								di	"current loop is `plan',  in year `year'"
								xtile pctile_`type'_`year' = PFS_`type' if !mi(PFS_`type')	&	year==`year', nq(1000)
		
								* We use loop to find the threshold value for categorizing households as food (in)secure
								local	counter 	=	1	//	reset counter
								local	ratio_FI	=	0	//	reset FI population ratio
								*local	ratio_VLFS	=	0	//	reset VLFS population ratio
								
								foreach	indicator	in	FI	/*VLFS*/	{
									
									local	counter 	=	1	//	reset counter
									local	ratio_`indicator'	=	0	//	reset population ratio
								
									* To decrease running time, we first loop by 10 
									while (`counter' < 1000 & `ratio_`indicator''<`prop_`indicator'_`year'') {	//	Loop until population ratio > USDA ratio
										
										qui di	"current indicator is `indicator', counter is `counter'"
										qui	replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,`counter')	//	categorize certain number of households at bottom as FI
										qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'	//	Generate population ratio
										local ratio_`indicator' = _b[PFS_`indicator'_`type']
										
										local counter = `counter' + 10	//	Increase counter by 10
									}

									*	Since we first looped by unit of 10, we now have to find to exact value by looping 1 instead of 10.
									qui di "internediate counter is `counter'"
									local	counter=`counter'-10	//	Adjust the counter, since we added extra 10 at the end of the first loop

									while (`counter' > 1 & `ratio_`indicator''>`prop_`indicator'_`year'') {	//	Loop until population ratio < USDA ratio
										
										qui di "counter is `counter'"
										qui	replace	PFS_`indicator'_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',`counter',1000)
										qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'
										local ratio_`indicator' = _b[PFS_`indicator'_`type']
										
										local counter = `counter' - 1
									}
									qui di "Final counter is `counter'"

									*	Now we finalize the threshold value - whether `counter' or `counter'+1
										
										*	Counter
										local	diff_case1	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')

										*	Counter + 1
										qui	replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,`counter'+1)
										qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'
										local	ratio_`indicator' = _b[PFS_`indicator'_`type']
										local	diff_case2	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')
										qui	di "diff_case2 is `diff_case2'"

										*	Compare two threshold values and choose the one closer to the USDA value
										if	(`diff_case1'<`diff_case2')	{
											global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'
										}
										else	{	
											global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'+1
										}
									
									*	Categorize households based on the finalized threshold value.
									qui	{
										replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,${threshold_`indicator'_`plan'_`type'_`year'})
										replace	PFS_`indicator'_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',${threshold_`indicator'_`plan'_`type'_`year'}+1,1000)		
									}	
									di "thresval of `indicator' in year `year' is ${threshold_`indicator'_`plan'_`type'_`year'}"
								}	//	indicator
								
								*	Food secure households
								replace	PFS_FS_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',1,${threshold_FI_`plan'_`type'_`year'})
								replace	PFS_FS_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',${threshold_FI_`plan'_`type'_`year'}+1,1000)
								
								*	Low food secure households
								*replace	PFS_LFS_`type'=1	if	year==`year'	&	PFS_FI_`type'==1	&	PFS_VLFS_`type'==0	//	food insecure but NOT very low food secure households			
								
								*	Categorize households into one of the three values: FS, LFS and VLFS						
								*replace	PFS_cat_`type'=1	if	year==`year'	&	PFS_VLFS_`type'==1
								*replace	PFS_cat_`type'=2	if	year==`year'	&	PFS_LFS_`type'==1
								*replace	PFS_cat_`type'=3	if	year==`year'	&	PFS_FS_`type'==1
								*assert	PFS_cat_`type'!=0	if	year==`year'
								
								*	Save threshold PFS as global macros and a variable, the average of the maximum PFS among the food insecure households and the minimum of the food secure households					
								qui	summ	PFS_`type'	if	year==`year'	&	PFS_FS_`type'==1	//	Minimum PFS of FS households
								local	min_FS_PFS	=	r(min)
								qui	summ	PFS_`type'	if	year==`year'	&	PFS_FI_`type'==1	//	Maximum PFS of FI households
								local	max_FI_PFS	=	r(max)
								
								*	Save the threshold PFS
								replace	PFS_threshold_`type'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2		if	year==`year'
								*global	PFS_threshold_`type'_`year'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2
								
								
							}	//	year
							
							label	var	PFS_FI_`type'	"Food Insecurity (PFS) (`type')"
							label	var	PFS_FS_`type'	"Food security (PFS) (`type')"
							*label	var	PFS_LFS_`type'	"Low food security (PFS) (`type')"
							*label	var	PFS_VLFS_`type'	"Very low food security (PFS) (`type')"
							*label	var	PFS_cat_`type'	"PFS category: FS, LFS or VLFS"
							

					}	//	type
					
					*lab	define	PFS_category	1	"Very low food security (VLFS)"	2	"Low food security (LFS)"	3	"Food security(FS)"
					*lab	value	PFS_cat_*	PFS_category
					
				* }	//	qui
		
		*	See the ratio matches
		svy, subpop(if year2==2001 & ${study_sample}):	mean	PFS_FI_glm_newratio	//	should be 5.7%
		svy, subpop(if year2==2003 & ${study_sample}):	mean	PFS_FI_glm_newratio	//	should be 4.3%
		svy, subpop(if year2==2015 & ${study_sample}):	mean	PFS_FI_glm_newratio	//	should be 7.1%
		svy, subpop(if year2==2017 & ${study_sample}):	mean	PFS_FI_glm_newratio	//	should be 4.9%
		
		}	//	Categorization			
		
		*	Draw a scatter plot
		*	Doesn't really give new info, since technically it is just a change in threshold.
		graph	twoway	(scatter	fs_scale_fam_rescale	PFS_glm if year2==2017 & PFS_FI_glm==1) 	///
						(scatter	fs_scale_fam_rescale	PFS_glm if year2==2017 & PFS_FI_glm_newratio==1)
						
						
		
		*	Check demographic distributions of FI households under different measures
		
			*	Gender
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	fs_cat_IS==1):	mean	HH_female		//	HFSM
			scalar	female_HFSM	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	mean	HH_female		//	PFS (current measure)
			scalar	female_PFS	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	mean	HH_female		//	PFS (new ratio)
			scalar	female_PFS_new	=	e(b)[1,1]
			
			mat	demo_dist_female	=	female_HFSM	,	female_PFS,	female_PFS_new
			scalar	drop	female_HFSM	female_PFS	female_PFS_new
			mat	list	demo_dist_female
		
			*	Race (non-White)
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	fs_cat_IS==1):	mean	HH_race_color		//	HFSM
			scalar	nonWhite_HFSM	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	mean	HH_race_color		//	PFS (current measure)
			scalar	nonWhite_PFS	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	mean	HH_race_color		//	PFS (new ratio)
			scalar	nonWhite_PFS_new	=	e(b)[1,1]
			
			mat	demo_dist_nonWhite	=	nonWhite_HFSM	,	nonWhite_PFS,	nonWhite_PFS_new
			scalar	drop	nonWhite_HFSM	nonWhite_PFS	nonWhite_PFS_new
			mat	list	demo_dist_nonWhite
			
			*	Marrital status (married)
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	fs_cat_IS==1):	mean	marital_status_cat		//	HFSM
			scalar	married_HFSM	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	mean	marital_status_cat		//	PFS (current measure)
			scalar	married_PFS	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	mean	marital_status_cat		//	PFS (new ratio)
			scalar	married_PFS_new	=	e(b)[1,1]
			
			mat	demo_dist_married	=	married_HFSM	,	married_PFS,	married_PFS_new
			scalar	drop	married_HFSM	married_PFS	married_PFS_new
			mat	list	demo_dist_married
			
			*	Disability
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	fs_cat_IS==1):	mean	phys_disab_head		//	HFSM
			scalar	disab_HFSM	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	mean	phys_disab_head		//	PFS (current measure)
			scalar	disab_PFS	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	mean	phys_disab_head		//	PFS (new ratio)
			scalar	disab_PFS_new	=	e(b)[1,1]
			
			mat	demo_dist_disab	=	disab_HFSM	,	disab_PFS,	disab_PFS_new
			scalar	drop	disab_HFSM	disab_PFS	disab_PFS_new
			mat	list	demo_dist_disab
			
			*	Employment		
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	fs_cat_IS==1):	mean	emp_HH_simple		//	HFSM
			scalar	emp_HFSM	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	mean	emp_HH_simple		//	PFS (current measure)
			scalar	emp_PFS	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	mean	emp_HH_simple		//	PFS (new ratio)
			scalar	emp_PFS_new	=	e(b)[1,1]
			
			mat	demo_dist_emp	=	emp_HFSM	,	emp_PFS,	emp_PFS_new
			scalar	drop	emp_HFSM	emp_PFS	emp_PFS_new
			mat	list	demo_dist_emp
			
			*	Education (grade completed)
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	fs_cat_IS==1):	proportion	grade_comp_cat		//	HFSM
			mat	edu_HFSM	=	e(b)'
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	proportion	grade_comp_cat		//	PFS (current measure)
			mat	edu_PFS	=	e(b)'
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	proportion	grade_comp_cat		//	PFS (new ratio)
			mat	edu_PFS_new	=	e(b)'
			
			mat	demo_dist_edu	=	edu_HFSM	,	edu_PFS,	edu_PFS_new
			*scalar	drop	edu_HFSM	edu_PFS	edu_PFS_new
			mat	list	demo_dist_edu
			
			*	Region
			cap	drop	state_group_cat
			gen		state_group_cat=1	if	state_group_NE==1
			replace	state_group_cat=2	if	state_group_MidAt==1
			replace	state_group_cat=3	if	state_group_South==1
			replace	state_group_cat=4	if	state_group_MidWest==1
			replace	state_group_cat=5	if	state_group_West==1
			
			lab	define	state_group_cat	1	"Northest"	2	"Mid-Atlantic"	3	"South"	4	"Mid-West"	5	"West", replace
			lab	val	state_group_cat	state_group_cat
			
			lab	var	state_group_cat	"Region of Residence (category)"
			
			
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	fs_cat_IS==1):	proportion	state_group_cat		//	HFSM
			mat	region_HFSM	=	e(b)'
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	proportion	state_group_cat		//	PFS (current measure)
			mat	region_PFS	=	e(b)'
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	proportion	state_group_cat		//	PFS (new ratio)
			mat	region_PFS_new	=	e(b)'
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_RPPadj==1):	proportion	state_group_cat		// PFS (RPP-adj)
			mat	region_PFS_RPPadj	=	e(b)'
			
			mat	demo_dist_region	=	region_HFSM	,	region_PFS,	region_PFS_new
			*scalar	drop	edu_HFSM	edu_PFS	edu_PFS_new
			mat	list	demo_dist_region
			
			
			*	Food stamp received this year
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	fs_cat_IS==1):	proportion	food_stamp_used_0yr		//	HFSM
			scalar	stamp_HFSM	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	proportion	food_stamp_used_0yr		//	HFSM
			scalar	stamp_PFS	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	proportion	food_stamp_used_0yr		//	PFS (new ratio)
			scalar	stamp_PFS_new	=	e(b)[1,1]
			
			mat	demo_dist_stamp	=	stamp_HFSM,	stamp_PFS,	stamp_PFS_new
			scalar	drop	stamp_HFSM	stamp_PFS	stamp_PFS_new
			mat	list	demo_dist_stamp

		*	Combine distribution matrices
		
		*mat	define	blankrow	=	J(1,3,.)
		mat	demo_dist_combined	=	demo_dist_female	\	demo_dist_nonWhite	\	demo_dist_married	\	demo_dist_disab	\	demo_dist_emp	\	///
									demo_dist_edu	\	demo_dist_region  \ demo_dist_stamp
								
		matrix rownames demo_dist_combined = Female non-White Married Disabled Employed Edu_noHS Edu_HS Edu_somecol Edu_col NE MidAt South MidWest West Stamp
		matrix colnames demo_dist_combined = HFSM PFS PFS_newcutoff
		
		putexcel	set "${PSID_outRaw}/Demo_dist_sample", sheet(Demo_dist_sample) /*modify*/	replace
		putexcel	A5	=	matrix(demo_dist_combined), names overwritefmt nformat(number_d1)
		
		esttab matrix(demo_dist_combined, fmt(%9.2f)) using "${PSID_outRaw}/demo_dist_combined.tex", replace	

		
		
		*	Marrital status (married)
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	marital_status_cat==0):	mean	fs_cat_IS PFS_FI_glm 		//	HFSM
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	marital_status_cat==1):	mean	fs_cat_IS PFS_FI_glm 		//	HFSM
			
			scalar	married_HFSM	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm==1):	mean	marital_status_cat		//	PFS (current measure)
			scalar	married_PFS	=	e(b)[1,1]
			svy, subpop(if ${study_sample} & !mi(fs_cat_IS)	&	!mi(PFS_glm)	&	inlist(year2,2001,2003,2015,2017)	&	PFS_FI_glm_newratio==1):	mean	marital_status_cat		//	PFS (new ratio)
			scalar	married_PFS_new	=	e(b)[1,1]
			
			mat	demo_dist_married	=	married_HFSM	,	married_PFS,	married_PFS_new
			scalar	drop	married_HFSM	married_PFS	married_PFS_new
			mat	list	demo_dist_married
		
		
	}
	
	if	`HFSM_dynamics==1'	{
	    
	*	To compare similarity in dynamics, we replicate spells approach using both HFSM and the PFS, using only the households that both outcomes are non-missing.	
			
		*	Define subsample
		*	Since we do spells approach only, we restrict our sample to hosueholds with non-missing PFS and HFSM in 2001, 2003, 2015 and 2017
		
			*	PFS
			capture	drop	num_nonmissing_PFS
			cap	drop	balanced_PFS
			bys fam_ID_1999: egen num_nonmissing_PFS=count(PFS_FI_glm)	if	inlist(year,2,3,9,10)
			gen	balanced_PFS=1	if	num_nonmissing_PFS==4
		
			*	HFSM
			capture	drop	num_nonmiss_HFSM
			cap	drop	balanced_HFSM
			bys fam_ID_1999: egen num_nonmiss_HFSM=count(fs_cat_fam_simp)	if	inlist(year,2,3,9,10)
			gen	balanced_HFSM=1	if	num_nonmiss_HFSM==4	//	4 waves total
			
			*	Define subsample; households that have (1) balanced PFS across all study waaves (sample as main analysis)  (2)balanced RPP-adj PFS across study waves and (3) 2009-2017 (when both measures are available)
			cap	drop	balanced_PFS_HFSM
			gen		balanced_PFS_HFSM=1		if	balanced_PFS==1			&	balanced_HFSM==1			//	All HH observations which has balanced PFS and RPP-adj PFS
			*gen	balanced_PFSs_all=1		if	balanced_PFS==1			&	balanced_PFS_RPPadj==1			//	All HH observations which has balanced PFS and RPP-adj PFS
			*gen	balanced_PFSs_0917=1	if	balanced_PFSs_all==1	&	inrange(year2,2009,2017)		//	HH with balanced PFS and RPP-adj PFS, only from 2009 to 2017 
			

	*	We only have two single-transition periods (2001-2003, 2015-2017), so we cannot use spell lengths here.
	
	*	Transition matrices	
		
		*	Preamble
		mat drop _all
		cap	drop	??_PFS_FS_glm	??_PFS_FI_glm	??_PFS_LFS_glm	??_PFS_VLFS_glm	??_PFS_cat_glm
		sort	fam_ID_1999	year
			
		*	Generate lagged FS dummies from PFS and HFSM, as svy: command does not support factor variable so we can't use l.'
		cap	drop	fs_cat_FS
		gen			fs_cat_FS	=	0	if	fs_cat_IS==1
		replace		fs_cat_FS	=	1	if	fs_cat_IS==0
		lab	var		fs_cat_FS	"Food secure (HFSM)"
		
		cap	drop	l1_PFS_FI_glm		l1_PFS_FS_glm	l1_fs_cat_IS	l1_fs_cat_FS
		gen	l1_PFS_FI_glm	=	l1.PFS_FI_glm
		gen	l1_PFS_FS_glm	=	l1.PFS_FS_glm
		gen	l1_fs_cat_IS	=	l1.fs_cat_IS
		gen	l1_fs_cat_FS	=	l1.fs_cat_FS
		
		*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
			
			local	PFS_var		PFS_FS_glm
			local	HFSM_var	fs_cat_FS
				
			tab		PFS_FI_glm
			tab		fs_cat_FS
				
			svy, subpop(if ${study_sample}==1 & year_enum3): tabulate PFS_FI_glm	
			svy, subpop(if ${study_sample}==1 & year_enum3): tabulate fs_cat_FS
					
			svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 &	year_enum3): tabulate l1_PFS_FS_glm	PFS_FS_glm
			svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 &	year_enum3): tabulate l1_fs_cat_FS	fs_cat_FS
					
			*	Year
			foreach	depvar	in	PFS	HFSM	{
			foreach year in 3 10	{			// Only these years are available for transition analysis in this practice.

				cap	mat	drop	trans_2by2_year_`depvar'	trans_change_year_`depvar'	
				
				*	Joint distribution	(two-way tabulate), PFS (default)
				svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 &	year_enum`year'): tabulate l1_``depvar'_var'	``depvar'_var'
				mat	trans_2by2_joint_`year'_`depvar' = 	e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`year'_`depvar'	=	e(N_sub)	//	Sample size
				
				*	Marginal distribution (for persistence and entry), PFS (default)
				svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 &	year_enum`year'): proportion	``depvar'_var'	if	l1_``depvar'_var'==0	//	Previously FI
				scalar	persistence_`year'_`depvar'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 &	balanced_PFS_HFSM==1 &	year_enum`year'): proportion	``depvar'_var'	if	l1_``depvar'_var'==1	//	Previously FS
				scalar	entry_`year'_`depvar'		=	e(b)[1,1]
				
				mat	trans_2by2_`year'_`depvar'	=	samplesize_`year'_`depvar',	trans_2by2_joint_`year'_`depvar',	persistence_`year'_`depvar',	entry_`year'_`depvar'	
				
				mat	trans_2by2_year_`depvar'	=	nullmat(trans_2by2_year_`depvar')	\	trans_2by2_`year'_`depvar'
				
							
			}	//	year
			}	//	depvar (HFSM, PFS)
			
					
			*	Gender
			
			
			
			
				*	Male, Joint
				svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 &	gender_head_fam_enum2): tabulate l1_``depvar'_var'	``depvar'_var'
				mat	trans_2by2_joint_male_`depvar' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_male_`depvar'	=	e(N_sub)	//	Sample size
				
				*	Female, Joint
				svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 & HH_female): tabulate l1_``depvar'_var'	``depvar'_var'
				mat	trans_2by2_joint_female_`depvar' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_female_`depvar'	=	e(N_sub)	//	Sample size
				
				*	Male, Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 & gender_head_fam_enum2):qui proportion	``depvar'_var'	if	l1_``depvar'_var'==0	//	Previously FI
				scalar	persistence_male_`depvar'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 & gender_head_fam_enum2):qui proportion	``depvar'_var'	if	l1_``depvar'_var'==1	//	Previously FS
				scalar	entry_male_`depvar'	=	e(b)[1,1]
				
				*	Female, Marginal distribution (for persistence and entry)
				svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 & HH_female):qui proportion	``depvar'_var'	if	l1_``depvar'_var'==0	//	Previously FI
				scalar	persistence_female_`depvar'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & balanced_PFS_HFSM==1 & HH_female):qui proportion	``depvar'_var'	if	l1_``depvar'_var'==1	//	Previously FS
				scalar	entry_female_`depvar'	=	e(b)[1,1]
				
				mat	trans_2by2_male_`depvar'		=	samplesize_male_`depvar',	trans_2by2_joint_male_`depvar',	persistence_male_`depvar',	entry_male_`depvar'	
				mat	trans_2by2_female_`depvar'	=	samplesize_female_`depvar',	trans_2by2_joint_female_`depvar',	persistence_female_`depvar',	entry_female_`depvar'
				
				mat	trans_2by2_gender_`depvar'	=	trans_2by2_male_`depvar'	\	trans_2by2_female_`depvar'
		
	
			*	Race
							
				foreach	type	in	1	0	{	//	white/color
					
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'): tabulate l1_PFS_FS_glm	PFS_FS_glm	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & HH_race_white==`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_race	=	trans_2by2_1	\	trans_2by2_0

			*	Region (based on John's suggestion)
			
				foreach	type	in	NE MidAt South MidWest	West	{
				
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1): tabulate l1_PFS_FS_glm	PFS_FS_glm	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & state_group_`type'==1):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
				}
				
				mat	trans_2by2_region	=	trans_2by2_NE	\	trans_2by2_MidAt	\	trans_2by2_South	\	trans_2by2_MidWest	\		trans_2by2_West
			
			*	Education
			
			foreach	type	in	NoHS	HS	somecol	col	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & highdegree_`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			mat	trans_2by2_degree	=	trans_2by2_NoHS	\	trans_2by2_HS	\	trans_2by2_somecol	\	trans_2by2_col
			
			
			*	Disability
			capture	drop	phys_nodisab_head
			gen		phys_nodisab_head=0	if	phys_disab_head==1
			replace	phys_nodisab_head=1	if	phys_disab_head==0
			
			foreach	type	in	nodisab	disab	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & phys_`type'_head):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			
			mat	trans_2by2_disability	=	trans_2by2_nodisab	\	trans_2by2_disab
			
			*	Child status (by age)
			foreach	type	in	nochild	presch	sch	both	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & childage_in_FU_`type'): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & childage_in_FU_`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & childage_in_FU_`type'):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			
			mat	trans_2by2_child	=	trans_2by2_nochild	\	trans_2by2_presch	\	trans_2by2_sch	\	trans_2by2_both
			
			*	Food Stamp
			cap drop	food_nostamp_used_1yr
			gen		food_nostamp_used_1yr=1	if	food_stamp_used_1yr==0
			replace	food_nostamp_used_1yr=0	if	food_stamp_used_1yr==1
			
			foreach	type	in	nostamp	stamp	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & food_`type'_used_1yr):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
			}
			
			mat	trans_2by2_foodstamp	=	trans_2by2_nostamp	\	trans_2by2_stamp
			
			*	Shock vars
			*	Create temporary vars to easily write a loop code.
			cap	drop	emp_shock noemp_shock marriage_shock nomarriage_shock disab_shock nodisab_shock	newstamp_shock nonewstamp_shock
			
			clonevar	emp_shock	=	no_longer_employed
			clonevar	marriage_shock	=	no_longer_married
			clonevar	disab_shock		=	became_disabled
			gen 		newstamp_shock=0
			replace		newstamp_shock=1	if	food_stamp_used_1yr==0	&	l.food_stamp_used_1yr==1
			
			gen			noemp_shock=0	if	emp_shock==1
			replace		noemp_shock=1	if	emp_shock==0
			gen			nomarriage_shock=0	if	marriage_shock==1
			replace		nomarriage_shock=1	if	marriage_shock==0
			gen			nodisab_shock=0	if	disab_shock==1
			replace		nodisab_shock=1	if	disab_shock==0
			gen			nonewstamp_shock=0	if	newstamp_shock==1
			replace		nonewstamp_shock=1	if	newstamp_shock==0
			
			cap	mat	drop	trans_2by2_shock
			foreach	type	in	/*noemp*/ emp /*nomarriage*/ marriage /*nodisab*/ disab /*nonewstamp*/ newstamp	{
				
				*	Joint
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock): tabulate l1_PFS_FS_glm	PFS_FS_glm	
				mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
				scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
				
				*	Marginal
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==0	&	!mi(PFS_FS_glm)	//	Previously FI
				scalar	persistence_`type'	=	e(b)[1,1]
				svy, subpop(if ${study_sample}==1 & ${nonmissing_PFS_lags} & `type'_shock):qui proportion	PFS_FS_glm	if	l1_PFS_FS_glm==1	&	!mi(PFS_FS_glm)	//	Previously FS
				scalar	entry_`type'	=	e(b)[1,1]
				
				mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
				
				mat	trans_2by2_shock	=	nullmat(trans_2by2_shock)	\	trans_2by2_`type'
			}

		*	Combine transition matrices (Table 6 of 2020/11/16 draft)
		
		mat	define	blankrow	=	J(1,7,.)
		mat	trans_2by2_combined	=	trans_2by2_year	\	blankrow	\	trans_2by2_gender	\	blankrow	\	///
									trans_2by2_race	\	blankrow	\	trans_2by2_region	\	blankrow	\	trans_2by2_degree	\	blankrow	\	///
									trans_2by2_disability	\	blankrow	\	trans_2by2_child	\	blankrow \	trans_2by2_foodstamp	\	blankrow	\	///
									trans_2by2_shock
		
		mat	list	trans_2by2_combined
			
		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices", sheet(2by2) replace	/*modify*/
		putexcel	A3	=	matrix(trans_2by2_combined), names overwritefmt nformat(number_d1)
		
		esttab matrix(trans_2by2_combined, fmt(%9.2f)) using "${PSID_outRaw}/Tab_5_Trans_2by2_combined.tex", replace	
		
		putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices", sheet(change) /*replace*/	modify
		putexcel	A3	=	matrix(trans_change_year), names overwritefmt nformat(number_d1)
		putexcel	A13	=	matrix(FI_still_year_all), names overwritefmt nformat(number_d1)
		putexcel	A23	=	matrix(FI_newly_year_all), names overwritefmt nformat(number_d1)
		
		*	Figure 3 & 4
		*	Need to plot from matrix, thus create a temporary dataset to do this
		preserve
		
			clear
			
			set	obs	8
			gen	year	=	_n
			replace	year	=	2001	+	(2*year)
			
			*	Matrix for Figure 3
			svmat trans_change_year
			rename	(trans_change_year?)	(still_FI	newly_FI	status_unknown)
			label var	still_FI		"Still food insecure"
			label var	newly_FI		"Newly food insecure"
			label var	status_unknown	"Previous status unknown"

			egen	FI_prevalence	=	rowtotal(still_FI	newly_FI	status_unknown)
			label	var	FI_prevalence	"Annual FI prevalence"
			
			*	Matrix for Figure 4a
			**	Figure 4 matrices (FI_still_year_all, FI_newly_year_all) have years in column and category as row, so they need to be transposed)
			foreach	fs_category	in	FI_still_year_all	FI_newly_year_all	{
				
				mat		`fs_category'_tr=`fs_category''
				svmat 	`fs_category'_tr
			}
			
			*	Figure 3	(Change in food security status by year)
			graph bar still_FI newly_FI	status_unknown, over(year) stack legend(lab (1 "Still FI") lab(2 "Newly FI") lab(3 "Previous status unknown") rows(1))	///
						graphregion(color(white)) bgcolor(white) asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(orange)) bar(3, fcolor(gs12))	///
						ytitle(Population prevalence(%))	ylabel(0(.025)0.153)
			graph	export	"${PSID_outRaw}/Fig_3_FI_change_status_byyear.png", replace
			graph	close
				
			*	Figure 4 (Change in Food Security Status by Group)
			*	Figure 4a
			graph bar FI_newly_year_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	ytitle(Population prevalence(%))	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
						bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Newly Food Insecure)	name(Newly_FI, replace) scale(0.8)     
			
			
			*	Figure 4b
			graph bar FI_still_year_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))*/	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
						bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Still Food Insecure)	name(Still_FI, replace)	scale(0.8)  
						
						
			grc1leg Newly_FI Still_FI, rows(1) legendfrom(Newly_FI)	graphregion(color(white)) /*(white)*/
			graph	export	"${PSID_outRaw}/Fig_4_FI_change_status_bygroup.png", replace
			graph	close
			
			
			*	Figure 4c (legend on the right side. For presentation)
			
			*	Figure 4aa
			graph bar FI_newly_year_all_tr?, over(year, label(labsize(small))) stack	graphregion(color(white)) bgcolor(white)	ytitle(Population prevalence(%))	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(8) cols(1) position(3) rowgap(2pt))		///
						bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Newly Food Insecure)	name(Newly_FI_aa, replace) scale(0.8)     
			
			
			*	Figure 4bb
			graph bar FI_still_year_all_tr?, over(year, label(labsize(small))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))*/	ylabel(0(.025)0.1)	///
						legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
						lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(8) cols(1) position(3) rowgap(2pt))	///
						bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
						bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Still Food Insecure)	name(Still_FI_bb, replace)	scale(0.8)  
			
			
			
			*	Figure 4c (legend on the right side. For presentation)
			grc1leg Newly_FI_aa Still_FI_bb, rows(1) cols(2) legendfrom(Newly_FI_aa)	graphregion(color(white)) position(3)	graphregion(color(white))	name(Fig4c, replace) ysize(4) xsize(9.0)
			graph display Fig4c, ysize(4) xsize(9.0)
			graph	export	"${PSID_outRaw}/Fig_4c_FI_change_status_bygroup_ppt.png", as(png) replace
			graph	close
			
			
		restore
			
	
	
	}	

	if	`GLM_dist==1'	{
		
		*	All households (balanced and unbalanced)
		
		*	Balanced households (study sample)
		use	"${PSID_dtFin}/fs_const_long.dta", clear
		include	"${PSID_doAnl}/Macros_for_analyses.do"
		isid	fam_ID_1999	year
		
		*	Distribution of per-capita food expenditure, per 5 random years
		*	Distribution seems to be Gamma or Poisson, flattened over time
		graph twoway 	(kdensity food_exp_stamp_pc if ${study_sample}, lpattern(dash))	///
						(kdensity food_exp_stamp_pc if ${study_sample} & year2==1999)	///
						(kdensity food_exp_stamp_pc if ${study_sample} & year2==2007)	///
						(kdensity food_exp_stamp_pc if ${study_sample} & year2==2013)	///
						(kdensity food_exp_stamp_pc if ${study_sample} & year2==2017),	///
						legend(lab (1 "All") lab(2 "2005")	lab(3 "2009")	lab(4 "2013")	lab(5 "2017") rows(1))	///
						title(Distribution of per capita food expenditure)
		
		summ food_exp_stamp_pc if ${study_sample}
		summ food_exp_stamp_pc if ${study_sample} & year2==1999
		summ food_exp_stamp_pc if ${study_sample} & year2==2005
		summ food_exp_stamp_pc if ${study_sample} & year2==2009
		summ food_exp_stamp_pc if ${study_sample} & year2==2013
		summ food_exp_stamp_pc if ${study_sample} & year2==2017
		
		graph	export	"${PSID_outRaw}/foodexp_dist_byyear.png", as(png) replace
		graph	close

						
		
		*	We try to fit distribution with 2009 distribution which is in the middle.
		cap	drop rgamma_?_?
		forval a=1/5	{
			forval	b=1/5	{
			
				gen	rgamma_`a'_`b'=rgamma(`a',`b')
				lab	var	rgamma_`a'_`b' "Gamma (`a',`b')"
			
			}
		}
		
		graph twoway 	(kdensity rgamma_1_1)	///
						(kdensity rgamma_2_1)	///
						(kdensity rgamma_3_1)	///
						(kdensity rgamma_4_1)	///
						(kdensity rgamma_5_1)
		
		
		graph twoway 	(kdensity rgamma_3_1)	///
						(kdensity rgamma_3_2)	///
						(kdensity rgamma_3_3)	///
						(kdensity rgamma_3_4)	///
						(kdensity rgamma_3_5)
		
			*	Test if it is normal
			swilk food_exp_stamp_pc if ${study_sample} //  (Shapiro-Wilk Test) P-value==0.0000. Reject it is normally distributed
			sfrancia food_exp_stamp_pc if ${study_sample}	// (Shapiro-Francia Test) P-value==0.0000. Reject it is normally distributed
			
			*	Test Gamma distribution with different distribution parameters
			loc	var	gamma_01_01
			cap	drop	`var'
			gen	`var'	=	rgamma(5,0.5)	if ${study_sample}
			kdensity	food_exp_stamp_pc
			
			
			
			graph	twoway	(kdensity	food_exp_stamp_pc)	(kdensity	`var')
	
			*	K-S test syntax
			// ksmirnov x = normal((x-mean)/stdev). normal(.) is standard cdf with z=.
			
			
		*	Generate PFS with different distributions to see robustness
		use	"${PSID_dtFin}/fs_const_long.dta", clear
		include	"${PSID_doAnl}/Macros_for_analyses.do"
		
			*	Normal distribution
			local	depvar		food_exp_stamp_pc
			
				*	Step 1
				svy, subpop(${study_sample}): reg 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}
				est	sto	normal_step1
				
				*	Predict fitted value and residual
				gen	normal_step1_sample=1	if	e(sample)==1 & `=e(subpop)'	//	We need =`e(subpop)' condition, as e(sample) includes both subpopulation and non-subpopulation.
				
				predict double mean1_foodexp_normal	if	normal_step1_sample==1
				predict double e1_foodexp_normal	if	normal_step1_sample==1,r
				gen e1_foodexp_sq_normal = (e1_foodexp_normal)^2
				
				*	Step 2
				local	depvar	e1_foodexp_sq_normal
			
				svy, subpop(${study_sample}): reg 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}
		
				est store normal_step2
				gen	normal_step2_sample=1	if	e(sample)==1 & `=e(subpop)'
				*svy:	reg `e(depvar)' `e(selected)'
				predict	double	var1_foodexp_normal	if	normal_step2_sample==1	
				gen	double		sd_foodexp_normal	=	sqrt(var1_foodexp_normal)
				
				*	Step 3
				gen thresh_normal=(foodexp_W_thrifty-mean1_foodexp_normal)/sd_foodexp_normal	//	Z-score of log(poverty line)
				gen prob_below_normal=normal(thresh_normal)
				gen PFS_normal=1-prob_below_normal
				lab	var	PFS_normal			"PFS (normal)"
		
			*	Gamma distribution with default link function (negative inverse)
			local	depvar		food_exp_stamp_pc
			
				*	Step 1
				svy, subpop(${study_sample}): glm 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}, family(gamma)	//link(log)
				gen	gamma_inv_step1_sample=1	if	e(sample)==1 & `=e(subpop)'	//	We need =`e(subpop)' condition, as e(sample) includes both subpopulation and non-subpopulation.
			
				predict double mean1_foodexp_gamma_inv	if	gamma_inv_step1_sample==1
				predict double e1_foodexp_gamma_inv		if	gamma_inv_step1_sample==1,r
				gen e1_foodexp_sq_gamma_inv = (e1_foodexp_gamma_inv)^2
		
				*	Step 2
				local	depvar	e1_foodexp_sq_gamma_inv
				
				svy, subpop(${study_sample}): glm 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}	, family(gamma)	//link(log)
			
				est store gamma_inv_step2
				gen	gamma_inv_step2_sample=1	if	e(sample)==1 & `=e(subpop)'
				*svy:	reg `e(depvar)' `e(selected)'
				predict	double	var1_foodexp_gamma_inv	if	glm_step2_sample==1	
				
				
				*	Step 3
				gen alpha1_foodexp_pc_gamma_inv	= (mean1_foodexp_gamma_inv)^2 / var1_foodexp_gamma_inv	//	shape parameter of Gamma (alpha)
				gen beta1_foodexp_pc_gamma_inv	= var1_foodexp_gamma_inv / mean1_foodexp_gamma_inv	//	scale parameter of Gamma (beta)
				
				*	Generate PFS by constructing CDF
				gen PFS_gamma_inv = gammaptail(alpha1_foodexp_pc_gamma_inv, foodexp_W_thrifty/beta1_foodexp_pc_gamma_inv)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_gamma_inv "PFS (Gamma with negative inverse link)"
	
	
			*	Normal (with IHS food expenditure)
			cap	drop	IHS_food_exp_stamp_pc	IHS_foodexp_W_thrifty
			gen	IHS_food_exp_stamp_pc	=	asinh(food_exp_stamp_pc)
			gen	IHS_foodexp_W_thrifty	=	asinh(foodexp_W_thrifty)
			
			local	depvar		IHS_food_exp_stamp_pc
			
				*	Step 1
				svy, subpop(${study_sample}): reg 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}
				est	sto	lnormal_step1
				
				*	Predict fitted value and residual
				gen	lnormal_step1_sample=1	if	e(sample)==1 & `=e(subpop)'	//	We need =`e(subpop)' condition, as e(sample) includes both subpopulation and non-subpopulation.
				
				predict double mean1_foodexp_lnormal	if	lnormal_step1_sample==1
				predict double e1_foodexp_lnormal	if	lnormal_step1_sample==1,r
				gen e1_foodexp_sq_lnormal = (e1_foodexp_lnormal)^2
				
				*	Step 2
				local	depvar	e1_foodexp_sq_lnormal
			
				svy, subpop(${study_sample}): reg 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}
		
				est store lnormal_step2
				gen	lnormal_step2_sample=1	if	e(sample)==1 & `=e(subpop)'
				*svy:	reg `e(depvar)' `e(selected)'
				predict	double	var1_foodexp_lnormal	if	lnormal_step2_sample==1	
				gen	double		sd_foodexp_lnormal	=	sqrt(var1_foodexp_lnormal)
				
				*	Step 3
				gen thresh_lnormal=(IHS_foodexp_W_thrifty-mean1_foodexp_lnormal)/sd_foodexp_lnormal	//	Z-score of log(poverty line)
				gen prob_below_lnormal=normal(thresh_lnormal)
				gen PFS_lnormal=1-prob_below_lnormal
				lab	var	PFS_lnormal			"PFS (log normal)"
			
			
			* Poission
			local	depvar		food_exp_stamp_pc
			
				*	Step 1
				svy, subpop(${study_sample}): glm 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}, family(poisson)	//link(log)
				gen	poisson_step1_sample=1	if	e(sample)==1 & `=e(subpop)'	//	We need =`e(subpop)' condition, as e(sample) includes both subpopulation and non-subpopulation.
				predict double mean1_foodexp_poisson	if	poisson_step1_sample==1
				
				*	Step 3
				gen PFS_poisson = poissontail(mean1_foodexp_poisson,foodexp_W_thrifty)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_poisson "PFS (Poisson)"


			
		*	Evaluate the performance
		
			*	Graph per capita food expenditure and conditional means
			twoway	(kdensity food_exp_stamp_pc, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Food expenditure per capita")))	///
					(kdensity mean1_foodexp_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Normal)")))	///
					(kdensity mean1_foodexp_glm, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Gamma log link)")))	///
					(kdensity mean1_foodexp_gamma_inv, lc(red) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "Cond.mean (Gamma neg inv)")))	///
					(kdensity mean1_foodexp_poisson, lc(black) lp(longdash) lwidth(medium) graphregion(fcolor(white)) legend(label(5 "Cond.mean (Poisson)"))),	///
					title("Per capita food expenditure and conditional means") ytitle("Density") xtitle("Expenditure")
			graph	export	"${PSID_outRaw}/Foodexp_cond_means.png", as(png) replace
			graph	close
			
			*	Graph PFS under different distributional assumptions
			twoway	(kdensity PFS_normal, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Normal")))	///
					(kdensity PFS_glm, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Gamma log link")))	///
					(kdensity PFS_gamma_inv, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Gamma negative inverse link")))	///
					(kdensity PFS_poisson, lc(red) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "Poisson")))	///
					(kdensity PFS_lnormal, lc(black) lp(longdash) lwidth(medium) graphregion(fcolor(white)) legend(label(5 "Normal with IHS food expenditure"))),	///
					title("PFS under different distributions") ytitle("Density") xtitle("PFS")
			graph	export	"${PSID_outRaw}/PFS_distributions.png", as(png) replace
			graph	close
			
		
			*	MSE (1st moment, diff between actual value and conditional mean)
			cap	drop	diff_m_*

			gen	diff_m_foodexp_normal		=	(food_exp_stamp_pc	-	mean1_foodexp_normal)^2		//	Normal
			gen	diff_m_foodexp_gamma		=	(food_exp_stamp_pc	-	mean1_foodexp_glm)^2		//	Gamma
			gen	diff_m_foodexp_gamma_iuv	=	(food_exp_stamp_pc	-	mean1_foodexp_gamma_inv)^2	//	Gamma
			gen	diff_m_foodexp_lnormal		=	(IHS_food_exp_stamp_pc	-	mean1_foodexp_lnormal)^2	//	Log-normal (Note: It should be lower than other differences, as )
			gen	diff_m_foodexp_poisson		=	(food_exp_stamp_pc	-	mean1_foodexp_poisson)^2	//	Poisson
			
			tabstat	diff_m_*, save
			mat	MSE_1st_moment =	r(StatTotal)'
			
			*	MSE (2nd moment, diff between squared residual and conditional variance)
			cap	drop	diff_v_*
			
			gen	diff_v_foodexp_normal		=	(e1_foodexp_sq_normal		-	var1_foodexp_normal)^2		//	Normal
			gen	diff_v_foodexp_gamma		=	(e1_foodexp_sq_glm			-	var1_foodexp_glm)^2		//	Gamma
			gen	diff_v_foodexp_gamma_iuv	=	(e1_foodexp_sq_gamma_inv	-	var1_foodexp_gamma_inv)^2	//	Gamma
			gen	diff_v_foodexp_lnormal		=	(e1_foodexp_sq_lnormal		-	var1_foodexp_lnormal)^2	//	Log-normal (Note: It should be lower than other differences, as )
			
			tabstat	diff_v_*, save
			mat	MSE_2nd_moment =	r(StatTotal)'
			
			
			
			tabstat	diff_*, save
			mat	MSE_PFS	=	r(StatTotal)'
			
			
			putexcel	I2	=	"RMSE of conditional mean"
			putexcel	I3	=	matrix(RMSE_cond_mean), names overwritefmt nformat(number_d1)
			
			summ PFS_glm PFS_normal
			
			local	depvar		food_exp_stamp_pc
			glm 	`depvar'	${statevars_rescaled}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${regionvars}	${timevars}, family(igaussian)	//link(log)
			
			
			
			
			
			
			twoway	(kdensity food_exp_stamp_pc, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Food expenditure per capita")))	///
					(kdensity mean1_foodexp_glm, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Gammma)")))	///
					(kdensity mean1_foodexp_normal, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Normal)")))	///
					(kdensity mean1_foodexp_gamma_inv, lc(red) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "Cond.mean (Gamma neg inv)"))),	///
					title("Distribution of All Exp and conditional means") ytitle("Density") xtitle("Expenditure")
			
			
			
			
			
			graph	twoway	(kdensity	PFS_glm)	(kdensity	PFS_normal)	(kdensity	PFS_gamma_inv)	(kdensity	PFS_lnormal)	(kdensity	PFS_poisson)
					
			di (1/exp(-3.2))
					
			
			
	}