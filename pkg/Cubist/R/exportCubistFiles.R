exportCubistFiles <- function(x, path = getwd(), prefix = NULL)
  {
    if(is.null(prefix)) prefix <- paste("model", format(Sys.time(), "%Y%m%d_%H%M"), sep = "")
    cat(x$model, file = file.path(path, paste(prefix, "model", sep = ".")))
    modelTest <- file.exists(file.path(path, paste(prefix, "model", sep = ".")))
    if(!modelTest) stop("the model file could not be created")
    
    cat(x$names, file = file.path(path, paste(prefix, "names", sep = ".")))
    namesTest <- file.exists(file.path(path, paste(prefix, "names", sep = ".")))
    if(!namesTest) stop("the names file could not be created")

    cat(x$data, file = file.path(path, paste(prefix, "data", sep = ".")))
    dataTest <- file.exists(file.path(path, paste(prefix, "data", sep = ".")))
    if(!dataTest) stop("the data file could not be created")
  }
