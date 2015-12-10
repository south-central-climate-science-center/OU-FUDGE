

callPRPostproc <- function(){
  #Performs the adjustments needed for post-downscaling precipitation
  #on the downscaled ouput, including a threshold adjustment for drizzle
  #bias and conservation of the total precipitation per time range
  
  if(rp$target.var=='pr'){
    ref.data<-list.target$clim.in
    adjust.data<-list.hist.pr$clim.in
    adjust.future<-list.fut.pr$clim.in
    adjust.ds <- ds.out
    
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
      adjust.ds[pr.masks.outer$future==0] <- 0
    }
    
    if(apply.S5.wetday.mask){
      # Here is a unique S5 option, which forces precip=0 in the DS output for days
      #  in the future GCM where precip < threshold (if threshold=T) or where precip = 0
      message('Outer S5 adjustment')
      message('Applying wetday mask to DS output. Output will have at least as many days without precip as the CF datset.')
      # switch NA's back to zero 
      adjust.ds[pr.masks.outer$future==0] <- 0
    }else{
      message('Not applying wetday mask. Output may have fewer days without precipitation than expected.')
    }
    
    #Apply the conserve option to the data
    if(lopt.conserve){
      adjust.future.units=attr(adjust.future, "units")$value
      #Obtain mask of days that will be eliminated
      # uses same threshold as S3 step
      out.mask <- MaskPRSeries(adjust.ds, adjust.future.units, threshold)
      # Loop over all lat/lon points available in the input datasets
      # assume lat/long dimensions are exactly the same for all datasets  
      for (i in 1:dim(adjust.ds)[1]){
        for (j in 1:dim(adjust.ds)[2]){ 
          esd.select <- adjust.ds[i,j,]
          mask.select <- out.mask[i,j,]
          esd.select[!is.na(esd.select)]<- conserve.prseries(data=esd.select[!is.na(esd.select)], 
                                                             mask=mask.select[!is.na(mask.select)])
          adjust.ds[i,j,] <- esd.select
          #Note: This section will produce negative pr if conserve is set to TRUE and the threshold is ZERO. 
          #However, there are checks external to the function to get that, so it might not be as much of an issue.
        }
      }
      #Apply the mask
      out.list <- list("ds.out" = as.numeric(adjust.ds) * out.mask)
      # Add the DS precip mask to the others
      pr.masks.outer$ds <<- list("DS"=out.mask)
    }
    return(out.list)          
  }else{
    stop("Target variable was not precipitation, returning without precip adjustments")
  }
}

