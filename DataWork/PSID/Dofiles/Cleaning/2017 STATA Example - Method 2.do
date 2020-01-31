/*-----------------------------------------------------------------------*
|              MERGE USING MULTIPLE FAMILY-INDIVIDUAL FILES              |
|                                                                        |
|   Step 1:    Subset family-level id's and selected variables           |
|                  and select cases from xyr-individual file             |
|                                                                        |
|   Step 2a:   Subset year-n family file                                 |
|   Step 2b:   Sort year-n family file from 2a by year-n family id       |
|   Step 2c:   Sort xyr-individual file from step 1 by year-n family id  |
|   Step 2d:   Merge sorted xyr-individual file from 2c                  |
|                  with sorted year-n subsetted family file from 2b      |
|                  (a one-to-many [family-to-individual] match)          |
|   Step 2e:   Sort resulting year-n family-individual file from 2d      |
|                   by individual ids                                    |
|                                                                        |
|     ...        Repeat Steps 2 for all other years                      |
|                                                                        |
|   Step 3:    Merge family-individual files from step 2e                |
|                                                                        |
| merge command uses syntax for STATA 12, for earlier versions of STATA  |
| it should be modified accordingly                                      |
*------------------------------------------------------------------------*/
#delimit ;

cd "[FOLDER NAME]" ;
tempfile
    FAM68 FAM69 FAM70 FAM71 FAM72 FAM73 FAM74 FAM75 FAM76 FAM77 FAM78 FAM79
    FAM80 FAM81 FAM82 FAM83 FAM84 FAM85 FAM86 FAM87 FAM88 FAM89
    FAM90 FAM91 FAM92 FAM93 FAM94 FAM95 FAM96 FAM97 FAM99
    FAM01 FAM03 FAM05 FAM07 FAM09 FAM11 FAM13 FAM15 FAM17
;

/* =================================================================== */
/*      step 1: subset family-level id's and individual variables      */
/*        and select cases from cross-year individual record           */
/* =================================================================== */

infix
    /*  1968 ID and PN */  ER30001  2-5  ER30002  6-8
    /*  1969  */ ER30020 44 - 47
    /*  1970  */ ER30043 97 - 100
    /*  1971  */ ER30067 152 - 155
    /*  1972  */ ER30091 207 - 210
    /*  1973  */ ER30117 265 - 268
    /*  1974  */ ER30138 317 - 320
    /*  1975  */ ER30160 370 - 373
    /*  1976  */ ER30188 436 - 439
    /*  1977  */ ER30217 503 - 506
    /*  1978  */ ER30246 571 - 574
    /*  1979  */ ER30283 648 - 651
    /*  1980  */ ER30313 718 - 721
    /*  1981  */ ER30343 788 - 791
    /*  1982  */ ER30373 858 - 861
    /*  1983  */ ER30399 919 - 922
    /*  1984  */ ER30429 992 - 995
    /*  1985  */ ER30463 1077 - 1080
    /*  1986  */ ER30498 1167 - 1170
    /*  1987  */ ER30535 1259 - 1262
    /*  1988  */ ER30570 1348 - 1351
    /*  1989  */ ER30606 1438 - 1441
    /*  1990  */ ER30642 1528 - 1532
    /*  1991  */ ER30689 1647 - 1650
    /*  1992  */ ER30733 1764 - 1767
    /*  1993  */ ER30806 1914 - 1918
    /*  1994  */ ER33101 2196 - 2200
    /*  1995  */ ER33201 2295 - 2299
    /*  1996  */ ER33301 2488 - 2491
    /*  1997  */ ER33401 2572 - 2576
    /*  1999  */ ER33501 2657 - 2661
    /*  2001  */ ER33601 2851 - 2854
    /*  2003  */ ER33701 3033 - 3037
    /*  2005  */ ER33801 3188 - 3192
    /*  2007  */ ER33901 3487 - 3491
    /*  2009  */ ER34001 3765 - 3769
    /*  2011  */ ER34101 3987 - 3991
    /*  2013  */ ER34201 4224 - 4228
    /*  2015  */ ER34301 4490 - 4494
    /*  2017  */ ER34501 4864 - 4868

    /*  your individual variable locations here  */

