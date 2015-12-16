
firstRv2 <- function(){
  cores <- 24
  i.count <- 194/(cores)
  j.count <- 114/(cores)
  i.low <- trunc(seq(1,194,i.count))
  i.low <- c(i.low,194)
  j.low <- trunc(seq(1,114,j.count))
  j.low <- c(j.low,114)
  i.c <- diff(i.low)
  j.c <- diff(j.low)
  cat(paste(i.low[1:(cores)],i.c[1:(cores-1)],j.low[1:(cores)],j.c[1:(cores-1)]),sep="\n")
}

firstRv2()

