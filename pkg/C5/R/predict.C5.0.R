
predict.C5.0 <- function (object, newdata = NULL, trials = object$trials, type = "class", ...) 
{
  if(!(type %in% c("class", "prob"))) stop("type should be either 'class' or 'prob'")
  if(is.null(newdata)) stop("newdata must be non-null")
  
  ## make sure that the order of data to make sure that it is the same
  newdata <- newdata[, object$predictors, drop = FALSE]

  if(length(trials) > 1) stop("only one value of trials is allowed")
  if(trials > object$trials) stop(paste("'trials' must be <=", object$trials, "for this object"))

  ## make cases file
  caseString <- makeDataFile(x = newdata, y = NULL)
  
  ## for testing
  ##cat(caseString, '\n')

  ## When passing trials to the C code, convert to
  ## zero if the original version of trails is used

  if(trials <= 0) stop("'trials should be a positive integer")
  if(trials == object$trials) trials <- 0

  ## Add trials (not object$trials) as an argument
  Z <- .C("predictions",
          as.character(caseString),
          as.character(object$names),
          as.character(object$tree),
          as.character(object$rules),
          pred = integer(nrow(newdata)),
          trials = as.integer(trials),
          output = character(1),
          PACKAGE = "C50"
          )

  if(type == "class")
    {
      out <- factor(object$levels[Z$pred], levels = object$levels)
    } else out <- NULL  ## add model confidence for type = "prob"
  out
}