using "[PATH]\IND2017ER.txt" , clear
;

    label variable ER30001 "1968 INTERVIEW NUMBER 68" ;
    label variable ER30002 "PERSON NUMBER         68" ;
    label variable ER30020 "1969 INTERVIEW NUMBER 69" ;
    label variable ER30043 "1970 INTERVIEW NUMBER 70" ;
    label variable ER30067 "1971 INTERVIEW NUMBER 71" ;
    label variable ER30091 "1972 INTERVIEW NUMBER 72" ;
    label variable ER30117 "1973 INTERVIEW NUMBER 73" ;
    label variable ER30138 "1974 INTERVIEW NUMBER 74" ;
    label variable ER30160 "1975 INTERVIEW NUMBER 75" ;
    label variable ER30188 "1976 INTERVIEW NUMBER 76" ;
    label variable ER30217 "1977 INTERVIEW NUMBER 77" ;
    label variable ER30246 "1978 INTERVIEW NUMBER 78" ;
    label variable ER30283 "1979 INTERVIEW NUMBER 79" ;
    label variable ER30313 "1980 INTERVIEW NUMBER 80" ;
    label variable ER30343 "1981 INTERVIEW NUMBER 81" ;
    label variable ER30373 "1982 INTERVIEW NUMBER 82" ;
    label variable ER30399 "1983 INTERVIEW NUMBER 83" ;
    label variable ER30429 "1984 INTERVIEW NUMBER 84" ;
    label variable ER30463 "1985 INTERVIEW NUMBER 85" ;
    label variable ER30498 "1986 INTERVIEW NUMBER 86" ;
    label variable ER30535 "1987 INTERVIEW NUMBER 87" ;
    label variable ER30570 "1988 INTERVIEW NUMBER 88" ;
    label variable ER30606 "1989 INTERVIEW NUMBER 89" ;
    label variable ER30642 "1990 INTERVIEW NUMBER 90" ;
    label variable ER30689 "1991 INTERVIEW NUMBER 91" ;
    label variable ER30733 "1992 INTERVIEW NUMBER 92" ;
    label variable ER30806 "1993 INTERVIEW NUMBER 93" ;
    label variable ER33101 "1994 INTERVIEW NUMBER 94" ;
    label variable ER33201 "1995 INTERVIEW NUMBER 95" ;
    label variable ER33301 "1996 INTERVIEW NUMBER 96" ;
    label variable ER33401 "1997 INTERVIEW NUMBER 97" ;
    label variable ER33501 "1999 INTERVIEW NUMBER 99" ;
    label variable ER33601 "2001 INTERVIEW NUMBER 01" ;
    label variable ER33701 "2003 INTERVIEW NUMBER 03" ;
    label variable ER33801 "2005 INTERVIEW NUMBER 05" ;
    label variable ER33901 "2007 INTERVIEW NUMBER 07" ;
    label variable ER34001 "2009 INTERVIEW NUMBER 09" ;
    label variable ER34101 "2011 INTERVIEW NUMBER 11" ;
    label variable ER34201 "2013 INTERVIEW NUMBER 13" ;
    label variable ER34301 "2015 INTERVIEW NUMBER 15" ;
    label variable ER34501 "2017 INTERVIEW NUMBER 17" ;
    /*      your individual variable labels here              */

    /*      your individual missing data here                 */

    /*      your filter for case selection, if any, here
      this selects the first 10 cases for testing setup */

    sort ER30001 ;

save INDVARS , replace;

/* =================================================================== */
/*      Step 2 for 1968 family file (n=4802)                           */
/* =================================================================== */
infix
    V3 7-10
    /* your 1968 variable locations here */
using "[PATH]\FAM1968.txt" , clear
;
    label variable V3 "INTERVIEW NUMBER 68 1:6-9" ;
    /* your 1968 variable labels here */
    /* your 1968 missing data here */
    rename V3 ER30001 ;
    sort ER30001 ;
save "`FAM68'" ;

merge 1:m ER30001 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND68 , replace;

/* =================================================================== */
/*      step 2 for 1969 family file (n=4460)                           */
/* =================================================================== */
infix
    V442 2-5
    /* your 1969 variable locations here */
