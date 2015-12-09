       Framework for Unified Downscaling of GCMs Empirically (FUDGE)

December 9, 2015

This file is the OU modification of FUDGE version "darkchocolate"

Modifications were to make the code modular for better user modification and to allow new downscaling methods to be added sequentially with minimal code changes.

See https://github.com/NOAA-GFDL/FUDGE for the original NOAA-GFDL darkchocolate version.

THIS CODE IS "PROOF OF CONCEPT" ONLY FOR TESTING THE APPROACH TO MODULARIZING THE WORKFLOW. THE CODE HAS NOT BEEN TESTED AGAINST THE ORIGINAL FUDGE.

  Modifications
  -------------
  Workflow is as follows:
	
	-- Create a run parameters JSON file
		- This is done manually or using the 
		  "create JSON run file.R" code

	-- On HPC, run the workflow in three steps

	1. submit the first R script
	
	This script 

BLAH
----

1. blah
2. Workshkljhsdfjkl asldkfjl falkdjf lkasdjf ol falkjsdf lasdkfj laksdjf laksdjf alsdkjf alsdkfj asldkfj 

  Requirements
  ------------
  This code has been running on CentOS release 6.3

  This code requires access to:
  - R 3.2.1 or higher 
  -- R packages: 
	ncdf4
	ncdf4.helpers
	CDFt
	PCICt
	udunits2 
	abind
	RNetCDF
	ncdf.tools
	jsonlite
	AND all package dependencies
  - netcdf 4.3.3.1 or higher
  - udunits 2.2.20 or higher


  Warnings
  -----------------------------

  1. This code has been designed for work with the Oklahoma State University cluster "Cowboy".  We make no guarantee that it 
  will still work properly elsewhere. 

  2. This code is a work in progress.  

  Contacts
  --------
     o Duncan Wilson, University of Oklahoma, South-central Climate Science Center, duncan@ou.edu
