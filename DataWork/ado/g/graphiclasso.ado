*! version 1.0.0  05jul2022

//////////////////////////////////////////////////////
/// Implements Graphical Lasso
//////////////////////////////////////////////////////

program graphiclasso, eclass
version 16

	////neq code
	_parse comma matrix rest : 0
	capture confirm matrix `matrix'


	if _rc == 0 {            // syntax 2:  matrix
		local syntax 2
		syntax [anything(name=mt)] ///
		[, LAMbda(real 0.1)        ///
		max_iter(integer 1000)    ///
		TOLerance(real 1e-5)     ///
		diag] //NOSTANDardize
	}
	else {                                        // syntax 1: varlist
		local syntax 1
		syntax varlist(min=2 numeric) [if] [in] ///
			[, LAMbda(real 0.1)  ///
			max_iter(integer 100) ///
			TOLerance(real 1e-5) ///
			diag] //NOSTANDardize
		marksample touse
		markout `touse'
	}
	ereturn clear
	mata: r = GLasso(1)
	if `syntax' == 1{
			mata: r.setup("`varlist'", "`touse'", ///
			`lambda', `max_iter', `tolerance', "`diag'") //"`nostandardize'",
	}
	else{
		mata: X = st_matrix("`matrix'")
		mata: r.setup1( X, `lambda',  `max_iter', ///
		`tolerance', "`diag'") //"`nostandardize'",
	}

	//return add
	if `r(totaliter)' < `max_iter' {
		di
		di as result "The algorithm converged at iteration `r(totaliter)'"
	}
	else{
		di
		di as result "The algorithm did not converge. Please increase " ///
		"the number of iterations"
	}

end





