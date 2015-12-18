


callDS<-function(target=NA,df.hist=NA,df.fut=NA){ 
  #'Performs an equidistant correction adjustment
  # LH: Local Historical (a.k.a. observations)
  # CH: Coarse Historical (a.k.a. GCM historical)
  # CF: Coarse Future (a.k.a GCM future)
  #'Cites Li et. al. 2010
  #' Calls latest version of the EDQM function
  #' as of 12-29
  lengthCF<-length(df.fut[[1]])
  lengthCH<-length(df.hist[[1]])
  #lengthLH<-length(target)
  
  CF.dim <- lengthCF
  CH.dim <- lengthCH
  
  
  # initialize data.frame
  temp<-data.frame(index=seq(1,CF.dim),CF=rep(NA,CF.dim))
  df<-data.frame(index=seq(1,CH.dim),CH=rep(NA,CH.dim),LH=rep(NA,CH.dim))
  temp$CF<-df.fut[[1]]
  df$CH<-df.hist[[1]]
  df$LH<-target
  
  temp<-temp[order(temp$CF),]
  # drop NA's due to windowing and/or kfold masking
  temp <- na.omit(temp)
  # define vector with probabilities [0,1] -- this has length of non-NA values
  prob<-seq(0.001,0.999,length.out=length(temp$CF))
  temp$qLHecdfCFqCF<-quantile(df$LH,ecdf(temp$CF)(quantile(temp$CF,prob,na.rm =TRUE)),na.rm =TRUE)
  temp$qCHecdfCFqCF<-quantile(df$CH,ecdf(temp$CF)(quantile(temp$CF,prob,na.rm =TRUE)),na.rm =TRUE)
  # EQUIDISTANT CDF (Li et al. 2010)
  temp$EquiDistant<-temp$CF + temp$qLHecdfCFqCF - temp$qCHecdfCFqCF
  # merge back into full data frame to preserve time order
  temp<-temp[order(temp$index),]
  full.tmp <- data.frame(index=seq(1,CF.dim),CF=rep(NA,CF.dim))
  full <- merge(full.tmp, temp, by.x="index", by.y="index", all=T)
  full$CF <- full$CF.y
  full$CF.x <- NULL
  full$CF.y <- NULL
  ds.predict <- full$EquiDistant
  
  # add dimensions and name these
  # this step is necessary to 'abind' these output into the fuller DS output array
  dim(ds.predict) <- c(1,1,length(ds.predict),1,1)
  t.name <- seq(1,dims.fut[3])
  dimnames(ds.predict) <- list(i.index, j.index, t.name, w.name[[window]], k.name[[kfold]])
  # These are EDQM fit parameters
  # grabbing the summary() of CH, LH, CF and downscaled CF
  # first 4 moments would be good also, but simple use require the "moments" package
  # put these into a data frame 'df.fit' and index this with [i,j,window,kfold]
  # Add other parameters and fit statistics here as needed
  acf <- quantile(full$CF,na.rm=T)
  aeq <- quantile(full$EquiDistant,na.rm=T)
  alh <- quantile(df$LH,na.rm=T)
  ach <- quantile(df$CH,na.rm=T)
  # All statistics on a single row right now, change format as needed
  df.fit <- data.frame(i.index,j.index,w.name[[window]],k.name[[kfold]],
                       acf[1],acf[2],acf[3],acf[4],acf[5],median(full$CF,na.rm=T),
                       aeq[1],aeq[2],aeq[3],aeq[4],aeq[5],median(full$EquiDistant,na.rm=T),
                       alh[1],alh[2],alh[3],alh[4],alh[5],median(df$LH,na.rm=T),
                       ach[1],ach[2],ach[3],ach[4],ach[5],median(df$CH,na.rm=T))
  colnames(df.fit)[5:10]<-c("CF.0%","CF.25%","CF.50%","CF.75%","CF.100%","CF.median")
  colnames(df.fit)[11:16]<-c("CFEQ.0%","CFEQ.25%","CFEQ.50%","CFEQ.75%","CFEQ.100%","CF.median")
  colnames(df.fit)[17:22]<-c("LH.0%","LH.25%","LH.50%","LH.75%","LH.100%","LH.median")
  colnames(df.fit)[23:28]<-c("CH.0%","CH.25%","CH.50%","CH.75%","CH.100%","CH.median")
  rownames(df.fit)<-NULL
  return(list("ds.predict"=ds.predict, "df.fit"=df.fit))

}
