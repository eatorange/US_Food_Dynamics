/*----------------------------------------------------------------------*
| This example program demonstrates a relatively simple method for      |
| merging PSID data.  It uses data from 3 different years, subset-      |
| ting criteria, and the compress and tagsort options.                  |
|                                                                       |
| When working with PSID data, the amount of available system disk      |
| space and memory is often an important consideration.                 |
|                                                                       |
| merge command uses syntax for STATA 12, for earlier versions of STATA |
| it should be modified accordingly                                     |
*-----------------------------------------------------------------------*/

#delimit ;

cd "[FOLDER NAME]" ;
tempfile IND90_92 FAM90 FAM91 FAM92 ;

* Read in cross-year individual file and select variables
*   from 1990-1992 needed for analysis;

infix
    ER30001     2 - 5
    ER30002     6 - 8
    ER30642  1528 - 1532
    ER30643  1533 - 1534
    ER30644  1535 - 1536
    ER30645  1537 - 1539
    ER30653  1555 - 1555
    ER30657  1563 - 1564
    ER30659  1566 - 1571
    ER30689  1647 - 1650
    ER30690  1651 - 1652
    ER30691  1653 - 1654
    ER30692  1655 - 1657
    ER30699  1672 - 1672
    ER30703  1680 - 1681
    ER30705  1683 - 1688
    ER30707  1690 - 1695
    ER30733  1764 - 1767
    ER30734  1768 - 1769
    ER30735  1770 - 1771
    ER30736  1772 - 1774
    ER30744  1790 - 1790
    ER30748  1798 - 1799
    ER30750  1801 - 1806
    ER30752  1808 - 1813
    ER30805  1907 - 1913
    ER32000  2057 - 2057
    ER32022  2111 - 2112
    ER32049  2187 - 2187
using "[PATH]\IND2017ER.txt", clear
;

label variable ER30001        "1968 INTERVIEW NUMBER" ;
label variable ER30002        "PERSON NUMBER                 68" ;
label variable ER30642        "1990 INTERVIEW NUMBER" ;
label variable ER30643        "SEQUENCE NUMBER90" ;
label variable ER30644        "RELATION TO HEAD              90" ;
label variable ER30645        "AGE OF INDIVIDUAL             90" ;
label variable ER30653        "EMPLOYMENT STAT-IND           90" ;
label variable ER30657        "COMPLETED EDUC-IND            90" ;
label variable ER30659        "TOT TXBL INCOME-IND           90" ;
label variable ER30689        "1991 INTERVIEW NUMBER"            ;
label variable ER30690        "SEQUENCE NUMBER91" ;
label variable ER30691        "RELATION TO HEAD              91" ;
label variable ER30692        "AGE OF INDIVIDUAL             91" ;
label variable ER30699        "EMPLOYMENT STAT-IND           91" ;
label variable ER30703        "COMPLETED EDUC-IND            91" ;
label variable ER30705        "TOT LABOR INCOME-IND          91" ;
label variable ER30707        "TOT ASSET INCOME-IND          91" ;
label variable ER30733        "1992 INTERVIEW NUMBER" ;
label variable ER30734        "SEQUENCE NUMBER92" ;
label variable ER30735        "RELATION TO HEAD              92" ;
label variable ER30736        "AGE OF INDIVIDUAL             92" ;
label variable ER30744        "EMPLOYMENT STAT               92" ;
label variable ER30748        "COMPLETED EDUCATION           92" ;
label variable ER30750        "TOT LABOR INCOME              92" ;
label variable ER30752        "TOT ASSET INCOME              92" ;
label variable ER30805        "COMBINED IND WEIGHT           92" ;
label variable ER32000        "SEX OF INDIVIDUAL" ;
label variable ER32022        "# LIVE BIRTHS TO THIS INDIVIDUAL" ;
label variable ER32049        "LAST KNOWN MARITAL STATUS" ;

rename ER30642 ID90 ;
rename ER30689 ID91 ;
rename ER30733 ID92 ;

replace ER30645=. if ER30645==999 ;
replace ER30657=. if ER30657==99  ;
replace ER30692=. if ER30692==999 ;
replace ER30703=. if ER30703==99  ;
replace ER30736=. if ER30736==999 ;
replace ER30748=. if ER30748==99  ;
replace ER32022=. if ER32022==98  ;
replace ER32049=. if ER32049==8   ;

* Select those who were ever heads or wives/"wives" between 1990 and 1992 ;

