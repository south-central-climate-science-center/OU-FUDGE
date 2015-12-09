callS3AdjustmentOuter<-function(){
  for(element in 1:length(rp$s3.outer.list)){
    test <- rp$s3.outer.list[[element]]
    print(test)
    adjusted.list <- switch(test,
                            'PR' = return(adjustWetDays()),
                            stop(paste('Adjustment Method Error: method', test, 
                                       "is not supported for callS3Adjustment. Please check your input.")))
    # modify code here to allow multiple pre-DS adjustments in order given
    # right now only a precip adjustment is in the R code
  }
  # create adjusted.list
  return(adjusted.list)
}

