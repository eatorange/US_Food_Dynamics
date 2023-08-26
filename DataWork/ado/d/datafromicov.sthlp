{smcl}
{* *! version 1.0.0  jun2020}{...}
{viewerjumpto "Title" "datafromicov##title"}{...}
{viewerjumpto "Syntax" "datafromicov##syntax"}{...}
{viewerjumpto "Description" "datafromicov##description"}{...}
{viewerjumpto "Example" "datafromicov##example"}{...}
{viewerjumpto "Stored results" "datafromicov##results"}{...}
{viewerjumpto "Author" "datafromicov##author"}{...}
{viewerjumpto "Also see" "datafromicov##alsosee"}{...}
{cmd:help datafromicov}{right: ({browse "https://doi.org/10.1177/1536867X221124538":SJ22-3: st0685})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 21 23 2}{...}
{p2col:{cmd:datafromicov} {hline 2}}Generate data from the inverse-covariance matrix given the sparsity level{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Implements the data generation from a multivariate normal distribution with
a random graph structure.

{p 8 20 2}
{cmd:datafromicov}{cmd:,} 
{opt n(#)} {opt p(#)}
[{it:{help datafromicov##options_table:options}}]

{synoptset 10 tabbed}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt n(#)}}number of observations of sample size{p_end}
{p2coldent:* {opt p(#)}}number of variables (dimension) of sample size{p_end}
{synopt:{opt prob(#)}}probability that any off-diagonal element of
inverse-covariance matrix is nonzero; default is {cmd:prob(3/}{it:p}{cmd:)}{p_end}
{synopt:{opt v(#)}}off-diagonal elements of the precision matrix, controlling
the magnitude of partial correlations with {cmd:u()}; default is {cmd:v(0.3)}{p_end}
{synopt:{opt u(#)}}positive number being added to the diagonal elements of the
precision matrix to control the magnitude of partial correlations; default is
{cmd:u(0.1)}{p_end}
{synoptline}
{pstd}
* {cmd:n()} and {cmd:p()} are required.


{marker description}{...}
{title:Description}

{pstd}
Given the adjacency matrix theta, the graph patterns are generated as follows:
Each pair of off-diagonal elements are randomly set theta[i,j]= theta[j,i]=1
for i!=j with probability {cmd:prob()} and 0 otherwise.  It results in about
p*(p-1)*{cmd:prob()}/2 edges in the graph.  The adjacency matrix theta has all
diagonal elements equal to 0.  To obtain a positive-definite precision matrix,
we compute the smallest eigenvalue of theta*v.  Then, we set the precision
matrix equal to theta*v+(theta*v++0.1+u)I.  We then compute the covariance
matrix to generate multivariate normal data.


{marker example}{...}
{title:Example}

{pstd}
Simulate data with {cmd:n(100)} and {cmd:p(150)}{p_end}
{phang2}{cmd:. datafromicov, n(100) p(150)}{p_end}

{pstd}
Extract the data and true precision matrix{p_end}
{phang2}{cmd:. matrix data = r(data)}{p_end}
{phang2}{cmd:. matrix omega_true= r(Omega)}{p_end}

{pstd}
Plot true inverse-covariance matrix using {helpb graphiclassoplot}{p_end}
{phang2}{cmd:. graphiclassoplot omega_true, type(graph) lab layout(circle) title(True precision matrix, color(white) position(12)) saving("trueomega", replace)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:datafromicov} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Scalar}{p_end}
{synopt:{cmd:r(sparsity)}}sparsity level in the inverse-covariance matrix{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(data)}}generated data matrix{p_end}
{synopt:{cmd:r(Omega)}}inverse-covariance matrix for the generated data{p_end}
{synopt:{cmd:r(Sigma)}}covariance matrix for the generated data{p_end}
{synopt:{cmd:r(S)}}empirical covariance matrix for the generated data{p_end}
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
Help:  {helpb compareicov},
{helpb graphiclassocv},
{helpb graphiclasso},
{helpb graphiclassoplot} (if installed){p_end}
