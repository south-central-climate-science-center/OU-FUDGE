# Create JSON script
#install.packages("jsonlite")
library(jsonlite)

stuff <- list(

  data.dir = '/scratch/dwilson/',
  work.dir = '/scratch/dwilson/',
  common.lib = '/home/dwilson/FUDGE/RLibrary/common.functions/',
  ds.lib = '/home/dwilson/FUDGE/RLibrary/DS.Library/DS.lm/',
  script.lib = '/home/dwilson/FUDGE/RLibrary/script/',
  
  ds.method = 'lm',
  create.ds.output=TRUE,
  
  #--------------predictor and target variable names--------#
  target.var = 'pr',
  predictor.vars = c('tasmax', 'pr', 'tasmin'), 
  time.step = 'day',
  calendar = 'Gregorian',
  
  hist.target.file = 'pr_day_GFDL-HIRAM-C360_amip_r1i1p1_US48_19790101-20081231.nc',
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
  apply.S3.outer = TRUE,
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
write(run.parms, "c:/FUDGE/work/runfile.HPC.json")



  
#--------------predictor and target variable names--------#
predictor.vars = c('tasmax', 'pr', 'tasmin'), 
target.var = 'tasmax',
#--------------grid region, mask settings----------#
grid = 'SCCSC0p1', 
spat.mask.dir_1 = '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/geomasks/red_river_0p1/OneD/', 
spat.mask.var = 'red_river_0p1_masks', 
ds.region = 'RR',
#--------------- I,J settings ----------------#
file.j.range = 'J31-170', 
i.file = 300,   
j.start = 31, 
j.end = 170,
#------------ historical predictor(s)----------# 
hist.file.start.year_1 = 1961, 
hist.file.end.year_1 = 2005,
hist.train.start.year_1 = 1961,
hist.train.end.year_1 = 2005, 
hist.scenario_1 = 'historical_r1i1p1',
hist.model_1 = 'MPI-ESM-LR', 
hist.freq_1 = 'day', 
hist.indir_1 = '/archive/esd/PROJECTS/DOWNSCALING///GCM_DATA/CMIP5//MPI-ESM-LR/historical//atmos/day/r1i1p1/v20111006/tasmax/SCCSC0p1/OneD/', 
hist.time.window = '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_bymonth_19610101-20051231.nc', 
#------------ future predictor(s) -------------# 
fut.file.start.year_1 = 2006, 
fut.file.end.year_1 = 2099, 
fut.train.start.year_1 = 2006, 
fut.train.end.year_1 = 2099, 
fut.scenario_1 = 'rcp85_r1i1p1',
fut.model_1 = 'MPI-ESM-LR', 
fut.freq_1 = 'day', 
fut.indir_1 = '/archive/esd/PROJECTS/DOWNSCALING///GCM_DATA/CMIP5//MPI-ESM-LR/rcp85//atmos/day/r1i1p1/v20111014/tasmax/SCCSC0p1/OneD/',
fut.time.window = '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_bymonth_20060101-20991231.nc',
fut.time.trim.mask = 'na',
#------------- target -------------------------# 
target.file.start.year_1 = 1961, 
target.file.end.year_1 = 2005, 
target.train.start.year_1 = 1961, 
target.train.end.year_1 = 2005, 
target.scenario_1 = 'historical_r0i0p0',
target.model_1 = 'livneh',
target.freq_1 = 'day', 
target.indir_1 = '/archive/esd/PROJECTS/DOWNSCALING///OBS_DATA/GRIDDED_OBS//livneh/historical//atmos/day/r0i0p0/v1p2/tasmax/SCCSC0p1/OneD/',
target.time.window = '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_bymonth_19610101-20051231.nc',
#------------- method name k-fold specs-----------------------#
ds.method = 'CDFt', 
ds.experiment = 's5-opts-RRtxp1-CDFt-A38af-mL01K00', 
k.fold = 0, 
#-------------- output -----------------------#
output.dir = '/home/cew/Code/testing/',
mask.output.dir = '/home/cew/Code/testing/QCMask/', 
#-------------  custom -----------------------#
mask.list = 'na')







library(jsonlite)
json.file <- file.path("C:","Fudge","work", "runfile.json")
# checks for existence of "runfile.json" and for errors in JSON file
if(file.exists(json.file)) {
  run.parms <- fromJSON(json.file, simplifyVector=TRUE) 
  validate(run.parms)
} else {
  message("Run parameters JSON file does not seem to exist")
}



library(jsonlite)
json.file <- file.path("C:","Fudge","work", "runfile.json")
run.parms <- fromJSON(json.file, simplifyVector=TRUE) 
# reads JSON format file and returns as list
names(run.parms)
for (i in 1:length(names(run.parms))) {
  tmp <- names(run.parms[1])
  names(run.parms[1]) <- run.parms$tmp
}

for (i in 1:length(names(run.parms))) {
  tmp = names(run.parms[i])
  val = run.parms$tmp
  assign(names(run.parms[i]), val)
}

rm(i, tmp, json.file)
rm(list=c('tmp','json.file'))
