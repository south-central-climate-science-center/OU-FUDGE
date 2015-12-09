       Framework for Unified Downscaling of GCMs Empirically (FUDGE)

December 9, 2015

This file is the University of Oklahoma, South-central Climate Science Center modification of FUDGE version "darkchocolate"

Modifications were to make the code modular for better user modification and to allow new downscaling methods to be added sequentially with minimal code changes.

See https://github.com/NOAA-GFDL/FUDGE for the original NOAA-GFDL darkchocolate version.

THIS CODE IS "PROOF OF CONCEPT" ONLY FOR TESTING THE APPROACH FOR MODULARIZING THE CODE. THE CODE HAS NOT BEEN TESTED AGAINST THE ORIGINAL FUDGE.

Workflow
--------
Workflow is as follows:
	
-- Create a run parameters JSON file
  - This is done manually or using the 
    "create JSON run file.R" code
  - See JSON file "runfile.json"
  
-- On HPC, run the workflow in three steps
-- The three steps are controlled by the shell script
   "write_fudge_pbs.sh"

  - 1. qsub the first R script

This script works on the entire downscale region. Here you would create weather analogs, ENSO indicies, or other datasets for use during douwnscaling, but where these datasets are outside the downscaling region. Save these datasets to a binary .RData file for use within the main downscaling jobs.

This script also allows simple error checking ... can you write to directories? ... are the climate datasets there?

And finally, this first R script uses logic, or user supplied parameters to "break" the downscale region in chunks to qsub as individual HPC jobs. 

 - 2. qsub the downscale region into separate jobs

This script is "MAIN_Runcode.R"

The chunks of the region for a job are controlled by passing commandArgs to R at invocation.

The script completes the downscaling for each chunk and saves output to a binary .RData file in /scratch/. It also save fit parameters to a binary file. 

  - 3. qsub the final R script

This script is not written yet.

This script will stitch together all the individual chunks together, and output to a netCDF file. It could also run bioclim or other post-processing jobs on the entire downscaled region. 

  Requirements
  ------------
  This code has been running on CentOS release 6.3

  This code requires access to:
  - R 3.2.1 or higher 
  -- R packages: 
	ncdf4,
	ncdf4.helpers,
	CDFt,
	PCICt,
	udunits2, 
	abind,
	RNetCDF,
	ncdf.tools,
	jsonlite,
	AND all package dependencies
  - netcdf 4.3.3.1 or higher
  - udunits 2.2.20 or higher


  Warnings
  -----------------------------

  1. This code has been designed for work with the Oklahoma State University cluster "Cowboy".  We make no guarantee that it will work properly elsewhere. 

  2. This code is a work in progress.  

  Contacts
  --------
     o Duncan Wilson, University of Oklahoma, South-central Climate Science Center, duncan@ou.edu
