*! version 1.0.0  08apr2022
version 16
set matastrict on

mata:

struct GLassoCV_result
{
	real matrix Omega
	real matrix Omega_inv
	real scalar lambda
}

class CV_GLasso
{
	public:
		void		       	setup()
		void 		       	setup1()
		void	       	 	CVglasso()
		void		       	CVglasso_fit()
		void 			plotcv()
		real scalar            	N
		real scalar            	p
		real scalar             gam
	// Private Funcitons

	// Input and estimated variables
	public:
		real matrix   	       	X 
		string scalar 		selection
		real matrix            	Omega
		real matrix 	       	Omega_inv
		real rowvector          m_fit
		real scalar	        lambda
		real scalar            	nfold
		real colvector	       	lamlist
		string scalar 		start
		pointer(real vector) scalar 		result
	private:
		class GLasso scalar    	gl
		real scalar            	nonzero()
		real matrix            	S_train
		real matrix 		scale()
}
	
/// Setup when input is Stata matrix type
void CV_GLasso::setup1(real matrix user_X, string colvector lbd_list, ///
			real scalar nlam, real scalar K,  ///
			real scalar max_iter, real scalar tolerance, ///
			real scalar gama, string scalar crit,  ///
			string scalar cvmethod, string scalar start, ///
			string scalar diag, string scalar nolog) // string scalar nostandardize, 
{
	real matrix S, diag_S, st_X 
	real scalar lammin, lammax
	real colvector sqrt_diag_S
//	if (nostandardize == "")
//	{
//		X      = gl.standardizeX(user_X)
//	}else{
	X = user_X
//	}
	if (crit == "")
	{
		crit = "loglik"
	}
	if (crit != "loglik" & crit != "eBIC" & crit != "AIC")
	{
		errprintf("Available criteria are CV, AIC and eBIC \n")
		exit(498)	
	}
	if (crit == "loglik"){
		selection = "Selection: Cross Validation" 
	}
	else if (crit == "eBIC"){
		selection = "Selection: eBIC"
	}
	else {
		selection = "Selection: AIC"
	}
	if (cvmethod == "")
	{
		cvmethod = "shuffle"
	}
	if (cvmethod != "mod" & cvmethod != "shuffle")
	{
		errprintf("Available cv methods are mod and shuffle \n")
		exit(498)
	}
	if (gama < 0 | gama > 1 )
	{
		errprintf("Gamma should be between 0 and 1 \n")
		exit(498)
	}
	if( K < 1)
	{
		errprintf("K should be positive. \n")
		exit(498)
	}
	if (start == "")
	{
		start = "cold"
	}
	if (start != "cold" & start != "warm")
	{
		errprintf("Available start methods are cold and warm \n")
		exit(498)
	}
	if (lbd_list == "")
	{
		if (nlam < 0)
		{
			errprintf("nlam should be positive. \n")
			exit(498)
		}
		S = quadcrossdev(X, 0, mean(X), X, 0, mean(X)) :/ rows(X)
		st_X = X :- mean(X)
		sqrt_diag_S = sqrt(diagonal(S))
		diag_S = diag(1 :/ sqrt_diag_S)
		st_X = quadcross(st_X', diag_S)
		S = quadcross(st_X, st_X) :/ rows(X)
		lammax = max(abs(S - diag(diagonal(S))))
		lammin = max((0.01, 0.01 * lammax))
		lamlist = 10:^rangen(log10(lammax), log10(lammin), nlam)
	}else{
		lamlist = st_matrix(lbd_list)
		if (length(select(lamlist, lamlist :< 0)))
		{
			errprintf("lamlist should contain only positive values. \n")
			exit(498)
		}
		lamlist = sort(lamlist,-1)
	}
	nfold     = K
	gam = gama
	CVglasso(max_iter, tolerance, crit, cvmethod, diag, nolog) //string scalar nostandardize, 
	st_eclear()
	st_matrix("e(Omega)", Omega)
	st_matrix("e(Sigma)", Omega_inv)
	st_numscalar("e(lambda)", lambda)
	st_matrix("e(lamlist)", lamlist)
//	st_matrix("CVvalues", (sort(lamlist,-1),sort(m_fit',-1)))
}

/// Setup when input is Stata variables type
void CV_GLasso::setup(string scalar varlist, string scalar touse, /// 
			string colvector lbd_list, real scalar nlam, ///
			real scalar K, real scalar max_iter, ///
			real scalar tolerance, real scalar gama, ///
			string scalar crit, string scalar cvmethod, ///
			string scalar start, ///
			string scalar diag, string scalar nolog) //string scalar nostandardize,
{
	real matrix user_X, S, st_X, diag_S
	string matrix rownm
	real scalar lammin, lammax
	real colvector sqrt_diag_S
	string colvector cv
//	pragma unset X
	st_view(X, ., tokens(varlist), touse)
	cv = tokens(varlist)
//		if (nostandardize == "")
//	{
//	X      = gl.standardizeX(X)
//	}
	if (length(uniqrows(cv)) != length(cv)) 
	{
		errprintf(" repeated variables not allowed \n")
		exit(498)
	}
	if (crit == "")
	{
		crit = "loglik"
	}
	if (crit != "loglik" & crit != "eBIC" & crit != "AIC")
	{
		errprintf("Available criteria are CV, AIC and eBIC \n")
		exit(498)	
	}
	if (crit == "loglik"){
		selection = "Selection: Cross Validation" 
	}
	else if (crit == "eBIC"){
		selection = "Selection: eBIC"
	}
	else {
		selection = "Selection: AIC"
	}
	if (cvmethod == "")
	{
		cvmethod = "shuffle"
	}
	if (cvmethod != "mod" & cvmethod != "shuffle")
	{
		errprintf("Available cv methods are mod and shuffle \n")
		exit(498)
	}
	if (start == "")
	{
		start = "cold"
	}
	if (start != "cold" & start != "warm")
	{
		errprintf("Available start methods are cold and warm \n")
		exit(498)
	}
	if (lbd_list == "")
	{
		S = quadcrossdev(X, 0, mean(X), X, 0, mean(X)) :/ (rows(X) - 1)
		st_X = X :- mean(X)
		sqrt_diag_S = sqrt(diagonal(S))
		diag_S = diag(1 :/ sqrt_diag_S)
		st_X = quadcross(st_X', diag_S)
		S = quadcross(st_X, st_X) :/ (rows(X) - 1)
		lammax = max(abs(S - diag(diagonal(S))))
		lammin = max((0.01, 0.01 * log10(lammax)))
		lamlist = 10:^rangen(log10(lammin), log10(lammax), nlam)
	}else{
		lamlist = st_matrix(lbd_list)
		if (length(select(lamlist, lamlist :< 0)))
		{
			errprintf("lamlist should contain only positive values. \n")
			exit(498)
		}
		//lamlist = sort(lamlist,-1)
	}
	nfold     = K
	gam = gama
	CVglasso(max_iter, tolerance, crit, cvmethod, diag, nolog) //nostandardize,
	st_eclear()
	st_matrix("e(Omega)", Omega)
	st_matrix("e(Sigma)", Omega_inv)
	st_numscalar("e(lambda)", lambda)
	st_matrix("e(lamlist)", lamlist)
//	st_matrix("CVvalues", (sort(lamlist,-1),sort(m_fit',-1)))
}

void CV_GLasso::CVglasso(real scalar max_iter, real scalar tolerance, ///
		string scalar crit, string scalar cvmethod, ///
		string scalar diag, string scalar nolog) //, string scalar nostandardize
{
	real scalar nlam, fold, j, se_fit, i_best_fit, ise_fit, nz
	real colvector fold_ids, cvm, cvse, index_te, index_tr, xbar
	real rowvector ind_te, ind_tr
	real matrix cv_folds, errs_fit, xtrain, xtest, S_test, tmp
	N = rows(X)
	p = cols(X)
	nlam = length(lamlist)
	if (cvmethod == "mod")
	{
		fold_ids = mod(mm_srswor(N, N), nfold) :+ 1 
	}else{
		fold_ids = mm_srswor(N,N)
	}
	cvm = J(nlam, 1, .)
	cvse = J(nlam, 1, .)
	cv_folds = J(nfold, nlam, 0)
	errs_fit = J(nlam, nfold, 0)

	for (fold = 1; fold <= nfold; fold++)
	{
	    if (cvmethod == "mod")
		{
			index_tr = selectindex(fold_ids :!= fold)
			index_te = selectindex(fold_ids :== fold)
		}else{
			ind_te = ((1 + floor((fold - 1) * N / nfold) ) .. floor(fold * N / nfold))
			index_te = fold_ids[ind_te]
			ind_tr = J(1, N, 1)
			ind_tr[ind_te] = J(1,length(ind_te), 0)
			index_tr = select(fold_ids, ind_tr')
		}
		xtrain = X[index_tr, ]
		xbar   = mean(xtrain)
		xtrain = xtrain :- xbar //scale(xtrain)	
		xtest = X[index_te,]
		xtest = xtest :- xbar
		S_test = quadcross(xtest,xtest) :/ (rows(xtest))
		S_train = quadcross(xtrain,xtrain) :/ (rows(xtrain))
		CVglasso_fit(xtrain, max_iter, tolerance, diag) //nostandardize,
		for(j = 1; j <= nlam; j++)
		{
			if (crit == "loglik")
			{
				errs_fit[j,fold] =  (rows(xtest))  * ///
					(trace((*result[j]),S_test) - ///
					log(det((*result[j]))))
			}else if (crit == "eBIC"){
				if (diag == ""){
					nz = sum((*result[j]) :!= 0) - p
				}
				else{
					nz = sum((*result[j]) :!= 0)
				}
				errs_fit[j,fold] =  (rows(xtest))  * ///
					(trace((*result[j]),S_test) -  ///
					log(det((*result[j]))))  + ///
					nz * (log(rows(xtest))) +  4 * nz * gam * log(p)
			} else{
				if (diag == ""){
					nz = sum((*result[j]) :!= 0) - p
				}
				else{
					nz = sum((*result[j]) :!= 0)
				}
				errs_fit[j,fold] =  (rows(xtest))  * ///
					(trace((*result[j]),S_test) -  ///
					log(det((*result[j]))))  + ///
					nz
			}
		}
	}
	m_fit = mean(errs_fit')
	se_fit = sqrt(diag(variance(errs_fit))) :/ sqrt(nfold)
	i_best_fit = selectindex(m_fit :== min(m_fit))[1]
	lambda = lamlist[i_best_fit]
	gl.setup1(X, lambda, max_iter, tolerance, diag) //nostandardize, 
	Omega = gl.Omega
	Omega_inv = gl.Omega_inv
	if (nolog == "verbose")
	{
		plotcv(i_best_fit)
	}
}


void CV_GLasso::CVglasso_fit(real matrix xtrain, ///
			real scalar max_iter, real scalar tolerance, ///
			string scalar diag) //string scalar nostandardize,
{
	real scalar lbd, i
	real matrix init, init_omega
	result = J(length(lamlist),1, NULL)
	for(i = 1; i <= length(lamlist); i++)
	{
	       result[i] = &(J(p, p, 0)) 
	}
	if (diag != "")
	{
		init = diag(diagonal(S_train)) // + diag(J(p,1,max(lamlist)))
	}else{
		init = S_train + diag(J(p,1,max(lamlist)))
	}
	init_omega = diag(1:/diagonal(init)) 
	for(i = 1; i <= length(lamlist); i++)
	{
		lbd = lamlist[i]
		if (start == "warm")
		{
			gl.setup1(xtrain, lbd, max_iter,tolerance, diag, init, init_omega) //nostandardize,
			(*result[i]) = gl.Omega
			init = gl.Omega_inv 
			init_omega = gl.Omega
		}
		else{
			gl.setup1(xtrain, lbd, max_iter,tolerance, diag, init, init_omega) //nostandardize,
			(*result[i]) = gl.Omega
		}
	}

}

real matrix CV_GLasso::scale(real matrix x ,| ///
		real scalar center, real scalar scl)
{
    real scalar p, N
	real matrix S, diag_S
	real colvector sqrt_diag_S
	real colvector cnt
        if(args() == 1)
	{
	    center = 1
		scl  = 0
	}
	p = cols(x)
	N = rows(x)
	if(center == 1)
	{
		x = x :- mean(x)
	}
	if(scl == 1)
	{
		S = quadcrossdev(x, 0, mean(x), x, 0, mean(x)) :/ N
		sqrt_diag_S = sqrt(diagonal(S))
		diag_S = diag(1 :/ sqrt_diag_S)
		x = quadcross(x', diag_S)
	}
	return(x)
}

void CV_GLasso::plotcv(real scalar best_fit)
{
	string colvector buffer
	real scalar i
	// Display CV values
	buffer = J(rows(lamlist) + 2, 1, "")
	buffer[1] = sprintf("{txt}{space 1} Threshold {space 1} {c |} Value {space 2} ")
	buffer[2] = sprintf("{hline 14}{c +}{hline 15}")
	for(i = 1; i<= rows(lamlist); i++ ) {
		// Predict esitmated vectore
		buffer[i + 2] = sprintf("{txt}%10.0g{space 3} {c |} %3.2f {space 4}", lamlist[i], m_fit[i])
	}
	buffer[best_fit + 2] = buffer[best_fit + 2] + "*"
	printf("\n")
	printf("{txt} %s \n", selection)
	printf("\n")
	display(buffer)
}

end
