applySpatialMask<-function(data, mask){
  #Assume a 2-D mask and 3-D data
  if(!is.null(mask)){
    if(length(mask[1,])!=length(data[1,,1])||length(mask[,1])!=length(data[,1,1])){
      stop(paste('Spatial mask dimension error: mask was of dimensions', dim(mask)[1], dim(mask)[2], 
                 "and was expected to be of dimensions", data_dim[1], data_dim[2]))
    }
    return(matrimultspatial(data, mask))  
  }else{
    message("No spatial mask included; passing data as-is")
    return(data)
  }
}
#Multiplies the lat./lon. mask by the spatial data at each timestep
#Assumes a 3-D matrix of original data.
#This is a strictly internal method
matrimultspatial<-function(mat,n){
  ret<-mat
  timedim<-dim(mat)[3]
  for (i in 1:timedim){
    ret[,,i]<-mat[,,i]*n
  }
  return(ret)
}