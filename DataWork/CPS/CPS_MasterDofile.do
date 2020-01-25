   * ******************************************************************** *
   * ******************************************************************** *
   *                                                                      *
   *               your_round_name                                        *
   *               MASTER DO_FILE                                         *
   *                                                                      *
   * ******************************************************************** *
   * ******************************************************************** *

       /*
       ** PURPOSE:      Write intro to survey round here

       ** OUTLINE:      PART 0: Standardize settings and install packages
                        PART 1: Prepare folder path globals
                        PART 2: Run the master dofiles for each high-level task

       ** IDS VAR:      list_ID_var_here         //Uniquely identifies households (update for your project)

       ** NOTES:

       ** WRITTEN BY:   names_of_contributors

       ** Last date modified:  1 Jan 2020
       */

*iefolder*0*StandardSettings****************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 0:  INSTALL PACKAGES AND STANDARDIZE SETTINGS
   *
   *           - Install packages needed to run all dofiles called
   *            by this master dofile.
   *           - Use ieboilstart to harmonize settings across users
   *
   * ******************************************************************** *

*iefolder*0*End_StandardSettings************************************************
*iefolder will not work properly if the line above is edited

   *Install all packages that this project requires:
   *(Note that this never updates outdated versions of already installed commands, to update commands use adoupdate)
   local user_commands ietoolkit       //Fill this list will all user-written commands this project requires
   foreach command of local user_commands {
       cap which `command'
       if _rc == 111 {
           ssc install `command'
       }
   }

   *Standardize settings accross users
   ieboilstart, version(12.1)          //Set the version number to the oldest version used by anyone in the project team
   `r(version)'                        //This line is needed to actually set the version from the command above

*iefolder*1*FolderGlobals*******************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 1:  PREPARING FOLDER PATH GLOBALS
   *
   *           - Set the global box to point to the project folder
   *            on each collaborator's computer.
   *           - Set other locals that point to other folders of interest.
   *
   * ******************************************************************** *

   * Users
   * -----------

   * Root folder globals
   * ---------------------
   
   * Add local folder name of each collaborator.
   * `c(username)' is the system macro of STATA which has username
   * To find collaborator's user name, type -di "`c(username)'"- in STATA

   if "`c(username)'"== "Seungmin Lee" {	//	Seungmin Lee, office PC
       global projectfolder "E:\GitHub\US_Food_Dynamics"
   }

   if "`c(username)'"== "xxx" {	//	Seungmin Lee, personal LAPTOP
       global projectfolder "..."
   }
   
   if "`c(username)'"== "xxx" {	//	Liz
       global projectfolder "..."
   }
   
   if "`c(username)'"== "xxx" {	//	Lizzie
       global projectfolder "..."
   }

* These lines are used to test that the name is not already used (do not edit manually)

   * Project folder globals
   * ---------------------

   global dataWorkFolder         "$projectfolder/DataWork"

*iefolder*1*FolderGlobals*master************************************************
*iefolder will not work properly if the line above is edited

   global mastData               "$dataWorkFolder/MasterData" 

*iefolder*1*FolderGlobals*encrypted*********************************************
*iefolder will not work properly if the line above is edited

   global encryptFolder          "$dataWorkFolder/EncryptedData" 

*iefolder*1*FolderGlobals*CPS***************************************************
*iefolder will not work properly if the line above is edited


   *Encrypted round sub-folder globals
   global CPS                    "$dataWorkFolder/CPS" 

   *Encrypted round sub-folder globals
   global CPS_encrypt            "$encryptFolder/Round CPS Encrypted" 
   global CPS_dtRaw              "$CPS_encrypt/Raw Identified Data" 
   global CPS_doImp              "$CPS_encrypt/Dofiles Import" 
   global CPS_HFC                "$CPS_encrypt/High Frequency Checks" 

   *DataSets sub-folder globals
   global CPS_dt                 "$CPS/DataSets" 
   global CPS_dtDeID             "$CPS_dt/Deidentified" 
   global CPS_dtInt              "$CPS_dt/Intermediate" 
   global CPS_dtFin              "$CPS_dt/Final" 

   *Dofile sub-folder globals
   global CPS_do                 "$CPS/Dofiles" 
   global CPS_doCln              "$CPS_do/Cleaning" 
   global CPS_doCon              "$CPS_do/Construct" 
   global CPS_doAnl              "$CPS_do/Analysis" 

   *Output sub-folder globals
   global CPS_out                "$CPS/Output" 
   global CPS_outRaw             "$CPS_out/Raw" 
   global CPS_outFin             "$CPS_out/Final" 

   *Questionnaire sub-folder globals
   global CPS_prld               "$CPS_quest/PreloadData" 
   global CPS_doc                "$CPS_quest/Questionnaire Documentation" 

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
   *            CPS should be replicated, including output of 
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
       do "$CPS_doImp/CPS_import_MasterDofile.do" 
   }

   if (`cleaningDo' == 1) { // Change the local above to run or not to run this file
       do "$CPS_do/CPS_cleaning_MasterDofile.do" 
   }

   if (`constructDo' == 1) { // Change the local above to run or not to run this file
       do "$CPS_do/CPS_construct_MasterDofile.do" 
   }

   if (`analysisDo' == 1) { // Change the local above to run or not to run this file
       do "$CPS_do/CPS_analysis_MasterDofile.do" 
   }

*iefolder*3*End_RunDofiles******************************************************
*iefolder will not work properly if the line above is edited

