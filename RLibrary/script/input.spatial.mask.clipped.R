# Spatial mask input & checking
# assume only a single spatial mask

message("Checking for spatial masks")
if(rp$apply.spat.mask){
  tmp.dir <- paste(ROOT,rp$data.dir,sep='')
  filename <- paste(tmp.dir, rp$spat.mask.file, sep='')
  message(paste('Obtaining spatial mask: ', filename, sep=''))
  # spatial masks are only 2D arrays [lon,lat]
  start.spat.clip <- start.clip[1:2]
  count.spat.clip <- count.clip[1:2]
  nc.object = nc_open(filename) 
  spat.mask <- ReadMaskNC(nc.object, dstart=start.spat.clip, dcount=count.spat.clip) 
  message(paste("Read spatial mask:", rp$spat.mask.file))
  rm(filename, tmp.dir, nc.object)
}else{
  spat.mask <- NULL
  message("no spatial mask included")
}


# Output passed to MAIN program:
#   R object 'spat.mask'
#   Attributes: 3D list
# 
# END

