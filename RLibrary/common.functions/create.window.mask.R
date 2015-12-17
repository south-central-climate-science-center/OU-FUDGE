# These will be a collection of spatial or temporal windowing masks
# Each has a specific name, e.g., ".seasonal" that will be referenced in the run parms file

# This is a generic function that substitutes itself for the actual masking function
createWindowMask <- function(){
  # choose mask based on run parms input
  funx.name <- (paste0("createWindowMask.",rp$apply.window.mask.name))
  funx.call <- get(funx.name, mode="function")
  return(funx.call)
}

createWindowMask.seasonal <- function(){
  # create a seasonal time windowing mask
  # time windowing masks are vectors with length = time of the climate data
  
  # bring in climate data dimensions, 
  # assume dimensions are [lat,lon,time]
  # time window masks are time vectors only
  # will need calendar adjustments here eventually
  tmp.time <- as.POSIXlt(hist.time.vector)
  tmp.month <- tmp.time$mon
  hist <- rep(NA, length(tmp.month))
  hist[tmp.month==0 | tmp.month==1 | tmp.month==2] <- 'Winter'
  hist[tmp.month==3 | tmp.month==4 | tmp.month==5] <- 'Spring'
  hist[tmp.month==6 | tmp.month==7 | tmp.month==8] <- 'Summer'
  hist[tmp.month==9 | tmp.month==10 | tmp.month==11] <- 'Fall'
  # now do future dates 
  tmp.time2 <- as.POSIXlt(fut.time.vector)
  tmp.month2 <- tmp.time2$mon
  fut <- rep(NA, length(tmp.month2))
  fut[tmp.month2==0 | tmp.month2==1 | tmp.month2==2] <- 'Winter'
  fut[tmp.month2==3 | tmp.month2==4 | tmp.month2==5] <- 'Spring'
  fut[tmp.month2==6 | tmp.month2==7 | tmp.month2==8] <- 'Summer'
  fut[tmp.month2==9 | tmp.month2==10 | tmp.month2==11] <- 'Fall'
  window.mask.names <- list('Winter','Spring','Summer','Fall')
  windows <- list(hist,fut,window.mask.names)
  names(windows) <- c('hist','fut','window.mask.names')
  return(windows)
}
  
createWindowMask.monthly <- function(){
  # create a seasonal time windowing mask
  # time windowing masks are vectors with length = time of the climate data
  
  # bring in climate data dimensions, 
  # assume dimensions are [lat,lon,time]
  # time window masks are time vectors only
  # will need calendar adjustments here eventually
  tmp.time <- as.POSIXlt(hist.time.vector)
  tmp.month <- tmp.time$mon
  list.months<-list('JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC')
  hist <- rep(NA, length(tmp.month))
  for(i in 1:12){
    hist[tmp.month==(i-1)]<-list.months[[i]]
  }
  # now do future dates 
  tmp.time2 <- as.POSIXlt(fut.time.vector)
  tmp.month2 <- tmp.time2$mon
  fut <- rep(NA, length(tmp.month2))
  for(i in 1:12){
    fut[tmp.month==(i-1)]<-list.months[[i]]
  }
  window.mask.names <- list.months
  windows <- list(hist,fut,window.mask.names)
  names(windows) <- c('hist','fut','window.mask.names')
  return(windows)
}
