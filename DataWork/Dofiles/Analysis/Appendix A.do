*	Appendix A
*	This do-file replicates Appendix A


	/****************************************************************
		Appendix A: Validating the PFS measure against the USDA’s FSSS
	****************************************************************/	
	
	use	"${FSD_dtFin}/FSD_const_long.dta", clear

	
	
			
		*	Create decile indicator
		cap	drop	PFS_decile_cutoff
		cap	drop	PFS_decile
		pctile 	PFS_decile_cutoff = PFS_glm [pweight=weight_multi12] if (${study_sample}==1	&	inlist(year,2,3,9,10)), nq(10)
		
		gen		PFS_decile=.
		quietly	summarize	PFS_decile_cutoff	in	1
		replace	PFS_decile=1	if	inrange(PFS_glm,0,r(mean))
		forvalues	i=1/8	{
			
			local	j=`i'+1
			qui	summ	PFS_decile_cutoff	in	`i'
			local	minPFS=r(mean)
			qui	summ	PFS_decile_cutoff	in	`j'
			local	maxPFS=r(mean)
			
			replace	PFS_decile	=	`j'	if	inrange(PFS_glm,`minPFS',`maxPFS')
		}
		
		qui	summarize	PFS_decile_cutoff	in	9
		replace	PFS_decile	=	10	if	inrange(PFS_glm,r(mean),1)

		
			
		*	Simple inclusion and exclusion
		
			*	All population
			**	This code gives type I (3.2%) and type II (9.9%) error rates
			svy, subpop(${study_sample}):	tab	fs_cat_fam_simp	PFS_FS_glm
			
			*	IPR below 130%
			*svy, subpop(if ${study_sample} & income_to_poverty<1.3):	tab	fs_cat_fam_simp	PFS_FS_glm
			
			*	SNAP recepients
			*svy, subpop(if ${study_sample} & food_stamp_used_0yr==1):	tab	fs_cat_fam_simp	PFS_FS_glm	
			
		
		*	Rank correlation (spearman, Kendall's tau)
		**	This part shows spearman and Kendall's tau (0.31, 0.25)
			
			*	Pooled
			cap	mat	drop	corr_all
			cap	mat	drop	corr_spearman
			cap	mat	drop	corr_kendall
			
			spearman	fs_scale_fam_rescale	PFS_glm		///
				if ${study_sample}	&	inlist(year,2,3,9,10),	stats(rho obs p)
			mat	corr_spearman	=	r(rho)	//	0.31
		
			ktau 	fs_scale_fam_rescale	PFS_glm		///
				if ${study_sample}	&	inlist(year,2,3,9,10), stats(taua taub p)
			mat	corr_kendall	=	r(tau_b)	//	0.25
			
		
			*	Frequencyy table of the FSSS 
			svy, subpop(if ${study_sample}==1 & !mi(PFS_glm) & !mi(fs_scale_fam_rescale)): tab fs_scale_fam_rescale
			
			
			*	Summarize PFS (https://www.stata.com/support/faqs/statistics/percentiles-for-survey-data/) (Goes to the FN11 and Fig A2)
			summ	fs_scale_fam_rescale 		if ${study_sample}==1	&	inlist(year,2,3,9,10)	&	!mi(PFS_glm)  [aweight=weight_multi12], detail
			summ	PFS_glm if ${study_sample}==1	&	inlist(year,2,3,9,10)	&	!mi(fs_scale_fam_rescale)		  [aweight=weight_multi12], detail
			
			
		*	Table A1
				
			*	Regression
				
				*	All study sample
				svy, subpop(${study_sample}): reg fs_scale_fam_rescale	PFS_glm
				est	sto	corr_glm_lin_noFE
				svy, subpop(${study_sample}): reg fs_scale_fam_rescale	c.PFS_glm##c.PFS_glm
				est	sto	corr_glm_nonlin_noFE
				svy, subpop(${study_sample}): reg fs_scale_fam_rescale	PFS_glm	i.year state_group? state_group1? state_group2?
				est	sto	corr_glm_lin_FE
				svy, subpop(${study_sample}): reg fs_scale_fam_rescale	c.PFS_glm##c.PFS_glm i.year state_group? state_group1? state_group2?
				est	sto	corr_glm_nonlin_FE	
			
			
			*	Output
			esttab	corr_glm_lin_noFE		corr_glm_nonlin_noFE			corr_glm_lin_FE			corr_glm_nonlin_FE	///
					using "${FSD_outTab}/Tab_A1.csv", ///
			cells(b(star fmt(a3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	keep(PFS_glm c.PFS_glm#c.PFS_glm)	///
			title(Regression of the USDA scale on PFS(glm)) replace
			
			
			esttab			corr_glm_lin_noFE		corr_glm_nonlin_noFE			corr_glm_lin_FE			corr_glm_nonlin_FE	///
				using "${FSD_outTab}/Tab_A1.tex", ///
				cells(b(nostar fmt(%8.3f)) se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc	%8.3fc)) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	keep(PFS_glm c.PFS_glm#c.PFS_glm)	///	///
				title(Regression of the USDA scale on PFS(glm)) replace
			
		
		
		
		*	Table A2
		
			*	Regression
			
				*	FSSS, without region FE
				local	depvar	fs_scale_fam_rescale	
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)):	///
					reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	
				est	store	FSSS_noregionFE	
				
				*	PFS, without region FE
				local	depvar	PFS_glm
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)):	///
					reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	
				est	store	PFS_noregionFE	
				
				*	FSSS, with region FE
				local	depvar	fs_scale_fam_rescale
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)):	///
					reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
				est	store	FSSS_regionFE	
				
				*	PFS, with region FE
				local	depvar	PFS_FS_glm
				svy, subpop(if ${study_sample} & FSSS_PFS_available_years==1	&	!mi(PFS_glm)	&	!mi(fs_scale_fam_rescale)):	///
					reg	`depvar'	${demovars}	${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	${foodvars}	${changevars}	${timevars}	${regionvars}
				est	store	PFS_regionFE	
						
			
			*	Output
				
				*	Food Security Indicators and Their Correlates 
				esttab	FSSS_noregionFE	PFS_noregionFE	FSSS_regionFE	PFS_regionFE	using "${FSD_outTab}/Tab_A2.csv", ///
						cells(b(star fmt(3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	drop(*year_enum* state_group* _cons)	///
						title(Effect of Correlates on Food Security Status) replace
						
						
				esttab	FSSS_noregionFE	PFS_noregionFE	FSSS_regionFE	PFS_regionFE	using "${FSD_outTab}/Tab_A2.tex", ///
						/*cells(b(star fmt(3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	*/	///
						cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)drop(*year_enum* state_group* _cons)	///
						title(Effect of Correlates on Food Security Status) replace
		
		
	
	