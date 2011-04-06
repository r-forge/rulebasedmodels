
predict.cubist <- function (object, newdata, ...) 
{

  ## TODO: check for null newdata
  ## TODO: check data types and order

  ## make cases file
  caseString <- makeDataFile(x = newdata, y = NULL)

  Z <- .C("predictions",
          as.character(caseString),
          as.character(object$names),
          as.character(object$data),
          as.character(object$model),
          ## flag for instances or not?
          pred = double(nrow(newdata)),    
          output = character(1),
          PACKAGE = "Cubist"
          )

  ## for testing
  cat(Z$output, '\n')

  Z$pred
}
