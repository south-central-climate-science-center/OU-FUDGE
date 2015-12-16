
# assume multiple predictors, but all with identical lat/long/time sequence
# assume historical and future are seperate files ... for now
# assume pred.vars and nc files are in JSON as 'list', so index, 1,2,...,n vars
# applies spatial masks to all datasets if condition=T

message("Obtaining Coarse Historical data (predictor)")
for (i in 1:length(rp$predictor.vars)){
  if(rp$predictor.vars[[i]]==rp$target.var){
    print(paste("predictor: ", rp$predictor.vars[i], sep='')) 
    p.var <- rp$predictor.vars[i]
    
    message(paste("Obtaining future predictor dataset for var:", p.var))
    tmp.dir <- paste(DATAROOT,rp$data.dir,sep='')
    filename <- paste(tmp.dir, rp$fut.predictor.file[[i]], sep='')
    nc.object <- nc_open(filename) 
    tmp.fut <- ReadNC(nc.object, var.name=p.var, dim='temporal')
    assign(paste('list.fut.', p.var, sep=''), tmp.fut)
    dims.fut <- dim(tmp.fut$clim.in)
    #rm(filename, tmp.dir, tmp.fut, nc.object, p.var)   
    rm(nc.object)   
  }  
}
rm(i)

# Output passed to MAIN program:
#   R objects 'list.hist.var[i]' and 'list.fut.var[i]'
#   Attributes: 3D list
# 
# END 