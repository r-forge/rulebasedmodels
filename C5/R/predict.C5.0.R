
predict.C5.0 <- function (object, newdata = NULL, ...) 
{
  
  if(is.null(newdata)) stop("newdata must be non-null")
  
  ## check order of data to make sure that it is the same
  newdata <- newdata[, object$vars$all,drop = FALSE]


  ## make cases file
  caseString <- makeDataFile(x = newdata, y = NULL)
  
  ## for testing
  cat(caseString, '\n')

  Z <- .C("predictions",
          as.character(caseString),
          as.character(object$names),
          as.character(object$tree),
          as.character(object$rules),
          pred = double(nrow(newdata)),  # XXX predictions are character
          output = character(1),
          PACKAGE = "C50"
          )

  ## for testing
  cat(Z$output, '\n')

  Z$pred
}
