C5.0 <-  function(x, ...) UseMethod("C5.0")

## About our approach here... see cubist.R for a run-down

C5.0.default <- function(x, y, control = C5.0Control(), ...)
{
  funcCall <- match.call(expand.dots = TRUE)
  if(!is.factor(y)) stop("C5.0 models require a factor outcome")

  ## TODO: check for missing outcome data
  
  namesString <- makeNamesFile(x, y, label = control$label, comments = TRUE)
  dataString <- makeDataFile(x, y)

  out <- list(data = dataString,
              names = namesString,
              dims = dim(x),
              lvl = levels(y),
              call = funcCall,
              control = control)
  class(out) <- "C5.0"
  out

}


print.C5.0 <- function(x, ...)
  {
    cat("\nCall:\n", truncateText(deparse(x$call, width.cutoff = 500)), "\n\n", sep = "")


    cat("Number of samples:", x$dims[1],
        "\nNumber of predictors:", x$dims[2],
        "\nClasses:", paste(x$lvl, collapse = ", "),
        "\n\n")
    
    cat("Number of Committees:", x$control$committees, "\n")
    otherOptions <- NULL
    if(x$control$subsets) otherOptions <- c(otherOptions, "attributes grouped into subsets")
    if(x$control$rules) otherOptions <- c(otherOptions, "rule-based model")
    if(x$control$winnow) otherOptions <- c(otherOptions, "predictors winnowed")
    if(!x$control$globalPruning) otherOptions <- c(otherOptions, "global pruning disabled")
    if(!is.logical(x$control$bandRules)) otherOptions <- c(otherOptions, paste("sort rules into", x$control$bandRules, "bands"))
    
    if(x$control$CF != .25) otherOptions <- c(otherOptions, paste("CF value:", x$control$CF))
    if(x$control$minCases != 2) otherOptions <- c(otherOptions, paste("minimun cases:", x$control$minCases))    
    if(x$control$sample < 99.9) otherOptions <- c(otherOptions, paste(x$control$sample, "% sub-sampling", sep = ""))
    if(!is.null(otherOptions))
      {
        cat("Other options:", paste(otherOptions, collapse = ", "))
      }
    

  }


C5.0Control <- function(subsets = FALSE,
                        rules = FALSE,
                        bandRules = FALSE,
                        winnow = FALSE,
                        softThresholds = FALSE,
                        globalPruning = TRUE,
                        CF = 0.25, 
                        minCases = 2, 
                        committees = 1,
                        sample = 99.9,
                        seed = 1,
                        label = "outcome")
  {
    if(!is.logical(bandRules) && bandRules < 1)
      stop("number of bands must be greater than zero")    
    if(minCases < 1)
      stop("number of samples in the terminal node must be greater than zero")    
    if(CF  <= 0 | CF >= 1)
      stop("CF must be between 0 and 1")    

    if(sample < .01 | sample > 99.9)
      stop("sampling percentage must be between 0.01 and 99.9")     
    if(committees < 1 | committees > 100)
      stop("number of committees must be between 1 and 100")
    
    list(subsets = subsets,
         rules = rules,
         bandRules = bandRules,
         winnow = winnow,
         softThresholds = softThresholds,
         globalPruning = globalPruning,
         CF = CF,
         minCases = minCases,
         committees = committees,
         sample = sample,
         seed = seed,
         label = label)    
  }
