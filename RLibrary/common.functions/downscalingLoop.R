

dsLoop <- function( ){
  
  # Apply window mask
  if(!is.na(window.masks[[window]])){
    # assume both climate data and window masks are always temporal (1D)
    tmp.w.t <- ifelse(windows$hist==window.masks[[window]],1,NA)
    tmp.w.h <- ifelse(windows$hist==window.masks[[window]],1,NA)
    tmp.w.f <- ifelse(windows$fut==window.masks[[window]],1,NA)
    target <- target*tmp.w.t
    for(i in 1:length(rp$predictor.vars)){
      df.hist[i] <- df.hist[i]*tmp.w.h
      df.fut[i] <- df.fut[i]*tmp.w.f
    }
  }
  
  # Apply k-fold mask
  if(!is.na(kfold.masks[[kfold]])){
    # assume both are always temporal (1D)
  }
  # apply "inner" S3 adjustments
  # S3 inner function not written yet ... so make sure it doesn't run
  rp$apply.S3.inner <- FALSE
  if(rp$apply.S3.inner){
    S3.tmp <- callS3AdjustmentInner()
    # ... 
  }

  # Call DS method
  # note the DS function actually used depends on the library read
  temp.out <- callDS(target=target,df.hist=df.hist,df.fut=df.fut)
  ds.predict <- temp.out$ds.predict
  df.fit <- as.data.frame(temp.out$df.fit)
  
  # Need to apply S5 adjustment here
  # ...
  # Need to collect QC masks here
  # ...
  
  return(list("ds.predict"=ds.predict, "df.fit"=df.fit))
}
  
#Converts NAs to 0, and all non-NA values to 1
#and returns the result in a 1-D form
convert.NAs<-function(dataset){
  dataset2<-dataset
  dataset2[is.na(dataset)]<-0
  dataset2[!is.na(dataset)]<-1
  return(as.vector(dataset2))
}