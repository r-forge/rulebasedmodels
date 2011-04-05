
predict.cubist <- function (object, newdata, ...) 
{

  ## TODO: check for null newdata
  ## TODO: check data types and order

  ## make cases file
  caesString <- makeDataFile(x = newdata, y = NULL)

  if(FALSE)
    {
      Z <- .C("predictions",
              as.character(caseString),
              as.character(object$names),
              as.character(object$data),
              as.character(object$model),
              ## flag for instances or not?
              output = double(nrow(newdata)),    
              PACKAGE = "Cubist"
              )
    }
  
  z$output
}
