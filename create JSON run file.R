# This R job creates the run parameter file that controlls the entire DS job

# Create JSON script
#install.packages("jsonlite")
library(jsonlite)

choose.OS <- function(x){ 
  return(if(x=="Windows") drive <- c("C:/FUDGE/","C:/FUDGE/DATA/","C:/FUDGE/SCRATCH/") 
         else if(x=="Linux") drive <- c("/home/dwilson/","/scratch/dwilson/DATA/","/scratch/dwilson/"))
}
drive <- choose.OS(Sys.info()["sysname"])
ROOT <- drive[1]

stuff <- list(

  common.lib = 'RLibrary/common.functions/',
  ds.lib = 'RLibrary/DS.library/',
  script.lib = 'RLibrary/script/',
  
  # options are: 'DS.lm', or 'DS.EDQMv2'
  ds.method = 'DS.EDQMv2',
  # this option = TRUE only if you want to create a netCDF file
  # Only set = TRUE is there are no k-folds
  create.ds.output=TRUE,
  # Option not working yet ...
  create.fit.output=TRUE,
  
  #--------------predictor and target variable names--------#
  target.var = 'tasmax',
  # first predictor var must be same as target
  predictor.vars = c('tasmax', 'pr', 'tasmin'), 

  hist.target.file = 'tasmax_day_GFDL-HIRAM-C360_amip_r1i1p1_US48_19790101-20081231.nc',
  hist.predictor.file = c(
    'tasmax_day_GFDL-HIRAM-C360-COARSENED_amip_r1i1p1_US48_19790101-20081231.nc',
    'pr_day_GFDL-HIRAM-C360-COARSENED_amip_r1i1p1_US48_19790101-20081231.nc',
    'tasmin_day_GFDL-HIRAM-C360-COARSENED_amip_r1i1p1_US48_19790101-20081231.nc'),
  fut.predictor.file = c(
    'tasmax_day_GFDL-HIRAM-C360-COARSENED_sst2090_r1i1p1_US48_20860101-20951231.nc',
    'pr_day_GFDL-HIRAM-C360-COARSENED_sst2090_r1i1p1_US48_20860101-20951231.nc',
    'tasmin_day_GFDL-HIRAM-C360-COARSENED_sst2090_r1i1p1_US48_20860101-20951231.nc'),
  
  apply.spat.mask = TRUE,
  spat.mask.file = 'interior3pt_masks.nc',
  
  apply.temporal.mask = FALSE,
  create.temporal.mask = FALSE,
  # enforce these must be in this order. These must be 4 items in the list, these can all be identical, NULL is ok
  temporal.mask.file = c(NULL),
  # this list is static, based on the order of the temporal mask input file list
  temporal.mask.list = c('hist.target','hist.pred','fut.pred','fut.target'),
  
  # window masks can be created and/or supplied
  create.window.mask = TRUE,
  supply.window.mask = FALSE,
  # this can be NULL, 
  window.mask.files = c(NULL),
    
  # k-fold validation masks can be created and/or supplied
  create.kfold.mask = FALSE,
  supply.kfold.mask = FALSE,
  # this can be NULL, 
  kfold.mask.files = c(NULL),  
  
  # S3 adjustments
  apply.S3.outer = FALSE,
  
  # list of instructions and their order of application
  # list must be tied to the CF variable
  s3.outer.list = c('PR'),
  # option threshold: 'us_trace' (0.01 in/day), 'global_trace' (0.1 mm/day), 'zero', or user-supplied value
  pr.adj.args.outer=c("threshold"='us_trace',
                      "lopt.drizzle"=TRUE,
                      "lopt.conserve"=TRUE,
                      "apply.0.mask"=FALSE),
  
  # S5 adjustments
  apply.S5.outer = TRUE,
  s5.outer.list = c('SBiasCorr'),
  apply.S5.wetday.mask = FALSE,
  # option produces a QC mask & sets up the bias correction
  S5.SBiasCorr = TRUE,
  # bias correction options (lower limit, upper limit, do bias correction (T/F))
  SBCorr.args=c(-6,6,TRUE),

  apply.S3.inner = FALSE,
  s3.inner.list = c(NULL),
  
  apply.S5.inner = FALSE,
  s5.inner.list = c(NULL),
  
  LM.formula = 'target ~ tasmax + log(tasmin) + pr',
  transform.target = FALSE,
  transform.function = NA
)  

# package jsonlite
run.parms <- toJSON(stuff, auto_unbox=TRUE, pretty=4)
validate(run.parms)
run.parms
write(run.parms, paste0(ROOT,"runfile.json"))



