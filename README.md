## Overview

The code in this replication package constructs the analysis file using Stata from the three data sources: Panel Study of Income Dynamics, United States Department of Agriculture (USDA), and the Bureau of Economic Analysis (BEA). One master do-file runs all the sub do-files to generate the tables and figures in the paper. The replicator should expect the code to run for about 1-3 hours.

## Instructions to Replicators

The Stata code uses relative path. The Dofiles folder must be the active directory. To make the Dofiles folcer the active directory, you have two options:

1. Double-click on Dofiles/MasterDofile.do to open Stata
2. Open the Dofiles/MasterDofile.do file, uncomment the cd command on line 3 and specify the full path of the Dofiles folder.

Adjust the counters in "Dofiles/MasterDofile.do" to select the do-files you want to run. Type 1 to run, 0 to not run.
  - If you are running the do-files for the first time, you should turn on "cleaningDo" and "constructDo" macro to prepare the dataset to be analyzed.
  - "MLDo", which runs "Datawork/Dofiles/Construct/GLM\_ML\_comparison.do", is turned off by default. If you are interested in running the do-file above, you should turn it on.

If the PSID data is not included in the package, download the PSID data files as referenced in "_Details on Each Data Source_" above. Store them in "DataSets/Raw/PSID" folder.

Run "Dofiles/MasterDofile.do" to run all steps in sequence.

## Data Availability and Provenance Statements

### Statement about Rights

- I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.
- I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permission are documented in the LICENSE.txt file.

### License for Data

