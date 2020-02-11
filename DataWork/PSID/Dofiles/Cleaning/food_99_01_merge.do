
* This do-file is a temporary do-file which tries to understand & manually replicate automatic merging of families over the years in PSID data center.
* This do-file may be deleted after test & replication is completed. If this file needs to remain in repository for record purpose, the structure of this do-file would be significantly modified, or would be integrated into another file as a separate section

use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Customized\food_famliy_only\food_family_only.dta", clear
tempfile	foodvar_99_01_fam
save		`foodvar_99_01_fam'

use	"E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Customized\food_family_indiv\food_family_indiv.dta", clear
tempfile	foodvar_99_01_indiv
save		`foodvar_99_01_indiv'

use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\Cross_year_individual\Cross_year_individual.dta", clear
tempfile indiv_all
save	`indiv_all'

use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam1999\FAM1999.dta", clear
tempfile	FAM1999
save		`FAM1999'

use "E:\Box\US Food Security Dynamics\DataWork\PSID\DataSets\Raw\Main\fam2001\FAM2001.dta", clear
tempfile	FAM2001
save		`FAM2001'

*	Merge 1999 familes in 1999-2001 food variable data with 2001 using 1999 family ID (ER13002), to check iwhether ER13002 uniquely identifies
use	`foodvar_99_01_fam', clear
keep if !mi(ER13002)
merge 1:1 ER13002 using `FAM1999', nogen assert(3)
** All households are matched 1:1. Thus family ID uniquely identifies between 1999 families in cross-year index custom data and 1999 package data.


*	The main concern is merging family-level variables over the years, as there is no ID in family data that uniquely identifies families over time. (1968 family ID can't be used, as splitted family share the same 1968 family ID)
*	According to PSID data structure file, PSID uses head of the household (sequence number==1 since 1983) to merge family variables over time. We will manually confirm whether it is true.

*	First, find families whose members are splitted into other families (thus have same 1999 family ID but different food expenditures in 2001)

use	`foodvar_99_01_indiv', clear
sort ER33501 ER33601
order ER33501 ER33502 ER16515A1 ER16515A2 ER16515A3  ER33601 ER33602 ER20456A1 ER20456A2 ER20456A3 
br ER33501 ER33502 ER16515A1 ER16515A2 ER16515A3  ER33601 ER33602 ER20456A1 ER20456A2 ER20456A3  if ER33502==1 & ER33602!=1

*	Below are some families splitted in between (ER33501=2,6)
/*
ER33501	ER33502	ER16515A1		ER16515A2	ER16515A3	ER33601	ER33602	ER20456A1	ER20456A2	ER20456A3
2	0	7280	5200	2080	5479	2	7020	5200	1820
2	1	7280	5200	2080	96		1	4680	3120	1560
2	2	7280	5200	2080	96		2	4680	3120	1560
2	3	7280	5200	2080	96		3	4680	3120	1560
2	4	7280	5200	2080	5479	1	7020	5200	1820
6	0	6944	5744.69	1200	6942	1	4320	3600	720
6	0	6944	5744.69	1200	6942	3	4320	3600	720
6	1	6944	5744.69	1200	3072	1	4800	3600	1200
6	2	6944	5744.69	1200	3072	2	4800	3600	1200
6	3	6944	5744.69	1200	6942	2	4320	3600	720
6	4	6944	5744.69	1200	3072	3	4800	3600	1200
6	5	6944	5744.69	1200	3072	4	4800	3600	1200
6	6	6944	5744.69	1200	3072	5	4800	3600	1200
6	7	6944	5744.69	1200	3072	6	4800	3600	1200
6	8	6944	5744.69	1200	3072	7	4800	3600	1200
*/

*	Now we will see how auto-merged family-level data look like
use	`foodvar_99_01_fam', clear
order ER13002 ER16515A1 ER16515A2 ER16515A3  ER17002 ER20456A1 ER20456A2 ER20456A3 

*	1999 Families who were splitted in between
br ER13002 ER16515A1 ER16515A2 ER16515A3  ER17002 ER20456A1 ER20456A2 ER20456A3  if inlist(ER13002,2,6)
/*
ER13002	ER16515A1	ER16515A2	ER16515A3	ER17002	ER20456A1	ER20456A2	ER20456A3
2	7280	5200	2080	96	4680	3120	1560
6	6944	5744.69	1200	3072	4800	3600	1200
* From the result above, we confirm that PSID uses household head to merge family-level variables over the years
*/

*	Newly splitted households in between
br ER13002 ER16515A1 ER16515A2 ER16515A3  ER17002 ER20456A1 ER20456A2 ER20456A3  if inlist(ER17002,5479,6942)
/*
ER13002	ER16515A1	ER16515A2	ER16515A3	ER17002	ER20456A1	ER20456A2	ER20456A3
												5479	7020	5200	1820
												6942	4320	3600	720
* From the result above, we confirm that those who were splitted in 2001 do have missing values in 1999 data
*/



*	Then we have another question here; what if household head in 1999 is no longer a head in 2001?
*	We will observe how PSID manages it 
use	`foodvar_99_01_indiv', clear
sort ER33501 ER33601
order ER33501 ER33502 ER16515A1 ER16515A2 ER16515A3  ER33601 ER33602 ER20456A1 ER20456A2 ER20456A3 
*	Individuals who were head in 1999 but were not in 2001
br ER33501 ER33502 ER16515A1 ER16515A2 ER16515A3  ER33601 ER33602 ER20456A1 ER20456A2 ER20456A3  if ER33502==1 & ER33602!=1


*	Check how food variables are assigned if household head changed
*	Individual is household head if sequence number==1 (1999 sequence No is ER33502)
use	`foodvar_99_01_indiv', clear
sort ER33501 ER33601
order ER33501 ER33502 ER16515A1 ER16515A2 ER16515A3 ER16515A4 ER33601 ER33602 ER20456A1 ER20456A2 ER20456A3 ER20456A4
br ER33501 ER33502 ER16515A1 ER16515A2 ER16515A3 ER16515A4 ER33601 ER33602 ER20456A1 ER20456A2 ER20456A3 ER20456A4 if ER33502==1 & ER33602!=1	//	HH who household head changed since 1999


/* Some families with household head change
ER33501	ER33502	ER16515A1	ER16515A2	ER16515A3	ER33601	ER33602	ER20456A1	ER20456A2	ER20456A3
3	1	2100	2100	0	0	0			
9	1	2236	1820	416.91	0	0			
29	1	520	520	0	0	0			
51	1	5980	2600	3380	2148	2	6500	3380	3120
69	1	1560	1560	0	0	0			
70	1	2600	2600	0	4179	81	7800	7800	0
71	1	1300	780	520	4178	2	5720	3120	2600
86	1	3580	2080	1500	2658	2	6880	5200	960
92	1	1490	1490.39	0	0	0			
93	1	4680	3120	1560	322	81	4680	2340	2340
*/
br ER33501 ER33502 ER16515A1 ER16515A2 ER16515A3 ER33601 ER33602 ER20456A1 ER20456A2 ER20456A3 if inlist(ER33501,3,9,29,51,69,70,71,86,92,93)


*/


** Test 


*	How family-level costs are imputed
use	`indiv_all', clear
keep ER30001 ER30002 ER33501-ER33547
drop	if	mi(ER33501) | ER33501==0

rename	ER33501 ER13002
merge	m:1	ER13002 using `FAM1999'

