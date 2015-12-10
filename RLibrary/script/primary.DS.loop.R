# this is the primary DS looping structure
# it is a pretty generic i,j,windiwing,k-fold nested loops
# it should be easily modified to allow different functionality
# these are applied to a single target and future target grid cell, one-at-a-time
# allows multiple predictors, but only single target vars

rp$apply.S3.outer <- FALSE
if(rp$apply.S3.outer){
  message("Applying pre-DS adjustments")
  tmp <- callS3AdjustmentOuter()
  # write adjustments to climate datasets
  # this code only work for PR adjustment
  # will need to make dynamic within the callS3AdjustmentOuter function
  list.target$clim.in <- tmp$ref  
  list.hist.pr$clim.in <- tmp$adjust 
  list.fut.pr$clim.in <- tmp$future
  rm(tmp)
}

# assume window masks are 1D - temporal only
if(rp$create.window.mask){
  # create and list window masks
  windows <- createWindowMask.seasonal()
  window.masks <- unlist(windows$season)
}else{
  if(rp$supply.window.mask){
    # read existing window masks
    # need an example script to read in window masks and convert to time vectors 
    # this option is not working right now ... I do not have an example window mask
    source(paste(ROOT,script.lib,'read.window.masks.R',sep=''))
    window.masks <- NA
  }else{
    window.masks <- NA
  }
}

# assume k-fold validation masks are 1D time vectors
if(rp$create.kfold.mask){
  # kfold masks on the fly
  # option not used right now
  kfolds <- createKfoldMask.random()
  kfold.masks <- unlist(kfolds$random)
}else{
  if(rp$supply.kfold.mask){
    # supplied kfold masks are entered here 
    # assumption that only one mask is allowed
    # this option is not working ... I do not have an example kfold mask
    source(paste(ROOT,script.lib,'read.kfold.masks.R',sep=''))
    kfold.masks <- NA
  }else{
    kfold.masks <- NA
  }
}


# Create downscale results array
# Has dims(lon-index,lat-index,time,windows,kfold)
# Filling array with NA's to be overwritten by DS results
if(rp$create.ds.output){
  message("Creating empty DS output array")
  # get length and dims in the original input source
  i.name <- seq(1,dims.fut[1])
  j.name <- seq(1,dims.fut[2])
  t.name <- seq(1,dims.fut[3])
  w.name <- window.masks
  k.name <- kfold.masks
  ds.out <- array(NA,
                  dim=c(dims.fut[1],
                       dims.fut[2],
                       dims.fut[3],
                       length(window.masks),
                       length(kfold.masks)), 
                  dimnames=list(i.name,j.name,t.name,w.name,k.name))
}else{
  message("Run will produce no downscale output")
  ds.out <- NA
}

# create null list to append DS fit summary info
fit.summary <- data.frame()


# This is the primary looping structure that trains and applies DS to the datasets
# Loops: Window masks --> kfold masks --> Lat --> Lon
#
# spatial & temporal windowing masks index
message(paste("DS with method ", rp$ds.method, " ", rp$ds.lib))
for (window in 1:length(window.masks)){
  message(paste("Begin Window mask = ", window))

  # k-fold validation index
  for(kfold in 1:length(kfold.masks)){
    message(paste("Begin kfold mask = ", kfold))

    # longitude index
    #for(i.index in i.index.lower:i.index.upper){
    for(i.index in 1:length(list.target$clim.in[,1,1])){

      # latitude index
      #for(j.index in j.index.lower:j.index.upper){
      for(j.index in 1:length(list.target$clim.in[1,,1])){
        message(paste("Begin processing point with lon index (i) = ", i.index, "and lat index (j) =", j.index))
 
        # step avoids looping over subsets of all zero's data
        if(all(!is.na(list.target$clim.in[i.index,j.index,]))){
        
        # create subsetted datasets
        target <- list.target$clim.in[i.index,j.index,]
        
        # put historical predictor vars into a data frame
        for (v in 1:length(rp$predictor.vars)){
          tmp.h <- paste0('list.hist.',rp$predictor.vars[[v]])
          assign(paste0(rp$predictor.vars[[v]]), get(tmp.h)$clim.in[i.index,j.index,])
          if(v==1){
            df.hist <- data.frame(get(rp$predictor.vars[[v]]))
            rm(list=(paste(rp$predictor.vars[[v]])))
          }else{
            df.hist <- cbind(df.hist, get(rp$predictor.vars[[v]]))
            rm(list=(paste(rp$predictor.vars[[v]])))
          }
        }
        names(df.hist) <- rp$predictor.vars
        rm(tmp.h,v)
        # put future predictor vars into a data frame
        for (v in 1:length(rp$predictor.vars)){
          tmp.f <- paste0('list.fut.', rp$predictor.vars[[v]])
          assign(paste0(rp$predictor.vars[[v]]), get(tmp.f)$clim.in[i.index,j.index,])          
          if(v==1){
            df.fut <- data.frame(get(rp$predictor.vars[[v]]))
            rm(list=(paste(rp$predictor.vars[[v]])))
          }else{
            df.fut <- cbind(df.fut, get(rp$predictor.vars[[v]]))
            rm(list=(paste(rp$predictor.vars[[v]])))
          }
        }
        names(df.fut) <- rp$predictor.vars
        rm(tmp.f, v)

        # Call DS function
        loop.temp <- dsLoop()
        
        # insert downscale results into the array
        # DS output "ds.predict" is matched by dimnames
        afill(ds.out) <- loop.temp$ds.predict 
        # parms output as data frame
        # adds i,j,window,k attributes
        df.fit <- as.data.frame(loop.temp$df.fit)
        fit.summary <- rbind(fit.summary,df.fit)
        rm(loop.temp)
        }
      }
    }
  }
}

if(rp$apply.S5.outer){
  message("Applying post DS adjustments (section 5)")
  tmp <- callS5AdjustmentOuter()
  # write adjustments to the DS output
  # this code only work for PR adjustment
  # will need to make dynamic within the callS3AdjustmentOuter function
  ds.out <- tmp$ds.out
  rm(tmp)
}

