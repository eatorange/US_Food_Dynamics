{smcl}
{* *! version 1.0.0  jun2020}{...}
{viewerjumpto "Title" "graphiclassocv##title"}{...}
{viewerjumpto "Syntax" "graphiclassocv##syntax"}{...}
{viewerjumpto "Description" "graphiclassocv##description"}{...}
{viewerjumpto "Examples" "graphiclassocv##examples"}{...}
{viewerjumpto "Stored results" "graphiclassocv##results"}{...}
{viewerjumpto "References" "graphiclassocv##references"}{...}
{viewerjumpto "Author" "graphiclassocv##author"}{...}
{viewerjumpto "Also see" "graphiclassocv##alsosee"}{...}
{cmd:help graphiclassocv}{right: ({browse "https://doi.org/10.1177/1536867X221124538":SJ22-3: st0685})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 23 25 2}{...}
{p2col:{cmd:graphiclassocv} {hline 2}}Select the tuning parameter lambda for
{help graphiclasso}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Sparse inverse-covariance matrix estimation through cross-validation using a
list of variables as an input.

{p 8 22 2}
{cmd:graphiclassocv} {varlist} {ifin}
[{cmd:,}
{it:{help graphiclassocv##options_table:options}}]

{pstd}
Sparse covariance matrix estimation through cross-validation using a Stata
matrix as an input.

{p 8 16 2}
{cmd:graphiclassocv} {it:matname}
[{cmd:,}
{it:{help graphiclassocv##options_table:options}}]

{phang}
{it:matname} is an n-by-b Stata matrix with p >= 2.

{synoptset 15}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{synopt:{opt lamlist(#)}}grid of positive tuning parameters for penalty
term; if provided, causes {cmd:graphiclassocv} to disregard {cmd:nlam()}{p_end}
{synopt:{opt nlam(#)}}number of generated tuning parameters for penalty term; 
default is {cmd:nlam(20)}{p_end}
{synopt:{opt max_iter(#)}}maximum number of iterations of outer loop; default
is {cmd:max_iter(1000)}{p_end}
{synopt:{opt tol:erance(#)}}maximum tolerance for convergence; default is
{cmd:tolerance(1e-5)}{p_end}
{synopt:{opt nfold(#)}}number of folds for K-fold cross-validation{p_end}
{synopt:{opt crit(string)}}cross-validation criterion ({cmd:loglik},
{cmd:eBIC}, or {cmd:AIC}); default is {cmd:crit(loglik)}{p_end}
{synopt:{opt start(string)}}type of initial values; default is
{cmd:start(cold)}; {cmd:start(warm)} uses the solution of the previous tuning parameter as an initial value{p_end}
{synopt: {opt gamma(#)}}parameter for extended Bayesian information criterion
(eBIC) criterion; {cmd:gamma(0)} corresponds to BIC 
({help graphiclassocv##FD2010:Foygen and Drton 2010}); default is {cmd:gamma(0.5)};
activated if {cmd:crit()} is {cmd:eBIC}{p_end}
{synopt:{opt diag}}whether diagonal should be penalized; default is false{p_end}
{synopt:{opt verbose}}show the table of selected information criterion{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:graphiclassocv} implements K-fold cross-validation 
({help graphiclassocv##HTF2009:Hastie, Tibshirani, and Friedman 2009}).


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. set seed 2}{p_end}

{pstd}Simulate data with n = 100 and p = 150{p_end}
{phang2}{cmd:. datafromicov, n(100) p(150)}{p_end}

{pstd}
Extract the data{p_end}
{phang2}{cmd:. matrix data = r(data)}{p_end}

{pstd}
Estimate sparse inverse-covariance matrix based on cross-validation{p_end}
{phang2}{cmd:. graphiclassocv data, nfold(5) nlam(40) crit(loglik)}{p_end}

{pstd}
Save the estimated matrix{p_end}
{phang2}{cmd:. matrix omega_cv = r(Omega)}{p_end}

{pstd}
Save the tuned regularization parameter{p_end}
{phang2}{cmd:. scalar lambda = r(lambda)}{p_end}

{pstd}
Estimate sparse inverse-covariance matrix based on eBIC using matrix as an
input{p_end}
{phang2}{cmd:. graphiclassocv data, nfold(5) nlam(40) crit(eBIC) gamma(0.2)}{p_end}

{pstd}
Save the estimated matrix{p_end}
{phang2}{cmd:. matrix omega_ebic = r(Omega)}{p_end}

{pstd}
Save the tuned regularization parameter{p_end}
{phang2}{cmd:. scalar lambda_ebic = r(lambda)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:graphiclassocv} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalar}{p_end}
{synopt:{cmd:e(lambda)}}selected regularization parameter{p_end}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(Omega)}}sparse inverse-covariance matrix{p_end}
{synopt:{cmd:e(Sigma)}}covariance matrix{p_end}
{synopt:{cmd:e(lamlist)}}list of regularization parameters{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{marker FD2010}{...}
{phang}
Foygel, R., and M. Drton. 2010. Extended Bayesian information criteria for
Gaussian graphical models. In 
{it:Proceedings of the 23rd International Conference on Neural Information Processing Systems -- Volume 1}, ed. J. D. Lafferty, C. K. I. Williams,
J. Shawe-Taylor, R. S. Zemel, and A. Culotta, 604–612. Red Hook, NY : Curran
Associates, Inc.

{marker HTF}{...}
{phang}
Hastie, T., R. Tibshirani, and J. Friedman. 2009. 
{it:The Elements of Statistical Learning: Data Mining, Inference, and Prediction}. 2nd ed. New York: Springer.


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
{helpb graphiclasso},
{helpb graphiclassoplot},
{helpb datafromicov} (if installed){p_end}
