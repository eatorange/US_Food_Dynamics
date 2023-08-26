{smcl}
{* *! version 1.0.0  jun2020}{...}
{viewerjumpto "Title" "compareicov##title"}{...}
{viewerjumpto "Syntax" "compareicov##syntax"}{...}
{viewerjumpto "Description" "compareicov##description"}{...}
{viewerjumpto "Example" "compareicov##example"}{...}
{viewerjumpto "Stored results" "compareicov##results"}{...}
{viewerjumpto "Author" "compareicov##author"}{...}
{viewerjumpto "Also see" "compareicov##alsosee"}{...}
{cmd:help compareicov}{right: ({browse "https://doi.org/10.1177/1536867X221124538":SJ22-3: st0685})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:compareicov} {hline 2}}Compare the estimated and true inverse-covariance matrices{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Compares the estimated and true inverse-covariance matrix based on true
positive, false positive, and true discovery rates.

{p 8 19 2}
{cmd:compareicov} {it:matname1}{cmd:,} {opt true(matname2)}

{phang}
{it:matname1} specifies the estimated matrix, which is a p-by-p
matrix with p >= 2.

{phang}
{opt true(matname2)} specifies the true matrix, which is a p-by-p matrix with
p >= 2.  {cmd:true()} is required.


{marker description}{...}
{title:Description}

{pstd}
{cmd:compareicov} compares two matrices; one is estimated, and the other is
the true matrix and estimates true positive, false positive, and true
discovery rates.


{marker example}{...}
{title:Example}

{phang2}{cmd:. set seed 2}{p_end}

{pstd}Set up by simulating data from {helpb datafromicov}{p_end}
{phang2}{cmd:. datafromicov, n(100) p(150)}{p_end}

{pstd}
Extract data and true precision matrix{p_end}
{phang2}{cmd:. matrix data = r(data)}{p_end}
{phang2}{cmd:. matrix omega_true = r(Omega)}{p_end}

{pstd}
Estimate inverse-covariance matrix using data input as variable names with
lambda = 0.2{p_end}
{phang2}{cmd:. graphiclasso data, lambda(0.2)}{p_end}
{phang2}{cmd:. matrix omega_est = e(Omega)}{p_end}

{pstd}
Compare the results{p_end}
{phang2}{cmd:. compareicov omega_est, true(omega_true)}{p_end}
{phang2}{cmd:. return list}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:compareicov} stores the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(tpr)}}true positive rate{p_end}
{synopt:{cmd:r(fpr)}}false positive rate{p_end}
{synopt:{cmd:r(tdr)}}true discovery rate{p_end}
{p2colreset}{...}


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
Help:  {helpb graphiclassocv},
{helpb graphiclasso},
{helpb graphiclassoplot},
{helpb datafromicov} (if installed){p_end}