keep if (
    (ER30643 == 01 &  ER30644 == 10) |
    (ER30643 == 02 & (ER30644 == 20  | ER30644 == 22)) |
    (ER30690 == 01 &  ER30691 == 10) |
    (ER30690 == 02 & (ER30691 == 20  | ER30691 == 22)) |
    (ER30734 == 01 &  ER30735 == 10) |
    (ER30734 == 02 & (ER30735 == 20  | ER30735 == 22))
) ;

sort ER30001 ER30002 ;
save "`IND90_92'" ;

* Read in 1990 family file and select variables needed for analysis ;

infix
	V17702     2 - 6
	V17836   281 - 286
	V18262  1175 - 1177
	V18564  1656 - 1658
	V18814  2046 - 2046
	V18878  2188 - 2193
	V18887  2230 - 2234
	V18888  2235 - 2239
using "[PATH]\FAM1990.txt", clear
;

label variable V17702 "1990 INTERVIEW NUMBER"    ;
label variable V17836 "WIFE 89 LABOR/WAGE"       ;
label variable V18262 "C9-10 OCC-LAST JOB (H-U)" ;
label variable V18564 "E9-10 OCC-LAST JOB (W-U)" ;
label variable V18814 "M32 RACE OF HEAD (1 MEN)" ;
label variable V18878 "TOTAL HEAD LABOR Y 89"    ;
label variable V18887 "HEAD 89 AVG HRLY EARNING" ;
label variable V18888 "WIFE 89 AVG HRLY EARNING" ;

rename V17702 ID90 ;

replace V18262=. if V18262==999 ;
replace V18564=. if V18564==999 ;
replace V18814=. if V18814==9   ;

sort ID90 ;
save "`FAM90'" ;

* Merge fam90 and ind90_92 by id90 ;
merge 1:m ID90 using "`IND90_92'" , keep(using matched) ;
drop _merge ;
save "FAM_IND" , replace ;

* Read in 1991 family file and select variables needed for analysis;

infix
    V19002     2 - 5
    V19136   281 - 286
    V19562  1175 - 1177
    V19864  1656 - 1658
    V20114  2046
    V20178  2188 - 2193
    V20187  2230 - 2234
    V20188  2235 - 2239
using "[PATH]\FAM1991.txt", clear
;

label variable V19002 "1991 INTERVIEW NUMBER"    ;
label variable V19136 "WIFE 90 LABOR/WAGE"       ;
label variable V19562 "C9-10 OCC-LAST JOB (H-U)" ;
label variable V19864 "E9-10 OCC-LAST JOB (W-U)" ;
label variable V20114 "L32 RACE OF HEAD (1 MEN)" ;
label variable V20178 "TOTAL HEAD LABOR Y 90"    ;
label variable V20187 "HEAD 90 AVG HRLY EARNING" ;
label variable V20188 "WIFE 90 AVG HRLY EARNING" ;

rename V19002 ID91 ;

replace V19562=. if V19562==999 ;
replace V19864=. if V19864==999 ;
replace V20114=. if V20114==9   ;

sort ID91 ;
save "`FAM91'" ;

* Merge fam91 and fam_ind by id91 ;
merge 1:m ID91 using FAM_IND , keep(using matched);
drop _merge ;
save "FAM_IND" , replace ;

* Read in 1992 family file and select variables needed for analysis;

infix
       V20302     2 - 5
       V20436   282 - 287
       V20862  1189 - 1191
       V21164  1670 - 1672
       V21420  2066
       V21484  2172 - 2177
       V21493  2218 - 2222
       V21494  2223 - 2227
using "[PATH]\FAM1992.txt", clear
;

label variable V20302 "1992 INTERVIEW NUMBER"    ;
label variable V20436 "WIFE 91 LABOR/WAGE"       ;
label variable V20862 "C9-10 OCC-LAST JOB (H-U)" ;
label variable V21164 "E9-10 OCC-LAST JOB (W-U)" ;
label variable V21420 "M32 RACE OF HEAD (1 MEN)" ;
label variable V21484 "TOTAL HEAD LABOR Y 91"    ;
label variable V21493 "HEAD 91 AVG HRLY EARNING" ;
label variable V21494 "WIFE 91 AVG HRLY EARNING" ;

rename V20302 ID92 ;

replace V20862=. if V20862==999 ;
replace V21164=. if V21164==999 ;
replace V21420=. if V21420==9   ;

sort ID92 ;
save "`FAM92'" ;

* Merge fam92 and fam_ind by id92 ;
merge 1:m ID92 using FAM_IND , keep(using matched);
drop _merge ;
sort ID92 ID91 ID90 ER30001 ER30002 ;
save "FAM_IND" , replace ;