using "[PATH]\FAM1969.txt" , clear
;
    label variable V442 "1969 INT NUMBER 11:6-9" ;
    /* your 1969 variable labels here */
    /* your 1969 missing data here */
    rename V442 ER30020 ;
    sort ER30020 ;
save "`FAM69'" ;

merge 1:m ER30020 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND69 , replace;

/* =================================================================== */
/*      step 2 for 1970 family file (n=4645)                           */
/* =================================================================== */
infix
    V1102 2-5
    /* your 1970 variable locations here */
using "[PATH]\FAM1970.txt" , clear
;
    label variable V1102 "1970 INT # 21:6-9" ;
    /* your 1970 variable labels here */
    /* your 1970 missing data here */
    rename V1102 ER30043 ;
    sort ER30043 ;
save "`FAM70'" ;

merge 1:m ER30043 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND70 , replace;

 /* =================================================================== */
/*      step 2 for 1971 family file (n=4840)                           */
/* =================================================================== */
infix
    V1802 2-5
    /* your 1971 variable locations here */
using "[PATH]\FAM1971.txt" , clear
;
    label variable V1802 "71 ID NO." ;
    /* your 1971 variable labels here */
    /* your 1971 missing data here */
    rename V1802 ER30067 ;
    sort ER30067 ;
save "`FAM71'" ;

merge 1:m ER30067 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND71 , replace;

/* =================================================================== */
/*      step 2 for 1972 family file (n=5060)                           */
/* =================================================================== */
infix
    V2402 2-5
    /* your 1972 variable locations here */
using "[PATH]\FAM1972.txt" , clear
;
    label variable V2402 "1972 INT # 46:6-9" ;
    /* your 1972 variable labels here */
    /* your 1972 missing data here */
    rename V2402 ER30091 ;
    sort ER30091 ;
save "`FAM72'" ;

merge 1:m ER30091 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND72 , replace;

/* =================================================================== */
/*      step 2 for 1973 family file (n=5285)                           */
/* =================================================================== */
infix
    V3002 2-5
    /* your 1973 variable locations here */
using "[PATH]\FAM1973.txt" , clear
;
    label variable V3002 "1973 INT # 59:6-9" ;
    /* your 1973 variable labels here */
    /* your 1973 missing data here */
    rename V3002 ER30117 ;
    sort ER30117 ;
save "`FAM73'" ;

merge 1:m ER30117 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND73 , replace;

/* =================================================================== */
/*      step 2 for 1974 family file (n=5517)                           */
/* =================================================================== */
infix
    V3402 2-5
    /* your 1974 variable locations here */
using "[PATH]\FAM1974.txt" , clear
;
    label variable V3402 "1974 ID NUMBER" ;
    /* your 1974 variable labels here */
    /* your 1974 missing data here */
    rename V3402 ER30138 ;
    sort ER30138 ;
save "`FAM74'" ;

merge 1:m ER30138 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND74 , replace;

/* =================================================================== */
/*      step 2 for 1975 family file (n=5725)                           */
/* =================================================================== */
infix
    V3802 2-5
    /* your 1975 variable locations here */
using "[PATH]\FAM1975.txt" , clear
;
    label variable V3802 "1975 INT # 80:6-9" ;
    /* your 1975 variable labels here */
    /* your 1975 missing data here */
    rename V3802 ER30160 ;
    sort ER30160 ;
save "`FAM75'" ;

merge 1:m ER30160 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND75 , replace;

/* =================================================================== */
/*      step 2 for 1976 family file (n=5862)                           */
/* =================================================================== */
infix
    V4302 2-5
    /* your 1976 variable locations here */
using "[PATH]\FAM1976.txt" , clear
;
    label variable V4302 "1976 ID NUMBER 6V2" ;
    /* your 1976 variable labels here */
    /* your 1976 missing data here */
    rename V4302 ER30188 ;
    sort ER30188 ;
save "`FAM76'" ;

merge 1:m ER30188 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND76 , replace;

/* =================================================================== */
/*      step 2 for 1977 family file (n=6007)                           */
/* =================================================================== */
infix
    V5202 2-5

