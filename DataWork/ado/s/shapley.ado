*! Shapley decomposition, idea by Tony Shorrocks, shora@essex.ac.uk,
*! implementation by Stas Kolenikov, skolenik@recep.glasnet.ru
*! version 3.1 17Feb2000
* globals:
* $SHsave   -- turnover results   $SHfile -- 0/1 patterns       $SHdebug
* $SHfactor -- factor list        $SHres  -- result to save
* $SHreplc  -- `replace' option   $SHcall -- call to calculate
* $SHbase   -- initial data       $SHMD   -- decomposition matrix
* $SHstore  -- decomposition      $SHdiff -- total difference
* $SHgl     -- global used

program define shapley, rclass
   version 6.0
* now, we need to parse as follows:
* shapley <factor list>, options : program whatever @ whatever
   local call `0'

   gettoken part call: call, parse(" :") quotes
   while `"`part'"'~=`":"' & `"`part'"' ~= "" {
      local left `"`left' `part'"'
      gettoken part call: call, parse(" :") quotes
   }
   * now, `left' is the thing up to the colon, i.e. factors and options,
   * and `call' is the call to the program
   if "`call'"=="" {
      di in red "no program is called"
      exit 198
   }

   gettoken part left: left, parse(" ,") quotes
   while `"`part'"'~=`","' & `"`part'"' ~= "" {
      local factor `"`factor' `part'"'
      gettoken part left: left, parse(" ,") quotes
   }

   * now, `factor' is the factor list, and `left' are net options

   local was `0'
   * for a rainy day
   local 0 `part'`left'

   #delimit ;
   syntax , RESult(str) [ DEBUG SAVing(str) Dots REPLACE STOring(str)
       PERCent TRace FROMTO TItle(str) NOIsily]
       ;
   #delimit cr

   if "`debug'"~="" { global SHdebug 1 }
               else { global SHdebug 0 }

   tokenize `result'
   if "`1'"=="global" {
     global SHres `2'
     global SHgl "$"
   }
   else {
     global SHres `result'
     global SHgl
   }

   tempname dmatrix
   global SHMD `dmatrix'
   local m: word count $SHfactor
   matrix $SHMD=J(`m'+1,2,0)
   matrix rownames $SHMD=$SHfactor total
   matrix colnames $SHMD=OneStage Shapley
   if "`long'"~="" {
      tempname dmlong
      global SHMD `dmlong'
      matrix $SHMD=J(`m'+1,`m'+1,0)
   }

   global SHreplc `replace'
   global SHcall `call'
   global SHfactor `factor'
   global SHsave `saving'
   if `"`saving'"'=="" {
      tempfile shsave
      global SHsave `shsave'
   }
   global SHstore `storing'
   if `"`storing'"'=="" {
      tempfile shstore
      global SHstore `shstore'
   }

   if $SHdebug {
     di _n in gre "Factors list    : " in whi `"`factor'"'
     di    in gre "Shapley options : " in whi `"`0'"'
     di    in gre "Call to program : " in whi `"`call'"'
   }

   tempfile save base
   global SHfile `save'
   global SHbase `base'
   preserve
   cap save $SHbase, replace
   if $SHdebug { di in whi "r(" _rc ")" }

   di in green _n "    Shapley decomposition"
   if "`title'"~="" {
     di in gre "    of `title'"
   }
   di

   if $SHdebug {
      di in gre "The list of the SH macros:" _n "SHsave   = " in yel "$SHsave"
      dir $SHsave
      di in gre "SHstore  = " in yel "$SHstore"
      dir $SHstore
      di in gre "SHfile   = " in yel "$SHfile"
      di in gre "SHbase   = " in yel "$SHbase"
      dir $SHbase

* $SHsave   -- turnover results   $SHfile -- 0/1 patterns       $SHdebug
* $SHfactor -- factor list        $SHres  -- result to save
* $SHreplc  -- `replace' option   $SHcall -- call to calculate
* $SHbase   -- initial data       $SHMD   -- decomposition matrix
* $SHstore  -- decomposition      $SHdiff -- total difference
* $SHgl     -- global used

   }

   SHMat01
   * OK, now we have our 011011 patterns in $SHfile

   if $SHdebug {
     drop _all
     use $SHfile
     li
     restore, preserve
   }

   * Calculate the partial values
   SHFill, `dots' `trace' `noisily'

   if "`fromto'"~="" {
      qui use $SHsave
      di in gre "All factors present : $SHgl" "$SHres = " in yel __res[_N]
      di in gre "None factors present: $SHgl" "$SHres = " in yel __res[1]
   }

   * do the decomposition
   SHDeComp, `dots'

   * output the results
   SHDisp, `percent'
   return matrix decompos $SHMD
   return local factors $SHfactor
   return local $SHcall

   global SHfile
   global SHMD
   global SHbase
   global SHreplc
   global SHgl

end

program define SHDisp
* display the results of decomposition and collect the returned values
   version 6

   syntax, [PERCENT]
   tokenize $SHfactor

   if "`percent'"~="" {
      local pc1 "|  Per cent"
      local pc2 "|"
      local pc3 "+------------"
   }

   #delimit ;
   di in gre _n
" Factors | 1st round |  Shapley  `pc1'" _n
"         |  effects  |   value   `pc2'" _n
"---------+-----------+-----------`pc3'"
;
  #delimit cr

 qui {
  drop _all
  use $SHstore
  local m: word count $SHfactor
  local i=1
  local sum1=0
  local sum2=0
  while "``i''"~="" {
    sum ``i'' [fw=__weight]
    matrix $SHMD[`i',2]=r(mean)
    local sum2=`sum2'+$SHMD[`i',2]
    tempname n`i'
    g `n`i''=__diff if __factor=="``i''" & __stage==1
    sum `n`i''
    matrix $SHMD[`i',1]=r(mean)
    local sum1=`sum1'+$SHMD[`i',1]
    #delimit ;
    noi di in gre "``i''" _col(10) "| " in yel %8.5g $SHMD[`i',1]
       _col(22) in gre "| " in yel %8.5g $SHMD[`i',2] _col(34) _c
    ;
    #delimit cr
    if "`percent'"~="" {
       noi di in gre "| " in yel %6.2f $SHMD[`i',2]*100/$SHdiff in gre " %"
    }
    else {
       noi di in whi
    }
    local i=`i'+1
  } /* end of while across factors */
  } /* end of quietly */
  matrix $SHMD[`m'+1,2]=$SHdiff /* total */
  matrix $SHMD[`m'+1,1]=`sum1' /* total at the first stage */
  #delimit ;
  di in gre
"---------+-----------+-----------`pc3'" _n
"Resdiual | " in yel %8.5g $SHMD[`m'+1,2]-$SHMD[`m'+1,1] _col(22) in gre "|" _n
"---------+-----------+-----------`pc3'" _n
"   Total | " in yel %8.5g $SHMD[`m'+1,2] _col(22) in gre "| "
             in yel %8.5g $SHMD[`m'+1,2] _col(34) _c
  ;
  #delimit cr
  if "`percent'"~="" {
     di in gre "| 100.00 %"
  }
  else { di }
end

program define SHDeComp
* purpose: does all decomposition
  version 6
  syntax , [DOTS]

  if "`dots'"~="" {
     di in gre "Calculating the differences due to factor elimination..."
  }
  qui {
   preserve
   postfile SHdec __factor __from __to __stage __diff __weight using $SHstore, $SHreplc
   drop _all
   use $SHsave
   gsort -__ID
   global SHdiff=__result[1]-__result[_N]
   tokenize $SHfactor
   local m : word count $SHfactor

   tempname d0
   scalar `d0'=1
   local i=1
   while `i'<=`m' {
      tempname d`i' diff`i'
      local i1=`i'-1
      scalar `d`i''=`d`i1''*2
      if $SHdebug { di in whi `d`i1'' "*2=" `d`i'' }
      local i=`i'+1
   }
   * to have degrees of 2. We did that in SHMat01, btw.
   local stage=0
   while `stage'<=`m' { /* step across stages starting at zero */
*      local wei`stage'=exp(lnfact(`m')-lnfact(`m'-`stage'-1)-lnfact(`stage'))/`m'
      local wei`stage'=exp(lnfact(`m'-`stage'-1)+lnfact(`stage'))
            * some weights attached to stages differences;
            * should be (`m'-1)!/(`m'-`stage'-1)! `stage'!
            * to represent the number of trajectories passing by
      if $SHdebug { noi di in gre "Stage " in yel `stage' in gre ": 1/weight = " in yel `wei`stage'' }
      local stage=`stage'+1
   }

   * now, explicit subscripting...
   tempname ID plus
   scalar `ID'=1
   while `ID'<=_N {
      * now, we need to find out where 1s are...
      local k=1
      while `k'<=`m' {
        if ``k''[`ID'] {
           * ... and to find the differences with this factor eliminated
           scalar `plus'=`d`m''/`d`k''
           scalar `diff`k''=__result[`ID']-__result[`ID'+`plus']
           local stage=`m'-__round[`ID']
           if $SHdebug {
             noi di in blu " Now posting : " in whi `"post SHdec (`k') (`ID') (`ID'+`plus') (__round[`ID']) (`diff`k'') (`wei`stage'')"'
           }
           # delimit ;
           post SHdec (`k') (`ID') (`ID'+`plus') (__round[`ID'])
               (`diff`k'') (`wei`stage'')
           ;
           #delimit cr
*           if "`dots'"~="" { noi di in whi "." _c }
        } /* yeah, that was 1 */
        local k=`k'+1
      }
      scalar `ID'=`ID'+1
   }
   postclose SHdec
   if "`dots'"~="" { noi di in whi }
   drop _all
   use $SHstore
   lab data "Shapley: marginal differences"
   ren __factor __fno
   lab var __fno "No. of the factor"
   g str8 __factor=" "
   local k=1
   while "``k''"~="" {
      replace __factor="``k''" if __fno==`k'
      g double ``k''=__diff if __fno==`k'
      lab var ``k'' "Contribution of ``k''"
      local k=`k'+1
   }
   lab var __from  "ID from"
   lab var __to    "ID to"
   lab var __stage "Stage of exclusion"
   lab var __diff  "Marginal contribution of the factor"
   lab var __weigh "Weights / no. trajectorius through"
   save $SHstore, replace
  }
  if $SHdebug { di in whi "SHDeComp successful!" }
end

program define SHFill
   version 6
   syntax , [DOTS TRACE NOISILY]
   local m: word count $SHfactor

   if "`dots'"~="" {
     di in gre _n "Filling in the values with different factor composition. Enjoy the dots!"
     tempname m2m
     scalar `m2m'=2^`m'
   }

   qui {
     preserve

     tokenize $SHfactor

     * parse the call
     gettoken part right: (global)SHcall, parse(" @") quotes
     while `"`part'"'~=`"@"' & `"`part'"' ~= "" {
        local left `"`left' `part'"'
        gettoken part right: right, parse(" @") quotes
     }
     if `"`part'"'~=`"@"' {
       di in red "No chance to cycle across factors; put @ in the call"
       exit 198
     }
     * now, `left' is the thing up to the @, and `right', after @

     tempname ID round
     local i=1
     while `i'>0 { /* cycle over the observations in $SHfile, i.e. 010110 */
        drop _all
        scalar `ID'=0
        scalar `round'=0
        cap use in `i' using $SHfile
        if _rc==0 { /* there are still observations in the $SHfile */
          local k=1
          local clist
          while `k'<=`m' {
            scalar `ID'=2*`ID'+``k''
            scalar `round'=`round'+``k''
            if ``k'' {
              local clist `clist' ``k''
            }
            local k=`k'+1
          } /* cycle over factors; `clist' is current list with factor==1 */
          drop _all
          use $SHbase
          local callit `left' `clist' `right'
          if $SHdebug { noi di in blue "The call is: " in whi "`callit'" }
          capture `noisily' `callit'
          local rc=_rc
          if `rc'~=0  {
             noi di in red "Error in the called program! " _c "
             if "`trace'"=="" {
               noi di in red
               exit `rc'
             }
             else {
               noi di in red "Look what it did:" _n(2) in whi ">> `left' `clist' `right'" _n
               noi `callit'
             }
          }
          tempname res
          scalar `res'=$SHgl$SHres
          drop _all
          use in `i' using $SHfile
          compress
          g double __result = `res'
          lab var __result "$SHgl $SHres from $SHcall"
          g long __ID=`ID'
          lab var __ID "Binary representation"
          g byte __round=`round'
          lab var __round "Number of 1s"
          if `i'==1 { save $SHsave, $SHreplc }
          else {
              append using $SHsave
              save $SHsave, replace
          }
          if "`dots'"~="" {
            noi di in whi "." _c
            if $SHdebug { noi di in red %4.1f `i'/`m2m'*100 "% " _c }
            if `i'/`m2m'>=0.1 & (`i'-1)/`m2m'<0.1 { noi di in whi "10% done! " _c }
            if `i'/`m2m'>=0.2 & (`i'-1)/`m2m'<0.2 { noi di in whi "20% done! " _c }
            if `i'/`m2m'>=0.3 & (`i'-1)/`m2m'<0.3 { noi di in whi "30% done! " _c }
            if `i'/`m2m'>=0.4 & (`i'-1)/`m2m'<0.4 { noi di in whi "40% done! " _c }
            if `i'/`m2m'>=0.5 & (`i'-1)/`m2m'<0.5 { noi di in whi "50% done! " _c }
            if `i'/`m2m'>=0.6 & (`i'-1)/`m2m'<0.6 { noi di in whi "60% done! " _c }
            if `i'/`m2m'>=0.7 & (`i'-1)/`m2m'<0.7 { noi di in whi "70% done! " _c }
            if `i'/`m2m'>=0.8 & (`i'-1)/`m2m'<0.8 { noi di in whi "80% done! " _c }
            if `i'/`m2m'>=0.9 & (`i'-1)/`m2m'<0.9 { noi di in whi "90% done! " _c }
          }
          local i=`i'+1
        } /* file was succesfully opened */
        else { local i=-1 } /* no more observations */
     } /* cycle over the observations in $SHfile, i.e. 010110 */
     use $SHsave
     label data "Shapley: results of factor substitution in various ways"
     compress
     local k=1
     while "``k''"~="" {
        lab var ``k'' "Shapley factor"
        local k=`k'+1
     }
     save $SHsave, replace
   } /* end of quietly; that's it, we have the results in $SHsave file */
   if "`dots'"~="" { di }
   if $SHdebug { di in whi "SHFill successful!" }
end

program define SHMat01
   version 6
* arguments: the list of factors in $SHfactor
* $SHfile -- the name of the file to post to

   tokenize $SHfactor

   local m: word count $SHfactor
   if `m'<=0 { di in red "Wrong number of arguments in Mat01a"
     exit 198
   }
   if `m'>56 { di in red "Too many factors: no more than 56"
     error 198
   }

   * scalars d* are degrees of 2
   tempname d0
   scalar `d0'=1
   local i=1
   while `i'<=`m' {
      tempname d`i'
      local i1=`i'-1
      scalar `d`i''=`d`i1''*2
      if $SHdebug { di in whi `d`i1'' "*2=" `d`i'' }
      local i=`i'+1
   }
   if $SHdebug {
     di in gre "2^" in yel `m' in gre "=" in yel `d`m''
     postfile SHfile $SHfactor using $SHfile
   }
   else {
     qui postfile SHfile $SHfactor using $SHfile
   }

   tempname k trk
   scalar `k'=`d`m''-1
   while `k'>=0 { /* workout the m2m-`k'-th row of the matrix */
      local i=`m'-1
      scalar `trk'=`k'
      * truncated `k'
      local zerone
      while `i'>=0 { /* find what the `i'-th bit of `k' is */
        local zo=(`trk'-`d`i''>-0.5)
        local zerone `zerone' `zo'
        if `zo' { scalar `trk'=`trk'-`d`i'' }
        local i=`i'-1
      }
      if $SHdebug {
         di in gre `k' ". `zerone'"
      }
      post SHfile `zerone'
      local k=`k'-1
   }
   postclose SHfile
   if $SHdebug { di in whi "SHMat01 successful!" }
end

exit

***************************************************************************

History of the file

Version 2.1
- program is made of estimate class
- global macronames for matrices
- some local macros changed to scalars

Version 2.2
- generalized to any type of program to deliver the result to be decomposed

Version 2.3
- `equalize' option added to `sumup' part
- "shapley" with no arguments repeats the last estimates

Version 2.4
- weights are added

Version 2.5
- replay() is introduced

Version 2.6
- `bstrap' and `reps' are added
- `callopt' introduced instead of "the rest of options"

Version 3.0 17-Feb-2000
- OK, let's redo everything: A NEW SYNTAX
- bs discarded
- redo the algorithm into `post' terms -- Mat01a
- redo the parsing to another syntax -- gettoken things in the beginning
- redo the display -- simplified to the 1st stage, Shapley contributions,
  and percentages (optional)

Version 3.1 20-Mar-2000
- global macro manipulation in -result- option is added
- -fromto- option added
- -title- and -noisily- options added (25 March)

  Files created:
  `saving'  $SHsave:
  factors  : present 1/not present 0
  __ID     : binary representation of 0/1 pattern
  __result : the corresponding result
  __round  : number of 1s in the pattern; round of exclusion = #factors - it

  `storing' $SHstore:
  __factor : the name of the factor
  __fno    : the number of the factors in the list
  __from   : the pattern of the parent node
  __to     : the pattern of the daughter node
  __stage  : the stage of exclusion; 0 is nothing excluded; #factors is all
             excluded
  __weight : the number of trajectories passing through
  __diff   : the marginal difference
