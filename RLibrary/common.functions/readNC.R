

ReadNC <- function(nc.object,var.name=NA,dstart=NA,dcount=NA,dim='none',verbose=FALSE) {

  clim.in <- ncvar_get(nc.object,start=dstart,count=dcount)            
  
  # get standard name,long name, units if present
  attname = 'standard_name'
  cfname <- ncatt_get(nc.object, var.name, attname) 
  attname = 'long_name'
  long_name <- ncatt_get(nc.object, var.name, attname)
  attname <- 'units' 
  units <- ncatt_get(nc.object, var.name, attname)
  attr(clim.in, "units") <- units

  #Control getting the dimensions and other variables in the output file
  dim.list <- list(dim=list(), vars=list())
  # odd since dim is a string with length=1
  for(d in 1:length(dim)){
      temp.list <- switch(dim[d], 
                          "spatial"=get.space.vars(nc.object, var.name), 
                          "temporal"=get.time.vars(nc.object, var.name),
                          #If other arg or "nothing", do nothing
                          list("dim"=list("none"), 'vars'=list("none"))
      )
      dim.list$dim <- c(dim.list$dim, temp.list$dim)
      dim.list$vars <- c(dim.list$vars, temp.list$vars)
      #print(names(dim.list$dim))
  }

    listout <- list("clim.in"=clim.in,"cfname"=cfname,"long_name"=long_name,"units"=units, 
                    "dim"=dim.list$dim, 'vars'=dim.list$vars)
    
    ###Add attributes for later QC checking against each other
    attr(listout, "calendar") <- nc.object$dim$time$calendar
    attr(listout, "filename") <- nc.object$filename
    nc_close(nc.object)
    return(listout)
}

get.space.vars <- function(nc.object, var){
  # Obtains spatial vars, grid specs and all vars not the main var of interest
  # that depend upon those vars
  # Axes with spatial information
  message('getting spatial vars')
  axes <- c("X", "Y", "Z")
  file.axes <- nc.get.dim.axes(nc.object, var)
  if(is.null(file.axes)){
    stop(paste("Error in ReadNC: File", nc.object$filename, "has no variable", var, "; please examine your inputs."))
  }else{
    print("Obtaining axis", )
    spat.axes <- file.axes[file.axes%in%axes] #Here is where the extra Z dim check comes in
    spat.varnames <- names(file.axes[file.axes%in%axes])
  }
  #Obtain any dimensions that reference space
  spat.dims <- list()
  for (sd in 1:length(spat.varnames)){
    ax <- spat.axes[[sd]]
    dim <- spat.varnames[[sd]]
    spat.dims[[dim]] <- nc.get.dim.for.axis(nc.object, var, ax)
    #Make sure that original file is being included, in order to support attribute cloning
    attr(spat.dims[[dim]], "filename") <- attr(nc.object, "filename")
  }
  #Obtain any dimensions that are not time
  #Obtain any variables that do not reference time
  #THIS is the bit that was tripping you up last time. deal with it, please.
  vars.present <- names(nc.object$var)[names(nc.object$var)!=var]
  spat.vars <- list()
  for(i in 1:length(vars.present)){
    var.loop <- vars.present[i]
    if(! ("time"%in%lapply(nc.object$var[[var.loop]]$dim, obtain.ncvar.dimnames))){
      spat.vars[[var.loop]] <- ncvar_get(nc.object, var.loop, collapse_degen=FALSE)
      #Grab the bits used to build the vars later
      att.vector <- c(nc.object$var[[var.loop]]$units, nc.object$var[[var.loop]]$longname, 
                      #nc.object$var[[var.loop]]$missval, 
                      nc.object$var[[var.loop]]$prec)
      att.vector[4] <- paste(names(nc.object$dim)[(nc.object$var[[var.loop]]$dimids)+1], collapse=",") #formerly 5
      names(att.vector) <- c("units", "longname", "prec", "dimids") #"missval", 
      att.vector[att.vector=='int'] <- "integer"
      for (a in 1:length(att.vector)){
        attr(spat.vars[[var.loop]], which=names(att.vector)[[a]]) <- att.vector[[a]]
      }
      #And finally, grab the comments attribute, which is important
      #for i and j offsets (but not much else)
      comments <- ncatt_get(nc.object, var.loop, 'comments')
      if(comments$hasatt){
        attr(spat.vars[[var.loop]], which='comments') <- comments$value
      }
    }
  }
  return(list("dim"=spat.dims, "vars"=spat.vars))
}

get.time.vars <- function(nc.object, var){
  #Obtains time vars, calendar attributes and all vars that depend on time
  #that are not the main var of interest
  message('getting time vars')
  axes<- c("T")
  file.axes <- nc.get.dim.axes(nc.object, var)
  if(is.null(file.axes)){
    stop(paste("Error in ReadNC: File", nc.object$filename, "has no variable", var, "; please examine your inputs."))
  }else{
    time.axes <- file.axes[file.axes%in%axes]
    time.varnames <- names(file.axes[file.axes%in%axes])
  }
  #Obtain any dimensions that reference time
  time.dims <- list()
  for (td in 1:length(time.varnames)){
    ax <- time.axes[[td]]
    dim <- time.varnames[[td]]
    time.dims[[dim]] <- nc.get.dim.for.axis(nc.object, var, ax)
    #Make sure that original file is being included, in order to support attribute cloning
    attr(time.dims[[dim]], "filename") <- attr(nc.object, "filename")
  }
  #Obtain any dimensions that are not time
  #Obtain any variables that do not reference time
  #THIS is the bit that was tripping you up last time. deal with it, please.
  if(length(time.varnames > 1)){
    vars.present <- names(nc.object$var)[names(nc.object$var)!=var]
    time.vars <- list()
    for(i in 1:length(vars.present)){
      var.loop <- vars.present[i]
      #Obtain all vars that have a dim named 'time'
      if( "time"%in%lapply(nc.object$var[[var.loop]]$dim, obtain.ncvar.dimnames) ){
        time.vars[[var.loop]] <- ncvar_get(nc.object, var.loop, collapse_degen=FALSE)
        #Grab bits needed to construct vars later; store as attributes
        att.vector <- c(nc.object$var[[var.loop]]$units, nc.object$var[[var.loop]]$longname, 
                        #nc.object$var[[var.loop]]$missval, 
                        nc.object$var[[var.loop]]$prec)
        att.vector[4] <- paste(names(nc.object$dim)[(nc.object$var[[var.loop]]$dimids)+1], collapse=",") #formerly 
        names(att.vector) <- c("units", "longname", "prec", "dimids") #"missval", 
        att.vector[att.vector=='int'] <- "integer"
        for (a in 1:length(att.vector)){
          attr(time.vars[[var.loop]], which=names(att.vector)[[a]]) <- att.vector[[a]]
        }
        #And finally, grab the comments attribute, which is important
        #for i and j offsets (but not much else)
        comments <- ncatt_get(nc.object, var.loop, 'comments')
        if(comments$hasatt){
          attr(time.vars[[var.loop]], which='comments') <- comments$value
        }
      }
    }
  }else{
    message("No variables but the main variable found using time dimension; continue on.")
    time.dims[[dim]]
  }
  return(list("dim"=time.dims, "vars"=time.vars))
}

obtain.ncvar.dimnames <- function(nc.obj){
  #obtains one of the names of the dimensions of a netcdf 
  #variable
  return(nc.obj[['name']])
}

