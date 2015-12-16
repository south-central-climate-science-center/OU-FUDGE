
callS5AdjustmentOuter<-function(){
  for(element in 1:length(rp$s5.outer.list)){
    test <- rp$s5.outer.list[[element]]
    print(test)
    adjusted.list <- switch(test,
                            'SBiasCorr' = return(callSBCorr()),
                            'PR' = return(callPRPostproc()),
                            stop(paste('Adjustment Method Error: method', test, 
                                       "is not supported for callS5Adjustment. Please check your input.")))
  }
  return(adjusted.list)
}

