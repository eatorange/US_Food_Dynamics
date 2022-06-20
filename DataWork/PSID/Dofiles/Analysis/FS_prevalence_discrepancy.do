*	Check the discrepance between raw data and our study sample
		
		*	PSID raw data (family-level )
		*	I randomly test two years.
			
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
		
		*	PSID (Balanced sample, weighted)
		use	"${PSID_dtFin}/fs_const_long.dta", clear
		include	"${PSID_doAnl}/Macros_for_analyses.do"
		
		isid	fam_ID_1999	year
		svy, subpop(if year==10 & ${study_sample}==1):	mean	fs_cat_IS	PFS_FI_glm

use	"${PSID_dtInt}/PSID_raw_ind.dta", clear


