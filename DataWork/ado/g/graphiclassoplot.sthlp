{smcl}
{* *! version 1.0.0  jun2020}{...}
{viewerjumpto "Title" "graphiclassoplot##title"}{...}
{viewerjumpto "Syntax" "graphiclassoplot##syntax"}{...}
{viewerjumpto "Description" "graphiclassoplot##description"}{...}
{viewerjumpto "Examples" "graphiclassoplot##examples"}{...}
{viewerjumpto "Reference" "graphiclassoplot##reference"}{...}
{viewerjumpto "Author" "graphiclassoplot##author"}{...}
{viewerjumpto "Also see" "graphiclassoplot##alsosee"}{...}
{cmd:help graphiclassoplot}{right: ({browse "https://doi.org/10.1177/1536867X221124538":SJ22-3: st0685})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 25 27 2}{...}
{p2col:{cmd:graphiclassoplot} {hline 2}}Visualize the estimated inverse-covariance matrix{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Visualizes the inverse-covariance matrix as an undirected graph or matrix.

{p 8 20 2}
{cmd:graphiclassoplot} {it:matname} 
[{cmd:,} 
{it:{help PLOTP##options:options}}]

{phang}
{it:matname} specifies the estimated inverse-covariance matrix, which is a
p-by-p matrix with p >= 2.

{synoptset 25}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{synopt:{opt type(string)}}type of the graph: {cmd:graph} or {cmd:matrix};
default is {cmd:type(graph)}{p_end}
{synopt:{opt newlabs(lab1 lab2 ...)}}labels for the plot{p_end}
{synopt:{help nwplot:{it:nwplot_options}}}options for undirected graph plot; for details, see Grund and Hedstr{c o:}m (Forthcoming){p_end}
{synopt:{help nwplotmatrix:{it:nwplotmatrix_options}}}options for matrix plot; for details, see Grund and Hedstr{c o:}m (Forthcoming){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:graphiclassoplot} visualizes the inverse-covariance matrix as an
undirected graph or matrix.  The command heavily relies on {helpb nwcommands}
(Grund and Hedstr{c o:}m Forthcoming).


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. set seed 2}{p_end}

{pstd}
Set up by simulating data from {helpb datafromicov}{p_end}
{phang2}{cmd:. datafromicov, n(100) p(150)}{p_end}

{pstd} Extract data and true precision matrix{p_end}
{phang2}{cmd:. matrix data = r(data)}{p_end}
{phang2}{cmd:. matrix omega_true = r(Omega)}{p_end}

{pstd}
Estimate inverse-covariance matrix using data input as variable names and 
lambda = 0.2, and extract estimated precision matrix{p_end}
{phang2}{cmd:. graphiclasso data, lambda(0.2)}{p_end}
{phang2}{cmd:. matrix omega_est = r(Omega)}{p_end}

{pstd}
Visualize the result{p_end}
{phang2}{cmd:. graphiclassoplot omega_est, type(matrix)}{p_end}
{phang2}{cmd:. graphiclassoplot omega_est, type(graph) lab layout(circle)}{p_end}


{marker reference}{...}
{title:Reference}

{phang}
Grund, T., and P. Hedstr{c o:}m. Forthcoming. 
{it:An Introduction to Social Network Analysis and Agent-Based Modeling Using Stata}.
College Station, TX: Stata Press.


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
{helpb datafromicov} (if installed){p_end}
