
	/*****************************************************************
	PROJECT: 		US Food Security Dynamics
					
	TITLE:			PSID_analysis
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Jan 31, 2020, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	list_ID_var_here         // Uniquely identifies households (update for your project)

	DESCRIPTION: 	Aanlyzes PSID Data
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Data cleaning
						1.1	-	
						1.2 -	
						1.3 -	
						1.4	-	
					2 - Generate & adjust indicators
					X - Save and Exit
					
	INPUTS: 		* PSID Data
			
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
	loc	name_do	PSID_analysis
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${PSID_doAnl}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1.1: Food Expenditure
	****************************************************************/	
	
	*	Food expenditure
	use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Customized\Food_variables\food_variables.dta", clear
	
	*	Distribution of food expenditure
		graph twoway	(kdensity ER16515A1) (kdensity ER24138A1) (kdensity ER41027A1) (kdensity ER52395A1) (kdensity ER71487) if !mi(ER66002),	///
		title(Distribution of Annual Food Expenditure)	legend(lab (1 "1999") lab(2 "2003") lab(3 "2007") lab(4 "2011") lab(5 "2017"))
		
	*	Distribution of food security (scaled score)
		graph twoway	(kdensity ER14331T) (kdensity ER18470T) (kdensity ER21735T) (kdensity ER60798) (kdensity ER66846) if !mi(ER66002),	///
		title(Distribution of Food Security Score(scaled))	legend(lab (1 "1999") lab(2 "2001") lab(3 "2003") lab(4 "2015") lab(5 "2017"))
		
	*	Distribution of food security (category)
		graph twoway	(bar ER14331U) (bar ER18470U) (bar ER21735U) (bar ER60799) (bar ER66847) if !mi(ER66002),	///
		title(Distribution of Food Security Score(scaled))	legend(lab (1 "1999") lab(2 "2001") lab(3 "2003") lab(4 "2015") lab(5 "2017"))
		
	    
	
	count if     