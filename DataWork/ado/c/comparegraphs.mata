version 16
set matastrict on


mata:

void comparegraphs(string matrix est, string matrix tr)
{
     real matrix  diffm, diffm2, true, estimated
	 real scalar p, nmbTrueEdges, nmbTrueGaps, trueEstEdges, i
	 real scalar fpr, tpr, tdr
	 real colvector combined
	 
	 true = st_matrix(tr)
	 estimated  = st_matrix(est)
	 if ((issymmetric(true) == 0) | (issymmetric(estimated) == 0))
	 {
 		errprintf("Input should be symmetric \n")
		exit(3498)
	 }
	 if ((rows(estimated) != cols(true)) | (cols(estimated) != rows(true)) | (rows(estimated) != rows(true)))
	 {
	    errprintf("True and Estimated matrix should have the same dimension \n")
		exit(3498)   
	 }
         p = rows(true)
	 for (i = 1; i <= p; i++)
	 {
		 true[selectindex(true[,i]), i] = J(length(selectindex(true[,i])), 1, 1)
		 estimated[selectindex(estimated[,i]), i] = J(length(selectindex(estimated[,i])), 1, 1)
	 }
	 estimated = estimated - diag(estimated)
	 true      = true - diag(true)
	 diffm = estimated - true
	 nmbTrueGaps = (sum(true :== 0)) / 2
	 if (nmbTrueGaps == 0)
	 {
	         fpr = 1
	 }else{
	         fpr = (sum(diffm :> 0) / 2) / nmbTrueGaps
	 }
	 diffm2 = true - estimated
	 nmbTrueEdges = sum(true :== 1) / 2
	 if (nmbTrueEdges == 0)
	 {
	         tpr = 0
	 }else{
	         tpr = 1 - (sum(diffm2 :> 0) / 2) / nmbTrueEdges
	 }
	 trueEstEdges = nmbTrueEdges - sum(diffm2 :> 0) / 2
	 if (nmbTrueEdges == 0)
	 {
	 	if(trueEstEdges == 0)
		{
	         tdr = 1
		}else{
			tdr = 0
		}
	 }else{
	         tdr = trueEstEdges / (sum(estimated :== 1) / 2)
	 }
	 
	 combined = (tpr\fpr\tdr)
	 st_rclear()
	 st_numscalar("r(tpr)", tpr)
	 st_numscalar("r(fpr)", fpr)
	 st_numscalar("r(tdr)", tdr)
	 st_matrix("combined",combined)
}

end
