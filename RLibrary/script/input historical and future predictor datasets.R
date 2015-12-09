
# assume multiple predictors, but all with identical lat/long/time sequence
# assume historical and future are seperate files ... for now
# assume pred.vars and nc files are in JSON as 'list', so index, 1,2,...,n vars
# applies spatial masks to all datasets if condition=T

for (i in 1:length(rp$predictor.vars)){
  message("Obtaining Coarse Historical data (predictor)")
  print(paste("predictor: ", rp$predictor.vars[i], sep='')) 
  p.var <- rp$predictor.vars[i]

  #Obtain coarse GCM data
  #assume nc files names are in a list
  tmp.dir <- paste(ROOT,rp$data.dir,sep='')
  filename <- paste(tmp.dir, rp$hist.predictor.file[[i]], sep='')
  
  if(i==1){
    # create time vector from the dataset as POSIXct R vector
    # fxn requires packages 'RNetCDF' and 'ncdf.tools' 
    # "Some Unix-like systems (especially Linux ones) do not have environment variable TZ set, 
    # yet have internal code that expects it (as does POSIX). We have tried to work around this, 
    # but if you get unexpected results try setting TZ. See Sys.timezone for valid settings."
    hist.time.vector <- convertDateNcdf2R(open.nc(filename))
  } 
  
  nc.object <- nc_open(filename) 
  tmp.hist <- ReadNC(nc.object, var.name=p.var)
  if(rp$apply.spat.mask){
    message(paste('Applying spatial mask to historical predictor data for var: ', p.var, sep=''))
    tmp.hist$clim.in <- applySpatialMask(tmp.hist$clim.in, spat.mask$masks[[1]])
  }
  if(rp$apply.temporal.mask){
    message(paste("Applying temporal mask to historical predictor data for var: ", p.var, sep=''))
    tmp.mask <- paste('temporal.mask.', rp$temporal.mask.list[[2]],'$masks[[1]]', sep='')
    tmp.hist$clim.in <- applyTemporalMask(tmp.hist$clim.in, tmp.mask)
    rm(tmp.mask)
  }
  assign(paste('list.hist.', p.var, sep=''), tmp.hist)
  #assign(paste('list.hist.', i, sep=''), tmp.hist)
  #assign(paste(p.var,'1',sep=''), tmp.hist)
  # dimension of climate dataset
  dims.hist <- dim(tmp.hist$clim.in)
  rm(filename, tmp.dir, tmp.hist, nc.object)

  message(paste("Obtaining future predictor dataset for var:", p.var))
  tmp.dir <- paste(ROOT,rp$data.dir,sep='')
  filename <- paste(tmp.dir, rp$fut.predictor.file[[i]], sep='')
  if(i==1){
    fut.time.vector <- convertDateNcdf2R(open.nc(filename))
  }
  nc.object <- nc_open(filename) 
  tmp.fut <- ReadNC(nc.object, var.name=p.var, dim='temporal')
  if(rp$apply.spat.mask){
    message(paste("Applying spatial mask to future predictor data for var: ", p.var, sep=''))
    tmp.fut$clim.in <- applySpatialMask(tmp.fut$clim.in, spat.mask$masks[[1]])
  }
  if(rp$apply.temporal.mask){
    message(paste("Applying temporal mask to future predictor data for var: ", p.var, sep=''))
    tmp.mask <- paste('temporal.mask.', rp$temporal.mask.list[[3]],'$masks[[1]]', sep='')
    tmp.fut$clim.in <- applyTemporalMask(tmp.fut$clim.in, tmp.mask)
    rm(tmp.mask)
  }
  assign(paste('list.fut.', p.var, sep=''), tmp.fut)
  #assign(paste('list.fut.', i, sep=''), tmp.fut)
  #assign(paste(p.var,'2',sep=''), tmp.fut)
  # dimension of climate dataset
  dims.fut <- dim(tmp.fut$clim.in)
  rm(filename, tmp.dir, tmp.fut, nc.object, p.var)
}
rm(i)

# Output passed to MAIN program:
#   R objects 'list.hist.var[i]' and 'list.fut.var[i]'
#   Attributes: 3D list
# 
# END 