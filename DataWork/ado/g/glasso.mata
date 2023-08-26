*! version 1.0.0  08apr2022
version 16
set matastrict on


mata:
struct GLasso_result
{
	// Structure to store the result
	real matrix Omega
	real matrix Omega_inv
}

struct decomp_matrix
{
	// Structure used to decompose symmetric matrix 
	real matrix A11
	real colvector a12
	real scalar    a11
}


class GLasso
{
    // Public Functions
	public:
		void				setup()
		void 				setup1()
		real rowvector 			mean_X()
		real matrix             	S()      // variance matrix
		real scalar             	N()      // # obs 
		real scalar             	p()      // # X vars 
		real scalar             	ispdf()
		real matrix            		standardizeX()
		struct GLasso_result scalar 	GLasso_fit()
		real scalar			soft()
		real matrix 			S
		real matrix 			Omega
		real matrix 			Omega_inv
	// Private Funcitons

	private:
		struct decomp_matrix scalar 	block_decomp()
	
	// Input and estimated variables
	public:
		pointer(real matrix) scalar 	X  
		real scalar			lambda
		struct GLasso_result scalar 	result
		real matrix 			init	
		real matrix			init_omega
		
	private:
		real matrix			W
		real colvector			w
		real scalar			sigma
		real matrix			standardizedX
		real scalar             	X_st
		real rowvector          	mean_X
		real scalar			totaliter
	
}


///////////////////////NEW CODE for the syntax ////////////////////////////////
void GLasso::setup1(real matrix user_X, real scalar lbd, ///
		real scalar max_iter, real scalar tolerance, ///
		| string scalar diag, real matrix init_s, real matrix init_o) //string scalar nostandardize,
{
	string colvector cv
//	if(nostandardize == "")
//	{
//		X      = &standardizeX(user_X)
//	}else{
	X = &user_X
//	}
	lambda = lbd
	if(lambda < 0)
	{
	    errprintf("lambda must be positive \n")
		exit(498)
	}
	if(max_iter < 0)
	{
	    errprintf("Number of iterations should be positive \n")
		exit(498)
	}
	if(tolerance < 0)
	{
	    errprintf("Threshold should be positive \n")
		exit(498)
	}
	if(cols(*X) < 2)
	{
	    errprintf("Number of variables should be >2. \n")
		exit(498)
	}
	S = S()
	if (args() == 6)
	{
		init = init_s
		init_omega = luinv(init_s)
	}else if (args() > 6){
		init = init_s
		init_omega = init_o

	}else{
			if(diag != "")
			{
			init = S + lambda * diag(J(1,p(),1)) 
			}else{
			    init = S
			}
			init_omega = diag(1:/diagonal(init)) 
	}
	result = GLasso_fit(max_iter, tolerance, diag) //, nostandardize
	Omega = result.Omega
	Omega_inv =  result.Omega_inv
	st_eclear()
	st_matrix("e(Omega)", Omega)
	st_matrix("e(Sigma)", Omega_inv)
	st_matrix("e(lambda)", lambda)
	st_numscalar("r(totaliter)", totaliter)
}




//////////////////////////////////////////////////////////////

void GLasso::setup(string scalar varlist, string scalar touse, ///
			real scalar lbd, real scalar max_iter, ///
			real scalar tolerance,| string scalar diag, ///
			real matrix init_s, real matrix init_o ) //string scalar nostandardize, 
{
	real matrix user_X
	string colvector cv
	pragma unset user_X
	st_view(user_X, ., tokens(varlist), touse)
//	if(nostandardize == "")
//	{
//		X      = &standardizeX(user_X)
//	}else{
	X = &user_X
//	}
	lambda = lbd
		if(lambda < 0)
	{
		errprintf("lambda must be positive \n")
		exit(498)
	}
	if(max_iter < 0)
	{
		errprintf("Number of iterations should be positive \n")
		exit(498)
	}
	if(tolerance < 0)
	{
		errprintf("Threshold should be positive")
		exit(498)
	}
	if(cols(*X) < 2)
	{
		errprintf("Number of variables should be >2. \n")
		exit(498)
	}

	S = S()
	if (args() == 7)
	{
		init = init_s
		init_omega = luinv(init_s)
	}else if (args() > 7){
		init = init_s
		init_omega = init_o
	}else{
		if(diag != "")
		{
			init = S + lambda * diag(J(1,p(),1)) 
		}else{
		    init = S
		}
		init_omega = diag(1:/diagonal(init)) 
	
	}
	cv = tokens(varlist)
	
	if (length(uniqrows(cv)) != length(cv)) 
	{
		errprintf(" repeated variables not allowed \n")
		exit(498)
	}
 //   tolerance = tolerance * mean(abs(mean(S - diag(diagonal(S)))'))
	result = GLasso_fit(max_iter, tolerance, diag) //nostandardize
	Omega = result.Omega
	Omega_inv =  result.Omega_inv
	st_eclear()
	st_matrix("e(lambda)", lambda)
	st_matrix("e(Omega)", Omega)
	st_matrix("e(Sigma)", Omega_inv)
	st_numscalar("r(totaliter)", totaliter)
}


