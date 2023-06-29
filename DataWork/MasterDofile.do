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
   
	global	FSD_dofiles				"$dataWorkFolder/Dofiles"
	global	FSD_doCln				"$FSD_dofiles/Cleaning"
	global	FSD_doCon				"$FSD_dofiles/Construct" 
	global	FSD_doAnl				"$FSD_dofiles/Analysis" 

   *Dofile sub-folder globals
	global PSID_do                "$PSID/Dofiles" 
	global PSID_doCln             "$PSID_do/Cleaning" 
	global PSID_doCon             "$PSID_do/Construct" 
	global PSID_doAnl             "$PSID_do/Analysis" 

   *Output sub-folder globals
	global PSID_out               "$PSID/Output" 
	global PSID_outRaw            "$PSID_out/Raw" 
	global PSID_outFin            "$PSID_out/Final" 


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
   local importDo       0
   local cleaningDo     0
   local constructDo    0
   local analysisDo     0

   if (`importDo' == 1) { // Change the local above to run or not to run this file
       do "$PSID_doImp/PSID_import_MasterDofile.do" 
   }

   if (`cleaningDo' == 1) { // Change the local above to run or not to run this file
       do "$PSID_do/PSID_cleaning_MasterDofile.do" 
   }

   if (`constructDo' == 1) { // Change the local above to run or not to run this file
       do "$PSID_do/PSID_construct_MasterDofile.do" 
   }

   if (`analysisDo' == 1) { // Change the local above to run or not to run this file
       do "$PSID_do/PSID_analysis_MasterDofile.do" 
   }

*iefolder*3*End_RunDofiles******************************************************
*iefolder will not work properly if the line above is edited

