#-------Add traceback call for error handling -------
stored.opts <- options()[c('warn', 'error', 'showErrorCalls')]
error.handler.function <- function(){
  #message(writeLines(traceback()))
  traceback()
  message("Quitting gracefully with exit status 1")
  #If quitting from a non-interactive session, a status of 1 should be sent. Test this.
  #quit(save="no", status=1, runLast=FALSE, save=FALSE) #runLast=FALSE
}
#previously traceback
options(error=error.handler.function, warn = 1, showErrorCalls=TRUE)