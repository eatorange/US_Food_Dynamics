   * ******************************************************************** *
   * ******************************************************************** *
   *                                                                      *
   *           Food Security Dynamics in the United States, 2001-2017	  *
   *           MASTER DO_FILE                                         	  *
   *                                                                      *
   * ******************************************************************** *
   * ******************************************************************** *

       /*
       ** PURPOSE:     A master do-file that replicates the analyses and outputes (tables/figures) in the paper

       ** OUTLINE:      PART 0: Standardize settings 
                        PART 1: Set up working directories 
						PART 2: Prepare global macros for the analyses
                        PART 2: Run the sub do-files

       ** IDS VAR:      list_ID_var_here         //Uniquely identifies households (update for your project)

       ** NOTES:

       ** WRITTEN BY:   Seungmin Lee (sl3235@cornell.edu)

       ** Last date modified:  Jan 29, 2023
       */


   * ******************************************************************** *
   *
   *       PART 0:  Standardize settings across users
   *
   *
   * ******************************************************************** *

	clear	all
	version 16
	set	maxvar	32767
	set	matsize	11000


   * ******************************************************************** *
   *
   *       PART 1:  PREPARING FOLDER PATH GLOBALS
   *
   *
   * ******************************************************************** *

   *	Set the project folder below to your working directory.
	global	projectfolder	"E:\GitHub\US_Food_Dynamics"		//	Github location
	*global	clouldfolder	"E:\Box\US Food Security Dynamics"	//


* These lines are used to test that the name is not already used (do not edit manually)

   * Project folder globals
   * ---------------------

	global	dataWorkFolder     "$projectfolder/DataWork"
	
	global	FSD_dt					"$dataWorkFolder/DataSets"
	global	FSD_dtRaw		      	"$FSD_dt/Raw"
	global	FSD_dtInt				"$FSD_dt/Intermediate"
	global	FSD_dtFin				"$FSD_dt/Final"

   *Dofile sub-folder globals	
	global	FSD_dofiles				"$dataWorkFolder/Dofiles"
	global	FSD_doCln				"$FSD_dofiles/Cleaning"
	global	FSD_doCon				"$FSD_dofiles/Construct" 
	global	FSD_doAnl				"$FSD_dofiles/Analysis" 

   *Output sub-folder globals
	global FSD_out               "$dataWorkFolder/Output" 
	global FSD_outTab            "$FSD_out/Tables" 
	global FSD_outFig            "$FSD_out/Figures" 


*iefolder*1*End_FolderGlobals***************************************************
*iefolder will not work properly if the line above is edited


*iefolder*2*StandardGlobals*****************************************************
*iefolder will not work properly if the line above is edited

   * Set all non-folder path globals that are constant accross
   * the project. Examples are conversion rates used in unit
   * standardization, different sets of control variables,
   * adofile paths etc.

   do "$dataWorkFolder/global_setup.do" 


*iefolder*2*End_StandardGlobals*************************************************
*iefolder will not work properly if the line above is edited


*iefolder*3*RunDofiles**********************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 3: - RUN DOFILES CALLED BY THIS MASTER DOFILE
   *
   *           - A task master dofile has been created for each high-
   *            level task (cleaning, construct, analysis). By 
   *            running all of them all data work associated with the 
   *            PSID should be replicated, including output of 
   *            tables, graphs, etc.
   *           - Feel free to add to this list if you have other high-
   *            level tasks relevant to your project.
   *
   * ******************************************************************** *

   **Set the locals corresponding to the tasks you want
   * run to 1. To not run a task, set the local to 0.
	local cleaningDo	1	//	Import and clean data
	local constructDo	1	//	Construct outcomes and other indicators
	local analysisDo	0	//	Analyze
	local appendixDo	0	//	Replicate appendix
	local othersDo		0	//	Other do-files replicating numbers in the main text.
		local	MLDo	0	//	Run ML and compare it with the GLM model. set as 0 by default	

   if (`cleaningDo' == 1) { // Change the local above to run or not to run this file
       do "$FSD_doCln/FSD_clean.do" 
   }

   if (`constructDo' == 1) { // Change the local above to run or not to run this file
       do "$FSD_doCon/FSD_const.do" 
   }

   if (`analysisDo' == 1) { // Change the local above to run or not to run this file
       do "$FSD_doAnl/FSD_analyses.do" 
   }

   if (`appendixDo' == 1) { // Change the local above to run or not to run this file
       do "$FSD_doAnl/Appendix A.do" 
	   do "$FSD_doAnl/Appendix B.do" 
	   do "$FSD_doAnl/Appendix C.do" 
	   do "$FSD_doAnl/Appendix D.do" 
   }

   if (`othersDo' == 1) { // Change the local above to run or not to run this file
       do "$FSD_doAnl/Recall_seam_period.do" 
	   if	`MLDo'==1	{
		do "$FSD_doAnl/GLM_ML_comparison.do" // ***** CAUTION: IT TAKES A LONG TIME TO RUN ***********
	   }
   }

   
*iefolder*3*End_RunDofiles******************************************************
*iefolder will not work properly if the line above is edited

