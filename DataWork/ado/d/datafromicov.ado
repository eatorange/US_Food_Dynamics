*! version 1.0.0  08apr2022

///////////////////////////////////////
///// Simulate the radnom graph 
////////////////////////////////////// 
program datafromicov, rclass
version 16
	syntax  , n(integer) p(integer) ///
	[v(real 0.3)  u(real 0.1) prob(string) ]  //seed(integer 100)


	if "`prob'" == ""{
		scalar prob = min(1, 3 / `p')
		scalar prob = sqrt(prob/2) * (prob < 0.5) + ///
		(1 - sqrt(0.5 - 0.5 * prob)) * (prob >=0.5)
	}
	else if `prob' > 0 & `prob' <= 1 {
		scalar prob = `prob'
	}
	else{
		display as error "probability should be between 0 and 1"
		exit 111
	}
	if `n' <= 1 | `p' <= 1{
		display as error "number of observations should be >1"
	}
	if `v' <= 0 | `u' <= 0{
		display as error "v or u should be positive"
	}
	capt which nwplot
	if _rc != 0 {
		 di as txt "user-written package nwcommands needs to be installed first;"
		 di as txt "use -search nwcommands- to install"
		 exit 498
	}

	mata: r = randomgraph(1)
	mata: r.setup(`n', `p', `v', `u', st_numscalar("prob")) //, `seed')
	svmat var
	return add
	

	
end

