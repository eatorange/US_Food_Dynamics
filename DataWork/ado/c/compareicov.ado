*! version 1.0.0  05jul2022

//////////////////////////////////////////////////////
/// Function to compare graphs
//////////////////////////////////////////////////////

program compareicov, rclass
version 16

	_parse comma matrix rest : 0
	capture confirm matrix `matrix'
	if _rc != 0{
			di as error "Input should be a matrix"
	}
	////neq code
	syntax anything(name = estimated), true(string) 

	if "`estimated'" == "" | "`true'" == ""{
			di as error "Both matrices should be specified"
	}


	mata: comparegraphs("`estimated'", "`true'")

	matrix rownames combined = tpr fpr tdr

	return matrix combine = combined
	return add

end

