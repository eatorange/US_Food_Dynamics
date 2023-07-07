*	Appendix B

	use	"${FSD_dtFin}/FSD_const_long.dta", clear
		
		*	Correlation (in-text numbers)
		
				
		
		
		
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
			