using "[PATH]\FAM1977.txt" , clear
;
    label variable V5202 "1977 ID" ;
    /* your 1977 variable labels here */
    /* your 1977 missing data here */
    rename V5202 ER30217 ;
    sort ER30217 ;
save "`FAM77'" ;

merge 1:m ER30217 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND77 , replace;

/* =================================================================== */
/*      step 2 for 1978 family file (n=6154)                           */
/* =================================================================== */
infix
    V5702 2-5
    /* your 1978 variable locations here */
using "[PATH]\FAM1978.txt" , clear
;
    label variable V5702 "1978 ID" ;
    /* your 1978 variable labels here */
    /* your 1978 missing data here */
    rename V5702 ER30246 ;
    sort ER30246 ;
save "`FAM78'" ;

merge 1:m ER30246 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND78 , replace;

/* =================================================================== */
/*      step 2 for 1979 family file (n=6373)                           */
/* =================================================================== */
infix
    V6302 2-5
    /* your 1979 variable locations here */
using "[PATH]\FAM1979.txt" , clear
;
    label variable V6302 "1979 ID" ;
    /* your 1979 variable labels here */
    /* your 1979 missing data here */
    rename V6302 ER30283 ;
    sort ER30283 ;
save "`FAM79'" ;

merge 1:m ER30283 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND79 , replace;

/* =================================================================== */
/*      step 2 for 1980 family file (n=6533)                           */
/* =================================================================== */
infix
    V6902 2-5
    /* your 1980 variable locations here */
using "[PATH]\FAM1980.txt" , clear
;
    label variable V6902 "1980 INTERVIEW NUMBER" ;
    /* your 1980 variable labels here */
    /* your 1980 missing data here */
    rename V6902 ER30313 ;
    sort ER30313 ;
save "`FAM80'" ;

merge 1:m ER30313 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND80 , replace;

/* =================================================================== */
/*      step 2 for 1981 family file (n=6620)                           */
/* =================================================================== */
infix
    V7502 2-5
    /* your 1981 variable locations here */
using "[PATH]\FAM1981.txt" , clear
;
    label variable V7502 "1981 INTERVIEW NUMBER" ;
    /* your 1981 variable labels here */
    /* your 1981 missing data here */
    rename V7502 ER30343 ;
    sort ER30343 ;
save "`FAM81'" ;

merge 1:m ER30343 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND81 , replace;

/* =================================================================== */
/*      step 2 for 1982 family file (n=6742)                           */
/* =================================================================== */
infix
    V8202 2-5
    /* your 1982 variable locations here */
using "[PATH]\FAM1982.txt" , clear
;
    label variable V8202 "1982 INTERVIEW NUMBER" ;
    /* your 1982 variable labels here */
    /* your 1982 missing data here */
    rename V8202 ER30373 ;
    sort ER30373 ;
save "`FAM82'" ;

merge 1:m ER30373 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND82 , replace;

/* =================================================================== */
/*      step 2 for 1983 family file (n=6852)                           */
/* =================================================================== */
infix
    V8802 2-5
    /* your 1983 variable locations here */
using "[PATH]\FAM1983.txt" , clear
;
    label variable V8802 "1983 INTERVIEW NUMBER" ;
    /* your 1983 variable labels here */
    /* your 1983 missing data here */
    rename V8802 ER30399 ;
    sort ER30399 ;
save "`FAM83'" ;

merge 1:m ER30399 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND83 , replace;

/* =================================================================== */
/*      step 2 for 1984 family file (n=6918)                           */
/* =================================================================== */
infix
    V10002 2-5
    /* your 1984 variable locations here */
using "[PATH]\FAM1984.txt" , clear
;
    label variable V10002 "1984 INTERVIEW NUMBER" ;
    /* your 1984 variable labels here */
    /* your 1984 missing data here */
    rename V10002 ER30429 ;
    sort ER30429 ;
save "`FAM84'" ;

merge 1:m ER30429 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND84 , replace;

/* =================================================================== */
/*      step 2 for 1985 family file (n=7032)                           */
/* =================================================================== */
infix
    V11102 2-5
    /* your 1985 variable locations here */
using "[PATH]\FAM1985.txt" , clear
;
    label variable V11102 "1985 INTERVIEW NUMBER" ;
    /* your 1985 variable labels here */
    /* your 1985 missing data here */
    rename V11102 ER30463 ;
    sort ER30463 ;
