

callSBCorr <- function(){
  # Outputs a mask where NA values show flagged data and 1's show good data
  # Set corrective error factor:
  print("entering section 5 simple bias correction func")
  # Creates a bias QC mask and sets up a bias correction for use later
  if(rp$S5.SBiasCorr){
    botlim <- rp$SBCorr.args[1]
    toplim <- rp$SBCorr.args[2]
  }else{
    stop("Section 5 Adjustment Error: Arguments toplim and botlim are not present for the SBiasCorr function")
  }
  for(i in 1:length(rp$predictor.vars)){
    if(rp$predictor.vars[[i]]==rp$target.var){
      hist.pred <- get(paste0("list.hist.",rp$predictor.vars[[1]]))
      hist.pred <- hist.pred$clim.in
      hist.targ <- list.target$clim.in
      fut.pred <- get(paste0("list.fut.",rp$predictor.vars[[i]]))
      fut.pred <- fut.pred$clim.in
    }
  }
  # bring in downscaled data
  adjust.ds <- ds.out
  # collaps downscaled array to [i,j,time]    
  adjust.ds.single <- apply(adjust.ds, c(1:3), mean, na.rm=TRUE)
  # crude check
  mean(adjust.ds.single, na.rm=T)
  mean(adjust.ds, na.rm=T)
  # initialize objects
  hist.dim<-dim(hist.targ)
  fut.dim<-dim(fut.pred)
  hist.bias<-array(NA,dim=hist.dim[1:2])
  fut.adj<-array(NA,dim=fut.dim)
  mask.vec<-array(NA,dim=fut.dim)
  out.list<-NA
  # assumption that all data sets have same lat/lon dimensions
  for (i in 1:dim(hist.targ)[1]){
    for (j in 1:dim(hist.targ)[2]){     
      # compute mean difference across all time values
      hist.bias[i,j] <- mean(hist.pred[i,j,]-hist.targ[i,j,])
      fut.adj[i,j,] <- fut.pred[i,j,]-hist.bias[i,j]
      mask.vec[i,j,] <- ifelse((botlim <= (adjust.ds.single[i,j,]-fut.adj[i,j,]) &
                              (adjust.ds.single[i,j,]-fut.adj[i,j,]) < toplim), 
                               yes=1, no=NA)
    }
  }
  qc.mask <- list(mask.vec)
  bias.corrected <- sum(is.na(mask.vec))
  total.cells <- sum(!is.na(mask.vec)) + sum(is.na(mask.vec))
  print(paste("Bias correction applied to ",bias.corrected," cells"))
  print(paste("out of  ",total.cells," cells"))
  # Does bias correction to downscaled data if option [3] = TRUE
  if(rp$SBCorr.args[3]==TRUE){
    adjust.vec <- ifelse((is.na(mask.vec)), yes=fut.adj, no=adjust.ds.single)
  }
  mean(adjust.ds.single,na.rm=T)
  mean(adjust.vec,na.rm=T)  
  # Now, expand the 3D array adjusted.ds.single -->> the original 5D array
  # Doing it this way preserves the original Windows and Kfold array indicies for non-NA values
  full.dims <- dim(ds.out)
  tmp.q<-NULL
  for(i in 1:length(window.masks)){
    tmp.q[i] <- list(adjust.vec)
  }
  tmp.q1 <- abind(tmp.q,rev.along=0)
  dim(tmp.q1)
  tmp.q2<-NULL
  for(i in 1:length(kfold.masks)){
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
  dim(adjust.ds)
  dim(tmp.q3)
  az <- mapply(revert,adjust.ds,tmp.q3,SIMPLIFY=TRUE)  
  az <- unlist(az)
  az <- array(az,dim=full.dims)
  # add dimnames
  dimnames(az)<-list(i.name,j.name,t.name,w.name,k.name)
  mean(adjust.ds, na.rm=T)
  mean(az,na.rm=T)
  out.S5 <- list("out.S5"=az,"qc.mask"=qc.mask)
  return(out.S5)
}
