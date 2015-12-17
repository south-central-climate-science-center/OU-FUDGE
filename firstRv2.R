# This only work on "perfect model" runs
firstRv2 <- function(){
  cores <- 24
  i.count <- 194/(cores)
  i.low <- trunc(seq(1,194,i.count))
  i.low <- c(i.low,195)
  i.c <- diff(i.low)
  cat(paste(i.low[1:(cores)],i.c[1:(cores)],1,114),sep="\n")
}

firstRv2()

