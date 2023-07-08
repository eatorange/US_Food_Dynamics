*	Appendix B

	use	"${FSD_dtFin}/FSD_const_long.dta", clear
		
		*	Correlation (in-text numbers)
		
		{	
			
			*	between FSSS and PFS

				*	Spearman (all sample)
				spearman	fs_scale_fam_rescale	PFS_glm		///
						if ${study_sample}	&	inlist(year,2,3,9,10),	stats(rho obs p)
				mat	corr_spearman_all_FSSS_PFS	=	r(rho), r(p)
				
				*	Spearman (FSSS FI households only)
				spearman	fs_scale_fam_rescale	PFS_glm		///
						if ${study_sample}	&	inlist(year,2,3,9,10)	&	fs_cat_fam_simp==0,	stats(rho obs p)
				mat	corr_spearman_FI_FSSS_PFS	=	r(rho), r(p)	
			
				*	Tau's b (all sample)
				ktau 	fs_scale_fam_rescale	PFS_glm		///
						if ${study_sample}	&	inlist(year,2,3,9,10), stats(taua taub p)
				mat	corr_kendall_all_FSSS_PFS	=	r(tau_b), r(p)
				
				*	Tau's b (FSSS FI household only)
				ktau 	fs_scale_fam_rescale	PFS_glm		///
						if ${study_sample}	&	inlist(year,2,3,9,10)	&	fs_cat_fam_simp==0, stats(taua taub p)
				mat	corr_kendall_FI_FSSS_PFS	=	r(tau_b), r(p)
				
				
				mat	corr_FSSS_PFS	=	corr_spearman_all_FSSS_PFS	\	corr_spearman_FI_FSSS_PFS	\	corr_kendall_all_FSSS_PFS	\	corr_kendall_FI_FSSS_PFS
			
			*	Between FSSS and NME
				
				*	Spearman (all sample)
				spearman	fs_scale_fam_rescale	NME		///
						if ${study_sample}	&	inlist(year,2,3,9,10),	stats(rho obs p)
				mat	corr_spearman_all_FSSS_E	=	r(rho), r(p)	
				
				*	Spearman (FSSS FI households only)
				spearman	fs_scale_fam_rescale	NME		///
						if ${study_sample}	&	inlist(year,2,3,9,10)	&	fs_cat_fam_simp==0,	stats(rho obs p)
				mat	corr_spearman_FI_FSSS_E	=	r(rho), r(p)	
			
				*	Tau's b (all sample)
				ktau 	fs_scale_fam_rescale	NME		///
						if ${study_sample}	&	inlist(year,2,3,9,10), stats(taua taub p)
				mat	corr_kendall_all_FSSS_E	=	r(tau_b), r(p)
				
				*	Tau's b (FSSS FI household only)
				ktau 	fs_scale_fam_rescale	NME		///
						if ${study_sample}	&	inlist(year,2,3,9,10)	&	fs_cat_fam_simp==0, stats(taua taub p)
				mat	corr_kendall_FI_FSSS_E	=	r(tau_b), r(p)
				
				mat	corr_FSSS_E	=	corr_spearman_all_FSSS_E	\	corr_spearman_FI_FSSS_E	\	corr_kendall_all_FSSS_E	\	corr_kendall_FI_FSSS_E
				
				mat	corr_all	=	corr_FSSS_PFS,	corr_FSSS_E
				mat	list	corr_all
		
		
			
			*	Table B1: Regression of FSSS on PFS and NME
			
				*	FSSS on PFS, no control
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
					reg	fs_scale_fam_rescale	PFS_glm
				est	store	FSSS_PFS_biv_nocont	
			
				*	FSSS on E, no control
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
					reg	fs_scale_fam_rescale	NME
				est	store	FSSS_E_biv_nocont	
				
				*	FSSS on PFS, control
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
				reg	fs_scale_fam_rescale	PFS_glm	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
				est	store	FSSS_PFS_biv_cont	
			
				*	FSSS on E, control
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
				reg	fs_scale_fam_rescale	NME	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
				est	store	FSSS_E_biv_cont	
				
				*	FSSS on PFS and E, no control
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
					reg	fs_scale_fam_rescale	PFS_glm	NME
				est	store	FSSS_PFS_E_nocont
				
				*	FSSS on PFS and E, control
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
					reg	fs_scale_fam_rescale	PFS_glm	NME	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
				est	store	FSSS_PFS_E_cont	
				
					* Table B1
					esttab	FSSS_PFS_biv_nocont 	FSSS_E_biv_nocont	FSSS_PFS_E_nocont	FSSS_PFS_E_cont	///
						using "${FSD_outTab}/Tab_B1.csv", ///
						cells(b(star fmt(a3)) se(fmt(3) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	keep(PFS_glm	NME)	///
						title(Regression of FSSS on FI indicators) 	replace
					
					esttab	FSSS_PFS_biv_nocont 	FSSS_E_biv_nocont	FSSS_PFS_E_nocont	FSSS_PFS_E_cont	///
						using "${FSD_outTab}/Tab_B1.tex", ///
						cells(b(star fmt(a3)) se(fmt(3) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	keep(PFS_glm	NME)	///
						title(Regression of FSSS on FI indicators) 	replace
			
			
			*	Table B2: Food Security Indicators and Their Correlates - with NME
			
		
				*	FSSS, with region FE
				local	depvar	fs_scale_fam_rescale
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
					reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
				est	store	FSSS_regionFE	
				
				*	PFS, with region FE
				local	depvar	PFS_FS_glm
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
					reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
				est	store	PFS_regionFE	
			
				*	E, with region FE
				local	depvar	NME
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)	&	!mi(NME)):	///
					reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
				est	store	NME_regionFE

				
				esttab	FSSS_regionFE	PFS_regionFE	NME_regionFE	using "${FSD_outTab}/Tab_B2.csv", ///
				cells(b(star fmt(3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	drop(*year_enum* state_group*)	///
				title(Effect of Correlates on Food Security Status) replace

				esttab	FSSS_regionFE	PFS_regionFE	NME_regionFE	using "${FSD_outTab}/Tab_B2.tex", ///
				/*cells(b(star fmt(3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	*/	///
				cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
				title(Effect of Correlates on Food Security Status) replace
				
			}	
					
		
		*	Spell length
		{
			*	Tag balanced sample (Households without any missing PFS throughout the study period)
			*	Unbalanced households will be dropped from spell length analyses not to underestimate spell lengths
			capture	drop	num_nonmissing_NME
			cap	drop	balanced_NME
			bys fam_ID_1999: egen num_nonmissing_NME=count(NME_FI)
			gen	balanced_NME=1	if	num_nonmissing_NME==9

			*	Summary stats of spell lengths among FI incidence
			*mat	summ_spell_length	=	J(9,2,.)	
			cap drop	_seq	_spell	_end
			tsspell, cond(year>=2 & NME_FI==1)
			svy, subpop(if	${study_sample} & _end==1 & balanced_NME==1): mean _seq //	Mean of spell lengths (To get length as an year, multiply spell length by 2)
			svy, subpop(if	${study_sample}	& _end==1 & balanced_NME==1): tab _seq 	//	Tabulation of spell lengths.
			*mat	summ_spell_length	=	e(N),	e(b)
			mat	summ_spell_length	=	e(b)[1..1,2..10]'

			*	Persistence rate conditional upon spell length (Table 7 of 2020/11/16 draft)
			tsset // need to run befor the code below
			mat	persistence_upon_spell	=	J(9,2,.)	
			forvalues	i=1/8	{
				svy, subpop(if l._seq==`i'	&	!mi(NME_FS) &	balanced_NME==1): proportion NME_FS		//	Previously FI
				mat	persistence_upon_spell[`i',1]	=	/*e(N),*/ e(b)[1,1], r(table)[2,1]
			}

			*	Distribution of spell length and conditional persistent (Table 7 of 2020/11/16 draft)
			mat spell_dist_comb	=	summ_spell_length,	persistence_upon_spell
			mat	rownames	spell_dist_comb	=	2	4	6	8	10	12	14	16	18

			*putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices_NME", sheet(spell_dist_comb) modify	/*replace*/
			*putexcel	A5	=	matrix(spell_dist_comb), names overwritefmt nformat(number_d1)
			
			*esttab matrix(spell_dist_comb, fmt(%9.2f)) using "${PSID_outRaw}/Spell_dist_combined_NME.tex", replace	

			drop	_seq _spell _end

			*	Spell length given household newly become food insecure, by each year
			cap drop FI_duration
			gen FI_duration=.

			cap	mat	drop	dist_spell_length
			mat	dist_spell_length	=	J(8,10,.)

			forval	wave=2/9	{
				
				cap drop FI_duration_year*	_seq _spell _end	
				tsspell, cond(year>=`wave' & NME_FI==1)
				egen FI_duration_year`wave' = max(_seq), by(fam_ID_1999 _spell)
				replace	FI_duration = FI_duration_year`wave' if NME_FI==1 & year==`wave'
						
				*	Replace households that used to be FI last year with missing value (We are only interested in those who newly became FI)
				if	`wave'>=3	{
					replace	FI_duration	=.	if	year==`wave'	&	!(NME_FI==1	&	l.NME_FI==0)
				}
				
			}
			replace FI_duration=.	if	balanced_NME!=1 //

			*	Figure 4 of 2020/11/16 draft
			mat	dist_spell_length_byyear	=	J(8,10,.)
			forval	wave=2/9	{
				
				local	row=`wave'-1
				svy, subpop(if year==`wave'	&	!mi(FI_duration)): tab FI_duration
				mat	dist_spell_length_byyear[`row',1]	=	e(N_sub), e(b)
				
			}

			*putexcel	set "${PSID_outRaw}/Tab_5_Transition_Matrices_NME", sheet(spell_length) modify	/*replace*/
			*putexcel	A5	=	matrix(dist_spell_length_byyear), names overwritefmt nformat(number_d1)
			
			*esttab matrix(dist_spell_length_byyear, fmt(%9.2f)) using "${PSID_outRaw}/Tab_4_Dist_spell_length_NME.tex", replace	
			
			
			*	Figure B1
			preserve
				
				clear
				
				set	obs	10
				
				mat	dist_spell_length_byyear_tr	=	dist_spell_length_byyear'
				svmat	dist_spell_length_byyear_tr
				rename	(dist_spell_length_byyear_tr?)	(yr_2001	yr_2003	yr_2005	yr_2007	yr_2009	yr_2011	yr_2013	yr_2015)
				drop	in	1
				
				gen	spell_length	=	(2*_n)
				
				
				*	Figure 2 (Spell Length of Food Insecurity (2003-2015))
				local	marker_2003	mcolor(gs0)	msymbol(circle)
				local	marker_2005	mcolor(gs2)		msymbol(diamond)
				local	marker_2007	mcolor(gs4)	msymbol(triangle)
				local	marker_2009	mcolor(gs6)		msymbol(square)
				local	marker_2011	mcolor(gs8)	msymbol(plus)
				local	marker_2013	mcolor(gs10)	msymbol(X)
				local	marker_2015	mcolor(gs12)	msymbol(V)			
				
				twoway	(connected	yr_2003	spell_length	in	1/7, `marker_2003'	lpattern(solid))			(connected	yr_2003	spell_length	in	8, `marker_2003')	///
						(connected	yr_2005	spell_length	in	1/6, `marker_2005'	lpattern(dash))				(connected	yr_2005	spell_length	in	7, `marker_2005')	///
						(connected	yr_2007	spell_length	in	1/5, `marker_2007'	lpattern(dot))				(connected	yr_2007	spell_length	in	6, `marker_2007')	///
						(connected	yr_2009	spell_length	in	1/4, `marker_2009'	lpattern(dash_dot))			(connected	yr_2009	spell_length	in	5, `marker_2009')	///
						(connected	yr_2011	spell_length	in	1/3, `marker_2011'	lpattern(shortdash))		(connected	yr_2011	spell_length	in	4, `marker_2011')	///
						(connected	yr_2013	spell_length	in	1/2, `marker_2013'	lpattern(shortdash_dot))	(connected	yr_2013	spell_length	in	3, `marker_2013')	///
						(connected	yr_2015	spell_length	in	1/6, `marker_2015'	lpattern(longdash))			(connected	yr_2015	spell_length	in	2, `marker_2015'),	///
						xtitle(Years)	ytitle(Percentage)	legend(order(1 "2003"	3	"2005"	5	"2007"	7	"2009"	9	"2011"	11	"2013"	13	"2015") rows(2))	///
						xlabel(0(2)16)	ylabel(0(0.1)0.7)	graphregion(color(white)) bgcolor(white)	ysize(2)	xsize(4)
				
				graph	export	"${FSD_outFig}/Fig_B1.png", replace
				graph	close
				
				
			restore
		
		}	//	spell length
		
	
		*	Transition matrix
		
		{
		
			*	Preamble
			mat drop _all
			cap	drop	??_NME_FS	??_NME_FI	??_NME_LFS	??_NME_VLFS	??_NME_cat
			sort	fam_ID_1999	year
				
			*	Generate lagged FS dummy from PFS, as svy: command does not support factor variable so we can't use l.	
			forvalues	diff=1/9	{
				foreach	category	in	FS	FI	LFS	VLFS	cat	{
					if	`diff'!=9	{
						qui	gen	l`diff'_NME_`category'	=	l`diff'.NME_`category'	//	Lag
					}
					qui	gen	f`diff'_NME_`category'	=	f`diff'.NME_`category'	//	Forward
				}
			}
			
			*	Restrict sample to the observations with non-missing PFS and lagged PFS
			global	nonmissing_NME_lags	!mi(l1_NME_FS)	&	!mi(NME_FS)
			
			*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
				
				*	Year
				cap	mat	drop	trans_2by2_year	trans_change_year
				forvalues	year=3/10	{			

					*	Joint distribution	(two-way tabulate)
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & year_enum`year'): tabulate l1_NME_FS	NME_FS
					mat	trans_2by2_joint_`year' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`year'	=	e(N_sub)	//	Sample size
					
					*	Marginal distribution (for persistence and entry)
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & year_enum`year'): proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
					scalar	persistence_`year'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & year_enum`year'):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
					scalar	entry_`year'	=	e(b)[1,1]
					
					mat	trans_2by2_`year'	=	samplesize_`year',	trans_2by2_joint_`year',	persistence_`year',	entry_`year'	
					mat	trans_2by2_year	=	nullmat(trans_2by2_year)	\	trans_2by2_`year'
					
					
					*	Change in Status (For Figure 3 of 2020/11/16 draft)
					**	Note: here we do NOT limit our sample to non-missing values, as we need the ratio of those with missing values.
					svy, subpop(if ${study_sample}  & !mi(NME_FI)	&	year==`year'): tab 	l1_NME_FI NME_FI, missing
					local	sample_popsize_total=e(N_subpop)
					mat	trans_change_`year' = e(b)[1,5], e(b)[1,2], e(b)[1,8]
					mat	trans_change_year	=	nullmat(trans_change_year)	\	trans_change_`year'
					
					cap	mat	drop	Pop_ratio
					cap	mat	drop	FI_still_`year'	FI_newly_`year'	
					
					foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
						foreach	race	in	0	1	{	//	People of colors, white
							foreach	gender	in	1	0	{	//	Female, male
								
									
								qui	svy, subpop(if	${study_sample} & !mi(NME_FI)	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'	&	year==`year'):	tab l1_NME_FI NME_FI, missing
													
								local	Pop_ratio	=	e(N_subpop)/`sample_popsize_total'
								local	FI_still_`year'		=	e(b)[1,5]*`Pop_ratio'
								local	FI_newly_`year'		=	e(b)[1,2]*`Pop_ratio'
								
								mat	Pop_ratio	=	nullmat(Pop_ratio)	\	`Pop_ratio'
								mat	FI_still_`year'	=	nullmat(FI_still_`year')	\	`FI_still_`year''
								mat	FI_newly_`year'	=	nullmat(FI_newly_`year')	\	`FI_newly_`year''
								
							}	//	gender
						}	//	race
					}	//	education
					
					mat	FI_still_year_all	=	nullmat(FI_still_year_all),	FI_still_`year'
					mat	FI_newly_year_all	=	nullmat(FI_newly_year_all),	FI_newly_`year'
								
				}	//	year

				
						
				*	Gender
				
					*	Male, Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & gender_head_fam_enum2): tabulate l1_NME_FS	NME_FS	
					mat	trans_2by2_joint_male = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_male	=	e(N_sub)	//	Sample size
					
					*	Female, Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & HH_female): tabulate l1_NME_FS	NME_FS	
					mat	trans_2by2_joint_female = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_female	=	e(N_sub)	//	Sample size
					
					*	Male, Marginal distribution (for persistence and entry)
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & gender_head_fam_enum2):qui proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
					scalar	persistence_male	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & gender_head_fam_enum2):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
					scalar	entry_male	=	e(b)[1,1]
					
					*	Female, Marginal distribution (for persistence and entry)
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & HH_female):qui proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
					scalar	persistence_female	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & HH_female):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
					scalar	entry_female	=	e(b)[1,1]
					
					mat	trans_2by2_male		=	samplesize_male,	trans_2by2_joint_male,	persistence_male,	entry_male	
					mat	trans_2by2_female	=	samplesize_female,	trans_2by2_joint_female,	persistence_female,	entry_female
					
					mat	trans_2by2_gender	=	trans_2by2_male	\	trans_2by2_female
					
				*	Race
								
					foreach	type	in	1	0	{	//	white/color
						
						*	Joint
						svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & HH_race_white==`type'): tabulate l1_NME_FS	NME_FS	
						mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
						scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
						
						*	Marginal
						svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & HH_race_white==`type'):qui proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
						scalar	persistence_`type'	=	e(b)[1,1]
						svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & HH_race_white==`type'):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
						scalar	entry_`type'	=	e(b)[1,1]
						
						mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
					}
					
					mat	trans_2by2_race	=	trans_2by2_1	\	trans_2by2_0

				*	Region (based on John's suggestion)
				
					foreach	type	in	NE MidAt South MidWest	West	{
					
						*	Joint
						svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & state_group_`type'==1): tabulate l1_NME_FS	NME_FS	
						mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
						scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
						
						*	Marginal
						svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & state_group_`type'==1):qui proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
						scalar	persistence_`type'	=	e(b)[1,1]
						svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & state_group_`type'==1):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
						scalar	entry_`type'	=	e(b)[1,1]
						
						mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'		
					}
					
					mat	trans_2by2_region	=	trans_2by2_NE	\	trans_2by2_MidAt	\	trans_2by2_South	\	trans_2by2_MidWest	\		trans_2by2_West
				
				*	Education
				
				foreach	type	in	NoHS	HS	somecol	col	{
					
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & highdegree_`type'): tabulate l1_NME_FS	NME_FS	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & highdegree_`type'):qui proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & highdegree_`type'):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
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
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & phys_`type'_head): tabulate l1_NME_FS	NME_FS	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & phys_`type'_head):qui proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & phys_`type'_head):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
					
				}
				
				mat	trans_2by2_disability	=	trans_2by2_nodisab	\	trans_2by2_disab
				
				*	Food Stamp
				cap drop	food_nostamp_used_1yr
				gen		food_nostamp_used_1yr=1	if	food_stamp_used_1yr==0
				replace	food_nostamp_used_1yr=0	if	food_stamp_used_1yr==1
				
				foreach	type	in	nostamp	stamp	{
					
					*	Joint
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & food_`type'_used_1yr): tabulate l1_NME_FS	NME_FS	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & food_`type'_used_1yr):qui proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & food_`type'_used_1yr):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
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
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & `type'_shock): tabulate l1_NME_FS	NME_FS	
					mat	trans_2by2_joint_`type' = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
					scalar	samplesize_`type'	=	e(N_sub)	//	Sample size
					
					*	Marginal
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & `type'_shock):qui proportion	NME_FS	if	l1_NME_FS==0	&	!mi(NME_FS)	//	Previously FI
					scalar	persistence_`type'	=	e(b)[1,1]
					svy, subpop(if ${study_sample}==1 & ${nonmissing_NME_lags} & `type'_shock):qui proportion	NME_FS	if	l1_NME_FS==1	&	!mi(NME_FS)	//	Previously FS
					scalar	entry_`type'	=	e(b)[1,1]
					
					mat	trans_2by2_`type'	=	samplesize_`type',	trans_2by2_joint_`type',	persistence_`type',	entry_`type'
					
					mat	trans_2by2_shock	=	nullmat(trans_2by2_shock)	\	trans_2by2_`type'
				}

			*	Combine transition matrices (Table 6 of 2020/11/16 draft)
			
			mat	define	blankrow	=	J(1,7,.)
			mat	trans_2by2_combined	=	trans_2by2_year	\	blankrow	\	trans_2by2_gender	\	blankrow	\	///
										trans_2by2_race	\	blankrow	\	trans_2by2_region	\	blankrow	\	trans_2by2_degree	\	blankrow	\	///
										trans_2by2_disability	\	blankrow	\	trans_2by2_foodstamp	\	blankrow	\	///
										trans_2by2_shock
			
			mat	list	trans_2by2_combined
				
			putexcel	set "${FSD_outTab}/Tab_B3", sheet(2by2) replace	
			putexcel	A3	=	matrix(trans_2by2_combined), names overwritefmt nformat(number_d1)
			
			esttab matrix(trans_2by2_combined, fmt(%9.2f)) using "${FSD_outTab}/Tab_B3.tex", replace	
			
			*putexcel	set "${FSD_outTab}/Tab_5_Transition_Matrices_E", sheet(change) /*replace*/	modify
			*putexcel	A3	=	matrix(trans_change_year), names overwritefmt nformat(number_d1)
			*putexcel	A13	=	matrix(FI_still_year_all), names overwritefmt nformat(number_d1)
			*putexcel	A23	=	matrix(FI_newly_year_all), names overwritefmt nformat(number_d1)
			
			*	Figure B2 and B3
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
				
				*	Figure B2
				graph bar still_FI newly_FI	status_unknown, over(year) stack legend(lab (1 "Still FI") lab(2 "Newly FI") lab(3 "Previous status unknown") rows(1))	///
							graphregion(color(white)) bgcolor(white) asyvars bar(1, fcolor(gs11)) bar(2, fcolor(gs6)) bar(3, fcolor(gs1))	///
								ytitle(Fraction of Population)	ylabel(0(.025)0.153)
				graph	export	"${FSD_outFig}/Fig_B2.png", replace
				graph	close
					
				*	Figure B3
					
					*	left panel
					graph bar FI_newly_year_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	ytitle(Population prevalence(%))	ylabel(0(.025)0.1)	///
								legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
								lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
								asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
								bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Newly Food Insecure)	name(Newly_FI, replace) scale(0.8)     
					
					
					*	right panel
					graph bar FI_still_year_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))*/	ylabel(0(.025)0.1)	///
								legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
								lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
								asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
								bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Still Food Insecure)	name(Still_FI, replace)	scale(0.8)  
								
							
				grc1leg Newly_FI Still_FI, rows(1) legendfrom(Newly_FI)	graphregion(color(white)) /*(white)*/
				graph	export	"${FSD_outFig}/Fig_B3.png", replace
				graph	close
			
			restore
				
		}
		
				
		*	Permanent approach	
		{
			
		
			*cap	drop	NMNME_normal
			cap	drop	SFIG
			cap	drop	NME_mean
			cap	drop	NME_total
			cap	drop	NME_threshold_total
			cap	drop	NME_mean_normal
			cap	drop	NME_threshold_mean
			cap	drop	NMNME_normal_mean
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
			*gen NMNME_normal	=.
			
			*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at household-level.
			*	Since households have different number of non-missing PFS and our cut-off probability varies over time, we cannot simply use "mean" function.
			*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
			
			*	Aggregate PFS over time (numerator)
			bys	fam_ID_1999:	egen	NME_total	=	total(NME)	if	inrange(year,2,10)
			
			*	Aggregate cut-off PFS over time. To add only the years with non-missing PFS, we replace the cut-off PFS of missing PFS years as missing.
			replace	NME_threshold=.	if	mi(NME)
			bys	fam_ID_1999:	egen	NME_threshold_total	=	total(NME_threshold)	if	inrange(year,2,10)
			
			*	Generate (normalized) mean-E by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
			gen	NME_mean_normal	=	NME_total	/	NME_threshold_total
			
			*	Construct FIG and SFIG
			cap	drop	FIG_indiv
			cap	drop	SFIG_indiv
			gen	FIG_indiv=.
			gen	SFIG_indiv	=.
					
				
				cap	drop	NME_normal
				gen NME_normal	=.
					
					
				*	Normalized E (E/threshold E)	(Eit/E_underbar_t)
				replace	NME_normal	=	NME	/	NME_threshold
				
				*	Inner term of the food securit gap (FIG) and the squared food insecurity gap (SFIG)
				replace	FIG_indiv	=	(1-NME_normal)^1	if	!mi(NME_normal)	&	NME_normal<1	//	NME<NME_threshold
				replace	FIG_indiv	=	0					if	!mi(NME_normal)	&	NME_normal>=1	//	NME>=NME_threshold
				replace	SFIG_indiv	=	(1-NME_normal)^2	if	!mi(NME_normal)	&	NME_normal<1	//	NME<NME_threshold
				replace	SFIG_indiv	=	0					if	!mi(NME_normal)	&	NME_normal>=1	//	NME>=NME_threshold
			
				
			*	Total, Transient and Chronic FI

			
				*	Total FI	(Average SFIG over time)
				bys	fam_ID_1999:	egen	Total_FI_HCR	=	mean(NME_FI)	if	inrange(year,2,10)	//	HCR
				bys	fam_ID_1999:	egen	Total_FI_SFIG	=	mean(SFIG_indiv)	if	inrange(year,2,10)	//	SFIG
				
				label	var	Total_FI_HCR	"TFI (HCR)"
				label	var	Total_FI_SFIG	"TFI (SFIG)"

				*	Chronic FI (SFIG(with mean E))					
				gen		Chronic_FI_HCR=.
				gen		Chronic_FI_SFIG=.
				replace	Chronic_FI_HCR	=	(1-NME_mean_normal)^0	if	!mi(NME_mean_normal)	&	NME_mean_normal<1		//	Avg E < Avg cut-off E
				replace	Chronic_FI_SFIG	=	(1-NME_mean_normal)^2	if	!mi(NME_mean_normal)	&	NME_mean_normal<1		//	Avg E < Avg cut-off E
				replace	Chronic_FI_HCR	=	0					if	!mi(NME_mean_normal)	&	NME_mean_normal>=1	//	Avg E >= Avg cut-off E (thus zero CFI)
				replace	Chronic_FI_SFIG	=	0					if	!mi(NME_mean_normal)	&	NME_mean_normal>=1	//	Avg E >= Avg cut-off E (thus zero CFI)
				
				lab	var		Chronic_FI_HCR	"CFI (HCR)"
				lab	var		Chronic_FI_SFIG	"CFI (SFIG)"
				
				**** In several households, CFI is greater than TFI. I assume it is because the threshold probability varies, but need to thoroughly check why.
				**** For now, in that case we treat CFI as equal to the TFI
				**** (2021/1/24) Chris said it is OK to have TFI<CFI. Below is his comments from the e-mail sent on Jan 24, 2021
				**** "That said, it’s fine to have CFI>TFI. That’s the very definition of a household that is chronically food insecure but occasionally food secure (i.e., chronically but not persistently food insecure). The poverty dynamics literature includes this as well, as it reflects the headcount basis for the average period-specific (total) food insecurity (TFI) versus the period-average food insecurity (CFI). "
				*replace	Chronic_FI_HCR	=	Total_FI	if	Chronic_FI>Total_FI
				
				*	Transient FI (TFI - CFI)
				gen	Transient_FI_HCR	=	Total_FI_HCR	-	Chronic_FI_HCR
				gen	Transient_FI_SFIG	=	Total_FI_SFIG	-	Chronic_FI_SFIG
						


			*	Restrict sample to non_missing TFI and CFI
			global	nonmissing_TFI_CFI	!mi(Total_FI_HCR)	&	!mi(Chronic_FI_HCR)
			
			*	Descriptive stats
				
				**	For now we include households with 5+ E.
				cap	drop	num_nonmissing_NME
				cap	drop	dyn_sample
				bys fam_ID_1999: egen num_nonmissing_NME=count(NME)
				gen	dyn_sample=1	if	num_nonmissing_NME>=5	&	inrange(year,2,10)
				
				*	For time-variance categories (ex. education, region), we use the first year (2001) value (as John suggested)
				local	timevar_cat	highdegree_NoHS highdegree_HS highdegree_somecol highdegree_col	///
						state_group_NE state_group_MidAt state_group_South state_group_MidWest state_group_West	resid_metro resid_nonmetro
				foreach	type	of	local	timevar_cat		{
					
					gen		`type'_temp	=	1	if	year==2	&	`type'==1
					replace	`type'_temp	=	0	if	year==2	&	`type'!=1	&	!mi(`type')
					replace	`type'_temp	=	.n	if	year==2	&	mi(`type')
					
					cap	drop	`type'_2001
					bys	fam_ID_1999:	egen	`type'_2001	=	max(`type'_temp)
					drop	`type'_temp
					
				}				
				
				*	If 2001 education is missing, use the earliest available education information
				cap	drop	tempyear
				bys fam_ID_1999: egen tempyear = min(year) if (${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1 & mi(highdegree_NoHS_2001))

				foreach edu in NoHS HS somecol col	{
					
					cap	drop	highdegree_`edu'_2001_temp?
					gen	highdegree_`edu'_2001_temp1	=	highdegree_`edu'	if	year==tempyear
					bys fam_ID_1999: egen highdegree_`edu'_2001_temp2	=	max(highdegree_`edu'_2001_temp1) if !mi(tempyear)
					replace	highdegree_`edu'_2001	=	highdegree_`edu'_2001_temp2	if	!mi(tempyear)
					drop	highdegree_`edu'_2001_temp?
				}
				drop	tempyear


				*	Generate statistics for tables
				local	exceloption	replace
				foreach	measure	in	HCR	SFIG	{
				
					*	Overall			
					svy, subpop(if ${study_sample} &	!mi(NME)	& ${nonmissing_TFI_CFI} 	&	dyn_sample==1 ):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_all	=	e(b)[1,2]/e(b)[1,1]
					*scalar	samplesize_all	=	e(N_sub)
					mat	perm_stat_2000_all	=	e(N_sub),	e(b), prop_trans_all
					
					*	Gender
					svy, subpop(if ${study_sample} &	!mi(NME) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	gender_head_fam_enum2==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_male	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_male	=	e(N_sub),	e(b), prop_trans_male
					
					svy, subpop(if ${study_sample} &	!mi(NME) & ${nonmissing_TFI_CFI} 	&	dyn_sample==1 	&	HH_female==1):	///
						mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
					scalar	prop_trans_female	=	e(b)[1,2]/e(b)[1,1]
					mat	perm_stat_2000_female	=	e(N_sub),	e(b), prop_trans_female
					
					mat	perm_stat_2000_gender	=	perm_stat_2000_male	\	perm_stat_2000_female
					
					*	Race
					foreach	type	in	1	0	{
						
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	HH_race_white==`type'):	///
							mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
						scalar	prop_trans_race_`type'	=	e(b)[1,2]/e(b)[1,1]
						mat	perm_stat_2000_race_`type'	=	e(N_sub),	e(b), prop_trans_race_`type'
						
					}
					
					mat	perm_stat_2000_race	=	perm_stat_2000_race_1	\	perm_stat_2000_race_0

					*	Region (based on John's suggestion)
					foreach	type	in	NE	MidAt South MidWest West	{
						
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	state_group_`type'==1	):	///
							mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
						scalar	prop_trans_region_`type'	=	e(b)[1,2]/e(b)[1,1]
						mat	perm_stat_2000_region_`type'	=	e(N_sub),	e(b), prop_trans_region_`type'
						
					}
				
					mat	perm_stat_2000_region	=	perm_stat_2000_region_NE	\	perm_stat_2000_region_MidAt	\	perm_stat_2000_region_South	\	///
													perm_stat_2000_region_MidWest	\	perm_stat_2000_region_West
					
					*	Metropolitan Area
					foreach	type	in	metro	nonmetro	{
						
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	resid_`type'==1):	///
							mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
						scalar	prop_trans_metro_`type'	=	e(b)[1,2]/e(b)[1,1]
						mat	perm_stat_2000_metro_`type'	=	e(N_sub),	e(b), prop_trans_metro_`type'
						
					}
				
					mat	perm_stat_2000_metro	=	perm_stat_2000_metro_metro	\	perm_stat_2000_metro_nonmetro
					
					*	Education degree (Based on 2001 degree)
					foreach	degree	in	NoHS	HS	somecol	col	{
						
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1	&	highdegree_`degree'_2001==1):	///
							mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
						scalar	prop_trans_edu_`degree'	=	e(b)[1,2]/e(b)[1,1]
						mat	perm_stat_2000_edu_`degree'	=	e(N_sub),	e(b), prop_trans_edu_`degree'
						
					}
					
					mat	perm_stat_2000_edu	=	perm_stat_2000_edu_NoHS	\	perm_stat_2000_edu_HS	\	perm_stat_2000_edu_somecol	\	perm_stat_2000_edu_col

					
					 *	Further decomposition
				   cap	mat	drop	perm_stat_2000_decomp_`measure'
				   cap	mat	drop	Pop_ratio
				   svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1):	///
					mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure' 
				   local	subsample_tot=e(N_subpop)		   
				   
				   foreach	race	in	 HH_race_color	HH_race_white	{	//	Black, white
						foreach	gender	in	HH_female	gender_head_fam_enum2	{	//	Female, male
							foreach	edu	in	NoHS	HS	somecol	col   	{	//	No HS, HS, some col, col
								svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	&	dyn_sample==1  & `gender'==1 & `race'==1 & highdegree_`edu'_2001==1): mean Total_FI_`measure' Chronic_FI_`measure' Transient_FI_`measure'	
								local	Pop_ratio	=	e(N_subpop)/`subsample_tot'
								scalar	prop_trans_edu_race_gender	=	e(b)[1,2]/e(b)[1,1]
								mat	perm_stat_2000_decomp_`measure'	=	nullmat(perm_stat_2000_decomp_`measure')	\	`Pop_ratio',	e(b), prop_trans_edu_race_gender
							}	// edu			
						}	//	gender	
				   }	//	race

					
					*	Combine results (Table 6)
					mat	define	blankrow	=	J(1,5,.)
					mat	perm_stat_2000_allcat_`measure'	=	perm_stat_2000_all	\	blankrow	\	perm_stat_2000_gender	\	blankrow	\	perm_stat_2000_race	\	///
													blankrow	\	perm_stat_2000_region	\	blankrow	\	perm_stat_2000_metro	\	blankrow \	///
													perm_stat_2000_edu	//	To be combined with category later.
					mat	perm_stat_2000_combined_`measure'	=	perm_stat_2000_allcat_`measure'	\	blankrow	\	blankrow	\	perm_stat_2000_decomp_`measure'

					*putexcel	set "${FSD_outTab}/perm_stat_NME", sheet(perm_stat_`measure') `exceloption'
					*putexcel	A3	=	matrix(perm_stat_2000_combined_`measure'), names overwritefmt nformat(number_d1)
					
					*esttab matrix(perm_stat_2000_combined_`measure', fmt(%9.3f)) using "${FSD_outTab}/Tab_6_perm_stat_`measure'_NME.tex", replace	
					
					*local	exceloption	modify
				}	//	measure
				
				*	Fig B4
				preserve
				
					clear
					
					set	obs	16
					gen		race_gender	=	1	in	1/4
					replace	race_gender	=	2	in	5/8
					replace	race_gender	=	3	in	9/12
					replace	race_gender	=	4	in	13/16
					
					label	define	race_gender	1	"Non-White/Female"	2	"Non-White/Male"	3	"White/Female"	4	"White/Male",	replace
					label	values	race_gender	race_gender
					
					gen		education	=	mod(_n,4)
					replace	education	=	4	if	education==0
					
					label	define	education	1	"Less than High School"	2	"High School"	3	"Some College"	4	"College",	replace
					label	values	education	education
					
					gen	edu_fig5	=	_n
					
					//	Currently we use the value for the proportion of each category from the pre-calculated value. It would be better if we can automatically update it as analyses are updated.
					label	define	edu_fig5	1	"Less than High School (2%)"	2	"High School (2.4%)"	3	"Some College (1.4%)"	4	"College (0.6%)"	///
												5	"Less than High School (0.8%)"	6	"High School (2.7%)"	7	"Some College (2.7%)"	8	"College (1.9%)"	///
												9	"Less than High School (1.5%)"	10	"High School (5.6%)"	11	"Some College (4.6%)"	12	"College (4%)"		///
												13	"Less than High School (4.7%)"	14	"High School (21.4%)"	15	"Some College (16.3%)"	16	"College (27.5%)",	replace
					label	values	edu_fig5	edu_fig5
					
				
					
					svmat	perm_stat_2000_decomp_HCR
					rename	perm_stat_2000_decomp_HCR?	(pop_ratio	TFI	CFI	TFF_minus_CFI	ratio_CFI_TFI)
					
					*	Figure 5
					graph hbar TFI CFI, over(edu_fig5, sort(education) descending	label(labsize(vsmall)))	over(race_gender, descending	label(labsize(vsmall) angle(vertical)))	nofill	///	/*	"nofill" option is needed to drop missing categories
										legend(lab (1 "Total Food Insecurity (TFI)") lab(2 "Chronic Food Insecurity (CFI)") size(vsmall) rows(1))	bar(1, fcolor(gs3*0.5)) bar(2, fcolor(gs12*0.6))	graphregion(color(white)) bgcolor(white)
					graph	export	"${FSD_outFig}/Fig_B4_TFI_CFI_bygroup_E.png", replace
					graph	close
					
						
				restore
				
				
				
				*	Categorize HH into four categories
				*	First, generate dummy whether (1) always or not-always FI (2) Never or sometimes FI
					loc	var1	NME_FI_always
					loc	var2	NME_FI_never
					cap	drop	`var1'
					cap	drop	`var2'
					bys	fam_ID_1999:	egen	`var1'	=	min(NME_FI)	//	1 if always FI (persistently poor), 0 if sometimes FS (not persistently poor)
					bys	fam_ID_1999:	egen	`var2'	=	min(NME_FS)	//	1 if never FI, 0 if sometimes FI (transient)
					replace	`var1'=.	if	year==1
					replace	`var2'=.	if	year==1
				
				local	exceloption	modify
				foreach	measure	in	HCR	/*SFIG*/	{
					
					assert	Total_FI_`measure'==0 if NME_FI_never==1	//	Make sure TFI=0 when HH is always FS (E>cut-off E)
					
					*	Categorize households
					cap	drop	NME_perm_FI_`measure'
					gen		NME_perm_FI_`measure'=1	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	NME_FI_always==1	///
						//	Persistently FI (CFI>0, always FI)
					replace	NME_perm_FI_`measure'=2	if	Chronic_FI_`measure'>0	&	!mi(Chronic_FI_`measure')	&	NME_FI_always==0	///
						//	Chronically but not persistently FI (CFI>0, not always FI)
					replace	NME_perm_FI_`measure'=3	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	NME_FI_never==0		///
						//	Transiently FI (CFI=0, not always FS)
					replace	NME_perm_FI_`measure'=4	if	Chronic_FI_`measure'==0	&	!mi(Chronic_FI_`measure')	&	Total_FI_`measure'==0	///
						//	Always FS (CFI=TFI=0)
						
					label	define	NME_perm_FI	1	"Persistently FI"	///
												2	"Chronically, but not persistently FI"	///
												3	"Transiently FI"	///
												4	"Never FI"	///
												,	replace
				
					label values	NME_perm_FI_`measure'	NME_perm_FI
					
				*	Descriptive stats
				
					*	Overall
					svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): proportion	NME_perm_FI_`measure'
					mat	E_perm_FI_all	=	e(N_sub),	e(b)
					
					*	Gender
					svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	gender_head_fam_enum2):	///
						proportion NME_perm_FI_`measure'
					mat	E_perm_FI_male	=	e(N_sub),	e(b)
					svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_female):	///
						proportion NME_perm_FI_`measure'
					mat	E_perm_FI_female	=	e(N_sub),	e(b)
					
					mat	E_perm_FI_gender	=	E_perm_FI_male	\	E_perm_FI_female
					
				
					*	Race
					foreach	type	in	1	0	{
						
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	HH_race_white==`type'):	///
							proportion NME_perm_FI_`measure'
						mat	E_perm_FI_race_`type'	=	e(N_sub),	e(b)
						
					}
					
					mat	E_perm_FI_race	=	E_perm_FI_race_1	\	E_perm_FI_race_0
					
					*	Region
					foreach	type	in	NE	MidAt	South	MidWest West	{
						
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	state_group_`type'==1):	///
							proportion NME_perm_FI_`measure'
						mat	E_perm_FI_region_`type'	=	e(N_sub),	e(b)
						
					}
					
					mat	E_perm_FI_region	=	E_perm_FI_region_NE	\	E_perm_FI_region_MidAt	\	E_perm_FI_region_South	\	///
												E_perm_FI_region_MidWest	\	E_perm_FI_region_West
					
					*	Metropolitan
					foreach	type	in	metro	nonmetro	{
						
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	resid_`type'==1):	///
							proportion NME_perm_FI_`measure'
						mat	E_perm_FI_metro_`type'	=	e(N_sub),	e(b)
						
					}
					
					mat	E_perm_FI_metro	=	E_perm_FI_metro_metro	\	E_perm_FI_metro_nonmetro
					
					
					*	Education
					foreach	degree	in	NoHS	HS	somecol	col	{
						
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1	&	highdegree_`degree'_2001==1):	///
							proportion NME_perm_FI_`measure'
						mat	E_perm_FI_edu_`degree'	=	e(N_sub),	e(b)
						
					}
					mat	E_perm_FI_edu	=	E_perm_FI_edu_NoHS	\	E_perm_FI_edu_HS	\	E_perm_FI_edu_somecol	\	E_perm_FI_edu_col
					

					*	Combine results (Table 9 of 2020/11/16 draft)
					mat	define	blankrow	=	J(1,5,.)
					mat	E_perm_FI_combined_`measure'	=	E_perm_FI_all	\	blankrow	\	E_perm_FI_gender	\	blankrow	\	E_perm_FI_race	\	blankrow	\	///
															E_perm_FI_region	\	blankrow	\	E_perm_FI_metro	\	blankrow	\	E_perm_FI_edu
					
					mat	list	E_perm_FI_combined_`measure'
					
					*di "excel option is `exceloption'"
					*putexcel	set "${FSD_outTab}/perm_stat", sheet(FI_perm_`measure') `exceloption'
					*putexcel	A3	=	matrix(E_perm_FI_combined_`measure'), names overwritefmt nformat(number_d1)
				
					*esttab matrix(E_perm_FI_combined_`measure', fmt(%9.2f)) using "${FSD_outTab}/NME_perm_FI_`measure'.tex", replace	
					
					*	Table B4
					mat	define Table_B4_`measure'_E	=	perm_stat_2000_allcat_`measure',	E_perm_FI_combined_`measure'[.,2...]
					
					putexcel	set "${FSD_outTab}/Tab_B4", sheet(Table_B4_`measure'_E) replace
					putexcel	A3	=	matrix(Table_B4_`measure'_E), names overwritefmt nformat(number_d1)
				
					esttab matrix(Table_B4_`measure'_E, fmt(%9.3f)) using "${FSD_outTab}/Tab_B4.tex", replace
		
					
				}	//	measure
			
				
			
			
			*	Group State-FE of TFI and CFI		
				
				
				local measure HCR
				
				foreach	depvar	in	Total_FI_`measure'	Chronic_FI_`measure'	Transient_FI_`measure'	{
					
					
					*	Without controls/time FE
					qui	svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' ${regionvars}
					est	store	`depvar'_nocontrols
					
					
					*	With controls/time FE
					qui	svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1): regress `depvar' ${regionvars}	///
						${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}
					est	store	`depvar'
				}
				
				/*
				*	Output
				esttab	Total_FI_`measure'_nocontrols	Chronic_FI_`measure'_nocontrols	Transient_FI_`measure'_nocontrols Total_FI_`measure'	Chronic_FI_`measure'	Transient_FI_`measure'	using "${FSD_outTab}/TFI_CFI_regression_E.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
						title(Regression of TFI/CFI on Characteristics) 	///
						addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
						replace
						
				esttab	Total_FI_`measure'	Chronic_FI_`measure'		using "${FSD_outTab}/TFI_CFI_regression_E.tex", ///
						cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	///
						title(Regression of TFI/CFI on Characteristics) 	///
						addnotes(Sample includes household responses from 2001 to 2017. Base household is as follows; Household head is white/single/male/unemployed/not disabled/without spouse or partner or cohabitor. Households with negative income.)	///
							
				*/
			
				*	Shapley Decomposition
			
					
					ds	state_group?	state_group1?	state_group2?
					local groupstates `r(varlist)'		
					
					foreach	depvar	in	Total_FI_`measure'	Chronic_FI_`measure'	{
						
						*	Unadjusted
						cap	drop	_mysample
						regress `depvar' 	${demovars}		${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	///
										${foodvars}		${changevars}	 ${regionvars}	${timevars}	///
										if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1
						shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head	mental_problem no_longer_employed	no_longer_married	no_longer_own_house	became_disabled) 
						
						mat	`depvar'_shapley_indiv	=	e(shapley),	e(shapley_rel)
						mata : st_matrix("`depvar'_shapley_sum", colsum(st_matrix("`depvar'_shapley_indiv")))
						
						mat	`depvar'_shapley	=	`depvar'_shapley_indiv	\	`depvar'_shapley_sum
						
						
						*	Survey-adjusted
						cap	drop	_mysample
						svy, subpop(if ${study_sample} &	!mi(NME)	&	 ${nonmissing_TFI_CFI} 	& dyn_sample==1):	///
							regress `depvar'  	${demovars}		${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	///
									${foodvars}		${changevars}	 ${regionvars}	${timevars}
						shapley2, stat(r2) force group(`groupstates', highdegree_NoHS highdegree_somecol highdegree_col,age_head_fam age_head_fam_sq, HH_female, HH_race_black HH_race_other,marital_status_cat,ln_income_pc,food_stamp_used_1yr	child_meal_assist WIC_received_last	elderly_meal,num_FU_fam ratio_child emp_HH_simple phys_disab_head	mental_problem no_longer_employed	no_longer_married	no_longer_own_house	became_disabled)
						
						*	For some reason, Shapely decomposition does not work properly under the adjusted regression model (they don't sum up to 100%)
						*mat	`depvar'_shapley_indiv	=	e(shapley),	e(shapley_rel)
						*mata : st_matrix("`depvar'_shapley_sum", colsum(st_matrix("`depvar'_shapley_indiv")))
						
						*mat	`depvar'_shapley	=	`depvar'_shapley_indiv	\	`depvar'_shapley_sum
					
					}	//	depvar			
				
				
				mat	TFI_CFI_`measure'_shapley	=	Total_FI_`measure'_shapley,	Chronic_FI_`measure'_shapley
				
				putexcel	set "${FSD_outTab}/Tab_B5", sheet(shapley) replace	
				putexcel	A3	=	matrix(TFI_CFI_`measure'_shapley), names overwritefmt nformat(number_d1)
				
				esttab matrix(TFI_CFI_`measure'_shapley, fmt(%9.3f)) using "${FSD_outTab}/Tab_B5.tex", replace	
			

				/*
				*	Northeast & Mid-Atlantic
					
					coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI_`measure'	Chronic_FI_`measure', keep(state_group1	state_group2	state_group3	state_group4	state_group5)	xline(0)	graphregion(color(white)) bgcolor(white)	///
											title(Northeast and Mid-Atlantic)	name(TFI_CFI_FE_NE_MA, replace) /*xscale(range(-0.05(0.05) 0.10))*/
					graph	export	"${FSD_outFig}/TFI_CFI_groupstateFE_NE.png", replace
					graph	close

				/*
				*	Mid-Atlantic
					coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI	Chronic_FI, keep(state_group2	state_group3	state_group4	state_group5)	xline(0)	graphregion(color(white)) bgcolor(white)	///
											title(TFI_CFI_Mid_Atlantic)	name(TFI_CFI_FE_MA, replace)	xscale(range(-0.05(0.05) 0.10))
					graph	export	"${PSID_outRaw}/TFI_CFI_groupstateFE_MA.png", replace
					graph	close
				*/
				
				*	South
					coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI_`measure'	Chronic_FI_`measure', keep(state_group6 state_group7 state_group8 state_group9 state_group10 state_group11)		xline(0)	graphregion(color(white)) bgcolor(white)	///
											title(South)	name(TFI_CFI_FE_South, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
					graph	export	"${FSD_outFig}/TFI_CFI_groupstateFE_South.png", replace
					graph	close
					
				*	Mid-West
					coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI_`measure'	Chronic_FI_`measure', keep(state_group12 state_group13 state_group14 state_group15 state_group16 state_group17)		xline(0)	graphregion(color(white)) bgcolor(white)	///
											title(Mid-West)	name(TFI_CFI_FE_MW, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
					graph	export	"${FSD_outFig}/TFI_CFI_groupstateFE_MW.png", replace
					graph	close
				
				*	West
					coefplot	/*Total_FI_nocontrols	Chronic_FI_nocontrols*/	Total_FI_`measure'	Chronic_FI_`measure', keep(state_group18 state_group19 state_group20 state_group21)		xline(0)	graphregion(color(white)) bgcolor(white)	///
											title(West)		name(TFI_CFI_FE_West, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
					graph	export	"${FSD_outFig}/TFI_CFI_groupstateFE_West.png", replace
					graph	close
			*/
				
			/*
			coefplot	Total_FI_`measure'_nocontrols	Chronic_FI_`measure'_nocontrols, 	///
						keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)	///
						xline(0)	graphregion(color(white)) bgcolor(white)	/*title(Regional Fixed Effects)*/	legend(lab (2 "TFI") lab(4 "CFI") /*size(vsmall)*/ rows(1))	name(TFI_CFI_FE_All, replace)	/*xscale(range(-0.05(0.05) 0.10))*/
					graph	export	"${FSD_outFig}/TFI_CFI_`measure'_groupstateFE_All_nocontrol_E.png", replace
					graph	close
			*/
			
			coefplot	(Total_FI_`measure', mcolor(gs2) msymbol(diamond))	(Chronic_FI_`measure', mcolor(gs9)	msymbol(circle)), 	///
						keep(state_group1 state_group2	state_group3	state_group4	state_group5	state_group6	state_group7	state_group8	state_group9 state_group1? state_group2?)	///
						xline(0)	graphregion(color(white)) bgcolor(white)	legend(lab (2 "TFI") lab(4 "CFI") rows(1))	name(TFI_CFI_FE_All, replace)	ylabel(,labsize(small))	/*xscale(range(-0.05(0.05) 0.10))*/
					graph	export	"${FSD_outFig}/Fig_B5.png", replace
					graph	close
				
			/*
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
			*/
			
			
		}
	
		*	Groupwise Decomposition
		
		{
		
		
		*	Limit the sample to non-missing observations in ALL categories (gender, race, education, region)
		*	It is because when we use "subpop()" option in "svy:" prefix, the command includes missing values outside the defined subpopulation in the population estimate (number of obs)
		*	For example, let's say the variable "race" has missing values, both for male and female.
		*	If we use "svy: tab race", the number of population includes only the observations with non-missing race values.
		*	However, if we use "svy, subpop(if male==1): tab race", the the number of observations includes observations with non-missing race values AND missing race values in "female==1"
			* More details: https://www.stata.com/statalist/archive/2010-03/msg01263.html, https://www.stata.com/statalist/archive/2010-03/msg01264.html
		*	This can be remedied by restricting subpopulation to observations with non-missing values in all categories of interest.
		global	nonmissing_FGT	!mi(NME_FI) & !mi(FIG_indiv) & !mi(SFIG_indiv)
					
		
		foreach	group	in	all	male	female	white	black	other	NoHS	HS	somecol	col	NE	MidAt	South	MidWest	West metro nonmetro	{
			cap	mat	drop	sampleno_`group'	HCR_`group'	FIG_`group'	SFIG_`group'
		}
		
		
			*	Yearly decomposition
			forval	year=2/10	{
				
				
				*	Overall
					
				svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
				mat	sampleno_all	=	nullmat(HCR_all),	e(N_sub)
				mat	HCR_all			=	nullmat(HCR_all),	e(b)[1,1]
				mat	FIG_all			=	nullmat(FIG_all),	e(b)[1,2]
				mat	SFIG_all		=	nullmat(SFIG_all),	e(b)[1,3]

				*	Gender
					
					*	Male
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	&	${nonmissing_FGT} & HH_female==0	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_male	=	nullmat(sampleno_male),	e(N_sub)
					mat	HCR_male		=	nullmat(HCR_male),	e(b)[1,1]
					mat	FIG_male		=	nullmat(FIG_male),	e(b)[1,2]
					mat	SFIG_male		=	nullmat(SFIG_male),	e(b)[1,3]
					
					*	Female
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	&	${nonmissing_FGT} & HH_female==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_female	=	nullmat(sampleno_female),	e(N_sub)
					mat	HCR_female		=	nullmat(HCR_female),	e(b)[1,1]
					mat	FIG_female		=	nullmat(FIG_female),	e(b)[1,2]
					mat	SFIG_female		=	nullmat(SFIG_female),	e(b)[1,3]
					
				*	Race
				  
					*	White
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_white==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_white	=	nullmat(sampleno_white),	e(N_sub)
					mat	HCR_white		=	nullmat(HCR_white),	e(b)[1,1]
					mat	FIG_white		=	nullmat(FIG_white),	e(b)[1,2]
					mat	SFIG_white		=	nullmat(SFIG_white),	e(b)[1,3]
					
					*	Black
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_black==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_black	=	nullmat(sampleno_black),	e(N_sub)
					mat	HCR_black		=	nullmat(HCR_black),	e(b)[1,1]
					mat	FIG_black		=	nullmat(FIG_black),	e(b)[1,2]
					mat	SFIG_black		=	nullmat(SFIG_black),	e(b)[1,3]
					
					*	Other
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_race_other==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_other	=	nullmat(sampleno_other),	e(N_sub)
					mat	HCR_other		=	nullmat(HCR_other),	e(b)[1,1]
					mat	FIG_other		=	nullmat(FIG_other),	e(b)[1,2]
					mat	SFIG_other		=	nullmat(SFIG_other),	e(b)[1,3]	
					
				*	Education
				
					*	Less than High School
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_NoHS==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_NoHS	=	nullmat(sampleno_NoHS),	e(N_sub)
					mat	HCR_NoHS		=	nullmat(HCR_NoHS),	e(b)[1,1]
					mat	FIG_NoHS		=	nullmat(FIG_NoHS),	e(b)[1,2]
					mat	SFIG_NoHS		=	nullmat(SFIG_NoHS),	e(b)[1,3]
					
					*	High School
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_HS==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_HS	=	nullmat(sampleno_HS),	e(N_sub)
					mat	HCR_HS		=	nullmat(HCR_HS),	e(b)[1,1]
					mat	FIG_HS		=	nullmat(FIG_HS),	e(b)[1,2]
					mat	SFIG_HS		=	nullmat(SFIG_HS),	e(b)[1,3]
					
					*	Some College
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_somecol==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_somecol	=	nullmat(sampleno_somecol),	e(N_sub)
					mat	HCR_somecol		=	nullmat(HCR_somecol),	e(b)[1,1]
					mat	FIG_somecol		=	nullmat(FIG_somecol),	e(b)[1,2]
					mat	SFIG_somecol		=	nullmat(SFIG_somecol),	e(b)[1,3]
					
					*	College
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& highdegree_col==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_col	=	nullmat(sampleno_col),	e(N_sub)
					mat	HCR_col		=	nullmat(HCR_col),	e(b)[1,1]
					mat	FIG_col		=	nullmat(FIG_col),	e(b)[1,2]
					mat	SFIG_col		=	nullmat(SFIG_col),	e(b)[1,3]
				
				*	Region (based on John's suggestion)
					
					foreach	stategroup	in	NE	MidAt	South	MidWest	West	{
						
						svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& state_group_`stategroup'==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
						mat	sampleno_`stategroup'	=	nullmat(sampleno_`stategroup'),	e(N_sub)
						mat	HCR_`stategroup'		=	nullmat(HCR_`stategroup'),	e(b)[1,1]
						mat	FIG_`stategroup'		=	nullmat(FIG_`stategroup'),	e(b)[1,2]
						mat	SFIG_`stategroup'		=	nullmat(SFIG_`stategroup'),	e(b)[1,3]
						
					}
					
					
				*	Metropolitan Area
				 
					*	Metro
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& resid_metro==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_metro	=	nullmat(sampleno_metro),	e(N_sub)
					mat	HCR_metro		=	nullmat(HCR_metro),	e(b)[1,1]
					mat	FIG_metro		=	nullmat(FIG_metro),	e(b)[1,2]
					mat	SFIG_metro		=	nullmat(SFIG_metro),	e(b)[1,3]
					
					*	Non-metro
					svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& resid_nonmetro==1	&	year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
					mat	sampleno_nonmetro	=	nullmat(sampleno_nonmetro),	e(N_sub)
					mat	HCR_nonmetro		=	nullmat(HCR_nonmetro),	e(b)[1,1]
					mat	FIG_nonmetro		=	nullmat(FIG_nonmetro),	e(b)[1,2]
					mat	SFIG_nonmetro		=	nullmat(SFIG_nonmetro),	e(b)[1,3]
				
				   
			}
			
			mat	define	blankrow_1by9	=	J(1,9,.)
			mat list blankrow_1by9
			foreach measure in HCR FIG SFIG	{
				
				cap	mat	drop	`measure'_year_combined
				mat	`measure'_year_combined	=	`measure'_all	\	blankrow_1by9	 \	`measure'_male	\	`measure'_female	\	blankrow_1by9	 \	///
											 	`measure'_white	\	`measure'_black	\	`measure'_other	\	blankrow_1by9 	 \		`measure'_NoHS	 \	///
												 `measure'_HS	\	`measure'_somecol	\	`measure'_col	\	blankrow_1by9	\	///
												 `measure'_NE	\	`measure'_MidAt	\	`measure'_South	\	`measure'_MidWest	\	`measure'_West	\	blankrow_1by9	\	///
												 `measure'_metro	\	`measure'_nonmetro
				
			}
			cap	mat	drop	FGT_year_combined
			mat	FGT_year_combined	=	blankrow_1by9	\	HCR_year_combined	\	blankrow_1by9	\	blankrow_1by9	\	FIG_year_combined	\	blankrow_1by9	\	blankrow_1by9	\	SFIG_year_combined
			
			*putexcel	set "${PSID_outRaw}/FGT_bygroup_E", sheet(year) replace	/*modify*/
			*putexcel	A3	=	matrix(FGT_year_combined), names overwritefmt nformat(number_d1)
			
			*esttab matrix(perm_stat_2000_combined, fmt(%9.4f)) using "${PSID_outRaw}/perm_stat_combined.tex", replace
			
		   *	Categorical decomposition
		   *	Input for Figure 3 in Dec 2020 draft (Food Insecurity Prevalence and Severity by Group).
			*	Data and Graph can be found in "FGT_group" sheet in "Min_report" Excel file.
		  
		   *	Generate group-level aggregates.
		   *	We need to do it twice - one for main graph and one for supplement graph. The latter use more detailed educational category.
		   
		   *	Total population size, which is needed to get the share of each sub-group population to total population later
			qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT}): mean NME_FI FIG_indiv	SFIG_indiv
			local	sample_popsize_total=e(N_subpop)
		   
		   
				*	Main graph
				cap	mat	drop	Pop_ratio_all
				cap	mat	drop	HCR_cat	FIG_cat	SFIG_cat
				cap mat drop	HCR_weight_cat	FIG_weight_cat	SFIG_weight_cat
				cap	mat	drop	HCR_weight_cat_all	FIG_weight_cat_all	SFIG_weight_cat_all

			   /*foreach	edu	in	1	2	3	4	{	//	No HS, HS, some col, col*/
			   foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
					foreach	race	in	0	1	{	//	People of colors, white
						foreach	gender	in	1	0	{	//	Female, male
							
							*	FGT measures across all years (Figure 3 in Dec 2020 draft)
							
							qui svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	///
								mean NME_FI FIG_indiv	SFIG_indiv
							
							local	Pop_ratio_all	=	e(N_subpop)/`sample_popsize_total'	//	Share of sub-group pop to total pop.
							mat		Pop_ratio_all	=	nullmat(Pop_ratio_all)	\	`Pop_ratio_all'
							mat	HCR_cat			=	nullmat(HCR_cat)	\	e(b)[1,1]
							mat	FIG_cat			=	nullmat(FIG_cat)	\	e(b)[1,2]
							mat	SFIG_cat		=	nullmat(SFIG_cat)	\	e(b)[1,3]
							
							*	Weighted average for stacked bar graph, by year					
							
							forval	year=2/10	{
								
								*	Generate population size estimate of the sample, which will be used to calculate weighted average.
								qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT} & year==`year'): mean NME_FI FIG_indiv	SFIG_indiv
								local	sample_popsize_year=e(N_subpop)
								
								*	Estimate FGT measures
								qui	svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'	&	year==`year'):	///
									mean NME_FI FIG_indiv	SFIG_indiv
									
								local	Pop_ratio	=	e(N_subpop)/`sample_popsize_year'
								local	HCR_weighted_`year'		=	e(b)[1,1]*`Pop_ratio'
								local	FIG_weighted_`year'		=	e(b)[1,2]*`Pop_ratio'
								local	SFIG_weighted_`year'	=	e(b)[1,3]*`Pop_ratio'
								macro list _HCR_weighted_`year'
								
								mat	HCR_weight_cat	=	nullmat(HCR_weight_cat),	`HCR_weighted_`year''
								mat	FIG_weight_cat	=	nullmat(FIG_weight_cat),	`FIG_weighted_`year''
								mat	SFIG_weight_cat	=	nullmat(SFIG_weight_cat),	`SFIG_weighted_`year''	
				
							}	//	year
							
							mat	HCR_weight_cat_all	=	nullmat(HCR_weight_cat_all)	\	HCR_weight_cat
							mat	FIG_weight_cat_all	=	nullmat(FIG_weight_cat_all)	\	FIG_weight_cat
							mat	SFIG_weight_cat_all	=	nullmat(SFIG_weight_cat_all)	\	SFIG_weight_cat
							
							cap	mat	drop	HCR_weight_cat	FIG_weight_cat	SFIG_weight_cat
							
						}	// gender			
					}	//	race	
			   }	//	edu
			   
				cap	mat	drop	FGT_cat_combined
				mat	FGT_cat_combined	=	Pop_ratio_all,	HCR_cat,	FIG_cat,	SFIG_cat
				
				
				*	Supplementary graph - use 4 educational categories, across all years, no weighted
				cap	mat	drop	Pop_ratio_all_sup	HCR_cat_sup	FIG_cat_sup	SFIG_cat_sup	
				
				 foreach	edu	in	1	2	3	4	{	//	No HS, HS, some col, col
			   /*foreach	edu	in	1	0	{	//	HS or below, beyond HS*/	   
					foreach	race	in	0	1	{	//	People of colors, white
						foreach	gender	in	1	0	{	//	Female, male
							
							*	FGT measures across all years
							
							qui svy, subpop(if ${study_sample} & ${nonmissing_FGT}	& HH_female==`gender' & HH_race_white==`race' & grade_comp_cat==`edu'):	///
								mean NME_FI FIG_indiv	SFIG_indiv
							
							local	Pop_ratio_all_sup	=	e(N_subpop)/`sample_popsize_total'	//	Share of sub-group pop to total pop.
							mat		Pop_ratio_all_sup	=	nullmat(Pop_ratio_all_sup)	\	`Pop_ratio_all_sup'
							mat	HCR_cat_sup			=	nullmat(HCR_cat_sup)	\	e(b)[1,1]
							mat	FIG_cat_sup			=	nullmat(FIG_cat_sup)	\	e(b)[1,2]
							mat	SFIG_cat_sup		=	nullmat(SFIG_cat_sup)	\	e(b)[1,3]
							
						}	// gender			
					}	//	race	
			   }	//	edu
			   
				cap	mat	drop	FGT_cat_combined_sup
				mat	FGT_cat_combined_sup	=	Pop_ratio_all_sup,	HCR_cat_sup,	FIG_cat_sup,	SFIG_cat_sup
				
			   /*
				putexcel	set "${PSID_outRaw}/FGT_bygroup_E", sheet(categorical) /*replace*/	modify
				putexcel	A3	=	matrix(FGT_cat_combined), names overwritefmt nformat(number_d1)			//	HCR, FIG and SFIG by different groups (across all years)
				putexcel	A14	=	matrix(HCR_weight_cat_all), names overwritefmt nformat(number_d1)		//	HCR by different groups by each year. Input for Fig 8a
				putexcel	A24	=	matrix(FIG_weight_cat_all), names overwritefmt nformat(number_d1)		//	FIG by different groups by each year.	Input for Fig A5
				putexcel	A34	=	matrix(SFIG_weight_cat_all), names overwritefmt nformat(number_d1)		//	SFIG by different groups by each year.	Input for Fig 8b
				putexcel	M3	=	matrix(FGT_cat_combined_sup), names overwritefmt nformat(number_d1)	//	Input for Fig 7 "Food Insecurity Prevalence and Severity by Group"
				*/
				
			*	Figure B6
			preserve
			
				clear
				
				set	obs	16
				
				*	Generate category variable 
				gen	fig7_cat	=	_n
				
					//	Currently we use the value for the proportion of each category from the pre-calculated value. It would be better if we can automatically update it as analyses are updated.
				label	define	fig7_cat	1	"NoHS/NonWhite/Female (1.6%)"		2	"NoHS/NonWhite/Male (0.8%)"		3	"NoHS/White/Female (1.2%)"		4	"NoHS/White/Male (4%)"	///
											5	"HS/NonWhite/Female (2.4%)"			6	"HS/NonWhite/Male (2.5%)"		7	"HS/White/Female (5%)"			8	"HS/White/Male (21%)"	///
											9	"SomeCol/NonWhite/Female (1.4%)"	10	"SomeCol/NonWhite/Male (2.6%)"	11	"SomeCol/White/Female (5%)"		12	"SomeCol/White/Male (15.8%)"		///
											13	"Sol/NonWhite/Female (0.9%)"		14	"Col/NonWhite/Male (2.2%)"		15	"Col/White/Female (4.4%)"		16	"Col/White/Male (29.2%)",	replace
				label	values	fig7_cat	fig7_cat
				
				
				*	Generate category variable for Fig 8 and A5
				
				
				svmat	FGT_cat_combined_sup
				rename	FGT_cat_combined_sup?	(pop_ratio	HCR	FIG	SFIG)
				
				*	Figure 7	(Food Insecurity Prevalence and Severity by Group)
				graph hbar HCR SFIG, over(fig7_cat, sort(HCR) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "HCR") lab(2 "SFIG") size(small) rows(1))	///
							bar(1, fcolor(gs03*0.5)) bar(2, fcolor(gs10*0.6))	graphregion(color(white)) bgcolor(white)
				graph	export	"${FSD_outFig}/Fig_B6.png", replace
				graph	close
				
				/*
				*	Figure A5-a	(Food Insecurity Prevalence and Severity by Group - FIG)
				graph hbar FIG, over(fig7_cat, sort(FIG) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "FIG") size(small) rows(1))	///
							bar(1, fcolor(yellow*0.5)) /*bar(2, fcolor(green*0.6))*/	graphregion(color(white)) bgcolor(white)	title((a) FI Severity by Group) ytitle(FIG) name(FIG_bygroup)
				graph	export	"${PSID_outRaw}/FGT_group_decomposition_FIG.png", replace
				graph	close
				*/
			
			restore
			
			*	Figure B7
			
			preserve
			
				clear
			
				set	obs	9
				gen	year	=	_n
				replace	year	=	1999	+	(2*year)
				
				*	Input matrices
				**	Input matrices (HCR_weight_cat_all, FIG_weight_cat_all,	SFIG_weight_cat_all) have years in column and category as row, so they need to be transposed)
				foreach	FGT_category	in	HCR_weight_cat_all FIG_weight_cat_all	SFIG_weight_cat_all{
					
					mat		`FGT_category'_tr=`FGT_category''
					svmat 	`FGT_category'_tr
				}
				
			
				
				*	Figure B7a	(HCR)
				graph bar HCR_weight_cat_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))	ylabel(0(.025)0.1)*/	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
							asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Headcount Ratio)	name(Fig8_HCR, replace) scale(0.8)     

							
				*	Figure B7b	(SFIG)
				graph bar SFIG_weight_cat_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))	ylabel(0(.025)0.1)*/	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
							asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Squared Food Insecurity Gap)	name(Fig8_SFIG, replace) scale(0.8)   
							
				*	Figure B7 (Food Security Status By Group and Yea)
				grc1leg Fig8_HCR Fig8_SFIG, rows(2) legendfrom(Fig8_HCR)	graphregion(color(white)) /*(white)*/
				graph	export	"${FSD_outFig}/Fig_B7.png", replace
				graph	close
				
				/*
				
				*	Figure A5	(Food Insecurity Status (FIG) by Group and Year)
				graph bar FIG_weight_cat_all_tr?, over(year, label(labsize(tiny))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))	ylabel(0(.025)0.1)*/	///
							legend(lab (1 "HS/Non-White/Female (4.1%)") lab(2 "HS/Non-White/Male (3.3%)") lab(3 "HS/White/Female (6.1%)")	lab(4 "HS/White/Male (25%)") 	///
							lab (5 "Col/Non-White/Female (2.3%)") lab(6 "Col/Non-White/Male (4.8%)") lab(7 "Col/White/Female (9.5%)")	lab(8 "Col/White/Male (45%)") size(vsmall) rows(3))	///
							asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	/*title((b) By Group and Year)*/	name(FigA5_b, replace) scale(0.8) 
				graph	export	"${FSD_outFig}/Fig_A5_FGT_group_change_FIG_E.png", replace
				graph	close
				
				*/
				
			restore
				
				
		*	Food Security Prevalence over different groups	(Table 8)
		cap	mat	drop	HCR_group_PFS_3 HCR_group_PFS_7 HCR_group_PFS_10 HCR_group_PFS_all

		
		foreach year in	3	7	10	{	// 2003, 2011, 2017
		   foreach	edu	in	1	0	{	//	HS or below, beyond HS	   
				foreach	race	in	0	1	{	//	People of colors, white
					foreach	gender	in	1	0	{	//	Female, male
							
					*	FS prevalence
							
					qui svy, subpop(if ${study_sample} & year==`year'	&	HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	mean NME_FI 
							
					mat	HCR_group_PFS_`year'	=	nullmat(HCR_group_PFS_`year')	\	e(b)[1,1]
					
					/*
					if	inlist(`year',3,10)	{
						
						qui svy, subpop(if ${study_sample} & year==`year'	&	HH_female==`gender' & HH_race_white==`race' & highdegree_HSorbelow==`edu'):	mean HFSM_FI 
						
						mat	HCR_group_HFSM_`year'	=	nullmat(HCR_group_HFSM_`year')	\	e(b)[1,1]
						
					}
					*/								
					}	// gender			
				}	//	race	
		   }	//	edu	 
		   
		   *	Overall prevalence (should be equal to the HFSM prevalence)
		   		
			qui svy, subpop(if ${study_sample} & year==`year'):	mean NME_FI 
			mat	HCR_group_PFS_`year'	=	nullmat(HCR_group_PFS_`year')	\	e(b)[1,1]
			
			/*
			if	inlist(`year',3,10)	{
				qui svy, subpop(if ${study_sample} & year==`year'):	mean HFSM_FI 
			}
			mat	HCR_group_HFSM_`year'	=	nullmat(HCR_group_HFSM_`year')	\	e(b)[1,1]
			*/
			
		}	// year
		
		mat	HCR_group_PFS_all	=	HCR_group_PFS_3,	HCR_group_PFS_7,	HCR_group_PFS_10
		//mat	HCR_group_HFSM_all	=	HCR_group_HFSM_3,	HCR_group_HFSM_10
		
		putexcel	set "${FSD_outTab}/Tab_B6", sheet(HCR_desc) /*replace*/	modify
		putexcel	A3	=	matrix(HCR_group_PFS_all), names overwritefmt nformat(number_d1)
		//putexcel	F3	=	matrix(HCR_group_HFSM_all), names overwritefmt nformat(number_d1)
			
		esttab matrix(HCR_group_PFS_all, fmt(%9.2f)) using "${FSD_outTab}/Tab_B6.tex", replace
		
	}
				

	