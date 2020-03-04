
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_family_splitoff
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Mar 01, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	Fx11101ll // Personal Identification Number

	DESCRIPTION: 	Generate family splitoff & respondent status
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Descriptive Stats
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID 1999 Constructed (family)
					${PSID_dtInt}/PSID_const_1999_fam.dta
					
					* PSID 1999 Constructed (individual)
					${PSID_dtInt}/PSID_const_1999_ind.dta
			
	OUTPUTS: 		* Graphs & Tables

	NOTE:			*
	******************************************************************/

	/****************************************************************
		SECTION 0: Preamble			 									
	****************************************************************/		 
		
	/* 0.1 - Environment setup */
	
	* Clear all stored values in memory from previous projects
	clear			all
	cap	log			close

	* Set version number
	version			14

	* Set basic memory limits
	set maxvar 		32767
	set matsize		11000

	* Set default options
	set more		off
	pause			on
	set varabbrev	off
	
	* Filename and log
	loc	name_do	PSID_family_splitoff
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doAnl}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1: Summary stats 
	****************************************************************/		
	
	use	"${PSID_dtFin}/PSID_const_1999_2017_ind.dta", clear
	
	*	Descriptive Stats
	local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
	
		*	Individual level
		
			
			*	Member status of respodents
			foreach	year of local years	{
				tabulate relat_to_current_head`year'	if	respondent`year'==1			
			}
			
			
			*	Weight(individual)
			local	desc_stats	Mean St_Dev Min Max p(25) p(50) p(75) p(90) p(95) p(99) N
			
				*	Longitudinal  (sample & non-sample)
				foreach	year	of	local	years	{
					
					*	All individauls
					qui	summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3),d
					
					mat	long_ind_`year'_all	=	nullmat(long_ind_`year'_all)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_ind_allyear_all	=	nullmat(long_ind_allyear_all),	long_ind_`year'_all				
					
					*	SRC
					qui	summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	sample_source==1,d
					
					mat	long_ind_`year'_src	=	nullmat(long_ind_`year'_src)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_ind_allyear_src	=	nullmat(long_ind_allyear_src),	long_ind_`year'_src	
					
					*	SRC
					qui	summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	sample_source==2,d
					
					mat	long_ind_`year'_seo	=	nullmat(long_ind_`year'_seo)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_ind_allyear_seo	=	nullmat(long_ind_allyear_seo),	long_ind_`year'_seo	
					
					*	Immigrant Refresher
					qui	summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	inlist(sample_source,3),d
					
					mat	long_ind_`year'_imm	=	nullmat(long_ind_`year'_imm)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_ind_allyear_imm	=	nullmat(long_ind_allyear_imm),	long_ind_`year'_imm	
									
				}
				mat	colnames	long_ind_allyear_all	=	`years'
				mat	colnames	long_ind_allyear_src	=	`years'
				mat	colnames	long_ind_allyear_seo	=	`years'
				mat	colnames	long_ind_allyear_imm	=	`years'
				
				mat	rownames	long_ind_allyear_all	=	`desc_stats'
				mat	rownames	long_ind_allyear_src	=	`desc_stats'
				mat	rownames	long_ind_allyear_seo	=	`desc_stats'
				mat	rownames	long_ind_allyear_imm	=	`desc_stats'
					
				/*
				*	Export it into Excel file
				*	For unknown reason, the below command can't be automatically run within a dofile, but can be only run manually
				putexcel	set "${PSID_outRaw}/weight_analysis", sheet(long_ind) replace
				putexcel	A2 = "All"
				putexcel	A3	=	matrix(long_ind_allyear_all), names overwritefmt nformat(number_d1)
				putexcel	A16 = "SRC"
				putexcel	A17	=	matrix(long_ind_allyear_src), names overwritefmt nformat(number_d1)
				putexcel	A30 = "SEO"
				putexcel	A31	=	matrix(long_ind_allyear_seo), names overwritefmt nformat(number_d1)
				putexcel	A44 = "Refresher"
				putexcel	A45	=	matrix(long_ind_allyear_imm), names overwritefmt nformat(number_d1)
				*/
				
				* % of tail distribution per sample
				local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
				
				foreach	year	of	local	years	{
					
					/*
					count	if	xsqnr_`year'!=0 &	inrange(sample_source,1,3)
					scalar	N=r(N)
					count	if	xsqnr_`year'!=0 &	inrange(sample_source,1,3)	&	weight_long_ind`year'==0
					scalar	zero=r(N)
					
					scalar k=zero/N
					di "year `year' ratio is" k
					
					*local ratio_zero=`zero'/`N'
					*di	`ratio_zero'
					*/	

					qui summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3), d 
					di "Year `year', below 5 percentile"
					tab sample_source if xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_long_ind`year'<=`r(p5)'
					qui summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3), d 
					di "Year `year', above 95 percentile"
					tab sample_source if xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_long_ind`year'>=`r(p95)'			
				}
				
				*	% of non-sample members in family-level
				local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
				foreach	year	of	local	years	{
									*	#
					count	if	xsqnr_`year'!=0 &	inrange(sample_source,1,3)
					scalar	N=r(N)
					count	if	xsqnr_`year'!=0 &	inrange(sample_source,1,3)	&	weight_long_ind`year'==0
					scalar	zero=r(N)
					
					scalar k=zero/N
					di "year `year' ratio is" k
				}
				scalar drop _all
			
			*	Longitudinal  (sample only)
				mat	drop	_all
			
				local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
				local	desc_stats	Mean St_Dev Min Max p(25) p(50) p(75) p(90) p(95) p(99) N
				foreach	year	of	local	years	{
					
					*	All individauls
					qui	summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_long_ind`year'!=0,d
					
					mat	long_ind_`year'_all	=	nullmat(long_ind_`year'_all)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_ind_allyear_all	=	nullmat(long_ind_allyear_all),	long_ind_`year'_all				
					
					*	SRC
					qui	summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	sample_source==1	&	weight_long_ind`year'!=0,d
					
					mat	long_ind_`year'_src	=	nullmat(long_ind_`year'_src)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_ind_allyear_src	=	nullmat(long_ind_allyear_src),	long_ind_`year'_src	
					
					*	SRC
					qui	summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	sample_source==2	&	weight_long_ind`year'!=0,d
					
					mat	long_ind_`year'_seo	=	nullmat(long_ind_`year'_seo)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_ind_allyear_seo	=	nullmat(long_ind_allyear_seo),	long_ind_`year'_seo	
					
					*	Immigrant Refresher
					qui	summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	inlist(sample_source,3)	&	weight_long_ind`year'!=0,d
					
					mat	long_ind_`year'_imm	=	nullmat(long_ind_`year'_imm)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_ind_allyear_imm	=	nullmat(long_ind_allyear_imm),	long_ind_`year'_imm	
					
				}
				mat	colnames	long_ind_allyear_all	=	`years'
				mat	colnames	long_ind_allyear_src	=	`years'
				mat	colnames	long_ind_allyear_seo	=	`years'
				mat	colnames	long_ind_allyear_imm	=	`years'
				
				mat	rownames	long_ind_allyear_all	=	`desc_stats'
				mat	rownames	long_ind_allyear_src	=	`desc_stats'
				mat	rownames	long_ind_allyear_seo	=	`desc_stats'
				mat	rownames	long_ind_allyear_imm	=	`desc_stats'
				
				
				/*
				*	Export it into Excel file
				*	For unknown reason, the below command can't be automatically run within a dofile, but can be only run manually
				putexcel	set "${PSID_outRaw}/weight_analysis", sheet(long_ind_sample) modify
				putexcel	A2 = "All"
				putexcel	A3	=	matrix(long_ind_allyear_all), names overwritefmt nformat(number_d1)
				putexcel	A16 = "SRC"
				putexcel	A17	=	matrix(long_ind_allyear_src), names overwritefmt nformat(number_d1)
				putexcel	A30 = "SEO"
				putexcel	A31	=	matrix(long_ind_allyear_seo), names overwritefmt nformat(number_d1)
				putexcel	A44 = "Refresher"
				putexcel	A45	=	matrix(long_ind_allyear_imm), names overwritefmt nformat(number_d1)
				*/
				
				* % of tail distribution per sample
				local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
				
				foreach	year	of	local	years	{
					
					/*
					count	if	xsqnr_`year'!=0 &	inrange(sample_source,1,3)
					scalar	N=r(N)
					count	if	xsqnr_`year'!=0 &	inrange(sample_source,1,3)	&	weight_long_ind`year'==0
					scalar	zero=r(N)
					
					scalar k=zero/N
					di "year `year' ratio is" k
					
					*local ratio_zero=`zero'/`N'
					*di	`ratio_zero'
					*/	

					qui summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_long_ind`year'!=0, d 
					di "Year `year', below 5 percentile"
					tab sample_source if xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_long_ind`year'!=0	&	weight_long_ind`year'<=`r(p5)'
					qui summ	weight_long_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_long_ind`year'!=0, d 
					di "Year `year', above 95 percentile"
					tab sample_source if xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_long_ind`year'!=0	&	weight_long_ind`year'>=`r(p95)'			
				}
				
				*	Cross-sectional (sample & non-sample): cross-seciontla weight does not distinguish sample and non-sample by construction
				mat	drop	_all
				local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
				local	desc_stats	Mean St_Dev Min Max p(25) p(50) p(75) p(90) p(95) p(99) N
				
				foreach	year	of	local	years	{
					
					*	All individauls
					qui	summ	weight_cross_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3),d
					
					mat	cross_ind_`year'_all	=	nullmat(cross_ind_`year'_all)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	cross_ind_allyear_all	=	nullmat(cross_ind_allyear_all),	cross_ind_`year'_all				
					
					*	SRC
					qui	summ	weight_cross_ind`year'	if	xsqnr_`year'!=0	&	sample_source==1,d
					
					mat	cross_ind_`year'_src	=	nullmat(cross_ind_`year'_src)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	cross_ind_allyear_src	=	nullmat(cross_ind_allyear_src),	cross_ind_`year'_src	
					
					*	SRC
					qui	summ	weight_cross_ind`year'	if	xsqnr_`year'!=0	&	sample_source==2,d
					
					mat	cross_ind_`year'_seo	=	nullmat(cross_ind_`year'_seo)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	cross_ind_allyear_seo	=	nullmat(cross_ind_allyear_seo),	cross_ind_`year'_seo	
					
					*	Immigrant Refresher
					qui	summ	weight_cross_ind`year'	if	xsqnr_`year'!=0	&	inlist(sample_source,3),d
					
					mat	cross_ind_`year'_imm	=	nullmat(cross_ind_`year'_imm)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	cross_ind_allyear_imm	=	nullmat(cross_ind_allyear_imm),	cross_ind_`year'_imm	
									
				}
				mat	colnames	cross_ind_allyear_all	=	`years'
				mat	colnames	cross_ind_allyear_src	=	`years'
				mat	colnames	cross_ind_allyear_seo	=	`years'
				mat	colnames	cross_ind_allyear_imm	=	`years'
				
				mat	rownames	cross_ind_allyear_all	=	`desc_stats'
				mat	rownames	cross_ind_allyear_src	=	`desc_stats'
				mat	rownames	cross_ind_allyear_seo	=	`desc_stats'
				mat	rownames	cross_ind_allyear_imm	=	`desc_stats'
					
				/*
				*	Export it into Excel file
				*	For unknown reason, the below command can't be automatically run within a dofile, but can be only run manually
				putexcel	set "${PSID_outRaw}/weight_analysis", sheet(cross_ind) modify
				putexcel	A2 = "All"
				putexcel	A3	=	matrix(cross_ind_allyear_all), names overwritefmt nformat(number_d1)
				putexcel	A16 = "SRC"
				putexcel	A17	=	matrix(cross_ind_allyear_src), names overwritefmt nformat(number_d1)
				putexcel	A30 = "SEO"
				putexcel	A31	=	matrix(cross_ind_allyear_seo), names overwritefmt nformat(number_d1)
				putexcel	A44 = "Refresher"
				putexcel	A45	=	matrix(cross_ind_allyear_imm), names overwritefmt nformat(number_d1)
				*/
					
				* % of tail distribution per sample
				local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
				
				foreach	year	of	local	years	{
					
					/*
					count	if	xsqnr_`year'!=0 &	inrange(sample_source,1,3)
					scalar	N=r(N)
					count	if	xsqnr_`year'!=0 &	inrange(sample_source,1,3)	&	weight_long_ind`year'==0
					scalar	zero=r(N)
					
					scalar k=zero/N
					di "year `year' ratio is" k
					
					*local ratio_zero=`zero'/`N'
					*di	`ratio_zero'
					*/	

					qui summ	weight_cross_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3), d 
					di "Year `year', below 5 percentile"
					tab sample_source if xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_cross_ind`year'<=`r(p5)', matcell(bottom_5pct_`year')
					qui summ	weight_cross_ind`year'	if	xsqnr_`year'!=0	&	inrange(sample_source,1,3), d 
					di "Year `year', above 95 percentile"
					tab sample_source if xsqnr_`year'!=0	&	inrange(sample_source,1,3)	&	weight_cross_ind`year'>=`r(p95)'			
				}
				*mat list bottom_5pct_1999
				*mat list bottom_5pct_2001
				*mat	drop	_all
				
				
				*	Cross-sectional distribution
					
					*	Individual Longitudinal (Sample & non-sample)
						cap	drop	*_wins
						
						*	Winsorize top 1%
						local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
						foreach	year	of	local	years	{
							winsor weight_long_ind`year' if xsqnr_`year'!=0 & inrange(sample_source,1,3), gen(weight_long_ind`year'_wins) p(0.01) highonly
						}
						
						*	Plot kernel density
						graph twoway	(kdensity weight_long_ind1999_wins if xsqnr_1999!=0 & inrange(sample_source,1,3))	///
										(kdensity weight_long_ind2003_wins if xsqnr_2003!=0 & inrange(sample_source,1,3))	///
										(kdensity weight_long_ind2007_wins if xsqnr_2007!=0 & inrange(sample_source,1,3))	///
										(kdensity weight_long_ind2011_wins if xsqnr_2011!=0 & inrange(sample_source,1,3))	///
										(kdensity weight_long_ind2015_wins if xsqnr_2015!=0 & inrange(sample_source,1,3)),	///
										title(Distribution of individual longitudinal weights)	///
										subtitle(Sample and Non-sample)	///
										note(note: Top 1% of weight is winsorized)	///
										legend(lab (1 "1999") lab(2 "2003") lab(3 "2007") lab(4 "2011") lab(5 "2015") rows(1))
						graph	export	"${PSID_outRaw}/wt_long_indiv_dist_all.png", replace
						graph	close
						
					*	Within-a year (1999) distribution by sample_source
						*	To better understand certain fluctuating patterns in overall cross-sectional distribution
						
						
						*	Winsorize top 1%
						cap	drop	*_wins
						local	years	1999 /*2001 2003 2005 2007 2009 2011 2013 2015 2017*/
						foreach	year	of	local	years	{
							winsor weight_long_ind`year' if xsqnr_`year'!=0 & sample_source==1, gen(weight_long_ind`year'_SRC_wins) p(0.01) highonly
							winsor weight_long_ind`year' if xsqnr_`year'!=0 & sample_source==2, gen(weight_long_ind`year'_SEO_wins) p(0.01) highonly
							winsor weight_long_ind`year' if xsqnr_`year'!=0 & sample_source==3, gen(weight_long_ind`year'_imm_wins) p(0.01) highonly
						}
						graph twoway	(kdensity weight_long_ind1999_SRC_wins if xsqnr_1999!=0 & sample_source==1)	///
										(kdensity weight_long_ind1999_SEO_wins if xsqnr_1999!=0 & sample_source==2)	///
										(kdensity weight_long_ind1999_imm_wins if xsqnr_1999!=0 & sample_source==3),	///
										title(1999 Distribution of individual longitudinal weights)	///
										subtitle(By Sample Composition)	///
										note(note: Top 1% of weight is winsorized)	///
										legend(lab (1 "SRC") lab(2 "SEO") lab(3 "Imm") rows(1))
						graph	export	"${PSID_outRaw}/wt_long_indiv_dist_all_99.png", replace
						graph	close
						
					*	Individual Longitudinal (Sample only)
						
						*	Winsorize top 1%
						cap	drop	*_wins
						local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
						foreach	year	of	local	years	{
							winsor weight_long_ind`year' if xsqnr_`year'!=0 & inrange(sample_source,1,3)	&	weight_long_ind`year'!=0, gen(weight_long_ind`year'_wins) p(0.01) highonly
						}
						
						*	Plot kernel density
						graph twoway	(kdensity weight_long_ind1999_wins if xsqnr_1999!=0 & inrange(sample_source,1,3)	&	weight_long_ind1999_wins!=0)	///
										(kdensity weight_long_ind2003_wins if xsqnr_2003!=0 & inrange(sample_source,1,3)	&	weight_long_ind2003_wins!=0)	///
										(kdensity weight_long_ind2007_wins if xsqnr_2007!=0 & inrange(sample_source,1,3)	&	weight_long_ind2007_wins!=0)	///
										(kdensity weight_long_ind2011_wins if xsqnr_2011!=0 & inrange(sample_source,1,3)	&	weight_long_ind2011_wins!=0)	///
										(kdensity weight_long_ind2015_wins if xsqnr_2015!=0 & inrange(sample_source,1,3)	&	weight_long_ind2015_wins!=0),	///
										title(Distribution of individual longitudinal weights)	///
										subtitle(Sample only Sample & Non-sample)	///
										note(note: Top 1% of weight is winsorized)	///
										legend(lab (1 "1999") lab(2 "2003") lab(3 "2007") lab(4 "2011") lab(5 "2015") rows(1))
						graph	export	"${PSID_outRaw}/wt_long_indiv_dist_sample.png", replace
						graph	close
						
						*	Within-a year (1999) distribution by sample_source
						*	To better understand certain fluctuating patterns in overall cross-sectional distribution
						
						
						*	Winsorize top 1%
						cap	drop	*_wins
						local	years	1999 /*2001 2003 2005 2007 2009 2011 2013 2015 2017*/
						foreach	year	of	local	years	{
							winsor weight_long_ind`year' if xsqnr_`year'!=0 & sample_source==1	&	weight_long_ind`year'!=0, gen(weight_long_ind`year'_SRC_wins) p(0.01) highonly
							winsor weight_long_ind`year' if xsqnr_`year'!=0 & sample_source==2	&	weight_long_ind`year'!=0, gen(weight_long_ind`year'_SEO_wins) p(0.01) highonly
							winsor weight_long_ind`year' if xsqnr_`year'!=0 & sample_source==3	&	weight_long_ind`year'!=0, gen(weight_long_ind`year'_imm_wins) p(0.01) highonly
						}
						graph twoway	(kdensity weight_long_ind1999_SRC_wins if xsqnr_1999!=0 & sample_source==1	&	weight_long_ind1999!=0)		///
										(kdensity weight_long_ind1999_SEO_wins if xsqnr_1999!=0 & sample_source==2	&	weight_long_ind1999!=0)		///
										(kdensity weight_long_ind1999_imm_wins if xsqnr_1999!=0 & sample_source==3	&	weight_long_ind1999!=0),	///
										title(1999 Distribution of individual longitudinal weights)	///
										subtitle(By Sample Composition Sample Only)	///
										note(note: Top 1% of weight is winsorized)	///
										legend(lab (1 "SRC") lab(2 "SEO") lab(3 "Imm") rows(1))
						graph	export	"${PSID_outRaw}/wt_long_indiv_dist_sample_99.png", replace
						graph	close
						
					* Individual Cross-sectional (sample & non-sample)
					
						*	Winsorize top 1%
							cap	drop	*_wins
							local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
							foreach	year	of	local	years	{
								winsor weight_cross_ind`year' if xsqnr_`year'!=0 & inrange(sample_source,1,3)	&	weight_cross_ind`year'!=0, gen(weight_cross_ind`year'_wins) p(0.01) highonly
							}
							
							*	Plot kernel density
							graph twoway	(kdensity weight_cross_ind1999_wins if xsqnr_1999!=0 & inrange(sample_source,1,3)	&	weight_cross_ind1999_wins!=0)	///
											(kdensity weight_cross_ind2003_wins if xsqnr_2003!=0 & inrange(sample_source,1,3)	&	weight_cross_ind2003_wins!=0)	///
											(kdensity weight_cross_ind2007_wins if xsqnr_2007!=0 & inrange(sample_source,1,3)	&	weight_cross_ind2007_wins!=0)	///
											(kdensity weight_cross_ind2011_wins if xsqnr_2011!=0 & inrange(sample_source,1,3)	&	weight_cross_ind2011_wins!=0)	///
											(kdensity weight_cross_ind2015_wins if xsqnr_2015!=0 & inrange(sample_source,1,3)	&	weight_cross_ind2015_wins!=0),	///
											title(Distribution of individual cross-sectional weights)	///
											subtitle(Sample & Non-sample only)	///
											note(note: Top 1% of weight is winsorized)	///
											legend(lab (1 "1999") lab(2 "2003") lab(3 "2007") lab(4 "2011") lab(5 "2015") rows(1))
							graph	export	"${PSID_outRaw}/wt_cross_indiv_dist_sample.png", replace
							graph	close
							
						*	Within-a year (1999) distribution by sample_source
						*	To better understand certain fluctuating patterns in overall cross-sectional distribution
						
						
						*	Winsorize top 1%
						cap	drop	*_wins
						local	years	1999 /*2001 2003 2005 2007 2009 2011 2013 2015 2017*/
						foreach	year	of	local	years	{
							winsor weight_cross_ind`year' if xsqnr_`year'!=0 & sample_source==1	&	weight_cross_ind`year'!=0, gen(weight_cross_ind`year'_SRC_wins) p(0.01) highonly
							winsor weight_cross_ind`year' if xsqnr_`year'!=0 & sample_source==2	&	weight_cross_ind`year'!=0, gen(weight_cross_ind`year'_SEO_wins) p(0.01) highonly
							winsor weight_cross_ind`year' if xsqnr_`year'!=0 & sample_source==3	&	weight_cross_ind`year'!=0, gen(weight_cross_ind`year'_imm_wins) p(0.01) highonly
						}
						graph twoway	(kdensity weight_cross_ind1999_SRC_wins if xsqnr_1999!=0 & sample_source==1	&	weight_cross_ind1999!=0)		///
										(kdensity weight_cross_ind1999_SEO_wins if xsqnr_1999!=0 & sample_source==2	&	weight_cross_ind1999!=0)		///
										(kdensity weight_cross_ind1999_imm_wins if xsqnr_1999!=0 & sample_source==3	&	weight_cross_ind1999!=0),	///
										title(1999 Distribution of Cross-sectional longitudinal weights)	///
										subtitle(By Sample Composition)	///
										note(note: Top 1% of weight is winsorized)	///
										legend(lab (1 "SRC") lab(2 "SEO") lab(3 "Imm") rows(1))
						graph	export	"${PSID_outRaw}/wt_cross_indiv_dist_all_99.png", replace
						graph	close
				
			
		*	Family-level
			
			*	Keep family-level variables only
			keep	x11102* splitoff* num_split* main_fam* sample_source splitoff_dummy*	resp_consist* accum_*	weight_long_fam*
			duplicates drop
			tempfile	family_crosswave
			save		`family_crosswave'
		
			*	Respondent consistency (family-level)
			tab	resp_consist_99_01
			tab	resp_consist_99_03
			tab	resp_consist_99_15
			tab	resp_consist_99_17
			tab	resp_consist_01_03
			tab	resp_consist_01_15
			tab	resp_consist_01_17
			tab	resp_consist_03_15
			tab	resp_consist_03_17
			tab	resp_consist_15_17
			
			*	# of split-offs
			tab	accum_splitoff2001
			tab	accum_splitoff2003
			tab	accum_splitoff2005
			tab	accum_splitoff2007
			tab	accum_splitoff2009
			tab	accum_splitoff2011
			tab	accum_splitoff2013
			tab	accum_splitoff2015
			tab	accum_splitoff2017
		
		*	Weight analysis
			mat	drop	_all
			local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
			local	desc_stats	Mean St_Dev Min Max p(25) p(50) p(75) p(90) p(95) p(99) N
			
				*	Longitudinal  (sample & non-sample)
				preserve
				foreach	year	of	local	years	{
					
				keep	weight_long_fam`year' x11102_`year'	sample_source
				duplicates drop
					
					*	All individauls
					qui	summ	weight_long_fam`year'	if	!mi(x11102_`year')	&	inrange(sample_source,1,3),d
					
					mat	long_fam_`year'_all	=	nullmat(long_fam_`year'_all)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_fam_allyear_all	=	nullmat(long_fam_allyear_all),	long_fam_`year'_all				
					
					*	SRC
					qui	summ	weight_long_fam`year'	if	!mi(x11102_`year')	&	sample_source==1,d
					
					mat	long_fam_`year'_src	=	nullmat(long_fam_`year'_src)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_fam_allyear_src	=	nullmat(long_fam_allyear_src),	long_fam_`year'_src	
					
					*	SRC
					qui	summ	weight_long_fam`year'	if	!mi(x11102_`year')	&	sample_source==2,d
					
					mat	long_fam_`year'_seo	=	nullmat(long_fam_`year'_seo)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_fam_allyear_seo	=	nullmat(long_fam_allyear_seo),	long_fam_`year'_seo	
					
					*	Immigrant Refresher
					qui	summ	weight_long_fam`year'	if	!mi(x11102_`year')	&	inlist(sample_source,3),d
					
					mat	long_fam_`year'_imm	=	nullmat(long_fam_`year'_imm)	\	r(mean)	\ r(sd)	\	///
												r(min)	\	r(max)	\	r(p25)	\	r(p50)	\	r(p75)	\	///
												r(p90)	\	r(p95)	\	r(p99)	\	r(N)
												
					mat	long_fam_allyear_imm	=	nullmat(long_fam_allyear_imm),	long_fam_`year'_imm	
					restore, preserve				
				}
				restore
				mat	colnames	long_fam_allyear_all	=	`years'
				mat	colnames	long_fam_allyear_src	=	`years'
				mat	colnames	long_fam_allyear_seo	=	`years'
				mat	colnames	long_fam_allyear_imm	=	`years'
				
				mat	rownames	long_fam_allyear_all	=	`desc_stats'
				mat	rownames	long_fam_allyear_src	=	`desc_stats'
				mat	rownames	long_fam_allyear_seo	=	`desc_stats'
				mat	rownames	long_fam_allyear_imm	=	`desc_stats'
					
				/*
				*	Export it into Excel file
				*	For unknown reason, the below command can't be automatically run within a dofile, but can be only run manually
				putexcel	set "${PSID_outRaw}/weight_analysis", sheet(long_fam) modify
				putexcel	A2 = "All"
				putexcel	A3	=	matrix(long_fam_allyear_all), names overwritefmt nformat(number_d1)
				putexcel	A16 = "SRC"
				putexcel	A17	=	matrix(long_fam_allyear_src), names overwritefmt nformat(number_d1)
				putexcel	A30 = "SEO"
				putexcel	A31	=	matrix(long_fam_allyear_seo), names overwritefmt nformat(number_d1)
				putexcel	A44 = "Refresher"
				putexcel	A45	=	matrix(long_fam_allyear_imm), names overwritefmt nformat(number_d1)
				*/
				
				* % of tail distribution per sample
				local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
				preserve
				foreach	year	of	local	years	{
					
					keep	weight_long_fam`year' x11102_`year'	sample_source
					duplicates drop
					/*
					count	if	!mi(x11102_`year') &	inrange(sample_source,1,3)
					scalar	N=r(N)
					count	if	!mi(x11102_`year') &	inrange(sample_source,1,3)	&	weight_long_fam`year'==0
					scalar	zero=r(N)
					
					scalar k=zero/N
					di "year `year' ratio is" k
					
					*local ratio_zero=`zero'/`N'
					*di	`ratio_zero'
					*/	

					qui summ	weight_long_fam`year'	if	!mi(x11102_`year')	&	inrange(sample_source,1,3), d 
					di "Year `year', below 5 percentile"
					tab sample_source if !mi(x11102_`year')	&	inrange(sample_source,1,3)	&	weight_long_fam`year'<=`r(p5)'
					qui summ	weight_long_fam`year'	if	!mi(x11102_`year')	&	inrange(sample_source,1,3), d 
					di "Year `year', above 95 percentile"
					tab sample_source if !mi(x11102_`year')	&	inrange(sample_source,1,3)	&	weight_long_fam`year'>=`r(p95)'			
					restore, preserve
				}
				restore
			
			*	Cross-sectional distribution
				
				*	Family Longitudinal (Sample & non-sample)
					cap	drop	*_wins
					cap	drop	represent_*
										
					*	Winsorize top 1%
					local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
					foreach	year	of	local	years	{
						
						*	Generate indicator (to use only one observation per family)
						gen represent_`year'=1	if	xsqnr_`year'==1	&	inrange(sample_source,1,3)	// One per family, excluding 2017 immigrants
						
						*	Winsorization
						winsor weight_long_fam`year' if represent_`year'==1 & inrange(sample_source,1,3), gen(weight_long_fam`year'_wins) p(0.01) highonly
					}
					
					*	Plot kernel density
					graph twoway	(kdensity weight_long_fam1999_wins if represent_1999==1 & inrange(sample_source,1,3))	///
									(kdensity weight_long_fam2003_wins if represent_2003==1 & inrange(sample_source,1,3))	///
									(kdensity weight_long_fam2007_wins if represent_2007==1 & inrange(sample_source,1,3))	///
									(kdensity weight_long_fam2011_wins if represent_2011==1 & inrange(sample_source,1,3))	///
									(kdensity weight_long_fam2015_wins if represent_2015==1 & inrange(sample_source,1,3)),	///
									title(Distribution of family longitudinal weights)	///
									subtitle(Sample and Non-sample)	///
									note(note: Top 1% of weight is winsorized)	///
									legend(lab (1 "1999") lab(2 "2003") lab(3 "2007") lab(4 "2011") lab(5 "2015") rows(1))
					graph	export	"${PSID_outRaw}/wt_long_fam_dist_all.png", replace
					graph	close
					
					*	Within-a year (1999) distribution by sample_source
					*	To better understand certain fluctuating patterns in overall cross-sectional distribution
				
						*	Winsorize top 1%
						cap	drop	*_wins

						local	years	2003 /*2001 2003 2005 2007 2009 2011 2013 2015 2017*/
						foreach	year	of	local	years	{
							winsor weight_long_fam`year' if represent_`year'==1 & sample_source==1, gen(weight_long_fam`year'_SRC_wins) p(0.01) highonly
							winsor weight_long_fam`year' if represent_`year'==1 & sample_source==2, gen(weight_long_fam`year'_SEO_wins) p(0.01) highonly
							winsor weight_long_fam`year' if represent_`year'==1 & sample_source==3, gen(weight_long_fam`year'_imm_wins) p(0.01) highonly
						}
						graph twoway	(kdensity weight_long_fam2003_SRC_wins if represent_2003==1 & sample_source==1)	///
										(kdensity weight_long_fam2003_SEO_wins if represent_2003==1 & sample_source==2)	///
										(kdensity weight_long_fam2003_imm_wins if represent_2003==1 & sample_source==3),	///
										title(2003 Distribution of family longitudinal weights)	///
										subtitle(By Sample Composition)	///
										note(note: Top 1% of weight is winsorized)	///
										legend(lab (1 "SRC") lab(2 "SEO") lab(3 "Imm") rows(1))
						graph	export	"${PSID_outRaw}/wt_long_fam_dist_all_03.png", replace
						graph	close
	
/*

		
		
		*	Individual file
		use	"${PSID_dtRaw}/Main/ind2017er.dta", clear
		
			*	Survey respondents
			clonevar	respondent1999	=	ER33511
			clonevar	respondent2001	=	ER33611
			clonevar	respondent2003	=	ER33711
			clonevar	respondent2015	=	ER34312
			clonevar	respondent2017	=	ER34511
			
			
			
			*	Relation to head (reference person)
			clonevar	relat_to_head1999	=	ER33503
			clonevar	relat_to_head2001	=	ER33603
			clonevar	relat_to_head2003	=	ER33703
			clonevar	relat_to_head2015	=	ER34303
			clonevar	relat_to_head2017	=	ER34503
			
				
			
			label values	respondent_*	yesno
			
			*	Relation to "current" head
			gen	relation_to_head1999=.
			gen	relation_to_head2001=.
			gen	relation_to_head2003=.
			gen	relation_to_head2015=.
			gen	relation_to_head2017=.
		
	
		*	Clean
			
			
		/*
			local	years	1999 2001 2003 2005 2007 2009 2011 2013 2015 2017
			foreach	year of local years	{
			    if	`year'==1999	{
					local	surveyed 1999
				}
				else	{
				    local	surveyed	`surveyed'	&	`year'
				}
				
			}
			di "surveyed is `surveyed'"
			*/
			