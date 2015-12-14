# Assumption of single target variable

message(paste("Reading in historical target data for variable: ", rp$target.var, sep=''))
tmp.dir <- DATAROOT
filename <- paste(tmp.dir, rp$hist.target.file, sep='')
message(paste("Reading in historical target data: ", filename, sep=''))

# read in primary climate target dataset
nc.object <- nc_open(filename)
list.target <- ReadNC(nc.object, var.name=rp$target.var, dim="spatial")
 
if(rp$apply.spat.mask){
  message(paste('Applying spatial mask to historical target data: ', filename))
  list.target$clim.in <- applySpatialMask(list.target$clim.in, spat.mask$masks[[1]])
}else{
  message('No spatial mask')
}
if(rp$apply.temporal.mask){
  message('Applying temporal mask to historical target data')
  tmp.mask <- paste('temporal.mask.', rp$temporal.mask.list[[1]],'$masks[[1]]', sep='')
  list.target$clim.in <- applyTemporalMask(list.target$clim.in, tmp.mask)
  rm(tmp.mask)
}else{
  message('There was no temporal mask')
}
# note, ReadNC fxn runs nc_close
rm(filename, nc.object, tmp.dir)

# Output passed to MAIN program:
#   R object 'list.target'
#   Attributes: 3D list
# 
# END 

if(clipToBox){
  message("Clipping to bounding box")
  
}else{
  message('There was no clipping to bounding box')
}

