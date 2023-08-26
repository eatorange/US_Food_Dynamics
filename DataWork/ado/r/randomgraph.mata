*! version 1.0.0  08apr2022
version 16
set matastrict on


mata:
class randomgraph
{
       // Public Functions
	public:
		void				setup()
		real matrix 		   	cov2cor()
		real matrix            		mvrnorm()      // variance matrix
		struct sim_result scalar  	RandomGraph()
	// Private Funcitons

	
	// Input variables
	public: 
		real scalar			n
		real scalar			p
		real scalar			v
		real scalar            		u
		real scalar            		prob
//		real scalar			seed
		struct sim_result scalar 	result
    // Output variables
	public:
		real matrix 			data
		real matrix 			Sigma
		real matrix 			S
		real matrix 			Omega
		real matrix 			sparsity

}
struct sim_result
{
	real matrix data
	real matrix Sigma
	real matrix S
	real matrix Omega
	real matrix sparsity
}

void randomgraph::setup(real scalar user_n, ///
		real scalar user_p,  ///
		real scalar user_v,  ///
		real scalar user_u,  ///
		real scalar user_prob)  //, real scalar user_seed
{
    
	n = user_n
	p = user_p
	v = user_v
	u = user_u
//	seed = user_seed
	prob = user_prob
	result = RandomGraph()
	data  = result.data
	Sigma = result.Sigma
	S     = result.S
	Omega = result.Omega
	sparsity = result.sparsity
	st_rclear()
	st_matrix("r(Omega)", Omega)
	st_matrix("r(Sigma)", Sigma)
	st_matrix("r(S)", S)
	st_matrix("r(data)", data)
	st_numscalar("r(sparsity)", sparsity)
	st_matrix("var", data)
}

struct sim_result scalar randomgraph::RandomGraph()
{
	real matrix theta, tmp, omega, X, sigma, sigmahat, L, data
	struct sim_result scalar sim
	real scalar i
	real colvector data_bar
//	rseed(seed)
	theta = J(p, p, 0)
	tmp = runiform(p, p, 0, 0.5)
	tmp = tmp + tmp'
	for(i = 1; i <= p; i++)
	{
		theta[selectindex(tmp[i,] :< prob),i] ///
			=  J(rows(selectindex(tmp[,i] :< prob)), 1,1)
		theta[i,i] = 0
	}
	theta = (theta + theta') :/ 2
	omega = theta :* v
	eigensystem(omega, X, L)
	for(i = 1; i <= p; i++)
	{
		omega[i,i] =  abs(min(Re(L))) + 0.1 + u
	}
	sigma = cov2cor(invsym(omega))
	omega = invsym(sigma)
	for(i = 1; i <= p; i++)
	{
		omega[selectindex(omega[.,i] :< 1e-10), i] = ///
			J(rows(selectindex(omega[.,i] :< 1e-10)), 1, 0)
	}
	data = mvrnorm(J(p,1,0), sigma)
	data_bar = mean(data)
	sigmahat = quadcross(data :- data_bar, data :- data_bar) :/ (n - 1)
	sim.data = data
	sim.Sigma = sigma
	sim.Omega = omega
	sim.S = sigmahat
	sim.sparsity = sum(theta) / (p * (p -1))
	return(sim)
}

real matrix randomgraph::cov2cor(real matrix A)
{
	real scalar p, i
	real colvector diagsq
	real matrix r
	p = rows(A)
	diagsq = sqrt(1 :/ diagonal(A))
	r = diagsq :* A :* diagsq'
	for(i = 1; i<=p; i++)
	{
	   r[i,i] = 1
	}
	
	return(r)
}

real matrix randomgraph::mvrnorm(real colvector mean, real matrix sigma)
{
	real matrix L, X
	real colvector u
	real scalar p,i
	p = rows(sigma)
	L = cholesky(sigma)
	X = J(n, p, 0)
	u = rnormal(n, p, 0, 1)
	X = mean' :+ u * L'
	/*
	for(i = 1; i<= n; i++)
	{
		u = rnormal(p,1, 0, 1)
		X[i, ] = (mean + L * u )'
	}
	*/
	return(X)
}

end