save "`FAM85'" ;

merge 1:m ER30463 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND85 , replace;

/* =================================================================== */
/*      step 2 for 1986 family file (n=7018)                           */
/* =================================================================== */
infix
    V12502 2-5
    /* your 1986 variable locations here */
using "[PATH]\FAM1986.txt" , clear
;
    label variable V12502 "1986 INTERVIEW NUMBER" ;
    /* your 1986 variable labels here */
    /* your 1986 missing data here */
    rename V12502 ER30498 ;
    sort ER30498 ;
save "`FAM86'" ;

merge 1:m ER30498 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND86 , replace;

/* =================================================================== */
/*      step 2 for 1987 family file (n=7061)                           */
/* =================================================================== */
infix
    V13702 2-5
    /* your 1987 variable locations here */
using "[PATH]\FAM1987.txt" , clear
;
    label variable V13702 "1987 INTERVIEW NUMBER" ;
    /* your 1987 variable labels here */
    /* your 1987 missing data here */
    rename V13702 ER30535 ;
    sort ER30535 ;
save "`FAM87'" ;

merge 1:m ER30535 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND87 , replace;

/* =================================================================== */
/*      step 2 for 1988 family file (n=7114)                           */
/* =================================================================== */
infix
    V14802 2-5
    /* your 1988 variable locations here */
using "[PATH]\FAM1988.txt" , clear
;
    label variable V14802 "1988 INTERVIEW NUMBER" ;
    /* your 1988 variable labels here */
    /* your 1988 missing data here */
    rename V14802 ER30570 ;
    sort ER30570 ;
save "`FAM88'" ;

merge 1:m ER30570 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND88 , replace;

/* =================================================================== */
/*      step 2 for 1989 family file (n=7114)                           */
/* =================================================================== */
infix
    V16302 2-5
    /* your 1989 variable locations here */
using "[PATH]\FAM1989.txt" , clear
;
    label variable V16302 "1989 INTERVIEW NUMBER" ;
    /* your 1989 variable labels here */
    /* your 1989 missing data here */
    rename V16302 ER30606 ;
    sort ER30606 ;
save "`FAM89'" ;

merge 1:m ER30606 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND89 , replace;

/* =================================================================== */
/*      step 2 for 1990 family file (n=9371)                           */
/* =================================================================== */
infix
    V17702 2-6
    /* your 1990 variable locations here */
using "[PATH]\FAM1990.txt" , clear
;
    label variable V17702 "1990 INTERVIEW NUMBER 90" ;
    /* your 1990 variable labels here */
    /* your 1990 missing data here */
    rename V17702 ER30642 ;
    sort ER30642 ;
save "`FAM90'" ;

merge 1:m ER30642 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND90 , replace;

/* =================================================================== */
/*      step 2 for 1991 family file (n=9363)                           */
/* =================================================================== */
infix
    V19002 2-5
    /* your 1991 variable locations here */
using "[PATH]\FAM1991.txt" , clear
;
    label variable V19002 "1991 INTERVIEW NUMBER" ;
    /* your 1991 variable labels here */
    /* your 1991 missing data here */
    rename V19002 ER30689 ;
    sort ER30689 ;
save "`FAM91'" ;

merge 1:m ER30689 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND91 , replace;

/* =================================================================== */
/*      step 2 for 1992 family file (n=9829)                           */
/* =================================================================== */
infix
    V20302 2-5
    /* your 1992 variable locations here */
using "[PATH]\FAM1992.txt" , clear
;
    label variable V20302 "1992 INTERVIEW NUMBER" ;
    /* your 1992 variable labels here */
    /* your 1992 missing data here */
    rename V20302 ER30733 ;
    sort ER30733 ;
save "`FAM92'" ;

merge 1:m ER30733 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND92 , replace;

/* =================================================================== */
/*      step 2 for 1993 family file (n=9977)                           */
/* =================================================================== */
infix
    V21602 2-6
    /* your 1993 variable locations here */
