# Final.Runcode.R
# Written by D.Wilson, University of Oklahoma, Dec 2015
#
# This is the final of three R runcodes needed to run FUDGE
# This script reads in downscaled output from individual HPC jobs and stitches these together into 
# a standard array.
#
# Options are included to save this R array, or write to a netCDF file format
# 
# Further options are to stitch fit statistics and fit parameters together and save as R object or csv file. 
# This option not written yet ...
#
choose.OS <- function(x){ 
  return(if(x=="Windows") drive <- c("C:/FUDGE/","C:/FUDGE/DATA/","C:/FUDGE/SCRATCH/") 
         else if(x=="Linux") drive <- c("/home/dwilson/OU-FUDGE/","/scratch/dwilson/DATA/","/scratch/dwilson/"))
}
drive <- choose.OS(Sys.info()["sysname"])
ROOT <- drive[1]
DATAROOT <- drive[2]
WORKROOT <- drive[3]
setwd(WORKROOT)
getwd()

# Read in runfile parameters
library(jsonlite)
json.file <- paste0(ROOT,"runfile.json")
# reads JSON format file and returns as list
rp <- fromJSON(json.file, simplifyVector=TRUE) 
# echo variable names
names(rp)
rm(json.file)

# Read in common functions
sapply(list.files(pattern="[.]R$", path=paste(ROOT, rp$common.lib, sep=''), full.names=TRUE), source);
# Load packages needed for this final R script
LoadLib()

# Read in window and kfold masks
if(rp$create.window.mask | rp$supply.window.mask){
  load("window.masks.Rdata")
}else{
  window.masks <- NA
}
if(rp$create.kfold.mask | rp$supply.kfold.mask){
  load("kfold.masks.Rdata")  
}else{
  kfold.masks <- NA
}

# Read in future GCM data to extract dimensions
# This is impossibly large if the data file is global ... 
# It is fine for "Perfect Model" data
source(paste(ROOT, rp$script.lib, 'input future predictor dataset.single.R', sep=''))

# Create downscale results array
# Has dims(lon-index,lat-index,time,windows,kfold)
# Filling array with NA's to be overwritten by DS results

message("Creating empty DS output array")
# get length and dims in the original input source
i.name <- seq(1,dims.fut[1])
j.name <- seq(1,dims.fut[2])
t.name <- seq(1,dims.fut[3])
w.name <- window.masks
k.name <- kfold.masks
ds.out.full <- array(NA,
                     dim=c(dims.fut[1],
                           dims.fut[2],
                           dims.fut[3],
                           length(window.masks),
                           length(kfold.masks)), 
                     dimnames=list(i.name,j.name,t.name,w.name,k.name))
message("DS output array has dimensions")
cat(dim(ds.out.full))
message("with order [lon,lat,time,window,kfold]")
message("Windows:")
print(dimnames(ds.out.full)[4])
message("k-folds:")
print(dimnames(ds.out.full)[5])

# sequentially read in the chunked DS output files & fill the array 
tmp.files <- list.files(pattern="ds.out", path=paste(WORKROOT))
for(i in 1:length(tmp.files)){
  load(tmp.files[i])
  message(paste("loaded file ", tmp.files[i]))
  # insert downscale results into the array
  # DS output "ds.predict" is matched by dimnames to "ds.out"
  afill(ds.out.full) <- ds.out 
  rm(ds.out)
}

# Write full array to binary R file
file.DS <- "finalDSoutput.Rdata"
print(file.DS)
save(ds.out.full, file=file.DS)  


# --------------------------------------------------------------------------- #
# Wite output to a netCDF file
#
if(rp$create.ds.output){
  
  # First need to collapse windows and kfold to a single column
  # Assumes no overlapping dates within windows or kfolds
  # This is really awkward but fine to do, ONLY if the kfolds are either 'NA' or non-overlapping
  # The windows must also be 'NA' or non-overlapping
  # if kfolds duplicate data (e.g., folds are random subsets), then this is not allowed
  # otherwise this returns the mean of the non-overlapping data across windows and kfolds
  # This operation takes awhile to run for perfect model area (20 min+) & is a large memory job (20GB)
  ds.out.single <- apply(ds.out.full, c(1:3), mean, na.rm=TRUE)
  # crude check
  mean(ds.out.single, na.rm=T)
  mean(ds.out.full, na.rm=T)
  
  # this section will need to be rewritten to better match "writeNC" in the original FUDGE code
  # quick and dirty approach here, I simply copy the future GCM netCDF file and overwrite values with 
  # downscaled output.
  # Many assumptions as to similarity of these files (units, dims, etc) ...
  # This is for testing results against GFDL-FUDGE only
  for (i in 1:length(rp$predictor.vars)){
    if(rp$predictor.vars[[i]]==rp$target.var){
      print(paste("predictor: ", rp$predictor.vars[i], sep='')) 
      file.copy(paste(DATAROOT,rp$fut.predictor.file[[i]],sep=''),"tmp.nc",overwrite=TRUE) 
    }
  }  
  message("Creating empty DS output array")
  ds.out.NA <- array(1.e20,
                       dim=c(dims.fut[1],
                             dims.fut[2],
                             dims.fut[3]),
                       dimnames=list(i.name,j.name,t.name))
  nc.obj <- nc_open("tmp.nc", write=TRUE)
  message("writing nc vars to file: tmp.nc")
  # first, fill wih NA values (as out of bounds vals)
  ncvar_put(nc.obj, p.var, ds.out.NA)
  # now write downscale results
  ncvar_put(nc.obj, p.var, ds.out.single)
  # Now write over global attributes for safety sake
  global<-ncatt_get(nc.obj,0)
  for(i in 1:length(global)){
    ncatt_put(nc.obj,0,names(global[i]),"NA")  
  }
  nc_close(nc.obj)
}

