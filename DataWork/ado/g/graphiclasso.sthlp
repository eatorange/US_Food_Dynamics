{smcl}
{* *! version 1.0.0  jun2020}{...}
{viewerjumpto "Title" "graphiclasso##title"}{...}
{viewerjumpto "Syntax" "graphiclasso##syntax"}{...}
{viewerjumpto "Description" "graphiclasso##description"}{...}
{viewerjumpto "Examples" "graphiclasso##examples"}{...}
{viewerjumpto "Stored results" "graphiclasso##results"}{...}
{viewerjumpto "Reference" "graphiclasso##reference"}{...}
{viewerjumpto "Author" "graphiclasso##author"}{...}
{viewerjumpto "Also see" "graphiclasso##alsosee"}{...}
{cmd:help graphiclasso}{right: ({browse "https://doi.org/10.1177/1536867X221124538":SJ22-3: st0685})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 21 23 2}{...}
{p2col:{cmd:graphiclasso} {hline 2}}Graphical lasso{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Sparse inverse-covariance matrix estimation through graphical lasso algorithm
using a list of variables as an input.

{p 8 20 2}
{cmd:graphiclasso} {varlist} {ifin}
[{cmd:,}
{it:{help graphiclasso##options_table:options}}]

{pstd}
Sparse covariance matrix estimation through graphical lasso algorithm using a
matrix as an input.

{p 8 18 2}
{cmd:graphiclasso} {it:matname}
[{cmd:,} {it:{help graphiclasso##options_table:options}}]

{phang}
{it:matname} is an n-by-b matrix with p >= 2.

{synoptset 15}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{synopt:{opt lam:bda(#)}}(nonnegative) penalty parameter; default is
{cmd:lambda(0.1)}{p_end}
{synopt:{opt max_iter(#)}}maximum number of iterations of outer loop; default
is {cmd:max_iter(100)}{p_end}
{synopt:{opt tol:erance(#)}}maximum tolerance for convergence; default is
{cmd:tolerance(1e-5)}{p_end}
{synopt:{opt diag}}whether diagonal should be penalized; default is false{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:graphiclasso} estimates a sparse inverse-covariance matrix using a lasso
(L1) penalty, using the framework developed in 
{help graphiclasso##FHT2007:Friedman, Hastie, and Tibshirani (2007)}.

{pstd}
{cmd:graphiclasso} allows data in the forms of both variable and matrix.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. set seed 2}{p_end}

{pstd}Set up by simulating data from {helpb datafromicov}{p_end}
{phang2}{cmd:. datafromicov, n(100) p(150)}{p_end}

{pstd}
Save data as matrix{p_end}
{phang2}{cmd:. matrix data = r(data)}{p_end}

{pstd}
Estimate inverse-covariance matrix using data input as variable names and
lambda = 0.2{p_end}
{phang2}{cmd:. graphiclasso var1-var50, lambda(0.2)}{p_end}

{pstd}
Estimate inverse-covariance matrix using data input as matrix and lambda =
0.2{p_end}
{phang2}{cmd:. graphiclasso data, lambda(0.2)}{p_end}
{phang2}{cmd:. ereturn list}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:graphiclasso} stores the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(lambda)}}tuning parameter{p_end}
{synopt:{cmd:e(Omega)}}inverse-covariance matrix{p_end}
{synopt:{cmd:e(Sigma)}}covariance matrix{p_end}
{p2colreset}{...}


{marker reference}{...}
{title:Reference}

{marker FHT2007}{...}
{phang}
Friedman, J., T. Hastie, and R. Tibshirani. 2008. Sparse inverse covariance
estimation with the graphical lasso. {it:Biostatistics} 9: 432–441. 
{browse "https://doi.org/10.1093/biostatistics/kxm045"}.


{marker author}{...}
{title:Author}

{pstd}
Aramayis Dallakyan{break}
StataCorp{break}
College Station, TX{break}
adallakyan@stata.com


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 22, number 3: {browse "https://doi.org/10.1177/1536867X221124538":st0685}{p_end}

{p 7 14 2}
Help:  {helpb compareicov},
{helpb graphiclassocv},
{helpb graphiclassoplot},
{helpb datafromicov} (if installed){p_end}