using "[PATH]\FAM1993.txt" , clear
;
    label variable V21602 "1993 INTERVIEW NUMBER" ;
    /* your 1993 variable labels here */
    /* your 1993 missing data here */
    rename V21602 ER30806 ;
    sort ER30806 ;
save "`FAM93'" ;

merge 1:m ER30806 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND93 , replace;

/* =================================================================== */
/*      step 2 for 1994 family file (n=10764)                          */
/* =================================================================== */
infix
    ER2002 2-6
    /* your 1994 variable locations here */
using "[PATH]\FAM1994ER.txt" , clear
;
    label variable ER2002 "1994 INTERVIEW #" ;
    /* your 1994 variable labels here */
    /* your 1994 missing data here */
    rename ER2002 ER33101 ;
    sort ER33101 ;
save "`FAM94'" ;

merge 1:m ER33101 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND94 , replace;

/* =================================================================== */
/*      step 2 for 1995 family file (n=10401)                          */
/* =================================================================== */
infix
    ER5002 2-6
    /* your 1995 variable locations here */
using "[PATH]\FAM1995ER.txt" , clear
;
    label variable ER5002 "1995 INTERVIEW #" ;
    /* your 1995 variable labels here */
    /* your 1995 missing data here */
    rename ER5002 ER33201 ;
    sort ER33201 ;
save "`FAM95'" ;

merge 1:m ER33201 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND95 , replace;

/* =================================================================== */
/*      step 2 for 1996 family file (n=8511)                           */
/* =================================================================== */
infix
    ER7002 2-5
    /* your 1996 variable locations here */
using "[PATH]\FAM1996ER.txt" , clear
;
    label variable ER7002 "1996 INTERVIEW #" ;
    /* your 1996 variable labels here */
    /* your 1996 missing data here */
    rename ER7002 ER33301 ;
    sort ER33301 ;
save "`FAM96'" ;

merge 1:m ER33301 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND96 , replace;

/* =================================================================== */
/*      step 2 for 1997 family file (n=6747)                           */
/* =================================================================== */
infix
    ER10002 2-6
    /* your 1997 variable locations here */
using "[PATH]\FAM1997ER.txt" , clear
;
    label variable ER10002 "1997 INTERVIEW #" ;
    /* your 1997 variable labels here */
    /* your 1997 missing data here */
    rename ER10002 ER33401 ;
    sort ER33401 ;
save "`FAM97'" ;

merge 1:m ER33401 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND97 , replace;

/* =================================================================== */
/*      step 2 for 1999 family file (n=6997)                           */
/* =================================================================== */
infix
    ER13002 2-6
    /* your 1999 variable locations here */
using "[PATH]\FAM1999ER.txt" , clear
;
    label variable ER13002 "1999 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 1999 variable labels here */
    /* your 1999 missing data here */
    rename ER13002 ER33501 ;
    sort ER33501 ;
save "`FAM99'" ;

merge 1:m ER33501 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND99 , replace;

/* =================================================================== */
/*      step 2 for 2001 family file (n=7406)                           */
/* =================================================================== */
infix
    ER17002 2-5
    /* your 2001 variable locations here */
using "[PATH]\FAM2001ER.txt" , clear
;
    label variable ER17002 "2001 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2001 variable labels here */
    /* your 2001 missing data here */
    rename ER17002 ER33601 ;
    sort ER33601 ;
save "`FAM01'" ;

merge 1:m ER33601 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND01 , replace;

/* =================================================================== */
/*      step 2 for 2003 family file (n=7822)                           */
/* =================================================================== */
infix
    ER21002 2-6
    /* your 2003 variable locations here */
using "[PATH]\FAM2003ER.txt" , clear
;
    label variable ER21002 "2003 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2003 variable labels here */
    /* your 2003 missing data here */
    rename ER21002 ER33701 ;
    sort ER33701 ;
save "`FAM03'" ;

merge 1:m ER33701 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND03 , replace;

/* =================================================================== */
/*      step 2 for 2005 family file (n=8002)                           */
/* =================================================================== */
infix
    ER25002 2-6
    /* your 2005 variable locations here */
using "[PATH]\FAM2005ER.txt" , clear
;
    label variable ER25002 "2005 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2005 variable labels here */
    /* your 2005 missing data here */
    rename ER25002 ER33801 ;
    sort ER33801 ;
