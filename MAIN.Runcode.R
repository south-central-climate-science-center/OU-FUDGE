# MAIN_Runcode.R
# Written by D.Wilson, University of Oklahoma, Oct 2015
#
# This is the main R script to run FUDGE
# This script is wholey contained in that it will read the XML run parameters file,
# then proceed with the entire statistical downscaling steps for a single climate variable. 
#


#--------------------------------------------------------------------#
# Section R-INVOCATION
#
# Section captures arguments from the command line at R invocation.
# Arguments are captured as an R "list" of character strings.
# These arguments could be:
#   1. HPC specific, e.g., directory paths
#   2. HPC job specific, e.g., which lat/long's to process on this core  
#
# This section allows tailoring code to specific HPCC environments
# without rewriting the base R scripts. It does assume an HPCC environment, 
# not a single workstation.
# 
# Most job-specific information will be auto-generated in the "bash" script 
# that generates the HPC jobs. Right now, instructions for how these are 
# generated are part of the XML run parameters file.
#

print(Sys.info()["sysname"])

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

# these are specific to the coordinate system in the netCDF files
# perfect model data are 0.25 deg lat grid, but variable lon grid (approx 0.31 deg in Oklahoma)
# On a PC you only run one job, so here decide which i,j index section to run 
# start.clip is (lon-index-start, lat-index-start, time-start)
# perfect model data are [194,114,] dimension

if(Sys.info()["sysname"]=='Windows'){
  # on a PC, do one section at a time
  start.clip <- c(100,55,1)
  # counts [1:2] must be > 1 ... for now. 
  # counts are number of grid cells for i,j and time (time=-1 means run all cells)
  count.clip <- c(10,15,-1)
  job<-1  
}
if(Sys.info()["sysname"]=='Linux'){
  console.args <- commandArgs(TRUE)
  print(console.args)
  # i is longitude index in the netCDF file, j is latitude
  i.lower <- as.numeric(console.args[1])
  i.count <- as.numeric(console.args[2])
  j.lower <- as.numeric(console.args[3])
  j.count <- as.numeric(console.args[4])
  # perfect model is [194,114,]
  start.clip <- c(i.lower,1,1)
  count.clip <- c(i.count,114,-1)
  if(start.clip[1]==1){ job<-1
  }else{
    job<-0
  }
}
  

#--------------------------------------------------------------------#
# Section 
# Reads JSON file created with all run parameters
# Returns list 'rp'
#

library(jsonlite)
json.file <- paste0(ROOT,"runfile.json")
# reads JSON format file and returns as list
rp <- fromJSON(json.file, simplifyVector=TRUE) 
# echo variable names
names(rp)
rm(json.file)


#--------------------------------------------------------------------#
# Section 
# Load common functions and packages
#
# Load functions common to all DS methods
# Only allow functions within these directories
sapply(list.files(pattern="[.]R$", path=paste(ROOT, rp$common.lib, sep=''), full.names=TRUE), source);
# Load DS specific function
sapply(list.files(pattern="[.]R$",path=paste(ROOT,rp$ds.lib,rp$ds.method,'/',sep=''), full.names=TRUE), source);
# Load packages common to all DS methods
LoadLib()


#--------------------------------------------------------------------#
# Section 
# Initiate error handling for the run
# File: "./script/trace_errors.R"
message(paste('Initiate error handling for the run', sep=''))
source(paste(ROOT,rp$script.lib,'trace.errors.R',sep=''))


#--------------------------------------------------------------------#
# Section 
# Read in spatial mask
# File: ".//.R"
#
if(rp$apply.spat.mask){
  source(paste(ROOT, rp$script.lib, 'input.spatial.mask.clipped.R', sep=''))
}


#--------------------------------------------------------------------#
# Section MAIN.X.1
# Read in temporal masks
# File: ".//.R"
#
if(rp$apply.temporal.mask){
  source(paste(ROOT, rp$script.lib, 'input.temporal.masks.R', sep=''))  
}
if(rp$create.temporal.mask){
  # add simple source or function to read in temporal masks as functions for use later
}

                          
#--------------------------------------------------------------------#
# Section 
# Input historical target dataset
# Also 'mask' dataset with spatial masks
# File: "./script/input historical target dataset.R"
#
source(paste(ROOT, rp$script.lib,'input historical target dataset.clipped.R', sep=''))


#--------------------------------------------------------------------#
# Section 
# Input historical and future predictor datasets
# Also 'mask' dataset with spatial masks
# File: "./script/input historical and future predictor datasets.R"
#
source(paste(ROOT, rp$script.lib, 'input historical and future predictor datasets.clipped.R', sep=''))


#--------------------------------------------------------------------#
# Section 
# Primary downscaling loop: 
# File: ".//.R"
#
source(paste(ROOT, rp$script.lib,'primary.DS.loop.R',sep=''))

#--------------------------------------------------------------------#
# Section 
# save window and kfold masks to binary R files
# these are used in the final R script step
# only the first HPC job does this
if(job==1){
  if(rp$create.window.mask | rp$supply.window.mask){
    save(window.masks, file="window.masks.Rdata")  
  }
  if(rp$create.kfold.mask | rp$supply.kfold.mask){
    save(kfold.masks, file="kfold.masks.Rdata")  
  }  
}


#--------------------------------------------------------------------#
# End of downscaling run
# Write output to scratch
# Output for each HPC job are binary R files (".RData")

# rename the DS output array dimensions to the section completed by this HPC job
if(rp$create.ds.output){
  message(paste('Final Downscaled output file location: ', WORKROOT, sep=""))
  message("renaming DS output array to regional coordinates")
  # get length and dims in the original input source
  i.name <- seq(start.clip[1],start.clip[1]+count.clip[1]-1)
  j.name <- seq(start.clip[2],start.clip[2]+count.clip[2]-1)
  dimnames(ds.out)[1:2] <- list(i.name,j.name)

# write DS array to binary R object file
# file name is dynamic based on job (section of area to DS)
file.DS <- paste0("ds.out.",i.name[1],".",i.name[length(i.name)],".",j.name[1],".",j.name[length(j.name)],".Rdata")
print(file.DS)
save(ds.out, file=file.DS)

# fit or summary statistics as a data frame ... each DS method has unique output
# write DS fit summary list to binary R object file
# file name is dynamic based on job (section of area to DS)
if(rp$create.fit.output){
  file.fit <- paste0("fit.summary.",i.name[1],".",i.name[length(i.name)],".",j.name[1],".",j.name[length(j.name)],".Rdata")
  print(file.fit)
  save(fit.summary, file=file.fit)  
}
}else{
  message("Job completed, but will produce no downscale output")
}

# END of file
