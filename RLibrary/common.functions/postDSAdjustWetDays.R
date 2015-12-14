

callPRPostproc <- function(){
  #Performs the adjustments needed for post-downscaling precipitation
  #on the downscaled ouput, including a threshold adjustment for drizzle
  #bias and conservation of the total precipitation per time range
  
  if(rp$target.var=='pr'){
    adjust.future <- list.fut.pr$clim.in
    adjust.ds <- ds.out
    full.dims <- dim(ds.out)
    
    # First need to collapse windows and kfold to a single column
    # Assumes no overlapping dates within windows or kfolds
    # This is really awkward but fine to do, ONLY if the kfolds are either 'NA' or non-overlapping
    # The windows must also be 'NA' or non-overlapping
    # if kfolds duplicate data (e.g., folds are random subsets with replacement), then this is not allowed
    # otherwise this returns the mean of the non-overlapping data across windows and kfolds
    adjust.ds.single <- apply(adjust.ds, c(1:3), mean, na.rm=TRUE)
    # crude check
    mean(adjust.ds.single, na.rm=T)
    mean(adjust.ds, na.rm=T)

        
    # right now these option are the same for S3 & S5 ... might need to adjust this logic
    threshold <- rp$pr.adj.args.outer[1]
    # Never adjusting to another frequency at this point in the process
    lopt.drizzle <- FALSE
    lopt.conserve <- rp$pr.adj.args.outer[3]
    
    # apply.0.mask: Converts days with precipitation below the threshold
    # to NA instead of 0, so that downscaling only takes place on those days 
    # with precipitation greater than the trace. Days are converted back to 0
    # after downscaling based on the future predictor (CF, MF) mask during
    # post-downscaling adjustment.
    #
    apply.0.mask <- rp$pr.adj.args.outer[4]
    
    if(apply.0.mask){
      message('Outer S5 adjustment')
      message('Backing out the apply.0.mask from the S3 adjustment (NAs --> zeros)')
      # switch NA's back to zero 
      adjust.ds.single[pr.masks.outer$future==0] <- 0
    }
    
    if(rp$apply.S5.wetday.mask){
      # Here is a unique S5 option, which forces precip=0 in the DS output for days
      #  in the future GCM where precip < threshold (if threshold=T) or where precip = 0
      message('Outer S5 adjustment')
      message('Applying wetday mask to DS output. Output will have at least as many days without precip as the CF datset.')
      # switch NA's back to zero 
      adjust.ds.single[pr.masks.outer$future==0] <- 0
    }else{
      message('Not applying wetday mask. Output may have fewer days without precipitation than expected.')
    }
    
    #Apply the conserve option to the data
    if(lopt.conserve){
      adjust.future.units=attr(adjust.future, "units")$value
      # Obtain mask of days that will be eliminated
      # uses same threshold as S3 step
      out.mask <- MaskPRSeries(adjust.ds.single, adjust.future.units, threshold)
      # Loop over all lat/lon points available in the input datasets
      # assume lat/long dimensions are exactly the same for all datasets  
      for (i in 1:dim(adjust.ds.single)[1]){
        for (j in 1:dim(adjust.ds.single)[2]){ 
          esd.select <- adjust.ds.single[i,j,]
          mask.select <- out.mask[i,j,]
          esd.select[!is.na(esd.select)]<- conserve.prseries(data=esd.select[!is.na(esd.select)], 
                                                             mask=mask.select[!is.na(mask.select)])
          adjust.ds.single[i,j,] <- esd.select
          #Note: This section will produce negative pr if conserve is set to TRUE and the threshold is ZERO. 
          #However, there are checks external to the function to get that, so it might not be as much of an issue.
        }
      }
    }  
    # Apply the mask
    # Precip masks are 3D arrays
    out.list <- (as.numeric(adjust.ds.single) * out.mask)
    dimnames(out.list)<-NULL
    out.list[is.nan(out.list)]<-NA
    dimnames(out.list)
    # Add the DS precip mask to the others
    pr.masks.outer$ds <<- out.mask
    
    # Now, expand the 3D array adjusted.ds.single -->> the original 5D array
    # Doing it this way preserves the original Windows and Kfold array indicies for non-NA values
    tmp.q<-NULL
    for(i in 1:length(window.masks)){
      tmp.q[i] <- list(out.list)
    }
    tmp.q1 <- abind(tmp.q,rev.along=0)
    dim(tmp.q1)
    mean(tmp.q1[1,1,1,])
    tmp.q2<-NULL
    for(i in 1:2){
      tmp.q2[i] <- list(tmp.q1)
    }
    tmp.q3 <- abind(tmp.q2,rev.along=0)
    dim(tmp.q3)
    mean(tmp.q3,na.rm=T)
    revert <- function(x,y){
      if(!is.na(x)){
        x<-y
      }else{
        x<-NA
      }
    }
    dim(out.list)
    dim(tmp.q3)
    az <- mapply(revert,out.list,tmp.q3,SIMPLIFY=TRUE)  
    az <- unlist(az)
    az <- array(az,dim=full.dims)
    
    mean(out.list, na.rm=T)
    mean(az,na.rm=T)
    out.S5 <- list("out.S5"=az)
    return(out.S5)          
  }else{
    stop("Target variable was not precipitation, returning without precip adjustments")
  }
}