save "`FAM05'" ;

merge 1:m ER33801 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND05 , replace;

/* =================================================================== */
/*      step 2 for 2007 family file (n=8289)                           */
/* =================================================================== */
infix
    ER36002 2-6
    /* your 2007 variable locations here */
using "[PATH]\FAM2007ER.txt" , clear
;
    label variable ER36002 "2007 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2007 variable labels here */
    /* your 2007 missing data here */
    rename ER36002 ER33901 ;
    sort ER33901 ;
save "`FAM07'" ;

merge 1:m ER33901 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND07 , replace;

/* =================================================================== */
/*      step 2 for 2009 family file (n=8690)                           */
/* =================================================================== */
infix
    ER42002 2-6
    /* your 2009 variable locations here */
using "[PATH]\FAM2009ER.txt" , clear
;
    label variable ER42002 "2009 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2009 variable labels here */
    /* your 2009 missing data here */
    rename ER42002 ER34001 ;
    sort ER34001 ;
save "`FAM09'" ;

merge 1:m ER34001 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND09 , replace;

/* =================================================================== */
/*      step 2 for 2011 family file (n=8907)                           */
/* =================================================================== */
infix
    ER47302 2-6
    /* your 2011 variable locations here */
using "[PATH]\FAM2011ER.txt" , clear
;
    label variable ER47302 "2011 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2011 variable labels here */
    /* your 2011 missing data here */
    rename ER47302 ER34101 ;
    sort ER34101 ;
save "`FAM11'" ;

merge 1:m ER34101 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND11 , replace;


/* =================================================================== */
/*      step 2 for 2013 family file (n=9063)                           */
/* =================================================================== */
infix
    ER53002 2-6
    /* your 2013 variable locations here */
using "[PATH]\FAM2013ER.txt" , clear
;
    label variable ER53002 "2013 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2013 variable labels here */
    /* your 2013 missing data here */
    rename ER53002 ER34201 ;
    sort ER34201 ;
save "`FAM13'" ;

merge 1:m ER34201 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND13 , replace;

/* =================================================================== */
/*      step 2 for 2015 family file (n=9048)                           */
/* =================================================================== */
infix
    ER60002 2-6
    /* your 2015 variable locations here */
using "[PATH]\FAM2015ER.txt" , clear
;
    label variable ER60002 "2015 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2015 variable labels here */
    /* your 2015 missing data here */
    rename ER60002 ER34301 ;
    sort ER34301 ;
save "`FAM15'" ;

merge 1:m ER34301 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND15 , replace;

/* =================================================================== */
/*      step 2 for 2017 family file (n=9607)                           */
/* =================================================================== */
infix
    ER66002 2-6
    /* your 2017 variable locations here */
using "[PATH]\FAM2017ER.txt" , clear
;
    label variable ER66002 "2017 FAMILY INTERVIEW (ID) NUMBER" ;
    /* your 2017 variable labels here */
    /* your 2017 missing data here */
    rename ER66002 ER34501 ;
    sort ER34501 ;
save "`FAM17'" ;

merge 1:m ER34501 using INDVARS , keep(using matched) ;
sort ER30001 ER30002 ;
drop _merge ;
save FAMIND17 , replace;


/* =================================================================== */
/*  step 3: merge familiy-individual files on individual identifiers   */
/* =================================================================== */
use FAMIND68 , clear ;
merge ER30001 ER30002
    using
        FAMIND69 FAMIND70 FAMIND71 FAMIND72 FAMIND73 FAMIND74 FAMIND75
        FAMIND76 FAMIND77 FAMIND78 FAMIND79 FAMIND80 FAMIND81 FAMIND82
        FAMIND83 FAMIND84 FAMIND85 FAMIND86 FAMIND87 FAMIND88 FAMIND89
        FAMIND90 FAMIND91 FAMIND92 FAMIND93 FAMIND94 FAMIND95 FAMIND96
        FAMIND97 FAMIND99 FAMIND01 FAMIND03 FAMIND05 FAMIND07 FAMIND09
        FAMIND11 FAMIND13 FAMIND15 FAMIND17
;
drop _merge* ;
save XYRFIND , replace;