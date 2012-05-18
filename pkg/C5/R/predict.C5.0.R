
predict.C5.0 <- function (object, newdata = NULL, trials = object$trials, type = "class", ...) 
{
  if(!(type %in% c("class", "prob"))) stop("type should be either 'class' or 'prob'")
  if(is.null(newdata)) stop("newdata must be non-null")
  
  ## check order of data to make sure that it is the same
  ## XXX Not implemented yet
  # newdata <- newdata[, object$vars$all,drop = FALSE]


  ## make cases file
  caseString <- makeDataFile(x = newdata, y = NULL)
  
  ## for testing
  ##cat(caseString, '\n')

  ## Add trials (not object$trials) as an argument
  Z <- .C("predictions",
          as.character(caseString),
          as.character(object$names),
          as.character(object$tree),
          as.character(object$rules),
          pred = integer(nrow(newdata)), 
          output = character(1),
          PACKAGE = "C50"
          )

  ## for testing
  ##cat(Z$output, '\n')

  if(type == "class")
    {
      out <- factor(object$levels[Z$pred], levels = object$levels)
    } else out <- NULL  ## add model confidence for type = "prob"
  out
}
