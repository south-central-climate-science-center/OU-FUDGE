

ReadMaskNC <- function(mask.nc,var.name=NA,dstart=NA,dcount=NA,verbose=FALSE) {
  message('Obtaining mask vars')
  mask.var <- names(mask.nc$var)[which(regexpr(pattern="mask", names(mask.nc$var)) != -1)]
  if(identical(mask.var, character(0))){
    stop(paste("Mask name error: no variable within the file", mask.nc$filename, 
               "has a name that matches the pattern 'mask'. "))
  }
  mask.list <- list()
  for (name in 1:length(mask.var)){
    mask.name <- mask.var[name]
    if(verbose){
      message(paste("Obtaining", mask.name, ":mask", name, "of", length(mask.var)))
    }
    mask <- ncvar_get(mask.nc,mask.name, dstart, dcount, collapse_degen=FALSE) #verbose adds too much info
    mask.list[[mask.name]] <- mask
  }    
  listout <- list('masks' = mask.list)
  attr(listout, "filename") <- mask.nc$filename
  nc_close(mask.nc)
  return(listout)
}

create.ncvar.list <- function(mask.nc, varname, dim.string){
  #'Creates a list with elements named in a manner appropriate
  #'for a NetCDF variable. 
  return(list('name' = varname, 
              'units' = mask.nc$var[[varname]]$units, 
              'dim' = dim.string,
              'longname' = mask.nc$var[[varname]]$longname,
              'prec' = correct.int(mask.nc$var[[varname]]$prec) ))
}

correct.int <- function(string){
  if(string=="int"){
    return("integer")
  }else{
    return(string)
  }
}