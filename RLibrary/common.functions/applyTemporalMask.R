# fxn opens, reads and applies a time windowing mask
# fxn is called within the primary DS loop
# this is slow since it reads the nc obj for each i,j, pass
  # might reorder loop k,w,i,j ??

#spatial masks are 2D
#temporal masks are 1D
#kfold masks are either spatial or temporal

#right now the data passed to the DS fxn is a subset of I=i, J=j and all T, 
#so this is a vector with NULL dimension


applyTemporalMask2 <- function(data, mask){
  #Assume a 1-D mask and 3-D data
  if(!is.null(mask)){
    if(length(mask)!=length(data[1,1,])){
      stop(paste("Temporal mask dimension error: mask was of dimensions ", length(mask), 
                 "but was expected to be dimension ", length(data[1,1,]), sep=''))
    }
    return(matrimulttemporal(data, mask))  
  }else{
    message("No spatial mask included; passing data as-is")
    return(data)
  }
}
  
  
matrimulttemporal<-function(mat,n){
  ret<-mat
  latdim<-dim(mat)[1]
  londim<-dim(mat)[2]
  for (i in 1:latdim){
    for(j in 1:londim){
      ret[i,j, ]<-mat[i,j, ]*n  
    }
  }
  return(ret)
}