real scalar GLasso::N() return(rows(*X))
real scalar GLasso::p() return(cols(*X))


real rowvector GLasso::mean_X()
{
	// Function to return the mean of each column
        mean_X = mean(*X)
        return(mean_X)
}


real matrix GLasso::S()   
{
	// Function returns the sample covariance
		S = quadcrossdev(*X, 0, mean_X(), *X, 0, mean_X()) :/ (N() - 1)
	return(S)
}


real matrix GLasso::standardizeX(real matrix X)
{
	// Standardies X to have mean 0 and variance 1
	real matrix diag_S, st_X
	real vector sqrt_diag_S
	real colvector inv_diag_S
	st_X = X :- mean(X)
	S = quadcross(st_X, st_X) / rows(X)
	sqrt_diag_S = sqrt(diagonal(S))
	sqrt_diag_S
	diag_S = diag(1 :/ sqrt_diag_S)
	inv_diag_S = (1 :/ sqrt_diag_S)
	standardizedX = quadcross(st_X', diag_S)
	return(standardizedX)
}


struct decomp_matrix scalar GLasso::block_decomp(real matrix mat, ///
				real scalar index)
{
	// Function to decompose matrix into column vector and submatrix
	struct decomp_matrix scalar res
//	real matrix tmp
	res.a12 = select(mat[,index], (1::p()) :!= index)
	res.A11 = select(select(mat, (1..p()) :!= index), (1::p()) :!= index)
	res.a11 = mat[index,index]
	
	return(res)
}


struct GLasso_result scalar GLasso::GLasso_fit(real scalar max_iter, ///
		real scalar tolerance, string scalar diag) //string scalar nostandardize
{
	struct decomp_matrix scalar dec1, dec2, dec3
	struct GLasso_result scalar res
	real colvector beta, beta_old, s, beta_j, omega
	real rowvector sel_ind
	real scalar converge_beta, s_ii, omega_ii, converge_omega, iter, i, j
	real rowvector W_j
	real matrix Omega_inv_old, Omega, Omega_inv, Omega_old
	//Initialization of algorithm
	Omega_inv = init
	Omega =  init_omega //diag(1:/diagonal(Omega_inv)) 
	iter = 0
	totaliter = max_iter
	converge_omega = 0
			// Update diagonal
	while((converge_omega == 0) & (iter <= max_iter))
	{
		Omega_inv_old = Omega_inv
		Omega_old = Omega

		// Update nondiagonals
		for (i = 1; i <= p(); i++)
		{
			dec1 = block_decomp(Omega_inv, i)
			W = dec1.A11
			w = dec1.a12
//			sigma = dec1.a11
			dec2 = block_decomp(S, i)
			s = dec2.a12
//			s_ii = dec2.a11	

			// Initialize beta
			beta = beta_old = J((p() - 1), 1, 0)
			converge_beta = 0
			while (converge_beta == 0)
			{
				beta_old = beta
				for (j = 1; j <= (p() - 1); j++)
				{
					beta_j = select(beta,(1::(p()-1)) :!= j)
					W_j = select(W[,j], (1::(p()-1)) :!= j)
					beta[j] = (soft((s[j] - ///
					quadcross(W_j, beta_j)), lambda))/ (W[j,j])               
				}
				if (sum(abs(beta - beta_old):^2) < tolerance) 
				{
					converge_beta = 1
				}
			}
			// Update  W, w, and sigma
			w = W * beta //quadcross(W', beta)
			sel_ind = select((1..(p())) , (1..(p())) :!= i)
			Omega_inv[i, sel_ind] = w' 
			Omega_inv[sel_ind', i] = w
			omega_ii    = 1 / (Omega_inv[i,i] - quadcross(w, beta))
			omega = -beta :* omega_ii
			Omega[i, sel_ind] = omega' 
			Omega[sel_ind', i] = omega
			Omega[i,i] = omega_ii	
			if (sum(abs(Omega_inv - Omega_inv_old):^2) < tolerance)
			{
				converge_omega = 1
				totaliter = i
			}else{
				iter = iter + 1
			}
		}
	}
	
	// return the results
	res.Omega = Omega
	res.Omega_inv = Omega_inv
	return(res)
}


real scalar GLasso::soft(real colvector a, real scalar b)
{
	// Function to implement soft-thresholding
	return( sign(a) :* max((abs(a) :- b)\0))
}

real scalar GLasso::ispdf(real matrix A)
{
        real matrix N, M
        if(issymmetric(X) == 0)
	{
		errprintf(" Matrix is not symmetric")
		exit(3498)
	}
	N = .
	M = .
	eigensystem(A, N, M)
	if (length(selectindex(Re(M) :< 0)) > 0)
	{
	        return(0)
	}else{
	        return(1)
	}
	
}

end



