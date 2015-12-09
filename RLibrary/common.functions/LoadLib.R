# Function to load common and DS method specific libraries
# automatically throws an error if libraries are not available 

LoadLib <- function(){
  # Load common libraries and those based on the DS method used
  # ncdf4 is common to all methods as datasets used in FUDGE are netCDF only at this time.
  library(ncdf4)
  library(PCICt)
  library(udunits2)
  library(ncdf4.helpers)
  library(RNetCDF)
  library(ncdf.tools)
  library(abind)
  if(rp$ds.method=='CDFt'){
    print("Importing CDFt library")       
    library(CDFt)
  }else{
    print("No method-specfic libraries required")  
  }
}  