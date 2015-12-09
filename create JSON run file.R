# This R job creates the run parameter file that controlls the entire DS job

# Create JSON script
#install.packages("jsonlite")
library(jsonlite)

stuff <- list(

  data.dir = 'DATA/',
  work.dir = 'WORK/',
  common.lib = 'RLibrary/common.functions/',
  ds.lib = 'RLibrary/DS.Library/DS.EDQMv2/',
  script.lib = 'RLibrary/script/',
  
  # options are: 'lm', or 'EDQMv2'
  ds.method = 'EDQMv2',
  create.ds.output=TRUE,
  create.fit.output=TRUE,
  
  #--------------predictor and target variable names--------#
  target.var = 'tasmax',
  predictor.vars = c('tasmax', 'pr', 'tasmin'), 
  time.step = 'day',
  calendar = 'Gregorian',
  
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
  # list of instructions and the order
  # list must be tied to the CF variable
  s3.outer.list = c('PR'),
  # option threshold: 'us_trace' (0.01 in/day), 'global_trace' (0.1 mm/day), 'zero', or user-supplied value
  pr.adj.args.outer=c(threshold='us_trace',
                      lopt.drizzle=TRUE,
                      lopt.conserve=TRUE,
                      apply.0.mask=FALSE),
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
write(run.parms, "c:/FUDGE/runfile.json")



