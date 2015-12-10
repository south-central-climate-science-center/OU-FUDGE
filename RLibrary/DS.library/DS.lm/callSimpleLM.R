 


callDS <- function(target=NA,df.hist=NA,df.fut=NA){

  fitting.formula <- as.formula(rp$LM.formula) 
  if(rp$transform.target){ 
    # if variable transformation is needed on the target (e.g., log(tasmax)), do it here
    # need to add JSON option here as, 'target <- log(target)' ...
  }
  attach(df.hist)
  fit.lm <- lm(fitting.formula)
  detach(df.hist)
  attach(df.fut)
  ds.predict <- predict(fit.lm, df.fut)
  detach(df.fut)
  # add dimensions and name these
  # this step is necessary to 'abind' these output into the fuller DS output array
  dim(ds.predict) <- c(1,1,length(ds.predict),1,1)
  t.name <- seq(1,dims.fut[3])
  dimnames(ds.predict) <- list(i.index, j.index, t.name, w.name[[window]], k.name[[kfold]])
  # These are lm fit parameters
  # Add parameters and fit statistics here as needed
  df.fit <- data.frame(i.index,j.index,w.name[[window]],k.name[[kfold]],fit.lm$coefficients,
                       names(fit.lm$coefficients))
  rownames(df.fit)<-NULL
  return(list("ds.predict"=ds.predict, "df.fit"=df.fit))
}
