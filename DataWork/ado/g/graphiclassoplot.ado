*! version 1.0.0  05jul2022

///////////////////////////////////////////////////////////
/// Plot random matrix 
///////////////////////////////////////////////////////////
program graphiclassoplot
version 16
syntax anything(name = mt)[, type(string) newlabs(string) *] //msize(passthru)

mat mt = `mt'
mata	mt = st_matrix("mt")
//mata 	r = convertmt(mt)

capt which nwplot
if _rc != 0{
         di as txt "user-written package nwcommands needs to be installed first;"
         di as txt "use -search nwcommands- to install"
         exit 498
}
nwclear
nwset, mat(mt) undirected // labs("`labs'")
nwname, newlabs("`newlabs'")
if "`type'" == "" | "`type'" == "graph"{
	nwplot, `options' 
}
else if "`type'" == "matrix" {
	nwplotmatrix, `options'
}
else{
	di as error "type should be wither graph or matrix"
}
end