The PSID data may NOT be shared or re-distributed directly per its [Conditions of Use](https://simba.isr.umich.edu/u/conduse.aspx). It can only be accessed either through direct download from the PSID webpage, or through an OpenICPSR repository. See LICENSE.txt for details.

### Summary of Availability

- All data **is** publicly available.

### Details on each Data Source

| Data.Name | Data.Files | Location | Provided | Citation |
| --- | --- | --- | --- | --- |
| "Panel Study of Income Dynamics 1999-2017" | fam1999er.dta, …, fam2017er.dta, wlth1999.dta, …, wlth2007.dta, ind2017er.dta | DataWork/DataSets/Raw/PSID | FALSE | Panel Study of Income Dynamics (2020) |
| "Cost of Food Reports" | Cost of Food Reports.xlsx | DataWork/DataSets/Raw/USDA | TRUE | USDA (2020b) |
| "Regional Price Parities" | Regional Price Parities.xls | DataWork/DataSets/Raw/BEA | TRUE | Bureau of Economic Analysis (2022) |

1. Panel Study of Income Dynamics (PSID): the paper uses the PSID data (Panel Study of Income Dynamics, 2020). The study uses public family survey data from 1999 to 2017, wealth data from 1999 to 2007, and cross-year individual record from 1968 to 2017. This data was downloaded from [the PSID webpage](https://psidonline.isr.umich.edu/default.aspx) in February 2020. PSID does not allow for data redistribution per its [Conditions of Use](https://simba.isr.umich.edu/u/conduse.aspx), except for the purpose of replication archives. The data can also be directly downloaded through "Data" -\> "Packaged Data" -\> "Main and Supplemental Studies." Note: the reference to "Panel study of Income Dynamics, 2020" would be resolved in the Reference section of this README, and in the main manuscript.

> _Datafile: fam1999er.dta, …, fam2017er.dta, wlth1999.dta, …,_ _wlth2007.dta,_ _ind2017er.dta under "DataWork/DataSets/Raw/PSID"_


2. Cost of Food Report for Thrifty Food Plan: The paper uses the USDA's monthly report of the thrifty food plan cost from Jan 2001 to Dec 2017. These data are downloaded from [the USDA webpage](https://www.fns.usda.gov/cnpp/usda-food-plans-cost-food-reports-monthly-reports). Since the original data are in pdf formats per year-month, the author(s) manually entered and aggregated them in a single MS Excel file "Food Plans\_Cost of Food Reports.xlsx" in the folder. Any discrepancies between the raw data and the aggregated data, if any, are authors' responsibility.

> _Datafile: "DataWork/DataSets/Raw/USDA/Cost of Food Reports.xlsx"_


3. Regional Price Parity (RPP): The study uses the RPP from 2009 to 2017. The data was directly downloaded from the Bureau of Economic Analysis (BEA) website ([here](https://www.bea.gov/data/prices-inflation/regional-price-parities-state-and-metro-area)) in June 2022. The data can be directly downloaded under "Interactive Data" -\> "Interactive Tables: Regional Price Parities" -\> "Regional Price Parities" -\> "PARPP – Regional price parities by portion." A copy of data is provided as part of this archive. The data are in the public domain.

> _Datafile: "DataWork/DataSets/Raw/BEA/Regional Price Parities.xls"_

## Dataset list

| Data file | Source | Notes | Provided |
| --- | --- | --- | --- |
| DataSets/Raw/PSID/fam????er.dta, DataSets/Raw/PSID/wlth????.dta (????: 1999 to 2017), DataSets/Raw/PSID/ind2017er.dta | PSID | As per terms of use | Yes (only in OpenICPSR repository) |
| DataSets/Raw/BEA/Regional Price Parities.xlsx | BEA | --- | Yes |
| DataSets/Raw/USDA/Cost of Food Reports/Food Plans\_Cost of Food Reports.xlsx | USDA | Manually entered from the original pdf files included in the package. | Yes |

## Computational requirements

### Software Requirements

1. Stata (code was last run with version 16)
  * psidtools (as of 2022-08-16)
  * winsor (version 1.3.0 NJC, 20 Feb 2002)
  * lassopack (version 1.4.1, 29 Jul 2020)
  * rforest (version 1.6, Sep 2019)
  * estout (version 2.0.6 02jun2014)
  * unique (version 1.2.4 Jun 17, 2020)
  * grc1leg (version 1.0.5 02jun2010)
  * grc1leg2 (version 1.2 11nov2019)
  * tsspell (version 2.1.0 NJC 11 May 2014)
  * shapley2 (version 1.5 10jun15)
  * coefplot (version 1.7.5 29jan2015 )
  * All the packages above are included in the "DataWork/ado" folder, and "DataWork/global\_setup.do" will install all dependencies locally, and should be run once. This file is run inside the "MasterDofile.do".

2. Java (last run with version 8 update 371)
3. Excel (last run with Office 365, version 2306)

### Controlled Randomness

- Random seed is set as "20200520" of program "DataWork/global\_setup.do"

### Summary

Approximate time needed to reproduce the analyses on a standard 2023 desktop machine:

1. All codes: 1-3 hours
2. All codes excluding "DataWork/Dofiles/Construct/GLM\_ML\_comparison.do"
 10-30 minutes.

_Note: "GLM\_ML\_comparison.do" file replicates merely the numbers in the footnote 9 and does not replicate any other analyses in the main text and in the appendix._

### Details

The code was last run on a **6-core AMD Ryzen 5 3600 desktop with Windows 11 Pro version 22H2**. Computation took 104 minutes. (13 minutes excluding "GLM\_ML\_comparison.do")

## Description of programs/code
- "Datawork/Dofiles/MasterDofile.do" file: setup default path, declares global macros, and run all other sub-dofiles. Sub-dofiles can be run or not run by adjusting local macro counters.
- "DataWork/Dofiles/global\_setup.do" declares global macros used in other do-files (i.e. regression model specification), and set up the user-written commands used in this study. It needs to be run once before running other do-files, and it is called inside "MasterDofile.do" above.
- "Datawork/Dofiles/Cleaning/FSD\_clean.do" file imports raw files and does basic cleaning.
- "Datawork/Dofiles/Construct/FSD\_cost.do" file does additional cleaning and constructs outcome variables used in the paper. It also replicates some of the tables/figures in Appendix D.
- "Datawork/Dofiles/Construct/FSD\_analyses.do" file replicates all tables and figures in the main text, and some of them in the Appendix D. Output files are called appropriate names (Tab\_5.xlsx, Fig\_3.png) and should be easy to correlate with the manuscript.
- "Datawork/Dofiles/Construct/Appendix\_?.do" files replicate tables and figures in the Appendix ?. (?: A to D). Some tables and figures in Appendix D are replicates from other do-files.
- "Datawork/Dofiles/Construct/Recall\_seam\_period.do" file replicates the numbers mentioned in the main text and footnote.
- "Datawork/Dofiles/Construct/GLM\_ML\_comparison.do" file replicate the numbers mentioned in the footnote 9.

### License for Code

Codes are licensed under the BSD-3-Clause. See LICENSE.txt for details.

## List of tables and programs

The provided code reproduces:

- All numbers provided in text in the paper
- Selected tables and figures in the paper, as explained and justified below.

Figure/Table #	|	Program Name	|	Program Line No(s).	|
---	|	---	|	---	|
Table 1	|	FSD_analyses.do	|	100-106	|
Table 2	|	FSD_analyses.do	|	515-528	|
Table 3	|	FSD_analyses.do	|	1068-1078	|
Table 4	|	FSD_analyses.do	|	1170-1212	|
Table 5	|	FSD_analyses.do	|	1726-1775	|
Table A1	|	Appendix A.do	|	77-103	|
Table A2	|	Appendix A.do	|	136-148	|
Table B1	|	Appendix B.do	|	68-105	|
Table B2	|	Appendix B.do	|	112-141	|
Table B3	|	Appendix B.do	|	524-535	|
Table B4	|	Appendix B.do	|	1027-1033	|
Table B5	|	Appendix B.do	|	1075-1117	|
Table B6	|	Appendix B.do	|	1592-1641	|
Table C1	|	Appendix C.do	|	68-75	|
Table C2	|	Appendix C.do	|	199-206	|
Table C3	|	Appendix C.do	|	574-656	|
Table C4	|	Appendix C.do	|	689-740	|
Table D1    |        ---        | Coleman-Jensen et al. (2022) |
Table D2    |        ---        | Bickel et al. (2000) |
Table D3	|	Appendix D.do	|	27-87	|
Table D4	|	Appendix D.do	|	90-146	|
Table D5	|	FSD_const.do	|	1498-1554	|
Table D6	|	FSD_analyses.do	|	1130-1135	|
Table D7	|	FSD_analyses.do	|	1055-1061	|
Figure 1	|	FSD_analyses.do	|	165-185	|
Figure 2	|	FSD_analyses.do	|	537-544	|
Figure 3\*	|	FSD_analyses.do	|	555-570	|
Figure 4	|	FSD_analyses.do	|	1069-1104	|
Figure 5	|	FSD_analyses.do	|	1189-1195	|
Figure 6	|	FSD_analyses.do	|	1523-1562	|
Figure 7\*	|	FSD_analyses.do	|	1620-1643	|
Figure B1	|	Appendix B.do	|	223-259	|
Figure B2	|	Appendix B.do	|	544-575	|
Figure B3	|	Appendix B.do	|	577-592	|
Figure B4	|	Appendix B.do	|	872-912	|
Figure B5	|	Appendix B.do	|	1163-1167	|
Figure B6	|	Appendix B.do	|	1456-1497	|
Figure B7\*	|	Appendix B.do	|	1508-1534	|
Figure C1	|	Appendix C.do	|	785-800	|
Figure C2	|	Appendix C.do	|	746-762	|
Figure D1	|	Appendix D.do	|	155-168	|
Figure D2	|	Appendix D.do	|	170-178	|
Figure D3	|	Appendix D.do	|	249-292	|
Figure D4\*	|	FSD_analyses.do	|	205-211	|
Figure D5	|	FSD_analyses.do	|	1619-1646	|

\* These figures are generated inside Microsoft Excel, as these figures cannot be directly generated in Stata which does not support various fill patterns in bar graphs. Programs export data matrix to Excel files which feed the corresponding figures. These excel files are included in the package. DO NOT DELETE THESE EXCEL FILES IN THE PACKAGE, OR THE DATA EXPORTED CANNOT BE GENERATED AS FIGURES.

## Article Citation

Title of the paper: Food Security Dynamics in the United States, 2001-2017<br>
Journal: _American Journal of Agricultural Economics_  
DOI:  [DOI - Digital Object Identifier]    

Author 1 Name: Seungmin Lee<br>
Author 1 Institution: _Cornell University_<br>
Author 1 ORCID: 0000-0003-4909-6106  

Author 2 Name: Christopher B. Barrett<br>
Author 2 Institution: _Cornell University_<br> 
Author 2 ORCID: 0000-0001-9139-2721  

Author 3 Name: John F. Hoddinott<br>
Author 3 Institution: _Cornell University_<br> 
Author 3 ORCID: 0000-0002-0590-3917  

Corresponding author:  Seungmin Lee<br>
Contact details:  email: sl3235@cornell.edu  

Study Mnemonic: R2-2023-LEE-1

---

## Code Citation

Code Author 1 Name: Seungmin Lee<br>
Code Author 1 ORCID: 0000-0003-4909-6106  

Year of Publication: 2023<br>
Title of Reproducibility package:  "Replication files for Food Security Dynamics in the Unitd States, 2001-2017  (version 1)<br>
Location and Distribution:  Ithaca, NY:  Cornell Center for Social Science (Florio Arguillas)<br>
DOI: [enter DOI of the replication files catalog for this study]

---

## References

Ahrens, Achim, Christian B. Hansen, and Mark E. Schaffer. 2020. "lassopack: Model selection and prediction with regularized regression in Stata." _Stata Journal_ 20 (1): 176–235

Bickel, Gary, Mark Nord, Cristofer Price, William Hamilton, and John Cook. 2000. _Guide to Measuring Household Food Security, Revised 2000_. Alexandria, VA: U.S. Department of Agriculture, Food & Nutrition Service.

Brady, Tony. 1998. _UNIQUE: Stata module to report number of unique values in variable(s)_. Statistical Software Components, Boston College Department of Economics

Coleman-Jensen, Alisha, Matthew P. Rabbitt, Christian A. Gregory, and Anita Singh. 2022. _Household Food Security in the United States in 2021_. ERR-309. U.S. Department of Agriculture, Economic Research Service

Cox, Nicholas J. 1998. _WINSOR: Stata module to Winsorize a variable_. Statistical Software Components, Boston College Department of Economics

Cox, Nicholas J. 2002. _TSSPELL: Stata module for identification of spells or runs in time series_. Statistical Software Components, Boston College Department of Economics

Jann, Ben. 2007. "Making Regression Tables Simplified." _The Stata Journal: Promoting communications on statistics and Stata_ 7 (2): 227–244

Jann, Ben.2023. _COEFPLOT: Stata module to plot regression coefficients and other results_

Kohler, Ulrich. 2021. _PSIDTOOLS: Stata module to facilitate access to Panel Study of Income Dynamics (PSID)_.

Schonlau, Matthias, and Rosie Yuyan Zou. 2020. "The random forest algorithm for statistical learning." _The Stata Journal_ 20 (1): 3–29.

Wendelspiess Chávez Juárez, Florian. 2015. _SHAPLEY2: Stata module to compute additive decomposition of estimation statistics by regressors or groups of regressors_.

## Acknowledgements

Some content on this page was copied from [Hindawi](https://www.hindawi.com/research.data/#statement.templates). Other content was adapted from [Fort (2016)](https://doi.org/10.1093/restud/rdw057), Supplementary data, with the author's permission.